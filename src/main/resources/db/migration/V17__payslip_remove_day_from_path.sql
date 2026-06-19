UPDATE storage_path_rule
SET path_template = 'Famille/[membre_famille]/Emploi/Fiches-de-paie/[yyyy]/[yyyy]-[mm?]-[employeur]'
WHERE label = 'Famille - Emploi : fiches de paie';
