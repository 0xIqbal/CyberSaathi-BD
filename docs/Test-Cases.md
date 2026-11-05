# Test Cases

## URL Checker

- Analyze a valid benign URL.
- Reject malformed input.
- Detect suspicious URL indicators.
- Handle provider timeout without returning a safe result.
- Prevent one user from reading another user's analysis.

## Document Scanner

- Accept supported PDF and DOCX files.
- Reject unsupported, oversized, and malformed files.
- Detect metadata and known sensitive patterns.
- Process scans asynchronously.
- Delete the document and associated results.

## Health Navigator

- Search in Bangla and English.
- Return answers grounded in approved content.
- Display source and review date.
- Escalate emergency or unsafe questions.

## Evidence Vault

- Create a case and add an evidence item.
- Generate a reproducible SHA-256 hash.
- Prevent cross-user access.
- Export a case report.
- Record important changes in the audit history.
