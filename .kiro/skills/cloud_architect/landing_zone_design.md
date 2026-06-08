---
id: landing_zone_design
version: 1.0.0
owners: [cloud_architect, security_engineer, devops_engineer]
tags: [landing-zone, multi-account, org-policy, scp, blast-radius]
when_to_use: |
  Any cloud account/subscription beyond a single dev sandbox. A
  landing zone is the structural skeleton you wish you'd built on
  day one — account boundaries, baseline policies, network topology,
  identity foundation. Retrofitting it costs months; building it
  first costs weeks.
inputs:
  - org_size, compliance_scope, target_cloud
outputs:
  - "landing_zone: account hierarchy + baseline policies + identity wiring + diagram"
---

# Landing Zone — Multi-Account By Default

> One AWS account / Azure subscription / GCP project for "everything"
> is the first scaling failure of cloud. Production deploys to the
> same place as a dev sandbox, blast radius is the whole org, the
> bill is unowned. Build the landing zone before the second team
> shows up.

## Account hierarchy (AWS Organizations / Azure Mgmt Groups / GCP Folders)

```
Root / Org
├── Security OU
│   ├── log-archive    (write-only audit logs from EVERY account)
│   └── audit          (read-only access for compliance team)
├── Infrastructure OU
│   ├── shared-services    (DNS, transit gateway, central monitoring)
│   └── network            (Transit Gateway hubs, IPAM)
├── Workloads OU
│   ├── prod
│   │   ├── prod-payments
│   │   ├── prod-api
│   │   └── prod-data
│   ├── staging
│   │   └── staging-all
│   └── dev
│       ├── dev-sandbox-alice
│       └── dev-sandbox-bob
└── Suspended OU         (deactivated accounts pre-deletion)
```

Account per environment per workload at minimum. Blast radius is
the account.

## Org-level guardrails

AWS: **Service Control Policies (SCPs)**.
Azure: **Azure Policy** at Management Group scope.
GCP: **Organization Policies**.

These DENY actions org-wide, irrespective of IAM. Examples:

```json
// Deny disabling CloudTrail / Activity Log
// Deny creating IAM users with console + no MFA
// Deny public S3 buckets / blob containers
// Deny regions outside [us-east-1, eu-west-1] (data residency)
// Deny use of unapproved instance types
// Deny stopping security tools (GuardDuty, Defender)
```

Apply at OU root → inherited by every account below. Cannot be
removed by the account owner.

## Identity foundation

- **Central IdP** (Okta, Azure AD, Google Workspace) is the
  source of truth for humans.
- **SSO / OIDC federation** into cloud — no long-lived IAM users
  for humans.
- **Permission Sets** (AWS Identity Center) / **Conditional Access
  policies** (Azure) — role-based access by group.
- **Break-glass account** — emergency-only, hardware MFA,
  PagerDuty-style activation logged separately.
- **CI/CD** uses OIDC trust (GitHub Actions → AWS, Azure DevOps →
  Azure). No long-lived secrets.

For machine identities:
- AWS: IAM Roles for Service Accounts (IRSA) on EKS, role-based
  access.
- Azure: Managed Identities.
- GCP: Workload Identity.

NEVER ship a long-lived access key to a workload. Ever.

## Network topology

```
              [ TGW / Hub VPC ]
             /        |        \
       [ prod-A ]  [ prod-B ]  [ staging ]
                       │
                  [ on-prem VPN ]
```

- **Transit Gateway / Virtual WAN / Network Connectivity Center**
  hub for any > 3 accounts.
- **Hub-and-spoke** topology; spokes don't peer directly.
- **Egress NAT** in a dedicated subnet per AZ.
- **DNS** centralized in shared-services account, resolved across
  the org via Route 53 Resolver / Private DNS Zones.
- **IPAM** to allocate non-overlapping CIDRs (you WILL want VPC
  peering eventually; overlapping ranges block that).

## Logging + audit centralization

The `log-archive` account is the most important account in the org:

- ALL CloudTrail / Activity Log / Audit Log streams write here.
- ONLY APPEND access from source accounts.
- ONLY READ access from `audit` account / compliance team.
- Retention per compliance window (7+ years typical).
- Object-Lock / immutable storage enabled.

Even if a workload account is compromised, the attacker can't
delete the audit trail.

## Cost + chargeback

- **Tagging policy** enforced by Org Policy / Azure Policy:
  `env`, `owner`, `cost-center`, `application` required on every
  resource.
- **Account-level cost** (root account aggregates) → chargeback
  per OU / per team.
- **Budgets + anomaly detection** per account.

## Account vending — automation

Manually creating + bootstrapping a new account is hours. Use:
- AWS Control Tower / Account Factory.
- Azure Landing Zones (CAF + Bicep / Terraform).
- GCP Cloud Foundation Toolkit.

These vend a NEW account already wired with: SCPs applied,
default VPC, baseline IAM, logging to log-archive.

A request like "I need a new account for project X" should be a
ticket that auto-fulfils within 30 minutes, not a week.

## Compliance bake-in

For SOC 2 / ISO 27001 / HIPAA / PCI:
- Specific OU under "Compliance" with stricter policies
  (forced encryption, stricter SCPs, mandatory tags).
- Workloads in scope go there; out-of-scope stay separate.
- Reduces audit scope to ONE OU.

## Anti-patterns

- **One mega-account.** Blast radius = whole company.
- **Per-team account but no central audit.** Compromise + cover
  tracks impossible to detect.
- **SCPs disabled "for convenience."** Defeats the point.
- **Manual account creation.** Drift between accounts; some
  miss baseline policies.
- **Overlapping CIDRs.** You can't peer; you can't have
  Transit Gateway across them without NAT pain.
- **Long-lived IAM users for humans / CI.** Audit nightmare,
  rotation nightmare, leakage risk.
- **Tagging "encouraged" but not enforced.** Chargeback breaks
  on day one.

## Validation

- [ ] At least 3 environments (prod / staging / dev) are
      separate accounts.
- [ ] log-archive account exists, immutable, write-only from
      sources.
- [ ] Org-level guardrails block public storage + region drift
      + IAM user creation without MFA.
- [ ] SSO is the only path for humans; no console IAM users.
- [ ] CI/CD federates via OIDC; no long-lived keys.
- [ ] Tagging policy is enforced (not advisory).
- [ ] Account vending is automated and produces a
      ready-to-use account in < 30 min.
