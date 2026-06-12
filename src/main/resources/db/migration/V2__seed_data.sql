-- Default settings
INSERT INTO setting (key, value) VALUES
    ('watchdog_enabled',     'false'),
    ('ai_model',             'claude-sonnet-4-6'),
    ('auto_archive_enabled', 'false'),
    ('confidence_threshold', '0.75'),
    ('import_mode',          'copy');

-- Document types
INSERT INTO document_type_def (slug, label, description) VALUES
    -- Finances
    ('facture',            'Facture',                     'Facture commerciale pour l''achat de biens ou services. Contient un numéro de facture, une date, un montant TTC et un émetteur.'),
    ('releve-bancaire',    'Relevé bancaire',             'Relevé de compte bancaire ou d''épargne listant les opérations débit/crédit sur une période.'),
    ('virement',           'Avis de virement',            'Confirmation d''un virement bancaire entrant ou sortant.'),
    ('recu',               'Reçu / Ticket de caisse',     'Justificatif de paiement, ticket de caisse ou reçu émis par un commerçant.'),
    ('quittance',          'Quittance',                   'Quittance de loyer ou de paiement attestant la réception d''un règlement.'),
    ('devis',              'Devis',                       'Proposition commerciale détaillant prestations et prix avant commande.'),
    ('bon-de-commande',    'Bon de commande',             'Document formalisant une commande de biens ou services auprès d''un fournisseur.'),
    ('avoir',              'Avoir / Note de crédit',      'Note de crédit émise par un fournisseur, remboursement partiel ou total d''une facture.'),
    -- Impôts & administration
    ('avis-imposition',        'Avis d''imposition',          'Avis d''imposition sur le revenu émis par les impôts. Contient le montant à payer et le revenu fiscal de référence.'),
    ('declaration-impots',     'Déclaration de revenus',      'Formulaire de déclaration annuelle des revenus (2042, 2044…).'),
    ('taxe-fonciere',          'Taxe foncière',               'Avis de taxe foncière pour un bien immobilier.'),
    ('taxe-habitation',        'Taxe d''habitation',          'Avis de taxe d''habitation pour une résidence.'),
    ('courrier-administratif', 'Courrier administratif',      'Courrier officiel d''un organisme public (CAF, CPAM, Pôle Emploi, mairie, préfecture…).'),
    ('formulaire',             'Formulaire administratif',    'Formulaire à remplir ou déjà complété (Cerfa, demande de prestation…).'),
    -- Contrats & assurances
    ('contrat',               'Contrat',                     'Contrat entre deux parties (service, abonnement, location…).'),
    ('avenant',               'Avenant',                     'Modification ou complément à un contrat existant.'),
    ('attestation-assurance', 'Attestation d''assurance',    'Attestation prouvant la souscription d''une assurance (auto, habitation, RC…).'),
    ('police-assurance',      'Police d''assurance',         'Contrat d''assurance complet détaillant les garanties, franchises et cotisations.'),
    ('resiliation',           'Résiliation',                 'Lettre ou confirmation de résiliation d''un contrat ou abonnement.'),
    ('garantie',              'Garantie',                    'Certificat ou bon de garantie pour un appareil ou produit acheté.'),
    -- Santé
    ('ordonnance',           'Ordonnance médicale',          'Prescription médicale d''un médecin pour des médicaments ou actes médicaux.'),
    ('compte-rendu-medical', 'Compte rendu médical',         'Compte rendu de consultation, d''hospitalisation ou d''examen médical (radio, scanner…).'),
    ('remboursement-sante',  'Remboursement santé',          'Décompte de remboursement de l''Assurance Maladie (CPAM) ou d''une mutuelle.'),
    ('mutuelle',             'Mutuelle / Complémentaire',    'Contrat ou attestation de complémentaire santé (mutuelle).'),
    ('vaccination',          'Carnet de vaccination',        'Attestation ou carnet de vaccination.'),
    ('analyse',              'Résultats d''analyse',         'Résultats d''analyses biologiques, radiologiques ou autres examens.'),
    -- Emploi & revenus
    ('fiche-de-paie',      'Fiche de paie',                'Bulletin de salaire mensuel. Contient salaire brut, cotisations, net à payer, IBAN et informations employeur.'),
    ('contrat-travail',    'Contrat de travail',           'Contrat d''embauche (CDI, CDD, apprentissage…).'),
    ('rupture-contrat',    'Rupture de contrat',           'Lettre ou solde de tout compte lié à une rupture conventionnelle, démission ou licenciement.'),
    ('attestation-emploi', 'Attestation d''emploi',        'Certificat de travail ou attestation employeur prouvant une activité salariée.'),
    ('attestation-chomage','Attestation chômage',          'Attestation d''ouverture de droits ou de versement d''allocations chômage (France Travail).'),
    ('bilan-formation',    'Formation / Certification',    'Attestation de formation professionnelle, bilan de compétences ou certification.'),
    -- Logement
    ('bail',               'Bail / Contrat de location',  'Contrat de location d''un logement ou local commercial.'),
    ('etat-des-lieux',     'État des lieux',               'État des lieux d''entrée ou de sortie d''un logement loué.'),
    ('quittance-loyer',    'Quittance de loyer',           'Reçu mensuel confirmant le paiement du loyer par le locataire.'),
    ('acte-vente',         'Acte de vente immobilier',     'Acte notarié formalisant la vente ou l''achat d''un bien immobilier.'),
    ('diagnostic',         'Diagnostic immobilier',        'Rapport de diagnostic technique (DPE, amiante, électricité, plomb…).'),
    ('permis-construire',  'Permis de construire',         'Autorisation administrative pour des travaux ou constructions.'),
    ('pv-assemblee',       'PV d''assemblée générale',     'Procès-verbal d''assemblée générale de copropriété.'),
    -- Identité & famille
    ('identite',      'Carte d''identité',              'Document officiel d''identité nationale ou titre de séjour.'),
    ('passeport',     'Passeport',                      'Passeport ou document de voyage officiel.'),
    ('diplome',       'Diplôme / Attestation scolaire', 'Diplôme officiel (bac, licence, master…) ou relevé de notes.'),
    ('acte-naissance','Acte de naissance',              'Acte d''état civil certifiant une naissance.'),
    ('acte-mariage',  'Acte de mariage / PACS',         'Acte d''état civil certifiant un mariage ou un PACS.'),
    ('livret-famille','Livret de famille',              'Document officiel récapitulant l''état civil d''une famille.'),
    ('jugement',      'Jugement / Décision de justice', 'Décision ou jugement rendu par un tribunal ou une autorité administrative.'),
    -- Véhicule
    ('carte-grise',        'Carte grise',           'Certificat d''immatriculation d''un véhicule.'),
    ('controle-technique', 'Contrôle technique',    'Rapport de contrôle technique périodique d''un véhicule.'),
    ('assurance-auto',     'Assurance automobile',  'Contrat ou attestation d''assurance pour un véhicule.'),
    ('facture-reparation', 'Facture de réparation', 'Facture d''un garage ou prestataire pour l''entretien ou la réparation d''un véhicule.');

-- Tags
INSERT INTO tag_def (slug, label, description) VALUES
    -- Énergie & logement
    ('eau',           'Eau',                    'Factures et contrats liés à la consommation d''eau.'),
    ('electricite',   'Électricité',            'Factures et contrats d''électricité.'),
    ('gaz',           'Gaz',                    'Factures et contrats de gaz.'),
    ('internet',      'Internet / Box',         'Factures et contrats internet ou téléphone fixe.'),
    ('telephone',     'Téléphone mobile',       'Factures et contrats de téléphonie mobile.'),
    ('logement',      'Logement',               'Documents liés à l''habitation : loyer, charges, copropriété.'),
    -- Travaux & équipement
    ('travaux',       'Travaux',                'Devis, factures et autorisations de travaux ou rénovation.'),
    ('entretien',     'Entretien',              'Contrats et factures d''entretien (chaudière, climatisation, ascenseur…).'),
    ('reparation',    'Réparation',             'Factures de réparation d''appareils, véhicules ou équipements.'),
    ('electromenager','Électroménager',         'Documents liés aux appareils électroménagers (achat, garantie, réparation).'),
    ('electronique',  'Électronique',           'Documents liés aux appareils électroniques (ordinateur, téléphone, TV…).'),
    ('mobilier',      'Mobilier',               'Documents liés aux meubles et à la décoration intérieure.'),
    ('outillage',     'Outillage',              'Documents liés aux outils, machines et matériel de bricolage.'),
    -- Véhicule
    ('vehicule',      'Véhicule',               'Documents liés aux véhicules : voiture, moto, vélo, scooter.'),
    -- Finances
    ('banque',        'Banque',                 'Relevés, virements, prélèvements et documents bancaires.'),
    ('impots',        'Impôts',                 'Déclarations, avis d''imposition et documents fiscaux.'),
    ('assurance',     'Assurance',              'Contrats, attestations, cotisations et remboursements d''assurance.'),
    ('credit',        'Crédit / Prêt',          'Contrats de prêt immobilier ou à la consommation, tableaux d''amortissement.'),
    ('epargne',       'Épargne / Investissement','Relevés de comptes d''épargne, PEA, assurance-vie, livrets.'),
    -- Santé
    ('sante',         'Santé',                  'Documents médicaux : ordonnances, comptes rendus, bilans, analyses.'),
    ('mutuelle',      'Mutuelle',               'Documents de complémentaire santé : contrats, décomptes, attestations.'),
    -- Famille & administration
    ('famille',       'Famille',                'Documents d''état civil et actes familiaux (naissance, mariage, divorce…).'),
    ('juridique',     'Juridique',              'Contrats, jugements, décisions de justice et documents légaux.'),
    ('administratif', 'Administratif',          'Courriers et formulaires d''organismes publics (CAF, CPAM, mairie…).'),
    ('sinistre',      'Sinistre',               'Documents liés à un sinistre : déclaration, expertise, remboursement assurance.'),
    -- Loisirs & autres
    ('voyage',        'Voyage',                 'Billets, réservations, hébergements et documents de voyage.'),
    ('abonnement',    'Abonnement',             'Contrats et factures d''abonnements divers (streaming, sport, presse…).');
