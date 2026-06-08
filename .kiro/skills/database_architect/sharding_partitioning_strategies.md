---
id: sharding_partitioning_strategies
version: 1.0.0
owners: [database_architect, backend_lead, sre]
tags: [sharding, partitioning, scaling, vitess, citus, hot-shard]
when_to_use: |
  A table is past ~50M rows or growing toward it, OR write
  throughput is bottlenecked by a single primary. Partitioning
  delays the pain; sharding distributes it. Both are
  one-way-doors if poorly chosen.
inputs:
  - row_count, write_rate, query_patterns, growth_curve
outputs:
  - "scale_plan: partitioning scheme + shard key + re-shard runbook"
---

# Sharding + Partitioning — Pick Before The Pain

> Postgres partitioning and Vitess/Citus sharding solve different
> problems. Partitioning keeps a single primary humming; sharding
> scales across primaries. The shard KEY decision is forever.

## Partitioning vs sharding

| | Partitioning | Sharding |
|---|---|---|
| Scope | Within one DB | Across N DBs |
| Engine support | Native (PG, MySQL) | Vitess, Citus, app-level |
| Operational cost | Low | High |
| Scaling axis | Disk I/O, planner | All of write throughput |
| When | < 1B rows / single primary OK | > 1B rows / write-bound |

Partition FIRST. Shard only when partitioning isn't enough.

## Postgres partitioning patterns

### RANGE (most common — time-series)

```sql
CREATE TABLE events (
  id          BIGINT,
  occurred_at TIMESTAMPTZ NOT NULL,
  ...
) PARTITION BY RANGE (occurred_at);

CREATE TABLE events_2026_01 PARTITION OF events
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
-- Repeat per month; automate via pg_partman.
```

- New partition each period → constant insertion speed.
- Old partition can be DROPPED (fast retention) or moved to cold
  storage.
- Indexes are per-partition; planner picks the right partition
  via partition pruning.

### LIST (small bounded value set)

```sql
PARTITION BY LIST (region);
CREATE TABLE orders_us PARTITION OF orders FOR VALUES IN ('us');
CREATE TABLE orders_eu PARTITION OF orders FOR VALUES IN ('eu');
```

- Use when queries are heavily skewed by a low-cardinality column.

### HASH (even distribution)

```sql
PARTITION BY HASH (tenant_id);
CREATE TABLE orders_p0 PARTITION OF orders
  FOR VALUES WITH (MODULUS 16, REMAINDER 0);
-- 16 partitions total.
```

- Use when there's no natural range and you want IO/CPU balanced.

## Sharding — the shard key decision

Shard key properties that matter:

1. **Cardinality** — high enough that data spreads evenly.
2. **Selectivity** — present in 90%+ of queries (so most queries
   hit one shard).
3. **Stable** — doesn't change after row creation (no re-sharding
   on update).
4. **Co-locatable** — related data shares the key (e.g., all of
   one customer's orders, items, payments).

Most common: `tenant_id` for multi-tenant SaaS. Customer id for
B2C. Time-bucket × user for IoT.

**NEVER shard by an auto-increment ID.** Distributes evenly but
loses co-location, every join is cross-shard.

## The hot-shard problem

Hash-sharding by `tenant_id` gives even distribution. UNTIL your
biggest tenant has 100x the data of the median. Now their shard
is on fire.

Mitigations:
- **Power-of-two splits**: detect hot shard, split into two.
- **Tenant sharding tier**: enterprise tenants get their own
  shard; SMBs share.
- **Tenant migration capability**: move a tenant between shards
  online. Vitess + Citus support this; rolling your own is hard.
- **Limit-per-tenant**: enforce upper bounds (rows, requests/min)
  so one tenant can't take down a shard.

## Re-sharding playbook

You WILL need to re-shard eventually. Plan upfront:

1. **Double-write phase**: writes go to old shard AND new shard.
   App reads still from old.
2. **Backfill**: copy historical data from old to new.
3. **Verify**: row counts + sample queries match.
4. **Switch reads**: gradually for one tenant / one query at a time.
5. **Stop writes to old**.
6. **Drop old shard**.

Per-tenant migration (move tenant T from shard A to shard B):
- Block tenant T's writes briefly (seconds, with a maintenance
  banner).
- Copy tenant T's data from A to B (filtered by tenant_id).
- Verify.
- Switch routing for tenant T to B.
- Resume writes.

## Vitess vs Citus vs PlanetScale (2026)

| | Vitess | Citus | PlanetScale |
|---|---|---|---|
| Engine | MySQL | Postgres extension | MySQL (Vitess-based) |
| Sharding model | VSchema (declared) | Distributed table | Branched |
| Online resharding | Yes | Yes (recent) | Yes |
| Cross-shard joins | Limited | Better | Limited |
| Operational | Open-source, complex | Postgres extension, simpler | Managed |

Pick by engine alignment + ops capability. Self-managed Vitess
is a real engineering investment.

## Indexes per partition / shard

- Local indexes (per-partition) — fast for partition-aligned queries.
- Global indexes (across partitions) — limited support; usually
  not what you want for a sharded write-heavy table.
- For time-series: partial indexes on hot ranges; drop old ones.

## Anti-patterns

- **Sharding by auto-increment ID.** Loses co-location.
- **No global identifier strategy.** When you shard, AUTO_INCREMENT
  collides. Use UUIDs or snowflake IDs from day one.
- **Cross-shard JOINs in hot paths.** Either denormalize or
  co-locate.
- **"We'll re-shard when we hit the limit."** Re-sharding under
  load takes weeks. Plan AHEAD.
- **Hot-shard tolerated until it pages.** Detect and migrate
  proactively.
- **Mixed partitioning schemes on the same table** (range + hash
  on different columns). Tooling support is poor; complexity is
  high.

## Validation

- [ ] Any table over 50M rows has a partitioning scheme OR an
      explicit decision to skip.
- [ ] Shard key is documented; queries that don't use it have
      a justified exception list.
- [ ] Online re-shard / migration playbook tested in staging.
- [ ] Per-tenant data volume is observable; alerts on top-N
      tenants exceeding fair-share threshold.
- [ ] Global ID strategy avoids per-shard collisions (UUIDv7 /
      snowflake / etc).
