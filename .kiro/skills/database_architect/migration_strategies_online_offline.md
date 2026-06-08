---
id: migration_strategies_online_offline
version: 1.0.0
owners: [database_architect, backend_lead, sre]
tags: [migrations, expand-contract, zero-downtime, online-ddl, gh-ost]
when_to_use: |
  Any schema change on a production database. The pattern is the
  same whether you're adding a column or renaming one: never
  combine a code change with a destructive schema change in the
  same release. Expand-migrate-contract over multiple deploys.
inputs:
  - current_schema, target_schema, rollback_window
outputs:
  - "migration_plan: phased deploys with rollback path between each"
---

# Online Schema Migrations — Expand / Migrate / Contract

> The forbidden pattern: deploy code that requires a new column,
> in the same release that adds the column. If the migration is
> slow or fails, every replica is mid-rollout AND the old code
> won't work either. Expand-migrate-contract makes every step
> revertible.

## The expand-migrate-contract pattern

Three (or four) deploys for a renamed column:

```
DEPLOY 1 — EXPAND
  Migration: ADD COLUMN new_name TEXT;
             (Optional: trigger to keep new_name = old_name)
  Code:      writes BOTH columns; reads OLD column.
  Rollback:  revert code; new column harmless.

DEPLOY 2 — BACKFILL
  Backfill job: UPDATE … SET new_name = old_name WHERE new_name IS NULL;
                Run in batches with throttle.
  Code:        unchanged.

DEPLOY 3 — MIGRATE READS
  Code:      reads NEW column; writes BOTH.
  Rollback:  flip to reading OLD column.

DEPLOY 4 — CONTRACT
  Migration: DROP COLUMN old_name; (and remove dual-write code).
  Rollback:  RESTORE from backup. (You should be confident by now.)
```

Each step is independently revertible. Each can be paused.

## Why not just `ALTER TABLE` and ship?

| Operation | Postgres impact | MySQL impact |
|---|---|---|
| ADD COLUMN nullable | Instant metadata change | Online (InnoDB) |
| ADD COLUMN with DEFAULT | Rewrites table (PG < 11) / Instant (PG ≥ 11) | Rewrites table |
| DROP COLUMN | Instant metadata change | Online |
| ALTER COLUMN TYPE | Rewrites table (locks) | Rewrites table |
| ADD INDEX | Locks unless CONCURRENTLY | Online (recent) |
| RENAME COLUMN | Instant metadata | Instant metadata |
| ADD NOT NULL | Locks (PG ≥ 11 has fast-path with DEFAULT) | Rewrites |

Locking operations on a hot table cause cascading timeouts under
load. NEVER run them at peak.

## Postgres-specific patterns

### Add a NOT NULL column

```sql
-- Step 1: nullable add (no rewrite if no default)
ALTER TABLE users ADD COLUMN verified BOOLEAN;

-- Step 2: backfill in batches
UPDATE users SET verified = false WHERE verified IS NULL LIMIT 10000;
-- (repeat)

-- Step 3: add NOT NULL with the fast path (PG ≥ 12)
ALTER TABLE users ALTER COLUMN verified SET NOT NULL;
```

### Add an index

```sql
-- ALWAYS use CONCURRENTLY in prod
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
-- This is online: no exclusive lock; reads + writes proceed.
-- It also can't run inside a transaction; one statement, by itself.
```

### Rename a column

The standard `RENAME COLUMN` is fast BUT it's a "rename in place"
that breaks any code still using the old name. Use the
expand-migrate-contract pattern above.

### Change column type

```sql
-- Heavy operation; rewrites the table.
-- For large tables: add new column, dual-write, backfill, swap.
ALTER TABLE orders ADD COLUMN amount_cents BIGINT;
-- backfill: UPDATE orders SET amount_cents = (amount * 100)::BIGINT;
-- swap reads in code, then DROP COLUMN amount;
```

## MySQL — gh-ost / pt-online-schema-change

For non-online operations, use a shadow-table tool:

- **gh-ost** (GitHub) — copies via binlog, no triggers, safer.
- **pt-online-schema-change** (Percona) — trigger-based, older,
  works on RDS.

Both create a copy with the new schema, mirror writes, swap when
done. Production-tested at high scale.

## Backfill discipline

A backfill is a long-running batch UPDATE. Rules:

1. **Batched** with explicit LIMIT, ordered by PK ASC.
2. **Throttled** to leave room for OLTP traffic (e.g., sleep 50ms
   between batches; reduce batch size under load).
3. **Resumable** — record progress (last PK touched) so you can
   resume after a crash.
4. **Monitored** — alert if rate drops below target.
5. **Tested in staging** with comparable data volume.

A "one big UPDATE statement" is how you take down a primary at 2am.

## Online DDL gotchas

- `ADD COLUMN ... DEFAULT non_null_constant` — fast in PG ≥ 11,
  table rewrite before. Check your version.
- `DROP COLUMN` — instant metadata change in PG/MySQL, but the
  space isn't reclaimed until VACUUM FULL / pt-osc.
- `ALTER TABLE ADD CONSTRAINT FOREIGN KEY ... NOT VALID` —
  the fast path: add the constraint first as NOT VALID, then
  `VALIDATE CONSTRAINT` later (acquires a SHARE lock only).

## Versioning + lock guards

Every migration tool (Alembic, Flyway, Liquibase, gh-ost) records
a version row. Add a lock-timeout guard:

```sql
SET lock_timeout = '5s';   -- abort migration if it can't acquire
```

Without this, a misbehaving migration can hold a lock indefinitely
and pile up connections.

## Rollback strategy per step

| Step | Rollback |
|---|---|
| Expand (ADD nullable) | Revert code; column is harmless |
| Backfill | Stop the job; partial data is fine for next time |
| Migrate reads | Flip the code back to old column |
| Contract (DROP) | Restore from backup OR re-add and re-backfill |

The first three are minutes; the last is hours. So don't contract
until the team is confident, and have a backup taken right before.

## Anti-patterns

- **DROP COLUMN in the same release that stops writing to it.**
  Replica that lags by 30 seconds runs the OLD code → writes to a
  column that's just been dropped.
- **Migrations bundled with feature code.** They release together
  → roll back together → migration rollback can corrupt or stall.
- **`ALTER COLUMN TYPE` on a hot 100M-row table.** Locks for
  minutes. Use shadow-table approach.
- **`CREATE INDEX` without CONCURRENTLY.** Locks for the duration.
- **No staging dry-run.** First time the migration is exercised
  is in prod with traffic. Predict the time.
- **Backfill in one giant UPDATE.** Locks rows, balloons WAL,
  blocks replicas.

## Validation

- [ ] Every migration is reversible (down() implemented or
      a documented rollback runbook).
- [ ] Renames + type changes follow expand-migrate-contract.
- [ ] Backfill jobs are batched + throttled + resumable.
- [ ] Index creation uses CONCURRENTLY (PG) or pt-osc / gh-ost
      (MySQL).
- [ ] Lock-timeout is set on every long-running migration.
- [ ] No migration ship reduces the rollback window (last good
      backup) to less than the recovery RTO.
