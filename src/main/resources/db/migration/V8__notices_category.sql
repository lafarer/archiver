-- Add product category custom field for notices
INSERT INTO custom_field_def (slug, label, description, field_type) VALUES
    ('categorie_produit', 'Catégorie produit',
     'Catégorie du produit concerné par la notice ou le manuel. Choisir parmi : electromenager (lave-linge, lave-vaisselle, réfrigérateur, four, hotte…), electronique (TV, hi-fi, casque, enceinte, appareil photo…), informatique (ordinateur, imprimante, routeur, disque dur, écran…), outillage (perceuse, scie, compresseur, outillage de jardin motorisé…), mobilier (meuble, luminaire, store, volet…), jardin (tondeuse manuelle, barbecue, mobilier de jardin…), vehicule (voiture, vélo, trottinette, accessoire auto…), autre (tout ce qui ne rentre pas dans les catégories précédentes).',
     'TEXT');

-- Update notices storage rule to classify by category then manufacturer
UPDATE storage_path_rule
SET path_template = 'Notices/[categorie_produit]/[issuer]/[modele?]-[title]'
WHERE label = 'Notices d''utilisation';
