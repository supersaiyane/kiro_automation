---
id: email_marketing_automation
version: 1.0.0
owners: [website_creator, product_manager]
tags: [email, marketing, drip, segmentation, deliverability, transactional]
when_to_use: |
  Building or scaling email beyond "manual blasts." Email remains the
  highest-ROI channel for B2B SaaS (≥ $36 per $1 spent, DMA studies).
  But deliverability is fragile — get it wrong and your domain reputation
  takes months to repair.
inputs:
  - email_list, sender_domain, automation_goals, tooling_budget
outputs:
  - "email_program: transactional + marketing + drip + segmentation + deliverability"
---

# Email Marketing + Automation

> Email is the most-overlooked owned channel. Social platforms can
> nerf your reach overnight; your email list can't. Build it
> deliberately — deliverability, segmentation, lifecycle automation —
> not as an afterthought.

## Two email systems — keep them separate

| Type | Purpose | Tools | Volume |
|---|---|---|---|
| **Transactional** | Order confirmation, password reset, alerts | Postmark, AWS SES, Resend, SendGrid | Per-user trigger |
| **Marketing** | Newsletters, campaigns, drips | Customer.io, Klaviyo, Mailchimp, HubSpot, Loops | Bulk |

NEVER mix them on the same sending domain. Transactional emails should
have near-100% delivery; marketing < 100% is fine. Mixing tanks
transactional reputation.

Separate subdomains: `notifications.example.com` (transactional),
`hello.example.com` (marketing).

## Deliverability — the floor

```
1. Authenticate the domain.
2. Warm up the IP / domain.
3. Maintain list hygiene.
4. Honor unsubscribes.
5. Avoid spam triggers.
6. Monitor inbox placement.
```

### Authentication (mandatory in 2024+)

| Standard | What | How |
|---|---|---|
| **SPF** | Who can send from your domain | TXT record |
| **DKIM** | Crypto signature on emails | Generated per ESP |
| **DMARC** | Policy if SPF/DKIM fail | TXT record at `_dmarc.example.com` |
| **BIMI** | Logo in inbox | DMARC `p=reject` + brand-cert |

Without these: Gmail + Yahoo (Feb 2024 onward) block bulk senders. Set
DMARC to `p=quarantine` minimum; `p=reject` ideal after monitoring.

### Sender reputation

- New domain / IP: warm up over 4-6 weeks (low volume → ramp).
- Monitor via Google Postmaster Tools, Microsoft SNDS.
- Spam-complaint rate < 0.1% (above = ESP suspends you).
- Bounce rate < 2%.

### List hygiene

- DOUBLE OPT-IN for marketing (confirms valid + intent).
- Verify emails (Kickbox, NeverBounce) before adding.
- Remove unengaged after 90-180 days (re-engagement campaign first).
- Honor unsubscribes within 24h (legal requirement).

## Lifecycle email automation

```
Trigger → Filter → Wait → Action → Branch
```

Examples:

### Onboarding sequence (PLG)
```
Day 0:  Welcome + first-action CTA
Day 1:  Did they complete first-action? Branch.
  Yes → Day 3: Feature spotlight 1
  No  → Day 1: Re-nudge with help link
Day 7:  "How's it going?" check-in
Day 14: Case study (if they're a likely buyer)
Day 21: Sales pitch (if free tier limit hit)
```

### Re-engagement
```
Day 30 no login → "We miss you"
Day 60 no login → "Tips you might've missed"
Day 90 no login → "Are you still interested?" (unsubscribe option)
Day 120 → remove from active list
```

### Cart-abandonment (e-commerce)
```
1 hour:  "Forget something?"
24 hours: "Items still in your cart"
48 hours: "10% off if you complete today"
```

### Webinar / event drip
```
T-7d:  RSVP confirmation
T-1d:  "Tomorrow at 2pm" reminder
T-1h:  "Starting in 1 hour"
T+0:   "We're live"
T+1d:  Recording link
T+3d:  Followup with relevant content
```

Build flows in: Customer.io, Klaviyo (e-comm), HubSpot, Loops (PLG-
friendly), Encharge, Iterable.

## Segmentation

Static segments (lists):
- Industry, role, company size, plan tier.

Dynamic segments (computed):
- "Users who viewed pricing 3+ times this week."
- "Customers paying > $X with NPS > 8" (advocate candidates).
- "Trials expiring in 3 days" (win-back window).

The TIGHTER the segment, the higher the engagement. Mass blasts to
"All users" are 19th-century marketing.

## Email copy + design

### Subject line
- 30-50 chars (mobile preview limit).
- A/B test EVERY major send.
- Avoid spam triggers ("Free!!", "Earn money fast"). Spamassassin
  scores in your ESP show risk.

### Preview text (preheader)
- ~50 chars after subject in inbox preview.
- Complements subject, doesn't repeat.

### Body
- One CTA per email (mostly).
- Plain-text fallback ALWAYS sent alongside HTML.
- < 50KB HTML to avoid Gmail clipping.
- Inline CSS (email clients strip `<style>` blocks unreliably).
- 600px width max for desktop; responsive for mobile (60-70% of opens).

### Personalization
- First name in subject when known (don't if it'll show "Hi {first_name}"
  on null).
- Reference past activity ("Last time you looked at X...").
- Relevant content per segment.

## Transactional email patterns

```python
# Each transactional email needs:
- Clear sender ("Acme <support@acme.com>")
- Subject that matches expectation ("Your order #42")
- Branded but minimal design
- Single primary action
- Footer: company info + unsubscribe (even for transactional, polite)
- Plain-text alt
```

Common transactional types:
- Welcome / account confirmation
- Password reset
- Order confirmation / shipping update
- Receipt / invoice
- Subscription renewal / cancellation
- Magic link / 2FA code
- Mentions / comments / activity digest
- Security alerts (new device, suspicious activity)

Tools: Postmark (developer favorite — focused, fast delivery), Resend
(modern, dev-friendly), AWS SES (cheapest at scale), SendGrid.

## Email + privacy law

- **GDPR**: Lawful basis for email. Opt-in (consent) most common.
- **CAN-SPAM (US)**: opt-OUT acceptable; clear unsubscribe required.
- **CASL (Canada)**: explicit opt-in only.
- **PECR (UK)**: opt-in for marketing.

Practical: assume strictest applicable (opt-in) for marketing;
transactional is allowed without explicit consent (legitimate interest).

## Metrics that matter

| Metric | Definition | Healthy |
|---|---|---|
| Open rate | Opens / delivered | 20-30% B2B; 15-25% B2C |
| Click-through rate | Clicks / delivered | 2-5% |
| CTOR | Clicks / opens | 10-20% |
| Reply rate | Replies / delivered | Cold outreach: > 3% good |
| Unsubscribe rate | Unsubs / delivered | < 0.5% per send |
| Spam complaint rate | Complaints / delivered | < 0.1% |
| Conversion rate | Goal completion / delivered | Varies; track per flow |
| Revenue per email | (B2C) | Varies |

Note: Apple Mail Privacy Protection (iOS 15+) inflates open rates.
Trust clicks + downstream conversion more.

## Tools landscape (2026)

| Use | Tools |
|---|---|
| Transactional | Postmark, Resend, AWS SES, SendGrid |
| Marketing (modern) | Customer.io, Klaviyo, Loops, Encharge |
| Marketing (enterprise) | HubSpot, Marketo, Pardot, Iterable |
| ESP-included (in CRM) | Salesforce Marketing Cloud, Adobe Campaign |
| Newsletter-first | Beehiiv, Substack, ConvertKit |
| Email design | Litmus, Email on Acid (testing), Stripo (templates) |
| Validation | Kickbox, NeverBounce, ZeroBounce |

Mid-market PLG SaaS default: **Postmark (transactional) + Customer.io
or Loops (marketing)**.

## AI in email (2026)

- AI subject-line generation (most ESPs offer).
- AI send-time optimization (per-recipient learned best send time).
- AI segmentation (find lookalike high-value users).
- Generative personalization (each email's body slightly customized).
- Predictive churn — trigger save-flow proactively.

Use these as accelerators, not replacement for strategy.

## Anti-patterns

- **Same domain for transactional + marketing.**
- **No DMARC.** Email lands in spam.
- **Bought lists.** Spam-complaint disaster.
- **No unsubscribe link.** Illegal + ESP suspension.
- **Sending to "All users" weekly.** Fatigue → unsub.
- **One mega-send blast** with no segmentation.
- **Subject line clickbait.** Short-term opens, long-term reputation.
- **No A/B testing.** Optimization left on the table.
- **Long sender name without domain alignment.** Reduces trust.
- **No mobile preview check before send.** 60%+ opens are mobile.

## Validation

- [ ] SPF + DKIM + DMARC configured for sender domain.
- [ ] Separate subdomains for transactional vs marketing.
- [ ] Double opt-in for marketing.
- [ ] Onboarding drip wired.
- [ ] Re-engagement campaign for inactive users.
- [ ] Segmentation beyond "all users."
- [ ] Subject-line A/B tests running.
- [ ] Plain-text alt sent alongside HTML.
- [ ] Spam complaint rate < 0.1%.
- [ ] Unsubscribe honors within 24h.
- [ ] GDPR / CAN-SPAM compliance documented.
