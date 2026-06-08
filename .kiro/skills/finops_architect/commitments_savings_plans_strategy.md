---
id: commitments_savings_plans_strategy
version: 1.0.0
owners: [finops_architect, cloud_architect]
tags: [reserved-instances, savings-plans, committed-use, commitment, finops]
when_to_use: |
  Cloud spend > $50k/month with stable baseline. Commitments
  unlock 30-70% savings on workloads that don't shrink. Done
  poorly, you over-commit on tech you'll refactor away. Done
  well, this is the single biggest FinOps lever.
inputs:
  - on_demand_baseline, workload_stability, growth_forecast
outputs:
  - "commitment_plan: tier + coverage % + term + renewal cadence + owner"
---

# Commitments — The 30-70% Lever

> Reserved Instances, Savings Plans, Committed Use Discounts.
> Different names; same math: trade flexibility for a discount.
> Commit to STABLE baseline; pay on-demand for variable tier.

## The three vendor models

### AWS — Savings Plans + Reserved Instances

| Type | Flexibility | Discount | Term |
|---|---|---|---|
| Compute Savings Plan | Cross-region, cross-family, EC2/Lambda/Fargate | ~28-66% | 1y or 3y |
| EC2 Instance Savings Plan | Family-locked, region-locked | ~40-72% | 1y or 3y |
| Standard RI | Instance-type / region locked | ~30-72% | 1y or 3y |
| Convertible RI | Trade between families | ~26-66% | 1y or 3y |

Default: Compute Savings Plans for steady spend. Standard RIs
for very stable, predictable instance shapes.

### Azure — Reserved VM Instances + Savings Plans for Compute

| Type | Flexibility | Discount | Term |
|---|---|---|---|
| Savings Plan for Compute | Cross-VM-series, cross-region | ~11-65% | 1y or 3y |
| Reserved VM Instance | Specific VM size / region | ~20-72% | 1y or 3y |
| Cosmos DB Reserved Capacity | Cosmos throughput | ~20-65% | 1y or 3y |

### GCP — Committed Use Discounts (CUDs)

| Type | Flexibility | Discount | Term |
|---|---|---|---|
| Flexible CUDs | Cross-machine-type within family | ~20-46% | 1y or 3y |
| Resource-based CUDs | Specific machine type | ~25-57% | 1y or 3y |
| Spend-based CUDs (specific services) | Service-bound | varies | 1y or 3y |

## Coverage target: 60-80% of baseline

```
Total stable compute baseline: 1000 instance-hours/day

Commit:  600-800 hours/day @ Savings Plan
On-demand: 200-400 hours/day for growth + variation

Coverage % = 60-80%
```

Why not 100%? Two reasons:
1. **Workload growth + refactor**: 12-36 months locks in.
   Reservations might outlast the workload.
2. **Spot opportunity**: variable tier on spot saves more than
   committing to it.

## 1-year vs 3-year decision

```
Discount    1-year    3-year
Average     ~30%      ~55%

Implied break-even:
   3-year only beats 1-year if workload stable > 2 years.
```

Default to 1-year for new workloads. 3-year for steady-state
core platform (typically: 30-50% of total commit volume).

## When NOT to commit

- Workload < 6 months old (might refactor away).
- Migration in progress (target shape unknown).
- Heavy seasonality (commit baseline only).
- Spiky / burst workloads (use spot, not commit).
- Pilot / experimental services.

## Renewal cadence + ownership

A reservation is a 12 or 36 month liability. Treat it like one:
- ONE owner accountable for each reservation cohort.
- Quarterly review: are we using what we bought?
- Renewals 30-60 days BEFORE expiry to avoid on-demand gap.
- Renewal includes refactor check (does this reservation still
  match what we're running?).

## Utilization monitoring

If you commit 1000 hours/day and use 600, you're paying for 400
hours of nothing. Utilization < 80% = signal:

- Workload shrunk (right-size to commitment).
- Workload moved (re-region, re-instance-type).
- Or sell unused (AWS RI Marketplace, Azure exchange).

Most cloud providers expose utilization dashboards; check
monthly.

## Multi-account / cross-OU commitments

AWS Savings Plans + RIs auto-apply across accounts in an org
(if RI sharing is on). Azure Reserved Capacity at the EA / MCA
level shares similarly. Don't buy per-account; buy at org level
and let it float to where used.

GOTCHA: a runaway dev account can consume prod's commitments.
Block via service control policies on the dev account.

## Procurement timing

- **Q1 best for big commits**: vendors have annual quotas;
  some flexibility on price (especially 3-year multi-million).
- **Negotiate Enterprise Discount Programs (EDP)**: > $1M/year
  qualifies. Stack EDP discount on top of Savings Plans.
- **Marketplace credits**: AWS / Azure / GCP marketplace
  resellers sometimes offer further discounts.

If your total annual cloud spend exceeds ~$2M, get a sales rep
involved in commitment design.

## Spot capacity — the other lever

For interruptible workloads:
- Batch processing.
- CI runners.
- ML training.
- Stateless API tier with auto-respawn.

Spot saves 70-90% vs on-demand. Combine with commitments for
baseline + spot for variable.

Modern pattern: Karpenter / cluster-autoscaler with spot pool
priority; commit only on baseline.

## Quarterly review template

```
Service category    | Commit (hrs) | Used (hrs) | Util %  | Action
EC2 c5.xlarge       | 24/24        | 22/24      | 92%     | Renew
Lambda              | $X spend     | $0.95X     | 95%     | Renew + 10%
RDS db.m5.large     | 24/24        | 12/24      | 50%     | Reduce by 50% at renewal
Total spend $       | $T_c         | $T_used    | $T_c-T_used = waste
```

If utilization dropped, the cause must be identified BEFORE
renewing.

## Anti-patterns

- **Commit-first, model-later.** Lock in before you understand
  workload. 30% waste guaranteed.
- **All-3-year.** Maximum savings, maximum lock-in. 50-70%
  3-year is fine; 100% is brave.
- **Set-and-forget.** Workload shifts; commits stay; bill stays.
- **Buying RIs at the account level for an org-wide need.**
  Stranded capacity.
- **Renewal happens at expiry day.** 30-60 day lead time;
  on-demand fills the gap and undoes the savings.
- **Marketplace impulse buys.** Vendors offer "deals" that
  don't match the workload. Model first.

## Validation

- [ ] Commitment coverage tracked weekly per cloud + per
      service category.
- [ ] Utilization > 80% on all active commitments.
- [ ] 1y vs 3y mix is intentional, not historical accident.
- [ ] Renewal calendar reviewed quarterly.
- [ ] Spot vs commit split is documented per workload.
- [ ] EDP / volume discount negotiated if spend > $2M/yr.
- [ ] Workload changes trigger commitment review.
