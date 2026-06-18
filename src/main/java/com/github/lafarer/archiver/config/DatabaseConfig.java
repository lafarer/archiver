package com.github.lafarer.archiver.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.flywaydb.core.Flyway;
import org.sqlite.SQLiteConfig;
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

    private final DatabaseInitState initState;

    @Bean
    @Primary
    DataSource dataSource() throws IOException {
        Files.createDirectories(props.getRoot());
        Files.createDirectories(props.getInboxPath());
        Files.createDirectories(props.getArchivePath());
        log.info("Archive root : {}", props.getRoot());
        log.info("Inbox        : {}", props.getInboxPath());
        log.info("Archive      : {}", props.getArchivePath());

        boolean isNewDb = !Files.exists(props.getDbPath());
        if (isNewDb) {
            log.info("No existing database found - will be created fresh");
            initState.markFreshlyCreated();
        }

        SQLiteConfig config = new SQLiteConfig();
        config.setBusyTimeout(10_000);           // retry for up to 10 s before giving up
        config.setJournalMode(SQLiteConfig.JournalMode.WAL); // WAL reduces write contention

        SQLiteDataSource ds = new SQLiteDataSource(config);
        ds.setUrl("jdbc:sqlite:" + props.getDbPath().toAbsolutePath());
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
