---
id: api_security_owasp_top10
version: 1.0.0
owners: [security_engineer, backend_lead, architect]
tags: [api-security, owasp-api, bola, mass-assignment, rate-limiting, schema-validation]
when_to_use: |
  Designing or auditing any HTTP / gRPC / GraphQL API. APIs have their
  own OWASP Top 10 (separate from the web-app one) because the attack
  surface is different — no browser to layer protections on, every
  endpoint is an exposed door.
inputs:
  - api_contract, auth_model, threat_model
outputs:
  - "api_security_checklist: per-endpoint hardening + testing + rate limits + schema enforcement"
---

# API Security — OWASP API Top 10 (2023)

> Web app security tools assume a browser; API security can't. Every
> endpoint is directly callable by anyone who finds it. The OWASP API
> Top 10 (refreshed 2023) is the lens for this distinct attack
> surface.

## The 2023 list

| # | Risk | What it is |
|---|---|---|
| 1 | **BOLA** (Broken Object Level Authorization) | API accepts an ID and returns/modifies that object without checking the user owns it |
| 2 | **Broken Authentication** | Token reuse, weak rotation, predictable session IDs |
| 3 | **Broken Object Property Level Authorization** | Mass assignment, excessive data exposure |
| 4 | **Unrestricted Resource Consumption** | No rate limit; one client can DoS or run up bills |
| 5 | **Broken Function Level Authorization** | Admin endpoint accessible by non-admin |
| 6 | **Unrestricted Access to Sensitive Business Flows** | Bypassing intended UX (rapid checkout, ticket scalping) |
| 7 | **Server-Side Request Forgery (SSRF)** | API fetches user-supplied URL; attacker pivots to internal services |
| 8 | **Security Misconfiguration** | Default creds, verbose errors, headers missing |
| 9 | **Improper Inventory Management** | Old API versions still serving; undocumented endpoints |
| 10 | **Unsafe Consumption of APIs** | Third-party API calls without input validation |

## API1 — BOLA (the #1 by far)

```python
# VULNERABLE
@app.get("/api/orders/{order_id}")
def get_order(order_id: int):
    return db.orders.get(order_id)   # missing: is this user's order?

# FIXED
@app.get("/api/orders/{order_id}")
def get_order(order_id: int, user: User = Depends(current_user)):
    order = db.orders.get(order_id)
    if not order or order.user_id != user.id:
        raise HTTPException(404)
    return order
```

Test EVERY endpoint that takes an ID with a different user's ID. Most
modern auth libs (Casbin, Cerbos, OPA, Cedar) let you define this once.

## API3 — Mass Assignment + Over-fetching

```python
# VULNERABLE — user can promote themselves to admin
@app.patch("/api/users/{user_id}")
def update(user_id, body: dict):
    db.users.update(user_id, **body)   # **body == is_admin=True if attacker sends it

# FIXED — explicit allowlist via Pydantic
class UserUpdate(BaseModel):
    name: str | None = None
    email: str | None = None
    # NO is_admin field — not user-settable
@app.patch("/api/users/{user_id}")
def update(user_id, body: UserUpdate):
    db.users.update(user_id, **body.model_dump(exclude_unset=True))
```

ALSO over-fetching: don't return entities verbatim. Use response models
(Pydantic, Zod, etc.) that EXCLUDE sensitive fields.

## API4 — Rate limiting + resource quotas

```
Per-IP:           1000 req/min
Per-user:         300 req/min
Per-endpoint:     login: 5/min, search: 60/min, write: 100/min
Per-tenant tier:  free: 100/day, pro: 100k/day, enterprise: custom
Concurrent:       max 5 in-flight per user
Payload size:     max 1MB per request
Time-window:      sliding window via Redis
```

Tool: see the `rate_limiting_algorithms` backend skill. At the API layer:
return RFC-compliant `429 Too Many Requests` + `Retry-After`.

## API5 — Function-level authz

```python
# VULNERABLE
@app.delete("/api/admin/users/{user_id}")
def delete_user(user_id, user: User = Depends(current_user)):
    db.users.delete(user_id)   # any authenticated user can call this

# FIXED — role check
@app.delete("/api/admin/users/{user_id}")
def delete_user(user_id, user: User = Depends(require_role("admin"))):
    db.users.delete(user_id)
```

URL path containing "admin" is NOT authorization. Hardcoded path-based
checks miss. Centralize.

## API7 — SSRF

```python
# VULNERABLE — user supplies URL
@app.post("/api/webhook-test")
def test_webhook(url: str):
    return requests.get(url).json()  # attacker → http://169.254.169.254/...

# FIXED — allowlist scheme + resolve + block private ranges
def safe_fetch(url):
    parsed = urlparse(url)
    if parsed.scheme not in ('http', 'https'):
        raise ValueError("scheme")
    ip = socket.gethostbyname(parsed.hostname)
    if ipaddress.ip_address(ip).is_private:
        raise ValueError("private IP")
    return requests.get(url, timeout=5, allow_redirects=False)
```

Even better: route ALL outbound through a proxy that enforces allowlist
+ inspects traffic.

## API9 — Inventory management

- Document EVERY endpoint (OpenAPI 3.1+).
- Auto-generate from code (FastAPI does this for free).
- Sunset old API versions with deprecation headers + 410 Gone eventually.
- "Shadow APIs" (undocumented endpoints) are the biggest risk — they don't
  get the same hardening.

Tool: Salt Security, Noname, 42Crunch, or open-source ZAP for API
discovery + drift.

## GraphQL-specific concerns

- **Query depth limit** — block 1000-deep nested queries.
- **Query complexity limit** — cost analysis (Apollo).
- **Introspection disabled in prod** (or auth-gated).
- **Aliases / batching limits** — prevent DoS via fragment explosion.
- **Field-level authorization** — every field check, not just queries.

## gRPC-specific concerns

- mTLS by default.
- Auth interceptors apply to ALL methods.
- Stream cancellation handled (don't lose money on uncancelled work).
- Reflection disabled in prod.

## Schema validation — the cheap mitigation

Run input through a strict schema (Pydantic, Zod, ajv) BEFORE business
logic. Strict mode = reject unknown fields → mass assignment dies in the
parser.

```python
# Pydantic v2
class TransferRequest(BaseModel):
    model_config = ConfigDict(extra='forbid')   # reject unknown keys
    amount: Decimal = Field(gt=0, le=10000)
    to_account: str = Field(pattern=r'^[A-Z]{2}\d{10}$')
```

Any junk → 422 before your code runs.

## Security headers (even for APIs)

```
Strict-Transport-Security: max-age=63072000; includeSubDomains
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'none'   # APIs return JSON
Cache-Control: no-store                       # for sensitive endpoints
Referrer-Policy: no-referrer
Permissions-Policy: ...
```

## CORS — restrict, don't widen

```python
# VULNERABLE
allow_origins = ['*']
allow_credentials = True   # combination = credential theft from any site

# FIXED
allow_origins = ['https://app.example.com', 'https://staging.example.com']
allow_credentials = True
```

NEVER `*` with credentials.

## Audit + observability

Every API call logged with:
- request_id, user_id, tenant_id
- endpoint + method + status code
- duration
- IP + user agent (sampled)

Anomaly detection on: spike in 401/403, spike in 429, single user enumerating
IDs (BOLA reconnaissance).

## Testing — automated + manual

- **OWASP ZAP** — automated baseline scan in CI.
- **Burp Suite** — manual testing during pen test.
- **Postman tests** — auth checks in test collections.
- **Schema-based fuzzing** — RESTler, Schemathesis.
- **OWASP API Crackle** — designed for the OWASP API Top 10.

Specific manual tests for every API in pen test scope:
1. Take a valid request from user A, swap object ID to user B's → BOLA?
2. Add `"is_admin": true` to body → mass assignment?
3. Hit admin endpoint without admin role → BFLA?
4. Send 1000 req/sec to login → rate limit?
5. Submit URL params for SSRF endpoints → blocked?
6. Cause errors → leak stack trace / DB schema?
7. Old API version /v1 still works? Same protections as /v2?

## Anti-patterns

- **"Auth is in the gateway, the backend trusts it."** Defense in depth —
  authz at every layer.
- **Authorization in the controller via `if`.** Centralize in middleware
  or policy engine.
- **Verbose errors in prod.** Leaks. Generic + log-internally.
- **Allowing ANY content-type to ANY endpoint.** Lock down explicit accepts.
- **Documentation drift** between API + reality.
- **Different rate limits per endpoint, none of them enforced consistently.**
- **CORS = `*`.** Period.
- **API keys in URL query params.** They land in logs forever.

## Validation

- [ ] OWASP API Top 10 pen-tested annually.
- [ ] Every endpoint has authz documented + enforced.
- [ ] BOLA / mass-assignment tests pass.
- [ ] Rate limits enforced + monitored.
- [ ] OpenAPI spec matches production.
- [ ] No shadow APIs (undocumented endpoints).
- [ ] Security headers + CORS reviewed.
- [ ] Schema-validation rejects unknown fields.
