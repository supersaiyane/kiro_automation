---
id: api_versioning
version: 1.0.0
owners: [backend_lead, architect]
tags: [api, versioning, contract, backwards-compatibility]
when_to_use: |
  Designing a public API surface or making a breaking change to an
  existing one. Use BEFORE the FE team has integrated, not after.
inputs:
  - endpoint_spec: HTTP method, path, request, response schema
outputs:
  - versioning_strategy: URL prefix, deprecation policy, rollout plan
---

# API Versioning

**Strategy: URL-prefixed semver-major (`/v1/`, `/v2/`)**

- New non-breaking fields → same version. Document as additive.
- Breaking changes (rename, remove, type change) → bump major.
- Run N and N-1 in parallel for at least one sprint AFTER announcement.
- Deprecation header on N-1: `Deprecation: true`, `Sunset: <RFC3339>`.

**Request/response design rules**

- Always wrap collections: `{ "items": [...], "next_cursor": "..." }`.
  Never return a top-level array — you can't add metadata later without
  a breaking change.
- Errors use `application/problem+json` (RFC 7807).
- Timestamps in ISO-8601 UTC with explicit `Z`.
- Money in minor units (cents) + ISO 4217 currency code.

**Anti-patterns**
- Versioning per-endpoint instead of per-API.
- Skipping the parallel-run period.
- Returning 200 with an error body — use HTTP status codes.
