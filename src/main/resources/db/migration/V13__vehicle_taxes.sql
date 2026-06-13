INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES
    (27, 'Taxes véhicule',
     'Le document est une taxe ou un impôt lié à un véhicule : malus écologique, taxe à l''essieu, vignette Crit''Air, amendes (PV), taxes régionales liées à l''immatriculation.',
     'Vehicules/[modele]-[immatriculation]/Taxes/[yyyy]/[document_type]-[title]',
     0, 1);
