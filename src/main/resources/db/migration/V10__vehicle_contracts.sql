INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES
    (26, 'Contrats véhicule',
     'Le document est un contrat lié à l''acquisition ou à l''usage d''un véhicule : contrat de vente, bon de commande, contrat de leasing, LOA (location avec option d''achat), LLD (location longue durée), contrat de financement ou crédit auto.',
     'Vehicules/[modele]-[immatriculation]/Contrats/[yyyy]-[title]',
     0, 1);
