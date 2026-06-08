---
id: multi_tenancy_patterns
version: 1.0.0
owners: [database_architect, architect, security_engineer]
tags: [multi-tenancy, isolation, saas, gdpr, blast-radius]
when_to_use: |
  Building a multi-tenant SaaS. The tenant-isolation decision is
  one of the most expensive to reverse — it dictates schema, IAM,
  backup, deletion, billing, and noisy-neighbor blast radius for
  the entire product life.
inputs:
  - tenant_count, isolation_requirement, gdpr_exposure
outputs:
  - "multi_tenancy_decision: pattern + per-pattern tradeoffs documented as ADR"
---

# Multi-Tenancy Patterns — Pick The One That Survives Your Compliance Auditor

> Three viable patterns. The one you pick affects EVERYTHING:
> queries, backup strategy, GDPR delete, on-call blast radius,
> per-tenant pricing model. Decide deliberately.

## The three patterns

### 1. Row-level (shared schema, tenant_id column)

```sql
CREATE TABLE orders (
  id          UUID PRIMARY KEY,
  tenant_id   UUID NOT NULL REFERENCES tenants(id),
  ...
);
CREATE INDEX orders_tenant_idx ON orders(tenant_id, created_at DESC);

-- Every query MUST include tenant_id in WHERE.
-- Use Postgres ROW-LEVEL SECURITY policies for defense-in-depth:
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.tenant_id')::UUID);
```

- Pros: cheapest, simplest, easiest to operate.
- Cons: noisy-neighbor risk, GDPR delete touches every row,
  one app bug → cross-tenant data leak.
- Use for: low-tier multi-tenant (< 10k tenants), SMB SaaS,
  free-tier-heavy products.

### 2. Schema-per-tenant (Postgres SCHEMA or MySQL DATABASE)

```sql
CREATE SCHEMA tenant_acme;
CREATE TABLE tenant_acme.orders (...);

-- Or N small DBs in the same cluster:
CREATE DATABASE tenant_acme;
```

- Pros: clean isolation, easy GDPR delete (DROP SCHEMA),
  per-tenant backup, per-tenant maintenance windows possible.
- Cons: O(N) schemas — migrations run N times, schema sprawl,
  N's max is bounded by DB engine (~1000s).
- Use for: mid-tier B2B SaaS, 100-1000 tenants, regulated
  industries.

### 3. Database-per-tenant (separate DB instance / cluster)

- Pros: hardest isolation; per-tenant resource limits,
  encryption keys, region, backup. Strongest compliance story.
- Cons: most expensive (per-tenant infra), per-migration
  orchestration, complex cross-tenant analytics.
- Use for: enterprise tier, healthcare / finance, residency
  requirements (GDPR / data localization), top of price ladder.

## Hybrid: tiered isolation

Most mature SaaS run more than one pattern:
- Free + SMB: row-level.
- Mid-market: schema-per-tenant.
- Enterprise: database-per-tenant or even VPC-per-tenant.

Plan for migration paths BETWEEN tiers. Going from row-level to
schema-per-tenant for a single customer is non-trivial; design
it as part of the tier upgrade flow.

## Decision matrix

| Factor | Row | Schema | DB |
|---|---|---|---|
| Tenant count | 1 to ∞ | up to ~1k | up to ~100s easily |
| Setup cost per tenant | ~0 | seconds | minutes |
| GDPR delete cost | full scan | DROP SCHEMA | drop DB |
| Cross-tenant query | trivial | expensive | very expensive |
| Cross-tenant analytics | trivial | requires aggregation | requires aggregation |
| Per-tenant encryption keys | hard | possible | trivial |
| Blast radius (1 query down) | all tenants | one tenant | one tenant |
| Migration discipline | 1 path | N paths | N paths |

## Postgres RLS — when row-level is enough but you want defense

Row-level security is the safety net for row-level multi-tenancy:

```sql
-- Force every query to filter by tenant
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_iso ON orders
  USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
```

App code sets `SET LOCAL app.tenant_id = '...'` per request. Even
if a developer forgets WHERE tenant_id, RLS blocks the cross-tenant
read. Belt + suspenders.

Trade-off: RLS adds 5-10% query overhead and complicates query
plan analysis. Worth it for compliance.

## Migration: row-level → schema-per-tenant

The hard one. Plan:

1. Pick the FIRST tenant to migrate (small, willing pilot).
2. Build dual-write: app writes to both row-level AND new schema.
3. Verify reads from new schema match row-level for the pilot.
4. Switch reads.
5. Stop writes to row-level for that tenant.
6. Repeat for each tenant.
7. Drop row-level data for migrated tenants.

This is months of work; budget accordingly.

## GDPR + data residency

- **GDPR Article 17 (right to erasure)**: documented delete
  cascade plan per tenant. Row-level: chained DELETE across tables.
  Schema-per-tenant: DROP SCHEMA. DB-per-tenant: DROP DATABASE.
  Latter two are cleaner.
- **Data residency** (e.g., EU customer data must stay in EU):
  effectively requires database-per-tenant in the customer's
  region. Or row-level with region-aware sharding (complex).
- **Backup**: per-tenant restore requires per-tenant backup unit.
  Schema-per-tenant or DB-per-tenant make this easy; row-level
  needs filtered restore which is operationally painful.

## Anti-patterns

- **Single shared DB without tenant_id on every row.** Cross-tenant
  data leak is a matter of time.
- **`SELECT *` patterns in row-level multi-tenancy.** Eventually
  someone forgets WHERE tenant_id. Use RLS.
- **Mixing tenants in the same row** (e.g., `tenant_ids JSON[]`).
  Permissioning becomes impossible.
- **Picking schema-per-tenant for 100k tenants.** PG bogs down
  past ~10k schemas.
- **No tier-migration plan.** A pilot customer outgrows row-level;
  you have no path forward.

## Validation

- [ ] One pattern per tier; tier upgrade has a migration runbook.
- [ ] RLS policies in place for any row-level multi-tenant table.
- [ ] GDPR delete cascade tested per tenant tier.
- [ ] Cross-tenant analytics has a defined separate path (e.g., a
      warehouse that aggregates with explicit consent).
- [ ] Per-tenant backup / restore drilled in the last 90 days.
