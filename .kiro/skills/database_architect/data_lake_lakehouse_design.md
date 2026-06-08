---
id: data_lake_lakehouse_design
version: 1.0.0
owners: [database_architect, cloud_architect]
tags: [data-lake, lakehouse, iceberg, delta, hudi, medallion, parquet]
when_to_use: |
  Building a multi-source analytical platform — events, OLTP CDC,
  third-party feeds, IoT — destined for analytics + ML. Data
  lakehouse is the 2025-2026 default; pick the table format and
  zone topology BEFORE you have 10TB on disk in raw JSON.
inputs:
  - source_inventory, retention_policy, query_engines
outputs:
  - "lakehouse_design: bronze/silver/gold zones + table format + governance + access"
---

# Data Lake / Lakehouse Design

> A "data lake" without governance becomes a data swamp in 18
> months. The lakehouse pattern (Databricks 2020, broadly adopted
> by 2024) layers table semantics, ACID, and schema enforcement
> on top of object storage — without giving up the cheap storage
> + open formats wins.

## The medallion architecture (Databricks/Delta, adopted broadly)

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   BRONZE        │ →  │   SILVER        │ →  │   GOLD          │
│  raw, append-   │    │  cleaned,       │    │  business-      │
│  only, source-  │    │  joined,        │    │  facing,        │
│  schema-faithful│    │  conformed      │    │  aggregated     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

- **Bronze**: dump exactly what arrived. No transformation.
  Schema-on-read. Retain ~30 days raw + archive to cold.
- **Silver**: cleaned, deduplicated, joined into a clean
  domain model. Schema-on-write. The "source of truth" for
  most analytics.
- **Gold**: aggregated, denormalized, business-question-shaped.
  What BI tools and ML feature stores read.

Each zone is a separate table / dataset, never overwriting the
prior layer. Provides replay capability.

## Storage layer — object stores

| Cloud | Service | Notes |
|---|---|---|
| AWS | S3 | Default; rich tooling |
| Azure | ADLS Gen2 (Hierarchical) | Faster than blob for path ops |
| GCP | GCS | Pairs with BigQuery natively |

Universal tactics:
- Lifecycle policy: bronze cold after 30d, gold cold after 1y.
- Versioning on (for accidental delete recovery).
- Object Lock / immutability for regulated data.
- Cross-region replication for DR-tier data.

## Table format — the 2026 default is Iceberg

The Open Table Formats (OTFs) add ACID + schema evolution on
top of object storage:

| Format | Origin | Strengths | Engine support |
|---|---|---|---|
| Iceberg | Netflix, Apache | Schema evolution, hidden partitioning, multi-engine | Snowflake, BigQuery, Databricks, Trino, Spark, Athena |
| Delta Lake | Databricks | Mature, time-travel, OPTIMIZE | Databricks, Spark, Trino |
| Hudi | Uber | Streaming upserts, MOR tables | Spark, Flink |

Default for new lakehouses: **Iceberg**. Multi-engine support
means you're not locked to Databricks / Snowflake / etc.

## File format — Parquet by default

- **Parquet**: columnar, compressed, broad support. Default.
- **Avro**: row-oriented, schema-evolution friendly. Use in
  Kafka / event store.
- **ORC**: like Parquet, Hive-native. Use only if you have a
  Hive stack.
- **JSON / CSV**: only at the edge (raw ingest); never the lake
  table format.

## Partitioning — the most consequential schema choice

Bad partitioning makes scans pull TB unnecessarily.

```sql
-- BAD: partitioned by user_id, query by date → full scan
PARTITIONED BY (user_id)

-- BETTER: partitioned by date for time-series queries
PARTITIONED BY (date_trunc('day', occurred_at))

-- BEST (Iceberg hidden partitioning): doesn't show up in queries
-- but planner uses it
PARTITIONED BY (day(occurred_at))
```

Rules:
- **High-selectivity** (date almost always in WHERE).
- **NOT high-cardinality** (avoid 10M unique values → 10M partitions).
- **Iceberg hidden partitioning** is much friendlier than
  Hive-style — partition column doesn't have to be in the data,
  and the user query doesn't need to know about partitioning.

## Ingestion patterns

### Batch (S3 → bronze)
```
[ source DB / API / file drop ] → [ Airflow / Glue job ] → [ bronze ]
```

### CDC (real-time OLTP)
```
[ Postgres / MySQL ] → [ Debezium / DMS / Datastream ] → [ Kafka ]
                                                            ↓
                                                 [ Spark / Flink ] → [ bronze Iceberg ]
```

### Streaming (events)
```
[ App events ] → [ Kafka / Kinesis / Pub/Sub ] → [ stream proc ] → [ bronze Iceberg ]
```

Idempotency:
- Source-stamp every row (event_id + ts).
- MERGE INTO bronze ON event_id WHEN NOT MATCHED.

## Schema enforcement + evolution

Bronze: schema-on-read (flexible — the upstream world is messy).
Silver / Gold: schema-on-write (rejects malformed records).

Iceberg evolution:
- ADD column (default null) — backward-compatible.
- RENAME column — backward-compatible (column ID stable).
- DROP column — careful; tables that consume it break.
- CHANGE type — limited; widening (int → bigint) is OK.

Always version table schemas; document breaking changes in a
deprecation registry.

## Governance

- **Catalog**: Glue Data Catalog / Unity Catalog / Polaris / Hive
  Metastore. Single registry of tables across engines.
- **Lineage**: auto-tracked (OpenLineage, Marquez, dbt docs).
- **Quality**: dbt tests / Great Expectations on silver + gold.
- **Access**: column-level + row-level security via catalog
  policies.

PII columns tagged at the catalog level → masked or denied per
role.

## Compute engines that read the lake

Pick by workload:

| Engine | Strength |
|---|---|
| Snowflake | Managed, easy, $$$ |
| BigQuery | Serverless, GCP-native, lakehouse with BigLake |
| Databricks SQL | Fast on Delta + Iceberg, ML-friendly |
| Trino / Athena | Federated query, ad-hoc, cheap |
| Spark | Programmable, ML pipelines |
| DuckDB | Single-node, $0 ops, great for small + dev |
| ClickHouse | Real-time analytical, can read external Iceberg |

Modern stacks run 2-3 in parallel (BigQuery for BI, Databricks
for ML, Athena for ops queries).

## Storage cost tactics

- Compress: Parquet + Zstandard compression saves 50-70% vs gzip
  on typical data.
- Tier: hot in S3 standard, warm in IA after 30d, cold in
  Glacier after 90d.
- Vacuum: Iceberg + Delta accrete versions; periodic compact +
  vacuum keeps storage tight.
- DROP old partitions automatically (retention policy).

A poorly maintained Iceberg table can have 10x its data in
old snapshots / orphan files. Schedule maintenance.

## Anti-patterns

- **One mega bronze table for everything.** Schema chaos;
  query unfeasible.
- **CSV / JSON as the table format.** No schema, slow scans.
- **No catalog.** Tables exist; nobody knows.
- **Schema-on-read for gold tables.** Consumers break silently.
- **No partitioning OR partitioning by high-cardinality
  column.** Scans pull everything.
- **PII in bronze without tagging.** GDPR delete is impossible.
- **Materialized aggregates not refreshed.** Stale gold tables
  silently lie.

## Validation

- [ ] Table format is one of Iceberg / Delta / Hudi (not raw
      Parquet without a manifest).
- [ ] Three-zone (bronze / silver / gold) discipline is enforced
      in the catalog.
- [ ] Partitioning chosen for query pattern, not record shape.
- [ ] Lifecycle policy + vacuum scheduled.
- [ ] PII columns tagged in the catalog.
- [ ] Lineage and data tests for silver + gold.
- [ ] Cost per zone is observable; bronze rarely dominates.
