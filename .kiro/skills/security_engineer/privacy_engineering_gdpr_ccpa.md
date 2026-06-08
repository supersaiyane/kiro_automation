---
id: privacy_engineering_gdpr_ccpa
version: 1.0.0
owners: [security_engineer, legal, database_architect]
tags: [privacy, gdpr, ccpa, dpia, anonymization, differential-privacy, dsr]
when_to_use: |
  Building any product that touches personal data. Privacy and security
  overlap but are NOT the same — privacy is about WHAT we collect, WHY,
  for HOW LONG, and WHO can see it. Get it wrong and the fine is 4% of
  global revenue (GDPR), not a slap on the wrist.
inputs:
  - data_inventory, jurisdictions, processing_purposes
outputs:
  - "privacy_program: purpose register + DPIA + DSR pipeline + retention + transfers"
---

# Privacy Engineering — GDPR, CCPA, and Beyond

> "We're encrypted" doesn't satisfy a regulator. Privacy law cares
> about purpose, consent, retention, subject rights, and transfers.
> Engineering privacy means encoding these into the system, not
> writing a policy nobody reads.

## The regulatory map (2026)

| Law | Region | Key idea |
|---|---|---|
| **GDPR** | EU + EEA | Lawful basis, rights, 72h breach notice |
| **UK GDPR** | UK | GDPR-aligned post-Brexit |
| **CCPA / CPRA** | California | Consumer rights, opt-out of sale |
| **VCDPA / CDPA / CPA / UCPA / others** | Most US states | Patchwork; converging on GDPR-lite |
| **LGPD** | Brazil | GDPR-influenced |
| **PIPL** | China | Stricter consent + cross-border |
| **PDPA** | Singapore | Notification + consent |
| **India DPDP** | India (2023) | Notice + consent, fiduciary duties |
| **Quebec Law 25** | Quebec | DPO required, consent thresholds |

Design for the strictest applicable; you'll comply elsewhere automatically.

## Core principles (GDPR Art. 5, mirrored elsewhere)

1. **Lawfulness, fairness, transparency** — process for documented reason.
2. **Purpose limitation** — collect for THIS purpose; don't repurpose.
3. **Data minimization** — collect ONLY what's needed.
4. **Accuracy** — keep current; rectify on request.
5. **Storage limitation** — retain only as long as needed.
6. **Integrity and confidentiality** — encrypt, restrict access.
7. **Accountability** — be able to PROVE compliance.

These map to engineering controls.

## Lawful basis register

For every processing activity, document basis:

| Basis | When |
|---|---|
| Consent | Most marketing, optional features |
| Contract | Service performance for the user |
| Legal obligation | Tax records, regulatory storage |
| Vital interests | Life-safety scenarios (rare) |
| Public task | Government bodies |
| Legitimate interests | Internal analytics (with balancing test) |

DO NOT default to "consent" — it's the weakest, user can revoke any time.

## Records of Processing Activities (RoPA)

GDPR Art. 30 requires controllers maintain a register:

```
Activity:      User analytics
Controller:    Acme Inc
Purpose:       Improve product features
Lawful basis:  Legitimate interests (balancing test attached)
Categories:    Online identifiers, behavioral data
Subjects:      Customers, prospects
Recipients:    Mixpanel (US processor under SCC)
Retention:     14 months
Security:      TLS in transit, AES-256 at rest, RBAC access
Transfers:     US — SCC + Mixpanel adequacy assessment
```

One row per ACTIVITY. Update on every new feature.

## Data Protection Impact Assessment (DPIA)

Required when processing is HIGH RISK:
- Systematic + extensive profiling.
- Large-scale processing of special categories (health, biometrics).
- Public-area monitoring.
- New tech that may pose risk (AI inference, facial recognition).

DPIA template (Article 35):

```
1. Description of processing (purpose, scope, context)
2. Necessity + proportionality assessment
3. Risk to data subjects (rate L/M/H)
4. Measures to mitigate
5. Sign-off (DPO + business owner)
```

Without a DPIA on a high-risk activity, the regulator can stop processing
immediately.

## Data Subject Requests (DSRs)

Subjects can demand:

| Right | GDPR Art. | Practical |
|---|---|---|
| Access | 15 | Provide all their data in 30 days |
| Rectification | 16 | Edit incorrect data |
| Erasure | 17 | "Right to be forgotten" |
| Restriction | 18 | Pause processing |
| Portability | 20 | Machine-readable export |
| Object | 21 | Stop processing on legitimate-interests basis |
| Automated decision rights | 22 | No solely-automated significant decisions |

**Engineer the DSR pipeline**:
- Endpoint accepts request (after identity verification).
- Maps user_id across all systems (CRM, support, prod DB, analytics, etc.).
- Executes per the right requested.
- Logs everything.
- Returns receipt to user.
- Completes within 30 days (extension up to 60d with notice).

If DSR is manual → at scale this breaks (cost + miss = fines).

## Consent management

Required for: cookies, marketing emails, optional analytics, sensitive data.

Properties of valid consent (GDPR):
- **Freely given** (no service refusal for refusal).
- **Specific** (per purpose, not blanket).
- **Informed** (purposes clearly stated).
- **Unambiguous** (active opt-in, no pre-ticked).
- **Withdrawable** (just as easy to withdraw as give).

Tools: OneTrust, Cookiebot, Osano, Didomi (Consent Management Platforms).

Backend: consent log per user/purpose with timestamp + version. Storage:
forever or until 5 years after last activity.

## Anonymization vs pseudonymization

| | Anonymization | Pseudonymization |
|---|---|---|
| Reversibility | Not possible | Possible with separately-held key |
| GDPR status | Falls OUT of scope | Still personal data |
| Use | Public datasets, archives | Internal processing |
| Techniques | k-anonymity, l-diversity, t-closeness, differential privacy | Hashing, tokenization |

Anonymization is HARD. The Netflix Prize re-identification (2008) showed
that "anonymized" data + auxiliary data often re-identifies. Reach for
DIFFERENTIAL PRIVACY for true anonymization:

```
# Add calibrated noise to query results
import diffprivlib.mechanisms as dpm
mech = dpm.Laplace(epsilon=1.0, sensitivity=1)
private_count = mech.randomise(real_count)
```

Tools: Google's Differential Privacy library, OpenDP, IBM's diffprivlib.

For most apps: PSEUDONYMIZATION (replace identifiers with tokens) is the
practical pattern. Combine with access control.

## Cross-border transfers

EU → US transfers post-Schrems II:
- **Standard Contractual Clauses (SCCs)** + supplementary measures.
- **Data Privacy Framework (DPF)** — replacement for Privacy Shield (2023).
- **Adequacy decisions** for some countries (UK, Switzerland, Japan, etc.).
- **Binding Corporate Rules (BCRs)** — for intra-group transfers, complex.

Implementation:
- Inventory data flows crossing borders.
- For each: which mechanism?
- Document Transfer Impact Assessment (TIA) for SCC use.
- Encryption + access controls as supplementary measures.

## Breach notification

GDPR Art. 33: notify supervisory authority **within 72 hours** of becoming
aware of a personal data breach (unless unlikely to risk subjects).

Art. 34: notify SUBJECTS without undue delay if HIGH RISK.

Engineering for the 72-hour requirement:
- Pre-drafted notification templates.
- Pre-identified DPO + legal contacts per jurisdiction.
- Audit logs sufficient to identify "what data, how many subjects."
- Incident classification rubric — breach or not?

Practice in tabletop exercises. The 72h clock starts ticking at AWARENESS,
not investigation completion.

## Privacy by Design + Default (Art. 25)

Embed in the engineering lifecycle:
- New feature → privacy review (cross-ref `threat_modeling_stride_pasta`,
  but add privacy lens: purpose, basis, minimization).
- Default settings PRO-PRIVACY (analytics off, sharing off, public off).
- Use cookies / fingerprinting only with explicit consent.
- Data architecture supports per-user deletion + export.

## DPO — when required

GDPR Art. 37: DPO required if:
- Public authority.
- Core activity = regular + systematic monitoring on large scale.
- Core activity = large-scale processing of special categories.

For most SaaS: DPO is NOT legally required but is BEST PRACTICE for B2B
buyers + buying complex contracts. Outsourced DPO is acceptable.

## Anti-patterns

- **Privacy policy is "all of the above"** — collect every basis. Triggers
  regulator interest.
- **Consent for everything**, including contract-necessary processing.
  Confusing + harder to withdraw.
- **Storing PII in logs**. Logs forwarded to vendor → de facto cross-
  border transfer + processor agreement implications.
- **"Anonymized" via removing names**. Re-identifiable; treat as personal
  data.
- **DSR pipeline = email to support@.** Doesn't scale; misses systems;
  fines.
- **No data inventory.** Can't comply because you don't know what you have.
- **Consent forms in legalese**. Invalid (not "informed").
- **Cross-border data without a mechanism**. Mandatory; gap = fine.

## Validation

- [ ] RoPA exists and is current.
- [ ] Lawful basis documented per processing activity.
- [ ] DPIA completed for high-risk activities.
- [ ] DSR pipeline automated; tested in last 90 days.
- [ ] Consent management platform live for cookies + marketing.
- [ ] Cross-border transfer mechanism documented for every flow.
- [ ] 72-hour breach notification playbook ready.
- [ ] Annual privacy training for all staff.
- [ ] Data retention policy implemented in code, not just policy doc.
