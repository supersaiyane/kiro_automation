---
id: multi_region_strategy
version: 1.0.0
owners: [cloud_architect, sre, architect]
tags: [multi-region, dr, active-active, active-passive, latency, residency]
when_to_use: |
  Tier 1 workloads (downtime measured in revenue/min), or strict
  data residency (GDPR, India DPDP), or sub-200ms global latency.
  Multi-region is expensive and complex; reach for it only with a
  clear driver, not because "we should."
inputs:
  - rto_rpo_targets, residency_constraints, user_geo_distribution
outputs:
  - "multi_region_design: pattern + region pairs + failover playbook + cost delta"
---

# Multi-Region — Pattern Picks The Cost

> "Multi-region" is three different architectures wearing one name.
> Disaster-recovery passive, active-active, and per-region tenancy
> have vastly different cost, complexity, and consistency budgets.

## The four patterns

### 1. Backup-Only (cheapest)
- Backups copied cross-region.
- No standby compute; restore on demand.
- RTO: hours. RPO: minutes-hour.
- Cost adder: ~5%.
- Use for: Tier 3-4 workloads.

### 2. Pilot Light (warm)
- Critical infra (DB, vault) replicated and running, BUT app
  tier scaled to zero.
- Failover: scale-up app tier + DNS cutover. ~30 minutes.
- RTO: 30 min. RPO: < 1 minute (DB replication).
- Cost adder: ~20-30%.

### 3. Active-Passive (warm-standby)
- Full duplicate stack in DR region.
- Async replication; DR region serves zero traffic in steady
  state.
- Failover: DNS cutover. < 5 minutes.
- RTO: < 5 min. RPO: seconds (sync where possible).
- Cost adder: ~80% (you're paying ~2x).

### 4. Active-Active
- Both regions serve traffic; each region has full stack +
  bidirectional data replication.
- Multi-master DB OR sharded by region.
- Per-region steady-state; failover is "stop sending to the
  dead region" — zero data loss possible.
- RTO: seconds. RPO: 0 (sync) or seconds (async).
- Cost adder: ~150-200% (more than 2x due to cross-region
  replication + complexity).

## Pick the cheapest pattern that meets your SLO

```
Driver                  → Pattern
DR-only                 → Backup-Only or Pilot Light
RTO < 30 min, RPO ~min  → Active-Passive
Sub-200ms global        → Active-Active
GDPR residency          → Per-region tenancy (variant of A-A)
```

Active-Active sounds glamorous; most companies overbuild for
their actual SLO.

## Data layer is the hard part

Stateless app tier replicating is easy. Data tier:

| Store | Active-Passive | Active-Active |
|---|---|---|
| Postgres | Logical replication / pglogical | Citus / Spanner-like, hard |
| MySQL | InnoDB Cluster, async | Vitess multi-region, Aurora Global |
| DynamoDB | Global tables (default) | Global tables (default) |
| Spanner | Multi-region (default) | Multi-region (default) |
| Cassandra | Multi-DC native | Multi-DC native |
| Redis | Replication async | RedisLabs Active-Active CRDT |

For relational active-active: either pay for Spanner/CockroachDB,
or accept the conflict-resolution complexity yourself.

## Region pair selection

- **Geographic separation**: > 500 km apart to survive natural
  disaster.
- **Independent power grids + carrier networks**.
- **Same provider** typically; cross-cloud DR is a separate level.
- **Latency considered**: us-east-1 + us-east-2 is geo-close but
  separate power grids = good. us-east-1 + us-west-2 has higher
  latency but stronger disaster isolation.
- **Regulatory**: EU-only workloads → pair within EU
  (eu-west-1 + eu-central-1).

## Data residency — GDPR-shaped

Multi-region under GDPR means:
- EU user data physically resident in EU.
- Replication to non-EU only with explicit lawful basis.
- Backup destination respects residency.
- Compute that processes EU data ALSO in EU (data transit
  matters).

Architecture: per-region tenancy. Customer signs up in EU →
EU stack handles everything. No silent replication to US.

## Failover playbook (active-passive)

```
1. DETECT — health checks confirm region-down.
2. DECIDE — IC declares failover (not auto for tier-1;
   automatic for some tier-2).
3. FAIL OVER:
   a. Promote DR region's DB to primary.
   b. Update Route 53 / Traffic Manager weights → DR region.
   c. Scale up DR app tier.
   d. Run smoke tests.
4. COMMUNICATE — status page update.
5. RECOVER — once primary region is healthy, plan controlled
   fail-back (in business hours, low-traffic window).
```

Total: < 5 min for tier-1, < 30 min for tier-2.

DRILL THIS QUARTERLY. A failover that's never tested usually
fails (DNS TTLs too long, missing IAM permissions, wrong
secrets in DR region).

## Cost realities

Cross-region data transfer is EXPENSIVE.
- AWS: $0.02/GB cross-region.
- 100GB/day replication = $60/mo just transfer.
- TB/day = $600/mo just transfer.
- Active-Active doubles every write's network cost.

Compute doubling is the visible cost; DATA TRANSFER often
exceeds it. Model it BEFORE picking active-active.

## DNS strategy

- Route 53 / Traffic Manager / Cloud DNS with health-check
  routing.
- LOW TTL (60s) for failover-critical names.
- Active-Active: latency-based or weighted routing.
- Active-Passive: failover policy (primary + secondary).

Tip: an "evacuation" mode — manually shift traffic away from a
region during a problem before declaring failover.

## Anti-patterns

- **Multi-region for the optics.** Spend the money on resilience
  in the current region first.
- **Active-Active without conflict resolution design.** Conflicts
  WILL happen. Design for them OR pick a store that handles them
  (Spanner, CockroachDB).
- **DR region with stale schema / config.** Drift = failover
  fails.
- **No failover drill.** First time you test it is during the
  incident. Done in DR with comms team.
- **Single DNS provider with no failover plan.** DNS provider
  outage is its own failure mode.
- **Cross-region replication for low-tier workloads.** Pure cost
  with no SLO win.
- **Picking the same vendor for primary + DR.** Vendor-wide
  outage = both down.

## Validation

- [ ] Pattern is named and matches the SLO (no over-design).
- [ ] Region pair survives a single natural disaster.
- [ ] Failover drill in the last 6 months met RTO.
- [ ] Data replication monitored; lag alerts page.
- [ ] DNS TTL on failover-critical names ≤ 60s.
- [ ] Cost model includes cross-region transfer.
- [ ] Residency constraints encoded in the architecture, not
      in policy alone.
