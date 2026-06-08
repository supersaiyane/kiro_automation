---
id: normalization_vs_denormalization
version: 1.0.0
owners: [database_architect, architect]
tags: [normalization, denormalization, schema-design, oltp, performance]
when_to_use: |
  Designing or auditing a relational schema. The default is 3NF;
  denormalize ONLY when measured query patterns demand it.
  Premature denormalization is the most common preventable schema
  bug — it costs you write integrity, GDPR delete cascades, and
  every future schema migration.
inputs:
  - access_patterns, read_write_ratio, consistency_requirements
outputs:
  - "schema_decisions: per-table normal form + denormalization carve-outs with justification"
---

# Normalization vs Denormalization — Default to 3NF

> Codd's normal forms exist because update anomalies are the
> silent killers of long-lived schemas. Denormalize for measured
> read performance, never for "it'll be faster" speculation.

## The normal forms in 30 seconds

- **1NF** — atomic columns (no comma-separated lists in a cell).
  Almost always the right baseline.
- **2NF** — every non-key column depends on the WHOLE primary key
  (relevant only for composite keys).
- **3NF** — no transitive dependencies (column A depends on
  column B which depends on the key → split out).
- **BCNF** — every determinant is a candidate key. Stricter than
  3NF; matters when you have overlapping composite candidate keys.

For 95% of OLTP, 3NF is the design target.

## When to denormalize (the legitimate cases)

1. **Aggregate caches** (e.g., `users.total_orders_count`):
   when COUNT() on a hot table dominates query cost AND staleness
   of a few seconds is acceptable. Recompute via trigger,
   materialized view, or async job.
2. **Read-side projections** (CQRS): a separate denormalized
   view optimized for one query pattern. The WRITE side stays
   3NF; you accept eventual consistency on the projection.
3. **History tables** (event-sourced or audit): immutable rows
   intentionally duplicate the "as-of" state.
4. **Reporting / OLAP**: dimensional models (star schema) are
   denormalized by design for scan-friendly queries.
5. **Cross-shard / cross-region**: when a join would require a
   network call to another shard, duplicate the small slice
   needed for local read.

## When NOT to denormalize

- "Joins are slow" — usually NOT true at OLTP volumes with
  indexes. Measure first.
- "We'll save a query" — until you have a profile showing a
  hot query is bottlenecked, this is speculation.
- "Easier to query" — convenience now is a re-migration later.
- "ORM is awkward" — fix the ORM, not the schema.

## The cost ledger for denormalization

| Cost | Detail |
|---|---|
| Update anomalies | Same fact in N places; updates touch N rows |
| Inconsistency window | Stale rows between writes |
| GDPR delete cost | Delete cascades to N tables; easier to miss one |
| Migration cost | Schema change requires updating duplicates |
| Test surface | Every consumer needs a refreshed mock |

If the denormalization can't outrun those costs in measurable
query speedup, leave it normalized.

## Patterns for safe denormalization

- **Computed columns**: derived value stored as a column,
  refreshed by trigger or materialized view. Cheaper than
  recomputing, but the cache must be invalidated.
- **Read replicas + projections**: writes go to the normalized
  primary; a projection job builds the denormalized read model.
  Latency budget per projection is explicit (e.g., < 30s).
- **JSONB columns** (Postgres): when the "denormalized" data is
  schema-flexible per row (e.g., per-tenant config). Index with
  GIN; query with `->>` operators. Beats EAV every time.

## The migration trap

Once a column is denormalized into N tables, removing it requires:
1. Stop writing the new column (still maintain old).
2. Backfill consumers from the source of truth.
3. Stop reading the denormalized column.
4. Drop the column.

That's 3 deploys minimum, with rollback paths between. Plan for
this BEFORE the first denormalization ships.

## Anti-patterns

- **Premature denormalization "because it'll be faster."** Always
  show a profile.
- **EAV (Entity-Attribute-Value).** Looks flexible; queries
  become unreadable. Use JSONB instead.
- **A "users" table with 80 columns of optional fields.** Some
  columns belong in profile / preferences / billing tables —
  split by access pattern.
- **Composite primary keys without surrogate IDs.** FK references
  multiply; updates cascade pain. Use a synthetic UUID/bigint
  surrogate AND keep the composite as a UNIQUE constraint.
- **NULL as the carrier of meaning.** "If verified_at IS NULL,
  user is unverified" — ambiguous. Use an explicit `status` enum.

## Validation that schema is well-shaped

- [ ] All tables in 3NF unless an explicit ADR justifies
      denormalization.
- [ ] No comma-separated value columns; arrays use proper
      ARRAY or JSONB types.
- [ ] Every denormalized field has a refresh strategy named.
- [ ] FK constraints exist and have ON DELETE behavior declared.
- [ ] No table > 50 columns without justification (it's probably
      two tables).
