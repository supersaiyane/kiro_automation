---
id: red_blue_purple_team_operations
version: 1.0.0
owners: [security_engineer]
tags: [red-team, blue-team, purple-team, pen-test, adversarial, mitre-attack]
when_to_use: |
  After your AppSec + IR baselines exist. Red / blue / purple team
  exercises pressure-test defensive controls against realistic
  adversary behavior. Audits ask if you do them; mature programs do.
inputs:
  - existing_controls, threat_model, in_scope_assets
outputs:
  - "team_program: cadence + scope + rules of engagement + findings + retest"
---

# Red / Blue / Purple Team Operations

> "We didn't think they'd do that" is not a defense. Adversary
> emulation tells you what your controls actually catch — before a
> real attacker tells you for free.

## The three flavors

| Flavor | Mindset | Output |
|---|---|---|
| **Red Team** | Attacker; achieve objective by any means | Did we get in? What did we get? |
| **Blue Team** | Defender; detect + respond | Did we detect? How fast? |
| **Purple Team** | Collaborative; red + blue together | Tuning loop: improve detection per technique |

A mature program runs all three with increasing frequency:
- Annual full red team (external firm).
- Quarterly purple team (in-house).
- Continuous blue (SOC + automated detection).

## Pen test vs red team — different goals

| Pen test | Red team |
|---|---|
| Find as many vulns as possible | Achieve a specific objective |
| Scoped systems | Whole company often in scope |
| Hours-days | Weeks-months |
| Loud + obvious | Stealthy + persistent |
| Result: vuln report | Result: did we get to the crown jewels? |

Both are useful; they answer different questions.

## Rules of engagement (ROE)

ALL red-team work needs documented ROE before kickoff:

- **Scope** — which IPs, domains, accounts, physical sites.
- **Out of scope** — production data destruction, customer impact, real
  ransomware, real DoS.
- **Objectives** — "exfil 'sensitive' from prod" or "obtain domain admin".
- **Allowed techniques** — phishing yes/no, physical yes/no, social
  engineering of employees yes/no.
- **Communication path** — single point of contact ("trusted agent") who
  knows the engagement is live; can call stop.
- **Escape hatch** — what triggers immediate stop (real incident, ROE
  breach).
- **Evidence collection** — what's captured, retention, who sees it.
- **Legal cover** — written authorization signed by an officer of the
  company.

Without ROE, you're indistinguishable from a real attacker. Hand the ROE
to law enforcement if needed.

## Adversary emulation frameworks

Plan campaigns to mirror specific adversaries:

| Framework | Source | Use |
|---|---|---|
| **MITRE ATT&CK** | MITRE | Catalog of techniques (T1XXX IDs) |
| **MITRE ATT&CK Navigator** | MITRE | Visualize coverage by technique |
| **Atomic Red Team** | Red Canary | Pre-built tests per technique |
| **Caldera** | MITRE | Automated adversary emulation |
| **Sliver / Cobalt Strike / Mythic / Havoc** | Commercial / OSS | C2 frameworks |
| **PurpleSharp / SilentTrinity** | Various | Open-source post-exploitation |

Pick 1-3 specific threat actor profiles you care about (e.g. APT29 for
nation-state, FIN7 for financial, ransomware affiliates) and emulate their
known TTPs.

## Purple team cadence (the high-leverage pattern)

Monthly or per-sprint:

```
1. Pick 5-10 ATT&CK techniques.
2. Red side: execute each (Atomic Red Team).
3. Blue side: review SIEM/EDR — did we alert? With useful context?
4. Together: per technique, score:
     DETECTED + ALERTED + ACTIONABLE  → ✓
     DETECTED + ALERTED + NOISE       → tune
     DETECTED + NOT ALERTED           → alert rule
     NOT DETECTED                     → telemetry gap
5. Document gaps + fixes; close in next cycle.
6. Update ATT&CK Navigator coverage map.
```

Result: detection coverage measurably improves quarter over quarter.

## Common red-team techniques to test

Per ATT&CK kill chain:

| Phase | Technique | Test |
|---|---|---|
| Initial Access | Phishing (T1566) | Internal phishing campaign quarterly |
| Initial Access | Public-facing app exploit (T1190) | External pen test annually |
| Execution | Cmd interpreter (T1059) | Drop suspicious binary, check EDR |
| Persistence | Scheduled task (T1053) | Add a task; does EDR catch? |
| Priv Esc | Cloud IAM (T1078.004) | Token-from-instance-metadata abuse |
| Defense Evasion | Indicator removal (T1070) | Modify auth logs; does monitor catch? |
| Credential Access | OS credential dumping (T1003) | LSASS dump; EDR catches? |
| Discovery | Account enumeration (T1087) | `net user /domain`; SIEM alerts? |
| Lateral Movement | RDP / SSH abuse (T1021) | Lateral hop; network monitor catches? |
| Collection | Data from local system (T1005) | Mass-read sensitive paths |
| Exfiltration | Cloud storage upload (T1567) | Push 1GB to attacker bucket |
| Impact | Data encrypted (T1486) | Simulated ransomware (CAREFULLY) |

Don't try to cover all 200+ techniques at once. Prioritize by relevance to
your threat model.

## Tabletop exercises (for response, not detection)

Adjacent skill: see SRE's `incident_command_system`. Tabletop is a paper
simulation of a scenario — "imagine someone clicked the phish, now what?"

Cadence: quarterly. Different scenarios:
- Ransomware in production.
- Supply chain compromise (SolarWinds-style).
- Insider data exfil.
- Cloud account compromise.
- Customer data breach with regulatory notification.

Roles: IC, ops, comms, legal, exec sponsor. Time-box 90 min. Output:
action items.

## Bug bounty as continuous external red team

If your scope is rich + your team has triage capacity:

- HackerOne / Bugcrowd / Intigriti.
- Pre-launch: internal AppSec mature.
- Scope: clear in-scope assets, out-of-scope (test env, third-party).
- Payouts: match industry (Critical $5k-$20k+).
- Triage SLO: acknowledge 24h, decision 7d.
- Use findings as red-team intel for purple team cycles.

## Defense maturity tiers (where you are matters)

Tier 1 — Foundational:
- Basic SAST + DAST.
- Annual pen test.
- IR runbook.

Tier 2 — Active:
- SIEM + EDR with tuned alerts.
- Annual external red team.
- Quarterly tabletop.
- Detection-as-code (Sigma rules in git).

Tier 3 — Mature:
- Continuous purple team.
- Threat intel feed integration.
- Adversary-specific emulation.
- Active threat hunting.
- Bug bounty.

Tier 4 — Industry-leading:
- In-house red team (full-time).
- Custom adversary emulation tooling.
- Detection engineering team.
- Deception (honeypots, canary tokens) deployed.

Most mid-sized orgs should aim for Tier 2-3. Tier 4 is for high-target
industries (defense, finance, big tech).

## Anti-patterns

- **Pen test only.** Compliance check-the-box; doesn't improve detection.
- **No ROE.** Real legal risk; engagement chaos.
- **Red team without blue.** Findings without remediation = decoration.
- **Skipping retest.** "Fixed" without verification often isn't.
- **Same scope every year.** Adversaries don't honor previous scopes.
- **Tools without process.** Buying Cobalt Strike doesn't make you a red
  team.
- **No cross-functional debrief.** Findings stay in security; eng never
  sees them.
- **One-off team, never integrated.** Hand-off problem; results don't
  drive change.

## Validation

- [ ] Annual external red team / pen test completed within last 12 months.
- [ ] Quarterly tabletop exercises run with named participants.
- [ ] Purple team cadence established (monthly or per-sprint).
- [ ] ATT&CK Navigator showing detection coverage delta over time.
- [ ] Findings tracked in same backlog as engineering work.
- [ ] Retest verified critical fixes from last engagement.
- [ ] Bug bounty (or equivalent external program) running if scope is
      mature.
