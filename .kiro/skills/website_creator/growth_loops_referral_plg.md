---
id: growth_loops_referral_plg
version: 1.0.0
owners: [website_creator, product_manager]
tags: [growth, plg, referral, viral, loops, k-factor, retention]
when_to_use: |
  Designing the growth engine for a product. Linear acquisition (ads,
  outbound) plateaus. Growth LOOPS compound — outputs of one cycle
  feed the inputs of the next. The senior craft is identifying the
  loop that fits your product.
inputs:
  - product_type, current_acquisition_channels, network_effect_potential
outputs:
  - "growth_design: loop type + viral coefficient + retention curve + measurement"
---

# Growth Loops + Referral + PLG

> Funnels leak. Loops compound. The first hour of strategy is choosing
> WHICH loop your product naturally feeds — then designing the
> product so the loop closes.

## Loops vs funnels

```
FUNNEL (linear):
  Marketing → Trial → Activation → Retention → Revenue
  (each stage loses %; growth requires more inputs at top)

LOOP (compounding):
  Output → becomes input → drives more output
  k-factor > 1: each user creates > 1 new user; viral growth
  k-factor < 1: each user creates fraction; needs supplement
```

You need BOTH. Funnels optimize conversion within a loop.

## The five canonical growth loops (Reforge framework)

### 1. Content loop
```
Create content → search engines / social rank it → users visit →
some convert + some create more content (UGC, reviews) →
that content ranks → more users
```
Examples: Wikipedia, Stack Overflow, Reddit, Quora.

### 2. Paid loop
```
Spend $X on ads → acquire user → LTV > CAC → reinvest profit in more ads
```
Examples: Most DTC e-commerce. Bootstrappable; capital-intensive.

### 3. Sales loop
```
Outbound → meeting → close → customer references → warm intros →
more meetings
```
Examples: Enterprise SaaS.

### 4. Viral loop
```
User signs up → invites N friends → some accept → each invites N more →
exponential growth
```
Examples: Slack, Zoom, Loom, Calendly.

K-factor = invites × acceptance rate. K > 1 = viral; K ≈ 0.5 = strong
amplifier; K = 0 = no virality.

### 5. UGC loop
```
User creates content on platform → that content brings visitors →
some sign up + create more content
```
Examples: YouTube, Instagram, TikTok, Pinterest.

## Identify YOUR loop

Match product to loop type:
- **B2B SaaS**: usually content + sales + (some) viral.
- **DTC e-commerce**: paid + content + (some) referral.
- **Marketplace**: 2-sided viral (sellers attract buyers attract sellers).
- **Communication tool**: viral (Slack, Loom).
- **Creator tool**: UGC + content (Canva, Figma).
- **Productivity SaaS**: PLG (workspace invites, embeds).

You may have MULTIPLE loops; one is usually dominant. Invest behind
the dominant one.

## Designing the viral loop

Steps:
1. **Trigger**: when does the user want to invite others?
2. **Channel**: email, Slack, in-app, embed.
3. **Hook**: what's the recipient promised?
4. **Conversion**: how does recipient become user?
5. **Repeat**: recipient's first action triggers their own invite.

Example (Calendly):
- Trigger: scheduling a meeting.
- Channel: meeting invite email with calendly URL.
- Hook: "Pick a time" (free utility).
- Conversion: recipient sees the tool, signs up to use themselves.
- Repeat: they schedule their first meeting.

K-factor reality check: most B2B SaaS K ≈ 0.1-0.3. Even at K = 0.5,
viral alone won't scale; pair with paid / content / sales.

## Referral programs

Different from organic virality — referrals are EXPLICIT incentivized.

```
Give: free month / $20 credit / extra storage to referrer.
Get:  free trial / $20 credit / discount to referee.
```

Best practices:
- DOUBLE-SIDED incentive (give + get) outperforms one-sided 2-3x.
- Reward at the right time (when referee gets VALUE, not on signup).
- Make sharing low-friction (email, link, social, QR).
- Track via unique referral links (UTM + cookie).

Tools: Friendbuy, Rewardful, Referral Rock, GrowSurf.

Common failure: rewards too tied to immediate purchase. People sign
up for the reward, never use the product, churn. Reward retention,
not signup.

## PLG (Product-Led Growth) tactics

```
Free / freemium → activate users → expand to paid → invites within team
```

Pillars:
1. **Self-serve signup** — no sales call required.
2. **Time to value < 1 day** — user gets value in their first session.
3. **Activation metric** — measurable "first value" moment.
4. **Conversion mechanism** — usage hits limit / pro feature appears.
5. **Expansion within account** — team member invites.

Examples: Slack, Notion, Linear, Vercel, Stripe.

Friction kills PLG:
- Credit card required for free tier.
- Onboarding > 5 minutes.
- Hidden pricing.
- Sales gate before first value.

## Network effects

Different from virality:
- **Virality**: growth via invites.
- **Network effect**: product VALUE grows with more users.

Types:
- **Direct (Metcalfe's Law)**: each user adds value for all others
  (Slack, Twitter).
- **Indirect (two-sided)**: more buyers attract more sellers (Airbnb,
  Uber, Etsy).
- **Data**: more usage → better algorithm → more usage (Google, Spotify).
- **Local**: only near you (Nextdoor, Uber).

Network effects = MOAT. They take years to build but eventually become
unbreakable.

## Retention — the floor under all growth

```
"If you have a leaky bucket, more water at the top doesn't fix it."
```

Retention curves:
- **Linear decay** (terrible): each cohort halves every period.
- **Flattening curve** (good): decay slows; long tail of engaged users.
- **Smiley curve** (great): some inactive users come BACK.

Measure: % of users retained at day 1, 7, 30, 90 by cohort.

Improve retention BEFORE pouring more into acquisition.

## Activation — the precondition

Define your "aha moment":
- Slack: 2000 messages sent.
- Facebook: 7 friends in 10 days.
- Dropbox: file in folder + synced to 2 devices.

Then DESIGN onboarding to push users to that moment FAST.

Methods:
- Empty states with sample data.
- Guided tour (sparingly — most people skip).
- Pre-filled / templates.
- Email drip nudging toward action.
- Friction removal — remove every avoidable step.

## Measurement

```
North Star metric: ONE number that captures product value.
  - Airbnb: nights booked.
  - Slack: messages sent.
  - YouTube: watch time.

Funnel metrics:
  visits → signups → activated → paid → retained → expanded
  Conversion rate per stage. Find the WORST stage; fix.

Loop metrics:
  Viral coefficient K, cycle time, referral conversion rate.
  Track per loop.

Cohort metrics:
  Retention by signup week. Are newer cohorts better than older?
```

Tools: Mixpanel, Amplitude, PostHog, Google Analytics 4 (with custom
events). Build a growth dashboard tied to North Star.

## Anti-patterns

- **All channels at once.** Spread thin; nothing compounds. Pick 1-2
  dominant channels first.
- **Vanity metrics** (impressions, traffic) over conversion + retention.
- **Referral with no usage requirement.** Quick freebie chasers churn.
- **Optimizing acquisition before retention.** Leaky bucket.
- **Discounts as growth lever.** Trains customers to wait for sales.
- **No experiment cadence.** Growth is iterative; pick + ship + measure
  + decide.
- **K-factor inflation tricks** (inviting via auto-import contacts).
  Spam-feeling; long-term damage.
- **One-size-fits-all onboarding.** Different personas need different
  paths.
- **Skipping the loop diagram.** Without it, growth is a wish.

## Validation

- [ ] Primary growth loop identified + designed.
- [ ] North Star metric defined + tracked.
- [ ] Activation metric defined + onboarding tuned to hit it.
- [ ] Retention curves cohort-tracked + flattening.
- [ ] Referral program incentive structure documented (if applicable).
- [ ] Viral coefficient measured (if applicable).
- [ ] Experiment backlog with hypotheses + expected lift.
- [ ] Quarterly growth review with team.
