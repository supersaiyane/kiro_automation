---
id: cloud_data_pipelines_aws_azure_gcp
version: 1.0.0
owners: [database_architect, cloud_architect, devops_engineer]
tags: [data-pipeline, etl, elt, glue, dataflow, data-factory, kafka, kinesis, pubsub]
when_to_use: |
  Designing a cloud-native data movement system: source → transform →
  destination, batch or streaming. Picking the wrong primitive locks
  you into a vendor's pipeline runtime for years. Choose deliberately
  with the workload's shape (batch / micro-batch / streaming) and the
  team's operational appetite.
inputs:
  - sources, destinations, latency_sla, transformation_complexity
outputs:
  - "pipeline_design: source + transform + sink + orchestrator + cost + observability"
---

# Cloud Data Pipelines (AWS / Azure / GCP)

> Every cloud has 5+ data-movement services that overlap 80%.
> The right pick depends on: latency target, source shape,
> ops capacity, and whether you've already invested in Spark /
> Kafka. Don't pick by marketing pages.

## The pipeline taxonomy

```
┌─────────────────────────────────────────────────────────────┐
│ INGESTION                                                   │
│   Batch:    S3 / Blob / GCS landing, scheduled pulls       │
│   Stream:   Kafka / Kinesis / Event Hubs / Pub/Sub          │
│   CDC:      Debezium / DMS / Datastream / Data Factory CDC  │
├─────────────────────────────────────────────────────────────┤
│ STORAGE / STAGING                                           │
│   Raw lake:  S3 / ADLS / GCS (object storage)               │
│   Format:    Parquet / Avro / Iceberg / Delta / Hudi        │
├─────────────────────────────────────────────────────────────┤
│ TRANSFORMATION                                              │
│   Batch:    EMR Spark, Glue, Databricks, Dataproc           │
│   Streaming: Flink, Kinesis Data Analytics, Dataflow,       │
│              Stream Analytics                               │
│   Warehouse: dbt + Snowflake / BigQuery / Redshift          │
├─────────────────────────────────────────────────────────────┤
│ ORCHESTRATION                                               │
│   Airflow / MWAA / Composer / Data Factory / Dagster        │
├─────────────────────────────────────────────────────────────┤
│ DESTINATION                                                 │
│   Warehouse / lakehouse / OLTP / search / cache             │
└─────────────────────────────────────────────────────────────┘
```

## AWS pipeline service map

| Layer | Service | When |
|---|---|---|
| Streaming ingest | Kinesis Data Streams | Real-time, < 1s |
| Streaming ingest | MSK (managed Kafka) | When existing Kafka shop / open-source |
| Streaming ingest | Kinesis Firehose | Stream → S3/Redshift, no code |
| CDC | DMS | OLTP → DW initial + ongoing |
| CDC | Database Migration Service + Kinesis | RDS/Aurora → Kinesis stream |
| Batch ETL | Glue (Spark managed) | < 8h jobs, Spark-flavor |
| Batch ETL | EMR | Heavy Spark / Hadoop / Hive workloads |
| Stream processing | Kinesis Data Analytics (Flink) | Real-time aggregations |
| Stream processing | Lambda (with KCL) | Low-volume, simple transforms |
| Orchestration | Step Functions | Stateful workflow |
| Orchestration | MWAA (managed Airflow) | DAG-based, multi-system |
| Warehouse | Redshift | OLAP, Postgres-compat dialect |
| Warehouse | Athena (Presto) | Query over S3, ad-hoc |
| Warehouse | Iceberg on S3 + Athena | Lakehouse |

## Azure pipeline service map

| Layer | Service | When |
|---|---|---|
| Streaming ingest | Event Hubs | Kafka-compatible managed service |
| Streaming ingest | IoT Hub | Device telemetry |
| CDC | Data Factory CDC | OLTP → DW |
| CDC | Debezium on AKS | Open-source path |
| Batch ETL | Data Factory | No-code / SaaS-friendly |
| Batch ETL | Synapse Pipelines | Inside the Synapse workspace |
| Batch ETL | Databricks | Spark-heavy, ML-friendly |
| Stream processing | Stream Analytics | SQL over streams |
| Stream processing | Databricks Structured Streaming | Complex stateful |
| Orchestration | Data Factory | Pipeline runtime + scheduler |
| Orchestration | Azure Logic Apps | Workflow with connectors |
| Warehouse | Synapse Dedicated Pool | Classic MPP DW |
| Warehouse | Synapse Serverless | Lake query |
| Warehouse | Microsoft Fabric (newer) | Unified analytics platform |

## GCP pipeline service map

| Layer | Service | When |
|---|---|---|
| Streaming ingest | Pub/Sub | Default messaging |
| Streaming ingest | Pub/Sub Lite | Cheaper, zone-scoped |
| CDC | Datastream | Postgres / MySQL / Oracle → BigQuery |
| Batch ETL | Dataflow (Beam) | Unified batch + stream |
| Batch ETL | Dataproc | Spark / Hadoop managed |
| Stream processing | Dataflow | Beam runner, autoscaling |
| Orchestration | Cloud Composer | Managed Airflow |
| Orchestration | Workflows | Lightweight DAG |
| Warehouse | BigQuery | Serverless OLAP, default |
| Warehouse | BigLake | Lake + warehouse unification |

## Pattern 1 — Batch ETL (warehouse-bound)

```
[ Source DB ] →DMS/Datastream/DataFactory→ [ S3/ADLS/GCS raw ]
                                                ↓
                                       [ Glue/Databricks/Dataflow ]
                                                ↓
                                          [ DW: Redshift/Snowflake/BQ ]
                                                ↓
                                            [ dbt models ]
                                                ↓
                                             [ BI tool ]
```

Cadence: nightly or hourly. ELT shape (load raw, transform in DW).

Pick dbt if you've standardized SQL transformations and want
testability + version control of the transforms. dbt + Snowflake /
BigQuery is the modern lake/warehouse default.

## Pattern 2 — Streaming pipeline (real-time)

```
[ App events ] → [ Kafka/Kinesis/Event Hubs/Pub-Sub ]
                              ↓
                  [ Flink/Spark Streaming/Beam ]
                              ↓
              [ State store: OLAP / OLTP / cache ]
```

Cadence: ms - seconds. Latency budget MUST be declared up front.

Watch out for:
- **Late-arriving data** (event time vs processing time). Apache Beam
  / Flink handle this with watermarks; raw Lambda doesn't.
- **Exactly-once semantics**: Kafka with idempotent producer +
  transactional consumer + atomic commit at sink. Hard to get right.
- **Backpressure**: when downstream slows, upstream must too.
  Flink / Beam handle natively; hand-rolled streams flap.

## Pattern 3 — Lambda Architecture (batch + speed layer)

```
Source → [ Stream layer (real-time, approximate) ]
        → [ Batch layer (nightly, correct, overwrites) ]
              ↓
          Serving = merge of both layers (correct latest hours, approximate now)
```

Used when stream gives speed but batch is the source of truth for
correctness. Modern shift: Kappa architecture (stream only, with
replay for corrections via Iceberg / Delta time-travel).

## Pattern 4 — CDC to warehouse (OLTP → analytics)

```
[ Postgres / MySQL ] → [ Debezium / DMS / Datastream ]
                              ↓
                  [ Kafka / Kinesis / Pub/Sub ]
                              ↓
                  [ DW: BigQuery / Snowflake / Redshift ]
```

Use this to keep the warehouse fresh without querying OLTP. Most
modern stacks default here over nightly dumps.

## Orchestration choice

| Choice | Strength | Weakness |
|---|---|---|
| Airflow (MWAA / Composer / self-host) | Python DAGs, big ecosystem | Operational tax |
| Dagster | Modern, asset-oriented | Younger ecosystem |
| Prefect | Python-native, cloud + OSS | Vendor lock-in on cloud |
| Step Functions | Native AWS, stateful | AWS-only, JSON-heavy |
| Data Factory | Azure-native, low-code | Azure lock-in |
| Cloud Workflows | GCP-native, lightweight | Limited expressiveness |

Default for portable stacks: Airflow. Default for cloud-native
locked-in path: native service.

## Cost levers

- **Spot for batch transforms** (EMR + Spot, Dataflow flexible
  resource scheduling, Databricks spot pools).
- **Auto-scaling cluster size** per job (avoid always-on).
- **Columnar formats** (Parquet, ORC) at rest — 5-10x smaller than
  CSV / JSON.
- **Partition by date** for time-windowed queries (partition pruning).
- **Materialize hot views** vs recompute every query.

## Observability for pipelines

- **Per-job runtime** trend; alert if 2x baseline.
- **Data quality checks** (dbt tests, Great Expectations) — row
  counts, null rates, referential integrity.
- **Schema drift detection** — fail loud on unexpected column type.
- **Lag from source to destination** as a first-class SLO.
- **Cost per run** — high-cost runs flagged.

## Anti-patterns

- **Custom Python ETL when dbt would do.** Reinventing tested
  transformations.
- **Streaming when batch suffices.** Streaming is 5x harder to
  operate.
- **No schema enforcement on the lake.** Garbage in, garbage in
  forever.
- **One mega-DAG with 200 tasks.** Brittle; long debug cycles.
- **No data lineage.** Who consumes this table? Nobody knows when
  it breaks.
- **CDC pipeline with no replication slot monitoring.** Postgres
  WAL fills; primary crashes.
- **Direct queries from BI tools to OLTP.** Use a warehouse.

## Validation

- [ ] Every pipeline has an owner + SLO (freshness, completeness).
- [ ] Schema is enforced at the lake (Parquet/Iceberg/Delta).
- [ ] Data quality tests run on every pipeline run.
- [ ] Costs per pipeline are visible per month.
- [ ] No PII flows into the lake without classification.
- [ ] Source → destination lag is observable and alerted.
- [ ] Orchestrator's pipeline definitions live in git, not in the
      UI.
