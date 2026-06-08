---
id: security_review_drives
version: 1.0.0
owners: [cloud_architect, security_engineer, devops_engineer]
tags: [security-review, posture, csp, cspm, audit, drive]
when_to_use: |
  Pre-launch, pre-audit, post-incident, or a quarterly cadence.
  A "security drive" is a focused multi-day review of cloud
  posture across IAM, network, data, runtime, and supply chain.
  Distinct from a pentest (external attacker view); both are needed.
inputs:
  - target_environment, scope, time_box
outputs:
  - "drive_report: findings + severity + owners + remediation timeline"
---

# Cloud Security Review Drives

> A security review is a focused 1-2 week sweep, not a weekly
> meeting. Treat it like a tax audit: clear scope, time-box,
> evidence collection, findings register, remediation plan with
> owners. Done quarterly, it catches drift before regulators do.

## When to run a drive

- 30 days before launch of a new cloud workload.
- 60 days before a SOC 2 / ISO / HIPAA audit.
- After a security incident.
- Quarterly cadence for any production tier.
- After a major refactor (new region, new account, M&A integration).

## Drive scope — the 6 review domains

```
1. IDENTITY          — IAM, MFA, federated SSO, break-glass
2. NETWORK           — VPC, egress, segmentation, encryption in transit
3. DATA              — encryption at rest, classification, retention
4. RUNTIME           — workload hardening, secrets, container images
5. SUPPLY CHAIN      — SBOM, signing, dependency hygiene
6. DETECTION + IR    — logging, alerting, runbooks, drill cadence
```

Each domain has a checklist; findings are prioritized P0-P3.

## Tools (CSPM + native services)

**Cloud-native CSPM (free-ish, opinionated)**:
- AWS Security Hub + Config + GuardDuty + Macie + Inspector.
- Azure Defender for Cloud (Microsoft Cloud Security
  Posture Management).
- GCP Security Command Center Premium.

**Third-party CSPM (richer reporting)**:
- Wiz, Orca Security, Lacework, Prisma Cloud, Datadog Cloud
  Security, Sysdig Secure.

**Open-source**:
- Prowler (AWS + Azure + GCP).
- ScoutSuite (multi-cloud audit).
- CloudCustodian (policy-as-code).
- kube-bench (K8s CIS benchmark).

Default: native CSPM + Prowler for the drive (free, scriptable).

## Drive playbook — 5-day execution

### Day 1 — Scope + inventory
- Confirm accounts / subscriptions / projects in scope.
- Run automated inventory: every resource, every account, every
  region.
- Identify outliers (resources in unexpected regions, untagged
  resources).

### Day 2 — IDENTITY review
- Run CSPM IAM checks (publicly anonymous access, * permissions,
  long-lived keys, MFA exceptions).
- Pull IAM Access Analyzer findings.
- Review break-glass account activations in the last 90 days.
- Validate federation paths.

Findings register entries:
```
F-001  IAM user with access keys older than 90 days     P1
F-002  Role with Action:* AND Resource:* in prod        P0
F-003  Service account with no recent activity (suspect)P2
```

### Day 3 — NETWORK + DATA review
- Review every security group / NSG with 0.0.0.0/0.
- Check encryption-at-rest coverage (every S3, every RDS, every
  disk).
- Check encryption-in-transit (TLS versions, deprecated ciphers).
- VPC endpoint coverage for cloud-internal traffic.
- Egress paths: NAT, proxy, allowlist.

### Day 4 — RUNTIME + SUPPLY CHAIN
- Container image scan results (every prod image; CVE summary).
- Secrets in environment variables vs proper vault.
- K8s RBAC review (Cluster Admin roles, namespace boundaries).
- SBOM coverage (see `supply_chain_sbom_slsa`).
- Image signing + admission policy.

### Day 5 — DETECTION + IR
- CloudTrail / Activity Log / Audit Log in every region.
- Log retention meets policy.
- Alerting routes verified.
- Last 5 alerts: were they triaged in SLA?
- IR runbook reviewed against current org chart.

### Day 6 — Report + remediation plan
- Findings register sorted by severity.
- Owner assigned per P0/P1; target due dates.
- Risk-accepted findings explicitly recorded with sign-off.
- Executive summary delivered.

## Severity rubric

```
P0 (page now): exposes prod data, bypasses auth, or active
   exploit possible.
P1 (fix in 7 days): material control gap; would fail audit.
P2 (fix in 30 days): hardening; pattern improvement.
P3 (track, fix in 90 days): polish.
```

Every finding gets a CVE-like ID for tracking across drives.

## Pentest vs drive — they complement

| Pentest | Drive |
|---|---|
| External attacker view | Internal posture review |
| Black-box / gray-box | White-box / read all configs |
| Annual or semi-annual | Quarterly |
| Driven by red team / vendor | Driven by cloud / sec arch |
| Output: exploits + chain of impact | Output: posture gaps + control failures |

Pentests catch what posture misses (chains of weak controls).
Drives catch what pentests miss (compliant configs that drift).

## Continuous posture vs drive

Modern stacks run CSPM continuously: every config change is
evaluated. Drives are still useful because:
- CSPM has FALSE POSITIVES that need human filtering.
- CSPM doesn't reason ABOUT YOUR THREAT MODEL ("does this
  matter for our workload?").
- CSPM doesn't update the IR runbook or test the alert chain.

The drive is when you SIT WITH the tooling and reason about it.

## Drive deliverables (what auditors love)

- Executive summary (1 page).
- Findings register (table; sortable).
- Per-finding: owner + due + status.
- Trend: P0/P1 counts vs last quarter.
- Risk-accepted log.
- Photos / screenshots / config snapshots (evidence).
- The next drive scheduled.

If you can hand this to an auditor and they accept it, the
audit is half done.

## Anti-patterns

- **"We have CSPM, we're covered."** Tools don't replace
  reasoning.
- **Quarterly drives that produce 200 findings, of which 8 get
  fixed.** The backlog grows; everyone tunes out.
- **One-time pre-audit drive.** Drift returns within 60 days.
- **Findings without owners.** Nothing happens.
- **No risk-accepted log.** Findings sit "in progress" forever.
- **Drive done by external auditor only.** Internal team doesn't
  build the muscle.
- **Skipping the IR side.** Posture matters less if IR is broken.

## Validation

- [ ] Last security drive was within 90 days for production.
- [ ] P0 / P1 findings from last drive are closed or
      risk-accepted.
- [ ] CSPM tool deployed across all production accounts.
- [ ] Drive report archived; trend graph maintained.
- [ ] Cross-functional team (cloud + security + ops) participated.
- [ ] IR runbook updated based on drive findings.
