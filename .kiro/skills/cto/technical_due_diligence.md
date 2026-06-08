---
id: technical_due_diligence
version: 1.0.0
owners: [cto]
tags: [diligence, acquisition, investment, risk, audit]
when_to_use: |
  Evaluating an acquisition target, a strategic vendor, or a candidate
  open-source dependency we'd take a hard runtime dependency on.
  Output is a written verdict: invest / pass / conditional.
inputs:
  - target: company or codebase under review
  - access_level: read-only repos / interviews / production data
outputs:
  - dd_report: risk-scored sections + conditions for proceeding
---

# Technical Due Diligence

Six axes. Score each 1–5 with evidence. Total ≥21 = green; 15–20 = yellow
(conditions); ≤14 = pass.

## 1. Code health
- Repo size + commit cadence over 24 months. Spiky cadence with long
  silences = key-person risk.
- **`git shortlog -sn`** — bus factor. If 80% of the codebase is one
  author, that's an open chapter, not a moat.
- Test coverage trend (not just the number — the **trend**). Declining
  coverage on rising codebase is the smoke.
- Static analysis: `bandit`, `semgrep --config=auto`, `pip-audit`.
  Three critical CVEs in transitive deps = a culture signal, not a fix.
- Tech debt log. **No log** is worse than a long log; means they don't
  see it.

## 2. Architecture
- Read the *real* system diagram, not the slide. Pull it from the
  service registry / Terraform plan / k8s manifests.
- Coupling: how many services share a database? Shared DB = no real
  service boundaries.
- Stateful vs stateless: every stateful service is an on-call burden.
  Count them.
- **Single points of failure**: a DNS provider, a single Postgres
  primary, a single key signer. Each is a real risk row.

## 3. Operations
- Pull the last 12 months of incidents + postmortems. **No postmortems
  = a culture that does not learn.**
- MTTR trend. Rising MTTR with falling incident count is a worse signal
  than rising incident count.
- On-call rotation health: pages per person per week, p95 ack time,
  alert-to-incident ratio. >5:1 noise ratio = alert fatigue.
- DR test cadence. "We have backups" is not a DR plan.

## 4. Security & compliance
- Existing certifications (SOC 2 Type II, ISO 27001, HIPAA). Type I is
  nearly worthless for diligence.
- Last pen test date + remediation cadence. Findings open >90 days = red.
- Secret rotation policy + evidence it's followed. Grep their repos
  for `AKIA*`, `sk_live_*`, `BEGIN PRIVATE KEY`.
- Subprocessor list. Each one is a data-residency + breach-blast-radius
  question.

## 5. Team
- Tenure distribution. 0-1 yr median = post-acquisition flight risk.
- Senior engineer ratio. <20% senior in a 50+ team = scaling stalled.
- Hiring funnel health. Open seats > 6 months is structural.
- Documentation discipline. Onboarding-week docs exist? Architecture
  docs current within 6 months?

## 6. Strategic alignment
- Public roadmap vs. internal roadmap. Discrepancy reveals what they're
  actually optimizing.
- Customer concentration. Top customer >25% of revenue = a
  revenue-risk paragraph, not a line.
- License posture: dual-licensed OSS components, copyleft contagion,
  trademark policies. One AGPL contamination kills a closed-source
  acquisition outcome.

## Conditions language

When you say "conditional", be specific:
- "Acceptable if: top-3 SPOFs eliminated within 90 days post-close."
- "Acceptable if: bus-factor authors stay 24 months + sign IP
  assignments."
- "Acceptable if: outstanding critical CVEs remediated pre-close."

Conditions are contractual. Soft language ("we'd like to see…") gets
dropped in negotiation.

## Anti-patterns

- Reading the architecture slide and not the actual infrastructure.
- Scoring on stated process ("we do code review") rather than evidence
  (`git log --merges | grep "approved-by"`).
- Skipping the team axis because "we'll keep them all." 30% leave
  within 12 months of acquisitions; plan for it.
- A green DD report with no risk register. Every yes had reasons not
  to be — write them down.
