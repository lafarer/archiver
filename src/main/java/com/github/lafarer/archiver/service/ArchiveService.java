package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.config.ArchiverProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

@Service
@RequiredArgsConstructor
@Slf4j
public class ArchiveService {

    private final ArchiverProperties props;
    private final SettingService settingService;

    public enum SourceType { INBOX, MANUAL }

    public Path archive(Path sourceFile, String relativeTargetPath, SourceType sourceType) throws IOException {
        Path target = props.getRoot().resolve(relativeTargetPath);
        Files.createDirectories(target.getParent());
        target = resolveConflict(target);

        boolean move = sourceType == SourceType.INBOX
            || "move".equals(settingService.get("import_mode"));

        if (move) {
            Files.move(sourceFile, target, StandardCopyOption.ATOMIC_MOVE);
            log.info("Moved {} → {}", sourceFile.getFileName(), target);
            cleanupEmptyInboxDirs(sourceFile.getParent());
        } else {
            Files.copy(sourceFile, target, StandardCopyOption.REPLACE_EXISTING);
            log.info("Copied {} → {}", sourceFile.getFileName(), target);
        }
        return target;
    }

    public Path reclassify(Path source, String relativeTargetPath) throws IOException {
        Path target = props.getRoot().resolve(relativeTargetPath);
        if (source.toAbsolutePath().equals(target.toAbsolutePath())) return source;
        Files.createDirectories(target.getParent());
        target = resolveConflict(target);
        Files.move(source, target, StandardCopyOption.ATOMIC_MOVE);
        log.info("Reclassified {} → {}", source.getFileName(), target);
        return target;
    }

    private void cleanupEmptyInboxDirs(Path dir) {
        Path inbox = props.getInboxPath();
        while (dir != null && dir.startsWith(inbox) && !dir.equals(inbox)) {
            try {
                boolean isEmpty;
                try (var stream = Files.list(dir)) {
                    isEmpty = stream.findAny().isEmpty();
                }
                if (!isEmpty) break;
                Files.delete(dir);
                log.info("Removed empty inbox folder: {}", dir.getFileName());
                dir = dir.getParent();
            } catch (IOException e) {
                log.warn("Could not remove inbox folder {}: {}", dir, e.getMessage());
                break;
            }
        }
    }

    private Path resolveConflict(Path target) {
        if (!Files.exists(target)) return target;
        String name = target.getFileName().toString();
        int dot = name.lastIndexOf('.');
        String base = dot > 0 ? name.substring(0, dot) : name;
        String ext  = dot > 0 ? name.substring(dot)    : "";
        int i = 1;
        Path candidate;
        do {
            candidate = target.getParent().resolve(base + "-" + i + ext);
            i++;
        } while (Files.exists(candidate));
        return candidate;
    }
}
