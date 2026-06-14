package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.config.ArchiverProperties;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

@Service
@RequiredArgsConstructor
@Slf4j
public class WatchdogService {

    private final ArchiverProperties props;
    private final SettingService settingService;
    private final DocumentPipelineService pipelineService;

    private final AtomicBoolean running = new AtomicBoolean(false);
    private ExecutorService executor;
    private WatchService watchService;

    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        if (settingService.getBoolean("watchdog_enabled")) {
            start();
        }
    }

    public void start() {
        if (running.compareAndSet(false, true)) {
            executor = Executors.newSingleThreadExecutor(r -> {
                Thread t = new Thread(r, "watchdog");
                t.setDaemon(true);
                return t;
            });
            executor.submit(this::watch);
            log.info("Watchdog started on {}", props.getInboxPath());
        }
    }

    public void stop() {
        running.set(false);
        try {
            if (watchService != null) watchService.close();
        } catch (IOException ignored) {}
        if (executor != null) executor.shutdownNow();
        log.info("Watchdog stopped");
    }

    public boolean isRunning() {
        return running.get();
    }

    private void scanExisting() {
        try (var stream = Files.walk(props.getInboxPath())) {
            stream.filter(f -> Files.isRegularFile(f) && !f.getFileName().toString().startsWith("."))
                  .forEach(f -> {
                      log.info("Scanning existing inbox file: {}", f);
                      pipelineService.processAsync(f, ArchiveService.SourceType.INBOX);
                  });
        } catch (IOException e) {
            log.warn("Could not scan inbox for existing files: {}", e.getMessage());
        }
    }

    private void watch() {
        try {
            scanExisting();

            watchService = FileSystems.getDefault().newWatchService();
            props.getInboxPath().register(watchService,
                StandardWatchEventKinds.ENTRY_CREATE,
                StandardWatchEventKinds.ENTRY_MODIFY);

            while (running.get()) {
                WatchKey key = watchService.take();
                for (WatchEvent<?> event : key.pollEvents()) {
                    if (event.kind() == StandardWatchEventKinds.OVERFLOW) continue;
                    @SuppressWarnings("unchecked")
                    Path path = props.getInboxPath().resolve(((WatchEvent<Path>) event).context());
                    if (Files.isDirectory(path)) {
                        log.info("New folder detected in inbox: {}", path.getFileName());
                        processFolder(path);
                    } else if (Files.isRegularFile(path) && !path.getFileName().toString().startsWith(".")) {
                        log.info("New file detected: {}", path.getFileName());
                        pipelineService.processAsync(path, ArchiveService.SourceType.INBOX);
                    }
                }
                if (!key.reset()) break;
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (IOException e) {
            if (running.get()) log.error("Watchdog error: {}", e.getMessage());
        }
    }

    private void processFolder(Path folder) {
        try (var stream = Files.walk(folder)) {
            stream.filter(f -> Files.isRegularFile(f) && !f.getFileName().toString().startsWith("."))
                  .forEach(f -> {
                      log.info("Processing file from dropped folder: {}", f);
                      pipelineService.processAsync(f, ArchiveService.SourceType.INBOX);
                  });
        } catch (IOException e) {
            log.warn("Could not scan dropped folder {}: {}", folder.getFileName(), e.getMessage());
        }
    }

    @PreDestroy
    public void onShutdown() {
        stop();
    }
}
