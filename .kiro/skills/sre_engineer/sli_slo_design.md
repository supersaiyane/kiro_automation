---
id: sli_slo_design
version: 1.0.0
owners: [sre_engineer]
tags: [slo, sli, sla, error-budget, observability]
when_to_use: |
  A service is going (or already in) production and needs measurable
  reliability targets that drive engineering trade-offs.
inputs:
  - user_journeys: critical paths through the service
outputs:
  - slos: per-journey SLI + target + alerting threshold
---

# SLI / SLO Design

**SLI** (Service Level Indicator) — what we measure: latency, error rate,
availability, freshness. Pick at most 2-3 per service.

**SLO** (Service Level Objective) — the target on that SLI over a window.
Example: "99.9% of /search requests return 200 in <300ms over 30 days."

**Error budget** = 100% − SLO. With 99.9% over 30 days, the budget is
~43 min of unavailability. Spend it on shipping; if you've burned it,
freeze launches and fix reliability.

**Method**
1. Write each user journey as a sentence. "User logs in." "User searches."
2. For each, pick an SLI that the user cares about (not CPU usage).
3. Set the SLO conservatively at first. 99.9% is hard. Don't promise
   99.99% on day one.
4. Alert at burn rate ≥ 2x the budget over a short window (5-15 min)
   AND at total budget consumption (e.g. 50% used at 25% through window).

**Anti-patterns**
- SLOs that measure the system (CPU, queue depth) instead of the user
  experience (request success, latency).
- SLOs without an alerting policy = SLOs that don't exist.
- SLO targets identical to the SLA — no margin for routine issues.
