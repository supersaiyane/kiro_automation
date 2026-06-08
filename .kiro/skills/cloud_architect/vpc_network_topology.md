---
id: vpc_network_topology
version: 1.0.0
owners: [cloud_architect, security_engineer, sre]
tags: [vpc, network, transit-gateway, privatelink, hub-and-spoke, cidr]
when_to_use: |
  Designing or refactoring cloud network. VPC/VNet/Project-network
  decisions cascade for years — CIDR ranges, peering reachability,
  egress paths. Bad choices early force expensive rework when you
  need to connect a 4th, 5th, 10th VPC.
inputs:
  - account_count, on_prem_connectivity, security_zones
outputs:
  - "network_design: CIDR plan + hub-spoke + egress + DNS + diagram"
---

# VPC / VNet Network Topology

> Cloud networking is software-defined, but the design constraints
> are still physics-shaped. CIDR planning, hub-and-spoke topology,
> and consistent egress patterns make the difference between "we
> can connect anything to anything" and "we built a maze."

## CIDR planning — non-overlapping, hierarchical

Allocate the org's IP space in tiers:

```
Org-wide: 10.0.0.0/8

Region buckets:
  10.0.0.0/12    → us-east-1
  10.16.0.0/12   → us-west-2
  10.32.0.0/12   → eu-west-1

Per-region environment buckets:
  10.0.0.0/14    → us-east-1 prod
  10.4.0.0/14    → us-east-1 staging
  10.8.0.0/14    → us-east-1 dev

Per-account VPCs:
  10.0.0.0/16    → us-east-1 prod-account-A
  10.1.0.0/16    → us-east-1 prod-account-B
  ...
```

Rules:
- **No overlap.** Ever. Peering / Transit Gateway requires
  unique CIDRs.
- **Per-region buckets** survive expansion.
- **Reserved space** for on-prem (RFC 1918 segments your network
  team owns) outside the cloud space.
- **IPAM tool** (AWS IPAM, Azure IPAM, custom) tracks allocations.

CIDR exhaustion is a quiet killer. /16 sounds large until you have
20 microservices × 3 AZs × 4 subnets each.

## Subnet design within a VPC

```
VPC: 10.0.0.0/16

Public subnets   (one per AZ):
  10.0.0.0/24    → public-az-a   (NAT, ALB ingress)
  10.0.1.0/24    → public-az-b
  10.0.2.0/24    → public-az-c

Private subnets  (one per AZ):
  10.0.16.0/20   → private-az-a   (4096 IPs)
  10.0.32.0/20   → private-az-b
  10.0.48.0/20   → private-az-c

Data subnets     (RDS, ElastiCache — locked down):
  10.0.64.0/24   → data-az-a
  10.0.65.0/24   → data-az-b
  10.0.66.0/24   → data-az-c
```

Tiers: PUBLIC, PRIVATE, DATA. Each tier in 3+ AZs. The DATA tier
has NO route to internet (not even via NAT).

## Hub-and-spoke topology

```
                  [ Network Account ]
                  Transit Gateway hub
                /        |        \
       [ prod-A ]  [ prod-B ]  [ shared-svc ]
                       │
                  [ on-prem VPN / DX ]
```

- All workload VPCs connect to the hub.
- Hub policy controls who reaches whom (TGW route tables).
- ZERO direct VPC-to-VPC peering (full-mesh peering explodes
  combinatorially).

Equivalents:
- AWS: Transit Gateway.
- Azure: Virtual WAN.
- GCP: Network Connectivity Center.

For < 3 VPCs total, peering is fine. Above that, hub it.

## Egress strategy

The egress problem: every outbound connection costs money and
introduces an attack surface.

Patterns:
- **NAT Gateway per AZ** — straightforward, $$ at scale.
- **Centralized egress VPC** — all egress flows through the
  network account's NAT (cheaper per-byte after a point, easier
  to enforce traffic inspection).
- **Egress proxy** (Squid, Aviatrix, third-party FWaaS) —
  allowlist of destination domains, deep packet inspection.
- **VPC endpoints / Private Link** — for AWS-service-to-VPC
  traffic, no internet hop, no NAT cost.

Use PrivateLink / Service Endpoints for S3, DynamoDB, KMS,
Secrets Manager. These are free OR much cheaper than NAT, AND
data never leaves the cloud's private backbone.

## Security groups vs NACLs

- **Security Groups (stateful)**: the primary control. Per
  workload. Allow-only.
- **NACLs (stateless)**: subnet-level, allow + deny. Use sparingly
  — for known-bad block lists or compliance scoping.

Patterns:
- Most workloads need only SGs.
- NACLs to enforce env boundaries (DATA tier can't talk to
  internet, period).
- Both: belt + suspenders.

## DNS architecture

Cloud DNS is its own complex topic:

- **Private hosted zones / Private DNS Zones**: internal-only
  records.
- **DNS Resolver** in the hub VPC; all spoke VPCs forward there.
- **On-prem resolution**: Resolver endpoints federate to on-prem
  DNS.
- **Public DNS** managed separately (Route 53 public zones,
  Cloudflare).

Bad DNS topology = "I can't reach service X from VPC Y" → hours
of debugging.

## Service mesh — when network policy isn't enough

Cloud network controls = layer 3-4 (IP, port).
Service mesh = layer 7 (HTTP, gRPC, mTLS).

Use a service mesh (Istio, Linkerd, AWS App Mesh, Consul) when:
- mTLS between services is a requirement.
- You need fine-grained routing (canary, traffic mirror).
- Service-to-service authz beyond "can reach the IP."

Without zero-trust requirements, you don't need a mesh. Don't
adopt one for fashion.

## Cross-region networking

- **Region pairs** connected via cross-region peering (TGW peering,
  Global VNet peering).
- **Latency budget** documented per service.
- **Egress between regions** is expensive (cross-region transfer);
  prefer in-region where possible.
- **Failover routing** via Route 53 / Traffic Manager — see
  `multi_region_strategy`.

## Compliance + traffic logs

- **VPC Flow Logs / NSG Flow Logs**: ALL VPCs, ALL traffic, to the
  log-archive account.
- **Sampled or full** per env (full in prod, sampled in dev).
- **Retention**: per compliance window.
- **GuardDuty / Defender for Cloud / SCC** consume the flow logs
  for threat detection.

Without flow logs, you can't answer "did the attacker exfiltrate?"
during an IR.

## Anti-patterns

- **Same CIDR across regions / accounts.** Future peering
  blocked. Plan unique from day one.
- **Single AZ.** AZ outage = total downtime.
- **Public subnets used for application servers.** Use ALB in
  public, app in private.
- **NACLs as primary access control.** Stateless = pain.
- **VPC peering at > 5 VPCs.** Full-mesh maintenance burden.
- **No flow logs.** Blind in IR.
- **Default security group used.** Allow-all rules; remove or
  empty it.
- **NAT Gateway in only one AZ.** AZ failure → no egress.

## Validation

- [ ] CIDR allocations follow a documented org-wide plan; no
      overlaps.
- [ ] Every prod VPC spans 3 AZs.
- [ ] Data tier subnets have NO route to internet.
- [ ] Hub-and-spoke topology in use for > 3 VPCs.
- [ ] VPC Flow Logs / NSG Flow Logs flow to log-archive.
- [ ] Private Endpoints used for cloud-internal traffic.
- [ ] Security groups follow least-privilege; default SG empty.
- [ ] DNS topology documented; on-prem + cloud resolve each other.
