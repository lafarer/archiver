# Règles de classement — Archiver

Ce document décrit la structure de classement et les règles de stockage appliquées par l'IA.
La source de vérité reste les migrations Flyway (`src/main/resources/db/migration/`).

## Structure générale

```
Root/
├── Notices/
├── Vehicules/
├── Logements/
├── Famille/
├── Finances/
├── Achats/
└── Administratif/
```

---

## Champs personnalisés (custom fields)

| Champ | Usage | Format |
|---|---|---|
| `modele` | Modèle de produit ou véhicule | `Renault Clio 5`, `WH-1000XM5` |
| `immatriculation` | Plaque d'immatriculation | `AB-123-CD` |
| `type_assurance` | Type de contrat d'assurance | `tous-risques`, `habitation`, `vie` |
| `numero_contrat` | Numéro de contrat ou police | texte libre |
| `adresse_bien` | Identifiant normalisé du logement | `ville-nom-de-rue` (sans numéro ni CP) |
| `categorie_facture` | Catégorie de facture logement | `eau`, `electricite`, `gaz`, `internet`, `charges-copropriete` |
| `membre_famille` | Membre de la famille concerné | `Emmanuelle`, `Eric`, `Camille`, `Eliott` (ou autre prénom) |
| `categorie_produit` | Catégorie de produit ou achat | `electromenager`, `electronique`, `informatique`, `mobilier`, `outillage`, `bijoux-montres`, `habillement`, `sports-loisirs`, `jardin`, `vehicule`, `autre` |
| `nom_banque` | Identifiant de la banque | `boursorama`, `bnp`, `credit-agricole`, `lcl` |
| `type_compte` | Type de compte ou produit financier | `courant`, `livret-a`, `ldds`, `lep`, `pel`, `pea`, `compte-titres`, `credit-immo`, `credit-conso` |
| `numero_compte` | Derniers chiffres du numéro de compte | `1234` |
| `categorie_achat` | _(inutilisé — remplacé par `categorie_produit`)_ | — |

---

## Règles de classement

Les règles sont évaluées par ordre de priorité croissante. La première règle dont la condition correspond au document est appliquée. Une règle par défaut (catch-all) s'applique si aucune autre ne correspond.

### Notices (priorité 10)

| Priorité | Règle | Path template |
|---|---|---|
| 10 | Notices d'utilisation | `Notices/[categorie_produit]/[issuer]/[modele?]-[title]` |

**Contenu :** notices, manuels d'installation, guides de démarrage rapide.

---

### Véhicules (priorités 20–27)

Structure : `Vehicules/[modele]-[immatriculation]/`

| Priorité | Règle | Path template |
|---|---|---|
| 20 | Assurances — Contrats et polices | `Vehicules/[modele]-[immatriculation]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]` |
| 21 | Assurances — Courriers | `Vehicules/[modele]-[immatriculation]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[title]` |
| 22 | Documents officiels (carte grise, CT) | `Vehicules/[modele]-[immatriculation]/Documents/[document_type]-[title]` |
| 23 | Entretiens et réparations | `Vehicules/[modele]-[immatriculation]/Entretien/[yyyy]/[issuer]-[title]` |
| 24 | Garanties | `Vehicules/[modele]-[immatriculation]/Garanties/[issuer?]-[title]` |
| 25 | Sinistres | `Vehicules/[modele]-[immatriculation]/Sinistres/[yyyy]/[title]` |
| 26 | Contrats (achat, leasing, LOA, LLD) | `Vehicules/[modele]-[immatriculation]/Contrats/[yyyy]-[title]` |
| 27 | Taxes (malus, amendes, vignette) | `Vehicules/[modele]-[immatriculation]/Taxes/[yyyy]/[document_type]-[title]` |

---

### Logements (priorités 30–38)

Structure : `Logements/[adresse_bien]/` — `adresse_bien` normalisé en `ville-nom-de-rue` (sans numéro ni code postal).

| Priorité | Règle | Path template |
|---|---|---|
| 30 | Actes notariés | `Logements/[adresse_bien]/Actes/[yyyy]-[title]` |
| 31 | Assurances — Contrats | `Logements/[adresse_bien]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]` |
| 32 | Assurances — Courriers | `Logements/[adresse_bien]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[title]` |
| 33 | Contrats (bail, syndic, règlement) | `Logements/[adresse_bien]/Contrats/[yyyy]-[title]` |
| 34 | Entretiens obligatoires (chaudière, ramonage) | `Logements/[adresse_bien]/Entretiens-obligatoires/[document_type]-[title]` |
| 35 | Factures (eau, énergie, internet, charges) | `Logements/[adresse_bien]/Factures/[categorie_facture]/[yyyy]/[issuer]-[title]` |
| 36 | Taxes (foncière, habitation) | `Logements/[adresse_bien]/Taxes/[yyyy]/[document_type]-[title]` |
| 37 | Travaux (factures, devis, permis) | `Logements/[adresse_bien]/Travaux/[yyyy]/[issuer]-[title]` |
| 38 | Sinistres (dégât des eaux, incendie, vol) | `Logements/[adresse_bien]/Sinistres/[yyyy]/[title]` |

---

### Famille (priorités 40–54)

Structure : `Famille/[membre_famille]/` — membres connus : **Emmanuelle, Eric, Camille, Eliott**. Pour une succession, `membre_famille` = le défunt.

#### Par membre

| Priorité | Règle | Path template |
|---|---|---|
| 40 | Éducation et formation (scolaire, CPF, DIF) | `Famille/[membre_famille]/Education/[document_type]/[yyyy]-[title]` |
| 41 | Identité et documents électoraux | `Famille/[membre_famille]/Identite/[document_type]-[title]` |
| 42 | Santé | `Famille/[membre_famille]/Sante/[yyyy]/[document_type]-[issuer?]-[title]` |
| 43 | Emploi — Fiches de paie | `Famille/[membre_famille]/Emploi/Fiches-de-paie/[yyyy]/[mm]-[issuer]` |
| 44 | Emploi — Contrats | `Famille/[membre_famille]/Emploi/Contrats/[yyyy]-[issuer]-[title]` |
| 45 | Emploi — Attestations | `Famille/[membre_famille]/Emploi/Attestations/[yyyy]-[title]` |
| 46 | Retraite et pension | `Famille/[membre_famille]/Retraite/[yyyy]/[document_type]-[title]` |
| 47 | Juridique (jugements, succession, testament) | `Famille/[membre_famille]/Juridique/[yyyy]-[document_type]-[title]` |
| 48 | Allocations (CAF, RSA, ARE, AAH) | `Famille/[membre_famille]/Allocations/[yyyy]/[issuer]-[title]` |
| 49 | Assurances personnelles — Contrats (dont emprunteur) | `Famille/[membre_famille]/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]` |
| 50 | Assurances personnelles — Courriers | `Famille/[membre_famille]/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[title]` |
| 53 | Services personnels — Contrats (mobile, abonnements) | `Famille/[membre_famille]/Services/[issuer]/Contrats/[title]` |
| 54 | Services personnels — Factures | `Famille/[membre_famille]/Services/[issuer]/Factures/[yyyy]/[mm]-[title]` |

#### Famille commune (non rattaché à un membre)

| Priorité | Règle | Path template |
|---|---|---|
| 51 | Assurances communes — Contrats (voyage, juridique, animaux) | `Famille/Commun/Assurances/[type_assurance?]-[numero_contrat]/Contrats/[title]` |
| 52 | Assurances communes — Courriers | `Famille/Commun/Assurances/[type_assurance?]-[numero_contrat]/Courriers/[yyyy]-[title]` |

---

### Finances (priorités 60–65)

#### Banque

Structure : `Finances/Banque/[nom_banque]/` — les produits d'épargne (livret-a, pel, pea…) et crédits sont des types de compte sous la même banque.

| Priorité | Règle | Path template |
|---|---|---|
| 60 | Relevés de compte | `Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Releves/[yyyy]/[mm]-[issuer]` |
| 61 | Contrats de compte | `Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Contrats/[title]` |
| 62 | Courriers relatifs à un compte | `Finances/Banque/[nom_banque]/[type_compte]-[numero_compte?]/Courriers/[yyyy]-[title]` |
| 63 | Courriers généraux (niveau banque) | `Finances/Banque/[nom_banque]/Courriers/[yyyy]-[title]` |

#### Impôts et fiscalité

| Priorité | Règle | Path template |
|---|---|---|
| 64 | Impôt sur le revenu (IR, IFI, reçus de dons) | `Finances/Impots/[yyyy]/IR/[document_type]-[title]` |
| 65 | Autres documents fiscaux (succession, plus-values, CSG) | `Finances/Impots/[yyyy]/[document_type]-[title]` |

> **Note :** taxe foncière et taxe d'habitation → règle 36 (Logements). Taxes véhicule → règle 27 (Véhicules).

---

### Achats (priorités 70–71)

Structure : `Achats/[categorie_produit]/`

| Priorité | Règle | Path template |
|---|---|---|
| 70 | Preuves d'achat (factures, tickets) | `Achats/[categorie_produit]/[yyyy]-[issuer]-[title]` |
| 71 | Garanties et contrats de garantie étendue | `Achats/[categorie_produit]/Garanties/[yyyy]-[title]` |

**Catégories :** `electromenager`, `electronique`, `informatique`, `mobilier`, `outillage`, `bijoux-montres`, `habillement`, `sports-loisirs`, `jardin`, `vehicule`, `autre`.

> **Note :** exclure les factures de services, travaux et achats liés à un logement ou véhicule.

---

### Administratif (priorité 80)

| Priorité | Règle | Path template |
|---|---|---|
| 80 | Courriers et documents administratifs divers | `Administratif/[yyyy]/[issuer]-[title]` |

Filet pour les courriers officiels d'organismes publics non couverts par une règle plus spécifique (préfecture, mairie, ministères…).

---

## Syntaxe des path templates

| Syntaxe | Comportement |
|---|---|
| `[champ]` | Champ requis — si absent, segment omis |
| `[champ?]` | Champ optionnel — si absent, le séparateur précédent est aussi omis |
| `[yyyy]` | Année extraite de `document_date` |
| `[mm]` | Mois extrait de `document_date` |
| `[title]` | Titre du document (slugifié) |
| `[issuer]` | Émetteur du document (slugifié) |
| `[document_type]` | Type de document (slug) |
