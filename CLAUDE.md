# Archiver

Outil personnel de classification et d'archivage de documents.

## Stack technique

- **Backend** : Java 21, Spring Boot 3.x, Gradle (Kotlin DSL)
- **Frontend** : jte (Java Template Engine) + HTMX + Bootstrap SCSS (servi par Spring Boot)
- **Base de données** : SQLite via Spring Data JPA + Hibernate
- **IA** : Anthropic Java SDK (`claude-sonnet-4-6`, multimodal)
- **PDF natif** : Apache PDFBox (extraction texte + métadonnées)
- **PDF scanné → image** : PDFBox renderer
- **File watching** : Java WatchService (watchdog activable via settings)
- **Config** : Spring Boot application.properties / variables d'environnement

## Variables d'environnement

| Variable | Obligatoire | Défaut | Description |
|---|---|---|---|
| `ARCHIVER_ROOT` | Oui | — | Dossier racine d'archivage (absolu) |
| `ARCHIVER_INBOX` | Non | `$ARCHIVER_ROOT/inbox` | Dossier de dépôt surveillé |
| `ANTHROPIC_API_KEY` | Oui | — | Clé API Anthropic |
| `ARCHIVER_HOST` | Non | `127.0.0.1` | Bind address |
| `ARCHIVER_PORT` | Non | `8080` | Port HTTP |

## Git

Conventional Commits obligatoires :

| Préfixe | Usage |
|---|---|
| `feat:` | Nouvelle fonctionnalité |
| `fix:` | Correction de bug |
| `docs:` | Documentation uniquement |
| `refactor:` | Refactoring sans changement de comportement |
| `test:` | Ajout ou modification de tests |
| `chore:` | Maintenance (deps, build, config) |

Exemples : `feat: add watchdog inbox monitoring`, `fix: handle partial date in path template`

## Démarrage

```bash
./gradlew bootRun        # compile le SCSS puis démarre Spring Boot
./gradlew scss           # compile le SCSS seul
```

L'application crée automatiquement au premier démarrage :
- `$ARCHIVER_ROOT/archiver.db` (SQLite)
- `$ARCHIVER_INBOX/` si inexistant

## Structure du projet

```
src/main/
  java/com/github/lafarer/archiver/
    ArchiverApplication.java
    config/
      AppConfig.java          # ArchiverProperties (@ConfigurationProperties)
      DatabaseConfig.java     # init SQLite + création DB
    model/                    # entités JPA
      Document.java
      CustomFieldDef.java
      StoragePathRule.java
      ClassificationHistory.java
      Setting.java
    repository/               # Spring Data JPA repositories
    service/
      ExtractionService.java  # détection type, PDFBox, parsing filename
      AiAnalysisService.java  # appel Anthropic SDK, prompt building
      PathResolverService.java# évaluation règles, rendu template
      SidecarService.java     # lecture/écriture JSON sidecar
      ArchiveService.java     # déplacement/copie fichier
      WatchdogService.java    # Java WatchService
    web/
      InboxController.java
      ArchiveController.java
      RulesController.java
      CustomFieldsController.java
      SettingsController.java
  resources/
    application.properties
    templates/                # jte
    static/
      css/
        app.css               # compilé depuis SCSS — gitignored
      js/
  scss/
    app.scss                  # point d'entrée : variables puis bootstrap
    _variables.scss           # overrides Bootstrap (couleurs, spacing…)
```

## Bootstrap SCSS

Bootstrap est installé via npm et compilé avec `sass` CLI vers `static/css/app.css`.

```
package.json                  # dépendances npm : bootstrap, sass
```

`src/main/scss/app.scss` :
```scss
// 1. Overrides avant import Bootstrap
@import "variables";

// 2. Bootstrap complet
@import "bootstrap/scss/bootstrap";

// 3. Styles applicatifs
```

`src/main/scss/_variables.scss` :
```scss
// Exemple de customisation
$primary:   #3d6b8e;
$font-size-base: 0.9rem;
```

La compilation SCSS est déclenchée automatiquement par Gradle avant `bootRun` via le plugin `com.github.node-gradle.node`. Le fichier compilé `app.css` est gitignored — seuls les sources SCSS sont versionnés.

## Schéma de données

### Tables principales

- **document** : fichier archivé avec ses métadonnées (type, titre, date, émetteur, tags jsonb, custom_fields jsonb, chemin résolu, provenance par champ)
- **custom_field_def** : champs personnalisés (name slug, label, description pour l'IA, field_type)
- **storage_path_rule** : règles de chemin (priority, condition en langage naturel, path_template, is_default)
- **classification_history** : historique des reclassifications
- **setting** : préférences runtime modifiables via l'UI (watchdog_enabled, ai_model, confidence_threshold)

### Points clés du modèle

- `document.tags` et `document.custom_fields` stockés en JSON (string en SQLite)
- `document.document_date` stocké en string (`"2024"`, `"2024-03"`, `"2024-03-15"`) pour supporter les dates partielles
- `document.sha256_hash` UNIQUE — déduplication
- Index partiel sur `storage_path_rule.is_default` — exactement une règle par défaut
- FK vers `storage_path_rule` en `SET NULL` dans `classification_history` — historique préservé si règle supprimée

## Pipeline d'extraction

1. **Détection** : natif (PDFBox, texte > 100 chars) vs scanné vs image
2. **Pré-extraction** : texte PDFBox (natif), métadonnées PDF, parsing dates filename, mtime filesystem
3. **Analyse IA** : appel unique — analyse document + sélection storage path rule
   - Prompt caché : instructions + définitions custom fields + hints types/tags
   - Prompt variable : rules actives + contexte pré-extrait + contenu document
4. **Merge** : réconciliation pré-extraction / IA avec provenance par champ
5. **Résolution chemin** : rendu déterministe du path_template
6. **Archivage** : move (inbox) ou copy (import manuel) + écriture sidecar JSON
7. **Validation UI** : mode manuel (toujours) ou auto si confiance ≥ seuil

## Sidecar JSON

Fichier caché co-localisé avec le document archivé :
`Documents/Assurances/2024/.2024-03-01-attestation.pdf.json`

Contient : raisonnement IA, toutes les valeurs extraites avec source/confiance, chemin résolu, règle appliquée. Permet de reconstruire la DB complètement.

## Interface (jte + HTMX + Bootstrap SCSS)

- **Inbox** : liste documents pending, drag & drop import, validation en ligne
- **Archive** : liste filtrée (type, tags, période, recherche)
- **Règles** : CRUD storage path rules, drag & drop priorité, bouton test
- **Champs** : CRUD custom field definitions
- **Réglages** : watchdog toggle, seuils confiance, mode import, modèle IA
