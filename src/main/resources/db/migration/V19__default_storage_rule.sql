-- Add a catch-all default rule.
-- This rule matches any document not covered by a more specific rule.
-- is_default = 1 ensures it is used as the fallback when no other rule matches.

INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES
    (99, 'Documents divers (règle par défaut)',
     'Document ne correspondant à aucune règle plus spécifique.',
     'Documents/[yyyy]/[mm?]/[document_type]-[title]',
     1, 1);
