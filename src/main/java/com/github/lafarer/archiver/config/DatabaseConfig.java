package com.github.lafarer.archiver.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.flywaydb.core.Flyway;
import org.sqlite.SQLiteDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import java.io.IOException;
import java.nio.file.Files;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class DatabaseConfig {

    private final ArchiverProperties props;

    @Bean
    @Primary
    DataSource dataSource() throws IOException {
        Files.createDirectories(props.getRoot());
        Files.createDirectories(props.getInboxPath());
        Files.createDirectories(props.getArchivePath());
        log.info("Archive root : {}", props.getRoot());
        log.info("Inbox        : {}", props.getInboxPath());
        log.info("Archive      : {}", props.getArchivePath());

        SQLiteDataSource ds = new SQLiteDataSource();
        ds.setUrl("jdbc:sqlite:" + props.getDbPath().toAbsolutePath());
        // SQLite is single-writer - pool size 1 avoids SQLITE_BUSY errors
        ds.setDatabaseName(props.getDbPath().toAbsolutePath().toString());

        // Run migrations before JPA initialises - auto-configuration cannot pick up
        // a programmatic DataSource, so Flyway is invoked explicitly here.
        Flyway.configure()
            .dataSource(ds)
            .locations("classpath:db/migration")
            .load()
            .migrate();

        return ds;
    }
}
