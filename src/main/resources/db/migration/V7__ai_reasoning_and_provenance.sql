ALTER TABLE document ADD COLUMN ai_reasoning TEXT;
ALTER TABLE document ADD COLUMN ai_model TEXT;
ALTER TABLE document ADD COLUMN custom_fields_provenance TEXT NOT NULL DEFAULT '{}';
