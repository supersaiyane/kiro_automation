---
id: auth_design
version: 1.0.0
owners: [security_engineer, backend_lead, architect]
tags: [authentication, authorization, oauth, oidc, jwt, rbac, abac]
when_to_use: |
  Any new service with a user surface, or an integration that exposes
  data across tenants. Get authn (who) and authz (what) right from
  day one; retrofitting causes data-leak incidents.
inputs:
  - user_classes: end-users, internal staff, machine-to-machine
outputs:
  - auth_design: protocol, token format, scope model, lifetime
---

# Authentication & Authorization Design

## Don't conflate authn and authz

- **Authentication (authn)** = "who are you?" The login flow.
- **Authorization (authz)** = "what can you do?" The permission check.

You can get authn perfect and still leak data if authz is missing on
endpoints. They're separate failure modes.

## Authentication — pick the right protocol

| Scenario | Protocol |
|---|---|
| Web app, user logs in | **OIDC** on top of OAuth 2.0 (delegate to Auth0 / Clerk / Cognito / Keycloak) |
| Mobile / SPA | OAuth 2.0 with **PKCE**. Never implicit flow (deprecated). |
| Service-to-service inside your perimeter | **mTLS** or **workload identity** (IRSA, GCP WI) |
| Service-to-service across orgs | **OAuth 2.0 client credentials** or **signed JWTs** with audience claim |
| API tokens for power users | Long-lived bearer tokens, scoped, rotatable, revocable |
| First-factor for new account | Email + password OR email-magic-link. Never SMS for new |
| Second factor (MFA) | **WebAuthn / passkeys** (best). TOTP (fine). SMS (last resort). |

**Don't roll your own.** Auth bugs are catastrophic and silent.

## Password rules that match modern guidance (NIST 800-63B)

- **Minimum 12 characters.** No max < 64.
- **No composition rules** ("must include a symbol"). They produce
  worse passwords (`Password1!`) than passphrases.
- **No periodic rotation.** Rotate on compromise.
- **Check against a breach corpus** (HIBP API or local copy).
- Hash with **Argon2id** (preferred) or scrypt or bcrypt cost ≥12.
  Never SHA-256, never MD5, never plain.

## Sessions vs JWTs — pick deliberately

| | Server session | JWT |
|---|---|---|
| Revocation | Easy (delete from store) | Hard (need denylist or short TTL) |
| Scaling | Needs a session store | Stateless |
| Size | Small cookie | Up to several KB |
| Tampering | Server enforces | Signature verifies |
| Default for new design | **Sessions backed by Redis** | Only when stateless is needed |

JWTs are NOT a session store. Their main legitimate use is short-lived
access tokens (5-15 min) in OAuth flows, where a refresh token
(opaque, server-side) is the long-lived state.

## JWT pitfalls you must avoid

- **`alg: none`** allowed. Forces an attacker-supplied alg through.
  Reject explicitly.
- **HS256 with a short key.** Brute-forceable. Use ≥256 bits.
- **No `aud` (audience) check.** A token issued for Service A is
  accepted by Service B.
- **No `iss` (issuer) check.** Trust any signer.
- **No `exp` (expiry).** Long-lived tokens are credentials.
- **kid header trust without an allowlist.** An attacker sets `kid`
  to point to a file they uploaded. Validate kid against your key
  registry.
- **Storing sensitive data in claims.** JWTs are signed, not
  encrypted. The body is base64; anyone can read it.

## Authorization — choose the model

| Model | When |
|---|---|
| **RBAC** (role-based) | Small set of distinct roles (admin / editor / viewer). Default for most apps. |
| **ABAC** (attribute-based) | Decisions depend on resource attributes + user attributes + context (time, IP). E.g. "owner of the document can edit; same-team members can view." |
| **ReBAC** (relationship-based) | Permissions flow through relationships (Google Drive sharing, Notion). Solved by tools like Google Zanzibar, OpenFGA, SpiceDB. |
| **Capability** | Bearer tokens that *are* the permission. Time-bounded download links, signed URLs. |

For a SaaS with tenants:
- **Tenant ID is in every query**. Row-level security (Postgres RLS)
  as a backstop.
- **Role per tenant** (a user can be admin of tenant A and viewer of B).
- **Cross-tenant operations require explicit allowance** (auditable).

## The authz check is not optional — and isn't middleware-only

- Authn checks every request: middleware.
- Authz checks every action: in the handler, after you load the
  resource, before you mutate or return it.
- **Authz at the controller AND the data layer.** Defense in depth.
  Row-level security catches the bug your handler missed.

## Authorization testing

- **Negative tests** are the point. "User B cannot read User A's
  resource" — write the test that fails closed.
- **Test with multiple personas** (admin, member, anonymous,
  expired-token, cross-tenant).
- **Authorization is NOT a "happy path test passes" thing.** Each
  endpoint needs ≥3 authz tests: authorized success, unauthorized
  rejection, cross-tenant rejection.

## Common attack patterns to defend against

- **IDOR** (Insecure Direct Object Reference): `/orders/42` — does
  Bob own order 42? Always verify ownership.
- **Mass assignment**: `PUT /users/42 { is_admin: true }` — accepted
  because you spread the body into the model. Whitelist fields.
- **Privilege escalation via PATCH**: editing your own role.
- **Open redirect after login**: `?next=https://evil.com` — validate
  the redirect host.
- **Session fixation**: re-issue session ID on login.
- **Cross-site request forgery (CSRF)**: same-site cookies + CSRF
  tokens on state-changing requests.

## Anti-patterns

- "Just use JWT" without thinking about revocation. Account
  termination doesn't take effect until the JWT expires.
- Building your own OAuth server. Use a battle-tested implementation.
- Permissions checked only in the frontend. The API is the security
  boundary, not the UI.
- A single `is_admin` boolean. Within 6 months you need three more
  bits of authorization and you're patching.
- "We'll add tenant scoping later." Then someone reads another
  tenant's data and you have a regulatory incident.
- Tokens that don't carry a tenant claim. Cross-tenant bugs become
  trivial.
- Logging the bearer token. Even partial — first 8 chars is enough
  for some attacks.
