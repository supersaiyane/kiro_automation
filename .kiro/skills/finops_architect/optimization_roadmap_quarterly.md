---
id: optimization_roadmap_quarterly
version: 1.0.0
owners: [finops_architect, devops_engineer, sre]
tags: [optimization, roadmap, right-sizing, spot, lifecycle, finops]
when_to_use: |
  After INFORM phase is mature (you can see what's spent and
  who's spending it). The roadmap is the OPTIMIZE phase: a
  prioritized list of concrete projects with expected savings,
  owners, and due dates. Without this, FinOps is decoration.
inputs:
  - current_spend_breakdown, growth_forecast, team_capacity
outputs:
  - "quarterly_roadmap: ranked projects + $ savings + owner + due date + measurement"
---

# FinOps Optimization Roadmap — Make It A Sprint, Not A Vibe

> "We should optimize cost" without a backlog is a wish.
> A roadmap with prioritized items, $ savings projection, owner,
> and due date is engineering.

## The roadmap shape

For each quarter, 5-10 prioritized projects:

```
P1  Right-size top-10 over-provisioned instances     -$8k/mo   alice    M+30 days
P2  Move CI runners to spot pool                     -$4k/mo   bob      M+45 days
P3  Lifecycle policy on S3 (Glacier > 90d)           -$3k/mo   carol    M+30 days
P4  Renegotiate Datadog contract                     -$5k/mo   dave     M+60 days
P5  Reduce dev DB instance class                     -$2k/mo   alice    M+15 days
P6  Compute Savings Plan: increase coverage 60→75%   -$6k/mo   bob      M+30 days
P7  Drop unused Elastic IPs / EBS snapshots          -$0.5k/mo  carol    M+15 days
P8  Move non-prod to off-hours auto-shutdown         -$4k/mo   bob      M+45 days
P9  CDN cache tuning to reduce origin egress         -$3k/mo   dave     M+60 days
P10 Audit + drop unused IAM-attached resources       -$1k/mo   alice    M+30 days
```

Each item is a TICKET. With owner. With due date. With expected
savings. Tracked like feature work.

## The 80/20 of savings (in rough order)

### Tier 1 — high-impact, low-effort (do FIRST)

| Lever | Typical savings |
|---|---|
| Right-size top 10 over-provisioned instances | 5-20% of compute |
| Off-hours shutdown of non-prod | 50-70% of non-prod |
| Drop unused EBS snapshots / EIPs / NAT GWs | 1-3% |
| Increase commitment coverage 60 → 75% | 5-10% of compute |
| S3 Intelligent Tiering / lifecycle policies | 30-60% of storage |

### Tier 2 — moderate effort

| Lever | Typical savings |
|---|---|
| Spot for batch / CI / non-critical | 30-50% of those workloads |
| Reduce log retention to compliance minimum | 20-40% of log spend |
| Renegotiate top vendor contracts | 10-30% of vendor spend |
| Cache tuning to reduce egress / origin hits | 5-20% of egress |

### Tier 3 — high effort, high reward

| Lever | Typical savings |
|---|---|
| Refactor to serverless where workload fits | 30-70% on that workload |
| Database tier change (Aurora → Aurora Serverless v2) | 20-50% on those DBs |
| Migrate to ARM / Graviton instances | 10-40% on compute |
| Re-architect cross-region replication | 50%+ on egress |

## Prioritization framework

Score each candidate:

```
Priority score = (Expected savings $/mo) × (Confidence 0-1)
                 ÷ (Effort estimate in eng-days)
```

Run a quarterly grooming meeting; sort backlog by score.

## Owner discipline

Every roadmap item has ONE owner. Not "the team," not "platform."
A person.

When the owner leaves the team or hands off, the item's tracking
ticket is updated. Untracked items become orphan; orphan items
don't ship.

## Measurement

Each item needs:
- **Baseline** measurement BEFORE work starts (last month's bill).
- **Savings measurement** AFTER work ships (vs. baseline).
- **Comparison** quarterly: roadmap projected $X savings,
  achieved $Y. Variance investigated.

Without measurement, the roadmap turns into "we did some things"
with unclear ROI.

## Sample quarterly cycle

```
Q1 weeks 1-2:  Audit. Identify top 10 candidate optimizations.
Q1 week 3:     Score + prioritize. Lock the roadmap.
Q1 weeks 4-13: Execute. Weekly status in FinOps review.
Q1 week 13:    Measure savings. Compare to projections.
Q2 week 1:     Retro. New roadmap based on what's now visible.
```

## Categories of resistance to overcome

- **"We need the headroom"** (right-sizing pushback). Show
  utilization graphs; agree on 60% utilization target, not 5%.
- **"Spot is risky"** (engineer aversion). Pilot on CI;
  demonstrate; expand.
- **"We can't shut dev off, I work nights"** (team pushback).
  Allow opt-in / opt-out; default to shutdown.
- **"Vendor X won't negotiate"** (procurement reluctance).
  Show the leverage of multi-cloud / open-source alternatives.

The FinOps Architect's role is not just technical; it's
political. Bring data to every conversation.

## The "no" list

Optimization can backfire:

- **Don't reserve capacity on a workload about to be deprecated.**
- **Don't compress storage so heavily that read latency suffers.**
- **Don't shut dev off in a way that breaks long-running tests.**
- **Don't right-size below the p95 spike (gives buffer).**

Engineering judgment + cost discipline together; not cost alone.

## Anti-patterns

- **Roadmap with no owners.** Decoration.
- **Aspirational savings ("we'll save $1M/year if we optimize").**
  Decompose into items or it's not real.
- **No measurement after ship.** Did it actually save the money?
  Often answer is "less than projected" — and the org doesn't learn.
- **One mega-project ("rewrite the warehouse").** 90% of value
  is in 10 small wins; chase those first.
- **Skipping the easy stuff because it's not glamorous.** Spot
  + commitments + lifecycle = boring; saves 30%+ collectively.
- **FinOps team owns the roadmap alone.** Engineering teams own
  the items.

## Validation

- [ ] Quarterly roadmap exists with 5-10 items.
- [ ] Each item has owner + due date + projected savings.
- [ ] Last quarter's roadmap was measured at end-of-quarter.
- [ ] Projected vs actual savings variance < 30%.
- [ ] At least one Tier 1 lever shipped per quarter.
- [ ] No orphan optimization tickets > 90 days old.
