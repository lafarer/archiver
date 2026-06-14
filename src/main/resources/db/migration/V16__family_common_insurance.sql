-- 1. Update family insurance rules to explicitly include assurance emprunteur
UPDATE storage_path_rule
SET condition_nl = 'Le document est un contrat d''assurance personnelle d''un membre de la famille, non liée à un logement ou un véhicule : assurance vie, prévoyance individuelle, complémentaire santé (mutuelle), garantie accidents de la vie, assurance emprunteur (liée à un crédit immobilier ou à la consommation, rattachée à la personne assurée).'
WHERE priority = 49;

UPDATE storage_path_rule
SET condition_nl = 'Le document est un courrier ou une notification d''une assurance personnelle d''un membre de la famille, non liée à un logement ou un véhicule : résiliation, modification, relevé annuel, attestation, avis d''échéance. Inclut les courriers relatifs à une assurance emprunteur.'
WHERE priority = 50;

-- 2. Storage path rules for family-wide insurance (priority 51-52)
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    (51, 'Famille Commun — Assurances : contrats',
     'Le document est un contrat d''assurance couvrant l''ensemble de la famille ou du foyer, non rattaché à un membre en particulier, ni à un logement ou un véhicule spécifique : assurance voyage, assurance annulation, protection juridique familiale, assurance animaux de compagnie, assurance scolaire collective.',
     'Famille/Commun/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]',
     0, 1),

    (52, 'Famille Commun — Assurances : courriers',
     'Le document est un courrier, une attestation ou une notification liée à une assurance couvrant l''ensemble de la famille ou du foyer, non rattaché à un membre en particulier, ni à un logement ou un véhicule spécifique : résiliation, modification, attestation d''assurance voyage, relevé annuel protection juridique.',
     'Famille/Commun/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[title]',
     0, 1);
