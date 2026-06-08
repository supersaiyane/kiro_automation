---
id: olap_oltp_boundaries
version: 1.0.0
owners: [database_architect, architect]
tags: [oltp, olap, etl, elt, lakehouse, clickhouse, snowflake]
when_to_use: |
  Analytics queries are degrading the OLTP database, OR you're
  designing the data path for a product that needs both operational
  reads (single-record, low-latency) and analytical reads (cross-cut
  aggregates, full-table scans). Mixing them in one store is the
  classic scaling antipattern.
inputs:
  - oltp_query_profile, analytical_use_cases, latency_budget
outputs:
  - "data_topology: OLTP store + replication pipeline + OLAP store + freshness SLA"
---

# OLAP / OLTP Boundary — Two Stores, Not One

> A single Postgres can serve OLTP and ad-hoc analytics — until
> the first VP runs a SELECT on a 100M-row table at 9am Monday.
> Now your app is degraded for everyone. Plan the boundary BEFORE
> the boardroom dashboard kills production.

## The two workloads — different physics

| | OLTP | OLAP |
|---|---|---|
| Query shape | Point lookup, small range | Scan, aggregate, JOIN |
| Latency target | < 10ms p99 | seconds to minutes |
| Throughput | High TPS, small txns | Low QPS, large reads |
| Schema | Normalized | Denormalized (star / snowflake) |
| Storage | Row-store | Column-store |
| Indexing | B-tree, per-row | Column compression, zone maps |
| Examples | Postgres, MySQL, DynamoDB | ClickHouse, Snowflake, BigQuery, Druid |

Trying to make one store excel at both is the OLD strategy. Modern:
keep them separate; replicate between them.

## The reference topology

```
[ App ] → [ OLTP store ] ───CDC───► [ OLAP store ] ← [ BI / dashboards ]
                ↑                          ↑
                │                          │
            [ Users ]                 [ Analysts ]
```

CDC (Change Data Capture) tails the OLTP transaction log
(Postgres WAL via Debezium, MySQL binlog) and streams changes
into the OLAP store. Freshness depends on tier:

- **Real-time** (< 5s): Debezium → Kafka → ClickHouse.
- **Near-real-time** (1-5 min): scheduled micro-batches.
- **Hourly / nightly**: traditional ETL with Airflow / dbt.

## ETL vs ELT

- **ETL** (Extract → Transform → Load): transform happens before
  loading. Legacy; tight coupling between schema and pipeline.
- **ELT** (Extract → Load → Transform): load raw, transform in
  the warehouse using dbt or similar. Modern default — warehouses
  are cheap enough to do transforms in-place.

ELT wins for data freshness, debuggability (re-run a transform,
not the whole pipeline), and schema evolution.

## Picking the OLAP store (2026)

| Store | Strength | Weakness |
|---|---|---|
| Snowflake | Mature, easy ops, big ecosystem | $$$ |
| BigQuery | Serverless, fast on huge | GCP lock-in |
| Databricks | Lakehouse, ML-friendly | Steeper learning curve |
| ClickHouse | Open-source, blazing fast, self-host | Operational tax |
| Redshift | AWS native | Falling behind on perf |
| DuckDB | Single-node, "Postgres of analytics" | Single-node |

Default for product analytics inside an app: ClickHouse (self-host
or ClickHouse Cloud).
Default for company-wide BI: Snowflake or BigQuery.

## The data contract

A schema in the OLAP store is a contract with downstream consumers.
Treat it like an API:

- Tables versioned (`orders_v1`, `orders_v2`).
- Breaking changes go through a deprecation window.
- Owner per table; SLA per table (freshness, completeness).
- Tests (dbt tests / Great Expectations) on key invariants.

A common failure: the analytics team renames a column in the
warehouse; 12 dashboards break overnight. Avoid by versioning.

## Read replicas — when they're "enough"

A read replica off the primary is the cheapest tier of "OLAP."
It works when:
- Analytical queries are row-pattern friendly (point + small range).
- Replica lag tolerance is loose.
- Query volume is modest.

It does NOT work for:
- Full-table scans on 100M+ rows.
- Wide JOINs across many tables.
- Concurrent analyst load.

When read replicas hurt OLTP perf, it's time for a real OLAP tier.

## Streaming analytics — the third store

For real-time analytics (live dashboards, anomaly detection):

```
[ App / events ] → [ Kafka ] → [ Flink / Materialize ] → [ App / dashboard ]
                                     ↑
                                  Stateful streaming SQL
```

Materialize, Flink SQL, Risingwave, ksqlDB all let you write SQL
over event streams with materialized results that update as events
flow. Pairs with the OLTP/OLAP split for the live-update side.

## CDC pipeline architecture

Debezium is the standard:

```
[ Postgres WAL ] → [ Debezium ] → [ Kafka topics: db.schema.table ]
                                       ↓
                                  [ Sink: ClickHouse / S3 / BQ ]
```

Caveats:
- Schema changes propagate via Kafka schema registry.
- DELETE → emits a tombstone event; sink must handle.
- Replication slot in Postgres holds WAL — monitor disk if
  consumer falls behind.

## Anti-patterns

- **Long-running SELECTs on OLTP primary.** Use a read replica
  at minimum.
- **Triggers updating denormalized cols in real time.** Doesn't
  scale; CDC + downstream stream processor is the modern path.
- **The "single source of truth is a Google Sheet."** A pipeline
  someone updates by hand; eventually it breaks; no one knows.
- **No SLA on the OLAP side.** Analysts query stale data, make
  decisions, lose trust.
- **Schema changes on OLTP that silently break OLAP.** Use
  versioned schemas + alerts on missing columns.
- **dbt models that aren't tested.** A typo in a join filter
  costs a quarter of analytics work.

## Validation

- [ ] OLTP and OLAP are physically separate stores.
- [ ] A CDC pipeline keeps OLAP in sync; freshness SLA documented.
- [ ] No analytical query runs against the OLTP primary in
      business hours.
- [ ] OLAP tables are owned, versioned, and tested.
- [ ] Schema changes have a propagation strategy; no surprise
      dashboard breaks.
- [ ] BI tool latency to query result is < 30 seconds on the
      hot 90% of queries.
