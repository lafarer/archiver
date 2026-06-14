-- 1. Famille — Education: explicitly include CPF/DIF professional training
UPDATE storage_path_rule
SET condition_nl = 'Le document concerne l''éducation ou la formation d''un membre de la famille, qu''elle soit scolaire, universitaire ou professionnelle : diplôme, bulletin scolaire, certificat de scolarité, résultats d''examens, relevé de notes universitaire, attestation de formation professionnelle, titre certifiant, bilan de compétences, attestation de formation CPF (Compte Personnel de Formation), attestation DIF, certificat de qualification professionnelle.'
WHERE priority = 40;

-- 2. Famille — Juridique: explicitly include succession documents
UPDATE storage_path_rule
SET condition_nl = 'Le document est un acte ou document juridique nominatif concernant un membre de la famille : acte de mariage, jugement de divorce, PACS, jugement civil ou prud''homal, procuration, testament, pension alimentaire, documents de succession (acte de notoriété, inventaire du patrimoine successoral, acte de partage, attestation de propriété après décès).'
WHERE priority = 47;

-- 3. Finances — Impôt sur le revenu: add donation tax receipts as supporting documents
UPDATE storage_path_rule
SET condition_nl = 'Le document concerne l''impôt sur le revenu des personnes physiques : déclaration de revenus (formulaire 2042 et annexes), avis d''imposition sur le revenu, avis de non-imposition, déclaration ou avis IFI (Impôt sur la Fortune Immobilière), acompte prélèvement à la source, reçu fiscal de don ou de mécénat (justificatif de réduction d''impôt pour dons à une association ou fondation reconnue d''utilité publique).'
WHERE priority = 64;
