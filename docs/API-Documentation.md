# API Documentation

## Base URL

All application endpoints are versioned under:

```text
/api/v1
```

## Endpoint Groups

- `/auth` — registration, login, logout, and password recovery
- `/url-analyses` — URL submission, results, history, and feedback
- `/documents` — secure upload, scans, findings, and reports
- `/health` — categories, curated articles, questions, and feedback
- `/evidence-cases` — cases and evidence items
- `/processing-jobs` — asynchronous job status

URL analysis:

```text
POST /api/v1/url-analyses   [protected, rate-limited]
```

The request body is `{ "url": "https://example.com" }`. The response
contains the normalized URL, a heuristic risk level and score, explainable
indicators, and explicit limitations. The backend never opens, resolves, or
follows the submitted URL.

## Document Privacy Scanner

```text
POST /api/v1/document-scans          [protected, rate-limited]
GET  /api/v1/document-scans/{id}    [protected, owner-only]
```

Submit a multipart `document` field containing a PDF or DOCX file. Files are
size-limited, validated using content signatures and container structure, and
stored under generated names on the private local disk. The scanner extracts
bounded text only for processing, stores masked findings and byte positions,
and does not persist the full extracted text. It never executes document
content or makes network requests.

## Authentication Endpoints

All protected requests use a Laravel Sanctum bearer token:

```text
Authorization: Bearer <token>
```

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout   [protected]
GET  /api/v1/auth/me       [protected]
```

Registration and login return a token and a serialized user under `data`.
Logout revokes only the current token. Invalid credentials return a
consistent `INVALID_CREDENTIALS` error without revealing whether the email
exists.

## API Rules

- Require authentication for user-owned resources.
- Enforce ownership server-side.
- Return consistent error codes and a request ID.
- Never expose storage paths, stack traces, secrets, or raw provider errors.
