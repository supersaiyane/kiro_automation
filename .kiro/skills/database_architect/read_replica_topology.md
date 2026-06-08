---
id: read_replica_topology
version: 1.0.0
owners: [database_architect, sre, backend_lead]
tags: [read-replica, replication-lag, ha, failover, postgres, mysql]
when_to_use: |
  Read traffic is more than 5x write traffic, OR you need a hot
  standby for failover, OR you want analytical reads off the
  primary. Read replicas are cheap; the wrong replica topology
  is the cause of subtle data bugs and surprise outages.
inputs:
  - read_write_ratio, lag_tolerance, ha_requirement
outputs:
  - "replica_topology: count + routing + lag SLA + failover playbook"
---

# Read Replica Topology — Beyond "Add a Replica"

> Read replicas trade write throughput (none, mostly) for read
> scale, HA, and bound failure domains. Get the routing wrong and
> you'll silently corrupt the user's view of their data — they
> write, immediately read, see stale data, write again. Now you
> have a duplicate.

## What a read replica gives you

- **Read scale** — many replicas can serve reads; one primary
  handles writes.
- **HA failover** — if primary dies, promote a replica.
- **Geographic locality** — replicas in user regions cut read
  latency.
- **Workload isolation** — analytical queries off the primary.

## Replication modes

| Mode | When committed primary returns | Replica lag | Data risk on failover |
|---|---|---|---|
| Synchronous | After replica acks | 0 | None |
| Async | Immediately | seconds | Last few txns lost |
| Semi-sync | Either ack or timeout | bounded | Bounded loss |

Most production systems run async by default; pick semi-sync
for "no data loss" tier (payments, ledgers). Synchronous is rare
in production due to latency tax.

## Replication lag — the hidden bug source

Async replication means the replica is BEHIND the primary by
some delta. A common bug:

```python
# WRITE goes to primary
user_repo.update(user_id, name="new_name")

# IMMEDIATELY read — goes to replica
fresh = user_repo.find(user_id)
assert fresh.name == "new_name"   # FAILS — replica hasn't caught up
```

Three solutions:

1. **Read-your-writes routing**: after any WRITE, route subsequent
   reads from that session to the PRIMARY for N seconds.
2. **Sticky session to primary**: same session reads from primary
   until session ends. Simpler; loads primary more.
3. **Quorum reads**: write to N replicas, read from ⌈(N+1)/2⌉ —
   guarantees seeing the latest write. Complex; mostly NoSQL territory.

For OLTP at scale, (1) is the standard.

## Routing patterns

```python
# Naive: app picks at random
# BAD — loses read-your-writes

# Pattern: smart router
class Router:
    def get_connection(self, query_type, session):
        if query_type == "WRITE":
            return self.primary
        if session.recent_writes(within=2.0):
            return self.primary    # serve own writes consistently
        return self.replica
```

Tools: pgbouncer (read/write splitting), pgcat, ProxySQL.
Connection pooler at the network layer keeps app code simple.

## Replication lag monitoring

ALWAYS monitor:
- `pg_replication_slots.replay_lag` (Postgres).
- `Seconds_Behind_Master` (MySQL).
- Alert if lag > N seconds for M minutes.

Sample dashboard:
```promql
postgres_replication_lag_seconds{role="replica"} > 30  # WARN
postgres_replication_lag_seconds{role="replica"} > 300 # PAGE
```

Lag spikes signal: replica overloaded, network issue, primary
WAL build-up. They precede the user-visible bug.

## Replica topology patterns

### One primary + N read replicas (most common)
```
[ primary ]
    ├── replica-1 (same AZ, hot standby for failover)
    ├── replica-2 (same region, read scale)
    ├── replica-3 (other region, geo-read)
```

### Cascading replicas (large fan-out)
```
[ primary ] → [ replica-1 ] → [ replica-2 ]
                            → [ replica-3 ]
```

- Reduces primary's replication CPU.
- Lag accumulates per hop.
- Failover gets more complex.

### Logical replication (per-table, per-DB)
- Postgres `pglogical` / Postgres logical replication.
- Replicates SELECTED tables, not the whole DB.
- Use for zero-downtime version upgrades (replicate old → new
  major) or for cross-region partial replicas.

## Failover playbook

When primary dies:

1. **Detect** — alert fires within < 30s of last health check.
2. **Promote** the best replica (lowest lag among healthy).
3. **Re-point** the proxy / DNS / pgbouncer to the new primary.
4. **Reconfigure** other replicas to follow the new primary.
5. **Validate** writes succeed.

Automation: Patroni, RDS Multi-AZ, Cloud SQL HA all do this.
For self-hosted: Patroni is the de-facto standard.

RTO targets:
- Tier 1 (payments): < 30s with auto-failover.
- Tier 2 (most apps): < 5 min.
- Tier 3 (internal tools): manual is fine; minutes to hours.

## Caveats: things that don't replicate

- **Sequences** (in Postgres < 10 logical replication) — can
  drift. Use replication-safe sequence types.
- **Temp tables, unlogged tables** — local only.
- **Statistics** — replica plans queries with its own statistics.
  Run ANALYZE there too.
- **In-memory state** (Redis-style) — not a replica problem,
  but the same architectural principle: don't assume distributed
  state is consistent.

## Cross-region replicas — latency reality

Cross-region replication lag = network RTT + serialization +
apply time. Typical:
- Same continent: 50-150ms.
- Trans-continental: 200-500ms.
- Across the world: 500-1000ms.

If a user in Tokyo reads from a US-East primary's Tokyo replica,
they get fast reads BUT data is 300ms behind. Plan UX for it
(optimistic UI, eventual consistency banner if needed).

## Analytical reads — when read replica isn't enough

A read replica works for analytical queries UNTIL:
- Long-running queries cause replication lag (vacuum + queries
  fight).
- Reporting load > OLTP read load.
- You need denormalized / columnar storage.

At that point, see `olap_oltp_boundaries` — pipe data to a real
OLAP store via CDC.

## Anti-patterns

- **Random read routing.** Read-your-writes broken; subtle bugs.
- **No replication lag monitoring.** First sign: customer
  complaint.
- **Heavy long-running SELECT on a replica.** Locks WAL replay;
  lag spikes.
- **Failover that's never been tested.** Promote-and-pray is
  not a runbook.
- **One replica behind another behind another with no monitoring
  at each hop.** Lag compounds.
- **Writing to a "read replica" by accident** (writes succeed
  if you don't enforce read-only). Set `default_transaction_read_only`.

## Validation

- [ ] Replication lag is monitored + alerted on per replica.
- [ ] Routing handles read-your-writes (verified by integration
      test).
- [ ] Failover is automated (RDS / Patroni / equivalent) and
      drilled.
- [ ] Cross-region replicas have a documented UX consistency
      story.
- [ ] No analytical queries run against the primary in business
      hours.
- [ ] Replica is set to read-only at the DB level, not just app.
