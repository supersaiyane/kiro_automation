---
id: consistency_models_cap
version: 1.0.0
owners: [architect, backend_lead]
tags: [cap, pacelc, consistency, distributed, replication]
when_to_use: |
  Any design involving more than one node holding data — multi-region
  DB, cache + DB, master + read replica, event-sourced system,
  microservices reading each other's stores. Pick the consistency
  model *explicitly* before writing code.
inputs:
  - data_access_pattern: read/write ratio, locality, staleness tolerance
outputs:
  - chosen_model: linearizable / sequential / causal / eventual + boundary
---

# Consistency Models — A Working Architect's Guide

## CAP (necessary, not sufficient)

> Under network partition, choose Consistency **or** Availability.

But partitions are rare; the everyday question is **latency vs.
consistency** when the network is fine. That's PACELC:

> If Partition: choose A or C. **Else: choose L (latency) or C
> (consistency).**

Most production decisions are PACELC's "else" branch.

## The model hierarchy (strongest to weakest)

| Model | What it guarantees | Cost |
|---|---|---|
| **Linearizable** | Reads see the latest committed write, globally | Highest latency; requires consensus on every write |
| **Sequential** | Some total order, all clients agree | Lower latency than linearizable, no real-time guarantee |
| **Causal** | If A happened-before B, all clients see A before B | Cheaper; no real-time guarantee |
| **Read-your-writes** | A client sees its own writes | Per-client sticky-read or session token |
| **Monotonic reads** | Subsequent reads never go backward in time for a client | Sticky-read |
| **Eventual** | Replicas converge eventually, no ordering | Cheapest; reads may see stale data of unbounded age |

**Default**: pick the **weakest model that still satisfies the
business rule**. Linearizable for money. Causal for social timelines.
Eventual for view counts.

## Mapping data to models

| Data | Right model | Why |
|---|---|---|
| Account balance | Linearizable | Double-spend = lawsuit |
| Order placement | Linearizable on the order key, eventual on the catalog | Order is the truth; catalog can be slightly stale |
| Username uniqueness | Linearizable on the unique index | Race conditions create duplicate accounts |
| Like count | Eventual | One-off staleness is fine |
| Inbox message ordering | Causal | Replies must follow the message they reply to |
| Auth token validity | Read-your-writes, then eventual revocation | Login must work immediately; logout can propagate |

## Practical patterns

### "Read your writes" via session sticky read
After a write, route the same client's next read to the primary (or the
replica that has caught up). Most DBs expose a session token / LSN.

### Causal consistency via vector clocks (or hybrid clocks)
Each event carries a vector of `(node_id → counter)`. Readers can
suppress display of an event until all causal predecessors are visible.

### Bounded staleness ("at most 5 seconds old")
Acceptable for analytics + dashboards. Make it a contract; track
replication lag and alert when it exceeds the bound.

### Quorum reads/writes (R + W > N)
N replicas, write to W, read from R. If R + W > N, every read sees the
latest committed write. Tuning the knobs:
- Read-heavy: W=N, R=1 (slow writes, fast reads, full durability)
- Write-heavy: W=1, R=N (fast writes, slow reads)
- Balanced: W = R = ceil((N+1)/2) — Dynamo default

### Optimistic concurrency control (OCC)
Read with a version. Write with `WHERE version = X`. If 0 rows
updated, retry from the read. Works when conflict rate is <5-10%.

### Pessimistic locks
Use only on hot rows with high contention. Long-held locks are the
cause of most "the database is fine but the app is dying" outages.

## Tradeoffs cheat sheet

- **Stronger consistency → higher latency, lower availability under
  partition.** Always.
- **Multi-region active-active linearizable**: requires Spanner/Calvin
  class systems. Order of magnitude more complex.
- **Eventual consistency for a domain that needs causality**: ships
  bugs that look like race conditions in production but pass every
  unit test. Avoid.

## Anti-patterns

- "We just use the DB" with no statement of replication / isolation
  level. Read Committed (most defaults) is not Serializable.
- Mixing isolation levels in one transaction. Picking the wrong one
  for the wrong operation = phantom reads, lost updates.
- Cache-aside without invalidation strategy. The cache becomes a
  source of truth by accident.
- Treating a read replica as authoritative. Lag is unbounded under
  load; don't read your own writes from it.
- Designing for linearizable, then "optimizing" by reading from
  replicas. You've silently downgraded to eventual.
- "We'll add consistency later." Switching from eventual to causal
  is a six-month migration; design for the right model from day one.
