UPDATE custom_field_def
SET description = 'Numéro de modèle ou référence commerciale du produit concerné par le document (appareil électroménager, électronique, outil, meuble, équipement médical…). S''applique aux notices, garanties, factures d''achat, réparations et bons de commande. Exemples : WH-1000XM5, KitchenAid 5KSM175, Bosch WAT28640.'
WHERE slug = 'modele';
