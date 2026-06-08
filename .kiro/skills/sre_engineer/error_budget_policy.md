---
id: error_budget_policy
version: 1.0.0
owners: [sre_engineer]
tags: [slo, error-budget, policy, reliability, feature-vs-stability]
when_to_use: |
  Once SLOs are defined (skill: sli_slo_design), the error budget
  is the mechanism that makes them actionable. Without a policy
  attached, SLOs are decoration.
inputs:
  - slos: from sli_slo_design
  - business_context: how risk-tolerant is the org?
outputs:
  - error_budget_policy: signed agreement on what triggers what
---

# Error Budget Policy

## What it is

The error budget = 100% − SLO. It's the **allowance for unreliability**
in a window (usually 30 days). The *policy* is the agreement between
SRE and product about what happens as the budget is consumed.

Without a policy:
- SLOs become aspirational.
- Reliability work loses every prioritization battle to features.
- SREs become the "no" team.

## The four budget states

Tie each to a defined action:

| Budget remaining | State | Actions |
|---|---|---|
| > 100% (over-performing) | **Healthy with slack** | Accept more risk: ship faster, larger canary steps, dev-team self-deploy |
| 50-100% | **Healthy** | Normal velocity; standard gates |
| 0-50% | **Drawdown** | Increase scrutiny: tighten canary, require senior approval for risky deploys, prioritize reliability stories at the next planning |
| < 0 (burned) | **Frozen** | Feature deploys halt. Only reliability fixes + sec hotfixes. SLO review meeting scheduled. |

Sign the policy. Print it. Reference it in incident retros. Without
signatures, "frozen" gets ignored.

## Burn-rate alerts (not just consumption)

A 30-day budget can be **consumed in 3 hours** during an outage. Alert
on burn rate, not just consumption:

| Burn rate | Window | What it means | Alert severity |
|---|---|---|---|
| 14.4× | 1h | Will consume 30-day budget in 2 days at this rate | PAGE |
| 6× | 6h | Will consume budget in 5 days | PAGE |
| 3× | 24h | Will consume in 10 days | TICKET |
| 1× | 72h | On track to spend exactly the budget over the window | INFO |

Two-window protection: alert only if BOTH a short and longer window
show the burn rate. Single-window alerts flap.

## Policy template (sign + post)

```
SERVICE: Checkout API
OWNER:   payments-team
SLOs:
  - availability: 99.95% over 30d
  - latency p99: <300ms for /checkout

ERROR BUDGET: 21.6 min/month for availability

GOVERNANCE:
  Budget > 50%: standard release process
  Budget 0-50%:
    * Risky deploys (touching payment path, DB migration)
      require SRE approval.
    * One reliability story prioritized per next sprint.
  Budget < 0%:
    * Feature deploys halted (security + reliability fixes only).
    * Joint SRE + product retro within 5 business days.
    * Two reliability stories prioritized per sprint until budget
      recovers to >50%.
  Budget < -100% (double-burn over 30d):
    * Escalate to VP. SLO review: was it set too aggressively, or
      is the service genuinely broken?

SIGNED:
  Engineering: ________ (EM)
  Product:     ________ (PM)
  SRE:         ________
  Date:        ________
```

## The "we're frozen but we have to ship" exception

There IS an exception path. Document it:

- Security CVE with public PoC → ship.
- Regulatory deadline that's a contract → ship + document.
- Customer escalation with executive buy-in → ship + executive
  signs as the approver (no anonymous "leadership said so").

Every exception is logged. If exceptions exceed N/quarter, the
policy is broken — re-discuss.

## How to USE the budget (not just husband it)

A budget you never spend is set too loose. Use it deliberately:
- Run chaos engineering tests during low-load windows.
- Run a bold migration knowing you have buffer.
- Skip some safety steps for a clear win.

If you finish a month with 95% of budget unused, your SLO should
have been tighter. Re-evaluate at the next SLO review.

## SLO review cadence

Quarterly. Look at:
- Did the SLO match user experience? (Customer complaints during
  green periods = SLO measures the wrong thing.)
- Did the budget burn track your major incidents?
- Should the SLO tighten (over-performed) or loosen (chronically
  under)?
- Are the burn-rate alerts firing on the right things?

## Anti-patterns

- 100% SLO. There's no error budget. Impossible to operate.
- 99.999% SLO without the infra to back it up. 5 min/year = no
  patches, no migrations, no human-driven anything.
- Policy that says "consider freezing." Either you freeze or you
  don't. Soft language gets ignored.
- The policy lives on a wiki that nobody reads at incident-time.
  Embed in the deploy tool — block deploys when frozen.
- Excluding planned maintenance from SLO measurement. Then your SLO
  is fiction; users felt the maintenance.
- One global SLO across very different services. Tier them: customer-
  facing tier-1 ≥99.95%, internal batch tier-3 ≥99.5%.
- Negotiation in the middle of an incident. The policy was supposed
  to be the agreement. If you're negotiating mid-fire, the policy
  failed.
