---
id: time_series_schema_design
version: 1.0.0
owners: [database_architect, sre, backend_lead]
tags: [time-series, timescale, clickhouse, retention, downsampling]
when_to_use: |
  Schema design for events, metrics, IoT telemetry, audit logs,
  any workload where 95% of writes are append-only and queries
  are mostly "this metric over this window." Use the wrong store
  (e.g., generic Postgres for 1B rows/day) and write throughput
  caps long before storage does.
inputs:
  - ingest_rate, retention_window, query_patterns
outputs:
  - "time_series_schema: store choice + partitioning + retention + downsampling + indexes"
---

# Time-Series Schema Design

> Time-series data is its own physics. A traditional RDBMS works
> up to ~100M rows; specialized time-series stores (TimescaleDB,
> ClickHouse, InfluxDB, VictoriaMetrics) handle 100B+ with
> appropriate partitioning.

## Pick the right store

| Store | Best for | Sweet spot |
|---|---|---|
| TimescaleDB | Postgres-compat, transactional time-series | Up to 100B rows |
| ClickHouse | Analytical, very wide tables | 1T+ rows |
| InfluxDB | Pure time-series, IoT | Devices, metrics |
| VictoriaMetrics | Prometheus replacement, ops-heavy | Metrics workloads |
| Druid | Real-time analytics | Sub-second queries on streaming |
| Plain Postgres + partitioning | < 100M rows / tier | Audit logs, low-volume events |

Decision questions:
1. Write rate at peak? > 100k inserts/sec → ClickHouse / Druid.
2. Retention? 7 days vs 7 years matters for compression strategy.
3. Query types? Point lookups vs scans vs aggregations.
4. Transactional integrity needed? TimescaleDB (Postgres) wins.

## Schema shape — typical time-series row

```sql
CREATE TABLE metrics (
  ts        TIMESTAMPTZ NOT NULL,    -- always required
  series_id BIGINT NOT NULL,          -- dimension (host, sensor, …)
  metric    TEXT NOT NULL,            -- name
  value     DOUBLE PRECISION,         -- the measurement
  tags      JSONB,                    -- low-cardinality labels
  ...
) PARTITION BY RANGE (ts);
```

Patterns:
- **Wide row vs tall row**: ClickHouse wins with wide rows
  (one column per metric); Postgres with tall (one row per
  observation). Use the engine's strength.
- **Tags column** for low-cardinality (region, env). Cardinality
  matters: tags with high cardinality (user_id) blow up
  storage. Use a dedicated dimension table.
- **No NULLs in the value column**: store an explicit "missing"
  marker or skip the row.

## Partitioning (TimescaleDB / Postgres)

Always partition by time:

```sql
-- TimescaleDB hypertable
SELECT create_hypertable('metrics', 'ts', chunk_time_interval => INTERVAL '1 day');

-- Vanilla Postgres
PARTITION BY RANGE (ts);
CREATE TABLE metrics_2026_05_27 PARTITION OF metrics
  FOR VALUES FROM ('2026-05-27') TO ('2026-05-28');
```

Chunk size guideline: aim for chunks of ~25% of available RAM,
so the hot chunk fits in shared_buffers. Daily chunks at 1M
rows/day = ~50MB each = perfect. Hourly chunks at 100M rows/hr
= 5GB each = too large; partition more finely.

## Indexes — composite is mandatory

```sql
CREATE INDEX ON metrics (series_id, ts DESC);    -- most queries
CREATE INDEX ON metrics (metric, ts DESC);       -- by metric
CREATE INDEX ON metrics USING GIN (tags);        -- tag lookup
```

- ALWAYS index `(dimension, ts DESC)`. Time is ALWAYS in the
  WHERE clause for time-series queries.
- BRIN indexes on `ts` for the cold partitions (cheap, smaller
  than B-tree).
- Avoid indexes on rapidly-changing columns; they slow inserts.

## Retention + tiering

Retention strategy must be IN the design, not an afterthought:

```sql
-- TimescaleDB: drop old chunks automatically
SELECT add_retention_policy('metrics', INTERVAL '90 days');

-- Move warm chunks to cheaper compressed storage
ALTER TABLE metrics SET (timescaledb.compress, timescaledb.compress_segmentby = 'series_id');
SELECT add_compression_policy('metrics', INTERVAL '7 days');
```

Tiers:
- **Hot** (last 7 days): uncompressed, indexed for fast queries.
- **Warm** (7-90 days): compressed, slower queries, cheaper storage.
- **Cold** (90 days - 7 years): exported to S3 Parquet; queries
  via DuckDB / Athena.
- **Glacier** (regulatory only): rarely-accessed deep archive.

## Downsampling — keep summaries forever

Raw 1-second data is useful for the last 24h. After that,
1-minute averages are usually enough.

```sql
-- TimescaleDB continuous aggregate
CREATE MATERIALIZED VIEW metrics_1m
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 minute', ts) AS bucket,
  series_id, metric,
  avg(value) AS avg_value,
  max(value) AS max_value,
  min(value) AS min_value
FROM metrics
GROUP BY 1, 2, 3;

SELECT add_continuous_aggregate_policy('metrics_1m',
  start_offset => INTERVAL '1 day',
  end_offset   => INTERVAL '1 hour',
  schedule_interval => INTERVAL '1 hour');
```

Drop the raw rows after 24h; keep the 1m for 30d, 1h for 1y,
1d forever. Storage cost falls 100-1000x; query patterns are
preserved for the time horizon that matters.

## Cardinality kills

The #1 cause of time-series store failure: HIGH-CARDINALITY tags.

```sql
-- BAD: tag with cardinality = 10M users
INSERT INTO metrics VALUES ('2026-05-27 ...', 'login_event', 1, '{"user_id":"42"}');

-- Now you have 10M unique series; storage explodes, queries slow.
```

For per-user metrics: put user_id in a SEPARATE dimension table
and query with a join. Or use a different store entirely (event
store + OLAP warehouse, not a metrics DB).

Rule of thumb: total series cardinality < 1M for InfluxDB,
TimescaleDB. ClickHouse handles higher but watch memory.

## Insert performance

- **Batch inserts**: 1k-10k rows per INSERT. NEVER one row at a
  time at scale.
- **Async commit** (Postgres `synchronous_commit = off` per
  session) for non-critical metrics; you trade ~1s of data on
  crash for 3x throughput.
- **Connection pooling** (pgbouncer): keep connections cheap.
- **Wal-G / write-ahead optimization**: tune for write-heavy
  workload.

## Query patterns

```sql
-- Last hour, 1-min bucket, one series
SELECT time_bucket('1 minute', ts) AS minute, avg(value)
FROM metrics
WHERE series_id = 42 AND ts >= now() - INTERVAL '1 hour'
GROUP BY 1 ORDER BY 1;

-- Top 10 noisiest series in last day
SELECT series_id, stddev(value) AS noise
FROM metrics
WHERE ts >= now() - INTERVAL '1 day'
GROUP BY 1 ORDER BY noise DESC LIMIT 10;
```

These patterns use the (series_id, ts) index and benefit from
partition pruning.

## Anti-patterns

- **Generic Postgres for 1B+ rows of time-series.** Use Timescale
  or ClickHouse.
- **High-cardinality tags.** Series explosion = death by 1000 cuts.
- **No retention policy.** Storage costs grow forever; queries
  slow down past 90d.
- **One-row-at-a-time INSERTs.** Throughput-bound on tx overhead.
- **No downsampling.** Storing 1s data for 5 years burns money.
- **No `ts` in the WHERE clause.** Every time-series query MUST
  filter by time. Without it, you scan everything.
- **JSONB for high-cardinality fields.** Use proper columns.

## Validation

- [ ] Time-series table is partitioned by time with appropriate
      chunk size.
- [ ] Retention + tiering policies are documented and automated.
- [ ] Continuous aggregates exist for the queries that span > 1d.
- [ ] Cardinality monitor exists; alerts if a new tag spikes
      series count.
- [ ] Inserts are batched (≥ 1k rows per INSERT).
- [ ] Every query the dashboards run has `ts >= …` in WHERE.
- [ ] Storage cost is observable per tier (hot / warm / cold).
