package com.github.lafarer.archiver.config;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import java.nio.file.Path;

@ConfigurationProperties(prefix = "archiver")
@Validated
@Getter @Setter
public class ArchiverProperties {

    @NotNull
    private Path root;

    private Path inbox;

    private String host = "127.0.0.1";

    private int port = 8080;

    public Path getInboxPath() {
        return inbox != null ? inbox : root.resolve("inbox");
    }

    public Path getDbPath() {
        return root.resolve("archiver.db");
    }
}
