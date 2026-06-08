---
id: chargeback_showback_models
version: 1.0.0
owners: [finops_architect, cto, devops_engineer]
tags: [chargeback, showback, allocation, tagging, accountability]
when_to_use: |
  Cloud bill is owned by no one specific OR by "Engineering" as
  a single bucket. Without per-team cost visibility, optimization
  is theoretical. Chargeback / showback make spend a metric every
  team can see and act on.
inputs:
  - team_structure, current_tagging, gl_chart_of_accounts
outputs:
  - "allocation_model: tagging spec + allocation rules + reporting cadence + dispute path"
---

# Chargeback vs Showback — Make Cost Visible, Then Owned

> Engineering doesn't optimize what it can't see. Chargeback
> (real internal billing) and showback (visibility-only) are the
> mechanisms. The choice depends on org maturity; both require
> the same plumbing.

## The two models

### Showback
- Cost VISIBLE to teams via dashboard.
- No actual billing.
- Cultural starting point.
- Low political cost; high educational value.

### Chargeback
- Cost actually billed to team's P&L / budget.
- Real consequences for over-spending.
- Higher trust needed in allocation accuracy.
- Reach for it after 6-12 months of showback.

Start with showback. Move to chargeback when teams trust the
numbers AND have the autonomy to act on them.

## Prerequisites — tagging discipline

Cost allocation depends on accurate tagging:

```yaml
# Mandatory tags (enforced by Org Policy)
env: prod | staging | dev | sandbox
team: payments | identity | platform | data
cost_center: COST-1234
application: orders-api | checkout-web
owner: alice@example.com
```

Enforcement: resource creation FAILS without these tags. The
exception is grandfathered legacy infra, retagged in a quarterly
sweep.

Tagging coverage target: > 95% of monthly spend. Below that,
allocation is too lossy to use.

## Allocation rules

Per cost line:

| Line | Allocation key | Notes |
|---|---|---|
| EC2 / Compute | `team` tag | Direct |
| Storage (S3 / Blob) | `team` tag per bucket | Direct |
| Database (RDS, Cosmos) | `team` tag | Direct |
| Network egress (NAT, internet) | by VPC tag | One VPC = one team |
| Shared services (DNS, IAM, observability) | weighted by `team` direct spend | Allocated |
| Engineering platform team | spread across all teams or zero | Decide |

The "shared services allocation" is the political one. Two
approaches:
- **Allocate**: every team pays share of shared services. Fair
  but hides shared-service cost from itself.
- **Don't allocate**: platform team owns its own bill; teams see
  only direct cost. Cleaner; platform team must justify its bill.

## Untagged cost — the leak

Resources without tags can't be allocated. Options:

1. **Penalty bucket**: allocate to a "shame" cost center. Tagging
   improves fast.
2. **Spread proportionally**: averaged across teams by direct spend.
3. **Platform absorbs**: counted against the platform team.

Use #1 during a tagging crackdown; switch to #2 or #3 once
coverage is high.

## Reporting cadence

- **Daily**: trend dashboard, anomaly alerts (Slack).
- **Weekly**: team-level summary email.
- **Monthly**: official chargeback / showback statement
  reviewed by team lead + finance.
- **Quarterly**: deep dive — top drivers, optimization wins,
  next-quarter forecast.

## Dispute resolution

Numbers will be questioned. Have a process:

1. Team disputes a line item.
2. FinOps team investigates: tagging error? Allocation rule
   wrong? Shared service genuinely consumed by them?
3. Decision recorded.
4. If allocation rule changed, retroactive adjustment for current
   month (not past).

Without a dispute mechanism, teams stop trusting the numbers.

## Cost ceiling per environment

For chargeback maturity:

- **Hard limits** on dev / sandbox accounts ($500/mo, $5000/mo).
- **Soft alerts** on prod (no auto-cutoff; PAGE the owner).
- **Auto-suspend** sandbox accounts past limit unless extended.

This works because dev/sandbox is where most "I'll clean it up
later" leakage happens.

## Per-customer chargeback (SaaS internal use)

Some orgs need cost-per-customer for internal pricing:

- Customer tag on every resource.
- Multi-tenant resources allocated by usage (e.g., request count
  in app logs).
- Reported as a separate dimension alongside team allocation.

This is the foundation of `cost_modeling_unit_economics`.

## Tools

- **Native**: AWS Cost Categories + Cost Explorer; Azure Cost
  Management; GCP Billing.
- **Multi-cloud**: CloudHealth (now VMware), Apptio Cloudability,
  Anodot.
- **K8s**: Kubecost / OpenCost — per-namespace, per-pod allocation
  inside a shared cluster.
- **Lightweight**: CUR / Billing Export → BigQuery / Snowflake →
  dbt models → Looker / Metabase. DIY at $0/mo of tooling, ~10
  days of work.

## Cultural shift

Visibility alone doesn't drive change. Pair with:
- Cost reviews in team retrospectives.
- "Cost saved" as a quarterly metric the team can boast about.
- FinOps office hours: someone helps teams optimize.
- Public top-N spenders list (gentle social pressure).

A chargeback without cultural reinforcement becomes a finance
exercise teams ignore.

## Anti-patterns

- **Tagging "encouraged."** Won't get to 95% coverage.
- **Per-team chargeback without team-level autonomy.** Team
  can't control the costs they're charged for.
- **Allocation rules change every month.** Trust erodes.
- **Shared-service allocation done in a black box.** Teams
  resent it.
- **No FinOps support.** Teams paged on a bill they don't
  know how to reduce.
- **Showback-only forever.** Visibility without consequence
  becomes wallpaper.
- **Untagged resources auto-allocated proportionally without
  notice.** Teams get hit; can't act.

## Validation

- [ ] Tagging coverage > 95% of monthly spend.
- [ ] Per-team cost dashboard exists; refreshed daily.
- [ ] Monthly chargeback / showback statements delivered on time.
- [ ] Dispute process is documented; turnaround ≤ 5 business days.
- [ ] Shared-service allocation rule is public.
- [ ] Untagged spend % is trending down quarter-over-quarter.
- [ ] At least one optimization win per team last quarter
      sourced from a chargeback discussion.
