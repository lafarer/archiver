-- 1. Extend Famille — Identité rule to include electoral documents
UPDATE storage_path_rule
SET condition_nl = 'Le document est un document d''identité officiel ou électoral nominatif d''un membre de la famille : carte nationale d''identité, passeport, permis de conduire, acte de naissance, acte de mariage, livret de famille, titre de séjour, carte d''électeur, procuration de vote.'
WHERE priority = 41;

-- 2. Storage path rules for personal services under Famille (priorities 53-54)
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    (53, 'Famille — Services personnels : contrats',
     'Le document est un contrat ou un abonnement de service personnel d''un membre de la famille, non lié à un logement : téléphonie mobile, abonnement internet mobile, abonnement de streaming (TV, musique, jeux), abonnement de presse ou magazine, abonnement sportif ou culturel.',
     'Famille/[membre_famille]/Services/[issuer]/Contrats/[title]',
     0, 1),

    (54, 'Famille — Services personnels : factures',
     'Le document est une facture ou un relevé de consommation lié à un service personnel d''un membre de la famille, non lié à un logement : facture de téléphonie mobile, facture d''abonnement streaming, reçu d''abonnement en ligne.',
     'Famille/[membre_famille]/Services/[issuer]/Factures/[yyyy]/[mm]-[title]',
     0, 1);

-- 3. Catch-all rule for miscellaneous administrative documents (priority 80)
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    (80, 'Administratif — Divers',
     'Le document est un courrier ou document officiel émanant d''un organisme public ou administratif (préfecture, mairie, ministère, tribunal, organisme de sécurité sociale) et non couvert par une règle plus spécifique : autorisation administrative, déclaration diverse, notification officielle, correspondance avec une administration.',
     'Administratif/[yyyy]/[issuer]-[title]',
     0, 1);
