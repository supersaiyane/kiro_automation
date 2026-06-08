---
id: retention_and_gdpr_deletion
version: 1.0.0
owners: [database_architect, security_engineer, legal]
tags: [retention, gdpr, ccpa, right-to-erasure, pii, deletion]
when_to_use: |
  Designing any table that holds personally identifiable information
  (PII). Retention + deletion are LEGAL requirements (GDPR Art.5,
  Art.17; CCPA 1798.105) — not features. Build them into the schema
  before the first user signs up, or pay a 4%-of-revenue fine later.
inputs:
  - pii_inventory, jurisdiction_map, business_retention_policy
outputs:
  - "retention_policy: per-table retention + deletion cascade + audit + tombstone strategy"
---

# Retention + GDPR Deletion — Schema-Native Compliance

> A "delete user" button that doesn't actually delete is a 4%-of-
> global-revenue GDPR fine. Build deletion into the schema; treat
> it as a query like any other. Bolting it on later is months of
> archeology.

## What "delete" actually means under GDPR (Art. 17)

The right to erasure requires the controller to "erase personal
data without undue delay." In practice:

- **Personal data**: anything that identifies a person, directly
  or indirectly (IDs, emails, IPs, fingerprints, behavioral data
  linked to an identity).
- **Erase**: actually gone, not just hidden by a "deleted = true"
  flag.
- **Without undue delay**: typically interpreted as within 30 days.
- **Backups**: must be erased OR you must demonstrate that
  restoring won't bring data back. Most teams use forward-
  rotation and document the window.

## The deletion cascade — design BEFORE first sign-up

For every table, document where the user's data flows to:

```
users (root)
  ├── orders.user_id           → cascade delete
  ├── sessions.user_id         → cascade delete
  ├── audit_log.actor_user_id  → tombstone (retain for compliance)
  ├── orders.created_by        → null out + reattribute to "deleted_user"
  └── payments.user_id         → cascade delete + retain payment_id
                                  for tax audit (legal retention)
```

Three patterns:
1. **Cascade delete** — child row is also erased. Default for
   pure PII.
2. **Tombstone** — child row is kept but the user-identifying
   column is nulled or replaced with a stable opaque ID. Used
   when ledgers / audit logs must persist.
3. **Anonymize** — replace PII with a hash; keep behavioral data
   for analytics in aggregate.

## The FK with ON DELETE CASCADE pattern

```sql
CREATE TABLE orders (
  id      UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ...
);
```

- Saves a manual delete-cascade orchestration script.
- BUT: cascade across many tables can be slow + lock-heavy.
- For large fan-out: implement as an async job that batches
  deletes (not a single SQL transaction).

## Soft vs hard delete

Soft delete (`deleted_at TIMESTAMPTZ`) is fine for "user can
restore." It is NOT compliant for GDPR erasure.

Hybrid pattern:
- Soft-delete by default (`deleted_at = now()`, hide from queries).
- Schedule a HARD delete job at 30-day mark.
- For GDPR request: skip the soft-delete period, hard-delete now.

## Encryption-at-rest as a delete shortcut (controversial)

"Crypto-shredding": encrypt user data with per-user keys; to
"delete," destroy the key. Data exists but is unreadable.

- Legal ambiguity: some regulators accept this, some don't.
- Operational complexity: key management lifecycle adds risk.
- Pairs well with backup-erasure problem.

Don't rely on this alone for GDPR. Use as defense-in-depth.

## Retention policy per table

Every PII-bearing table needs:

| Column / table | Retention | Justification | Deletion mechanism |
|---|---|---|---|
| `users` | forever or N days post-cancel | required service | hard delete + cascade |
| `sessions` | 90 days | security review | scheduled job |
| `audit_log` | 7 years | SOC 2 / SOX | tombstone PII, retain rest |
| `pii_attachments` (S3) | mirror parent | parent governs | DELETE on S3 object |
| `analytics_events` | 25 months | GA-standard cap | scheduled DROP partition |

Encode this in a `retention_policies` table or YAML config that
both the legal team and the deletion job reference.

## Backups and the 30-day window

The GDPR delete must propagate to backups within a "reasonable"
window. Two strategies:

1. **Short backup retention** (30 days) → next-30d backups will
   roll out the deleted data naturally.
2. **Re-process on restore** — document that any restore RUNS
   the deletion log against the restored data before the system
   comes online. Tested in DR drills.

Either is defensible; option 1 is simpler.

## The tombstone pattern (audit + financial)

Some data MUST survive deletion for legal reasons:
- Financial transactions (tax retention: 5-7 years).
- Security audit logs (SOC 2: 7 years).
- Medical records (HIPAA: 6+ years).

```sql
-- Original
INSERT INTO audit_log(actor_user_id, action, ts)
  VALUES ('uuid-42', 'order_create', now());

-- Post-deletion
UPDATE audit_log
SET actor_user_id = NULL,
    actor_opaque_id = 'redacted-user-7c8f2a'
WHERE actor_user_id = 'uuid-42';
```

The opaque ID is a stable hash for the audit trail to remain
internally consistent (linking related events without revealing
identity).

## The delete pipeline

```
[ GDPR request received ]
       ↓ (within 72h: acknowledge)
[ Verify identity ] (proof of identity required by GDPR)
       ↓
[ Schedule deletion task ]
       ↓
[ Delete from OLTP ] (cascade or tombstone per table)
       ↓
[ Delete from caches ] (Redis, CDN edge state)
       ↓
[ Delete from analytics / OLAP ]
       ↓
[ Delete from search indexes ] (Elasticsearch, Algolia)
       ↓
[ Delete from third parties ] (Mixpanel, Stripe — per their APIs)
       ↓
[ Confirm in writing within 30 days ]
       ↓
[ Audit log: this user requested + completed deletion ]
```

A "deletion service" that owns this pipeline is much safer than
ad-hoc scripts.

## CCPA / state law specifics

CCPA (California): right to delete, with carve-outs (active
transactions, regulatory). Similar to GDPR; same architecture.

State laws (Texas, Colorado, Virginia, etc.) are converging on
the GDPR/CCPA model. Build for the strictest; you're covered for
all.

## Anti-patterns

- **"Deleted = true" as the only delete.** GDPR-non-compliant.
- **Manual SQL deletion scripts.** Drift between table schemas
  and delete coverage; new table = forgotten deletion.
- **Re-introducing data via backup restore.** Document the
  process; rerun deletion as part of restore.
- **No retention policy.** Storage grows; compliance risk grows.
- **PII in JSON columns.** Hard to find / delete with confidence.
- **PII in log lines.** Logs aggregate to monitoring; deletion
  must extend there. Better: redact PII at the source.
- **Cross-table deletes done one row at a time.** Use batched
  DELETE per FK chain.

## Validation

- [ ] Every PII-bearing column is documented.
- [ ] Retention + deletion strategy per table is recorded.
- [ ] An end-to-end GDPR delete drill ran in the last 90 days
      and completed cleanly.
- [ ] Audit logs use opaque IDs after PII removal.
- [ ] Backup window + delete reconciliation is documented.
- [ ] Third-party data processors have a deletion API integration.
- [ ] The deletion request → confirmation cycle stays under 30 days.
