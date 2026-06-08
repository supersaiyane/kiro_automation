---
id: leadership_deck_authoring
version: 1.0.0
owners: [technical_writer]
tags: [deck, leadership, board, executive, pptx, marp, narrative]
when_to_use: |
  Quarterly business reviews, board updates, exec read-outs after a
  major launch or incident, investor decks. Audience = leadership +
  board: time-poor, outcome-oriented, will read SUMMARY first.
inputs:
  - quarterly_results / launch_metrics / strategic_context
outputs:
  - leadership_deck: "Marp/Reveal-shaped Markdown (renders to HTML, PPTX via marp-cli, or PDF). 10-15 slides typical."
---

# Leadership / Executive Deck Authoring

> Executives skim. Their attention is your scarce resource. Every
> slide must be parseable in 10 seconds and earn its place in the deck.

## The 10-slide rule

| # | Slide | Purpose |
|---|---|---|
| 1 | Title + subtitle + date | Frame the meeting |
| 2 | TL;DR (3 bullets max) | Whole deck in one slide; if they read nothing else |
| 3 | Strategic context | One line on why this matters |
| 4 | What we shipped | Outcome (NOT feature list) |
| 5 | Metrics (the chart slide) | One headline metric + 2 supporting; show movement vs. target |
| 6 | What's working | 3 wins, with evidence |
| 7 | What's NOT working | 2-3 risks/issues — be honest |
| 8 | Asks (decisions/resources/people) | Specific, owned, dated |
| 9 | Forward look | What lands by next review |
| 10 | Q&A / appendix | Backup data; not the main deck |

Stretch to 15 if needed; never beyond.

## Output format — Marp Markdown

```markdown
---
marp: true
theme: default
class: lead
paginate: true
backgroundColor: '#fff'
---

# Q3 Engineering Review
## <Product> · 2026-04-15

---

## TL;DR

- **Shipped** the new onboarding flow; time-to-first-value down 14d → 3d
- **Reliability**: 99.95% uptime, hit SLO; one incident (postmortem in
  appendix)
- **Asks**: hiring approval for 2 SR-ENG-BE; alignment on multi-region
  scope for Q4

---

## Strategic context

We committed at Q3 kickoff to remove the onboarding friction that
was driving 18% of churn at month-1. This was the quarter to prove
the hypothesis.

---

## Outcome metric — Time to first value

[chart placeholder: 14d → 3d trajectory, weekly]

- Target: ≤ 5 days
- Actual: 3.1 days median, 4.8 p90
- Cohort improvement: month-1 retention 67% → 81% (preliminary; final
  data in 2 weeks)

---

## What's working

- ✅ Onboarding redesign — measurable retention lift (above)
- ✅ Customer support time-to-resolution down from 8h → 2.5h (Zendesk metrics)
- ✅ Hired senior FE-lead (started Apr 1); first impact: shipped
      design-system v2

---

## What's NOT working

- ⚠️ Multi-region migration slipped 6 weeks; root cause: vendor
      latency under SLA, in escalation
- ⚠️ Tech-debt interest rising (incidents in payments-svc up 30% QoQ);
      proposed 2 sprint focus next quarter
- ⚠️ Pipeline test flake rate 14% (target: ≤ 2%); fix planned for Q4

---

## Asks

1. **Hiring**: approval for 2 SR-ENG-BE roles (open to backfill +
   incremental). Owner: <CTO>. Decision needed by: 2026-04-30.
2. **Multi-region scope for Q4**: full active-active OR primary-with-DR?
   Owner: leadership. Decision needed by: 2026-05-15.

---

## Forward look — Q4

- Multi-region (scope TBD) — primary infra investment
- Onboarding v2 expansion to enterprise tier
- Pipeline reliability — drive flake rate < 2%
- Hiring against approved plan

---

## Q&A / Appendix

(Backup slides — incidents postmortem, full metric tables, hiring
plan detail)
```

## Tone + style rules

- **Outcomes first, activities second.** "Reduced time-to-value 14d
  → 3d" beats "Shipped onboarding flow with 12 features."
- **Numbers, not adjectives.** "Improved performance" is rejected;
  "p95 latency 800ms → 220ms" is the floor.
- **Honest about what didn't work.** Execs trust people who name
  problems; they distrust spin.
- **One idea per slide.** If you have two ideas, you have two slides.
- **No tables of contents, no agenda slides, no "thank you" slide.**
  Earn every slide.

## Decision-driving asks

Vague: "We'd like more headcount."
Specific: "Approve 2 SR-ENG-BE backfills + 1 new req. Total cost
$650K/yr. Decision needed by 2026-04-30. Owner: CTO."

The vague version doesn't get a decision. The specific one does.

## Anti-patterns

- 50-slide decks. Nobody reads slide 35.
- Speaker notes carrying the real message. The slide should stand alone.
- Charts without a label naming the conclusion ("Latency by quarter"
  vs. "Latency dropped 73% after redesign").
- Bullet points >2 lines long. Cut.
- Status colors (red/yellow/green) without numeric thresholds —
  "yellow" means nothing without a definition.
- Burying bad news in slide 14. Lead with it on slide 2.
- "We crushed it" / "amazing" / "incredible" — exec readers tune out
  superlatives. Numbers carry the praise.

## Render to PPTX or PDF

```bash
# Install marp-cli: npm i -g @marp-team/marp-cli
marp leadership_deck.md --pptx --output leadership_deck.pptx
marp leadership_deck.md --pdf --output leadership_deck.pdf
marp leadership_deck.md --html --output leadership_deck.html
```
