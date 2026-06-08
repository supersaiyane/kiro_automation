# CTO Strategy & Tech Vision — CalcApp

**Role:** CTO | **Phase:** THINK | **Date:** 2025-01-15
**Upstream Input:** Market Research (TAM $1.36B, SOM $9.4M ARR Y3)
**Product:** Cross-platform smart calculator (iOS + Android + Web PWA)

---

## 1. Strategic Principles

Each principle is falsifiable — a team can point to a decision and say "this violates principle X."

| # | Principle | Falsification Test |
|---|-----------|-------------------|
| SP-1 | **Offline-first, sync-second** — All calculation operations execute locally with zero network dependency. Sync is eventual, never blocking. | Violated if any calculation requires a network call to complete. |
| SP-2 | **Single codebase, native performance** — One shared logic layer (Dart/Flutter) targeting iOS, Android, and Web from a single repository. No platform-specific calculation engines. | Violated if we maintain separate native codebases or if platform-specific code exceeds 5% of total LOC. |
| SP-3 | **Buy commodity, build the differentiator** — Authentication, payments, analytics are purchased. Cross-platform sync engine, natural math parser, and unified calculation modes are built in-house. | Violated if we build our own auth system or buy a third-party math engine for core calculation. |
| SP-4 | **Sub-100ms interaction latency** — Every user input (keypress, mode switch, history recall) renders a result in <100ms on a 2020-era mid-range device (Snapdragon 665 equivalent). | Violated if P95 interaction latency exceeds 100ms on benchmark device. |
| SP-5 | **Data portability over lock-in** — User calculation history is exportable in open formats (JSON, CSV, LaTeX). No proprietary binary formats for user data. | Violated if user data is stored in a format that requires CalcApp to read. |

---

## 2. Tech Stack Decision

| Layer | Choice | Version | Why (this product) | Simpler Option / Trade-off |
|-------|--------|---------|-------------------|---------------------------|
| **Frontend (Mobile + Web)** | Flutter | 3.24.x (Dart 3.5) | Single codebase → iOS + Android + Web PWA from one repo. Dart compiles to native ARM + JavaScript. Skia rendering gives pixel-identical math rendering across platforms. | React Native — loses web PWA target without Expo web (immature), loses custom canvas rendering for graphing mode. |
| **Calculation Engine** | Custom Dart library (`calcapp_core`) | Internal v1.0 | Core differentiator. Handles arbitrary-precision arithmetic, symbolic algebra, expression parsing (Pratt parser), and graphing evaluation. Must be pure Dart for cross-platform portability. | Use `math_expressions` pub package — loses natural math input, programmer mode (bitwise ops), and persistent AST for history replay. |
| **Local Storage** | Isar Database | 4.0.x | Embedded NoSQL optimized for Flutter. Zero-copy reads, async writes, 200μs query latency. Stores calculation history, user preferences, sync queue. | SQLite via `sqflite` — loses automatic Dart object mapping, requires more boilerplate, but would work. |
| **Sync Backend** | Supabase (PostgreSQL + Realtime) | Self-hosted or Cloud | Postgres for structured history sync. Row-Level Security for multi-tenant isolation. Realtime subscriptions for cross-device sync. Open-source, avoiding hard lock-in. | Firebase Firestore — loses SQL query flexibility, vendor lock-in to Google, higher cost at scale ($0.18/100K reads vs Supabase $0.01/100K). |
| **Authentication** | Supabase Auth (GoTrue) | Bundled with Supabase | Supports email/password, OAuth (Google, Apple, GitHub). Integrated with RLS policies. No additional vendor. | Firebase Auth — adds second vendor dependency, requires bridging two auth systems. |
| **Payments/Subscriptions** | RevenueCat | SDK 7.x | Handles Apple/Google IAP receipt validation, subscription lifecycle, trial management. Platform-required for mobile subscriptions. Web payments via Stripe integration within RevenueCat. | Build custom receipt validation — 3-6 months dev time, ongoing Apple/Google API changes. Not a differentiator. |
| **CI/CD** | GitHub Actions | N/A | Flutter-native actions available. Matrix builds (iOS/Android/Web) in parallel. Free tier sufficient for early stage. | Codemagic — Flutter-specialized but $75/mo minimum, premature cost. |
| **Hosting (Web PWA)** | Cloudflare Pages | Free tier → Pro $20/mo | Edge-deployed globally, <50ms TTFB. Free SSL, automatic cache invalidation. PWA service worker support native. | Vercel — $20/mo for same features but less edge coverage in Asia (key student market). |
| **Hosting (Backend/Sync)** | Supabase Cloud → Self-hosted (Phase 3) | Pro $25/mo | Managed Postgres + Auth + Realtime. Migrate to self-hosted on Fly.io when exceeding $200/mo (~10K MAU Pro tier). | AWS RDS + custom API — $150/mo minimum, over-engineered for Phase 1. |
| **Observability** | Sentry (errors) + PostHog (analytics) | Sentry 8.x, PostHog Cloud | Sentry: crash reporting with Flutter SDK, source maps for web. PostHog: product analytics, feature flags, session replay. Both have generous free tiers. | Datadog — $15/host/mo, overkill for mobile-first app with minimal backend. |
| **CDN / Assets** | Cloudflare R2 + CDN | Pay-as-you-go | Zero egress fees. Stores graph exports, shared calculation links, user profile images. | AWS S3 + CloudFront — egress costs scale poorly ($0.09/GB vs $0/GB on R2). |

---

## 3. Build-vs-Buy Table

### Decision Matrix Scoring (1-5 scale, higher = favors that option)

| Component | Decision | Differentiation (0.30) | Time-to-Market (0.20) | 3-Year TCO Build | 3-Year TCO Buy | Op. Burden (0.15) | Lock-in Risk (0.10) | Compliance (0.10) | Weighted Score (Build) | Weighted Score (Buy) | 18-Month Payback |
|-----------|----------|----------------------|---------------------|-----------------|---------------|------------------|--------------------|--------------------|----------------------|--------------------|-----------------| 
| **Math/Calc Engine** | BUILD | 5 | 2 | $85K (2 eng × 3mo + maintenance) | N/A (no adequate vendor) | 2 (low — embedded lib) | N/A | 5 (no data leaves device) | 3.85 | N/A | Payback at 500 Pro subscribers (Month 4). Engine enables all 3 tiers. $85K / $2.99×500×18 = 3.1x return. |
| **Authentication** | BUY (Supabase Auth) | 1 | 5 | $120K (custom auth + security audits + ongoing patches) | $0-$300/mo ($0-$10.8K over 3yr) | 5 (managed) | 2 (GoTrue is OSS, portable) | 4 (SOC2 included) | 2.30 | 4.10 | Buy saves $109K over 18 months. Custom auth ROI negative — not a differentiator. |
| **Payments/Subscriptions** | BUY (RevenueCat) | 1 | 5 | $200K (receipt validation + Apple/Google API maintenance + compliance) | $36K (1% of revenue, est. $100K rev × 3yr cap) | 5 (managed) | 3 (can switch to custom at scale) | 5 (PCI handled) | 1.95 | 4.45 | Buy saves $164K in eng time over 18 months. RevenueCat fee at $100K ARR = $1K/yr. |
| **Cross-Platform Sync Engine** | BUILD | 5 | 3 | $60K (1 eng × 2mo + CRDT library integration) | $48K (Firebase $1.3K/mo at 50K MAU × 3yr) | 3 (moderate) | 1 (full control) | 5 (data stays in our Postgres) | 3.70 | 3.15 | Payback at 1,000 sync-enabled users (Month 6). Sync is a top-3 differentiator per market research. Build cost recovered via Pro tier upsell. |
| **Analytics/Product Metrics** | BUY (PostHog) | 1 | 5 | $90K (custom analytics pipeline + dashboards) | $0-$450/mo ($0-$16.2K over 3yr) | 5 (managed) | 2 (OSS, self-hostable) | 3 | 2.00 | 4.30 | Buy saves $74K over 18 months. Zero eng distraction. |
| **Error Monitoring** | BUY (Sentry) | 1 | 5 | $50K (custom crash reporting infra) | $312/yr team plan ($936 over 3yr) | 5 (managed) | 2 (OSS core) | 4 | 2.00 | 4.50 | Buy saves $49K over 18 months. No payback period needed — instant ROI. |
| **Graph Rendering Engine** | BUILD | 5 | 3 | $40K (1 eng × 1.5mo, Flutter Canvas API) | $24K (Desmos API licensing estimate, limited customization) | 2 (embedded) | 1 (full control) | 5 (no network) | 3.85 | 3.00 | Payback at 200 Pro subscribers (Month 3). Graphing is P2 segment key feature. Custom engine allows offline + export. |
| **Push Notifications** | BUY (Firebase Cloud Messaging) | 1 | 5 | $30K (custom push infra per-platform) | $0 (free tier covers 100K+ MAU) | 5 (managed) | 3 (platform-standard, replaceable) | 4 | 2.00 | 4.50 | Buy saves $30K over 18 months. FCM is free at our scale. |

### TCO Summary
| | Build Total (3yr) | Buy Total (3yr) | Net Savings |
|---|---|---|---|
| Build items (Engine + Sync + Graphing) | $185K | N/A | These ARE the product. No buy equivalent. |
| Buy items (Auth + Payments + Analytics + Errors + Push) | $490K (if built) | $63K | **$427K saved** by buying commodity |

---

## 4. Approved Vendor List (Closed Set)

**Rule:** Any technology not on this list requires a formal build-vs-buy evaluation escalated to CTO before adoption.

| Vendor | Capability | Contract Status | Monthly Cost (at scale) | Exit Cost Estimate | Exit Strategy |
|--------|-----------|----------------|------------------------|--------------------|---------------|
| **Supabase** | Auth + Database + Realtime sync | Cloud Pro plan, month-to-month | $25-$100/mo | LOW ($2K migration) | Standard Postgres export. GoTrue is OSS. Migrate to self-hosted Supabase or raw Postgres + custom API. |
| **RevenueCat** | Subscription management + IAP | Standard terms, 1% rev share | $0-$100/mo (1% of IAP revenue) | MEDIUM ($15K, 2mo eng) | Build custom receipt validation. RevenueCat stores no user data we can't recreate from Apple/Google. |
| **Cloudflare** | CDN + Pages + R2 Storage + DNS | Pay-as-you-go | $0-$20/mo | LOW ($500 DNS migration) | Move to Vercel (pages) + AWS S3 (storage). Standard static hosting. |
| **Sentry** | Error monitoring + crash reporting | Team plan, annual | $26/mo | LOW ($1K, 1 week) | Switch to self-hosted Sentry (OSS) or GlitchTip. Standard SDK swap. |
| **PostHog** | Product analytics + feature flags | Cloud free → Scale | $0-$450/mo | LOW ($3K migration) | Self-host PostHog (OSS) or migrate to Amplitude. Event schema is portable. |
| **GitHub** | Source control + CI/CD (Actions) + Issues | Team plan $4/user/mo | $16/mo (4 users) | LOW ($500) | Git is portable. Actions workflows rewrite to GitLab CI (~1 week). |
| **Firebase (FCM only)** | Push notifications | Free (Google Terms) | $0 | LOW ($2K) | Switch to OneSignal or custom APNs/FCM direct integration. |
| **Fly.io** (Phase 3) | Self-hosted backend compute | Pay-as-you-go | $30-$150/mo | LOW ($3K) | Standard Docker containers. Move to Railway, Render, or AWS ECS. |

### Explicitly NOT Approved (with rationale)
| Vendor | Why Rejected |
|--------|-------------|
| AWS (full suite) | Over-engineered for Phase 1-2. Minimum viable backend is $150/mo vs $25/mo Supabase. Revisit at >50K MAU. |
| Firebase Firestore | Proprietary query model, no SQL, vendor lock-in HIGH. Egress costs unpredictable. |
| MongoDB Atlas | No relational integrity for sync conflict resolution. Supabase Postgres covers our needs. |
| Algolia | No search requirement in MVP. Calculator history is local-first, filterable client-side. |
| Stripe Direct | RevenueCat wraps Stripe for web. Direct Stripe adds IAP complexity we don't need separately. |

---

## 5. Risk Register

| ID | Risk | Severity | Likelihood | Impact | Mitigation | Owner | Review Cadence |
|----|------|----------|-----------|--------|------------|-------|----------------|
| R-1 | **Flutter Web performance insufficient for complex graphing** — Canvas rendering on WASM may not hit 60fps for real-time graph manipulation on low-end Chromebooks (student segment). | HIGH | MEDIUM (40%) | Revenue: P1 segment (students) churns from web app. Est. $1.2M ARR impact (40% of SOM). | 1. Benchmark Flutter Web Canvas vs HTML5 Canvas in Sprint 1. 2. If <45fps on Chromebook baseline: isolate graphing to platform-specific HTML5 Canvas via `HtmlElementView` on web only. 3. Fallback: static SVG rendering for graph export (no real-time manipulation on web). | CTO + Frontend Lead | Monthly through Phase 1 |
| R-2 | **Supabase Realtime scalability ceiling** — Supabase Realtime (Phoenix Channels) documented limit is ~10K concurrent connections per project. At 50K MAU with 20% concurrent = 10K connections. | HIGH | MEDIUM (35%) | Sync failures at growth inflection point. Users lose cross-device history. Churn spike in Pro tier. | 1. Implement client-side sync queue (CRDTs) that tolerates connection drops gracefully. 2. At 5K concurrent connections: evaluate Supabase self-hosted with horizontal scaling on Fly.io. 3. At 8K: migrate Realtime to custom WebSocket server (Elixir/Phoenix) on dedicated infra. Budget: $15K migration. | CTO + Backend | Quarterly, starting Month 6 |
| R-3 | **Apple App Store rejection for calculator app with subscription** — Apple has rejected calculator apps charging subscriptions when free alternatives exist. Requires demonstrable "above and beyond" value. | HIGH | MEDIUM (30%) | Blocks iOS revenue entirely. iOS = 55% of target market. $5.2M ARR at risk. | 1. Ensure Pro features are clearly "above and beyond" (sync, history, graphing, export). Standard calculator mode stays free forever. 2. Pre-submission: Apple Design consultation (free program). 3. Prepare appeal documentation citing Pcalc, Calculator+ precedents. 4. If rejected: offer Pro as tip jar + feature unlock (non-subscription). | Product + CTO | Pre-launch gate |
| R-4 | **Natural math input parser edge cases cause incorrect results** — Custom Pratt parser for expressions like "2sin(30) + √(16)/2!" may misparse ambiguous notation, producing wrong answers silently. | CRITICAL | MEDIUM (45%) | Trust destruction. One viral "this app gives wrong answers" post = category death. Unrecoverable brand damage. | 1. Property-based testing (QuickCheck-style) with 10K+ generated expressions per CI run. 2. Comparison oracle: validate against Wolfram Alpha API for random sample of 100 expressions per release. 3. Ambiguous inputs show disambiguation UI ("Did you mean 2×sin(30) or 2sin(30°)?"). 4. Launch with "beta" label on natural input, standard keypad as default. | Engineering Lead | Every PR touching parser |
| R-5 | **RevenueCat single-vendor dependency for 100% of subscription revenue** — RevenueCat outage = no new subscriptions processed, no trial conversions, no renewal receipts validated. | MEDIUM | LOW (15%) | Revenue loss during outage: est. $800/hr at scale (based on $9.4M ARR / 8760 hrs × conversion window). | 1. RevenueCat has 99.95% SLA (historically 99.99% uptime). 2. Implement grace period: app grants Pro access for 72hrs if receipt validation fails (cached entitlement). 3. At $5M ARR: build parallel receipt validation as hot standby (read Apple/Google receipts directly). Budget: $15K. | CTO | Semi-annually |
| R-6 | **Dart/Flutter ecosystem risk — Google deprioritization** — Google has historically abandoned frameworks (Angular 1, Polymer, Stadia). Flutter team layoffs in 2024 signal potential reduced investment. | MEDIUM | LOW (20%) | Forced rewrite in 2-3 years. Estimated cost: $300K-$500K. 12-month delay on features. | 1. Flutter is OSS with strong community (160K GitHub stars, active forks). Even without Google, community can maintain. 2. Architecture isolates business logic in pure Dart packages — portable to any Dart runtime. 3. If Flutter dies: Dart logic recompiles; UI layer rewrites to React Native or native (~6 months for existing feature set). 4. Decision gate: if Flutter has <3 stable releases in any 12-month period, initiate migration planning. | CTO | Annually |
| R-7 | **GDPR/CCPA compliance for calculation history sync** — Synced calculation history may contain PII (financial calculations, personal data in variable names). Requires proper consent, deletion, and portability. | MEDIUM | HIGH (70%) | Regulatory fine up to 4% of revenue (small at our scale) + mandatory app store privacy label issues + trust damage. | 1. Privacy-by-design: all sync data encrypted in transit (TLS 1.3) and at rest (AES-256). 2. Implement "Delete My Data" one-click wipe (Supabase RLS + cascade delete). 3. No server-side analytics on calculation content — only metadata (count, timestamp, mode). 4. Privacy label audit before each app store submission. 5. Legal review of Terms of Service before Pro tier launch. | CTO + Legal | Pre-launch, then quarterly |

---

## 6. Platform Strategy

### Architecture: Shared Core + Thin Platform Shells

```
┌─────────────────────────────────────────────────────────────────┐
│                        CalcApp Architecture                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              calcapp_core (Pure Dart Package)              │   │
│  │                                                            │   │
│  │  • Expression Parser (Pratt parser, arbitrary precision)   │   │
│  │  • Calculation Engine (Standard/Scientific/Programmer)     │   │
│  │  • Graph Evaluator (function → point set)                 │   │
│  │  • History Manager (CRDT-based, offline-first)            │   │
│  │  • Sync Protocol (conflict resolution, queue management)  │   │
│  │  • Unit Converter + Constants Library                     │   │
│  │                                                            │   │
│  │  Target: 0% platform imports. 100% testable in pure Dart. │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                    │
│  ┌───────────────────────────┼──────────────────────────────┐   │
│  │           Flutter UI Layer (Shared Widgets)                │   │
│  │                                                            │   │
│  │  • Calculator Keypad (responsive, haptic feedback)        │   │
│  │  • Expression Display (real-time LaTeX rendering)         │   │
│  │  • Graph Canvas (CustomPainter, gesture handling)         │   │
│  │  • History List (searchable, groupable by date)           │   │
│  │  • Settings & Subscription Management                     │   │
│  │                                                            │   │
│  │  Shared: 95%+ of UI code across all platforms             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                    │
│  ┌─────────┐  ┌─────────┐  ┌──────────────┐                   │
│  │   iOS   │  │ Android │  │   Web PWA    │                   │
│  │  Shell  │  │  Shell  │  │    Shell     │                   │
│  ├─────────┤  ├─────────┤  ├──────────────┤                   │
│  │ APNs    │  │ FCM     │  │ Service Wkr  │                   │
│  │ Haptics │  │ Haptics │  │ IndexedDB    │                   │
│  │ iCloud? │  │ Widgets │  │ Web Share    │                   │
│  │ Keychain│  │ Keystore│  │ localStorage │                   │
│  └─────────┘  └─────────┘  └──────────────┘                   │
│       <5% platform-specific code per shell                       │
└─────────────────────────────────────────────────────────────────┘
```

### Cross-Platform Sync Strategy

| Aspect | Implementation |
|--------|---------------|
| **Conflict Resolution** | Last-Write-Wins (LWW) with vector clocks per calculation entry. No merge conflicts possible — calculations are append-only. Edits to variable names use operational transform (OT). |
| **Offline Queue** | Isar local DB stores pending sync operations. On connectivity restore, batch-upload with idempotency keys. Server deduplicates via calculation UUID. |
| **Sync Protocol** | Supabase Realtime (WebSocket) for live sync when online. Polling fallback every 30s if WebSocket fails. Full reconciliation on app launch (compare local HEAD hash with server). |
| **Data Format** | Each calculation stored as: `{id: UUIDv7, expression_ast: JSON, result: string, mode: enum, created_at: ISO8601, device_id: string, vector_clock: map}` |
| **Encryption** | End-to-end: calculation content encrypted client-side with user-derived key (PBKDF2 from password). Server stores ciphertext only. Enables zero-knowledge sync. |

### Platform-Specific Adaptations (< 5% of codebase)

| Platform | Adaptation | Rationale |
|----------|-----------|-----------|
| iOS | Haptic feedback (UIFeedbackGenerator), iCloud Keychain for encryption key backup | Apple HIG compliance, key recovery |
| Android | Material You dynamic theming, home screen widget (Jetpack Glance via platform channel) | Android design language, quick-access |
| Web | Service Worker for offline caching, IndexedDB as Isar backend, keyboard shortcuts | PWA installability, desktop UX |

---

## 7. Scalability & Performance Targets

### User Scale Projections (from market research GTM)

| Milestone | Timeline | MAU | Concurrent Users (peak) | Pro Subscribers | Data Volume |
|-----------|----------|-----|------------------------|-----------------|-------------|
| Launch | Month 1 | 1,000 | 100 | 0 | 50 MB total |
| Phase 1 (Students) | Month 6 | 25,000 | 2,500 | 250 | 5 GB total |
| Phase 2 (Pro) | Month 12 | 100,000 | 10,000 | 3,000 | 50 GB total |
| Phase 3 (Dev) | Month 24 | 300,000 | 30,000 | 15,000 | 300 GB total |
| Year 3 target | Month 36 | 500,000 | 50,000 | 26,000 | 800 GB total |

### Performance Targets (Concrete, Measurable)

| Metric | Target | Measurement Method | Threshold for Action |
|--------|--------|-------------------|---------------------|
| **Keypress-to-display latency** | P95 < 50ms | Flutter DevTools frame timing on Pixel 6a (mid-range baseline) | >80ms = P1 bug |
| **Expression evaluation time** | P95 < 100ms for expressions ≤ 50 tokens | Microbenchmark suite, CI-gated | >150ms = blocker |
| **Graph render (100 points)** | P95 < 16ms (60fps) | CustomPainter benchmark on Pixel 6a | >32ms = drop to 30fps fallback |
| **Graph render (1000 points)** | P95 < 33ms (30fps) | CustomPainter benchmark on Pixel 6a | >50ms = progressive rendering |
| **App cold start** | < 2.0s (iOS), < 2.5s (Android), < 1.5s (Web FCP) | Measured on physical devices + Lighthouse | >3.0s = P1 bug |
| **App warm start** | < 500ms all platforms | Time from resume to interactive | >800ms = P2 bug |
| **Sync latency (device-to-device)** | P95 < 3s when both online | End-to-end timestamp measurement | >5s = investigate |
| **Offline queue drain** | 100 pending calcs synced in < 10s on 3G | Throttled network test | >30s = batch optimization |
| **History search (10K entries)** | P95 < 200ms | Isar query benchmark | >500ms = add index |
| **APK size** | < 15 MB (Android), < 25 MB (iOS) | CI size check | >20 MB Android = tree-shake |
| **Web bundle (initial)** | < 500 KB gzipped (main.dart.js) | Webpack bundle analyzer | >750 KB = code split |
| **Memory usage (idle)** | < 80 MB RAM | Platform profilers | >120 MB = memory leak hunt |
| **Memory usage (graphing)** | < 150 MB RAM | Platform profilers during graph interaction | >200 MB = object pooling |
| **API response time (sync endpoint)** | P95 < 200ms | Supabase dashboard + custom monitoring | >500ms = query optimization |
| **Database query time** | P95 < 50ms | Postgres `pg_stat_statements` | >100ms = index review |
| **Availability (sync service)** | 99.9% monthly (43min downtime max) | Uptime monitoring (BetterUptime) | <99.5% = incident review |
| **Crash-free rate** | > 99.5% sessions | Sentry crash-free metric | <99% = release blocker |

### Scalability Architecture Decisions

| Scale Trigger | Action | Estimated Cost | Timeline to Implement |
|---------------|--------|---------------|----------------------|
| 5K concurrent WebSocket connections | Enable Supabase connection pooling (PgBouncer) | $0 (config change) | 1 hour |
| 10K concurrent connections | Migrate to self-hosted Supabase on Fly.io (2 regions) | $150/mo | 2 weeks |
| 50K MAU on sync | Add read replicas (Fly.io Postgres) | $100/mo per replica | 1 week |
| 100K MAU on sync | Shard by user_id hash (4 shards) | $400/mo total | 4 weeks |
| 300K MAU | CDN-cached read paths + edge functions for non-personalized data | $50/mo (Cloudflare Workers) | 1 week |
| 1M+ MAU | Re-evaluate: dedicated infra (AWS/GCP), multi-region active-active | $2K-$5K/mo | 8 weeks |

---

## 8. Technical Constraints (Binding)

These are NOT guidelines. They are binding decisions. Violation requires CTO escalation.

| ID | Constraint | Rationale |
|----|-----------|-----------|
| C-1 | ✅ Dart 3.5+ for all business logic. ❌ No Kotlin/Swift for calculation code. | Single codebase principle (SP-2). |
| C-2 | ✅ Flutter 3.24+ for UI. ❌ No React Native, no Xamarin, no native UI code beyond platform channels. | Consistency, single team skill set. |
| C-3 | ✅ PostgreSQL for server-side data. ❌ No MongoDB, no DynamoDB, no Firestore. | Relational integrity for sync conflicts, ACID for financial calculations. |
| C-4 | ✅ Supabase for backend services (Phases 1-2). ❌ No AWS/GCP services until >50K MAU validated. | Cost control, complexity reduction. |
| C-5 | ✅ All user calculation data encrypted client-side before sync. ❌ No server-side plaintext storage of calculation content. | Zero-knowledge architecture, GDPR compliance (SP-5). |
| C-6 | ✅ Semantic versioning for all packages. ❌ No breaking changes without major version bump. | Consumer trust, update safety. |
| C-7 | ✅ CI must pass (lint + test + build) before any merge to main. ❌ No `--no-verify` pushes. | Quality gate enforcement. |

---

## 9. Decision Log

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2025-01-15 | Flutter over React Native | Single codebase for mobile + web. Dart's ahead-of-time compilation gives near-native performance. Flutter web maturity sufficient for PWA (not complex web app). React Native lacks production web target. | React Native + Expo Web (immature web), Kotlin Multiplatform (no web), Native × 3 (3x cost) |
| 2025-01-15 | Supabase over Firebase | Open-source, standard Postgres, predictable pricing, no vendor lock-in. Firebase Firestore's NoSQL model doesn't suit our relational sync requirements. | Firebase (lock-in), AWS Amplify (complexity), Custom backend (premature) |
| 2025-01-15 | Build math engine, don't buy | No vendor provides: natural input parsing + arbitrary precision + programmer mode + offline-first + history replay from AST. This IS our product. | Wolfram API (online-only, $$$), mathjs (JS-only, no Dart), Sympy (Python, wrong platform) |
| 2025-01-15 | Isar over SQLite for local storage | Native Dart, zero-copy reads, automatic object mapping, built for Flutter. SQLite via FFI adds complexity and platform-specific builds. | sqflite (more boilerplate), Hive (no queries), ObjectBox (license concerns) |
| 2025-01-15 | RevenueCat over custom IAP | Apple/Google receipt validation is complex, changes frequently, and is not a differentiator. RevenueCat's 1% fee is negligible vs engineering cost of custom solution. | Custom receipt validation ($200K+), Adapty (smaller, less Flutter support) |

---

## 10. Success Metrics (CTO-Level)

| Metric | Year 1 Target | Year 3 Target | Measurement |
|--------|--------------|--------------|-------------|
| Engineering velocity | 1 release/week (mobile), continuous (web) | 2 releases/week all platforms | Release cadence tracking |
| Test coverage | >80% line coverage on `calcapp_core` | >90% core, >70% UI | `lcov` in CI |
| Uptime (sync) | 99.9% | 99.95% | BetterUptime monitoring |
| P95 interaction latency | <80ms | <50ms | Automated performance benchmarks |
| Infrastructure cost / MAU | <$0.005/MAU/month | <$0.002/MAU/month | Monthly cost review |
| Time-to-recover (incidents) | <4 hours | <1 hour | Incident log |
| Security vulnerabilities (critical) | 0 unpatched >7 days | 0 unpatched >3 days | Sentry + `dart pub audit` |

---

*Document ends. This strategy is the binding constraint set for all downstream architecture and implementation decisions. Any deviation requires CTO re-evaluation with written rationale.*
