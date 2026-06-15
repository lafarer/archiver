INSERT INTO custom_field_def (slug, label, description, field_type) VALUES

    ('montant',
     'Montant TTC',
     'Montant total TTC du document (facture, devis, avoir, remboursement, quittance). Extraire la valeur numérique finale due ou remboursée.',
     'AMOUNT'),

    ('numero_facture',
     'Numéro de facture',
     'Numéro ou référence unique de la facture, de l''avoir ou du devis. Souvent libellé "N° facture", "Réf.", "Bon de commande n°".',
     'TEXT'),

    ('numero_contrat',
     'Numéro de contrat / police',
     'Numéro identifiant un contrat ou une police d''assurance. Peut être libellé "N° contrat", "N° police", "Référence contrat", "N° adhérent".',
     'TEXT'),

    ('date_echeance',
     'Date d''échéance',
     'Date d''échéance, de renouvellement ou de fin de validité du contrat, de l''assurance ou de la garantie.',
     'DATE'),

    ('immatriculation',
     'Immatriculation du véhicule',
     'Numéro d''immatriculation (plaque) du véhicule concerné par le document (carte grise, contrôle technique, assurance, réparation).',
     'TEXT'),

    ('adresse_bien',
     'Adresse du bien immobilier',
     'Identifiant normalisé et stable du bien immobilier, utilisé comme nom de dossier. RÈGLE DE NORMALISATION : [ville]-[type-de-voie]-[nom], en minuscules, sans numéro de rue, sans code postal, sans accent. Le type de voie (rue, avenue, boulevard, place, impasse, chaussee, cours, promenade, allee…) est TOUJOURS inclus — il fait partie du nom et lève les ambiguïtés (rue de la Republique ≠ place de la Republique). Le numéro et le code postal sont intentionnellement exclus car ils sont souvent absents ou dans un ordre variable selon les documents. Exemples : paris-rue-oberkampf, nice-promenade-des-anglais, lyon-place-de-la-republique, bordeaux-cours-victor-hugo, bruxelles-avenue-de-la-biqueterie, bruxelles-chaussee-de-wavre, bruxelles-place-condorcet, bruxelles-impasse-boileau. Si plusieurs biens sont dans la même ville sur la même voie, ajouter un discriminant minimal (ex: paris-rue-oberkampf-2eme). IMPORTANT : tous les documents d''un même bien doivent produire TOUJOURS le même identifiant, quelle que soit la façon dont l''adresse est écrite sur le document.',
     'TEXT'),

    ('annee_fiscale',
     'Année fiscale',
     'Année fiscale ou d''imposition concernée par le document (avis d''imposition, déclaration de revenus, taxe foncière, taxe d''habitation).',
     'NUMBER'),

    ('employeur',
     'Nom de l''employeur',
     'Nom ou raison sociale de l''employeur figurant sur le document (bulletin de salaire, contrat de travail, attestation d''emploi, rupture de contrat).',
     'TEXT'),

    ('medecin',
     'Praticien / établissement',
     'Nom du médecin prescripteur, du spécialiste ou de l''établissement de soin concerné par l''ordonnance, le compte rendu médical ou les résultats d''analyse.',
     'TEXT'),

    ('numero_dossier',
     'Numéro de dossier / référence',
     'Numéro de dossier, référence administrative ou identifiant attribué par un organisme public (CAF, CPAM, préfecture, tribunal) pour suivre une demande ou une procédure.',
     'TEXT'),

    ('membre_famille',
     'Membre de la famille',
     'Prénom normalisé du membre de la famille directement concerné par le document. Membres connus : Emmanuelle, Eric, Camille, Eliott. Utiliser TOUJOURS l''un de ces prénoms s''il correspond à la personne mentionnée sur le document, en respectant exactement la casse (première lettre majuscule). Si la personne n''est pas dans cette liste, utiliser son prénom tel qu''il apparaît. Ne renseigner que si le document est clairement nominatif pour une personne spécifique.',
     'TEXT'),

    ('modele',
     'Modèle / Référence produit',
     'Numéro de modèle, référence commerciale ou désignation du produit ou du véhicule concerné. Pour les appareils : WH-1000XM5, KitchenAid 5KSM175, Bosch WAT28640. Pour les véhicules, indiquer la marque ET le modèle : Renault Clio 5, Volkswagen Golf 7, BMW X3. S''applique aux notices, garanties, factures d''achat, réparations, entretien et tous documents liés à un véhicule ou un appareil.',
     'TEXT'),

    ('categorie_produit',
     'Catégorie produit / achat',
     'Catégorie du produit concerné par la notice, la facture ou le ticket d''achat. Choisir parmi : electromenager (lave-linge, lave-vaisselle, réfrigérateur, four, hotte…), electronique (TV, hi-fi, casque, enceinte, appareil photo…), informatique (ordinateur, imprimante, routeur, disque dur, écran…), outillage (perceuse, scie, compresseur, outillage de jardin motorisé…), mobilier (meuble, luminaire, store, volet…), jardin (tondeuse manuelle, barbecue, mobilier de jardin…), vehicule (voiture, vélo, trottinette, accessoire auto…), bijoux-montres (bijou, montre, joaillerie…), habillement (vêtement, chaussure, accessoire vestimentaire…), sports-loisirs (équipement sportif, instrument de musique, jeu, loisir créatif…), autre (tout ce qui ne rentre pas dans les catégories précédentes).',
     'TEXT'),

    ('type_assurance',
     'Type d''assurance',
     'Formule ou catégorie d''assurance. Pour les véhicules : responsabilite-civile, tiers-etendu, tous-risques. Pour les autres : habitation, multirisque, vie, prevoyance, sante, pret. Utiliser un slug kebab-case sans accents.',
     'TEXT'),

    ('categorie_facture',
     'Catégorie de facture',
     'Catégorie du service ou de la prestation facturée, pour le classement des factures de logement. Valeurs possibles : eau, electricite, gaz, energie (électricité+gaz combinés), internet, telephone, charges-copropriete, autre. Utiliser un slug kebab-case sans accents.',
     'TEXT'),

    ('nom_banque',
     'Nom de la banque / établissement financier',
     'Identifiant court normalisé de la banque ou de l''établissement financier, utilisé comme nom de dossier. Utiliser un slug kebab-case sans accents, en minuscules. Exemples : boursorama, bnp, credit-agricole, lcl, caisse-epargne, societe-generale, ing, fortuneo, hello-bank, cetelem, cofidis, credit-mutuel. Tous les documents d''un même établissement doivent produire TOUJOURS le même identifiant.',
     'TEXT'),

    ('type_compte',
     'Type de compte / produit financier',
     'Type de compte ou produit financier concerné par le document. Utiliser un slug kebab-case sans accents. Valeurs courantes : courant, livret-a, ldds, lep, pel, cel, pea, compte-titres, credit-immo, credit-conso, assurance-vie, prevoyance. Ne renseigner que si le document est clairement lié à un compte ou produit spécifique.',
     'TEXT'),

    ('numero_compte',
     'Numéro de compte (partiel)',
     'Identifiant court du compte bancaire : derniers 4 à 6 chiffres du numéro de compte, ou identifiant visible sur le document. Ne pas inclure le numéro complet. Exemples : 1234, 5678. Laisser vide si le numéro n''est pas visible ou si le document n''est pas lié à un compte précis.',
     'TEXT');
