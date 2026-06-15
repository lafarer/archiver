-- Storage path rules (must come first - referenced by document and classification_history)
CREATE TABLE storage_path_rule (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    priority     INTEGER NOT NULL,
    label        TEXT    NOT NULL,
    condition_nl TEXT,
    path_template TEXT   NOT NULL,
    is_default   INTEGER NOT NULL DEFAULT 0,
    is_active    INTEGER NOT NULL DEFAULT 1,
    created_at   TEXT,
    updated_at   TEXT
);

CREATE UNIQUE INDEX idx_storage_path_rule_default ON storage_path_rule (is_default) WHERE is_default = 1;

-- Archived documents
CREATE TABLE document (
    id                       INTEGER PRIMARY KEY AUTOINCREMENT,
    document_type            TEXT,
    title                    TEXT,
    title_source             TEXT,
    title_confidence         REAL,
    document_date            TEXT,
    document_date_precision  TEXT,
    document_date_source     TEXT,
    document_date_confidence REAL,
    issuer                   TEXT,
    issuer_source            TEXT,
    issuer_confidence        REAL,
    description              TEXT,
    tags                     TEXT,
    custom_fields            TEXT,
    original_filename        TEXT    NOT NULL,
    sha256_hash              TEXT    UNIQUE NOT NULL,
    mime_type                TEXT    NOT NULL,
    file_size_bytes          INTEGER,
    filesystem_mtime         TEXT,
    source_path              TEXT,
    resolved_path            TEXT,
    applied_rule_id          INTEGER REFERENCES storage_path_rule(id),
    is_classified            INTEGER NOT NULL DEFAULT 0,
    classified_at            TEXT,
    sidecar_path             TEXT,
    created_at               TEXT,
    updated_at               TEXT
);

-- Classification history
CREATE TABLE classification_history (
    id                        INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id               INTEGER NOT NULL REFERENCES document(id),
    old_path                  TEXT,
    new_path                  TEXT NOT NULL,
    old_rule_id               INTEGER REFERENCES storage_path_rule(id) ON DELETE SET NULL,
    new_rule_id               INTEGER REFERENCES storage_path_rule(id) ON DELETE SET NULL,
    trigger                   TEXT NOT NULL,
    triggering_rule_change_id INTEGER REFERENCES storage_path_rule(id) ON DELETE SET NULL,
    notes                     TEXT,
    created_at                TEXT
);

-- Custom field definitions (slug used in path templates, e.g. [numero_contrat])
CREATE TABLE custom_field_def (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    slug        TEXT NOT NULL UNIQUE,
    label       TEXT NOT NULL,
    description TEXT NOT NULL,
    field_type  TEXT NOT NULL
);

-- Runtime settings
CREATE TABLE setting (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- Document type catalogue
CREATE TABLE document_type_def (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    slug        TEXT    NOT NULL UNIQUE,
    label       TEXT    NOT NULL,
    description TEXT,
    enabled     INTEGER NOT NULL DEFAULT 1
);

-- Tag catalogue
CREATE TABLE tag_def (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    slug        TEXT    NOT NULL UNIQUE,
    label       TEXT    NOT NULL,
    description TEXT,
    enabled     INTEGER NOT NULL DEFAULT 1
);
