# Security Testing

## Required Coverage

- Authentication and authorization bypass
- Object-level access control and IDOR
- File type, size, signature, and path validation
- Malicious and malformed document handling
- Rate limiting and abuse controls
- Injection and mass-assignment protection
- Secret and sensitive-log scanning
- LLM prompt data minimization
- Private storage access controls
- Evidence hash and audit-history integrity

## Security Principles

- Fail closed when verification services are unavailable.
- Never report an external-service failure as a safe result.
- Use synthetic data for demonstrations.
- Do not log passwords, tokens, raw documents, or unnecessary health content.
