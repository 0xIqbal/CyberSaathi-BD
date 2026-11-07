# Previous Work Summary

## Project Overview

CyberSaathi BD is a cybersecurity-focused application with a Laravel 13
backend and a Flutter mobile/web client. The project currently includes
authentication, suspicious URL analysis, document privacy scanning, and a
Digital Evidence Organizer.

The Laravel application is in the repository root and the Flutter application
is under `mobile/`.

## Initial Architecture and Design

- Defined functional and non-functional requirements.
- Designed a modular Laravel API and Flutter feature architecture.
- Added API versioning under `/api/v1`.
- Chose Sanctum for API authentication.
- Chose private file storage for sensitive documents and evidence.
- Planned MySQL support while using SQLite locally.
- Prioritized privacy, ownership checks, input validation, maintainability,
  explainable analysis, and realistic capstone scope.
- Deferred advanced features such as public evidence sharing, automatic legal
  reporting, live URL fetching, and large-scale asynchronous AI workflows.

## Flutter Application Foundation

Created a Material 3 design system using deep navy and teal branding:

- Colors and accessible contrast
- Typography and spacing tokens
- Buttons and input fields
- Cards and app bars
- Status indicators
- Loading, empty, and error states

The Flutter project uses modular features, Riverpod state management, Dio, and
`file_picker`. Platform-aware API URLs are configured as:

```text
Web:             http://127.0.0.1:8000/api/v1
Android emulator: http://10.0.2.2:8000/api/v1
```

## Laravel Authentication

Implemented Sanctum-protected authentication:

- Registration
- Login
- Logout
- Current-user endpoint
- Form Request validation
- Consistent JSON responses
- Protected navigation in Flutter
- Secure token storage in Flutter

Health endpoint:

```text
GET /api/v1/health
```

## Suspicious URL Analyzer

Added:

```text
POST /api/v1/url-analyses
```

The analyzer includes:

- URL validation and normalization
- IP-host detection
- Punycode detection
- Suspicious pattern detection
- Excessive subdomain detection
- Protected-brand similarity checks
- Explainable risk indicators
- Rate limiting

Submitted URLs are treated as data and are never opened, resolved, fetched, or
redirected by the backend.

## Document Privacy Scanner

Added:

```text
POST /api/v1/document-scans
GET  /api/v1/document-scans/{id}
```

Supported formats are PDF and DOCX. The scanner includes:

- File signature validation
- Private generated storage paths
- SHA-256 hashes
- Bounded text extraction
- Phone, email, student-ID, and password-like detection
- Masked findings with positions
- User ownership checks
- Upload rate limiting
- Optional masked Bangla privacy explanations through local Ollama

### Flutter Document Scanner Integration

Added the feature under:

```text
mobile/lib/features/document_scanner/
```

It includes models, repository, Riverpod state, file picking, upload and scan
progress, result cards, finding cards, empty states, error states, and
dashboard navigation.

The shared Flutter API client was rewritten to restore valid generic return
types, valid Dart syntax, multipart support, and 120-second connect, send, and
receive timeouts. Authenticated requests use:

```text
Authorization: Bearer <token>
```

Flutter Web uploads use file bytes, while native uploads use the local file
path. The Laravel upload field is `document`. API and Dio failures include
status and backend response diagnostics in development logs.

`DocumentScan.fromJson()` supports both direct objects and Laravel responses
wrapped in a `data` object, including nested findings and `ai_explanation`.

## AI Test Endpoint and CORS

Added the temporary protected endpoint:

```text
POST /api/v1/ai/test
```

It uses Sanctum and has authenticated/unauthenticated feature tests.

Added local-development CORS configuration for:

```text
api/*
sanctum/csrf-cookie
```

All origins, methods, and headers are allowed for local development. A
document-upload OPTIONS preflight test was added and passed.

## Digital Evidence Organizer Backend

### Database foundation

Added these migrations without changing existing authentication or scanner
migrations:

```text
database/migrations/2026_11_06_142238_create_incidents_table.php
database/migrations/2026_11_06_142239_create_evidence_items_table.php
database/migrations/2026_11_06_142240_create_incident_events_table.php
```

The tables provide:

- User-owned incidents with title, category, description, status, and
  timestamps
- Evidence items belonging to incidents
- Image, PDF, URL, and note evidence types
- Private storage paths and original filenames
- SHA-256 fingerprints
- Incident timeline events with `occurred_at`
- Foreign keys, cascade deletion, and useful indexes

Uploaded file contents are never stored in MySQL.

### Models and relationships

Added:

```text
app/Models/Incident.php
app/Models/EvidenceItem.php
app/Models/IncidentEvent.php
```

Relationships:

- `User hasMany Incident`
- `Incident belongsTo User`
- `Incident hasMany EvidenceItem`
- `Incident hasMany IncidentEvent`
- `EvidenceItem belongsTo Incident`
- `IncidentEvent belongsTo Incident`

Models use explicit `$fillable` fields. `IncidentEvent` uses `occurred_at`
instead of Laravel's normal model timestamps.

### Incident Management API

Added ownership policy, Form Requests, API resources, controller, routes, and
feature tests:

```text
app/Policies/IncidentPolicy.php
app/Http/Requests/Api/V1/StoreIncidentRequest.php
app/Http/Requests/Api/V1/UpdateIncidentRequest.php
app/Http/Resources/Api/V1/IncidentResource.php
app/Http/Resources/Api/V1/IncidentEventResource.php
app/Http/Controllers/Api/V1/IncidentController.php
tests/Feature/Api/IncidentApiTest.php
```

Endpoints:

```text
GET    /api/v1/incidents
POST   /api/v1/incidents
GET    /api/v1/incidents/{incident}
PATCH  /api/v1/incidents/{incident}
DELETE /api/v1/incidents/{incident}
```

All endpoints require Sanctum. Users can only access their own incidents.
Listing is paginated and includes evidence counts. Creating an incident and
changing its status creates timeline events.

### Evidence Management API

Added:

```text
app/Http/Requests/Api/V1/StoreEvidenceRequest.php
app/Services/EvidenceService.php
app/Http/Controllers/Api/V1/EvidenceController.php
app/Http/Resources/Api/V1/EvidenceItemResource.php
tests/Feature/Api/EvidenceApiTest.php
```

Endpoints:

```text
POST /api/v1/incidents/{incident}/evidence
GET  /api/v1/incidents/{incident}/evidence/{evidence}/download
```

Evidence behavior:

- Supports `image`, `pdf`, `url`, and `note`.
- Image and PDF uploads are limited to 10 MB.
- Files are stored under private `storage/app/private/evidence/`.
- UUID filenames are generated.
- SHA-256 hashes are computed from uploaded file contents.
- URL and note content is stored in the description field.
- Evidence creation automatically records a timeline event.
- Downloads verify incident ownership and evidence membership.
- Stored files are removed if database persistence fails.

## Flutter Digital Evidence Vault

Added the feature under:

```text
mobile/lib/features/evidence_vault/
```

### Models

Created separate:

```text
data/models/incident.dart
data/models/evidence_item.dart
data/models/incident_event.dart
```

The models safely parse IDs, titles, categories, statuses, SHA-256 hashes,
dates, nested evidence lists, nested timeline lists, and Laravel responses
containing a nested `data` object.

### Repository and providers

Added:

```text
data/repositories/evidence_repository.dart
presentation/viewmodels/evidence_provider.dart
```

Repository operations:

```text
getIncidents()
createIncident()
getIncidentDetails(id)
uploadEvidence(incidentId, file, type, description)
```

The Riverpod notifier handles loading, saving, validation errors, API errors,
incident creation, incident detail loading, upload progress, and state
refreshing after an evidence upload.

### Web and native upload flow

The evidence picker uses `withData: true` so Flutter Web receives file bytes.

Web upload:

```dart
MultipartFile.fromBytes(file.bytes!, filename: file.name)
```

Native upload:

```dart
MultipartFile.fromFileSync(file.path!, filename: file.name)
```

Multipart fields sent to Laravel are:

```text
type
description
file
```

After a successful upload, the provider calls
`getIncidentDetails(incidentId)` and stores the refreshed incident, so the
attached evidence list updates automatically before the screen is closed.

### Vault screens

- `EvidenceHomeScreen`
  - Lists user incidents in Material 3 cards
  - Shows category, status, evidence count, and creation date
  - Provides refresh, loading, empty, and error states
  - Provides a create-incident floating action button
- `CreateIncidentScreen`
  - Provides title, category, and description fields
  - Supports `online_scam`, `phishing`, `cyberbullying`,
    `account_compromise`, `identity_impersonation`, and `other`
- `IncidentDetailsScreen`
  - Shows incident details and status
  - Shows evidence cards and SHA-256 fingerprints
  - Shows a vertical activity timeline
- `AddEvidenceScreen`
  - Supports JPG, JPEG, PNG, PDF, URL, and note evidence
  - Uses `file_picker`
  - Shows selected filename, size, and upload progress
  - Pops after successful upload

The Evidence Vault is connected to the authenticated dashboard.

## Testing and Validation

Laravel validation completed:

- Incident CRUD and ownership tests
- Evidence upload, hashing, event, download, validation, and cross-user tests
- Database relationship tests
- Sanctum authentication tests
- CORS preflight test
- Laravel Pint formatting

Flutter validation completed:

- Targeted Evidence Vault analysis passed with no issues.
- Full Flutter test suite passed with 8 tests.
- Document scanner and URL analyzer regression tests passed.

Existing unrelated analyzer notices remain in older document scanner and URL
checker files, including development `print` calls and deprecated
`withOpacity` usage.

## Current Architecture and Security Notes

- API routes are versioned under `/api/v1`.
- Sanctum protects authenticated endpoints.
- Flutter sends `Authorization: Bearer <token>`.
- Uploaded evidence and documents remain private.
- Ownership is checked before incident access and evidence downloads.
- Submitted URLs are never fetched or executed.
- Sensitive document and evidence contents should not be logged unnecessarily.
- SQLite is used locally; the deployment target supports MySQL.
- Ollama/Qwen3 remains a local integration and is not exposed directly to
  Flutter.

## Current Configuration Notes

- Ollama is installed locally.
- Qwen3 model configuration still requires local setup and environment values.
- Production deployment still requires debug disabling, secret configuration,
  private storage verification, and production CORS restrictions.

## Recommended Next Steps

- Add focused Flutter tests for Evidence Vault model parsing, repository
  requests, upload progress, and empty/error states.
- Add Flutter download support for private evidence files.
- Add file-content/signature validation beyond extension and MIME checks.
- Delete private stored files when evidence or incidents are deleted.
- Add a dedicated evidence policy if evidence operations grow independently of
  incident ownership.
- Move Ollama explanation generation to a queue or separate endpoint.
- Run the complete Laravel suite after the next backend change.
