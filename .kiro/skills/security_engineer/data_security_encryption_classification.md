---
id: data_security_encryption_classification
version: 1.0.0
owners: [security_engineer, database_architect, legal]
tags: [data-security, classification, dlp, tokenization, encryption-at-rest, encryption-in-transit]
when_to_use: |
  Designing the data layer for ANY system that stores customer info,
  payment data, PHI, or any regulated data. The first hour of design
  is worth a year of compliance retrofitting.
inputs:
  - data_inventory, regulatory_scope, threat_model
outputs:
  - "data_security_plan: classification + encryption tiers + DLP + tokenization + retention"
---

# Data Security — Classification, Encryption, DLP, Tokenization

> Data security starts with knowing what you have. "Encrypt
> everything" sounds robust but if you don't know what data exists,
> classification is impossible, GDPR delete is impossible, audit is
> impossible.

## Data classification — the foundation

Standard 4-tier scheme:

| Tier | Examples | Encryption | Access |
|---|---|---|---|
| **Public** | Marketing copy, open-source code | Not required | Anyone |
| **Internal** | Employee directory, internal docs | TLS in transit | Authenticated employees |
| **Confidential** | Customer PII, financial records, source code | At-rest + in-transit | Role-based |
| **Restricted** | PHI, payment card data, secrets, government CUI | At-rest + in-transit + tokenization/HSM | Strict need-to-know |

Every table, every S3 bucket, every Slack channel: tagged.

## Classification tooling

- **Data catalog**: Collibra, Atlan, OpenMetadata, Google Data Catalog —
  central registry of every dataset + tier.
- **Auto-classification**: AWS Macie, Microsoft Purview, BigID — scan
  storage for PII patterns (SSN, credit card, email).
- **Schema annotations**: PostgreSQL `COMMENT ON COLUMN` with classification.
  Or table_constraints, or external metadata layer (Iceberg / Delta).

Don't trust auto-classification alone. Combine with engineering ownership.

## Encryption at rest — defaults

- **Storage volumes**: enable at provisioning. AWS EBS default encryption,
  GCP CMEK, Azure Storage Service Encryption. NO opt-in.
- **Databases**:
  - RDS / Cloud SQL / Azure SQL: TDE (Transparent Data Encryption) on.
  - DynamoDB / Cosmos: encrypted by default.
  - For higher control: app-level encryption with KMS-issued DEK (envelope).
- **Object storage**: S3 SSE-KMS, GCS CMEK, Azure CMK.
- **Backups**: encrypted with the SAME KMS key as live data (or a
  designated backup-key with same rotation).
- **Logs**: classified — if they may contain PII, treat as Confidential and
  encrypt.

KMS rules:
- One KMS key per workload / tenant / region (blast radius).
- Key policy = principle of least privilege.
- Key access logged + alerted on anomalies.
- Rotation per `cryptography_pki_key_management` schedule.

## Encryption in transit

- TLS 1.3 (1.2 minimum) at every hop.
- mTLS between services.
- Even on private networks: NO clear-text protocols. Telnet, FTP, plain HTTP
  are dead. SMTP submission encrypted. Database connections require SSL.
- Verify certificates — disable verification flags are bugs masquerading as
  config.

## Application-level (field-level) encryption

For Restricted data, encrypt at the APPLICATION layer:

```python
# SSN column stored encrypted; key from KMS
ssn_ciphertext = kms.encrypt(plaintext=user.ssn, key_id=kek_id)
db.execute("UPDATE users SET ssn_enc=%s WHERE id=%s", (ssn_ciphertext, user.id))
```

Pros: DBAs can't see plaintext; storage backup compromise doesn't expose.
Cons: searchable encryption is HARD; usually only EQUALITY queries.

For searchable: use deterministic encryption (same plaintext → same ciphertext)
but be aware of frequency-analysis attacks. OR use a separate
search-friendly index with proper auth.

## Tokenization — when encryption isn't enough

For PCI-DSS, HIPAA: replace sensitive value with a token; map stored only in a
secure vault.

```
Original:     "4111-1111-1111-1111"
Token:        "tok_8e3f2a1b9c"  ← reversibly mapped in vault
Stored in DB: token only
Vault:        secured separately, audit-logged
```

Tokens are not encryption — they're indirection. The vault can be hardened
to a tiny attack surface; the rest of the system never sees real card data,
removing it from PCI scope.

Providers: Vault Transform, Skyflow, VGS, Basis Theory.

## Data Loss Prevention (DLP)

DLP catches sensitive data flowing where it shouldn't:

| DLP class | What it checks | Tool examples |
|---|---|---|
| Network DLP | Outbound traffic for PII patterns | Symantec, Forcepoint, Zscaler |
| Endpoint DLP | USB, clipboard, file transfers from laptops | CrowdStrike Falcon, MS Defender |
| Email DLP | Outbound emails for PII / classified terms | Google, MS 365 native |
| Cloud DLP | S3, Drive, Box scan + redact | AWS Macie, Google DLP API |
| Code DLP | Secrets / PII in source code | TruffleHog, GitGuardian, Snyk |

Don't deploy ALL of them on day 1; start with email + cloud + code.

## Data retention + deletion (cross-ref)

See the database-architect skill `retention_and_gdpr_deletion` — security
review covers:

- Every PII column has a documented retention period.
- Deletion is TESTED quarterly (GDPR drill).
- Backups are part of the deletion plan (re-process on restore or short
  retention window).
- Audit logs survive deletion via tombstone (opaque ID), not full erasure.

## Customer-managed encryption keys (CMEK / BYOK)

For enterprise customers requiring sovereignty:

- Customer brings their own KMS key (or imports their own material).
- Service encrypts customer's data with that key.
- Customer can REVOKE access, immediately rendering data unreadable.

Supported by Snowflake, Salesforce, Slack Enterprise, BigQuery, etc. Plan
for it in the data architecture from day 1 if you have enterprise customers.

## DSR (Data Subject Request) flow — GDPR Art. 15-21

- **Access**: deliver every PII record for a user in machine-readable form
  within 30 days.
- **Rectify**: edit incorrect data.
- **Erasure** (Art. 17): delete per `retention_and_gdpr_deletion`.
- **Portability** (Art. 20): provide a structured export.
- **Restrict / Object**: pause processing while disputes resolve.

Automate. A manual DSR pipeline = a 4% of revenue fine waiting to happen.

## Anti-patterns

- **"Encrypt everything" without classification.** Wasted CPU + key
  management cost without a security improvement story.
- **Encryption keys stored next to ciphertext.** Equivalent to no
  encryption.
- **No customer-data inventory.** Can't classify, can't delete, can't audit.
- **PII in logs.** "Just for debugging" — log redaction is mandatory.
- **Symmetric keys shared across tenants.** Breach → all tenants exposed.
- **DLP that only WATCHES (no block).** Catches breaches after the fact;
  block at the egress.
- **Backups encrypted with a key only the prod KMS knows.** Loss of KMS =
  loss of backups.

## Validation

- [ ] Every storage layer encrypted at rest (no exceptions in prod).
- [ ] Every data-flow uses TLS 1.2+; no clear-text protocols.
- [ ] Data classification catalog exists and is maintained.
- [ ] PII columns at application-encryption or tokenization tier.
- [ ] DLP scanning email + code + cloud storage at minimum.
- [ ] GDPR deletion path tested in last 90 days.
- [ ] CMEK supported for enterprise tenants (if applicable).
- [ ] Quarterly review of key access logs for anomalies.
