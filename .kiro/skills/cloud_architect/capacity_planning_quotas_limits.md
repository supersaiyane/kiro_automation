---
id: capacity_planning_quotas_limits
version: 1.0.0
owners: [cloud_architect, sre, devops_engineer]
tags: [capacity, quotas, limits, forecasting, scaling, headroom]
when_to_use: |
  Going to production, OR a launch with traffic forecast, OR after
  any cloud-quota-shaped outage. Cloud accounts have HARD ceilings;
  service quotas can take days to raise. Plan capacity BEFORE the
  outage that proves you didn't.
inputs:
  - traffic_forecast, current_utilization, service_quotas
outputs:
  - "capacity_plan: per-service forecast + quota requests + scaling shape + breaker"
---

# Capacity Planning — Cloud Has Hard Ceilings

> Cloud feels infinite until the AWS account hits a regional EC2
> instance quota at 14:32 during a launch and no new instances
> can spin up. Hard ceilings exist; treat them as engineering
> constraints, not vendor problems.

## What "capacity planning" really means

```
Traffic forecast → Resource demand → Quota check → Reservation/spot
                            ↓
                       Scaling shape (HPA / ASG / cluster autoscaler)
                            ↓
                   Headroom + breakage modeling
```

Output is a per-service spreadsheet of: today's usage, 30-day,
6-month, 12-month, 36-month projected, against current limits.

## Service quotas are sneaky

Every cloud has 1000+ quotas. Defaults are CONSERVATIVE. Examples:

| Cloud | Quota | Default | Real prod need |
|---|---|---|---|
| AWS | EC2 vCPU per region (on-demand) | 5 | 1000+ |
| AWS | S3 buckets per account | 100 | usually fine; spans rare |
| AWS | EBS volume IOPS | varies | size for hot DBs |
| AWS | Lambda concurrent executions | 1000 | bursty workloads need more |
| Azure | VM cores per region | 10 | 100+ |
| Azure | Storage accounts per subscription | 250 | OK |
| GCP | GCE CPUs per region | 24 | 500+ |
| GCP | GKE node pool size | 1000 | OK |

Some quotas raise instantly via API; some take 1-3 business
days; some require a ticket + justification.

**KNOW which is which before launch day.**

## The quota inventory

For every cloud account in scope:
1. Pull current quota usage AND limit via API:
   - AWS: `aws service-quotas list-service-quotas`
   - Azure: `az network list-usages`, `az vm list-usage`
   - GCP: `gcloud compute project-info describe`
2. Identify the top 20 most-constrained quotas (utilization > 50%).
3. File raise requests for any > 70%.
4. Document the raised limit in the architecture doc.

## Forecasting demand

Three forecasting models, each useful at different horizons:

### 1. Linear (trend-based)
Past 90-day growth, project forward.
- Easy.
- Bad at inflection points (launches, viral events).

### 2. Workload-driven
"At N customers, each consuming M req/day, we need K cores."
Derive from unit economics.
- Most defensible.
- Requires accurate unit model.

### 3. Scenario / stress
"What if Black Friday brings 10x traffic? What's the choke point?"
- Use for capacity headroom.
- Drives quota-raise priority.

Run all three for production-tier services.

## Headroom budget

After current usage, plan for:
- **Auto-scaling buffer**: 20-30% headroom for normal spikes.
- **Quarterly growth**: extrapolated demand.
- **Launch contingency**: 2-3x normal for known launches.
- **Failure contingency**: enough capacity to lose 1 AZ without
  degrading SLO (the "N-1" principle).

Total: typical prod runs at 50-70% utilization on average to
absorb spikes.

## Scaling primitives

### Horizontal Pod Autoscaler (K8s)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 4
  maxReplicas: 50
  metrics:
    - type: Resource
      resource: { name: cpu, target: { type: Utilization, averageUtilization: 65 } }
    - type: External
      external: { metric: { name: queue_length }, target: { type: Value, value: "30" } }
```

Tune: targets 65-75% (not 90%; spike absorption); cool-down
prevents flapping.

### Cluster autoscaler (nodes)
Karpenter (AWS) / GKE Autopilot / AKS Node Auto-Provisioning.
Adds nodes when pods can't schedule; right-sizes by pod request.

### ASG (VM-based)
- Scale on CPU + custom metrics (SQS depth, ALB requests).
- Predictive scaling for cyclic workloads (daily peaks).

## Database capacity is special

DBs DON'T auto-scale linearly:
- Vertical (instance class up) → minutes to apply + restart.
- Horizontal (read replicas) → faster but only helps reads.
- Sharding → MAJOR project.

Plan DB capacity 6-12 months ahead. Provision for the next
breakpoint, not today.

Aurora Serverless v2 / Azure SQL Serverless / Cloud SQL helps
for variable workloads — pay for actual usage, scale ~seconds.

## Comparing resources across clouds

Engineering teams often ask "AWS vs Azure vs GCP for this
workload." Comparison framework:

| Dimension | What to measure |
|---|---|
| Compute baseline | $/vCPU-hour at common instance shape |
| Storage | $/GB-month at standard tier |
| Egress | $/GB out (often the differentiator) |
| Managed service capability | Does the equivalent exist? |
| Latency to user base | Network test from sample regions |
| Quota generosity | How easy to scale? |
| Free tier / startup credits | First year cost |
| Compliance scope | Region count covering target jurisdictions |

Build a quick spreadsheet per workload class. Surprising winners
emerge per workload (AWS for breadth, GCP for ML/data, Azure for
MS-shop integration).

## Capacity "hits" — what they look like

Real outages from capacity:
- "We can't launch more EC2 in us-east-1 / availability zone B."
  Quota or AZ exhaustion. Mitigation: multi-AZ, multi-region.
- "Lambda concurrent execution at ceiling; requests throttled."
  Mitigation: provisioned concurrency, request quota raise.
- "RDS storage IOPS exhausted; queries queue."
  Mitigation: upgrade to provisioned IOPS or io2; scale up.
- "NAT Gateway bandwidth at limit." Mitigation: NAT Gateway
  per AZ; VPC endpoints reduce NAT load.

Each has a runbook step. Document.

## Reserved capacity vs spot for capacity planning

- **Reserved / Savings Plans**: guarantee CAPACITY in addition to
  discount. AWS Capacity Reservations (separate product) reserve
  specific instance shapes.
- **Spot**: variable; cheap but interruptible.
- **On-demand**: most expensive; always available IF quota allows.

For HIGH-RELIABILITY capacity (no spot tolerance), Reserved or
Capacity Reservation. Otherwise spot fills the variable need.

## Capacity test before launch

A load test (see `qa/load_testing_methodology`) at 3-5x peak
forecast. Watch:
- Where does the system break? (DB, queue, network, app tier)
- Did auto-scaling kick in in time? (Lag matters.)
- Did any quota get hit?
- What's the cost per minute at peak?

This is the only way to KNOW capacity. Forecasts lie; load
tests don't (mostly).

## Anti-patterns

- **"Cloud is infinite."** It isn't. Hard quotas exist.
- **Quotas raised after the incident.** Pre-raise during a
  drill cycle.
- **Auto-scale target = 90%.** No room for spike.
- **No N-1 capacity.** AZ outage = full degradation.
- **DB capacity an afterthought.** Costs 10x more to fix at peak.
- **No load test before launch.** Discover limits live with users.
- **Cross-region or cross-cloud "infinite scale" claims.** Each
  region has its own quotas.

## Validation

- [ ] Quota usage tracked per service; alerts at > 70%.
- [ ] Production runs at < 70% steady-state utilization.
- [ ] Last load test was within 90 days at ≥ 3x peak.
- [ ] N-1 capacity verified (can lose 1 AZ).
- [ ] DB capacity plan exists for next 12 months.
- [ ] Capacity reservation / commitment matches baseline.
- [ ] Cross-cloud capacity comparison documented for at least 1
      class of workload.
