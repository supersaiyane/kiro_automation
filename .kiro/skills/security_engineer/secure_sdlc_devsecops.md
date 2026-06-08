---
id: secure_sdlc_devsecops
version: 1.0.0
owners: [security_engineer, backend_lead, devops_engineer]
tags: [secure-sdlc, devsecops, shift-left, secure-coding, security-champions]
when_to_use: |
  Embedding security into the development lifecycle, not as a bolt-on
  before launch. Done well, security work becomes engineering work; done
  badly, security is a gate everyone resents.
inputs:
  - sdlc_topology, eng_team_size, current_friction
outputs:
  - "secure_sdlc_program: per-phase controls + champion network + metrics + culture"
---

# Secure SDLC + DevSecOps

> Security teams won't scale to review every PR; engineers won't tolerate
> security as a bottleneck. The fix is making security the easy default
> — tooling, templates, training — and reserving security review for the
> 5% that needs it.

## The 6-phase SDLC + security touchpoints

```
1. PLAN          → threat model, abuse cases, security stories
2. DESIGN        → architecture review, security ADR
3. IMPLEMENT     → secure code, SAST, secret scanning
4. TEST          → DAST, IAST, pen test, fuzzing
5. DEPLOY        → IaC scan, image signing, admission
6. OPERATE       → monitoring, IR, patch management, threat hunt
```

Each phase has its own controls and deliverables.

## Phase 1 — Plan (the cheapest hour you'll spend)

Inputs:
- Feature spec / RFC
- Sensitive data involved
- New trust boundaries

Outputs:
- Brief threat model (cross-ref `threat_modeling_stride_pasta`)
- Security acceptance criteria added to user stories
- Abuse cases: "Attacker tries to X → app must Y"

When to engage security team:
- New trust boundary
- New auth flow
- PII handling
- Regulatory data (PHI, PCI, etc.)
- External-facing API

Trigger via PR template checklist or eng-managed gate.

## Phase 2 — Design

Outputs:
- Security ADR for major decisions:
  - Auth model (RBAC / ABAC / ReBAC)
  - Crypto choice + key management
  - Data classification + storage
  - Failure modes (fail-open vs fail-closed)

Reviewer: security architect signs off when:
- New region / data residency
- New SSO or auth provider
- New PII collection
- Multi-tenant data architecture

For typical features: lightweight design checklist suffices.

## Phase 3 — Implement (the developer's daily reality)

Controls applied per commit:

| Control | Tool | When |
|---|---|---|
| **Secret scanning** | git-secrets, TruffleHog, GitGuardian | Pre-commit + CI |
| **SAST** | Semgrep, CodeQL, SonarQube | Pre-merge |
| **SCA** | Dependabot, Renovate, Snyk | Pre-merge |
| **Linter security rules** | Bandit (Py), ESLint security plugins, gosec | Pre-merge |
| **IaC scanning** | Checkov, tfsec, Trivy | Pre-merge |

Developer experience is paramount. Tools must:
- Run < 60 seconds in CI.
- Pre-merge feedback only on changed files (no legacy noise).
- Suppression mechanism with comment-why.
- Auto-fix where possible.

## Secure coding standards — pick one, enforce it

Pick by language:

| Language | Standard |
|---|---|
| Java | CERT Oracle Secure Coding Standard |
| C / C++ | CERT C, MISRA |
| Python | PEP 8 + bandit rules |
| JS / TS | OWASP JS guide + ESLint security |
| Go | Go security checklist |
| Rust | Rust security advisories DB |

Codify in linter config. Document in eng-handbook.

## Phase 4 — Test

Tests added by engineers:
- **Auth tests** — unauthenticated request → 401; wrong tenant → 403.
- **Authz tests** — IDOR (user A accessing user B's resource → 403/404).
- **Input validation tests** — invalid schema → 400/422.
- **Rate limit tests** — burst pattern → 429.

Tests run by security:
- **DAST** on staging deploy.
- **Pen test** annually or per major release.
- **Fuzz tests** on parsers + serializers.

## Phase 5 — Deploy

- **Image signing** (cosign keyless OIDC, cross-ref supply chain skill).
- **Admission control** verifies signature + base image.
- **IaC** all peer-reviewed, scanned, applied via GitOps.
- **Secrets** never in deploy manifests — externalized.

## Phase 6 — Operate

- **Monitoring** for anomaly (auth-fail spike, error spike, traffic
  anomaly).
- **Threat hunting** weekly per hypothesis.
- **Patch management** SLA-driven.
- **Incident response** drilled quarterly.

## Security champions — the network model

Don't try to put security people in every team. Instead:

- **1 champion per eng team** (volunteer, security-curious engineer).
- **Monthly champion sync** with security team.
- **Champion responsibilities**:
  - First reviewer for security-touching PRs in their team.
  - Triages SAST / SCA findings.
  - Runs the team's annual threat model.
  - Advocates for security training adoption.

Recognition: title, swag, learning budget. Budget time (10-20% of capacity).

Scaling: 10 champions cover ~100 engineers — sustainable.

## Security training cadence

- **All-hands annual** — phishing awareness, social engineering, data
  handling.
- **Role-specific quarterly** — secure coding for devs, IR for ops,
  privacy for support.
- **Champion training** — deeper, biannual.
- **Phishing drills** — monthly; results published (counts only, not
  names).

Tools: KnowBe4, Hoxhunt, Curricula. Or roll your own.

## Metrics that matter

| Metric | Target | What it tells you |
|---|---|---|
| Time-to-fix (TTF) critical SAST | < 7d | DevSecOps tightness |
| % PRs with security review | track | Coverage |
| % services with threat model | > 80% | Coverage |
| Phishing click rate | < 5% | Training effectiveness |
| MTTR for security incidents | < 24h (sev-1) | Response capacity |
| % findings auto-remediated | track | Automation maturity |

Don't chase vanity metrics ("vuln count"). Optimize for FLOW (TTF) +
OUTCOMES (incidents prevented + handled fast).

## Anti-patterns

- **Security as a gate at the end** — slow + adversarial. Shift left.
- **Tools without process** — Snyk dashboard with 5000 unaddressed
  findings is decoration.
- **One central security team for everything** — bottleneck.
- **Mandatory pre-merge security review** for every PR — engineering
  pause. Trigger only on touch.
- **No suppression mechanism** — devs work around scanner instead of
  marking false positives.
- **Training every quarter, no role-specific** — wasted time.
- **No security champion program** — security stays "their problem."
- **Findings without owners** — they sit forever.

## Cultural — what to AVOID saying

| Don't | Do |
|---|---|
| "Security says no" | "Here's what we need to ship safely" |
| "All vulns are critical" | Risk-rate; prioritize |
| Block-merge surprise gates | Document gates; predictable friction |
| Findings in a vacuum | Tie to threat model — why it matters |
| "Just disable that feature" | Compensating control with sunset |

## Validation

- [ ] Threat modeling required for new high-risk features (documented gate).
- [ ] SAST + SCA + secret scanning on every PR; < 60s feedback.
- [ ] Security champion network covers every eng team.
- [ ] Annual + quarterly training completed by > 95% of staff.
- [ ] Pen test annually + per major release.
- [ ] Findings tracked with owner + SLA + dashboard.
- [ ] Phishing drill click rate < 5%.
- [ ] Quarterly metrics reviewed by eng + security leadership together.
