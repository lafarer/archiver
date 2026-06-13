-- Document type
INSERT INTO document_type_def (slug, label, description) VALUES
    ('notice', 'Notice / Manuel d''utilisation',
     'Notice d''utilisation, manuel d''installation ou guide de démarrage rapide fourni avec un appareil, un meuble ou un outil. Contient des instructions d''utilisation, des schémas ou des spécifications techniques.');

-- Custom field
INSERT INTO custom_field_def (slug, label, description, field_type) VALUES
    ('modele', 'Modèle / Référence produit',
     'Numéro de modèle ou référence commerciale du produit concerné par la notice ou la garantie (ex: WH-1000XM5, KitchenAid 5KSM175). Permet de distinguer plusieurs notices d''un même fabricant.',
     'TEXT');

-- Storage path rule
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES
    (10, 'Notices d''utilisation',
     'Le document est une notice d''utilisation, un manuel d''installation ou un guide de démarrage rapide accompagnant un produit (appareil électroménager, électronique, outil, meuble…).',
     'Notices/[issuer]/[modele?]-[title]',
     0, 1);
