---
id: cross_cloud_multicloud_setup
version: 1.0.0
owners: [cloud_architect, devops_engineer, security_engineer]
tags: [multi-cloud, hybrid-cloud, dora, vendor-lock-in, exit-plan]
when_to_use: |
  You need to: (a) survive a vendor outage, (b) avoid lock-in
  for procurement leverage, (c) meet a regulatory mandate (DORA
  for EU financial services), or (d) absorb an acquisition on
  another cloud. Multi-cloud is a tax; pay it deliberately.
inputs:
  - drivers, current_cloud, target_clouds
outputs:
  - "multicloud_strategy: pattern + workload allocation + interconnect + cost + exit plan"
---

# Cross-Cloud / Multi-Cloud Setup

> "Multi-cloud because it sounds resilient" is the most expensive
> reason. Real drivers — regulatory mandate, vendor concentration
> risk, M&A inheritance — justify the tax. Pick a pattern and own
> the operational overhead.

## The four patterns (Gartner taxonomy, refined)

### 1. Multi-cloud (true)
Workloads run on multiple clouds, often the same workload across
clouds.
- Cost: HIGHEST. 30-50% overhead in tooling, expertise, data
  transfer.
- Use: regulatory (DORA), high-fault-tolerance, M&A inheritance.

### 2. Cloud-agnostic
Workloads CAN run on multiple clouds (containerized, Kubernetes,
open-source DB), but live on ONE. Insurance, not active spread.
- Cost: ~10-15% overhead from avoiding cloud-native shortcuts.
- Use: optionality, exit-plan readiness.

### 3. Polycloud (best-of-breed)
Different workloads on different clouds, by fit.
- ML on GCP (Vertex), CRM on Azure (Dynamics), commerce on AWS.
- Cost: moderate; each cloud is a separate ops domain.
- Use: when one cloud is clearly best for one workload class.

### 4. Hybrid (cloud + on-prem)
On-prem + cloud, integrated. Most enterprises that aren't
cloud-native.
- Cost: extends existing on-prem ops to cloud.
- Use: regulated data on-prem; bursty compute in cloud.

Pick ONE pattern; the operational shape is different for each.

## When NOT to go multi-cloud

- "For resilience" — most cloud outages are regional, not vendor-
  wide. Multi-region in one cloud is cheaper + simpler.
- "For DR" — cross-region in one cloud usually covers it.
- "For cost arbitrage" — labor + data transfer eats the savings.

Multi-cloud's REAL cases:
- Regulatory: DORA, sovereignty, prohibitions on a specific
  vendor.
- Vendor risk: > 30% spend concentration creates negotiation
  weakness AND single-vendor failure mode.
- Acquisition inheritance: portfolio company on AWS, you're on
  Azure.
- Customer requirement: customer dictates which cloud (common
  in BFSI / Gov).

## Interconnect — the physical layer

```
[ AWS VPC ] ──direct connect──► [ Customer router ]
                                       │
[ Azure VNet ] ──ExpressRoute──► [ Customer router ]
                                       │
[ GCP VPC ] ──Cloud Interconnect──► [ Customer router ]
                                       │
                              [ On-prem core ]
```

Real interconnect options:
- **Direct private connections** (AWS Direct Connect, Azure
  ExpressRoute, GCP Cloud Interconnect). Sub-10ms latency to
  on-prem; bypasses internet.
- **Megaport / Equinix Fabric / PacketFabric**: marketplace for
  cross-cloud private connections. Pay per port-hour + GB
  transferred.
- **Cloud-native cross-cloud**:
  - AWS-Azure: Azure ExpressRoute Global Reach.
  - GCP-AWS: Partner Interconnect via Megaport.
  - No native cross-cloud private peering between AWS-GCP
    without a partner / DIY VPN mesh.

The interconnect IS where many multi-cloud projects die. Budget
$5k-$50k/mo per interconnect.

## Identity federation

A single source of truth for humans + workloads:
- Central IdP: Okta / Azure AD / Google Workspace / Ping.
- SSO into ALL clouds via SAML / OIDC.
- Workload identity: SPIFFE / SPIRE for cross-cloud workload
  identity, or rely on each cloud's native (with explicit
  trust between them).

Without federation, you have N identity systems and N rotations.

## Data layer cross-cloud

The hardest part. Options:

### A. Single source of truth in one cloud, replicas in others.
- Database in AWS RDS.
- Cross-cloud read replicas via app-level replication.
- Writes always to one cloud.
- Pros: simple consistency.
- Cons: write region failure = downtime; egress costs.

### B. Multi-master across clouds (rare).
- CockroachDB / Spanner-equivalent / Cassandra multi-DC.
- Workload sees a single logical DB; the DB handles cross-cloud
  replication.
- Cost + complexity HIGH.

### C. Per-region tenancy.
- EU customers on Azure EU, US on AWS US, etc.
- No cross-cloud sync; tenants don't move.
- Cleanest pattern for regulated data residency.

## Tooling — the abstraction tax

Multi-cloud needs:
- IaC that targets all (Terraform / OpenTofu, Pulumi).
- K8s as the runtime substrate (EKS / AKS / GKE — same K8s API).
- Observability that aggregates all (Datadog, Grafana Cloud,
  Dynatrace).
- Cost tooling that spans all (Vantage, CloudHealth, FinOps
  Foundation's FOCUS standard).
- Cross-cloud service mesh (Istio, Linkerd, Consul mesh).

These tools EXIST. They're not free. Expect $50k-$500k/yr in
tooling alone at scale.

## DORA-driven multi-cloud (EU financial services)

DORA (Digital Operational Resilience Act, effective 2025) requires:
- ICT third-party risk register.
- Concentration risk monitoring (one vendor < 30% of critical
  operations).
- Exit plans for every critical third party.
- Cross-cloud / vendor-portable design for critical functions.

Pragmatic interpretation: be ABLE to move a critical workload
within N months. Doesn't mean ACTIVE in two clouds; means tested
and capable.

## Cost reality

| Item | Single-cloud | Multi-cloud delta |
|---|---|---|
| Compute | Baseline | +10% (different pricing per cloud) |
| Storage | Baseline | +20% (data copies) |
| Data transfer | Low (in-cloud) | HIGH (cross-cloud) |
| Tooling | Native ($) | Cross-cloud ($$$) |
| Headcount | N | N × 1.4 (per-cloud expertise) |
| Total | 1x | 1.3-1.5x |

The cost is real. Bake it into the ROI when proposing multi-cloud.

## Exit plan — required for SOC 2, DORA, common sense

For every cloud:
- Inventory of dependencies (services, IDs, configs).
- IaC-driven recreate to "rebuild in N weeks."
- Data export format (open standard: Parquet, Postgres dump).
- Tested annual drill.

Without this, your "cloud-agnostic" claim is marketing.

## Anti-patterns

- **Multi-cloud "for resilience" without sizing the cost.**
  Often a multi-region single-cloud is cheaper + equivalent.
- **Same workload split-deployed across clouds.** Operational
  hell; expertise gaps.
- **Cross-cloud database replication on every write.** Latency +
  cost.
- **No central IAM.** N identity domains; auditors love it
  (sarcasm).
- **Per-cloud team silos.** Each team optimizes locally; no
  consistency.
- **Multi-cloud without IaC.** Drift between clouds is
  permanent.

## Validation

- [ ] Multi-cloud driver is named and defensible (not "for
      resilience").
- [ ] Pattern is explicit: true MC / cloud-agnostic / polycloud
      / hybrid.
- [ ] Interconnect cost is in the budget.
- [ ] Identity federation is in place.
- [ ] Per-cloud workload allocation is documented.
- [ ] Exit plan exists per cloud + tested in last 12 months.
- [ ] Vendor concentration < 30% if DORA scope.
