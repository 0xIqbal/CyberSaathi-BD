# CyberSaathi BD Project Context

This document records the verified development context for CyberSaathi BD. It is
intended to be read before making future changes. It contains no credentials,
tokens, passwords, or API keys.

## Project Summary

CyberSaathi BD is a Laravel REST API with a Flutter mobile client for Bangladeshi
users. Its implemented product areas are:

- Suspicious URL analysis
- PDF/DOCX document privacy scanning
- Digital evidence organization
- Bangla/English health information navigation

The project is suitable for a capstone-scale implementation. A standalone
general cybersecurity chat assistant and QR Guardian BD are not complete
features in the current repository.

## Technology Stack

### Backend

- PHP `^8.3`
- Laravel `^13.17`
- Laravel Sanctum `^4.0`
- PHPUnit `^12.5`
- Laravel Pint
- MySQL-compatible production configuration
- SQLite test configuration
- Smalot PDF Parser
- ZipArchive for DOCX processing
- Ollama for local LLM integration

### Mobile

- Flutter and Dart (`>=3.3.0 <4.0.0`)
- Material 3
- Riverpod 3
- Dio
- Flutter Secure Storage
- File Picker
- Flutter Markdown
- Flutter TTS

## Repository Layout

### Laravel

```text
app/
  Http/Controllers/Api/V1/
  Http/Requests/Api/V1/
  Http/Resources/Api/V1/
  Models/
  Policies/
  Services/
  Support/
bootstrap/
config/
database/
  factories/
  migrations/
  seeders/
routes/
tests/
docs/health-navigator/reviewed-content/
```

### Flutter

```text
mobile/lib/
  app/
  core/
    network/
    theme/
  features/
    auth/
    dashboard/
    document_scanner/
    evidence_vault/
    health_navigator/
    url_checker/
  shared/
    models/
    widgets/
```

## Backend Architecture

- API versioning is implemented under `/api/v1` in [routes/api.php](routes/api.php).
- Controllers are grouped under `app/Http/Controllers/Api/V1`.
- Request validation uses Form Requests under `app/Http/Requests/Api/V1`.
- API serialization uses Resources under `app/Http/Resources/Api/V1`.
- Domain work is primarily implemented in `app/Services`.
- Standard success and error envelopes are defined by
  [ApiResponse.php](app/Support/ApiResponse.php).
- Laravel Sanctum bearer tokens protect user resources.
- Ownership checks for incidents and evidence are enforced by
  [IncidentPolicy.php](app/Policies/IncidentPolicy.php).

## Mobile Architecture

- [router.dart](mobile/lib/app/router.dart) manages the authentication gate and
  navigation to the feature areas.
- [api_service.dart](mobile/lib/core/network/api_service.dart) provides the
  shared Dio client, bearer-token injection, JSON parsing, multipart uploads,
  and API error conversion.
- Each feature is separated into data, presentation, repositories, models,
  providers, and screens where applicable.
- Theme and reusable visual components live under `mobile/lib/core/theme` and
  `mobile/lib/shared/widgets`.
- Presentation animations are centralized in
  [premium_motion.dart](mobile/lib/shared/widgets/premium_motion.dart).
- The current mobile API URLs are development-oriented: web uses
  `127.0.0.1`, while the Android emulator uses `10.0.2.2`.

## Implemented Modules

### Authentication

Implemented registration, login, logout, current-user lookup, and secure token
storage using Sanctum.

Primary files:

- [AuthController.php](app/Http/Controllers/Api/V1/AuthController.php)
- [auth_view_model.dart](mobile/lib/features/auth/presentation/viewmodels/auth_view_model.dart)
- [auth_repository.dart](mobile/lib/features/auth/data/repositories/auth_repository.dart)

### URL Scanner

Implemented by [UrlAnalysisService.php](app/Services/UrlAnalysisService.php)
and [UrlAnalysisController.php](app/Http/Controllers/Api/V1/UrlAnalysisController.php).

The scanner performs structural heuristics including:

- HTTP/HTTPS transport checks
- Numeric IP hosts
- Punycode
- Suspicious keywords
- Excessive subdomains
- Encoded paths
- Protected-brand similarity
- Embedded credentials

It does not resolve, open, or fetch submitted URLs. AI-generated explanations
are supplementary and are currently implemented directly in the controller.

### Document Privacy Scanner

Implemented by [DocumentScanService.php](app/Services/DocumentScanService.php)
and [DocumentScanController.php](app/Http/Controllers/Api/V1/DocumentScanController.php).

The scanner:

- Supports PDF and DOCX.
- Validates file signatures and DOCX ZIP structure.
- Uses private local storage and generated per-user paths.
- Limits file size, extracted text, and DOCX uncompressed content.
- Detects phones, emails, student IDs, and password-like strings.
- Masks findings and stores SHA-256 hashes.

Known integration issue: [DocumentScanResource.php](app/Http/Resources/Api/V1/DocumentScanResource.php)
does not currently expose every field expected by the Flutter model and an
existing test, including `document_type`.

### Evidence Vault

Implemented by [EvidenceService.php](app/Services/EvidenceService.php),
[IncidentController.php](app/Http/Controllers/Api/V1/IncidentController.php),
and [EvidenceController.php](app/Http/Controllers/Api/V1/EvidenceController.php).

It supports incidents, private evidence uploads, SHA-256 hashing, ownership
authorization, private downloads, and incident timeline events.

### Health Navigator

Implemented by [HealthAssistantService.php](app/Services/Health/HealthAssistantService.php),
[HealthKnowledgeService.php](app/Services/Health/HealthKnowledgeService.php),
[HealthSafetyService.php](app/Services/Health/HealthSafetyService.php), and
[OllamaService.php](app/Services/Health/OllamaService.php).

Implemented behavior includes:

- Published health article and topic retrieval.
- Bangla and selected Banglish query normalization.
- Deterministic emergency detection.
- Emergency responses that bypass Ollama.
- Reviewed article context retrieval.
- Bangla-safe prompting that prohibits diagnosis, prescriptions, dosage, and
  invented facts.
- Structured source and warning responses.
- Ollama error, timeout, malformed JSON, and empty-content handling.

There are 17 reviewed Markdown articles under
`docs/health-navigator/reviewed-content/`, seeded by
[HealthArticleSeeder.php](database/seeders/HealthArticleSeeder.php).

## Partial and Planned Features

### Partially implemented

- The general AI area currently has an `/api/v1/ai/test` endpoint, but
  [AiService.php](app/Services/AiService.php) is empty and there is no complete
  standalone cybersecurity chat assistant.
- Dashboard visualizations are primarily presentation-oriented; there is no
  complete backend activity/statistics aggregation feature.
- URL and document AI explanations work through separate controller-level
  Ollama calls rather than one shared AI service.

### Not implemented or only future scope

- QR Guardian BD
- Threat-intelligence or Safe Browsing lookups
- DNS/WHOIS URL reputation analysis
- Antivirus scanning for uploaded files
- Background jobs for document and AI processing
- Offline health-content synchronization
- Production deployment hardening

## Database Design

Important tables and relationships:

- `users`: authenticated users.
- `personal_access_tokens`: Sanctum tokens.
- `document_scans`: private document metadata, hashes, status, and masked findings.
- `incidents`: user-owned cyber incidents.
- `evidence_items`: evidence attached to incidents.
- `incident_events`: incident timeline entries.
- `health_articles`: bilingual reviewed health content.
- `health_sources`: source organizations and references.
- `health_article_source`: many-to-many article/source relationship with citation
  metadata.

Relevant models are under [app/Models](app/Models). Database changes must use
new migrations and must preserve existing data and API compatibility.

## API Endpoint Reference

### Authentication

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
GET  /api/v1/auth/me
```

### Scanners

```text
POST /api/v1/url-analyses
POST /api/v1/document-scans
GET  /api/v1/document-scans/{documentScan}
```

### Evidence

```text
GET    /api/v1/incidents
POST   /api/v1/incidents
GET    /api/v1/incidents/{incident}
PATCH  /api/v1/incidents/{incident}
DELETE /api/v1/incidents/{incident}
POST   /api/v1/incidents/{incident}/evidence
GET    /api/v1/incidents/{incident}/evidence/{evidence}/download
```

### Health Navigator

```text
GET  /api/v1/health-navigator/topics
GET  /api/v1/health-navigator/articles
GET  /api/v1/health-navigator/articles/{slug}
POST /api/v1/health-navigator/ask
```

The usual response shape is `{message, data}`. Do not change response fields
without updating the corresponding Resources, Flutter models, repositories, and
feature tests together.

## AI Integration

Health Navigator uses the configured Ollama values in
[config/services.php](config/services.php):

- Base URL defaults to `http://127.0.0.1:11434`.
- Model defaults to `qwen3:4b`.
- Endpoint: `/api/chat`.
- Requests are non-streaming and use `think: false`.
- Performance options include `num_predict`, `temperature`, and `num_ctx`.

URL and document explanations currently use direct `/api/generate` calls in
their controllers. Treat all user-provided document contents and questions as
untrusted input. Never allow document instructions to override system safety
rules, and never expose private reasoning or sensitive document contents in
logs.

## Development Commands

### Backend

```powershell
composer install
php artisan serve
php artisan route:list
php artisan test
vendor/bin/pint --dirty --format agent
```

Use migrations and seeders only when explicitly required:

```powershell
php artisan migrate
php artisan db:seed
```

### Flutter

Run commands from `mobile/`:

```powershell
flutter pub get
flutter analyze
flutter test
dart format lib test
flutter run
```

Do not install packages unless the dependency manifest has intentionally changed
or a required validation command reports a missing dependency.

## Coding and Security Conventions

- Inspect existing sibling files before introducing a new pattern.
- Keep controllers small; put reusable business logic in services.
- Validate every request server-side.
- Preserve `/api/v1` versioning and the `{message, data}` response contract.
- Use Form Requests, Policies, Resources, and existing repository/provider
  patterns.
- Keep uploaded documents and evidence private.
- Use generated storage names and validate file signatures, not only extensions.
- Never fetch arbitrary user URLs from the backend.
- Do not place API keys or secrets in Flutter source.
- Do not log raw document contents, generated health answers, or user questions.
- Use explicit error handling; do not silently convert failures into successful
  results without following an existing project convention.
- Add focused tests for changed behavior and important failure paths.
- Preserve Bangla text support and avoid layout changes that clip Bangla content.
- Keep visual changes separate from repositories, models, providers, and API
  contracts.

## Critical Warnings Before Changing Code

1. Read the relevant controller, service, request, resource, Flutter repository,
   provider, model, screen, and tests before changing a feature.
2. The document scan response contract is already inconsistent. Resolve the
   intended contract before changing either side.
3. The AI test endpoint and its existing test disagree. Clarify whether the
   endpoint is a real Ollama test or a placeholder before modifying it.
4. Do not replace deterministic health emergency handling with an LLM call.
5. Do not send full private documents or unnecessary personal data to an LLM.
6. Do not centralize Ollama calls or change prompts without preserving existing
   error handling and tested response parsing.
7. Tighten CORS, token lifetime, rate limits, upload limits, and production HTTPS
   only after checking deployment requirements and environment configuration.
8. Do not alter migrations, seeded reviewed health content, authentication, file
   ownership policies, or API response shapes casually.
9. URL analysis must remain non-network-fetching unless a separately approved
   threat-intelligence design includes SSRF protections.
10. Existing full Laravel validation has two known failures: the AI test contract
    mismatch and the document resource mismatch. Do not report the complete suite
    as passing until those are resolved.

