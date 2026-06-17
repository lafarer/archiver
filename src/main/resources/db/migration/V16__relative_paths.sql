-- Migrate absolute/root-relative paths to paths relative to their base folder.
--
-- resolved_path and sidecar_path were stored relative to root (e.g. "Archive/Factures/file.pdf").
-- They are now stored relative to archivePath (e.g. "Factures/file.pdf").
-- Default archiveFolder is "Archive"; if you use a custom value, adjust the prefix below.
--
-- source_path was stored as an absolute filesystem path (e.g. "/data/Inbox/file.pdf").
-- It is now stored as a filename relative to inboxPath (e.g. "file.pdf").
-- Inbox files are always flat (no subdirectories), so extracting the filename is sufficient.

-- Strip the "Archive/" prefix from resolved_path
UPDATE document
SET resolved_path = SUBSTR(resolved_path, LENGTH('Archive/') + 1)
WHERE resolved_path LIKE 'Archive/%';

-- Strip the "Archive/" prefix from sidecar_path
UPDATE document
SET sidecar_path = SUBSTR(sidecar_path, LENGTH('Archive/') + 1)
WHERE sidecar_path LIKE 'Archive/%';

-- Extract filename from absolute source_path (everything after the last '/')
UPDATE document
SET source_path = SUBSTR(source_path, LENGTH(source_path) - INSTR(REVERSE(source_path), '/') + 2)
WHERE source_path GLOB '*/*';
