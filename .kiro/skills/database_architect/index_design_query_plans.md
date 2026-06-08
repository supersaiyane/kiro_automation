---
id: index_design_query_plans
version: 1.0.0
owners: [database_architect, backend_lead, senior_engineer_be]
tags: [indexes, query-planner, postgres, explain, b-tree, covering]
when_to_use: |
  Slow query, missing index, OR you're designing a new table.
  Indexes are NOT free — every write pays the index cost. Every
  hot query needs an index path; every cold one doesn't. The
  discipline is making each index earn its keep.
inputs:
  - hot_queries, write_rate, table_sizes
outputs:
  - "index_strategy: per-table index list with query-plan evidence"
---

# Index Design — Earn The Index, Don't Just Add It

> An index is a write tax for a read benefit. If the query never
> runs, the index is pure cost. The discipline: KNOW the hot
> queries, design indexes for them, prune indexes that aren't pulling
> their weight.

## Read EXPLAIN before you write CREATE INDEX

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders
WHERE tenant_id = $1 AND status = 'pending' AND created_at > now() - INTERVAL '7 days'
ORDER BY created_at DESC LIMIT 50;
```

What to look for:
- **Seq Scan** on a big table → missing index.
- **Index Scan** but high `Rows Removed by Filter` → wrong index
  (it's scanning too much).
- **Sort** with rows = limit → ORDER BY column should be in
  the index.
- **Bitmap Heap Scan** with high `lossy` recheck → consider a
  covering index.

## Composite index column order

The order matters. Rule: equality columns BEFORE range columns
BEFORE sort columns.

```sql
-- Query: tenant_id = X AND status = 'pending' AND created_at > Y
--        ORDER BY created_at DESC

-- BEST:
CREATE INDEX ON orders(tenant_id, status, created_at DESC);

-- ALSO OK (if status has few values, server may bitmap):
CREATE INDEX ON orders(tenant_id, created_at DESC) WHERE status = 'pending';
```

Why: the planner uses the index left-to-right. Once it hits a
range condition (`created_at > Y`), it can use the index, but
later columns can't be used for filtering — only for sorting.

## Covering indexes (INCLUDE clause)

```sql
CREATE INDEX ON orders(tenant_id, created_at DESC) INCLUDE (status, total_cents);
```

- Index now contains the data needed by the query → "index-only
  scan" → never touch the heap.
- Trade-off: index is bigger (more storage, slower writes).
- Worth it for read-heavy hot queries that return a few columns.

## Partial indexes — narrow the scope

```sql
-- Only index pending orders (the common active set)
CREATE INDEX ON orders(tenant_id, created_at DESC) WHERE status = 'pending';
```

- Smaller index, faster scans.
- Useful when 95% of queries hit the same subset (e.g., active
  records, current month, this tenant tier).

## Expression indexes

```sql
-- Case-insensitive email lookup
CREATE INDEX ON users (LOWER(email));

-- Query
SELECT * FROM users WHERE LOWER(email) = LOWER($1);
```

The query MUST use the same expression for the index to be used.

## Index types — pick by data shape

| Type | Use | Engine |
|---|---|---|
| B-tree | Equality, range, sorted reads | All — default |
| Hash | Equality only (no range) | PG 10+, MySQL |
| GIN | JSONB, full-text, arrays | Postgres |
| GiST | Geo, fuzzy, custom | Postgres |
| BRIN | Very large + sorted (time-series) | Postgres |
| Bitmap | Low-cardinality cols (rare) | Some warehouses |

For typical OLTP: B-tree everywhere unless you have a specific
data shape (JSONB / GeoJSON / huge time-series).

## The write tax

Every index slows writes:
- INSERT: index entry per index.
- UPDATE: if the indexed column changes, both old + new entry.
- DELETE: index entry removed.

A table with 8 indexes is ~8x slower to write than no indexes.
On hot write tables (audit logs, events), keep indexes minimal.

## Index hygiene — what to prune

```sql
-- Unused indexes (Postgres)
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE '%_pkey';
```

Indexes with `idx_scan = 0` over a month of typical traffic are
dead weight. Drop them.

Caveat: query patterns shift over time. An index that's unused
today may matter for next month's feature. Check before pruning.

## ANALYZE — keep stats fresh

The query planner uses table statistics (histogram, ndistinct).
If stats are stale:
- After a big bulk load: `ANALYZE table;`
- After a backfill / migration: `ANALYZE` the touched tables.
- Postgres runs auto-analyze; tune the threshold for hot tables.

Bad plan? First action: `ANALYZE` → re-EXPLAIN. Often a stale-stats
fix.

## Concurrent index creation in prod

```sql
-- Postgres: CONCURRENTLY = no lock, online
CREATE INDEX CONCURRENTLY idx_orders_status ON orders(status);

-- MySQL: pt-online-schema-change or gh-ost for big tables
```

Concurrent creation is slower but doesn't block writes. ALWAYS
use in production. Without CONCURRENTLY, a 100M-row table can
lock for hours.

## Foreign key indexes — easily missed

A FK constraint doesn't automatically index the referencing
column.

```sql
CREATE TABLE orders (
  id        UUID PRIMARY KEY,
  user_id   UUID REFERENCES users(id)   -- NO INDEX BY DEFAULT
);

-- Add explicitly
CREATE INDEX ON orders(user_id);
```

Without this index:
- DELETE FROM users WHERE id = X — does a seq scan on orders
  to find dependent rows. Painfully slow.
- Cascade deletes can take hours.

## N+1 queries — the index won't save you

```python
posts = Post.all                # 1 query
for p in posts:
    print(p.author.name)        # 1 query each — N+1
```

Even with indexes, that's N round trips. Fix in app:

```python
posts = Post.includes(:author).all   # 2 queries, joined or batched
```

Indexes help INDIVIDUAL queries; they don't fix architectural
N+1 problems. See ORM docs.

## Index size sanity check

```sql
-- Postgres: index sizes per table
SELECT pg_size_pretty(pg_relation_size(c.oid)) AS index_size, c.relname
FROM pg_class c JOIN pg_index i ON c.oid = i.indexrelid
ORDER BY pg_relation_size(c.oid) DESC LIMIT 20;
```

If an index is > 50% the size of the table data, it's suspicious.
Often: indexed too wide, or covering more than it needs to.

## Anti-patterns

- **Indexing every column.** Write tax explodes; planner gets
  confused.
- **`SELECT *` with a covering index.** Defeats the index-only
  scan goal.
- **Composite index order based on column appearance, not
  query selectivity.** Bad order = bad plan.
- **Skipping indexes on FK columns.** Cascade DELETE is slow.
- **CREATE INDEX without CONCURRENTLY in prod.** Locks block writes.
- **`LIKE '%substring%'`.** Indexes can't help; use full-text
  search (GIN tsvector) or trigram.
- **Indexes that the planner doesn't use.** Often the column
  isn't selective enough — check ndistinct.

## Validation

- [ ] Every hot query has its EXPLAIN ANALYZE in version control
      (regression catch).
- [ ] No table has > 8 indexes without justification.
- [ ] Every FK column is indexed.
- [ ] Unused indexes are pruned at least quarterly.
- [ ] CONCURRENTLY is required for prod index creation
      (in the migration tool's lint).
- [ ] ANALYZE runs after every backfill in production.
