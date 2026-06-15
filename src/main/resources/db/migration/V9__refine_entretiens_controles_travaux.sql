UPDATE storage_path_rule
SET condition_nl  = 'Le document est un rapport, un certificat, une attestation ou une facture relatif à un entretien obligatoire ou à un contrôle par un organisme certificateur pour un logement. Entretiens obligatoires : entretien annuel de chaudière, ramonage de cheminée, vérification VMC, désinsectisation, dératisation. Contrôles certificateurs : certificat PEB (performance énergétique), contrôle conformité installation électrique (CERGA, Vinçotte, AIB-Vinçotte…), contrôle installation gaz, diagnostic amiante, diagnostic plomb. Ne concerne PAS les travaux de rénovation, d''aménagement ou de réparation non-obligatoires.',
    path_template = 'Logements/[adresse_bien]/Entretiens-et-controles/[yyyy]/[document_type]-[title]'
WHERE id = 24;

UPDATE storage_path_rule
SET condition_nl  = 'Le document est une facture, un devis, un bon de commande ou un permis lié à des travaux non-obligatoires dans un logement : rénovation, aménagement, construction, extension, second œuvre (plomberie, électricité, peinture, carrelage, menuiserie…). Exclure les entretiens obligatoires (chaudière, ramonage, VMC) et les contrôles par organismes certificateurs (PEB, électricité, gaz, amiante, plomb) qui relèvent de la règle "Entretiens et contrôles logement".'
WHERE id = 27;
