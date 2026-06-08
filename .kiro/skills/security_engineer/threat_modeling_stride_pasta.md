---
id: threat_modeling_stride_pasta
version: 1.0.0
owners: [security_engineer, architect]
tags: [threat-modeling, stride, pasta, dread, attack-trees, mitre-attack]
when_to_use: |
  Any new feature, service, or architectural change crossing a trust
  boundary (network, account, tenant, role). A threat model done EARLY
  costs hours; done AFTER an incident it costs careers. Pair with the
  architect's design and re-run at every significant change.
inputs:
  - architecture_diagram, data_flow, trust_boundaries, asset_inventory
outputs:
  - "threat_model: assets + entry points + threats per category + ratings + mitigations + residual risk"
---

# Threat Modeling — STRIDE / PASTA / Attack Trees

> "We didn't think about that" is the most expensive sentence in
> security. Threat modeling is the discipline of thinking about it
> BEFORE you ship — systematically, with a framework, every time.

## Pick the right framework for the job

| Framework | Best for | Output |
|---|---|---|
| **STRIDE** (Microsoft) | Per-component threat enumeration | Threats grouped by category |
| **PASTA** (Process for Attack Simulation) | Risk-driven business view | Attack scenarios tied to business impact |
| **DREAD** | Scoring/prioritization | Ranked risk list |
| **Attack Trees** (Schneier) | Specific high-value attack scenarios | Hierarchical attack paths |
| **MITRE ATT&CK** | Real-world adversary TTPs | Catalog of techniques to defend against |

Default for product engineering: **STRIDE** for breadth + **Attack Trees** for
the 3-5 highest-impact scenarios. PASTA for regulated industries that need
business-risk language for execs.

## STRIDE — six categories per asset/boundary

| Letter | Threat | Property violated | Example |
|---|---|---|---|
| **S** | Spoofing | Authentication | Forged session cookie |
| **T** | Tampering | Integrity | SQL injection modifies DB |
| **R** | Repudiation | Non-repudiation | User denies action; no audit log |
| **I** | Information disclosure | Confidentiality | Stack trace leaks DB schema |
| **D** | Denial of service | Availability | Slowloris on API endpoint |
| **E** | Elevation of privilege | Authorization | IDOR; user accesses other tenant's data |

For every component + every data flow + every trust boundary, ask: "what's the S? what's the T? …"

## The 4-step process (Adam Shostack)

```
1. What are we building?     → Diagram with trust boundaries
2. What can go wrong?        → STRIDE per element
3. What are we going to do?  → Mitigations + accepted risks
4. Did we do a good job?     → Validation tests, red team
```

Most teams skip step 4. Without validation, the threat model is decoration.

## Data flow diagram (DFD) — the foundation

```
[External User]
       │ HTTPS
       ▼
═══════ trust boundary (internet edge) ═══════
   [Load balancer / WAF]
       │ HTTPS
       ▼
═══════ trust boundary (VPC edge) ═══════
   [API service]──gRPC─→[Auth service]
       │                    │
       │                    └─→[Identity DB]
       ▼
   [Orders DB]
```

Every line crossing `═══` is a place where STRIDE applies.

## Attack trees — for high-value scenarios

```
GOAL: Steal customer credit cards
├── Compromise the database
│   ├── SQL injection on /search
│   ├── Compromise DB admin credentials
│   │   ├── Phish DBA's laptop
│   │   ├── Steal SSH key from CI runner
│   │   └── Find creds in public git history
│   └── Exploit DB CVE
├── Intercept in transit
│   ├── MITM TLS (cert pinning bypass)
│   └── Compromise upstream TLS vendor
├── Access decrypted memory
│   ├── Memory scrape from app process
│   └── Container escape from co-tenant
└── Social engineer customer service
```

Each leaf gets cost + skill required + likelihood. Defend the cheapest /
highest-likelihood leaves first.

## Risk scoring (DREAD or qualitative)

```
DREAD per threat:
  Damage         (0-10) — how bad if exploited
  Reproducibility(0-10) — how easy to repeat
  Exploitability (0-10) — skill required
  Affected users (0-10) — % of users impacted
  Discoverability(0-10) — how easy to find

Total /50 → risk tier
```

Quantitative is hard to calibrate; many teams use qualitative
(Critical/High/Med/Low) with documented rubrics. Either works; CONSISTENCY
matters more than precision.

## MITRE ATT&CK — adversary realism

For the highest-risk scenarios, map to ATT&CK techniques:

```
Initial Access: T1190 (Exploit public-facing app)
  → mitigation: WAF + dependency scanning
Persistence: T1505.003 (web shell)
  → mitigation: file integrity monitoring
Privilege Escalation: T1078.004 (cloud IAM)
  → mitigation: permission boundaries
Exfiltration: T1567 (web service)
  → mitigation: egress allowlist
```

ATT&CK forces you to think like an attacker chains techniques, not just
"one bug at a time."

## Outputs — the documents auditors and engineers BOTH want

1. **Diagram** — DFD with trust boundaries.
2. **Threat list** — per-element STRIDE table.
3. **Top 5 attack trees** for the highest-value assets.
4. **Mitigation map** — every threat → owner + status (mitigated / accepted /
   in-progress / can't-mitigate).
5. **Residual risk register** — what we accept and why, sign-off named.
6. **Validation plan** — pen tests, automated checks, red team objectives.

Templates: `threat_dragon` (OWASP), Microsoft Threat Modeling Tool,
IriusRisk, hand-drawn + Markdown.

## When to re-run

- New feature crossing a trust boundary (always)
- New service or microservice
- Dependency or major lib upgrade with security impact
- Architectural changes (new region, new auth flow)
- Annually (calendared) for stable systems
- After every security incident (lessons-learned input)

## Anti-patterns

- **One-time exercise.** Threat models go stale; calendar it.
- **Pure checklist.** STRIDE is a STARTER not the goal. Adversary thinking
  matters more than category coverage.
- **No mitigation owner.** Threats without owners aren't mitigations.
- **Security team alone.** Threat modeling is BEST with the engineering
  team in the room — they know the surface.
- **Ignoring assumed-trusted internal paths.** "It's behind the firewall"
  is not a mitigation in 2026. Apply STRIDE inside too (zero trust).
- **Threats without context.** "SQL injection" is not specific. "SQL
  injection on /api/search via the `q` parameter, against the orders
  database" IS.

## Validation that the threat model is real

- [ ] Every trust boundary in the architecture has a STRIDE entry.
- [ ] At least 3 attack trees exist for the highest-value assets.
- [ ] Every High/Critical threat has an owner + due date OR risk-accept
      with sign-off.
- [ ] Last quarterly review happened ≤ 90 days ago.
- [ ] Pen test scope covers the top 5 attack-tree leaves.
- [ ] Red team objective from last drill maps to a threat-model entry.
