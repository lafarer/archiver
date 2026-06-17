-- Debounce delay (ms) before the watchdog dispatches a new file to the pipeline.
-- Absorbs duplicate filesystem events (ENTRY_CREATE + ENTRY_MODIFY) emitted by
-- Docker volume mounts and also ensures the file is fully written before processing.
INSERT INTO setting (key, value) VALUES ('watchdog_debounce_ms', '1500');
