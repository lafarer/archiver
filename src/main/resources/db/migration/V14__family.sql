-- 1. Update membre_famille with known family members for consistent normalization
UPDATE custom_field_def
SET description = 'Prénom normalisé du membre de la famille directement concerné par le document. Membres connus : Emmanuelle, Eric, Camille, Eliott. Utiliser TOUJOURS l''un de ces prénoms s''il correspond à la personne mentionnée sur le document, en respectant exactement la casse (première lettre majuscule). Si la personne n''est pas dans cette liste, utiliser son prénom tel qu''il apparaît. Ne renseigner que si le document est clairement nominatif pour une personne spécifique.'
WHERE slug = 'membre_famille';

-- 2. Family-specific document types
INSERT OR IGNORE INTO document_type_def (slug, label, description) VALUES
    ('bulletin-scolaire',
     'Bulletin scolaire',
     'Bulletin de notes scolaires ou relevé de résultats semestriel ou trimestriel.'),
    ('certificat-scolarite',
     'Certificat de scolarité',
     'Attestation d''inscription dans un établissement scolaire ou universitaire pour une année donnée.'),
    ('carte-identite',
     'Carte nationale d''identité',
     'Carte nationale d''identité française, recto ou recto-verso.'),
    ('acte-naissance',
     'Acte de naissance',
     'Acte de naissance officiel délivré par une mairie ou un consulat.'),
    ('acte-mariage',
     'Acte de mariage',
     'Acte de mariage officiel délivré par une mairie.'),
    ('jugement',
     'Jugement / Décision de justice',
     'Décision rendue par un tribunal : jugement de divorce, ordonnance, décision prud''homale, jugement civil.'),
    ('attestation-secu',
     'Attestation Sécurité Sociale / Carte Vitale',
     'Attestation de droits à l''Assurance Maladie ou document relatif à la carte Vitale.'),
    ('remboursement-sante',
     'Remboursement santé',
     'Décompte de remboursement de l''Assurance Maladie (CPAM) ou de la mutuelle complémentaire.'),
    ('contrat-travail',
     'Contrat de travail',
     'Contrat de travail à durée déterminée (CDD), indéterminée (CDI), ou avenant au contrat.'),
    ('attestation-emploi',
     'Attestation employeur / Certificat de travail',
     'Attestation de l''employeur, certificat de travail, solde de tout compte, ou attestation Pôle Emploi.'),
    ('notification-retraite',
     'Notification / Relevé de retraite',
     'Notification de droits à la retraite, relevé de carrière, ou bulletin de pension de retraite.');

-- 3. Storage path rules for family members (priorities 40-52)
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    (40, 'Famille — Éducation',
     'Le document concerne l''éducation ou la formation d''un membre de la famille : diplôme, bulletin scolaire, certificat de scolarité, résultats d''examens, relevé de notes universitaire, attestation de formation professionnelle, titre certifiant.',
     'Famille/[membre_famille]/Education/[document_type]/[yyyy]-[title]',
     0, 1),

    (41, 'Famille — Identité',
     'Le document est un document d''identité officiel d''un membre de la famille : carte nationale d''identité, passeport, permis de conduire, acte de naissance, acte de mariage, livret de famille, titre de séjour.',
     'Famille/[membre_famille]/Identite/[document_type]-[title]',
     0, 1),

    (42, 'Famille — Santé',
     'Le document concerne la santé d''un membre de la famille : ordonnance, résultat d''analyse ou d''examen médical, compte-rendu de consultation ou d''hospitalisation, remboursement Sécurité Sociale ou mutuelle, attestation de droits, carnet de vaccination.',
     'Famille/[membre_famille]/Sante/[yyyy]/[document_type]-[issuer?]-[title]',
     0, 1),

    (43, 'Famille — Emploi : fiches de paie',
     'Le document est une fiche de paie ou un bulletin de salaire d''un membre de la famille.',
     'Famille/[membre_famille]/Emploi/Fiches-de-paie/[yyyy]/[mm]-[issuer]',
     0, 1),

    (44, 'Famille — Emploi : contrats',
     'Le document est un contrat de travail, un avenant ou une promesse d''embauche d''un membre de la famille.',
     'Famille/[membre_famille]/Emploi/Contrats/[yyyy]-[issuer]-[title]',
     0, 1),

    (45, 'Famille — Emploi : attestations',
     'Le document est une attestation liée à l''emploi d''un membre de la famille : attestation employeur, certificat de travail, solde de tout compte, rupture conventionnelle, attestation Pôle Emploi, ARE.',
     'Famille/[membre_famille]/Emploi/Attestations/[yyyy]-[title]',
     0, 1),

    (46, 'Famille — Retraite et pension',
     'Le document concerne la retraite ou la pension d''un membre de la famille : relevé de carrière, notification de droits à la retraite, bulletin de pension, estimation retraite, relevé de points.',
     'Famille/[membre_famille]/Retraite/[yyyy]/[document_type]-[title]',
     0, 1),

    (47, 'Famille — Juridique',
     'Le document est un acte ou document juridique nominatif concernant un membre de la famille : acte de mariage, jugement de divorce, PACS, jugement civil ou prud''homal, procuration, testament, pension alimentaire.',
     'Famille/[membre_famille]/Juridique/[yyyy]-[document_type]-[title]',
     0, 1),

    (48, 'Famille — Allocations',
     'Le document concerne des allocations ou aides sociales pour un membre de la famille : allocations familiales CAF, RSA, prime d''activité, aide au logement, ARE (chômage), allocation adulte handicapé.',
     'Famille/[membre_famille]/Allocations/[yyyy]/[issuer]-[title]',
     0, 1),

    (49, 'Famille — Assurances personnelles : contrats',
     'Le document est un contrat d''assurance personnelle d''un membre de la famille non liée à un logement ou véhicule : assurance vie, prévoyance individuelle, complémentaire santé (mutuelle), garantie accidents de la vie.',
     'Famille/[membre_famille]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]',
     0, 1),

    (50, 'Famille — Assurances personnelles : courriers',
     'Le document est un courrier ou une notification d''une assurance personnelle d''un membre de la famille non liée à un logement ou véhicule : résiliation, modification, relevé annuel, attestation.',
     'Famille/[membre_famille]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[title]',
     0, 1);
