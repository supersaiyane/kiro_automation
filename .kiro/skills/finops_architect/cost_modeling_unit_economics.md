---
id: cost_modeling_unit_economics
version: 1.0.0
owners: [finops_architect, cto, product_manager]
tags: [unit-economics, cost-per-customer, cogs, gross-margin, finops]
when_to_use: |
  Pricing a new product, raising a round, or any conversation
  with the CFO about "is this thing profitable?" Cloud unit cost
  is the bridge between engineering decisions and business model
  viability. Get it wrong and the company can grow revenue and
  shrink margin at the same time.
inputs:
  - workload_design, expected_volume, pricing_model
outputs:
  - "unit_economics: cost-per-customer + cost-per-request + gross-margin curve + breakeven"
---

# Cost Modeling + Unit Economics

> "Our cloud bill is $30K/mo" is finance noise. "Our cost per
> active customer is $4.20 and our ARPU is $19" is a business
> conversation. Build the second one before fundraising or
> repricing.

## The unit economics chain

```
Cloud bill ($) ÷ Active customers = COST PER CUSTOMER ($)
Cloud bill ($) ÷ Requests served  = COST PER REQUEST ($)

ARPU ($) − Cost per customer ($) − Other COGS ($) = GROSS MARGIN ($)
GROSS MARGIN / ARPU = GROSS MARGIN %

Time-to-recoup-CAC = CAC / (Monthly Gross Margin per customer)
```

Targets vary by industry: SaaS gross margin 70-80%, infra-heavy
SaaS 50-65%, marketplace 20-40%. Know yours.

## Build the model bottom-up

### Variable costs (scale with usage)
- Compute (per request or per GB-hour).
- Storage (per GB-month).
- Database (per IOPS, per GB).
- Egress (per GB out).
- Third-party SaaS (per API call, per seat).
- Per-tenant overhead (one DB schema, one S3 prefix).

### Fixed costs (baseline)
- Reserved capacity baseline.
- Observability tooling.
- Vendor contracts (licenses).
- Network hub costs (Transit Gateway hour rates).

### Allocated costs (split across customers)
- Engineering team salary (per customer).
- Support cost (per customer).
- Customer success.

```
Cost per customer = Fixed/N + Per-customer variable + Allocated/N
```

As N grows, fixed-per-customer shrinks. The curve is the unit
economics shape.

## Spreadsheet template (the skeleton)

```
                       Launch   M+6     Y+1     Y+3
Active customers       10       200     1000    10000
Requests / customer    100      500     1000    1500
─────────────────────────────────────────────────────
Compute               $X1     $X2     ...
Storage               ...
Database              ...
Egress                ...
Observability         ...
Per-cust overhead     ...
─────────────────────────────────────────────────────
TOTAL cloud bill      $T1     $T2     ...
Per-customer $        $T1/10  $T2/200 ...
Per-request $         $T1/10·100 ...
```

Update monthly with actuals; trend tells you whether you're
gaining leverage as you scale.

## Where unit cost actually comes from (the audit)

Bottom-up by service:

- **EC2 / Compute Engine / VMs**: hours × instance rate.
- **Lambda / Cloud Run / Functions**: invocations × duration × memory.
- **S3 / Blob / GCS**: GB stored + req/mo + egress.
- **RDS / Cloud SQL / Postgres**: instance hours + IOPS + storage.
- **DynamoDB / Cosmos**: RCU/WCU or per-million reads + storage.
- **CloudFront / CDN**: GB + per req.
- **NAT Gateway**: hours + GB processed (often surprising).

Tools: CUR (Cost & Usage Report), Azure Billing API, GCP Billing
Export to BigQuery. Pipe to a warehouse → unit cost dashboards.

## The cohort cost analysis

Two cohorts behave differently. Heavy users (top 10%) usually
cost 5-10x median. Plot:

```
              Cost per customer ($)
              ┌────────────────────────────────────
              │                            ●  (P99 customer)
              │                       ●
              │                  ●
              │           ●
              │     ●
              │ ●
              └────────────────────────────────────
                       Customer percentile
```

If your top decile costs > 5x ARPU, you have a pricing leak
(usage tier missing, or a customer abusing free tier).

## Pricing model alignment

Pricing should match the cost driver. Common mistakes:

- **Flat pricing on usage-based costs** → top users are
  unprofitable.
- **Per-seat pricing where cost is per-request** → high-traffic
  small teams cost more than they pay.
- **Per-API-call pricing where cost is per-CPU-second** → bursty
  workloads underpay.

Modern SaaS pricing: hybrid (base seat + usage above threshold).

## Reserved capacity math

The commitment question:

```
On-demand: $100/mo
Savings Plan 1y: $70/mo
Savings Plan 3y: $55/mo

Break-even point for 1y: never on-demand; pure savings.
Risk: workload disappears in 6 months → still paying $70/mo for 6 mo.
```

Commit 60-80% of stable baseline. Reserve headroom for growth /
refactor. Pay on-demand for the variable tier.

## The egress trap

Egress costs are sneaky. Examples:
- Cross-region replication: 100GB/day = $60/mo just for transfer.
- CDN miss → origin → user: pays origin egress.
- Multi-region active-active: every write replicated → 2x egress.

Always model egress separately. It's often 10-20% of bill.

## Cost forecast at growth tiers

```
1k customers:    $X / customer (baseline)
10k customers:   $X*0.6 / customer (fixed cost amortized)
100k customers:  $X*0.45 / customer (commit discounts)
1M customers:    $X*0.35 / customer (re-architecting wins)
```

If your model predicts cost-per-customer growing with scale,
the unit economics are upside down. Refactor before scaling.

## What the CFO wants to see

- Cost per customer (and trend).
- Gross margin %.
- Top 5 cost drivers + their levers.
- Commitment coverage + utilization.
- Anomaly response (when did the last cost spike happen, how
  was it caught + resolved).

Bring this to monthly business review; don't make finance dig
for it.

## Anti-patterns

- **"Cloud cost is a Cost of Goods sold problem; engineering
  ignores it."** It's an engineering input — design choices
  drive it.
- **No allocation per customer.** Can't compute unit economics
  without tagging.
- **Reactive optimization.** Bill grows; cuts in panic.
- **Ignoring the egress line item.** Then surprised by it.
- **Pricing model unrelated to cost driver.** Sales succeeds
  → margin collapses.
- **All-on-demand at scale.** Leaves 30-50% on the table.

## Validation

- [ ] Unit cost (per customer + per request) tracked monthly.
- [ ] Tagging maps cost to customer / cohort.
- [ ] Pricing model is aligned with cost drivers.
- [ ] Top 5 customers by cost reviewed quarterly.
- [ ] Forecast model exists for next 12-36 months.
- [ ] Egress is a tracked separately from compute / storage.
