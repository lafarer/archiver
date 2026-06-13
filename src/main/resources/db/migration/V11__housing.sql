-- 1. Update adresse_bien: encourage short identifiable form for use as folder name
UPDATE custom_field_def
SET description = 'Identifiant court et unique du bien immobilier, utilisé comme nom de dossier. Préférer une forme concise et sans ambiguïté : ville-rue-numero (ex: paris-11-rue-oberkampf, nice-promenade-des-anglais-06, lyon-appartement-bellecour). S''applique aux baux, actes de vente, taxes foncières, factures de logement et diagnostics.'
WHERE slug = 'adresse_bien';

-- 2. Add categorie_facture custom field
INSERT INTO custom_field_def (slug, label, description, field_type) VALUES
    ('categorie_facture', 'Catégorie de facture',
     'Catégorie du service ou de la prestation facturée, pour le classement des factures de logement. Valeurs possibles : eau, electricite, gaz, energie (électricité+gaz combinés), internet, telephone, charges-copropriete, autre. Utiliser un slug kebab-case sans accents.',
     'TEXT');

-- 3. Housing-specific document types
INSERT OR IGNORE INTO document_type_def (slug, label, description) VALUES
    ('bail',
     'Bail / Contrat de location',
     'Contrat de location d''un bien immobilier entre un propriétaire et un locataire, incluant ses avenants et renouvellements.'),
    ('etat-des-lieux',
     'État des lieux',
     'Document constatant l''état d''un logement à l''entrée ou à la sortie d''un locataire.'),
    ('diagnostic-immobilier',
     'Diagnostic immobilier',
     'Diagnostic technique obligatoire d''un bien immobilier : DPE, amiante, plomb, électricité, gaz, termites, ERP, bruit.'),
    ('acte-notarie',
     'Acte notarié',
     'Document établi par un notaire : acte de vente, acte d''achat, donation, hypothèque, compromis de vente.'),
    ('permis-de-construire',
     'Permis de construire / Déclaration de travaux',
     'Autorisation administrative pour des travaux de construction, d''extension ou de rénovation.'),
    ('proces-verbal-ag',
     'Procès-verbal d''assemblée générale',
     'Compte-rendu d''une assemblée générale de copropriété, incluant les décisions votées et les budgets approuvés.');

-- 4. Storage path rules for housing
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    (30, 'Actes notariés logement',
     'Le document est un acte notarié ou un document juridique lié à un bien immobilier : acte de vente, acte d''achat, compromis de vente, donation, hypothèque, titre de propriété.',
     'Logements/[adresse_bien]/Actes/[yyyy]-[title]',
     0, 1),

    (31, 'Assurances logement — Contrats et polices',
     'Le document est un contrat d''assurance habitation, une police multirisque habitation, une assurance propriétaire non-occupant (PNO), une attestation d''assurance logement ou un avis d''échéance pour un bien immobilier. Ne concerne pas les véhicules.',
     'Logements/[adresse_bien]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]',
     0, 1),

    (32, 'Assurances logement — Courriers',
     'Le document est un courrier, une lettre ou une notification d''une compagnie d''assurance concernant un logement ou bien immobilier : résiliation, modification de contrat, réponse à réclamation. Ne concerne pas les véhicules.',
     'Logements/[adresse_bien]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[title]',
     0, 1),

    (33, 'Contrats logement',
     'Le document est un contrat lié à un logement ou bien immobilier : bail de location, contrat de syndic, règlement de copropriété, mandat de gestion locative, état des lieux.',
     'Logements/[adresse_bien]/Contrats/[yyyy]-[title]',
     0, 1),

    (34, 'Entretiens obligatoires logement',
     'Le document est un rapport, un certificat ou une facture d''entretien obligatoire lié à un logement : entretien de chaudière, ramonage de cheminée, vérification VMC, contrôle installation gaz, contrôle installation électrique, désinsectisation.',
     'Logements/[adresse_bien]/Entretiens-obligatoires/[document_type]-[title]',
     0, 1),

    (35, 'Factures logement',
     'Le document est une facture liée à la consommation ou aux services d''un logement : eau, électricité, gaz, énergie, internet, téléphone fixe, charges de copropriété. Exclure les factures de travaux.',
     'Logements/[adresse_bien]/Factures/[categorie_facture]/[yyyy]/[issuer]-[title]',
     0, 1),

    (36, 'Taxes logement',
     'Le document est une taxe ou un impôt lié à un bien immobilier : taxe foncière, taxe d''habitation, taxe sur les logements vacants, cotisation foncière.',
     'Logements/[adresse_bien]/Taxes/[yyyy]/[document_type]-[title]',
     0, 1),

    (37, 'Travaux logement',
     'Le document est une facture, un devis, un bon de commande ou un permis lié à des travaux dans un logement : rénovation, aménagement, construction, extension, second œuvre (plomberie, électricité, peinture, carrelage…).',
     'Logements/[adresse_bien]/Travaux/[yyyy]/[issuer]-[title]',
     0, 1),

    (38, 'Sinistres logement',
     'Le document est lié à un sinistre dans un logement : déclaration de sinistre, constat de dégât des eaux, rapport d''expertise, courrier d''assurance relatif à un sinistre (incendie, dégât des eaux, vol, bris de glace…).',
     'Logements/[adresse_bien]/Sinistres/[yyyy]/[title]',
     0, 1);
