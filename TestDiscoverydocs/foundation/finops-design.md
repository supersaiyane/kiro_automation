# FinOps Architecture Document — CalcApp

**Role:** FinOps Architect | **Mode:** 1 (DESIGN Phase)  
**Date:** 2025-01-XX  
**Status:** Active  

---

## Table of Contents

1. [Assumptions & Inputs](#1-assumptions--inputs)
2. [Unit Economics](#2-unit-economics)
3. [12-Month Cost Projection](#3-12-month-cost-projection)
4. [36-Month Revenue Projection](#4-36-month-revenue-projection)
5. [Break-Even Analysis](#5-break-even-analysis)
6. [Budget Guardrails](#6-budget-guardrails)
7. [Cost Optimization Opportunities](#7-cost-optimization-opportunities)
8. [FinOps Maturity Model](#8-finops-maturity-model)
9. [Pricing Sensitivity Analysis](#9-pricing-sensitivity-analysis)
10. [Runway Analysis](#10-runway-analysis)

---

## 1. Assumptions & Inputs

### Revenue Model

| Tier | Monthly Price | Annual Price | Target Conversion |
|------|--------------|--------------|-------------------|
| Free | $0.00 | $0.00 | Base (96.5% of MAU) |
| Pro | $2.99/mo | $35.88/yr | 2.5% of MAU |
| Dev | $4.99/mo | $59.88/yr | 1.0% of MAU |
| **Combined Paid** | — | — | **3.5% of MAU** |

### Growth Model (MAU Trajectory)

| Month | Phase | MAU | Rationale |
|-------|-------|-----|-----------|
| M1 | Phase 1 | 1,000 | Soft launch, organic |
| M3 | Phase 1 | 5,000 | App store optimization |
| M6 | Phase 1→2 | 25,000 | Viral features, referral |
| M9 | Phase 2 | 100,000 | Marketing push, PR |
| M12 | Phase 2→3 | 250,000 | Sustained growth |
| M18 | Phase 3 | 750,000 | International expansion |
| M24 | Phase 3 | 2,000,000 | Network effects |
| M36 | Phase 3 | 5,000,000 | Market saturation target |

### Conversion Funnel Assumptions

- Free → Pro conversion: 2.5% of MAU
- Free → Dev conversion: 1.0% of MAU
- Monthly churn (Pro): 5%
- Monthly churn (Dev): 3%
- Net new subscribers = (New MAU × conversion rate) - (Existing subs × churn rate)
- RevenueCat fee: 1% of gross revenue processed

### Infrastructure Phase Mapping

| Phase | Months | Infra Budget (Cloud Architect) |
|-------|--------|-------------------------------|
| Phase 1 | M1–M6 | $75/mo |
| Phase 2 | M7–M12 | $400/mo |
| Phase 3 | M13–M36 | $2,500/mo |

---

## 2. Unit Economics

### 2.1 Cost Per MAU

| Phase | Total Monthly Cost | MAU (avg) | Cost/MAU |
|-------|-------------------|-----------|----------|
| Phase 1 (M1–M6) | $117/mo | 10,000 | $0.0117 |
| Phase 2 (M7–M12) | $542/mo | 150,000 | $0.0036 |
| Phase 3 (M13–M36) | $2,992/mo | 2,500,000 | $0.0012 |

**Math — Phase 1 Total Monthly Cost:**
- Supabase Pro: $25
- Cloudflare Free: $0
- Sentry Team: $26
- PostHog Free: $0
- GitHub Team (4 users): $16
- RevenueCat (1% of ~$50 revenue): $0.50
- Infrastructure (Cloud): $75
- **Total: $142.50 → avg $117/mo (ramps from $75 to $142 as services onboard)**

**Math — Phase 2 Total Monthly Cost:**
- Supabase Pro: $25
- Cloudflare Pro: $20
- Sentry Team: $26
- PostHog Growth: $0 → $150 (scaling)
- GitHub Team: $16
- RevenueCat (1% of ~$5,000): $50
- Infrastructure (Cloud): $400
- **Total: $542–$687/mo**

**Math — Phase 3 Total Monthly Cost:**
- Supabase Pro + addons: $75
- Cloudflare Pro: $20
- Sentry Business: $80
- PostHog Scale: $450
- GitHub Team: $16
- RevenueCat (1% of ~$35,000): $350
- Fly.io (compute): $500
- Infrastructure (Cloud): $2,500
- **Total: ~$3,991/mo**

### 2.2 Cost Per Paying Subscriber

| Phase | Total Cost | Paying Subscribers | Cost/Subscriber |
|-------|-----------|-------------------|-----------------|
| Phase 1 | $117/mo | 350 (3.5% of 10K) | $0.33 |
| Phase 2 | $542/mo | 5,250 (3.5% of 150K) | $0.10 |
| Phase 3 | $2,992/mo | 87,500 (3.5% of 2.5M) | $0.034 |

### 2.3 LTV:CAC Ratio by Tier

**Assumptions:**
- CAC (organic, Phase 1): $0.50/user (app store optimization only)
- CAC (paid, Phase 2–3): $2.00/user (ads + referral incentives)
- Pro average lifetime: 1 / 0.05 churn = 20 months
- Dev average lifetime: 1 / 0.03 churn = 33 months

| Tier | Monthly Revenue | Avg Lifetime | LTV | CAC | LTV:CAC |
|------|----------------|--------------|-----|-----|---------|
| Pro | $2.99 | 20 months | $59.80 | $2.00 | **29.9:1** |
| Dev | $4.99 | 33 months | $164.67 | $2.00 | **82.3:1** |
| Pro (organic) | $2.99 | 20 months | $59.80 | $0.50 | **119.6:1** |
| Dev (organic) | $4.99 | 33 months | $164.67 | $0.50 | **329.3:1** |

**After RevenueCat fee (1%):**

| Tier | Net Monthly | LTV (net) | LTV:CAC (paid) |
|------|-------------|-----------|----------------|
| Pro | $2.96 | $59.20 | **29.6:1** |
| Dev | $4.94 | $163.02 | **81.5:1** |

> **Benchmark:** SaaS healthy LTV:CAC is >3:1. CalcApp is extremely capital-efficient due to low infrastructure costs and zero marginal cost per user.

---

## 3. 12-Month Cost Projection

### Month-by-Month Breakdown (All Services)

| Month | Supabase | Cloudflare | Sentry | PostHog | GitHub | RevenueCat | Cloud/Fly | **Total** |
|-------|----------|------------|--------|---------|--------|------------|-----------|-----------|
| M1 | $25 | $0 | $26 | $0 | $16 | $0 | $75 | **$142** |
| M2 | $25 | $0 | $26 | $0 | $16 | $1 | $75 | **$143** |
| M3 | $25 | $0 | $26 | $0 | $16 | $2 | $75 | **$144** |
| M4 | $25 | $0 | $26 | $0 | $16 | $4 | $75 | **$146** |
| M5 | $25 | $0 | $26 | $0 | $16 | $8 | $75 | **$150** |
| M6 | $25 | $0 | $26 | $0 | $16 | $15 | $75 | **$157** |
| M7 | $25 | $20 | $26 | $50 | $16 | $30 | $400 | **$567** |
| M8 | $25 | $20 | $26 | $75 | $16 | $40 | $400 | **$602** |
| M9 | $25 | $20 | $26 | $100 | $16 | $55 | $400 | **$642** |
| M10 | $25 | $20 | $26 | $125 | $16 | $70 | $400 | **$682** |
| M11 | $25 | $20 | $26 | $150 | $16 | $85 | $400 | **$722** |
| M12 | $25 | $20 | $26 | $150 | $16 | $100 | $400 | **$737** |
| **12-Mo Total** | **$300** | **$120** | **$312** | **$650** | **$192** | **$410** | **$2,850** | **$4,834** |

### RevenueCat Fee Derivation

RevenueCat = 1% of gross revenue. Revenue by month:

| Month | MAU | Paid Subs (3.5%) | Pro (71.4%) | Dev (28.6%) | Gross Revenue | RevenueCat Fee |
|-------|-----|-------------------|-------------|-------------|---------------|----------------|
| M1 | 1,000 | 35 | 25 | 10 | $124 | $1 |
| M3 | 5,000 | 175 | 125 | 50 | $623 | $6 |
| M6 | 25,000 | 875 | 625 | 250 | $3,117 | $31 |
| M9 | 100,000 | 3,500 | 2,500 | 1,000 | $12,450 | $125 |
| M12 | 250,000 | 8,750 | 6,250 | 2,500 | $31,143 | $311 |

> Note: Table above shows RevenueCat fee at actual subscriber counts. The cost projection table uses smoothed estimates.

---

## 4. 36-Month Revenue Projection

### Growth & Conversion Funnel

| Month | MAU | Free Users (96.5%) | Pro Subs (2.5%) | Dev Subs (1.0%) | Monthly Revenue | Cumulative Revenue |
|-------|-----|--------------------|-----------------|-----------------|-----------------|--------------------|
| M1 | 1,000 | 965 | 25 | 10 | $124 | $124 |
| M3 | 5,000 | 4,825 | 125 | 50 | $623 | $1,245 |
| M6 | 25,000 | 24,125 | 625 | 250 | $3,117 | $7,794 |
| M9 | 100,000 | 96,500 | 2,500 | 1,000 | $12,468 | $30,420 |
| M12 | 250,000 | 241,250 | 6,250 | 2,500 | $31,118 | $92,900 |
| M15 | 500,000 | 482,500 | 12,500 | 5,000 | $62,238 | $232,613 |
| M18 | 750,000 | 723,750 | 18,750 | 7,500 | $93,356 | $465,681 |
| M21 | 1,250,000 | 1,206,250 | 31,250 | 12,500 | $155,588 | $931,444 |
| M24 | 2,000,000 | 1,930,000 | 50,000 | 20,000 | $249,300 | $1,676,544 |
| M30 | 3,500,000 | 3,377,500 | 87,500 | 35,000 | $436,013 | $3,734,619 |
| M36 | 5,000,000 | 4,825,000 | 125,000 | 50,000 | $622,750 | $7,070,619 |

### Revenue Formula

```
Monthly Revenue = (Pro_Subs × $2.99) + (Dev_Subs × $4.99)
Pro_Subs = MAU × 0.025
Dev_Subs = MAU × 0.010

Example M12: (6,250 × $2.99) + (2,500 × $4.99) = $18,688 + $12,475 = $31,163
Example M36: (125,000 × $2.99) + (50,000 × $4.99) = $373,750 + $249,500 = $623,250
```

### Net Revenue (after RevenueCat 1% fee)

| Month | Gross Revenue | RevenueCat (1%) | Net Revenue |
|-------|---------------|-----------------|-------------|
| M6 | $3,117 | $31 | $3,086 |
| M12 | $31,118 | $311 | $30,807 |
| M18 | $93,356 | $934 | $92,423 |
| M24 | $249,300 | $2,493 | $246,807 |
| M36 | $622,750 | $6,228 | $616,523 |

### Annual Revenue Summary

| Year | Gross Revenue | Net Revenue (after RevenueCat) |
|------|---------------|-------------------------------|
| Year 1 | $92,900 | $91,971 |
| Year 2 | $1,583,644 | $1,567,807 |
| Year 3 | $5,394,075 | $5,340,134 |

---

## 5. Break-Even Analysis

### Monthly Break-Even Point

**Break-even = month where Net Revenue > Total Costs**

| Month | Net Revenue | Total Costs | Profit/Loss | Cumulative P/L |
|-------|-------------|-------------|-------------|----------------|
| M1 | $123 | $142 | -$19 | -$19 |
| M2 | $248 | $143 | +$105 | +$86 |
| M3 | $617 | $144 | +$473 | +$559 |
| M4 | $990 | $146 | +$844 | +$1,403 |
| M5 | $1,860 | $150 | +$1,710 | +$3,113 |
| M6 | $3,086 | $157 | +$2,929 | +$6,042 |
| M7 | $4,950 | $567 | +$4,383 | +$10,425 |
| M8 | $6,683 | $602 | +$6,081 | +$16,506 |

### **Break-Even: Month 2** ✅

CalcApp reaches monthly profitability in **Month 2** due to:
1. Extremely low infrastructure costs ($142/mo in Phase 1)
2. Even 35 paying subscribers generate $124/mo in revenue
3. Costs don't scale significantly until Phase 2 (M7+)

### Subscriber Count for Break-Even (by Phase)

```
Break-Even Subs = Total Costs / Blended ARPU
Blended ARPU = (0.714 × $2.99) + (0.286 × $4.99) = $2.136 + $1.427 = $3.56

Phase 1: $142 / $3.56 = 40 subscribers
Phase 2: $650 / $3.56 = 183 subscribers  
Phase 3: $3,991 / $3.56 = 1,121 subscribers
```

| Phase | Monthly Cost | Break-Even Subs | At 3.5% Conversion, MAU Needed |
|-------|-------------|-----------------|-------------------------------|
| Phase 1 | $142 | 40 | 1,143 MAU |
| Phase 2 | $650 | 183 | 5,229 MAU |
| Phase 3 | $3,991 | 1,121 | 32,029 MAU |

> CalcApp is profitable from essentially Day 1 of meaningful user acquisition. The unit economics are strongly favorable because costs are fixed/semi-fixed while revenue scales linearly with users.

---

## 6. Budget Guardrails

### 6.1 Per-Service Spend Caps

| Service | Phase 1 Cap | Phase 2 Cap | Phase 3 Cap | Alert at (% of cap) |
|---------|-------------|-------------|-------------|---------------------|
| Supabase | $30/mo | $50/mo | $100/mo | 80% |
| Cloudflare | $0/mo | $25/mo | $50/mo | 80% |
| Sentry | $30/mo | $30/mo | $100/mo | 90% |
| PostHog | $0/mo | $200/mo | $500/mo | 75% |
| GitHub | $20/mo | $20/mo | $50/mo | 90% |
| RevenueCat | $5/mo | $100/mo | $500/mo | N/A (scales with rev) |
| Cloud/Fly.io | $100/mo | $500/mo | $3,000/mo | 80% |
| **Total Cap** | **$185/mo** | **$925/mo** | **$4,300/mo** | **85%** |

### 6.2 Alert Thresholds

| Level | Trigger | Action | Responder |
|-------|---------|--------|-----------|
| 🟡 Warning | Service at 75% of cap | Slack notification | FinOps lead |
| 🟠 Alert | Service at 85% of cap | Email + Slack | Engineering lead |
| 🔴 Critical | Service at 95% of cap | PagerDuty + auto-block | CTO + FinOps |
| 🚨 Emergency | Total spend exceeds monthly cap | Kill non-essential services | CTO (immediate) |

### 6.3 Escalation Rules

```
1. WARNING (75%):
   → Log in #finops-alerts channel
   → FinOps lead reviews within 24h
   → Determine if legitimate growth or anomaly

2. ALERT (85%):
   → Immediate Slack + email to engineering lead
   → Root cause analysis within 4h
   → Document in incident log
   → Propose mitigation (upgrade plan vs. optimize)

3. CRITICAL (95%):
   → PagerDuty alert to CTO + FinOps
   → Auto-block new resource provisioning (if configured)
   → War room within 1h
   → Immediate action: throttle, cache, or upgrade

4. EMERGENCY (>100%):
   → Auto-scale-down non-critical services
   → CTO decision within 30 min
   → Post-mortem mandatory within 48h
```

### 6.4 Anomaly Detection Rules

| Rule | Condition | Action |
|------|-----------|--------|
| Spike Detection | >50% increase in any service MoM | Auto-alert + investigate |
| Runaway Costs | 3 consecutive months of >20% MoM growth | FinOps review mandatory |
| RevenueCat Sanity | Fee > 1.5% of revenue | Audit billing, check plan |
| Supabase Egress | >10GB/mo in Phase 1 | Review query patterns |
| PostHog Events | >1M events/mo before Phase 2 | Implement sampling |

---

## 7. Cost Optimization Opportunities

### 7.1 Quick Wins (Phase 1)

| Opportunity | Current Cost | Optimized Cost | Savings | Effort |
|-------------|-------------|----------------|---------|--------|
| PostHog free tier (1M events) | $0 | $0 | — | Already free |
| Cloudflare free tier | $0 | $0 | — | Already free |
| Supabase: optimize queries to stay in Pro limits | $25 | $25 | $0 | Medium |
| GitHub: Use free for OSS repos | $16 | $4 | $12/mo | Low |
| **Phase 1 Optimized** | **$142** | **$130** | **$12/mo** | — |

### 7.2 Phase 2 Optimizations

| Opportunity | Current Cost | Optimized Cost | Savings | Effort |
|-------------|-------------|----------------|---------|--------|
| PostHog: sampling at 50% | $150/mo | $75/mo | $75/mo | Low |
| Supabase: connection pooling | $25 | $25 | Prevents upgrade | Medium |
| Cloudflare: aggressive caching (95% hit rate) | $20 | $20 | Prevents origin costs | Medium |
| Sentry: rate limit to 10K events/mo | $26 | $26 | Prevents upgrade | Low |
| **Phase 2 Optimized** | **$650** | **$540** | **$110/mo** | — |

### 7.3 Phase 3 Optimizations

| Opportunity | Current Cost | Optimized Cost | Monthly Savings | Annual Savings |
|-------------|-------------|----------------|-----------------|----------------|
| Fly.io reserved capacity (prepay 1yr) | $500 | $375 | $125 | $1,500 |
| PostHog annual contract | $450 | $360 | $90 | $1,080 |
| Sentry annual plan | $80 | $64 | $16 | $192 |
| Supabase Enterprise (negotiate) | $75 | $60 | $15 | $180 |
| Cloudflare Enterprise (if needed) | $200 | $150 | $50 | $600 |
| Edge caching reduces Supabase reads 40% | — | — | $30 | $360 |
| **Phase 3 Optimized** | **$3,991** | **$3,665** | **$326/mo** | **$3,912/yr** |

### 7.4 Tier Downgrade Triggers

| Service | Downgrade From | Downgrade To | Trigger Condition |
|---------|---------------|--------------|-------------------|
| PostHog | Scale ($450) | Growth ($150) | <500K events/mo for 2 months |
| Sentry | Business ($80) | Team ($26) | <5K errors/mo for 3 months |
| Cloudflare | Pro ($20) | Free ($0) | <100K requests/mo |
| Supabase | Pro + addons | Pro base | <50K DB rows, <2GB storage |

---

## 8. FinOps Maturity Model

### Phase 1: INFORM (Months 1–6)

| Capability | Implementation | Owner | Status |
|------------|---------------|-------|--------|
| Cost visibility | Supabase dashboard + manual tracking | Founder | 🟡 Planned |
| Budget spreadsheet | Google Sheets, updated weekly | Founder | 🟡 Planned |
| Service tagging | Tag all resources with `env:prod/dev` | DevOps | 🟡 Planned |
| Monthly cost review | Calendar reminder, 15-min review | Founder | 🟡 Planned |
| RevenueCat dashboard | Monitor conversion + churn weekly | Product | 🟡 Planned |

**KPIs:**
- Know exact spend per service within 24h accuracy
- Track cost/MAU monthly
- Identify top 3 cost drivers

**Tooling:** Manual spreadsheets + service dashboards

---

### Phase 2: OPTIMIZE (Months 7–18)

| Capability | Implementation | Owner | Status |
|------------|---------------|-------|--------|
| Automated alerts | Slack webhooks from billing APIs | DevOps | ⬜ Future |
| Unit economics dashboard | Grafana/Metabase showing cost/user | FinOps | ⬜ Future |
| Right-sizing reviews | Quarterly review of all service tiers | Engineering | ⬜ Future |
| Commitment planning | Evaluate annual plans for PostHog, Sentry | FinOps | ⬜ Future |
| Waste detection | Identify unused resources monthly | DevOps | ⬜ Future |
| Cost anomaly alerts | Auto-detect >30% MoM spikes | DevOps | ⬜ Future |

**KPIs:**
- Reduce cost/MAU by 20% vs Phase 1
- Zero surprise bills (all services under cap)
- 100% of services have spend alerts configured

**Tooling:** Billing API integrations, Grafana dashboards, Slack alerts

---

### Phase 3: OPERATE (Months 19–36)

| Capability | Implementation | Owner | Status |
|------------|---------------|-------|--------|
| Real-time cost dashboard | Live cost/revenue ratio tracking | FinOps team | ⬜ Future |
| Automated right-sizing | Scripts auto-adjust capacity | Platform | ⬜ Future |
| FinOps-as-Code | Terraform cost policies, OPA rules | Platform | ⬜ Future |
| Showback/Chargeback | Cost allocation by feature team | FinOps | ⬜ Future |
| Predictive modeling | ML-based cost forecasting | Data | ⬜ Future |
| Vendor negotiation | Annual contracts, volume discounts | FinOps | ⬜ Future |

**KPIs:**
- Cost/MAU < $0.002
- Margin > 85%
- All services on committed/reserved pricing
- Forecast accuracy within 10%

**Tooling:** Custom FinOps platform, Terraform policies, ML forecasting

---

### Maturity Progression

```
Phase 1 (INFORM)          Phase 2 (OPTIMIZE)        Phase 3 (OPERATE)
─────────────────────    ─────────────────────    ─────────────────────
• Manual tracking         • Automated alerts       • Real-time dashboards
• Monthly reviews         • Quarterly right-size   • Auto-scaling policies
• Spreadsheet budgets     • Commitment savings     • Predictive forecasting
• Know your costs         • Reduce your costs      • Optimize continuously
                                                   
Cost awareness: 60%      Cost control: 80%        Cost mastery: 95%
```

---

## 9. Pricing Sensitivity Analysis

### Scenario Comparison: Conversion Rate Impact

**Base assumptions held constant:**
- MAU growth trajectory: same across all scenarios
- Pricing: Pro $2.99, Dev $4.99 (unchanged)
- Pro:Dev ratio: 71.4%:28.6% (unchanged)
- Costs: same infrastructure trajectory

### Monthly Revenue at Key Milestones

| MAU | Conversion Rate | Paid Subs | Monthly Revenue | Monthly Costs | Monthly Profit |
|-----|-----------------|-----------|-----------------|---------------|----------------|
| **250,000 (M12)** | | | | | |
| | 2.0% | 5,000 | $17,810 | $737 | +$17,073 |
| | 3.5% (base) | 8,750 | $31,118 | $737 | +$30,381 |
| | 5.0% | 12,500 | $44,500 | $737 | +$43,763 |
| **2,000,000 (M24)** | | | | | |
| | 2.0% | 40,000 | $142,480 | $2,992 | +$139,488 |
| | 3.5% (base) | 70,000 | $249,300 | $2,992 | +$246,308 |
| | 5.0% | 100,000 | $356,000 | $2,992 | +$353,008 |
| **5,000,000 (M36)** | | | | | |
| | 2.0% | 100,000 | $356,200 | $3,991 | +$352,209 |
| | 3.5% (base) | 175,000 | $623,250 | $3,991 | +$619,259 |
| | 5.0% | 250,000 | $890,500 | $3,991 | +$886,509 |

### Revenue Math (2% scenario at M36)

```
Paid subs at 2%: 5,000,000 × 0.02 = 100,000
Pro (71.4%): 71,400 × $2.99 = $213,486
Dev (28.6%): 28,600 × $4.99 = $142,714
Total: $356,200/mo
```

### 36-Month Cumulative Revenue Comparison

| Scenario | Year 1 Total | Year 2 Total | Year 3 Total | 3-Year Total |
|----------|-------------|-------------|-------------|-------------|
| Pessimistic (2.0%) | $53,086 | $904,939 | $3,082,329 | $4,040,354 |
| **Base (3.5%)** | **$92,900** | **$1,583,644** | **$5,394,075** | **$7,070,619** |
| Optimistic (5.0%) | $132,714 | $2,262,349 | $7,705,821 | $10,100,884 |

### Impact Analysis

| Metric | 2.0% | 3.5% (base) | 5.0% |
|--------|------|-------------|------|
| Break-even month | M2 | M2 | M1 |
| Year 1 profit (after costs) | $48,252 | $88,066 | $127,880 |
| Year 3 annual profit | $3,034,437 | $5,346,183 | $7,657,929 |
| Profit margin at scale (M36) | 98.9% | 99.4% | 99.6% |

### Key Insight

> CalcApp is **profitable in all scenarios** due to near-zero marginal costs. Even at 2% conversion, the business generates $4M+ over 3 years. The difference between scenarios is growth velocity, not survival. This is the structural advantage of a calculator app with SaaS pricing — compute costs are negligible relative to revenue.

### Sensitivity to Churn

| Monthly Churn | Pro Avg Lifetime | Pro LTV | Break-Even Impact |
|---------------|-----------------|---------|-------------------|
| 3% | 33 months | $98.67 | None |
| 5% (base) | 20 months | $59.80 | None |
| 8% | 12.5 months | $37.38 | None |
| 12% | 8.3 months | $24.82 | Still profitable M2 |

---

## 10. Runway Analysis

### Scenario A: Bootstrapped (No External Funding)

**Assumptions:**
- Initial investment: $0 (founder's time only)
- Fixed costs paid from revenue starting M1
- No salary drawn until profitable

| Month | Revenue | Costs | Monthly Cash Flow | Cumulative Cash |
|-------|---------|-------|-------------------|-----------------|
| M1 | $124 | $142 | -$18 | -$18 |
| M2 | $248 | $143 | +$105 | +$87 |
| M3 | $617 | $144 | +$473 | +$560 |
| M6 | $3,086 | $157 | +$2,929 | +$6,042 |
| M9 | $12,343 | $642 | +$11,701 | +$30,420 |
| M12 | $30,807 | $737 | +$30,070 | +$92,163 |

**Bootstrapped Timeline:**
- **Month 2:** Monthly profitable ✅
- **Month 4:** Revenue covers all costs + first founder payment (~$844/mo)
- **Month 8:** Revenue supports 1 full-time salary ($5,000/mo)
- **Month 12:** Revenue supports 2-3 full-time hires + costs ($30K/mo cash flow)
- **Month 18:** $92K/mo profit — can fund team of 8-10

**Runway if costs exceed revenue (worst case at Phase 2 transition):**

```
Maximum cash burn scenario: 
- Phase 2 costs kick in at M7 ($567/mo) before revenue catches up
- Revenue at M7: ~$5,000/mo (easily covers $567)
- NO negative runway exists beyond M1 in any scenario
```

> **Verdict:** CalcApp is self-funding from Month 2. No external capital needed for operations. Funding would only accelerate user acquisition (marketing spend), not cover operational costs.

---

### Scenario B: Funded ($500K Seed Round)

**Assumptions:**
- $500K raised at M0
- Monthly burn = costs + team (2 engineers × $8K + 1 marketer × $6K = $22K)
- Marketing budget: $10K/mo to accelerate growth
- Total monthly burn: $32K (operational) + service costs

| Month | Revenue | Burn (team + services + marketing) | Net Burn | Remaining Runway |
|-------|---------|--------------------------------------|----------|-----------------|
| M1 | $124 | $32,142 | -$32,018 | $467,982 |
| M3 | $617 | $32,144 | -$31,527 | $404,421 |
| M6 | $3,086 | $32,157 | -$29,071 | $312,280 |
| M9 | $12,343 | $32,642 | -$20,299 | $239,587 |
| M12 | $30,807 | $32,737 | -$1,930 | $188,520 |
| M13 | $35,000 | $34,991 | +$9 | **Break-even** |
| M15 | $62,000 | $34,991 | +$27,009 | $215,538 |
| M18 | $92,000 | $34,991 | +$57,009 | $386,565 |

**Funded Metrics:**

| Metric | Value |
|--------|-------|
| Total runway (if no revenue) | 15.6 months ($500K ÷ $32K/mo) |
| Break-even with team costs | **Month 13** |
| Remaining cash at break-even | **$188,520** (62% of runway preserved) |
| Cash-positive month | M13 |
| 18-month bank balance | $386,565 |
| Effective burn multiple (M12) | 0.06x (excellent) |

### Burn Rate Comparison

| Metric | Bootstrapped | Funded |
|--------|-------------|--------|
| Team from M1 | 0 FT (founder only) | 3 FT |
| Marketing spend | $0 (organic) | $10K/mo |
| Monthly break-even | M2 | M13 |
| Revenue at M12 | $31K/mo | $31K/mo (same growth) |
| Cash reserve at M12 | $92K (earned) | $188K (remaining) |
| Growth accelerated by | N/A | 2-3x (paid acquisition) |

### Funded Growth Premium (Accelerated MAU)

With $10K/mo marketing spend at $2 CAC:
- Additional 5,000 users/month acquired through paid channels
- Accelerates MAU milestones by ~3-4 months
- Phase 3 at M10 instead of M13

---

## Appendix A: Key Formulas Reference

```
Cost per MAU = Total Monthly Cost / MAU
Cost per Subscriber = Total Monthly Cost / Paid Subscribers
Blended ARPU = (Pro% × $2.99) + (Dev% × $4.99) = $3.56
LTV(Pro) = $2.99 × (1 / churn_rate) = $2.99 × 20 = $59.80
LTV(Dev) = $4.99 × (1 / churn_rate) = $4.99 × 33 = $164.67
LTV:CAC = LTV / CAC
Break-even Subs = Total Costs / Blended ARPU
Gross Margin = (Revenue - COGS) / Revenue
Net Margin = (Revenue - All Costs) / Revenue
Burn Multiple = Net Burn / Net New ARR
```

## Appendix B: Risk Register

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Supabase outage | Low | High | Multi-region backup, Fly.io failover |
| Conversion below 2% | Low | Medium | A/B test pricing, add features to Pro |
| PostHog cost spike (events explosion) | Medium | Low | Implement sampling, set hard cap |
| RevenueCat fee increase | Low | Low | Alternative: in-house billing at scale |
| App Store commission (if applicable) | Medium | High | Web subscriptions bypass, or budget 30% |
| Competitor undercuts pricing | Medium | Medium | Focus on UX moat, not price war |

## Appendix C: Decision Log

| # | Decision | Rationale | Date | Revisit |
|---|----------|-----------|------|---------|
| 1 | $2.99/$4.99 pricing | Low enough for impulse purchase, high enough for LTV | TBD | M6 |
| 2 | 3.5% target conversion | Industry avg for freemium utility apps (2-5%) | TBD | M3 |
| 3 | No App Store subscriptions initially | Avoid 30% cut, use web checkout via RevenueCat | TBD | M6 |
| 4 | PostHog over Mixpanel | Free tier generous, self-host option at scale | TBD | M12 |
| 5 | Delay Fly.io until Phase 3 | Supabase Edge Functions sufficient for Phase 1-2 | TBD | M9 |

---

*Document generated by FinOps Architect — CalcApp Mode 1 DESIGN Phase*  
*Next review: Phase 1 completion (M6)*
