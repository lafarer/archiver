# Archiver

Archiver started as a personal tool for document classification - and as a test of how much of a real application Claude could generate from scratch.

A self-hosted document management tool that watches an inbox folder, extracts metadata from PDFs and images, and uses Claude AI to classify and file documents automatically. Storage paths are driven by configurable rules with template variables.

## Features

- AI-powered classification using Claude (Anthropic)
- Automatic and manual inbox processing with drag-and-drop
- Configurable storage rules with path templates (`{year}`, `{issuer}`, `[month?]`...)
- Custom fields for domain-specific metadata
- Full-text and faceted search across archived documents
- Document preview for PDFs and images
- Sidecar JSON files for DB-independent archiving

## Prerequisites

- An [Anthropic API key](https://console.anthropic.com/)
- Docker (recommended) or Java 21+

## Getting started with Docker

```bash
cp .env.example .env
# Edit .env and set ARCHIVER_ANTHROPIC_API_KEY
docker compose up --build
```

The app will be available at http://localhost:8080. Archived documents and the database are stored in `./data` (configurable via `ARCHIVER_DATA_PATH` in `.env`).

## Getting started locally

```bash
# Set your API key and local paths in src/main/resources/application-user.properties
./gradlew bootRun
```

## Configuration

| Variable | Required | Default | Description |
|---|---|---|---|
| `ARCHIVER_ANTHROPIC_API_KEY` | Yes | - | Anthropic API key |
| `ARCHIVER_ROOT` | No | `/data` | Root directory for the archive |
| `ARCHIVER_INBOX_FOLDER` | No | `Inbox` | Inbox subfolder name |
| `ARCHIVER_ARCHIVE_FOLDER` | No | `Archive` | Archive subfolder name |
| `ARCHIVER_PORT` | No | `8080` | HTTP port |

## Tech stack

- Java 21, Spring Boot 3, Gradle
- jte templates, HTMX, Bootstrap
- SQLite, Flyway
- Apache PDFBox, Anthropic Java SDK

## Documentation

Full documentation is available in the [Wiki](https://github.com/lafarer/archiver/wiki).

## License

[MIT](LICENSE)
