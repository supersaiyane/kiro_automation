---
id: competitive_teardown
version: 1.0.0
owners: [market_researcher]
tags: [market, competitive-analysis, teardown, positioning, moat]
when_to_use: |
  Before any positioning claim. A teardown shows what the competitor
  actually delivers (not what they say) and where the unserved gaps are
  that your product can credibly claim. Re-run quarterly — competitors
  move faster than your last research deck.
inputs:
  - top_competitors: 3-5 most-cited alternatives
outputs:
  - teardown_table: feature × competitor matrix with evidence
  - moat_assessment: what's defensible vs. table-stakes
---

# Competitive Teardown

A teardown is **not** a feature matrix from their website. It's:

1. **Sign up under a real-looking persona.** Free trial, screenshots,
   the onboarding emails they send, the day-3 nudge email, the
   day-14 churn-prevention discount.
2. **Reverse-engineer their architecture** from job posts (the stack
   they hire for), their docs (API versioning style, rate limits,
   pagination patterns), their status page (what services they list,
   how often they break, their SLO).
3. **Read their last 8 quarters of release notes.** Velocity tells
   you what they care about. A 6-month silence on a feature is a
   reliable signal of de-prioritization.
4. **Pull their pricing page Wayback Machine history.** Pricing
   changes telegraph who their buyer is shifting toward.
5. **Look at their public Slack / Discord / GitHub issues.** The
   complaints repeated across three years are the *durable* gaps.

## The teardown table

For each competitor, score on each dimension. **Score with evidence
links — every cell points to a screenshot, URL, or commit.**

| Dimension | Comp A | Comp B | Comp C | Us |
|---|---|---|---|---|
| Time-to-first-value (signup → first useful output) | | | | |
| API quality (versioned? errors? rate limits clear?) | | | | |
| Pricing transparency | | | | |
| Documentation depth | | | | |
| SOC 2 / security posture | | | | |
| Migration path *out* | | | | |
| Public roadmap | | | | |
| Reliability (status-page incidents last 90d) | | | | |

## Moat classification

For each capability where we beat them, ask: **how long would it take
them to copy this?**

- **Days to weeks**: not a moat. UI polish, copy, marketing.
- **Months**: a moat *only if you compound it*. Better onboarding flow,
  a single integration.
- **1-2 years**: structural moat. Data network effects, a marketplace
  with switching cost, a regulated certification (FedRAMP, HIPAA).
- **Indefinite**: rare. Patents you actually defend, exclusive
  partnerships with switching cost on the partner side.

If your "differentiator" is in the first bucket, you don't have one.

## Anti-patterns

- The "we're the only X that does Y" claim — usually false within 90 days.
- Scoring competitors from their marketing site only. Their site
  exaggerates what works and hides what doesn't.
- Skipping the "migration out" column. If switching off them is easy,
  switching off you will be too.
- Treating the matrix as a leaderboard. The point is to find the
  *unoccupied* cell, not to win every row.
- A teardown that names no employees. Read their team's LinkedIns —
  what they used to build tells you what they'll build next.
