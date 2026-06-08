---
id: database_schema_design
version: 1.0.0
owners: [backend_lead, senior_engineer_be, architect]
tags: [database, schema, normalization, indexes, migrations, postgres]
when_to_use: |
  Any new persistent storage decision. Schema mistakes are 10x more
  expensive to fix than code mistakes — the data is already in
  production by the time you notice.
inputs:
  - entities + relationships + access patterns
outputs:
  - schema_design: "tables, columns, types, constraints, indexes, migration plan"
---

# Database Schema Design

**Rule zero: design from the access patterns, not from the entities.**
Knowing what queries you'll run determines indexes, partitioning,
denormalization. The reverse never works.

## Column types — the choices that matter

| Need | Choose | Notes |
|---|---|---|
| Identity | `BIGINT IDENTITY` or `UUID v7` | UUID v7 is time-sortable, no DB-roundtrip to allocate, friendly for sharding |
| Surrogate vs natural key | Surrogate always; expose natural keys via UNIQUE indexes | Natural keys (email, username) change over the lifetime; PKs shouldn't |
| Timestamp | `TIMESTAMPTZ` (always UTC) | Never `TIMESTAMP` without timezone — endless DST bugs |
| Money | `NUMERIC(19,4)` or integer minor units | NEVER `FLOAT` — rounding errors are silent and irreversible |
| Enum-like | `TEXT` + CHECK constraint, OR a lookup table | Database-native ENUM types are hard to alter |
| Boolean | `BOOLEAN NOT NULL DEFAULT FALSE` | Nullable booleans express three states; reject in review |
| Free text | `TEXT` (no length limit needed in Postgres) | `VARCHAR(255)` is a relic; choose validation in the app |
| JSON | `JSONB` (queryable, indexable) | Use `JSON` only for write-once audit blobs |

## Normalize first, denormalize last

**3NF is the default.** Each fact lives in exactly one place. Denormalize
*only* when you've measured a read-path cost you can't otherwise fix.

When you denormalize:
- Document *why* (the query, the latency target).
- Have a sync mechanism (trigger / materialized view / app-level write).
- Add a backfill + verification job that catches drift.

## Indexes — the rules

1. **Every FK gets an index.** Postgres doesn't auto-create them.
   Missing FK indexes ruin DELETE cascades.
2. **Every column in a WHERE / ORDER BY gets considered.** Not every
   one gets indexed — but each is a decision.
3. **Composite index order: equality columns, then range, then sort.**
   `WHERE tenant_id = ? AND created_at > ?` → index on `(tenant_id,
   created_at)`, not `(created_at, tenant_id)`.
4. **Partial indexes** for sparse predicates: `WHERE deleted_at IS
   NULL`.
5. **EXPLAIN ANALYZE on the queries that matter.** "It uses the index"
   isn't enough; check rows-examined and cost.
6. **Indexes cost writes.** Every insert/update writes to every
   index. Don't over-index a hot write path.

## Constraints — your last line of defense against bad data

- `NOT NULL` whenever the column is required. Default-NULL hides bugs.
- `CHECK` for invariants the app can't be trusted to enforce —
  `CHECK (amount > 0)`, `CHECK (status IN ('open','closed','void'))`.
- `UNIQUE` for any natural-key uniqueness — email, slug, idempotency
  key.
- `FOREIGN KEY` always, with explicit `ON DELETE` action. SET NULL,
  CASCADE, RESTRICT — each has consequences; choose explicitly.

## Migrations — the painful path

**Three rules for production migrations**:

1. **Backward compatible** — old code must work after migration; new
   code must work before next migration.
   - Add column nullable → backfill → flip to NOT NULL in next deploy.
   - Rename column → add new, dual-write, migrate readers, drop old.
2. **Lock-aware** — `ALTER TABLE` in Postgres takes ACCESS EXCLUSIVE.
   On a 100M-row table, that's an outage. Use:
   - `CREATE INDEX CONCURRENTLY`
   - Add column with `NOT NULL DEFAULT` only after backfill
   - Avoid `SET DATA TYPE` on big tables — rewrites the whole table
3. **Reversible** — every migration has a down-migration. If down is
   impossible (destructive), make it a multi-step deploy with a
   feature flag.

## Sharding & partitioning — when

- Single-table size > 100M rows OR > 200GB: consider partitioning
  (Postgres declarative partitioning, range or hash).
- Single-database size > a few TB OR write-IOPS approaches the
  provisioned cap: consider sharding (by tenant for SaaS,
  by user_id for consumer, by date for time-series).

Sharding is expensive operationally. Don't shard preemptively.

## Anti-patterns

- **EAV** (entity-attribute-value) "for flexibility." You've recreated
  a NoSQL store inside Postgres without any of the upsides.
- **God table** with 100+ columns. Split by access pattern.
- **Wide-everywhere** — every table has `created_at, updated_at,
  created_by, updated_by, deleted_at`. Fine for some; pollutes the
  schema for many. Use audit tables for the ones that matter.
- **No FK constraints because "the app enforces it."** The app has
  bugs. The DB constraint is your seatbelt.
- **String enums via `VARCHAR(255)`.** Use a CHECK or a lookup table.
- **`status_at` columns** without a corresponding status_change_log.
  You'll need the history; capture it from day one.
- **Indexes added one by one in production.** Without
  `CREATE INDEX CONCURRENTLY`, you lock the table.
- **Migrations that mix DDL + data**. DDL takes locks; data is slow.
  Split them; deploy DDL fast, run data in background.
