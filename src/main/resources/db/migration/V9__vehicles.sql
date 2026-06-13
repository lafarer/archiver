-- 1. Update modele field to cover vehicles (brand + model)
UPDATE custom_field_def
SET description = 'Numéro de modèle, référence commerciale ou désignation du produit ou du véhicule concerné. Pour les appareils : WH-1000XM5, KitchenAid 5KSM175, Bosch WAT28640. Pour les véhicules, indiquer la marque ET le modèle : Renault Clio 5, Volkswagen Golf 7, BMW X3. S''applique aux notices, garanties, factures d''achat, réparations, entretien et tous documents liés à un véhicule ou un appareil.'
WHERE slug = 'modele';

-- 2. Add type_assurance custom field
INSERT INTO custom_field_def (slug, label, description, field_type) VALUES
    ('type_assurance', 'Type d''assurance',
     'Formule ou catégorie d''assurance. Pour les véhicules : responsabilite-civile, tiers-etendu, tous-risques. Pour les autres : habitation, multirisque, vie, prevoyance, sante, pret. Utiliser un slug kebab-case sans accents.',
     'TEXT');

-- 3. Vehicle-specific document types
INSERT OR IGNORE INTO document_type_def (slug, label, description) VALUES
    ('carte-grise',
     'Carte grise / Certificat d''immatriculation',
     'Document officiel attestant de l''immatriculation d''un véhicule et de l''identité de son propriétaire.'),
    ('controle-technique',
     'Contrôle technique',
     'Rapport de contrôle technique périodique obligatoire, incluant les points de contrôle, défauts constatés et date de validité.'),
    ('constat-amiable',
     'Constat amiable',
     'Formulaire rempli entre conducteurs suite à un accident, utilisé pour la déclaration de sinistre auprès des assurances.'),
    ('rapport-expertise',
     'Rapport d''expertise véhicule',
     'Rapport d''un expert automobile évaluant les dégâts ou la valeur du véhicule, notamment après sinistre.');

-- 4. Storage path rules for vehicles
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    (20, 'Assurances véhicule — Contrats et polices',
     'Le document est un contrat d''assurance, une police, une attestation d''assurance, un certificat d''assurance ou un avis d''échéance pour un véhicule automobile, moto ou véhicule motorisé.',
     'Vehicules/[modele]-[immatriculation]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]',
     0, 1),

    (21, 'Assurances véhicule — Courriers',
     'Le document est un courrier, une lettre ou une notification émanant d''une compagnie d''assurance et concernant un véhicule : résiliation, modification de contrat, relevé d''informations, réponse à réclamation.',
     'Vehicules/[modele]-[immatriculation]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[title]',
     0, 1),

    (22, 'Documents officiels véhicule',
     'Le document est un document administratif ou officiel propre à un véhicule : carte grise, certificat d''immatriculation, contrôle technique, certificat de conformité.',
     'Vehicules/[modele]-[immatriculation]/Documents/[document_type]-[title]',
     0, 1),

    (23, 'Entretien et réparations véhicule',
     'Le document est une facture, un bon de commande ou un bon de travaux relatif à l''entretien, la révision, la maintenance ou la réparation d''un véhicule (garage, concessionnaire, pneumaticien, carrossier…).',
     'Vehicules/[modele]-[immatriculation]/Entretien/[yyyy]/[issuer]-[title]',
     0, 1),

    (24, 'Garanties véhicule',
     'Le document est une garantie constructeur, une extension de garantie ou un certificat de garantie portant sur un véhicule ou des pièces automobiles.',
     'Vehicules/[modele]-[immatriculation]/Garanties/[issuer?]-[title]',
     0, 1),

    (25, 'Sinistres véhicule',
     'Le document est lié à un sinistre automobile : constat amiable, déclaration de sinistre, rapport d''expertise, courrier d''assurance relatif à un accident ou dommage subi par un véhicule.',
     'Vehicules/[modele]-[immatriculation]/Sinistres/[yyyy]/[title]',
     0, 1);
