---
id: identity_access_management_rbac_abac
version: 1.0.0
owners: [security_engineer, architect, backend_lead]
tags: [iam, rbac, abac, rebac, pam, jit-access, sso, scim]
when_to_use: |
  Designing the authorization layer for any multi-user product, or
  auditing an existing one. IAM design is one of the highest-leverage
  security decisions — get it wrong and every feature inherits the bug.
inputs:
  - tenant_model, user_personas, regulatory_scope
outputs:
  - "iam_design: identity sources + auth flow + authz model + audit trail + lifecycle"
---

# Identity & Access Management — RBAC, ABAC, ReBAC

> Authentication is who you are. Authorization is what you can do.
> Most "auth bugs" are actually authorization bugs — IDOR, privilege
> escalation, mass assignment. Pick the model deliberately before the
> first feature ships.

## The four authorization models

| Model | Decision based on | Best for | Examples |
|---|---|---|---|
| **RBAC** (Role-Based) | User's roles → permissions | Hierarchical orgs, B2B SaaS | Workday, Salesforce |
| **ABAC** (Attribute-Based) | User attrs + resource attrs + context | Fine-grained, regulatory | AWS IAM (mostly) |
| **ReBAC** (Relationship-Based) | Graph of relationships | Collaboration, social, files | Google Drive, Notion (Zanzibar) |
| **PBAC** (Policy-Based) | Declarative policies | Cross-cutting compliance | OPA, Cedar |

Most modern systems use a HYBRID: RBAC for the org chart + ABAC for tenant
isolation + ReBAC for document-style sharing.

## RBAC done right

```
Principal (User / Service)
   ↓ has_role
Role (Admin, Manager, Member, Viewer)
   ↓ has_permission
Permission (read_invoice, edit_user, delete_order)
   ↓ on
Resource (instance / type / wildcard)
```

Rules:
- Roles are FUNCTIONAL, not departmental ("InvoiceApprover" not "Finance").
- Permissions are GRANULAR (read/write/delete/manage).
- Inheritance kept SHALLOW (≤ 2 levels deep). Deep hierarchies = audit hell.
- Wildcards are RARE; explicit is better than implicit.
- Roles ASSIGNED, not inherited from groups (or sync them explicitly).

## ABAC for fine-grained

```
ALLOW if:
  user.tenant_id == resource.tenant_id
  AND user.role in {'manager', 'owner'}
  AND resource.classification == 'internal'
  AND current_time WITHIN user.allowed_hours
  AND request.ip IN user.allowed_cidrs
```

Implemented via Open Policy Agent (OPA) / Cedar / OPAL:

```rego
# OPA Rego
package authz

default allow = false
allow {
  input.user.tenant_id == input.resource.tenant_id
  input.user.role == "manager"
  input.action == "read"
}
```

Pros: incredibly flexible. Cons: hard to audit "who can access X?" without
running queries.

## ReBAC — for collaboration

Google's Zanzibar paper popularized this. Permissions are derived from a
RELATIONSHIP graph:

```
document:invoice-42  owner   user:alice
document:invoice-42  editor  user:bob
folder:finance-q1    parent  document:invoice-42
group:finance        member  user:carol
folder:finance-q1    viewer  group:finance
```

Query: "can user:carol read invoice-42?" → traverse: carol is in finance →
finance is viewer of finance-q1 → finance-q1 is parent of invoice-42 → YES.

Implementations: SpiceDB (Authzed), Permify, OpenFGA (Auth0).

Use when: file sharing, multi-team collaboration, fine-grained content
permissions.

## Authentication — OAuth/OIDC/SAML/Passkeys

| Use | Standard |
|---|---|
| Web SSO with enterprise IdPs | SAML 2.0 |
| Modern API + mobile + SPA | OAuth 2.0 + OIDC |
| Government / banking | OIDC FAPI 2.0 |
| Passwordless / biometric | WebAuthn / passkeys |
| Machine-to-machine | OAuth 2.0 client_credentials + mTLS |
| Federated workforce | SAML / OIDC with IdP-initiated SSO + SCIM provisioning |

Modern stack: Auth0 / Okta / Authentik / Cognito for the IdP. NEVER roll
your own password hashing + JWT issuer in 2026.

**MFA mandatory** for admin + payment + privacy actions. Passkeys >>
TOTP >> SMS (which is broken).

## Service-to-service auth

- **mTLS** with workload identity (SPIFFE/SPIRE, IRSA, GCP Workload Identity,
  Azure Managed Identity).
- **Short-lived tokens** (OAuth client_credentials with 1h TTL).
- **NO** long-lived shared secrets. NO API keys in env vars.

## SCIM — automated provisioning

For B2B SaaS with enterprise IdPs:

```
IdP (Okta / Entra ID)
   ↓ POST /Users (SCIM 2.0)
Your app provisions user with role from IdP groups
   ↓ ↓ ↓
PATCH user (role change)
DELETE /Users/{id} (deprovision on departure)
```

Implementing SCIM closes the "ex-employee still has access" gap. Required for
SOC 2, ISO 27001 enterprise contracts.

## PAM — Privileged Access Management

For human admin access to prod systems:

- NO standing prod admin access. Just-in-time (JIT) elevation via
  CyberArk, Teleport, ConductorOne, AccessNow.
- Approval workflow: user requests elevation → reason → approver → access
  for N minutes → auto-revoke + log.
- Session recording for highly-privileged actions.
- Break-glass account: hardware MFA, paged-on-use, quarterly audit.

## Lifecycle — joiners / movers / leavers

```
JOINER:
  1. IdP provisions account (HRIS → Workday → Okta).
  2. SCIM pushes to all SaaS apps.
  3. Birthright access from groups (manager + role).
  4. Logged in onboarding playbook.

MOVER (role change):
  1. HRIS triggers group update.
  2. SCIM cascades.
  3. Old role access REVOKED (this is where most orgs fail).
  4. Reviewer signs off.

LEAVER:
  1. HRIS triggers offboarding.
  2. SCIM deprovisions all apps.
  3. SSH/git keys revoked.
  4. Personal devices wiped (MDM).
  5. Access logs reviewed for last 30 days.
  6. Completion confirmed by IT within 4h of departure.
```

Quarterly user access review: managers attest each report's access. Audit
control for SOC 2 + ISO 27001.

## Audit trail

Every authn event + every authz decision LOGGED:

```json
{
  "ts": "2026-05-27T14:32:11Z",
  "actor": "user:alice@example.com",
  "action": "billing.invoice.delete",
  "resource": "invoice:42",
  "decision": "allow",
  "policy_evaluated": "rbac.billing_admin",
  "request_id": "..."
}
```

Stored in append-only audit log (separate account/store). Retention per
compliance (typically 7 years).

## Anti-patterns

- **One God role** (Admin = everything). Privilege escalation = total
  compromise.
- **Permissions defined in code at endpoints** (`if user.role == 'admin'`).
  Centralize in a policy engine.
- **Wildcards everywhere** (`action: *`). One missed deny = breach.
- **Long-lived tokens.** Rotate or use short-lived + refresh.
- **Per-feature ad-hoc auth.** Eventually conflicting; audit nightmare.
- **No deprovisioning.** Ex-employees with access = top breach vector.
- **MFA optional for admins.** First and most exploited credential.
- **Service accounts everywhere.** Hard to attribute actions.
- **Roles named after teams.** "Marketing" team disbands, role becomes
  orphan; better: "CampaignEditor".

## Validation

- [ ] Every endpoint dispatches through a central authz check (not scattered
      `if` statements).
- [ ] No human has standing admin access to prod.
- [ ] MFA enforced for ALL employees (passkeys preferred).
- [ ] SCIM in place for any SaaS the company uses at scale.
- [ ] Quarterly user-access review completed.
- [ ] Audit log retains 7+ years and is immutable.
- [ ] Test: ex-employee account loses access within 4h of HRIS offboarding.
- [ ] Test: IDOR on every endpoint — pen test passed.
