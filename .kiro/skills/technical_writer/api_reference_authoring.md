---
id: api_reference_authoring
version: 1.0.0
owners: [technical_writer, backend_lead]
tags: [api, openapi, reference, documentation, developer-experience]
when_to_use: |
  Any API that external developers (or even internal teams) need to
  consume. The reference is the contract. Bad reference = support
  tickets, churn, and integration outages.
inputs:
  - openapi_spec, code, real example payloads
outputs:
  - api_reference: rendered from OpenAPI + hand-authored guides
---

# API Reference Authoring

## OpenAPI is the source of truth

The spec lives in the repo, alongside the code. The reference doc
is **rendered from it** — never hand-maintained in parallel. When
they drift, the developer's faith in your docs evaporates.

If you don't have an OpenAPI spec, write one before writing docs.
Tools generate one from code (FastAPI, NestJS, Spring) — adopt one.

## What goes in a reference page (per endpoint)

```
POST /v1/orders

Create an order.

REQUEST
  Headers:
    Authorization: Bearer <token>     (required)
    Idempotency-Key: <uuid>           (recommended)
  Body (application/json):
    {
      "customer_id": "cust_abc123",   (required, string, 24 chars)
      "items": [                       (required, array, min 1)
        { "sku": "sku_xyz", "quantity": 1 }
      ],
      "currency": "USD"               (optional, ISO 4217, default: account currency)
    }

EXAMPLE REQUEST
  curl -X POST https://api.example.com/v1/orders \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Idempotency-Key: $(uuidgen)" \
    -d '{"customer_id":"cust_abc123","items":[...]}'

RESPONSE (201 Created)
  {
    "order_id": "ord_def456",
    "status": "pending",
    "total_cents": 1999,
    "currency": "USD",
    "created_at": "2026-01-15T10:30:00Z"
  }

ERRORS
  400 — validation error; see error_code + field
  401 — missing or invalid token
  402 — payment method declined (specific to this endpoint)
  409 — duplicate Idempotency-Key with different body
  429 — rate limit exceeded; check X-RateLimit-Reset header
  500 — server error (retry with idempotency key)

RATE LIMITS
  100 requests / minute per token; 10,000 / day
  Burst: 20

RELATED
  GET /v1/orders/:id      — retrieve a single order
  POST /v1/orders/:id/refund
  Webhook: order.created
```

The structure is identical across every endpoint. Predictability is
the doc's product.

## Auth section — the page developers find first

- Show how to authenticate **for each environment** (sandbox + live).
- Show the curl command in full, not as a fragment.
- Explain key rotation + revocation.
- Link to "how to test in sandbox" — every developer's second
  question.

## Error model — one place, all errors

Don't repeat the same error on every endpoint. Have a single page:

```
ERROR FORMAT (application/problem+json — RFC 7807)
{
  "type": "https://api.example.com/errors/invalid_request",
  "title": "Validation failed",
  "status": 400,
  "detail": "Field 'amount' must be positive.",
  "field": "amount",
  "error_code": "INVALID_AMOUNT"
}

GLOBAL ERROR CODES
  invalid_request — bad input; see `field` + `detail`
  authentication_required — missing or invalid bearer token
  permission_denied — token valid but lacks scope
  rate_limited — too many requests; back off per Retry-After
  ...
```

Endpoint-specific error codes link to the global page.

## Pagination — pick one strategy and document loudly

Cursor-based (default for modern APIs):
```
GET /v1/orders?limit=20&starting_after=ord_abc123

Response:
  {
    "items": [...],
    "has_more": true,
    "next_cursor": "ord_def456"
  }
```

Document:
- Default limit, max limit.
- How to start (first page = omit cursor).
- How to terminate (has_more = false).

Mixing offset and cursor pagination in the same API confuses
everyone. Pick one.

## Rate limits — show them with examples

For every endpoint, show:
- The limit (RPM, daily).
- The response headers (`X-RateLimit-Remaining`, `Retry-After`).
- The 429 response shape.
- An example of correct exponential-backoff handling.

## Versioning section

- Current major version + sunset dates for previous versions.
- How to specify a version (URL prefix `/v1/`, or header
  `API-Version: 2025-01-01` for date-based — pick one).
- Deprecation policy: how long old versions are supported.
- Changelog link.

## SDKs and code snippets

Every endpoint shows: curl + at least 2 SDK examples (Python, JS
are minimum). For a SaaS API: curl + Python + JS + Go + Ruby.

Auto-generate from the OpenAPI spec where possible
(`openapi-generator`); hand-tune the most-used ones.

## "Try it" interactive feature

Embed a request runner (Swagger UI, Redoc, Stoplight). Authenticate
with the developer's sandbox token. Show the response inline.

This single feature is the strongest doc usability improvement of
the past decade. Do it.

## Anti-patterns

- A reference doc that's NOT generated from OpenAPI. Drift is
  guaranteed.
- Examples with redacted payloads (`<your_token_here>`) that don't
  compile. Show full, working examples with sandbox tokens.
- Errors listed only as a list of codes, no example payloads.
- Pagination with hidden default limits ("returns at most 100"
  documented nowhere — discovered through pagination bugs).
- Rate limits documented as "fair use." Numbers or it doesn't exist.
- A "What's New" page that ends in 2022. Either kill it or keep it.
- A changelog with breaking changes mixed into non-breaking.
  Highlight breaks at the top.
- SDKs in 5 languages, only one of them maintained. Worse than no SDK.
- Hand-edited HTML reference that gets out of date 3 days after the
  next deploy. Generate from spec on every build.
