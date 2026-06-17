-- For payslips the issuer can be a payroll provider rather than the actual employer.
-- Use the employeur custom field in the path template instead of issuer so the
-- document is always filed under the company on the employment contract.
UPDATE storage_path_rule
SET path_template = 'Famille/[membre_famille]/Emploi/Fiches-de-paie/[yyyy]/[yyyy]-[mm?]-[dd?]-[employeur]'
WHERE id = 30;

-- Clarify that for payslips, employeur is the company on the employment contract,
-- not an intermediary payroll service provider.
UPDATE custom_field_def
SET description = 'Nom ou raison sociale de l''employeur figurant sur le document. Pour les fiches de paie, c''est l''entreprise mentionnée au contrat de travail (ex : THREE-i S.A.), pas le prestataire de paie qui a édité le bulletin (ex : Groupe Social Lerminiaux).'
WHERE slug = 'employeur';
