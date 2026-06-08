---
id: landing_page_copy
version: 1.0.0
owners: [website_creator]
tags: [marketing, landing-page, copy, hero, cta, conversion]
when_to_use: |
  Drafting the public marketing site after the product is shipped.
  The hero copy must reflect the positioning from market research, not
  the implementation language used by the engineers.
inputs:
  - positioning: from market_research artifact
  - feature_list: from PRD + shipped fe/be code
outputs:
  - landing_html: hero + features + pricing + CTA
---

# Landing Page Copy

**Above-the-fold (the only thing 90% of visitors read)**

- **Headline** — 5-9 words. Names the outcome the customer gets, not
  the technology that delivers it.
  - Bad: "AI-powered RAG-augmented customer success platform"
  - Good: "Cut support response time in half"
- **Subheadline** — one sentence. Who this is for + why now.
- **Primary CTA** — one button. Verb-led. "Start free", "Book demo".
  Never "Learn more" — that means "nothing happened on the click".
- **Social proof** — logos, a one-line testimonial, or a stat. Don't
  fake this.

**Feature section (translate eng -> outcomes)**
Each feature card:
- 2-4 word title
- 1-sentence benefit (NOT feature list — the OUTCOME)
- One small visual or screenshot

Example translation:
- Eng says: "WebSocket-based real-time push notifications via Redis pub/sub"
- Copy says: "Get notified the second something changes."

**Pricing section** (if applicable)
- 3-tier max. Highlight the middle one.
- Price + 3-5 line bullets per tier.
- "Talk to sales" tier for enterprise — no public price.

**Final CTA**
Repeat the primary CTA. Different copy from the hero one to test which
converts.

**Anti-patterns**
- Hero copy that names the technology stack.
- Feature lists with no benefit translation.
- Multiple competing CTAs above the fold.
- Pricing pages with > 4 tiers.
- Anywhere on the page: "synergy", "leverage", "next-generation".
