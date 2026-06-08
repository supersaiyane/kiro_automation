# Security Design Document — CalcApp

**Author:** Security Engineer  
**Phase:** DESIGN (Mode 1)  
**Date:** 2025-01-XX  
**Status:** APPROVED  

---

## 1. STRIDE Threat Model

### 1.1 Trust Boundary: Client (Flutter App)

| STRIDE Category | Threat | Likelihood | Impact | Mitigation |
|----------------|--------|-----------|--------|-----------|
| **Spoofing** | Attacker impersonates user via stolen device | Medium | High | Biometric/PIN lock, secure token storage (flutter_secure_storage → iOS Keychain / Android Keystore) |
| **Tampering** | Modified APK/IPA with disabled encryption | Medium | Critical | Code obfuscation (R8/ProGuard), runtime integrity checks, certificate pinning |
| **Repudiation** | User denies calculation actions | Low | Low | Client-side audit log synced to server with timestamps + user ID |
| **Information Disclosure** | Memory dump exposes decrypted calculations | Medium | High | Zeroize encryption keys after use, disable screenshots on sensitive screens, no plaintext in logs |
| **Denial of Service** | Resource exhaustion via complex calculations | Low | Medium | Computation timeout (5s max), input size limits (10KB per expression) |
| **Elevation of Privilege** | Local exploit gains access to other users' data | Low | Critical | Per-user encryption keys derived from password, OS sandboxing, no shared storage |

### 1.2 Trust Boundary: Transit (Network Layer)

| STRIDE Category | Threat | Likelihood | Impact | Mitigation |
|----------------|--------|-----------|--------|-----------|
| **Spoofing** | DNS spoofing redirects to malicious API | Medium | Critical | Certificate pinning (SHA-256 pin), DNSSEC via Cloudflare |
| **Tampering** | MITM modifies API responses | Medium | High | TLS 1.3 enforced, certificate pinning, payload HMAC validation |
| **Repudiation** | Disputed data sync events | Low | Medium | Idempotency keys + server-side audit trail per request |
| **Information Disclosure** | Traffic analysis reveals usage patterns | Low | Medium | E2E encryption (ciphertext in transit), TLS 1.3, Cloudflare proxy hides origin |
| **Denial of Service** | WebSocket flood / connection exhaustion | Medium | High | Cloudflare rate limiting (100 req/min/IP), WebSocket max connections (5/user) |
| **Elevation of Privilege** | Token interception enables account takeover | Medium | Critical | Short-lived JWT (1hr), refresh token rotation, secure cookie flags |

### 1.3 Trust Boundary: Server (Supabase + Fly.io Phase 3)

| STRIDE Category | Threat | Likelihood | Impact | Mitigation |
|----------------|--------|-----------|--------|-----------|
| **Spoofing** | Forged JWT bypasses auth | Low | Critical | RS256 JWT verification, JWKS endpoint rotation, `aud`/`iss` claim validation |
| **Tampering** | Direct DB manipulation bypassing RLS | Low | Critical | RLS on ALL tables, no service_role key in client, prepared statements only |
| **Repudiation** | Admin actions without trail | Medium | High | Immutable audit log table (INSERT-only, no UPDATE/DELETE grants) |
| **Information Disclosure** | SQL injection leaks other users' data | Low | Critical | Parameterized queries (PostgREST), RLS `auth.uid()` filters, zero-knowledge encryption |
| **Denial of Service** | Query of death / expensive joins | Medium | High | Statement timeout (10s), connection pooling (PgBouncer), Supabase rate limits |
| **Elevation of Privilege** | RLS bypass via function definer | Medium | Critical | All functions `SECURITY INVOKER`, no `SECURITY DEFINER` without audit, role separation |

### 1.4 Trust Boundary: Third-Party Services

| STRIDE Category | Threat | Likelihood | Impact | Mitigation |
|----------------|--------|-----------|--------|-----------|
| **Spoofing** | Fake OAuth callback steals auth code | Medium | High | PKCE (S256) for all OAuth flows, `state` parameter validation, registered redirect URIs only |
| **Tampering** | RevenueCat webhook forgery | Medium | High | Webhook signature verification (HMAC-SHA256), IP allowlisting |
| **Repudiation** | Disputed subscription status | Low | Medium | RevenueCat receipt validation + local audit log |
| **Information Disclosure** | Third-party breach exposes user emails | Medium | High | Minimize data shared (no calculation data to third parties), pseudonymous IDs where possible |
| **Denial of Service** | OAuth provider outage blocks login | Medium | Medium | Cached session tokens (7d refresh), graceful degradation, offline mode |
| **Elevation of Privilege** | Compromised OAuth token grants admin access | Low | Critical | OAuth tokens scoped to profile only, no admin role derivation from OAuth claims |

---

## 2. Auth Design

### 2.1 Authentication Flow

```
┌─────────┐         ┌───────────┐         ┌──────────────┐
│  Client  │────────▶│ Cloudflare │────────▶│ Supabase Auth │
│ (Flutter)│◀────────│   (WAF)    │◀────────│   (GoTrue)    │
└─────────┘         └───────────┘         └──────────────┘
     │                                           │
     │  1. Email/Password OR OAuth (PKCE)        │
     │  2. Receive access_token + refresh_token  │
     │  3. Store in flutter_secure_storage       │
     │  4. Attach Bearer token to all requests   │
     └───────────────────────────────────────────┘
```

### 2.2 Token Management

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Access token TTL | 1 hour | Balance UX vs exposure window |
| Refresh token TTL | 7 days | Sliding window, rotated on use |
| Token format | JWT RS256 | Asymmetric; client can't forge |
| Storage (mobile) | flutter_secure_storage | iOS Keychain / Android Keystore |
| Storage (web) | HttpOnly Secure SameSite cookie | XSS-resistant |
| Refresh rotation | One-time use, family revocation | Detects token replay |

### 2.3 Session Handling

- **Concurrent sessions:** Max 5 per user; oldest revoked on 6th login
- **Session revocation:** User can revoke all sessions from settings
- **Logout:** Client deletes tokens + calls `/auth/v1/logout` to invalidate server-side
- **Idle timeout:** 30min inactivity triggers soft-lock (biometric/PIN to resume, no re-auth)

### 2.4 OAuth Configuration

| Provider | Scopes | PKCE | State | Notes |
|----------|--------|------|-------|-------|
| Google | `openid email profile` | S256 | Random 32-byte | Android: SHA-256 fingerprint registered |
| Apple | `name email` | S256 | Random 32-byte | Required for iOS App Store |
| GitHub | `read:user user:email` | S256 | Random 32-byte | Developer audience |

### 2.5 MFA Considerations

| Decision | Status |
|----------|--------|
| MFA at launch (Phase 1-2) | **Deferred** — low-risk data (calculations), friction outweighs benefit |
| MFA for Phase 3+ | **Planned** — TOTP via Supabase Auth when premium/enterprise tier launches |
| MFA trigger | Enabled when user stores financial calculations or enables "high-security mode" |
| Implementation | Supabase Auth native TOTP (AAL2), backup codes (10x one-time) |

> **Decision:** MFA deferred to Phase 3 with clear implementation path. Not blocked.

---

## 3. OWASP Top 10 (2021) Review

| # | Category | CalcApp Risk | Status | Notes |
|---|----------|-------------|--------|-------|
| A01 | Broken Access Control | Medium | ✅ Mitigated | RLS on all tables with `auth.uid()`, no direct DB access from client |
| A02 | Cryptographic Failures | High | ✅ Mitigated | AES-256-GCM E2E, PBKDF2 (600k iterations) key derivation, TLS 1.3 |
| A03 | Injection | Low | ✅ Mitigated | PostgREST parameterized queries, no raw SQL from client, input validation |
| A04 | Insecure Design | Medium | ✅ Mitigated | This threat model, STRIDE per boundary, zero-knowledge architecture |
| A05 | Security Misconfiguration | Medium | ⚠️ Action Needed | Hardening checklist: disable Supabase dashboard in prod, rotate default keys |
| A06 | Vulnerable Components | Medium | ✅ Mitigated | Snyk + `dart pub outdated` in CI, weekly dependency scan |
| A07 | Auth Failures | High | ✅ Mitigated | GoTrue battle-tested, PKCE OAuth, token rotation, rate limiting (5 attempts/min) |
| A08 | Software & Data Integrity | Medium | ✅ Mitigated | Webhook signature validation, CI artifact signing, pubspec.lock pinning |
| A09 | Security Logging & Monitoring | Medium | ⚠️ Action Needed | Implement structured audit logging (Phase 2), Cloudflare analytics active |
| A10 | SSRF | Low | ✅ N/A | No user-supplied URLs processed server-side; all API endpoints are fixed |

### Action Items (A05, A09)

1. **A05:** Create Supabase production hardening runbook — disable Studio, restrict management API, enforce MFA on dashboard
2. **A09:** Deploy audit log table (Phase 2, Sprint 1), integrate Cloudflare Logpush to object storage

---

## 4. Data Protection

### 4.1 Data Classification

| Classification | Data Types | Encryption | Retention |
|---------------|-----------|-----------|-----------|
| **Confidential** | Calculation history, variables, expressions | E2E (AES-256-GCM) | User-controlled, delete on account removal |
| **Internal** | User profile (name, email), subscription status | At-rest (Supabase encryption) | Account lifetime + 30d post-deletion |
| **Public** | App metadata, feature flags | None required | Indefinite |

### 4.2 Encryption Architecture

| Layer | Method | Details |
|-------|--------|---------|
| **At Rest** | Supabase managed (AES-256, transparent) | Postgres TDE, encrypted backups |
| **In Transit** | TLS 1.3 | Cloudflare termination → Supabase (mTLS internal) |
| **End-to-End** | Client-side AES-256-GCM | Server stores only ciphertext; zero-knowledge |

### 4.3 E2E Encryption Flow

```
User Password → PBKDF2-SHA256 (600,000 iterations, 16-byte salt)
                    ↓
              Master Key (256-bit)
                    ↓
         ┌─────────┴─────────┐
         │                    │
    Data Encryption Key   Key Verification Hash
    (per-document AES key)    (stored server-side)
         │
    AES-256-GCM encrypt → ciphertext + 12-byte IV + auth tag
         │
    Store: { ciphertext, iv, tag, salt, key_id } → Supabase
```

### 4.4 Key Derivation Parameters

| Parameter | Value |
|-----------|-------|
| Algorithm | PBKDF2-HMAC-SHA256 |
| Iterations | 600,000 (OWASP 2023 recommendation) |
| Salt | 16 bytes, cryptographically random, per-user |
| Output | 256-bit master key |
| IV | 12 bytes random per encryption operation |
| Auth tag | 128-bit (GCM default) |

---

## 5. Secrets & Key Management

### 5.1 Secret Inventory

| Secret | Storage Location | Rotation Schedule | Access |
|--------|-----------------|-------------------|--------|
| Supabase service_role key | GitHub Secrets + Fly.io encrypted env | 90 days | CI/CD only, never in client |
| Supabase anon key | Client bundle (public, RLS-protected) | On compromise only | Public |
| JWT signing key (RS256) | Supabase managed (JWKS) | 180 days (automatic rotation) | Supabase internal |
| OAuth client secrets | GitHub Secrets → Supabase Auth config | 90 days | Supabase Auth only |
| RevenueCat API keys | GitHub Secrets + Fly.io encrypted env | 90 days | Server-side only |
| Cloudflare API token | GitHub Secrets | 90 days | CI/CD only |
| Database connection string | Supabase internal, Fly.io secrets | On credential rotation | App server only |

### 5.2 Secure Storage Architecture

```
┌─────────────────────────────────────────────────┐
│              Secret Storage Hierarchy             │
├─────────────────────────────────────────────────┤
│ Layer 1: Fly.io Secrets (fly secrets set)       │ ← Runtime secrets
│ Layer 2: GitHub Actions Secrets                  │ ← CI/CD secrets
│ Layer 3: Supabase Vault (Phase 3)               │ ← DB-level secrets
│ Layer 4: flutter_secure_storage                  │ ← Client tokens
└─────────────────────────────────────────────────┘
```

> **No plain environment variables.** All secrets stored in platform-managed encrypted stores:
> - **Fly.io:** `fly secrets set` (encrypted at rest, injected at runtime, never in Dockerfile)
> - **GitHub:** Repository/Organization Secrets (encrypted, accessible only in Actions)
> - **Phase 3:** Migrate to Supabase Vault (Postgres-native, audit logged)

### 5.3 Emergency Revocation Procedure

| Scenario | Response Time | Action |
|----------|--------------|--------|
| JWT signing key compromised | < 1 hour | Rotate JWKS, invalidate all sessions, force re-auth |
| Service role key leaked | < 30 min | Regenerate in Supabase dashboard, update Fly.io secrets, redeploy |
| OAuth secret compromised | < 2 hours | Revoke at provider, regenerate, update config |
| User encryption key compromised | User-initiated | Password change triggers re-encryption of all user data |
| Database credentials leaked | < 30 min | Rotate via Supabase, restart pooler connections |

### 5.4 Pre-Commit Secret Scanning

- **Tool:** gitleaks (pre-commit hook + CI)
- **Config:** `.gitleaks.toml` with custom rules for Supabase patterns
- **CI gate:** PR blocked if secrets detected
- **Baseline:** `gitleaks detect --baseline-path .gitleaks-baseline.json`

---

## 6. Compliance

### 6.1 GDPR (EU)

| Requirement | Implementation |
|-------------|---------------|
| Lawful basis | Consent (account creation) + Contract (service delivery) |
| Data minimization | Only email + calculation data; no analytics PII |
| Right to access (Art. 15) | Export endpoint: `GET /api/v1/user/export` → JSON dump |
| Right to erasure (Art. 17) | Delete endpoint: `DELETE /api/v1/user` → cascade delete + 30d backup purge |
| Right to portability (Art. 20) | Same export endpoint, machine-readable JSON |
| Data Processing Agreement | Supabase DPA signed, Cloudflare DPA signed |
| Cross-border transfers | Supabase (US/EU region selectable), Cloudflare (Privacy Shield successor) |
| Breach notification | 72hr window, automated detection → security@calcapp.io → DPA |

### 6.2 CCPA (California)

| Requirement | Implementation |
|-------------|---------------|
| Right to know | Same export endpoint as GDPR |
| Right to delete | Same deletion flow as GDPR |
| Right to opt-out of sale | N/A — CalcApp does not sell data |
| Non-discrimination | No service degradation for privacy requests |
| Privacy policy | In-app link + website, updated annually |

### 6.3 App Store Requirements

| Platform | Requirement | Compliance |
|----------|------------|-----------|
| Apple (iOS) | Privacy Nutrition Labels | Declared: email, name, usage data (linked) |
| Apple (iOS) | App Tracking Transparency | No tracking → no ATT prompt needed |
| Apple (iOS) | Sign in with Apple | Implemented (mandatory if other social logins) |
| Google Play | Data Safety Section | Declared: email, name, encrypted calculations |
| Google Play | Data deletion option | In-app account deletion + support email |
| Both | Encryption declaration | Yes — declared use of standard encryption (AES-256) |

### 6.4 Data Processing Summary

| Processor | Data Shared | Purpose | DPA |
|-----------|------------|---------|-----|
| Supabase | Encrypted calculations, email, profile | Primary backend | ✅ Signed |
| Cloudflare | IP addresses (transient), request metadata | CDN, WAF, DDoS | ✅ Signed |
| RevenueCat | User pseudonymous ID, subscription status | Subscription management | ✅ Signed |
| Google/Apple/GitHub | Email, OAuth profile | Authentication | Provider ToS |

---

## 7. Security Testing Plan

### 7.1 Static Analysis (SAST)

| Tool | Target | Frequency | Gate |
|------|--------|-----------|------|
| `dart analyze` | Flutter codebase | Every PR | 0 errors, 0 warnings |
| Snyk Code | Dart + SQL | Every PR | No high/critical findings |
| gitleaks | All committed files | Pre-commit + PR | 0 secrets detected |
| semgrep | Custom rules (auth patterns) | Weekly scheduled | Report to security channel |

### 7.2 Dependency Scanning (SCA)

| Tool | Target | Frequency | Gate |
|------|--------|-----------|------|
| Snyk Open Source | pubspec.lock | Every PR + daily | No critical unpatched (7d SLA) |
| `dart pub outdated` | Dart packages | Weekly | No packages > 2 major versions behind |
| GitHub Dependabot | All dependencies | Continuous | Auto-PR for security patches |
| Supabase advisory check | Postgres extensions | Monthly | Review + patch within 14d |

### 7.3 Dynamic Analysis (DAST)

| Tool | Target | Frequency | Gate |
|------|--------|-----------|------|
| OWASP ZAP (baseline scan) | API endpoints | Weekly (CI) | No medium+ findings |
| OWASP ZAP (full scan) | All endpoints + auth flows | Monthly | No high+ findings |
| Burp Suite (manual) | Auth, sync, subscription flows | Quarterly | Findings triaged within 7d |
| Nuclei | Infrastructure (Supabase, Cloudflare) | Monthly | No critical misconfigurations |

### 7.4 Penetration Testing

| Type | Scope | Frequency | Provider |
|------|-------|-----------|----------|
| Automated pen test | Full API surface | Quarterly | Internal (ZAP + Nuclei + custom scripts) |
| Manual pen test | Auth, E2E encryption, RLS bypass | Annually | External firm (budget: Phase 3) |
| Bug bounty | Full application | Phase 3+ | Platform TBD (HackerOne/Intigriti) |

### 7.5 Security Testing in CI/CD Pipeline

```yaml
# .github/workflows/security.yml (simplified)
security-scan:
  steps:
    - gitleaks detect --report-format sarif
    - dart analyze --fatal-infos
    - snyk test --severity-threshold=high
    - snyk code test
    - owasp-zap-baseline-scan (staging URL)
  gate: ALL must pass for merge to main
```

---

## 8. Incident Response

### 8.1 Severity Levels

| Level | Definition | Examples | Response Time | Resolution Target |
|-------|-----------|----------|---------------|-------------------|
| **SEV-1 (Critical)** | Active exploitation, data breach, full system compromise | RLS bypass with data exfil, JWT signing key leaked publicly | < 15 min acknowledge | < 4 hours contain |
| **SEV-2 (High)** | Vulnerability with clear exploit path, partial data exposure | Auth bypass (no confirmed exploit), unencrypted data in logs | < 1 hour | < 24 hours |
| **SEV-3 (Medium)** | Potential vulnerability, no confirmed exploit, limited scope | Outdated dependency with known CVE, misconfigured CORS | < 4 hours | < 7 days |
| **SEV-4 (Low)** | Informational, hardening opportunity, no immediate risk | Missing security header, verbose error messages | < 24 hours | Next sprint |

### 8.2 Response Procedures

**Phase 1 — Detection & Triage (0-15 min)**
1. Alert received (Cloudflare, Supabase logs, user report, automated scan)
2. On-call engineer assesses severity using matrix above
3. Create incident channel, assign Incident Commander (IC)

**Phase 2 — Containment (15 min - 4 hr)**
1. SEV-1/2: Revoke compromised credentials immediately
2. Enable enhanced logging on affected systems
3. If data breach: snapshot affected tables, preserve evidence
4. Block attacker IP/token via Cloudflare WAF rule
5. Disable affected feature if necessary (feature flag kill switch)

**Phase 3 — Eradication & Recovery (4-48 hr)**
1. Root cause analysis (5 Whys)
2. Deploy fix to staging → verify → production
3. Rotate all potentially affected secrets
4. Verify RLS policies intact, run policy test suite
5. Re-enable disabled features after verification

**Phase 4 — Post-Incident (48-72 hr)**
1. Blameless post-mortem document
2. Update threat model if new threat identified
3. Add regression test for the exploit vector
4. Update this security design if architecture changes
5. Notify affected users if data breach (per GDPR 72hr)

### 8.3 Communication Plan

| Audience | Channel | Timing | Content |
|----------|---------|--------|---------|
| Engineering team | Slack #incidents | Immediate | Technical details, actions needed |
| Leadership | Email + Slack DM | < 1 hour (SEV-1/2) | Impact summary, ETA, resource needs |
| Affected users | In-app notification + email | < 72 hours (if breach) | What happened, what we did, what to do |
| Regulators (GDPR) | Formal notification | < 72 hours (if breach) | Data subjects affected, measures taken |
| Public (if warranted) | Blog/status page | After containment | Transparent summary, no technical exploit details |

### 8.4 Incident Contacts

| Role | Primary | Backup |
|------|---------|--------|
| Incident Commander | Engineering Lead | CTO |
| Security Lead | Security Engineer | Senior Backend Dev |
| Communications | Product Manager | Founder |
| Legal/Compliance | External counsel | — |

---

## Appendix: Security Checklist (Pre-Launch Gate)

- [ ] All STRIDE mitigations implemented and verified
- [ ] RLS policies tested with multi-tenant test suite
- [ ] gitleaks pre-commit hook installed on all dev machines
- [ ] Snyk integration active on repository
- [ ] OWASP ZAP baseline scan passes clean
- [ ] OAuth PKCE verified for all providers
- [ ] Certificate pinning configured and tested
- [ ] flutter_secure_storage confirmed on both platforms
- [ ] Supabase production project hardened (Studio disabled, keys rotated)
- [ ] Privacy policy and data deletion flow functional
- [ ] Incident response contacts verified and reachable
- [ ] Cloudflare WAF rules active (rate limiting, bot protection)
- [ ] Audit logging table deployed and write-tested
- [ ] Backup encryption verified (restore test performed)
