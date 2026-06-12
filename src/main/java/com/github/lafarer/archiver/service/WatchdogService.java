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

    private void watch() {
        try {
            watchService = FileSystems.getDefault().newWatchService();
            props.getInboxPath().register(watchService,
                StandardWatchEventKinds.ENTRY_CREATE,
                StandardWatchEventKinds.ENTRY_MODIFY);

            while (running.get()) {
                WatchKey key = watchService.take();
                for (WatchEvent<?> event : key.pollEvents()) {
                    if (event.kind() == StandardWatchEventKinds.OVERFLOW) continue;
                    @SuppressWarnings("unchecked")
                    Path file = props.getInboxPath().resolve(((WatchEvent<Path>) event).context());
                    if (Files.isRegularFile(file) && !file.getFileName().toString().startsWith(".")) {
                        log.info("New file detected: {}", file.getFileName());
                        pipelineService.processAsync(file, ArchiveService.SourceType.INBOX);
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

    @PreDestroy
    public void onShutdown() {
        stop();
    }
}
