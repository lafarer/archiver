-- 1. Update categorie_produit to cover both notices and purchases, add habillement
UPDATE custom_field_def
SET label = 'Catégorie produit / achat',
    description = 'Catégorie du produit concerné par la notice, la facture ou le ticket d''achat. Choisir parmi : electromenager (lave-linge, lave-vaisselle, réfrigérateur, four, hotte…), electronique (TV, hi-fi, casque, enceinte, appareil photo…), informatique (ordinateur, imprimante, routeur, disque dur, écran…), outillage (perceuse, scie, compresseur, outillage de jardin motorisé…), mobilier (meuble, luminaire, store, volet…), jardin (tondeuse manuelle, barbecue, mobilier de jardin…), vehicule (voiture, vélo, trottinette, accessoire auto…), bijoux-montres (bijou, montre, joaillerie…), habillement (vêtement, chaussure, accessoire vestimentaire…), sports-loisirs (équipement sportif, instrument de musique, jeu, loisir créatif…), autre (tout ce qui ne rentre pas dans les catégories précédentes).'
WHERE slug = 'categorie_produit';

-- 2. Purchase-specific document types
INSERT OR IGNORE INTO document_type_def (slug, label, description) VALUES
    ('ticket-caisse',
     'Ticket de caisse / Reçu',
     'Ticket de caisse ou reçu de paiement délivré au moment de l''achat, valant preuve d''achat.'),
    ('facture-achat',
     'Facture d''achat',
     'Facture détaillée émise par un commerçant ou un site marchand lors de l''achat d''un bien.'),
    ('bon-garantie',
     'Bon de garantie / Certificat de garantie',
     'Document attestant de la garantie constructeur ou légale d''un produit acheté.'),
    ('garantie-etendue',
     'Contrat de garantie étendue',
     'Contrat souscrit auprès d''un assureur ou d''un distributeur prolongeant la garantie d''origine d''un produit.');

-- 3. Storage path rules for purchases (priorities 70-71)
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    (70, 'Achats — Preuves d''achat',
     'Le document est une preuve d''achat d''un bien de consommation : ticket de caisse, reçu de paiement, facture d''achat, bon de commande livré. Concerne des biens matériels conservés pour leur valeur (électronique, électroménager, mobilier, bijoux, outillage, vêtements, équipements sportifs…). Exclure les factures de services (eau, électricité, téléphone, abonnements), les factures de travaux et les achats liés à un logement ou un véhicule.',
     'Achats/[categorie_produit]/[yyyy]-[issuer]-[title]',
     0, 1),

    (71, 'Achats — Garanties',
     'Le document est un bon de garantie, un certificat de garantie constructeur ou un contrat de garantie étendue pour un bien de consommation acheté.',
     'Achats/[categorie_produit]/Garanties/[yyyy]-[title]',
     0, 1);
