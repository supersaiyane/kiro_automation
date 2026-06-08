---
id: cryptography_pki_key_management
version: 1.0.0
owners: [security_engineer, architect, devops_engineer]
tags: [crypto, tls, pki, kms, hsm, key-rotation, post-quantum]
when_to_use: |
  Any system that encrypts data, signs messages, or terminates TLS.
  Cryptography is unforgiving — "we'll fix it later" doesn't apply
  when keys leak or algorithms break. Get the design right BEFORE
  shipping production traffic.
inputs:
  - data_classification, threat_model, compliance_scope
outputs:
  - "crypto_design: algorithms + key hierarchy + rotation cadence + ceremony + audit"
---

# Cryptography, PKI, Key Management

> Don't roll your own crypto. Don't use rolled crypto. Use the
> battle-tested libraries, but UNDERSTAND what they do — every
> production breach has a key-management failure under it.

## Algorithm baseline (2026)

| Use | Algorithm | Don't use |
|---|---|---|
| Symmetric encryption | AES-256-GCM, ChaCha20-Poly1305 | DES, 3DES, CBC-without-MAC, ECB |
| Asymmetric | RSA-3072+, ECDSA P-256, Ed25519 | RSA-1024, DSA |
| Hashing | SHA-256, SHA-3, BLAKE2 | MD5, SHA-1 |
| Password hashing | Argon2id, scrypt, bcrypt | MD5, SHA-256 directly |
| HMAC | HMAC-SHA-256+ | HMAC-MD5 |
| KDF | HKDF, PBKDF2 (legacy) | proprietary KDF |
| TLS | 1.3 (1.2 minimum) | 1.0, 1.1, SSL |
| Post-quantum (when ready) | ML-KEM (Kyber), ML-DSA (Dilithium) | (start hybrid by 2027) |

## TLS / mTLS — the wire

- **TLS 1.3** everywhere. TLS 1.2 acceptable if downstream forces it.
  TLS 1.0/1.1 disabled at every termination point.
- **Cipher suite policy**: AEAD ciphers only (GCM, ChaCha20-Poly1305). No
  CBC, no RC4.
- **HSTS** with `max-age ≥ 31536000; includeSubDomains; preload`.
- **OCSP stapling** enabled to avoid revocation-check latency.
- **Cert rotation** every 90 days (Let's Encrypt cadence) — automate or
  outages are inevitable. Use ACME (certbot, cert-manager).
- **mTLS** for service-to-service: identity in the cert SAN, validated
  every connection. Issued by an internal PKI (e.g. SPIFFE/SPIRE, AWS
  Private CA, Vault PKI).

## Key hierarchy — the structure

```
  ┌─────────────────────────────────────────┐
  │  Root key (offline, ceremony-only)      │  HSM-backed
  │  Used to sign master keys, never data   │
  └──────────────┬──────────────────────────┘
                 │
       ┌─────────┴─────────┐
       ▼                   ▼
  Master KEK (KMS)    Signing KEK
  rotates yearly      rotates yearly
       │                   │
       ▼                   ▼
  Data Encryption     Per-document
  Keys (DEKs)         signing keys
  rotated per object  per-tenant scoped
```

**Envelope encryption pattern**: data is encrypted with a per-object DEK; the
DEK is then encrypted with a KEK and stored alongside the ciphertext. To
rotate the KEK, re-encrypt all DEKs (cheap); never re-encrypt the data.

## KMS / HSM choice

| Use | Where |
|---|---|
| Cloud-native data | AWS KMS, Azure Key Vault, GCP Cloud KMS |
| Highest assurance | Cloud HSM (AWS CloudHSM, Azure dedicated HSM) |
| Multi-cloud / vendor-neutral | HashiCorp Vault (Transit secrets engine) |
| Special compliance (FIPS 140-2 L3) | Hardware HSM |
| Code signing | Sigstore / GitHub OIDC + cosign (keyless) |
| TLS issuance | Let's Encrypt + cert-manager OR Vault PKI |

NEVER store raw private keys in app config, env vars, or git.

## Key rotation policy

| Key type | Rotation cadence | Trigger for emergency rotation |
|---|---|---|
| TLS server cert | 60-90 days | Suspected compromise, vendor incident |
| TLS root CA | 5-10 years | Algorithm deprecation |
| Service mTLS | 24h-7d | Workload identity refresh |
| KMS data-encryption keys | Annually (or per regulation) | After incident |
| API tokens / JWT signing | Quarterly | Suspected leak |
| User passwords | NEVER (use bcrypt/Argon2, allow user-driven change) | After breach |

Rotation MUST be tested in non-prod first. A rotation that has never been
exercised is hopeful code, not policy.

## Key ceremony — for high-stakes ops

For root key generation, recovery, or transfer:

1. Multi-person attendance (M-of-N), often 3-of-5.
2. Air-gapped environment.
3. Video + paper logs.
4. Each step witnessed and signed.
5. Output: split secret (Shamir) stored in geographically diverse safes.

This sounds theatrical but is real for regulated industries (PCI, payments,
crypto custodians). Plan it; don't improvise during an incident.

## Common cryptographic mistakes (the breach archive)

1. **ECB mode** → patterns leak (penguin meme).
2. **CBC without MAC** → padding-oracle attacks.
3. **RNG = `Random.nextInt`** → predictable session IDs.
4. **Hardcoded IV / nonce** → key recovery.
5. **MAC after encrypt vs encrypt-then-MAC** confusion → vulnerabilities.
6. **Custom KDF** ("just SHA the password 1000 times") → fast brute force.
7. **Storing keys in env vars committed to git history.**
8. **Validating signatures from unverified key pinning** → MITM.
9. **`memcmp` instead of constant-time compare** → timing side channels.
10. **Long-lived bearer tokens** without rotation.

Avoid #1-7 by using a vetted library: **libsodium**, **AWS Encryption SDK**,
**Google Tink**, **Rust's `ring`**. Don't write primitives.

## Post-quantum readiness (2026 status)

NIST published the first PQC standards in 2024:
- ML-KEM (FIPS 203) — key encapsulation
- ML-DSA (FIPS 204) — signatures
- SLH-DSA (FIPS 205) — stateless hash-based signatures

Migration approach:
1. **Hybrid TLS** — combine classical + PQC (X25519 + Kyber) at TLS handshake.
   Available in OpenSSL 3.2+, Cloudflare, Google.
2. **Inventory long-lived keys** that need to survive a CRQC (cryptographically
   relevant quantum computer). Anything signed today and verified in 10+ years
   is at "harvest now, decrypt later" risk.
3. **Plan crypto agility** — abstract algorithm choice in code so swapping
   doesn't require rewriting.

Most apps don't need PQC yet. Plan the path; don't rush implementation.

## Auditing crypto

Quarterly:
- TLS cert inventory + expiry calendar (alert at 14d, 7d, 1d before).
- Cipher suite scan (e.g. testssl.sh) — flag CBC + TLS 1.0/1.1.
- KMS access logs — who decrypted what, when. Anomalies?
- Key rotation status — any keys past rotation window?

Annually:
- External pen test of crypto implementation.
- Algorithm sunset review — anything heading for deprecation?

## Anti-patterns

- **Roll-your-own crypto** in any form. Even XOR cipher. Even "just hashing."
- **Long-lived static keys** baked into apps. Use rotating tokens / mTLS.
- **Same key for multiple purposes** (encryption + signing). Separate keys.
- **Padding oracles unaddressed** in legacy CBC + HTTP responses.
- **Ignoring side channels** (timing, cache, power) for ECC implementations.
- **Hardcoded "test" certs** that ship to production by accident.
- **No HSM for the master key** in regulated environments.
- **Trusting client-supplied JWT alg** (`{alg: none}` attacks).

## Validation

- [ ] TLS 1.3 enforced; 1.0/1.1 disabled at every termination.
- [ ] All cert expiry monitored with alerts ≥ 14 days out.
- [ ] No private keys in code, env, or git.
- [ ] KMS / HSM is the authority for production secrets.
- [ ] Rotation tested in last 90 days for at least one key class.
- [ ] testssl.sh scan against prod returns no Critical findings.
- [ ] Algorithm inventory documented for the next 24-month sunset risk.
- [ ] PQC crypto-agility considered in the architecture roadmap.
