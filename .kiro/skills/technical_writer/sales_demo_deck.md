---
id: sales_demo_deck
version: 1.0.0
owners: [technical_writer, website_creator]
tags: [deck, sales, customer, demo, pitch, conversion, marp]
when_to_use: |
  Customer-facing pitch deck for a sales call, a webinar, or a conference
  talk. Audience = a prospect deciding whether to invest 30 minutes of
  their next 30 days in a deeper conversation with you.
inputs:
  - product_positioning (from market_researcher), feature_set, proof_points
outputs:
  - sales_deck: "Marp Markdown rendering to slides + PPTX export, 12-18 slides"
---

# Sales / Customer Demo Deck

> The audience came to find out if you're worth more of their time.
> Your only job is to make that yes/no decision easy.

## The narrative arc (DON'T deviate)

```
Slide order = the story arc:

1.  Title + speaker intro (10 sec)
2.  The customer's WORLD today — the pain (1 min)
3.  The cost of that pain — quantified (30 sec)
4.  The shift / why now (30 sec)
5.  Your product — one-line positioning (30 sec)
6-9. How it works — 3-4 key moves (4-6 min)
10. Proof — a real customer's outcome (2 min)
11. Pricing model (NOT the prices) (30 sec)
12. Asks / next step (30 sec)
```

Most demo decks fail because they jump to slide 6 ("here's how it
works") before establishing slides 2-5 (why the prospect should care).
Don't.

## Marp template

```markdown
---
marp: true
theme: gaia
paginate: true
backgroundImage: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%)
---

<!-- _class: lead -->
# Cut your incident response time by 70%
## <Product Name> · for engineering teams running production at scale

<small>Speaker · Title · email · 2026-04-15</small>

---

## The problem you came to talk about

Your team is great. But every 3 weeks, someone gets paged at 2am for an
incident the dashboards SHOULD have caught.

- p99 alert fatigue: ~40% false-positive rate (industry benchmark)
- Mean time-to-triage: 18 minutes (most of that = "what is this?")
- Postmortems are scheduled, written, and never read again

---

## The cost

For a 50-person engineering org, that's:
- **~$2.4M/year** in lost engineering productivity
- **6.4 hours/week** of senior IC time on incidents-in-progress
- **One catastrophic incident per quarter** that hits revenue

[Source: <named industry report or your own customer data>]

---

## Why now

[Trend slide — 1 macro shift that makes the timing right]
e.g. AI-first detection is finally accurate enough to deploy in
production without flooding on-call with noise.

---

<!-- _class: lead -->
## <Product Name> is the observability platform built for AI-first incident response

Like Datadog, but designed for teams who'd rather hire one senior SRE
than ten alerting rules.

---

## How it works (1/4) — Detection that doesn't cry wolf

[screenshot / animated GIF of the dashboard]

- Trained on your service's normal patterns, not generic thresholds
- Each alert ships with the 3 most-relevant past incidents auto-linked
- False positive rate: 6% (median customer; benchmark = 40%)

---

[3 more "how it works" slides — each one ONE benefit, ONE proof, ONE
visual]

---

## Customer proof — Acme Inc.

> "We retired 80% of our PagerDuty rules within 6 weeks. My team
> sleeps through the night. I sleep through the night."
>
> — Jamie X, VP Engineering, Acme Inc.

- Incident count: -62% (Q1 → Q2)
- On-call satisfaction: 4.1 → 4.8 / 5
- Migrated from <competitor> in 3 weeks

[logo placeholder]

---

## Pricing model

- Tier per service, scales with ingest volume
- Free tier for teams up to 5 engineers
- Enterprise: SOC 2, SSO, dedicated support
- (No specific prices on the public deck — your AE will give the
  bespoke quote)

---

## Next step

If this resonates, here are three ways forward:

1. **15-min deep-dive demo** on your actual logs (sandbox env, no
   commitment)
2. **2-week pilot** on one service of your choice
3. **Refer to your team** — we'll send a discount code

[QR code → calendar booking link]
```

## Demo design — the slides ARE the demo

If you can SHOW the product in 3 screens, do that. Static screenshots
beat live demos when:
- The product is complex and the live path is fragile
- The audience is exec-tier and won't wait for clicks
- The demo environment isn't bulletproof

Live demos beat static when:
- The product is genuinely magical to watch in motion
- The audience is technical and will resent canned screenshots
- You're 100% certain the demo env will hold (test 3 times before the call)

## Anti-patterns

- **Feature-dump slide** — "30 features in 10 sections." Customers
  don't buy features; they buy outcomes.
- **Pricing on a public deck.** Pricing is bespoke; the deck is not.
  "Talk to sales" is the right answer.
- **"About us" history slide** in the first 5. Move to backup.
- **Generic customer logos with no story.** A logo wall is a lazy
  proof; one named customer with one specific outcome > 20 logos.
- **"World-class," "best-in-class," "next-generation."** Banned.
- **Speaker-notes-as-script.** If you need to read the slides, the
  slides are wrong.
- **Generic call-to-action ("contact us").** Specific next step with
  a friction-free path (booking link, sandbox URL, trial signup).

## Speaker tips (when running the deck live)

- 1.5x speed through context slides (2-5). Slow down at the proof + ask.
- After the demo, STOP TALKING. Let the prospect ask the question.
- For the "asks" slide, say the number ("Can we schedule a deep dive
  next Tuesday?") — silence = soft-ask, never gets booked.

## Render

```bash
marp sales_deck.md --pptx -o sales_deck.pptx
marp sales_deck.md --pdf -o sales_deck.pdf
marp sales_deck.md --html -o sales_deck.html
```
