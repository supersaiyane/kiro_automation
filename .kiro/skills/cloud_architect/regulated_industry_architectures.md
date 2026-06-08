---
id: regulated_industry_architectures
version: 1.0.0
owners: [cloud_architect, security_engineer, legal]
tags: [hipaa, hitrust, pci, sox, gdpr, government, fedramp, bfsi]
when_to_use: |
  Designing cloud architecture for healthcare, BFSI, ecommerce
  with PCI, government / public sector, manufacturing under
  industrial regulation. The reference architectures rhyme; the
  specific control mappings differ. Get them wrong and the
  product is unsellable.
inputs:
  - industry, jurisdictions, target_certifications
outputs:
  - "regulated_design: target frameworks + control mapping + audit posture + data flows"
---

# Regulated-Industry Cloud Architectures

> Regulators don't care about your elegant microservice mesh.
> They care that PHI is encrypted, that auditors can trace any
> data access, that breaches are notifiable within 72 hours.
> The architecture works backward from those non-negotiables.

## The framework landscape (by industry)

| Industry | Frameworks | Key controls |
|---|---|---|
| Healthcare (US) | HIPAA, HITECH, HITRUST CSF | PHI encryption, BAA, access audit |
| Healthcare (EU) | GDPR, NIS2 | data residency, breach notification 72h |
| BFSI (US) | PCI-DSS, SOX, GLBA, NYDFS Pt500 | PCI cardholder env, audit, MFA |
| BFSI (EU/UK) | DORA (effective 2025), PSD2, GDPR | ICT risk, third-party governance |
| Government (US) | FedRAMP (Mod/High), FISMA, CJIS | continuous monitoring, US-only personnel |
| Government (other) | IRAP (AU), C5 (DE), ENS (ES), MeitY (IN) | residency-heavy |
| Ecommerce | PCI-DSS, CCPA, state privacy laws | cardholder, consumer rights |
| Manufacturing | NIST 800-171/800-53 (CMMC for DoD), ISO 27001 | CUI handling, supply chain |
| Cross-industry | SOC 2 Type II, ISO 27001, ISO 27701 | controls foundation everyone wants |

## Cloud provider compliance services (use them)

| Cloud | Service |
|---|---|
| AWS | Audit Manager, Security Hub, Config (HIPAA, PCI, FedRAMP conformance packs) |
| Azure | Microsoft Defender for Cloud Compliance, Azure Policy regulatory initiatives |
| GCP | Assured Workloads, Security Command Center, Compliance Reports Manager |

Each ships predefined control sets (HIPAA, PCI, FedRAMP, etc.)
that map directly to native policies. Use them as the
ENFORCEMENT layer; don't reinvent.

## Pattern 1 — HIPAA / HITRUST (healthcare)

```
┌───────────────────────────────────────────────────────────────┐
│ AWS Org / Azure Tenant / GCP Org                              │
│                                                               │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │ PHI Workload OU │    │ Non-PHI OU      │                   │
│  │ (BAA scope)     │    │ (marketing, etc)│                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                                                   │
│  - All storage encrypted at rest with CMK (BYOK if required)  │
│  - TLS 1.2+ everywhere                                        │
│  - Audit log (CloudTrail / Activity Log) to log-archive       │
│  - VPC isolated; no internet ingress without WAF              │
│  - No PHI in non-PHI OU (DLP scanning)                        │
│  - PHI database row-level access logged + retained 6+ years   │
│  - Patient-rights portal: data access, deletion, portability  │
└───────────────────────────────────────────────────────────────┘
```

Critical: **BAA (Business Associate Agreement)** with the cloud
vendor. AWS, Azure, GCP all sign one. Only services COVERED by
the BAA can touch PHI.

HITRUST CSF builds on HIPAA + ISO + NIST; many US payers require it.

## Pattern 2 — PCI-DSS (cardholder data)

Cardholder Data Environment (CDE) is the bounded scope:

```
┌──────────────────────────────────────────────────────┐
│ Public ────► [ WAF + DDoS ]                          │
│                  │                                    │
│                  ▼                                    │
│           [ Front-end VPC ]                           │
│                  │                                    │
│                  ▼ (tokenized only, no PAN)           │
│           [ Application VPC ]                         │
│                  │                                    │
│                  ▼                                    │
│           [ CDE VPC — PCI scope ]                     │
│           - Network-isolated                          │
│           - All PAN in tokenization vault             │
│           - Hardened OS, change control, audit log    │
│           - Quarterly ASV scan                        │
└──────────────────────────────────────────────────────┘
```

The win pattern: TOKENIZE early, minimize CDE scope. Most apps
don't need to touch raw PAN; they reference tokens that the CDE
exchanges.

## Pattern 3 — BFSI (banking, financial services, insurance)

Layered:

- **Customer-facing edge** (open banking APIs, mobile, web).
- **Transaction core** (FedRAMP-Moderate-equivalent isolation).
- **Settlement / clearing** (highest tier; physical separation
  often required).
- **Analytics & ML** (separated by purpose binding under DORA).

Patterns:
- **Active-active multi-region** for SLA tier-1 systems.
- **Hot-warm-cold DR tiers** documented per service.
- **Vendor concentration risk** (DORA): no single cloud > 30%
  for critical functions — use multi-cloud OR an exit plan.
- **Real-time fraud detection** in a dedicated low-latency
  region.
- **Tax / regulatory reporting** uses immutable storage with
  WORM (object lock).

## Pattern 4 — Government / FedRAMP

```
   GovCloud / Azure Government / GCP Assured Workloads
        │
        ├── US-only personnel access (IAM region condition)
        ├── FIPS 140-2 validated crypto
        ├── Continuous monitoring (DHS CDM)
        ├── FedRAMP-authorized services ONLY (subset of commercial)
        ├── No transit through commercial regions
```

US Federal: FedRAMP Moderate / High. State (CJIS for law
enforcement, IRS Pub 1075 for tax data, etc.) bolt on.

For DoD: IL2 / IL4 / IL5 (Impact Levels) — separate enclaves;
not commercial cloud at IL5+.

Equivalents: UK G-Cloud (Crown Hosting), Germany C5, Australia
IRAP, India MeitY-empanelled.

## Pattern 5 — Ecommerce (PCI + CCPA + state laws)

Variant of PCI pattern + consumer rights:

- Privacy preference center (CCPA / state laws).
- Right-to-delete pipeline (see DB architect's
  retention_and_gdpr_deletion).
- Data-sale opt-out (state laws).
- Cookie consent (TCF v2 for IAB-aligned).
- Fraud + chargeback tooling integrated.

## Pattern 6 — Manufacturing (CMMC for DoD supply chain)

- **CUI (Controlled Unclassified Information)** segmentation.
- **NIST 800-171** (110 controls) at minimum.
- **CMMC Level 2** for DoD prime contractors.
- **IoT / OT integration**: ICS / SCADA networks NEVER directly
  internet-connected; air-gapped or via DMZ + IDS.
- **Digital twin** of supply chain often a separate AI / OLAP env.

## Cross-pattern essentials

### Data residency
- Per-region compute + storage for residency-bound data.
- DR region in the same jurisdiction.
- "Sovereign cloud" offerings (e.g., AWS Sovereign Cloud, Azure
  Local) for jurisdictions that block all foreign tenant access.

### Audit log immutability
- Append-only, separate account, S3 Object Lock / Azure
  Immutable Blob / GCS Bucket Lock.
- 7+ year retention.
- No deletion privileges in operational accounts.

### Breach notification timing
- GDPR: 72 hours to regulator.
- HIPAA: 60 days to affected individuals.
- State laws: vary 30-90 days.
- Build the IR runbook to MEET the strictest applicable.

### Vendor / third-party risk (DORA, SOC 2)
- Inventory every SaaS / API / data processor.
- Risk-tier each.
- Contracts include termination, data return, audit clauses.
- Annual review.

## Audit readiness — never not ready

- All native compliance services on (Audit Manager, Defender,
  Security Command Center).
- Evidence collection automated (screenshots, logs, configs
  pulled to an audit-evidence bucket monthly).
- Pen test annually + after material changes.
- Tabletop drill of breach scenario annually.

Auditors arrive; you click "export evidence pack." Not a 3-week
fire drill.

## Anti-patterns

- **"We'll be compliant before launch."** Compliance is multi-
  month; design FROM compliance, don't bolt it on.
- **PHI / PCI data flowing through non-scoped services.**
  Massive scope creep at audit time.
- **One mega-tenant for regulated + non-regulated.** Blast
  radius too big.
- **No BAA / DPA.** Vendor isn't in scope; you're personally
  liable.
- **"It's encrypted, we're done."** Encryption is necessary,
  not sufficient. Key management, access logging, network
  isolation also required.
- **Same architecture for all jurisdictions.** EU + India +
  China each have different residency / inspection rules.
- **No segregation between admin + audit roles.** Auditors
  expect the access-granter and access-auditor to be separate.

## Validation

- [ ] Target frameworks listed in the design; controls mapped.
- [ ] BAA / DPA signed with cloud + every relevant SaaS.
- [ ] Data residency enforced by SCPs / Org Policies.
- [ ] Audit log immutable, 7+ year retention, separate account.
- [ ] Encryption: TLS 1.2+ everywhere; CMK / BYOK where
      regulator requires.
- [ ] Breach notification runbook tested annually.
- [ ] Vendor risk register exists and is reviewed annually.
- [ ] Pre-audit dry run completed; gaps closed.
