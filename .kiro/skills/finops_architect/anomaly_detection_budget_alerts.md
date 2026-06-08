---
id: anomaly_detection_budget_alerts
version: 1.0.0
owners: [finops_architect, devops_engineer, sre]
tags: [anomaly-detection, budgets, alerts, cost-spike, finops]
when_to_use: |
  Any cloud account in production. The "bill grew 4x and nobody
  noticed until the invoice arrived" failure mode is preventable
  with budgets and anomaly detection. Set them up before the
  first incident.
inputs:
  - team_budgets, services_in_use, paging_routing
outputs:
  - "alert_topology: budget alerts + anomaly thresholds + escalation + actions"
---

# Cost Anomaly Detection + Budget Alerts

> A 30-day delay in noticing a cost spike is a 30-day expensive
> bug. Alerting on cost works the same as alerting on latency:
> baseline, threshold, page when crossed.

## The two alert types

### Budget alerts (threshold)
- Pre-set monthly cap per team / account / service.
- Fire at 50% / 80% / 100% of cap with escalating severity.
- Action: notify owner; at 100%, optionally restrict actions.

### Anomaly alerts (deviation)
- Statistical: spend deviates > N std-dev from baseline.
- Action: same notify chain, but caught EARLIER than a budget
  would trigger.

Both are needed; they catch different failure shapes.

## Budget alert design

```
account: prod-payments
budget: $50,000 / month
alerts:
  - threshold: 50%   → email team lead + finops
  - threshold: 80%   → slack #cost-payments + page lead
  - threshold: 100%  → page on-call + finops + restrict create-resource
  - threshold: 120%  → exec escalation
```

Tooling:
- **AWS Budgets** (per account, OU, tag).
- **Azure Cost Management** budgets.
- **GCP Billing budgets**.

Multi-cloud: roll up via a single dashboard / tool (Vantage,
CloudHealth, native data warehouse).

## Anomaly detection — what counts as anomalous

Catch spend that deviates without crossing a threshold:

- 24-hour rolling spend > 1.5x 7-day baseline → notify.
- Single service category jumps > 20% WoW → notify.
- New unusual service appearing in bill (e.g., suddenly $5k of
  SageMaker on a non-ML team) → notify.
- Region with no prior spend now spending > $100 → notify.

Tooling:
- **AWS Cost Anomaly Detection** (managed, free).
- **Azure Cost Management anomaly detection**.
- **GCP Recommender** (limited anomaly).
- **Third-party**: Anodot, Vantage, CloudZero — usually deeper
  ML-based detection.

## What triggers cost spikes (common patterns)

1. **Forgotten resource** — engineer leaves a GPU instance
   running over the weekend.
2. **Misconfiguration** — `EVERYTHING_LOGGED=true` in prod
   blows S3 storage.
3. **DDoS / abuse** — high egress, high requests.
4. **Runaway loop** — a Lambda or app retry storm.
5. **Promotion** — viral launch, real but unexpected.
6. **Refactor side effect** — new caching layer doesn't cache.
7. **Data pipeline failure** — failed job retries 10000 times.
8. **Vendor price change** — rare but real.

Each has a different RESPONSE. Anomaly alert should be loud
enough to investigate within hours.

## Escalation routing

Layered:

```
spike < 5x baseline    → Slack channel
spike 5-20x baseline   → Slack + PagerDuty
spike > 20x baseline   → P0 page (executive notification)
```

For each level, the runbook lists:
- What to check first (recent deploys, alerts, dashboards).
- Who has the authority to throttle / shut down.
- The communication template.

## Auto-mitigations (carefully)

For dev / sandbox:
- **Hard ceiling** on monthly spend. At 100%, AWS Budgets +
  Lambda can disable resource creation, stop instances, etc.
- Auto-resume requires explicit human approval.

For prod:
- **Never auto-throttle prod from cost alerts** unless absolutely
  safe. Falsely triggering = self-inflicted outage.
- Auto-mitigations only on isolated, known-noisy line items
  (e.g., "if NAT egress > $X today, page; don't auto-block").

## False positive management

Cost anomaly alerts have higher false positive rates than perf
alerts because:
- Spend is bursty (batch jobs, periodic reports).
- New features WILL look anomalous on day 1.
- Marketing campaigns spike traffic legitimately.

Mitigate:
- Per-service baselines, not org-wide.
- Whitelist "expected" anomalies (a known batch job).
- Tag-based context: an anomaly in a "campaign-launch" tagged
  account is expected.

Tune the threshold UP if FPs flood. The signal that matters is
the 10x weekly drift, not the 1.5x normal.

## Per-service baselines

Different services have different volatility. EC2 baseline is
stable; Lambda is bursty.

```
Service        | Baseline volatility | Anomaly trigger
EC2 / VM       | Low (±5% normal)    | > 25% deviation
S3 storage     | Slow growth         | > 50% week-over-week
NAT egress     | Moderate (±20%)     | > 100% deviation
Lambda         | Bursty (±50%)       | > 200% deviation
BigQuery / Athena | Highly variable  | > 500% deviation
```

Tune per service or rely on managed anomaly detection (already
calibrated).

## Weekly cost review meeting

15-min standing meeting:
- Per-team budget status (red / yellow / green).
- Top 3 spend drivers WoW.
- Anomalies resolved last week (root cause + action).
- Anomalies still open.

This + alerts replace the surprise quarterly bill.

## Anti-patterns

- **One budget for the whole org.** Single point of accountability
  failure.
- **Alerts that page everyone.** Notification fatigue → ignored.
- **Threshold-only, no anomaly.** Caught when the monthly cap is
  blown — by then the spike has run 20 days.
- **Anomaly thresholds set to default and never tuned.** Either
  too noisy or too quiet.
- **Cost alerts only see the FinOps team.** Engineering must be
  in the loop.
- **No defined response to a spike.** Alert fires; nobody knows
  what to do.
- **Hard cutoff on prod from a cost alert.** Self-DOS.

## Validation

- [ ] Every prod account has at least 3 budget alerts (50%, 80%,
      100%).
- [ ] Anomaly detection is enabled and tuned (FP rate < 1/wk).
- [ ] Last anomaly was caught in < 24 hours of start.
- [ ] On-call rotation includes a finops escalation tier.
- [ ] Weekly cost review attended by engineering leads.
- [ ] Auto-mitigations are scoped to dev / sandbox only.
- [ ] Per-service baselines reviewed quarterly.
