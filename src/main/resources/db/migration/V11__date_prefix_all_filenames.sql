-- Add [yyyy]-[mm?]-[dd?]- prefix to the filename (last path segment) of all
-- storage path rules that did not already have it.
-- Rule 20 (Actes notariés logement) and rule 60 (Notices) are left unchanged.

-- -------------------------------------------------------------------------
-- VÉHICULES (10-17)
-- -------------------------------------------------------------------------

UPDATE storage_path_rule SET path_template =
    'Vehicules/[modele]-[immatriculation]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 10;

UPDATE storage_path_rule SET path_template =
    'Vehicules/[modele]-[immatriculation]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 11;

UPDATE storage_path_rule SET path_template =
    'Vehicules/[modele]-[immatriculation]/Documents/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 12;

UPDATE storage_path_rule SET path_template =
    'Vehicules/[modele]-[immatriculation]/Entretien/[yyyy]/[yyyy]-[mm?]-[dd?]-[issuer]-[title]'
WHERE priority = 13;

UPDATE storage_path_rule SET path_template =
    'Vehicules/[modele]-[immatriculation]/Garanties/[yyyy]-[mm?]-[dd?]-[issuer?]-[title]'
WHERE priority = 14;

UPDATE storage_path_rule SET path_template =
    'Vehicules/[modele]-[immatriculation]/Sinistres/[yyyy]/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 15;

UPDATE storage_path_rule SET path_template =
    'Vehicules/[modele]-[immatriculation]/Contrats/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 16;

UPDATE storage_path_rule SET path_template =
    'Vehicules/[modele]-[immatriculation]/Taxes/[yyyy]/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 17;

-- -------------------------------------------------------------------------
-- LOGEMENTS (21-28) — rule 20 already correct, skipped
-- -------------------------------------------------------------------------

UPDATE storage_path_rule SET path_template =
    'Logements/[adresse_bien]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 21;

UPDATE storage_path_rule SET path_template =
    'Logements/[adresse_bien]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 22;

UPDATE storage_path_rule SET path_template =
    'Logements/[adresse_bien]/Contrats/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 23;

UPDATE storage_path_rule SET path_template =
    'Logements/[adresse_bien]/Entretiens-et-controles/[yyyy]/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 24;

UPDATE storage_path_rule SET path_template =
    'Logements/[adresse_bien]/Factures/[categorie_facture]/[yyyy]/[yyyy]-[mm?]-[dd?]-[issuer]-[title]'
WHERE priority = 25;

UPDATE storage_path_rule SET path_template =
    'Logements/[adresse_bien]/Taxes/[yyyy]/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 26;

UPDATE storage_path_rule SET path_template =
    'Logements/[adresse_bien]/Travaux/[yyyy]/[yyyy]-[mm?]-[dd?]-[issuer]-[title]'
WHERE priority = 27;

UPDATE storage_path_rule SET path_template =
    'Logements/[adresse_bien]/Sinistres/[yyyy]/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 28;

-- -------------------------------------------------------------------------
-- FAMILLE - PAR MEMBRE (30-42)
-- -------------------------------------------------------------------------

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Emploi/Fiches-de-paie/[yyyy]/[yyyy]-[mm?]-[dd?]-[issuer]'
WHERE priority = 30;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Identite/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 31;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Sante/[yyyy]/[yyyy]-[mm?]-[dd?]-[document_type]-[issuer?]-[title]'
WHERE priority = 32;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Education/[document_type]/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 33;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Emploi/Contrats/[yyyy]-[mm?]-[dd?]-[issuer]-[title]'
WHERE priority = 34;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Emploi/Attestations/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 35;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Retraite/[yyyy]/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 36;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Juridique/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 37;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Allocations/[yyyy]/[yyyy]-[mm?]-[dd?]-[issuer]-[title]'
WHERE priority = 38;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 39;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 40;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Services/[issuer]/Contrats/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 41;

UPDATE storage_path_rule SET path_template =
    'Famille/[membre_famille]/Services/[issuer]/Factures/[yyyy]/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 42;

-- -------------------------------------------------------------------------
-- FAMILLE - COMMUN (45-46)
-- -------------------------------------------------------------------------

UPDATE storage_path_rule SET path_template =
    'Famille/Commun/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 45;

UPDATE storage_path_rule SET path_template =
    'Famille/Commun/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 46;

-- -------------------------------------------------------------------------
-- FINANCES (50-55)
-- -------------------------------------------------------------------------

UPDATE storage_path_rule SET path_template =
    'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Releves/[yyyy]/[yyyy]-[mm?]-[dd?]-[issuer]'
WHERE priority = 50;

UPDATE storage_path_rule SET path_template =
    'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Contrats/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 51;

UPDATE storage_path_rule SET path_template =
    'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Courriers/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 52;

UPDATE storage_path_rule SET path_template =
    'Finances/Banque/[nom_banque]/Courriers/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 53;

UPDATE storage_path_rule SET path_template =
    'Finances/Impots/[yyyy]/IR/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 54;

UPDATE storage_path_rule SET path_template =
    'Finances/Impots/[yyyy]/[yyyy]-[mm?]-[dd?]-[document_type]-[title]'
WHERE priority = 55;

-- -------------------------------------------------------------------------
-- ACHATS (70-71)
-- -------------------------------------------------------------------------

UPDATE storage_path_rule SET path_template =
    'Achats/[categorie_produit]/[yyyy]-[mm?]-[dd?]-[issuer]-[title]'
WHERE priority = 70;

UPDATE storage_path_rule SET path_template =
    'Achats/[categorie_produit]/Garanties/[yyyy]-[mm?]-[dd?]-[title]'
WHERE priority = 71;

-- -------------------------------------------------------------------------
-- ADMINISTRATIF (80)
-- -------------------------------------------------------------------------

UPDATE storage_path_rule SET path_template =
    'Administratif/[yyyy]/[yyyy]-[mm?]-[dd?]-[issuer]-[title]'
WHERE priority = 80;
