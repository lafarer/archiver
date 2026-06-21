UPDATE storage_path_rule
SET label = 'Documents divers'
WHERE label = 'Documents divers (règle par défaut)' AND is_default = 1;
