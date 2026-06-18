package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.DocumentRepository;
import com.github.lafarer.archiver.repository.StoragePathRuleRepository;
import com.github.lafarer.archiver.service.StorageAuditService.AnomalyType;
import com.github.lafarer.archiver.service.StorageAuditService.AuditEntry;
import com.github.lafarer.archiver.service.StorageAuditService.AuditReport;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
@Slf4j
public class SidecarImportService {

    private final DocumentRepository documentRepository;
    private final StoragePathRuleRepository ruleRepository;
    private final SidecarService sidecarService;
    private final StorageAuditService auditService;
    private final ArchiverProperties props;

    /**
     * Scans the archive for UNTRACKED_WITH_SIDECAR entries and imports each one.
     * Errors on individual documents are logged and skipped so other documents still import.
     */
    public int importAllUntracked() throws IOException {
        AuditReport report = auditService.scan();
        List<AuditEntry> entries = report.byType().getOrDefault(AnomalyType.UNTRACKED_WITH_SIDECAR, List.of());
        int imported = 0;
        for (AuditEntry entry : entries) {
            try {
                imported += importFromSidecar(entry.relPath());
            } catch (Exception e) {
                log.error("Failed to auto-import {}: {}", entry.relPath(), e.getMessage());
            }
        }
        return imported;
    }

    /**
     * Imports a single archived document from its sidecar into the DB.
     * Returns 1 if imported, 0 if skipped (missing files or duplicate hash).
     */
    @Transactional
    public int importFromSidecar(String relPath) throws IOException {
        Path docFile = props.getArchivePath().resolve(relPath);
        Path sidecarFile = sidecarService.sidecarPathFor(docFile);
        if (!Files.exists(docFile) || !Files.exists(sidecarFile)) return 0;

        String hash = sha256(docFile);
        if (documentRepository.findBySha256Hash(hash).isPresent()) {
            log.info("Skipping duplicate during import: {}", relPath);
            return 0;
        }

        Document doc = sidecarService.importDocument(sidecarFile);
        doc.setOriginalFilename(docFile.getFileName().toString());
        doc.setResolvedPath(relPath);
        doc.setSidecarPath(props.getArchivePath().relativize(sidecarFile).toString());
        doc.setSha256Hash(hash);
        doc.setMimeType(probeType(docFile));
        doc.setFileSizeBytes(Files.size(docFile));
        doc.setFilesystemMtime(Files.getLastModifiedTime(docFile).toInstant());

        var ruleRef = sidecarService.readAppliedRuleRef(sidecarFile);
        if (ruleRef.isEmpty()) {
            log.warn("No applied_rule found in sidecar for {} - document will use default rule", relPath);
        } else {
            var ref = ruleRef.get();
            log.info("Sidecar applied_rule for {}: label='{}', conditionNl='{}'", relPath, ref.label(), ref.conditionNl());
            List<com.github.lafarer.archiver.model.StoragePathRule> allRules = ruleRepository.findAll();
            com.github.lafarer.archiver.model.StoragePathRule matched = allRules.stream()
                .filter(r -> ref.conditionNl() != null
                        && r.getConditionNl() != null
                        && ref.conditionNl().strip().equals(r.getConditionNl().strip()))
                .findFirst()
                .or(() -> allRules.stream()
                        .filter(r -> ref.label() != null
                                && r.getLabel() != null
                                && ref.label().strip().equals(r.getLabel().strip()))
                        .findFirst())
                .orElse(null);
            if (matched != null) {
                doc.setAppliedRule(matched);
                log.info("Matched rule '{}' (id={}) for {}", matched.getLabel(), matched.getId(), relPath);
            } else {
                log.warn("Could not match applied rule (label='{}', conditionNl='{}') for {} - rule may have been renamed or deleted",
                        ref.label(), ref.conditionNl(), relPath);
                log.warn("Available rules: {}", allRules.stream()
                        .map(r -> "'" + r.getLabel() + "'/" + r.getConditionNl())
                        .toList());
            }
        }

        documentRepository.save(doc);
        log.info("Imported from sidecar: {}", relPath);
        return 1;
    }

    private String sha256(Path file) throws IOException {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            try (InputStream is = new DigestInputStream(Files.newInputStream(file), md)) {
                is.transferTo(OutputStream.nullOutputStream());
            }
            return HexFormat.of().formatHex(md.digest());
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    private String probeType(Path file) throws IOException {
        String type = Files.probeContentType(file);
        return type != null ? type : "application/octet-stream";
    }
}
