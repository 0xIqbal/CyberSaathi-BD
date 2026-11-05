# System Architecture

## Overview

CyberSaathi BD uses a Flutter mobile client and a Laravel modular monolith connected through versioned HTTPS JSON APIs.

```text
Flutter mobile app
        |
      HTTPS
        |
Laravel API -> MySQL
        |
        +-> private file storage
        +-> queued processing
        +-> LLM and reputation providers
```

## Module Boundaries

- Flutter features are organized by feature and split into data and presentation layers.
- Laravel services isolate URL, document, AI, health, and evidence workflows.
- Authentication, authorization, validation, storage, queues, and audit logging are shared infrastructure.

## Decisions

- Use a modular monolith instead of microservices for capstone feasibility.
- Run document processing asynchronously.
- Apply deterministic checks before using an LLM.
- Ground health answers in curated content with source references.
