---
id: finops_baseline
version: 1.0.0
owners: [cloud_architect, devops_engineer, cto]
tags: [finops, cost-optimization, savings-plans, tagging, chargeback]
when_to_use: |
  Cloud bill is non-trivial AND owned by no one specific. FinOps
  is the discipline of treating cloud spend as a managed input,
  not a surprise on the invoice. Apply BEFORE the CFO asks why
  the bill doubled.
inputs:
  - current_bill, growth_rate, team_structure
outputs:
  - "finops_baseline: tagging + chargeback + commitments + anomaly detection + reviews"
---

# FinOps Baseline — Cloud Spend As Engineering Discipline

> Cloud cost is the side-effect of engineering decisions. Treat
> it as observable, ownable, optimizable. The FinOps Foundation's
> framework (Inform → Optimize → Operate) is the playbook.

## The three FinOps phases (FinOps Foundation)

```
1. INFORM   — visibility into who's spending what, anomalies surfaced
2. OPTIMIZE — right-size, commitments, eliminate waste
3. OPERATE  — continuous review, automated guardrails, culture
```

Most orgs are stuck at INFORM ("we have a Datadog dashboard").
The leverage is in OPTIMIZE + OPERATE.

## INFORM — make the bill legible

### Tagging policy (mandatory)
Every resource MUST have:
- `env` (prod / staging / dev / sandbox)
- `cost-center` or `team`
- `application` or `workload`
- `owner` (email)
- `temp-until` (for ephemeral)

Enforced by Org Policy / Azure Policy / GCP Org Policy. Resources
without tags FAIL to create, or auto-tag → email the responsible
team.

### Chargeback / showback
- **Chargeback**: actual cost billed to the team's P&L.
- **Showback**: visibility, no billing.

Showback is the cultural starting point; chargeback comes after
teams trust the tagging.

### Anomaly detection
- AWS Cost Anomaly Detection / Azure Cost Management / GCP
  Recommender.
- Custom threshold: alert if a service category jumps > 20%
  WoW.
- Per-team budget alerts at 50% / 80% / 100% of monthly target.

## OPTIMIZE — the 80/20 levers

### Right-sizing (biggest savings)
Most cloud bills have 30-50% over-provisioning waste.

- **CPU + memory utilization**: target avg 40-60%. < 20% = downsize.
- **Database instance class**: same rule.
- **EBS volumes**: gp3 > gp2 for almost everything; smaller IOPS
  provisioning where possible.
- **Tools**: AWS Compute Optimizer, Azure Advisor, GCP
  Recommender — show specific right-size recommendations.

### Commitments (Reserved Instances, Savings Plans, CUDs)
30-70% savings on STEADY workloads:

- **Compute Savings Plans (AWS)**: most flexible. Commit $X/hr
  for 1 or 3 years.
- **EC2 Instance Savings Plans**: deeper discount, family-locked.
- **Reserved Capacity (Azure)**: similar.
- **Committed Use Discounts (GCP)**: similar.

Pick by:
- 1-year vs 3-year (3-year only if confident in workload).
- Coverage target: 60-80% of baseline. Leave headroom for
  scaling, growth, refactors.

### Spot / interruptible (huge for fault-tolerant)
70-90% off list price for workloads that can survive a 2-min
notice termination:
- Batch processing.
- CI/CD runners.
- ML training.
- Non-prod environments.

NEVER use spot for stateful prod or anything not auto-restart.

### Storage tiering
- S3: Intelligent Tiering by default; lifecycle policies for cold
  data → Glacier.
- Azure Blob: Hot → Cool → Archive lifecycle.
- Old snapshots, detached volumes, orphaned IPs — easy waste.

### Auto-scaling DOWN in off-hours
Non-prod environments shutting overnight = 60%+ saving on those
envs.
- Lambda for hours-of-operation enforcement.
- Auto-scaling group min-instances = 0 in off-hours.

## OPERATE — continuous discipline

### Monthly cost review
- Per-team breakdown + WoW trend.
- Top 5 cost drivers + their owners.
- New anomalies + resolutions.
- Commitment coverage + utilization.

15-minute meeting; team leads attend.

### Quarterly deep-dive
- WAF cost pillar review per workload.
- Renew / adjust commitments.
- Retire deprecated services.

### Automation gates
- New resource fails creation if cost > $X/mo without approval.
- Sandbox accounts have hard ceilings ($500/mo, auto-suspend).
- Pre-merge CI checks: "this Terraform adds $Y/mo" for visibility.

## The data layer cost trap

Database is usually the biggest line item AND the hardest to
optimize because it's stateful:

- Don't run prod-class instances in dev.
- Auto-pause dev DBs in off-hours (Aurora Serverless v2, Azure
  SQL Serverless support this).
- Drop unused read replicas.
- Compress + archive cold partitions.
- See `time_series_schema_design` for tiered storage that pays
  for itself in storage cost.

## Egress + cross-region transfer

The hidden cost:
- AWS cross-region: $0.02/GB.
- AWS internet egress: $0.05-0.09/GB.
- Azure / GCP similar.

Mitigations:
- Use VPC Endpoints / PrivateLink for cloud-internal traffic.
- CDN (CloudFront, Cloud CDN) for public — caches at edge.
- Avoid chatty cross-region replication on hot data.

## The "set it and forget it" myth

Cloud bills GROW silently:
- Engineers spin up resources for "just a test."
- Old experiments never get cleaned up.
- Workloads grow but right-sizing doesn't keep pace.

Without FinOps DISCIPLINE (reviews, ownership, anomaly alerts),
your bill compounds.

## Anti-patterns

- **Bill owned by no one.** "It's just cloud cost."
- **One person reviews the bill monthly, manually.** Doesn't scale.
- **Tagging "encouraged."** Not enforced = chargeback impossible.
- **Buying RIs / Savings Plans before stabilizing workload.**
  Lock in 3-year commitment, then refactor 6 months later.
- **Running non-prod 24/7.** Easy 50%+ savings.
- **Skipping the FinOps role at scale.** > $1M/mo cloud spend
  warrants dedicated FinOps headcount.
- **Cost dashboards no one looks at.** Tied to a recurring
  meeting, or it doesn't get used.

## Tools (2026)

- **Native**: AWS Cost Explorer, Azure Cost Management, GCP
  Billing.
- **Multi-cloud + advanced**: CloudHealth, Apptio Cloudability,
  Anodot.
- **K8s-specific**: OpenCost / Kubecost (per-pod, per-namespace
  cost).
- **Anomaly**: native or Vantage / CloudZero.
- **Commitment optimization**: Vantage, CloudZero, ProsperOps.

## Validation

- [ ] Tagging policy enforced by org policy (not advisory).
- [ ] Per-team chargeback or showback dashboard exists.
- [ ] Monthly FinOps review meeting runs with team leads.
- [ ] Commitment coverage > 60% on baseline workloads.
- [ ] Right-sizing reviewed quarterly.
- [ ] Cost anomaly alerts page someone.
- [ ] Sandbox accounts have hard cost ceilings.
- [ ] Non-prod environments auto-shut overnight.
