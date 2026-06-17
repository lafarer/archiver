package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.DocumentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class StorageAuditService {

    private final DocumentRepository documentRepository;
    private final ArchiverProperties props;
    private final SidecarService sidecarService;

    public enum AnomalyType {
        /** DB record exists but file and sidecar are both missing */
        GHOST_RECORD,
        /** DB record and sidecar exist but file is missing (deleted manually) */
        MISSING_FILE,
        /** File and DB record exist but sidecar is missing */
        FILE_WITHOUT_SIDECAR,
        /** File and sidecar exist but no DB record (main reconstruction case) */
        UNTRACKED_WITH_SIDECAR,
        /** File exists on disk with no sidecar and no DB record */
        UNTRACKED_NO_SIDECAR,
        /** Sidecar exists but corresponding file and DB record are both absent */
        ORPHAN_SIDECAR
    }

    public record AuditEntry(
        String relPath,
        AnomalyType type,
        Document dbRecord    // null when not in DB
    ) {}

    public record AuditReport(
        List<AuditEntry> anomalies,
        int filesScanned,
        int dbRecords,
        Instant scannedAt
    ) {
        public Map<AnomalyType, List<AuditEntry>> byType() {
            return anomalies.stream().collect(
                Collectors.groupingBy(AuditEntry::type,
                    () -> new EnumMap<>(AnomalyType.class),
                    Collectors.toList()));
        }

        public boolean hasAnomalies() {
            return !anomalies.isEmpty();
        }
    }

    public AuditReport scan() throws IOException {
        Path archivePath = props.getArchivePath();

        Map<String, Document> dbMap = documentRepository.findAll().stream()
            .filter(Document::isClassified)
            .filter(d -> d.getResolvedPath() != null)
            .collect(Collectors.toMap(Document::getResolvedPath, d -> d, (a, b) -> a));

        if (!Files.exists(archivePath)) {
            log.warn("Archive path does not exist: {}", archivePath);
            List<AuditEntry> ghosts = dbMap.entrySet().stream()
                .map(e -> new AuditEntry(e.getKey(), AnomalyType.GHOST_RECORD, e.getValue()))
                .toList();
            return new AuditReport(ghosts, 0, dbMap.size(), Instant.now());
        }

        Set<String> seenFiles = new HashSet<>();
        List<AuditEntry> anomalies = new ArrayList<>();

        try (var stream = Files.walk(archivePath)) {
            for (Path path : (Iterable<Path>) stream::iterator) {
                if (Files.isDirectory(path)) continue;
                String filename = path.getFileName().toString();

                if (filename.startsWith(".") && filename.endsWith(".json")) {
                    // Sidecar file - check if its document exists
                    String docFilename = filename.substring(1, filename.length() - 5);
                    Path docPath = path.getParent().resolve(docFilename);
                    if (!Files.exists(docPath)) {
                        String docRelPath = archivePath.relativize(docPath).toString();
                        // Only report ORPHAN_SIDECAR if no DB record; if there is one,
                        // the DB-pass below will report it as MISSING_FILE.
                        if (!dbMap.containsKey(docRelPath)) {
                            anomalies.add(new AuditEntry(docRelPath, AnomalyType.ORPHAN_SIDECAR, null));
                        }
                    }
                    continue;
                }

                if (filename.startsWith(".")) continue; // other hidden files (.DS_Store, etc.)

                String relPath = archivePath.relativize(path).toString();
                seenFiles.add(relPath);

                boolean hasSidecar = Files.exists(sidecarService.sidecarPathFor(path));
                Document dbRecord = dbMap.get(relPath);

                if (dbRecord != null) {
                    if (!hasSidecar) {
                        anomalies.add(new AuditEntry(relPath, AnomalyType.FILE_WITHOUT_SIDECAR, dbRecord));
                    }
                    // file + sidecar + DB → OK, no anomaly
                } else {
                    AnomalyType type = hasSidecar
                        ? AnomalyType.UNTRACKED_WITH_SIDECAR
                        : AnomalyType.UNTRACKED_NO_SIDECAR;
                    anomalies.add(new AuditEntry(relPath, type, null));
                }
            }
        }

        // DB records whose file was not found on disk
        for (Map.Entry<String, Document> entry : dbMap.entrySet()) {
            if (!seenFiles.contains(entry.getKey())) {
                Path filePath = archivePath.resolve(entry.getKey());
                boolean hasSidecar = Files.exists(sidecarService.sidecarPathFor(filePath));
                AnomalyType type = hasSidecar ? AnomalyType.MISSING_FILE : AnomalyType.GHOST_RECORD;
                anomalies.add(new AuditEntry(entry.getKey(), type, entry.getValue()));
            }
        }

        log.info("Audit complete: {} file(s) scanned, {} DB record(s), {} anomalie(s)",
            seenFiles.size(), dbMap.size(), anomalies.size());

        return new AuditReport(Collections.unmodifiableList(anomalies),
            seenFiles.size(), dbMap.size(), Instant.now());
    }
}
