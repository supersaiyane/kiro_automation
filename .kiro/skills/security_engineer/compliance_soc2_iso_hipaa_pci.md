---
id: compliance_soc2_iso_hipaa_pci
version: 1.0.0
owners: [security_engineer, legal, cto]
tags: [compliance, soc2, iso-27001, hipaa, pci-dss, gdpr, fedramp, dora]
when_to_use: |
  Approaching a customer audit, signing a regulated-industry contract,
  or preparing for a certification. Compliance is the legal language
  for security controls — you'll need it to sell to enterprise + gov.
inputs:
  - target_frameworks, current_controls, scope_boundary
outputs:
  - "compliance_roadmap: gap analysis + control mapping + evidence plan + audit timeline"
---

# Compliance — SOC 2, ISO 27001, HIPAA, PCI-DSS, GDPR, FedRAMP, DORA

> Frameworks differ in name but rhyme in control. Master one well
> (usually SOC 2 Type II) and you've done 70% of the work for any
> other. The auditor cares about evidence, not vibes — design the
> evidence collection BEFORE you start the audit.

## The framework landscape

| Framework | Owner | Scope | Required for |
|---|---|---|---|
| **SOC 2 Type II** | AICPA | Trust services criteria | Enterprise B2B SaaS, baseline expectation |
| **ISO 27001** | ISO/IEC | Information security mgmt system (ISMS) | Global enterprise, EU preference |
| **ISO 27017/27018** | ISO/IEC | Cloud-specific extensions | Cloud providers, SaaS |
| **HIPAA / HITRUST** | HHS / HITRUST | US healthcare PHI | Healthcare buyers |
| **PCI-DSS v4** | PCI SSC | Payment card data | Anyone handling card data |
| **GDPR** | EU | Personal data | EU data subjects |
| **CCPA / state privacy** | US states | Consumer data | US consumers (CA, VA, CO, etc.) |
| **FedRAMP Moderate/High** | GSA | US federal cloud | US government contracts |
| **CMMC L2+** | DoD | US defense supply chain | DoD primes + subs |
| **DORA** | EU (effective 2025) | EU financial services ICT | EU banks + critical suppliers |
| **IRAP (AU), C5 (DE), ENS (ES)** | Various | National equivalents of FedRAMP | National-gov contracts |

## Common controls across frameworks (the 80%)

Master these and you're 70-80% there for any framework:

1. **Access control** — least privilege, MFA, deprovisioning.
2. **Encryption** — at rest + in transit + key management.
3. **Audit logging** — immutable, retention per framework window.
4. **Change management** — ticketed changes, approval, rollback plan.
5. **Vulnerability management** — scanning, patching SLO, exception tracking.
6. **Incident response** — runbook, drills, evidence retention.
7. **Backup + DR** — tested restore, RTO/RPO documented.
8. **Vendor management** — third-party risk register, contracts.
9. **Security training** — annual employee training, phishing drills.
10. **Risk assessment** — annual exercise, treatment plan.
11. **Asset management** — inventory of all in-scope assets.
12. **Physical security** — for self-hosted; cloud inherits from CSP.

## SOC 2 Type II — the default

Trust Services Criteria:
- **Security** (mandatory — common criteria).
- **Availability** (most SaaS opts in).
- **Processing integrity** (opt in for payments, ETL providers).
- **Confidentiality** (opt in for B2B handling customer data).
- **Privacy** (opt in for B2C).

Type II: requires evidence over a 6-12 month observation period.
Type I: point-in-time. (Type II is what enterprise buyers ask for.)

Timeline: ~12 months from start to first SOC 2 Type II report.
- Month 1-2: gap analysis, policy writing.
- Month 3-4: control implementation.
- Month 5: readiness assessment.
- Month 6-11: observation period.
- Month 12: audit fieldwork + report.

Cost: $30-100k for first audit. Subsequent annual: 50-70% of first.

## ISO 27001 — the global equivalent

Differs from SOC 2:
- ISO is a CERTIFICATION (yes/no); SOC 2 is a REPORT.
- ISO requires a documented Information Security Management System
  (ISMS) with Statement of Applicability.
- ISO 27002:2022 lists 93 controls in 4 themes (Organizational, People,
  Physical, Technological).

Use the same evidence as SOC 2 with re-labeling. Save 60-80% on audit
time when stacking.

## HIPAA — US healthcare

Pieces:
- **Privacy Rule** — when/how PHI is shared.
- **Security Rule** — administrative, physical, technical safeguards.
- **Breach Notification Rule** — notify HHS, affected individuals.
- **Omnibus Rule** — extends to Business Associates.

Critical for SaaS handling PHI:
- **Business Associate Agreement (BAA)** signed with every covered
  entity + every sub-processor.
- PHI encrypted at rest + in transit (Security Rule §164.312).
- Audit logs retained 6+ years.
- Workforce training + access review.

**HITRUST CSF** is the certification overlay — pre-mapped controls;
saves audit-prep time for HIPAA-regulated SaaS.

## PCI-DSS v4.0

Applies if you store, process, or transmit cardholder data. Tier:

| Level | Annual transactions | Validation |
|---|---|---|
| 1 | > 6M | External QSA audit |
| 2 | 1M-6M | SAQ + ASV scans |
| 3 | 20k-1M | SAQ + ASV scans |
| 4 | < 20k | SAQ |

12 requirements, 250+ sub-controls. The big move in v4 (effective 2025):
"customized approach" — define your own controls that meet objectives,
defensible to assessor.

**Scope-reduction is the key technique**: tokenize PAN, outsource to
PCI-compliant payment processor (Stripe, Adyen). If you NEVER see raw card
data, you're not in scope for the bulk of PCI.

## GDPR + state privacy laws

Both center on:
- Lawful basis for processing.
- Data subject rights (access, erasure, portability).
- 72-hour breach notification.
- DPIA for high-risk processing.
- Cross-border transfer mechanisms (SCC, BCR, adequacy).

Implementation:
- Privacy policy that's actually accurate.
- DSR flow automated (don't process manually at scale).
- DPO appointed where required (large-scale processing, public bodies).
- Data residency-compatible architecture.
- Cookie consent (CMP) for tracking.

## FedRAMP

For US federal cloud. Two paths:
- **JAB authorization** — Joint Authorization Board (3LoD: DHS, GSA, DoD).
- **Agency ATO** — single agency sponsors. Faster.

Moderate baseline: ~325 controls (NIST 800-53). High: ~425.

Cost: $1-5M. Year+. Done only when the federal pipeline justifies it.

**StateRAMP / TX-RAMP / AZ-RAMP** are state equivalents with lower bar.

## DORA — new EU mandate (2025)

Applies to financial entities + their critical ICT suppliers (cloud, SaaS).
Five pillars:
1. ICT risk management (annual + ad-hoc).
2. ICT incident reporting (major incident < 4h notification).
3. Resilience testing (pen tests, including TLPT for systemic firms).
4. Third-party risk (register, exit plans, oversight authority audits).
5. Information sharing (encouraged).

If you sell to EU banks: REQUIRED.

## Evidence collection — automate or fail

Manual evidence collection is unsustainable at scale. Tools:

- **Vanta / Drata / Secureframe** — compliance automation: connect to AWS,
  GitHub, Okta, MDM → continuous evidence collection. Pre-built control
  mappings. Required for fast SOC 2.
- **Hyperproof / OneTrust** — broader GRC, enterprise.
- **Compliance as Code** — Terraform modules that emit attestations,
  custom auditing scripts.

For a 30-person company: Vanta or Drata. For a 3000-person company: same +
a GRC team for the unique controls.

## Evidence types auditors want

| Control | Evidence |
|---|---|
| MFA enforced | Okta admin screenshot showing MFA policy + user list |
| Backups tested | Restore drill report with timestamp + verification |
| Access review | Quarterly attestation from managers, signed |
| Patching SLO | Ticket data showing Critical patched < 7d |
| Encryption | KMS key list + S3 bucket configuration screenshots |
| Code review | GitHub branch protection + PR audit log |
| IR drill | Tabletop exercise minutes + action items |
| Training | Completion records for annual training |

EVERY control needs concrete evidence. "We have a policy" doesn't count.

## Anti-patterns

- **Compliance ≠ security.** SOC 2 says you have controls; doesn't mean
  they're effective. Don't mistake the certificate for safety.
- **Annual scramble.** Last-minute audit prep = exhausted team + control
  gaps. Continuous compliance via tooling.
- **Policy-only.** Writing the policy doesn't implement it. Evidence is
  king.
- **Wrong scope.** Putting EVERYTHING in scope = expensive + slow. Use
  scoping (PCI cardholder env, FedRAMP boundary) deliberately.
- **Skipping the readiness assessment.** Discovers gaps cheaply BEFORE
  the audit; auditors charge for re-attempts.
- **No control owner.** "Security team owns all controls" = nothing
  enforced. Each control has a named owner.

## Validation

- [ ] Target frameworks documented in the security program plan.
- [ ] Compliance automation tool in place (Vanta / Drata / equivalent).
- [ ] Gap analysis run within last 90 days; tracked.
- [ ] Last audit's findings remediated (or risk-accepted with sign-off).
- [ ] Annual training completion ≥ 95%.
- [ ] DSR + breach notification flows tested.
- [ ] Vendor risk register reviewed annually.
- [ ] Evidence collection runs continuously, not just at audit time.
