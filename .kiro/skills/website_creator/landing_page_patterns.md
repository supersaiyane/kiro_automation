---
id: landing_page_patterns
version: 1.0.0
owners: [website_creator, designer, product_manager]
tags: [landing-page, hero, features, social-proof, cta, above-the-fold]
when_to_use: |
  Building a marketing landing page from scratch — campaign-specific, paid
  traffic, product launch, or marketing home. Pattern fluency makes the
  difference between a 1% and a 10% conversion rate.
inputs:
  - audience, value_prop, target_action, traffic_source
outputs:
  - "landing_page_blueprint: section order + content per section + CTA placement"
---

# Landing Page Patterns

> A landing page has ONE job. Visitor arrives, decides in 3 seconds:
> "am I in the right place?" Decides in 8 seconds: "do I trust this?"
> Decides in 30: "do I want this?" Every section serves one of those
> three jobs.

## The canonical structure (top to bottom)

```
1. NAV         — light, focused, has secondary CTA in top-right
2. HERO        — headline + subhead + primary CTA + hero visual
3. SOCIAL PROOF strip — customer logos / press / stats (above the fold!)
4. PROBLEM     — pain the visitor recognizes
5. SOLUTION    — your product as the answer
6. FEATURES    — 3-5 specific capabilities, each with proof
7. HOW IT WORKS — 3-5 step flow
8. PROOF       — case study / testimonial / data
9. PRICING     — link or inline (depending on cycle stage)
10. FAQ        — preempt objections
11. CTA repeat — sticky bottom or final hero
12. FOOTER     — supporting links, trust signals
```

You don't always need ALL sections. Campaign landing pages can be 3-4
sections (hero, features, proof, CTA). Marketing home is fullest.

## Hero — the 5-second test

A visitor decides within 5 seconds if they're in the right place. Hero
must answer:

```
1. WHAT is this product?
2. WHO is it for?
3. WHY should they care?
4. WHAT to do next?
```

Layout: H1 + subhead + 1-2 CTAs + visual.

### H1 patterns that work

- **Outcome-led**: "Ship features 3× faster" (Linear)
- **Problem-led**: "Email that doesn't suck" (HEY)
- **Identity-led**: "For engineers who'd rather build than babysit" (PagerDuty alt)
- **Differentiation-led**: "The CRM your sales team will actually use"
- **Specific metric**: "From 18 minutes to triage to 3"

NOT:
- Clever wordplay without context.
- Buzzword salad ("AI-powered next-gen platform").
- Long abstract claims.

### Subhead

Explain HOW or for WHO in 1-2 sentences. ~15-25 words.

### CTAs

- **Primary**: outcome-led ("Start free trial", "Book a demo"). High
  contrast.
- **Secondary**: low-commitment ("See pricing", "Watch demo"). Lower contrast.

DON'T:
- "Submit" / "Click here" / "Get started" (too generic).
- Three primary CTAs.
- CTA below the fold only.

### Hero visual

| Type | When |
|---|---|
| Product screenshot | When the product IS the value prop (SaaS) |
| Annotated screenshot with callouts | When key features need explanation |
| Looping video / GIF | When the product feels great in motion |
| Hand-drawn illustration | For consumer / brand-led products |
| Abstract / 3D / WebGL | High-end / luxury / dev-tool brands |
| Customer photo | When social proof IS the value |

Default: a screenshot of the product showing its most differentiated screen.

## Social proof strip — above the fold

```
"Trusted by 10,000+ teams"
[Logo] [Logo] [Logo] [Logo] [Logo]
```

OR specific:
```
"Used by Notion, Linear, Vercel, and Stripe to ship faster"
```

Specific company names > generic logos. Numbers ("10,000+") build trust
fast.

Place IMMEDIATELY after hero, before the fold. Sets credibility.

## Problem section — "I know my customer"

```
HEADER: "Your team is great. But these still happen every week:"
LIST:
  ✗ Every alert is 'check the dashboard'
  ✗ Postmortems are written, never read
  ✗ The same incident, third time this quarter
```

Show the pain in YOUR CUSTOMER's voice. Quote them if you can.

## Solution section — your one-liner

ONE clear positioning statement:

```
"Datadog for AI workloads."
"Like Notion, but for engineers."
"The CRM your sales team will actually use."
```

Then 1-2 paragraphs expanding.

## Features section — translate to outcomes

```
✗ "AI-powered alert correlation"
✓ "Stop debugging at 3am — alerts arrive with the root cause already identified."

✗ "Multi-tenant SSO"
✓ "Onboard your CISO in 15 minutes — Okta, OneLogin, Azure AD all supported."

✗ "Webhook integrations"
✓ "Trigger your workflow without writing code — 200+ apps connected."
```

Each feature = headline + short paragraph + visual + (optional) proof
quote.

Layout: alternating left-right (image + text) for narrative pacing.

## How it works

Three or four steps in a sequence. Numbered. Each ~1 sentence + simple
illustration.

```
1. Connect — 1-click OAuth to your tools.
2. Configure — Pick what to monitor, who to alert.
3. Improve — Get weekly reports + recommendations.
```

Visual: clean step diagram, NOT a 100-arrow flowchart.

## Proof section — the heaviest lift

The single highest-impact section. Replace "X loved us" with:

**Customer story**:
```
[Photo of named human]

"We retired 80% of our PagerDuty rules within 6 weeks.
My team sleeps through the night. I sleep through the night."

— Jamie X, VP Engineering, Acme Inc.

Acme migrated from <competitor> in 3 weeks. Their metrics:
- Incident count: ↓ 62%
- On-call satisfaction: 4.1 → 4.8 / 5
- MTTR: 28 min → 9 min
```

**Always include**:
- Named human + role + company.
- Specific quote (not "amazing product").
- Concrete numbers (% change, dollar amount, time saved).
- Optional: link to fuller case study.

## Pricing section — or link out

If sales-led:
- "Talk to sales" + form. No prices on page.
- 1-2 sentence on what's included at enterprise.

If self-serve:
- 3 tiers (Free / Pro / Business / Enterprise).
- Highlight the recommended.
- Annual toggle with "save 20%".
- Most important features per tier (NOT full list).
- Compare-features link below.

## FAQ — preempt objections

Top of FAQ should be the objections that delay sales:

```
- Is this right for my [industry/size/use case]?
- How is this different from [obvious competitor]?
- What's the security / compliance story?
- What if I want to leave?
- What does setup look like? Time to value?
- Can I see customer references?
```

Answer concisely (2-3 sentences). Link to docs for depth.

## Final CTA — repeat the ask

Right before footer:

```
"Ready to ship faster?"
[Start free trial]   [Book a demo]
or call (415) 555-...
```

Re-state the value prop briefly, repeat both CTAs.

## Sticky elements

- Top nav: shrinks on scroll. Has CTA from initial scroll.
- Floating CTA bar (mobile): appears after user scrolls past hero.
- Live chat / Intercom: bottom-right. Defer load (after 5s + on idle).

Don't trap users in floating popups. Cookie banner is the only mandated
interrupt.

## Anti-patterns

- **Carousels in the hero.** Bounce rate spike. People don't wait for
  slide 2.
- **Hero video that auto-plays with sound.** Hostile.
- **Multiple unrelated CTAs in the hero** ("Sign up", "Book a demo",
  "Watch video", "Read blog").
- **Buzzword H1** ("Reimagine. Reinvent. Revolutionize.").
- **No social proof above the fold.**
- **All features, no benefits.**
- **30-row pricing comparison table** on a landing page (link to it).
- **No FAQ.** Implies you have no objections, which is suspicious.
- **Cookie banner blocks ENTIRE page.** Use a small bottom bar.
- **Long form before any value demo.**
- **Auto-popup email-capture in 5 seconds.** Annoying.
- **Footer with 80 links.** Unfocused; visitor bails.

## Conversion benchmarks (B2B SaaS, paid traffic)

| Funnel stage | Median | Top-tier |
|---|---|---|
| Bounce rate | 50% | < 30% |
| Time on page | 1m | > 3m |
| Scroll depth (75%+) | 30% | > 50% |
| CTA click | 3-5% | 10%+ |
| Lead form completion | 1-3% | 8%+ |
| Trial start (self-serve) | 2-4% | 8%+ |

Measure via your analytics (cross-ref `analytics_event_tracking_setup`).

## Validation

- [ ] Hero answers WHAT / WHO / WHY / NEXT in 5 seconds.
- [ ] Social proof above the fold (logos or stats).
- [ ] Primary CTA repeated 3-5 times throughout the page.
- [ ] Customer story with name, photo, role, company, specific metric.
- [ ] FAQ preempts top 5 objections.
- [ ] Mobile experience parity tested (no horizontal scroll, big tap
      targets, readable type).
- [ ] LCP < 2.5s on mobile.
- [ ] No carousel in hero.
- [ ] Cookie banner non-blocking.
