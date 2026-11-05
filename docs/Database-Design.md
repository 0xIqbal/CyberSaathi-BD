# Database Design

## Core Entities

- Users
- URL analyses and indicators
- Documents, scans, and findings
- Health categories, articles, and queries
- Evidence cases, items, and tags
- Audit logs

## Design Rules

- Store timestamps in UTC.
- Enforce foreign keys and user ownership.
- Index ownership, status, and relationship columns.
- Keep uploaded files in private storage; store generated storage keys in the database.
- Store hashes for evidence and uploaded documents.
- Minimize retention of health questions and sensitive findings.
