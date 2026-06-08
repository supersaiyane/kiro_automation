---
id: secrets_management
version: 1.0.0
owners: [security_engineer, devops_engineer, backend_lead]
tags: [secrets, vault, rotation, kms, encryption, scanning]
when_to_use: |
  Any credential, API key, signing key, OAuth client secret,
  database password, JWT signing material — anywhere. Get the model
  right before the first secret enters your system; retrofitting is
  10x painful.
inputs:
  - secret_classes: types of credentials your services use
outputs:
  - secrets_design: storage, rotation, access policy, audit
---

# Secrets Management

## The rules that are non-negotiable

1. **Never in git.** Not in `.env`, not in CI YAML, not in Terraform
   state without encryption.
2. **Never in app logs.** Redact in the logger, not after.
3. **Never in error messages to the user.** The error path is a leak
   channel.
4. **Always rotated.** Static secrets are time-bombs. Rotation cadence
   per type below.
5. **Always scoped.** Production secret can't decrypt a staging
   environment. Per-environment, per-service, per-purpose.
6. **Always audited.** Every access logged; reviewed weekly for
   anomalies.

## The storage tiers

| Tier | Use for | Examples |
|---|---|---|
| **KMS** (key management service) | Master keys; nothing else | AWS KMS, GCP KMS, HashiCorp Vault Transit |
| **Secrets manager** | App secrets, DB creds, API keys | AWS Secrets Manager, GCP Secret Manager, Vault KV |
| **Env vars at runtime** | Acceptable IF injected from a secrets manager at boot, never persisted | injected via container orchestration |
| **`.env` on dev laptops** | Local development only; gitignored | local Vault dev mode is better |

**Anti-pattern**: env vars baked into a Docker image. Anyone with image
pull access has the secret.

## Rotation cadence

| Secret type | Rotate | How |
|---|---|---|
| Database password (service-to-service) | 30-90 days | Automated via Secrets Manager rotation lambda |
| API keys to external vendors | 90 days | Vendor's rotation API, or manual + ticket |
| JWT signing key | Every 60 days, with overlap | Two valid keys at once; new tokens use new key; old key validates until expiry of last issued token |
| TLS cert | Before expiry; LetsEncrypt auto-renews 30d before | Automated |
| OAuth client secret | 180 days | Manual; track in calendar / ticketing |
| User passwords | NEVER on a schedule (NIST 800-63B updated guidance) | Rotate on compromise only; enforce length + breach-corpus check |

**Manual rotations always fail.** Automate or accept that you have a
key from 2019 still in production.

## The JWT key rotation pattern (because everyone gets this wrong)

```
# At time T:
keys = { "k-2026-01": SECRET_NEW }      # signing
verify_keys = [SECRET_NEW, SECRET_OLD]  # accepting both

# Issue tokens with k-2026-01 (kid header points to which key).

# At time T + 60 days:
keys = { "k-2026-03": SECRET_NEWER }
verify_keys = [SECRET_NEWER, SECRET_NEW]  # drop SECRET_OLD

# All tokens signed with SECRET_OLD have expired by T+60 because
# token TTL <= 60 days.
```

JWT lib must support `kid` header lookup. Stuffing one secret into a
global breaks rotation.

## Access patterns

- **Workload identity over keys.** AWS IRSA, GCP Workload Identity,
  Vault Kubernetes auth. The service authenticates *by who it is*, not
  by a long-lived secret it carries.
- **Short-lived tokens.** STS, OIDC. Default to 15-minute tokens with
  automatic refresh.
- **Per-environment KMS keys.** A prod-key encrypts prod data; staging
  cannot decrypt prod even if compromised.
- **Break-glass account** in a separate vault, with two-person rule
  to access. Used once a year, audited every time.

## Detection

- **Pre-commit hooks**: `gitleaks`, `trufflehog`, `pre-commit-secrets`.
- **CI scan** on every PR. Block merge on positive.
- **Repo history scan** quarterly. The hook only catches the future.
- **CSPM tools** (Wiz, Prisma) for cloud-side exposed secrets in
  user-data, S3 buckets, container images.
- **Subscribe to GitHub secret-scanning alerts** — they tell you when
  a key was committed even to a fork.

## Incident response (secret leaked)

In this order, within minutes:
1. **Revoke** the secret at the provider.
2. **Issue replacement** to the services that need it.
3. **Audit logs** for anomalous use during the exposure window.
4. **Force-push** removal from git is too late (forks already have it),
   but do it.
5. **Postmortem**: how did it leak? Add a guard so it can't happen
   that way again.

## Anti-patterns

- One Vault root token shared via Slack. The root token is the keys
  to the kingdom; treat like a break-glass.
- `git rm secret.txt; git commit`. The secret is still in history.
  Rewrite history (`git filter-repo`) + force-push + assume leaked.
- Letting CI inject secrets but logging the env at startup. Fast leak.
- 1-year API keys with no rotation plan. They will become legacy.
- A secret used by 50 services. One compromise scopes to all. Issue
  per-service secrets and per-tenant keys where applicable.
- Encrypting secrets with a key stored next to them. That's encoding,
  not encryption.
- Hand-typing prod secrets into laptops. Use SSO + workload identity
  + short-lived tokens.
- "We'll address this when we do SOC 2." Auditors are the wrong
  forcing function; do it because it's right.
