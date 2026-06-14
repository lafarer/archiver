-- Storage path rules ordered by priority (lower number = evaluated first).
-- Ordering principle: most constrained (specific, unique identifier) → least constrained (catch-all).
--
-- 10-17 : Véhicules     — contrainte forte : immatriculation unique
-- 20-28 : Logements     — contrainte forte : adresse_bien normalisée
-- 30-42 : Famille/membre — contrainte personne : membre_famille + type de document
-- 45-46 : Famille/Commun — moins contraint que par membre
-- 50-55 : Finances       — documents très distinctifs par nature
-- 60    : Notices        — type de document transversal, après les domaines
-- 70-71 : Achats         — règles générales sur les preuves d'achat
-- 80    : Administratif  — filet, toujours en dernier

INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    -- -------------------------------------------------------------------------
    -- VÉHICULES (10-17)
    -- -------------------------------------------------------------------------

    (10, 'Assurances véhicule — Contrats et polices',
     'Le document est un contrat d''assurance, une police, une attestation d''assurance, un certificat d''assurance ou un avis d''échéance pour un véhicule automobile, moto ou véhicule motorisé.',
     'Vehicules/[modele]-[immatriculation]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]',
     0, 1),

    (11, 'Assurances véhicule — Courriers',
     'Le document est un courrier, une lettre ou une notification émanant d''une compagnie d''assurance et concernant un véhicule : résiliation, modification de contrat, relevé d''informations, réponse à réclamation.',
     'Vehicules/[modele]-[immatriculation]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[title]',
     0, 1),

    (12, 'Documents officiels véhicule',
     'Le document est un document administratif ou officiel propre à un véhicule : carte grise, certificat d''immatriculation, contrôle technique, certificat de conformité.',
     'Vehicules/[modele]-[immatriculation]/Documents/[document_type]-[title]',
     0, 1),

    (13, 'Entretien et réparations véhicule',
     'Le document est une facture, un bon de commande ou un bon de travaux relatif à l''entretien, la révision, la maintenance ou la réparation d''un véhicule (garage, concessionnaire, pneumaticien, carrossier…).',
     'Vehicules/[modele]-[immatriculation]/Entretien/[yyyy]/[issuer]-[title]',
     0, 1),

    (14, 'Garanties véhicule',
     'Le document est une garantie constructeur, une extension de garantie ou un certificat de garantie portant sur un véhicule ou des pièces automobiles.',
     'Vehicules/[modele]-[immatriculation]/Garanties/[issuer?]-[title]',
     0, 1),

    (15, 'Sinistres véhicule',
     'Le document est lié à un sinistre automobile : constat amiable, déclaration de sinistre, rapport d''expertise, courrier d''assurance relatif à un accident ou dommage subi par un véhicule.',
     'Vehicules/[modele]-[immatriculation]/Sinistres/[yyyy]/[title]',
     0, 1),

    (16, 'Contrats véhicule',
     'Le document est un contrat lié à l''acquisition ou à l''usage d''un véhicule : contrat de vente, bon de commande, contrat de leasing, LOA (location avec option d''achat), LLD (location longue durée), contrat de financement ou crédit auto.',
     'Vehicules/[modele]-[immatriculation]/Contrats/[yyyy]-[title]',
     0, 1),

    (17, 'Taxes véhicule',
     'Le document est une taxe ou un impôt lié à un véhicule : malus écologique, taxe à l''essieu, vignette Crit''Air, amendes (PV), taxes régionales liées à l''immatriculation.',
     'Vehicules/[modele]-[immatriculation]/Taxes/[yyyy]/[document_type]-[title]',
     0, 1),

    -- -------------------------------------------------------------------------
    -- LOGEMENTS (20-28)
    -- adresse_bien normalisé : [ville]-[nom-de-rue], sans numéro ni code postal
    -- -------------------------------------------------------------------------

    (20, 'Actes notariés logement',
     'Le document est un acte notarié ou un document juridique lié à un bien immobilier : acte de vente, acte d''achat, compromis de vente, donation, hypothèque, titre de propriété.',
     'Logements/[adresse_bien]/Actes/[yyyy]-[title]',
     0, 1),

    (21, 'Assurances logement — Contrats et polices',
     'Le document est un contrat d''assurance habitation, une police multirisque habitation, une assurance propriétaire non-occupant (PNO), une attestation d''assurance logement ou un avis d''échéance pour un bien immobilier. Ne concerne pas les véhicules.',
     'Logements/[adresse_bien]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]',
     0, 1),

    (22, 'Assurances logement — Courriers',
     'Le document est un courrier, une lettre ou une notification d''une compagnie d''assurance concernant un logement ou bien immobilier : résiliation, modification de contrat, réponse à réclamation. Ne concerne pas les véhicules.',
     'Logements/[adresse_bien]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[title]',
     0, 1),

    (23, 'Contrats logement',
     'Le document est un contrat lié à un logement ou bien immobilier : bail de location, contrat de syndic, règlement de copropriété, mandat de gestion locative, état des lieux.',
     'Logements/[adresse_bien]/Contrats/[yyyy]-[title]',
     0, 1),

    (24, 'Entretiens obligatoires logement',
     'Le document est un rapport, un certificat ou une facture d''entretien obligatoire lié à un logement : entretien de chaudière, ramonage de cheminée, vérification VMC, contrôle installation gaz, contrôle installation électrique, désinsectisation.',
     'Logements/[adresse_bien]/Entretiens-obligatoires/[document_type]-[title]',
     0, 1),

    (25, 'Factures logement',
     'Le document est une facture liée à la consommation ou aux services d''un logement : eau, électricité, gaz, énergie, internet, téléphone fixe, charges de copropriété. Exclure les factures de travaux.',
     'Logements/[adresse_bien]/Factures/[categorie_facture]/[yyyy]/[issuer]-[title]',
     0, 1),

    (26, 'Taxes logement',
     'Le document est une taxe ou un impôt lié à un bien immobilier : taxe foncière, taxe d''habitation, taxe sur les logements vacants, cotisation foncière.',
     'Logements/[adresse_bien]/Taxes/[yyyy]/[document_type]-[title]',
     0, 1),

    (27, 'Travaux logement',
     'Le document est une facture, un devis, un bon de commande ou un permis lié à des travaux dans un logement : rénovation, aménagement, construction, extension, second œuvre (plomberie, électricité, peinture, carrelage…).',
     'Logements/[adresse_bien]/Travaux/[yyyy]/[issuer]-[title]',
     0, 1),

    (28, 'Sinistres logement',
     'Le document est lié à un sinistre dans un logement : déclaration de sinistre, constat de dégât des eaux, rapport d''expertise, courrier d''assurance relatif à un sinistre (incendie, dégât des eaux, vol, bris de glace…).',
     'Logements/[adresse_bien]/Sinistres/[yyyy]/[title]',
     0, 1),

    -- -------------------------------------------------------------------------
    -- FAMILLE — PAR MEMBRE (30-42)
    -- Membres connus : Emmanuelle, Eric, Camille, Eliott
    -- Pour une succession : membre_famille = le défunt
    -- Ordre interne : du plus distinctif au plus général
    -- -------------------------------------------------------------------------

    (30, 'Famille — Emploi : fiches de paie',
     'Le document est une fiche de paie ou un bulletin de salaire d''un membre de la famille.',
     'Famille/[membre_famille]/Emploi/Fiches-de-paie/[yyyy]/[mm]-[issuer]',
     0, 1),

    (31, 'Famille — Identité et documents électoraux',
     'Le document est un document d''identité officiel ou électoral nominatif d''un membre de la famille : carte nationale d''identité, passeport, permis de conduire, acte de naissance, acte de mariage, livret de famille, titre de séjour, carte d''électeur, procuration de vote.',
     'Famille/[membre_famille]/Identite/[document_type]-[title]',
     0, 1),

    (32, 'Famille — Santé',
     'Le document concerne la santé d''un membre de la famille : ordonnance, résultat d''analyse ou d''examen médical, compte-rendu de consultation ou d''hospitalisation, remboursement Sécurité Sociale ou mutuelle, attestation de droits, carnet de vaccination.',
     'Famille/[membre_famille]/Sante/[yyyy]/[document_type]-[issuer?]-[title]',
     0, 1),

    (33, 'Famille — Éducation et formation',
     'Le document concerne l''éducation ou la formation d''un membre de la famille, qu''elle soit scolaire, universitaire ou professionnelle : diplôme, bulletin scolaire, certificat de scolarité, résultats d''examens, relevé de notes universitaire, attestation de formation professionnelle, titre certifiant, bilan de compétences, attestation de formation CPF (Compte Personnel de Formation), attestation DIF, certificat de qualification professionnelle.',
     'Famille/[membre_famille]/Education/[document_type]/[yyyy]-[title]',
     0, 1),

    (34, 'Famille — Emploi : contrats',
     'Le document est un contrat de travail, un avenant ou une promesse d''embauche d''un membre de la famille.',
     'Famille/[membre_famille]/Emploi/Contrats/[yyyy]-[issuer]-[title]',
     0, 1),

    (35, 'Famille — Emploi : attestations',
     'Le document est une attestation liée à l''emploi d''un membre de la famille : attestation employeur, certificat de travail, solde de tout compte, rupture conventionnelle, attestation Pôle Emploi, ARE.',
     'Famille/[membre_famille]/Emploi/Attestations/[yyyy]-[title]',
     0, 1),

    (36, 'Famille — Retraite et pension',
     'Le document concerne la retraite ou la pension d''un membre de la famille : relevé de carrière, notification de droits à la retraite, bulletin de pension, estimation retraite, relevé de points.',
     'Famille/[membre_famille]/Retraite/[yyyy]/[document_type]-[title]',
     0, 1),

    (37, 'Famille — Juridique',
     'Le document est un acte ou document juridique nominatif concernant un membre de la famille : acte de mariage, jugement de divorce, PACS, jugement civil ou prud''homal, procuration, testament, pension alimentaire, documents de succession (acte de notoriété, inventaire du patrimoine successoral, acte de partage, attestation de propriété après décès).',
     'Famille/[membre_famille]/Juridique/[yyyy]-[document_type]-[title]',
     0, 1),

    (38, 'Famille — Allocations',
     'Le document concerne des allocations ou aides sociales pour un membre de la famille : allocations familiales CAF, RSA, prime d''activité, aide au logement, ARE (chômage), allocation adulte handicapé.',
     'Famille/[membre_famille]/Allocations/[yyyy]/[issuer]-[title]',
     0, 1),

    (39, 'Famille — Assurances personnelles : contrats',
     'Le document est un contrat d''assurance personnelle d''un membre de la famille, non liée à un logement ou un véhicule : assurance vie, prévoyance individuelle, complémentaire santé (mutuelle), garantie accidents de la vie, assurance emprunteur (liée à un crédit immobilier ou à la consommation, rattachée à la personne assurée).',
     'Famille/[membre_famille]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]',
     0, 1),

    (40, 'Famille — Assurances personnelles : courriers',
     'Le document est un courrier ou une notification d''une assurance personnelle d''un membre de la famille, non liée à un logement ou un véhicule : résiliation, modification, relevé annuel, attestation, avis d''échéance. Inclut les courriers relatifs à une assurance emprunteur.',
     'Famille/[membre_famille]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[title]',
     0, 1),

    (41, 'Famille — Services personnels : contrats',
     'Le document est un contrat ou un abonnement de service personnel d''un membre de la famille, non lié à un logement : téléphonie mobile, abonnement internet mobile, abonnement de streaming (TV, musique, jeux), abonnement de presse ou magazine, abonnement sportif ou culturel.',
     'Famille/[membre_famille]/Services/[issuer]/Contrats/[title]',
     0, 1),

    (42, 'Famille — Services personnels : factures',
     'Le document est une facture ou un relevé de consommation lié à un service personnel d''un membre de la famille, non lié à un logement : facture de téléphonie mobile, facture d''abonnement streaming, reçu d''abonnement en ligne.',
     'Famille/[membre_famille]/Services/[issuer]/Factures/[yyyy]/[mm]-[title]',
     0, 1),

    -- -------------------------------------------------------------------------
    -- FAMILLE — COMMUN (45-46)
    -- Documents couvrant l''ensemble du foyer, non nominatifs
    -- -------------------------------------------------------------------------

    (45, 'Famille Commun — Assurances : contrats',
     'Le document est un contrat d''assurance couvrant l''ensemble de la famille ou du foyer, non rattaché à un membre en particulier, ni à un logement ou un véhicule spécifique : assurance voyage, assurance annulation, protection juridique familiale, assurance animaux de compagnie, assurance scolaire collective.',
     'Famille/Commun/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]',
     0, 1),

    (46, 'Famille Commun — Assurances : courriers',
     'Le document est un courrier, une attestation ou une notification liée à une assurance couvrant l''ensemble de la famille ou du foyer, non rattaché à un membre en particulier, ni à un logement ou un véhicule spécifique : résiliation, modification, attestation d''assurance voyage, relevé annuel protection juridique.',
     'Famille/Commun/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[title]',
     0, 1),

    -- -------------------------------------------------------------------------
    -- FINANCES (50-55)
    -- -------------------------------------------------------------------------

    (50, 'Banque — Relevés de compte',
     'Le document est un relevé de compte bancaire mensuel ou périodique (compte courant, livret d''épargne, PEA, compte-titres, crédit). Le document est clairement lié à un compte identifié chez une banque ou un établissement financier.',
     'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Releves/[yyyy]/[mm]-[issuer]',
     0, 1),

    (51, 'Banque — Contrats de compte',
     'Le document est un contrat ou une convention liée à un compte ou produit bancaire spécifique : ouverture de compte, convention de compte courant, contrat de livret d''épargne, contrat PEA, offre de prêt, contrat de crédit immobilier ou à la consommation, tableau d''amortissement.',
     'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Contrats/[title]',
     0, 1),

    (52, 'Banque — Courriers relatifs à un compte',
     'Le document est un courrier, une notification ou un avis émis par une banque ou un établissement financier et concernant un compte ou produit spécifique identifiable : modification de conditions, alerte de solde, notification de virement, relevé de frais, résiliation d''un produit bancaire particulier.',
     'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Courriers/[yyyy]-[title]',
     0, 1),

    (53, 'Banque — Courriers généraux',
     'Le document est un courrier, une communication générale ou un document administratif émis par une banque ou un établissement financier, non lié à un compte ou produit spécifique : conditions générales, information tarifaire générale, communication commerciale, réponse à réclamation générale.',
     'Finances/Banque/[nom_banque]/Courriers/[yyyy]-[title]',
     0, 1),

    (54, 'Impôt sur le revenu',
     'Le document concerne l''impôt sur le revenu des personnes physiques : déclaration de revenus (formulaire 2042 et annexes), avis d''imposition sur le revenu, avis de non-imposition, déclaration ou avis IFI (Impôt sur la Fortune Immobilière), acompte prélèvement à la source, reçu fiscal de don ou de mécénat (justificatif de réduction d''impôt pour dons à une association ou fondation reconnue d''utilité publique).',
     'Finances/Impots/[yyyy]/IR/[document_type]-[title]',
     0, 1),

    (55, 'Autres documents fiscaux',
     'Le document est un document fiscal ou lié à une obligation fiscale non couverte par les règles logement, véhicule ou impôt sur le revenu : droits de succession ou de donation, plus-values mobilières, prélèvements sociaux sur revenus du capital, avis de taxe sur les plus-values immobilières, CSG/CRDS autonome, déclaration de revenus de capitaux mobiliers.',
     'Finances/Impots/[yyyy]/[document_type]-[title]',
     0, 1),

    -- -------------------------------------------------------------------------
    -- NOTICES (60)
    -- Après les domaines : un manuel véhicule va en Notices, pas en Véhicules
    -- -------------------------------------------------------------------------

    (60, 'Notices d''utilisation',
     'Le document est une notice d''utilisation, un manuel d''installation ou un guide de démarrage rapide accompagnant un produit (appareil électroménager, électronique, outil, meuble…).',
     'Notices/[categorie_produit]/[issuer]/[modele?]-[title]',
     0, 1),

    -- -------------------------------------------------------------------------
    -- ACHATS (70-71)
    -- -------------------------------------------------------------------------

    (70, 'Achats — Preuves d''achat',
     'Le document est une preuve d''achat d''un bien de consommation : ticket de caisse, reçu de paiement, facture d''achat, bon de commande livré. Concerne des biens matériels conservés pour leur valeur (électronique, électroménager, mobilier, bijoux, outillage, vêtements, équipements sportifs…). Exclure les factures de services (eau, électricité, téléphone, abonnements), les factures de travaux et les achats liés à un logement ou un véhicule.',
     'Achats/[categorie_produit]/[yyyy]-[issuer]-[title]',
     0, 1),

    (71, 'Achats — Garanties',
     'Le document est un bon de garantie, un certificat de garantie constructeur ou un contrat de garantie étendue pour un bien de consommation acheté.',
     'Achats/[categorie_produit]/Garanties/[yyyy]-[title]',
     0, 1),

    -- -------------------------------------------------------------------------
    -- ADMINISTRATIF (80) — filet
    -- -------------------------------------------------------------------------

    (80, 'Administratif — Divers',
     'Le document est un courrier ou document officiel émanant d''un organisme public ou administratif (préfecture, mairie, ministère, tribunal, organisme de sécurité sociale) et non couvert par une règle plus spécifique : autorisation administrative, déclaration diverse, notification officielle, correspondance avec une administration.',
     'Administratif/[yyyy]/[issuer]-[title]',
     0, 1);
