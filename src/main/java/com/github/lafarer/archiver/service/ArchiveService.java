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
        } else {
            Files.copy(sourceFile, target, StandardCopyOption.REPLACE_EXISTING);
            log.info("Copied {} → {}", sourceFile.getFileName(), target);
        }
        return target;
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
