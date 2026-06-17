-- permis-construire is a duplicate of the more precise permis-de-construire.
-- pv-assemblee is a duplicate of the more precise proces-verbal-ag.
-- Disable the generic slugs and migrate any existing documents to the precise ones.

UPDATE document_type_def SET enabled = 0 WHERE slug IN ('permis-construire', 'pv-assemblee');

UPDATE document SET document_type = 'permis-de-construire' WHERE document_type = 'permis-construire';
UPDATE document SET document_type = 'proces-verbal-ag'     WHERE document_type = 'pv-assemblee';
