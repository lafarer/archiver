UPDATE storage_path_rule
SET label          = 'Entretiens et contrôles logement',
    condition_nl   = 'Le document est un rapport, un certificat ou une facture d''entretien ou de contrôle lié à un logement : entretien de chaudière, ramonage de cheminée, vérification VMC, contrôle installation gaz, contrôle installation électrique, désinsectisation.',
    path_template  = 'Logements/[adresse_bien]/Entretiens-et-controles/[document_type]-[title]'
WHERE id = 24;
