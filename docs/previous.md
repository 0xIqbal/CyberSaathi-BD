# Previous Work Summary

## Project Structure

- Moved the Laravel application from `backend/` to the repository root.
- Kept the Flutter application under `mobile/`.
- Added project documentation under `docs/`.
- Added workspace Copilot instructions under `.github/copilot-instructions.md`.

## Flutter Application

- Created a Material 3 design system with:
  - Deep navy and teal colors
  - Typography and spacing tokens
  - Buttons, inputs, cards, app bars, status indicators, loading states, empty states, and error states
- Added modular feature structure for `url_checker`.
- Added authentication foundation:
  - API service
  - Secure token storage
  - Authentication repository
  - Authentication state management
  - Login screen
  - Registration screen
  - Protected navigation
- Added platform-aware API URLs:
  - Web: `http://127.0.0.1:8000/api/v1`
  - Android emulator: `http://10.0.2.2:8000/api/v1`

## Laravel Backend

- Set up Laravel 13 with Sanctum.
- Implemented authentication:
  - Registration
  - Login
  - Logout
  - Current user endpoint
  - Protected API routes
  - Form Request validation
  - Consistent JSON responses
- Added reusable API response and request structures.
- Added API versioning under `/api/v1`.
- Added health endpoint:

```text
GET /api/v1/health
```

## URL Analyzer

- Added protected URL analysis endpoint:

```text
POST /api/v1/url-analyses
```

- Added:
  - URL validation and normalization
  - IP-host detection
  - Punycode detection
  - Suspicious pattern detection
  - Excessive subdomain detection
  - Protected brand similarity checks
  - Explainable risk indicators
  - Rate limiting
- The analyzer never opens, resolves, or fetches submitted URLs.

## Document Privacy Scanner

- Added protected document scanning endpoints:

```text
POST /api/v1/document-scans
GET /api/v1/document-scans/{id}
```

- Supports PDF and DOCX files.
- Added:
  - File signature validation
  - Private generated storage paths
  - SHA-256 hashes
  - Bounded text extraction
  - Phone detection
  - Email detection
  - Configurable student ID detection
  - Context-aware password-like detection
  - Masked findings with positions
  - User ownership checks
  - Upload rate limiting
  - The backend now attempts to generate a masked Bangla privacy explanation
    through local Ollama, with a safe fallback message when Ollama is unavailable.

  ## Recent Step-by-Step Integration Work

  ### 1. Flutter document scanner foundation

  - Added the Flutter document scanner feature under:

  ```text
  mobile/lib/features/document_scanner/
  ```

  - Added:
    - `DocumentScan` and `DocumentFinding` models
    - Document scan repository
    - Riverpod notifier and state
    - File picker integration
    - Upload progress
    - Scanning progress
    - Result and finding cards
    - Error and empty states
    - Dashboard navigation

  ### 2. Flutter API client corrections

  - Rewrote `mobile/lib/core/network/api_service.dart`.
  - Fixed corrupted generic return types such as:

  ```dart
  Future<Map<String, dynamic>>
  ```

  - Added 120-second connect, send, and receive timeouts.
  - Added multipart upload support.
  - Corrected authentication headers to:

  ```text
  Authorization: Bearer <token>
  ```

  ### 3. Flutter Web upload support

  - Updated document upload handling for both platforms:
    - Flutter Web uses `MultipartFile.fromBytes(...)`.
    - Native platforms use `MultipartFile.fromFileSync(...)`.
  - Confirmed that the Laravel multipart field name is:

  ```text
  document
  ```

  - Added logging for API and Dio upload failures, including:
    - Error message
    - Status code
    - Error code
    - Backend response errors
    - Stack trace

  ### 4. Nested Laravel response parsing

  - Updated `DocumentScan.fromJson()` to support both:
    - A direct scan object
    - Laravel's wrapped response format:

  ```json
  {
    "message": "Document scan completed.",
    "data": {}
  }
  ```

  - The parser now reads `findings` and `ai_explanation` from the nested `data`
    object.

  ### 5. AI explanation display fix

  - Ensured the upload repository parses the response with
    `DocumentScan.fromJson()`.
  - Updated the Riverpod notifier to preserve the complete scan returned from
    the upload response.
  - Avoided replacing the result with a follow-up response that may omit the
    transient `ai_explanation` field.
  - Added an AI advisory card to the scanner result screen.

  ### 6. Temporary protected AI endpoint

  - Added:

  ```text
  POST /api/v1/ai/test
  ```

  - Protected the endpoint with Laravel Sanctum.
  - Added a consistent JSON success response.
  - Added feature tests for authenticated and unauthenticated requests.

  ### 7. Flutter Web CORS support

  - Added `config/cors.php`.
  - Enabled CORS for:
    - `api/*`
    - `sanctum/csrf-cookie`
  - Allowed all origins, methods, and headers for local development.
  - Added a preflight test for:

  ```text
  OPTIONS /api/v1/document-scans
  ```

  - Confirmed that preflight requests return HTTP `204` before authentication
    and file validation.

  ### 8. Validation completed

  - Flutter document scanner tests passed.
  - Flutter analysis completed without compilation errors.
  - Laravel CORS preflight test passed.
  - Laravel Pint formatting was run.

  ## Current Document Scanner Notes

  - Laravel document scanning currently performs extraction synchronously.
  - AI explanation generation may be slow or unavailable when Ollama is not
    running.
  - The backend should eventually move AI explanation generation to a queue or
    separate endpoint so deterministic document scanning does not depend on
    Ollama response time.

## Testing and Validation

- Added Laravel feature and unit tests for authentication, URL analysis, and document scanning.
- Laravel test suite passed with 30 tests and 100 assertions during the latest backend foundation work.
- Laravel Pint formatting passed.
- Flutter SDK and dependencies are installed.
- A stale Flutter test referencing `MyApp` was identified as a remaining issue during workspace inspection.

## Current Configuration Notes

- Laravel currently uses SQLite locally.
- MySQL PHP extensions are available, but MySQL connection settings are not configured.
- Ollama is installed locally.
- Qwen3 model integration is not configured yet.
- Production deployment settings still require hardening, including disabling debug mode and configuring production secrets.
