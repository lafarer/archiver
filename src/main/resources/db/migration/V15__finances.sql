-- 1. Custom fields for banking
INSERT INTO custom_field_def (slug, label, description, field_type) VALUES
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

-- 2. Finance-specific document types
INSERT OR IGNORE INTO document_type_def (slug, label, description) VALUES
    ('releve-compte',
     'Relevé de compte',
     'Relevé mensuel ou trimestriel d''un compte bancaire courant, d''épargne ou d''investissement.'),
    ('releve-epargne',
     'Relevé d''épargne / situation de compte',
     'Relevé annuel ou semestriel d''un livret d''épargne (Livret A, LDDS, LEP, PEL, CEL) ou d''un compte d''investissement (PEA, compte-titres).'),
    ('tableau-amortissement',
     'Tableau d''amortissement',
     'Tableau détaillant le remboursement d''un crédit : échéances, capital remboursé, intérêts, capital restant dû.'),
    ('avis-imposition',
     'Avis d''imposition',
     'Avis d''imposition sur le revenu émis par la Direction Générale des Finances Publiques (DGFiP).'),
    ('declaration-revenus',
     'Déclaration de revenus',
     'Déclaration annuelle des revenus (formulaire 2042 et annexes) déposée auprès de l''administration fiscale.'),
    ('declaration-ifi',
     'Déclaration IFI',
     'Déclaration de l''Impôt sur la Fortune Immobilière (IFI), annexée à la déclaration de revenus.'),
    ('avis-ifi',
     'Avis IFI',
     'Avis d''imposition relatif à l''Impôt sur la Fortune Immobilière (IFI).'),
    ('droits-succession',
     'Droits de succession / donation',
     'Document relatif à une déclaration de succession, une donation ou au paiement des droits correspondants.');

-- 3. Storage path rules for finances (priorities 60-65)
INSERT INTO storage_path_rule (priority, label, condition_nl, path_template, is_default, is_active) VALUES

    (60, 'Banque — Relevés de compte',
     'Le document est un relevé de compte bancaire mensuel ou périodique (compte courant, livret d''épargne, PEA, compte-titres, crédit). Le document est clairement lié à un compte identifié chez une banque ou un établissement financier.',
     'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Releves/[yyyy]/[mm]-[issuer]',
     0, 1),

    (61, 'Banque — Contrats de compte',
     'Le document est un contrat ou une convention liée à un compte ou produit bancaire spécifique : ouverture de compte, convention de compte courant, contrat de livret d''épargne, contrat PEA, offre de prêt, contrat de crédit immobilier ou à la consommation, tableau d''amortissement.',
     'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Contrats/[title]',
     0, 1),

    (62, 'Banque — Courriers relatifs à un compte',
     'Le document est un courrier, une notification ou un avis émis par une banque ou un établissement financier et concernant un compte ou produit spécifique identifiable : modification de conditions, alerte de solde, notification de virement, relevé de frais, résiliation d''un produit bancaire particulier.',
     'Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Courriers/[yyyy]-[title]',
     0, 1),

    (63, 'Banque — Courriers généraux',
     'Le document est un courrier, une communication générale ou un document administratif émis par une banque ou un établissement financier, non lié à un compte ou produit spécifique : conditions générales, information tarifaire générale, communication commerciale, réponse à réclamation générale.',
     'Finances/Banque/[nom_banque]/Courriers/[yyyy]-[title]',
     0, 1),

    (64, 'Impôt sur le revenu',
     'Le document concerne l''impôt sur le revenu des personnes physiques : déclaration de revenus (formulaire 2042 et annexes), avis d''imposition sur le revenu, avis de non-imposition, déclaration ou avis IFI (Impôt sur la Fortune Immobilière), acompte prélèvement à la source.',
     'Finances/Impots/[yyyy]/IR/[document_type]-[title]',
     0, 1),

    (65, 'Autres documents fiscaux',
     'Le document est un document fiscal ou lié à une obligation fiscale non couverte par les règles logement, véhicule ou impôt sur le revenu : droits de succession ou de donation, plus-values mobilières, prélèvements sociaux sur revenus du capital, avis de taxe sur les plus-values immobilières, CSG/CRDS autonome, déclaration de revenus de capitaux mobiliers.',
     'Finances/Impots/[yyyy]/[document_type]-[title]',
     0, 1);
