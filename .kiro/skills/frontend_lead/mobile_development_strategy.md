---
id: mobile_development_strategy
version: 1.0.0
owners: [frontend_lead, senior_engineer_fe]
tags: [mobile, ios, android, react-native, capacitor, pwa, app-store]
when_to_use: |
  Deciding whether to build a mobile app — and HOW (native vs hybrid
  vs PWA). 60%+ of B2C traffic is mobile in 2026; even B2B trends
  > 40%. Choosing wrong locks in a multi-year cost mismatch.
inputs:
  - audience_devices, feature_requirements, team_skills, time_to_market
outputs:
  - "mobile_strategy: platform choice + tech stack + native bridges + distribution"
---

# Mobile Development Strategy

> The "native vs hybrid vs PWA" decision affects every line of code
> you write for years. Senior craft is asking the right questions
> BEFORE the team commits.

## The 4 mobile delivery paths

| Path | Build cost | UX | Native APIs | Update cycle | Best for |
|---|---|---|---|---|---|
| **Native iOS + Android** | 2× (two codebases) | Best | Full | App store review | Premium UX, deep native, big audience |
| **React Native / Flutter** | 1.2-1.5× | Very good | Most via bridges | Mostly OTA + occasional store | Cross-platform, native feel, mid budget |
| **Capacitor / Tauri Mobile** | 1× (web + thin shell) | Good | Most via plugins | Mostly OTA | Existing web app, fast time-to-market |
| **PWA (Progressive Web App)** | 0× (just web) | OK | Limited (improving) | Instant | Web-first, no app store needed |

There is NO universal winner. The right answer depends on your product.

## Decision framework

```
Does the product need:
  - Camera / sensors / Bluetooth / NFC / push notif?
  - Best-in-class scrolling / animation?
  - App-store presence for discovery / trust?
  - Offline functionality?

  YES (any 2+) → React Native, Flutter, or Native.

Web-app-with-native-wrapper sufficient (mostly content + forms)?
  YES → Capacitor or PWA.

How big is your team + budget?
  Small (1-3) → React Native or PWA.
  Mid (4-10) → React Native.
  Large with iOS + Android experts → Native (separate teams).

Time to market?
  ASAP → PWA or Capacitor.
  3-6 months → React Native.
  6-12 months → Native.

What's the existing tech?
  React web → React Native, Capacitor.
  Vue web → Capacitor, ionic.
  No web → Native, Flutter.
```

## Native (Swift iOS + Kotlin Android)

When it's the right call:
- Premium consumer app (banking, finance, fitness, social).
- Deep native integration (AR, ML on-device, BLE peripherals).
- 60fps animation requirement.
- Apple Watch / Wear OS companion.
- Big enough product to justify two engineering teams.

Tools:
- **iOS**: SwiftUI (modern) or UIKit (legacy/complex). Xcode.
- **Android**: Jetpack Compose (modern) or XML views (legacy). Android Studio.

CI/CD:
- **iOS**: Xcode Cloud, fastlane, Bitrise.
- **Android**: Gradle + GitHub Actions, Bitrise.

Cost: 2x web. Specialized hires required.

## React Native

The most-shipped cross-platform stack in 2026.

When it's the right call:
- Existing React team.
- 80-90% code sharing acceptable (some native modules expected).
- Want near-native UX without two codebases.

Tools:
- **Expo** — managed workflow; most teams start here.
- **React Native CLI** — eject when you need custom native modules.
- **Reanimated 3 + Gesture Handler** for animations.
- **React Navigation** for routing.
- **Zustand / Jotai / Redux Toolkit** for state.
- **TanStack Query** for data.

Updates:
- **Expo Updates / CodePush** for OTA JS updates — bypass app store
  review for non-native changes.
- Native changes require app store rebuild.

Trade-offs:
- Hot-loaded JS slightly slower than native first-render.
- Native API access via bridges — gap shrinks every year.
- Performance gap with native is small for most apps (< 5% perceptible).

## Flutter

Google's cross-platform with Dart. Excellent perf via own rendering
engine (Skia / Impeller). Single codebase, true 60fps usually.

When it's the right call:
- Heavy graphical / custom UI.
- Game-ish apps.
- Teams without React preference.

Trade-offs:
- Dart language (less universal than JS/TS).
- Smaller ecosystem than React Native.
- Less common in B2B SaaS.

## Capacitor

Modern Cordova successor. Wraps your existing web app in a native
shell with bridges to native APIs.

When it's the right call:
- Existing solid web app.
- Want app-store presence quickly.
- Native features needed only occasionally.

Tools:
- **Capacitor** (by Ionic).
- **Tauri Mobile** (Rust-based, smaller, newer).

Trade-offs:
- UX is web-quality, not native (scrolling, animations).
- App rejection risk: Apple sometimes rejects pure-web wrappers.

## PWA

No app store. User installs the web app via "Add to Home Screen."

When it's the right call:
- Audience won't install from store.
- Frequent updates needed.
- Geographic / demographic markets where app store isn't dominant.

Limitations (mostly iOS):
- Limited push notifications (Safari 16.4+ supports, with caveats).
- No camera/Bluetooth on iOS (some on Android).
- App-store discovery zero.
- Storage caps lower.

Modern PWA features (2026):
- **Service Worker** for offline.
- **Web App Manifest** for install.
- **Push API + Web Push** (limited iOS).
- **WebTransport** for streaming.
- **WebGPU** for compute.
- **File System Access API**.

## Distribution + app stores

### iOS App Store
- Annual fee: $99 (individual) / $299 (enterprise).
- Review: 1-7 days typical; rejections common on policy grounds.
- Mandatory APIs: App Tracking Transparency, Privacy Manifest (2024+),
  age rating, in-app purchase for digital goods.
- 30% revenue share (15% for < $1M revenue + subscriptions in Y2+).

### Google Play
- One-time fee: $25.
- Review: hours-days, often instant.
- Mandatory: Data Safety section, target SDK upgrades enforced.
- Same revenue share.

### Alternative distribution
- TestFlight (iOS beta) — 10k testers, 90-day expiry.
- Google Play Internal / Closed / Open testing.
- Enterprise distribution (sideload via MDM).
- Web (PWA) — bypass stores entirely.

## Performance

| Metric | Target |
|---|---|
| App size | < 100MB (above triggers WiFi-only download) |
| Time to interactive | < 2s on mid-range device |
| 60 FPS scrolling | Required for premium feel |
| Memory | < 200MB steady-state for most apps |
| Battery | Background work minimized |
| Network | Offline-first; graceful degradation |

Test on BUDGET Android (Pixel 6a, Samsung A14). Not just iPhone 15 Pro.

## Mobile-specific UX patterns

| Pattern | Use |
|---|---|
| Bottom tab bar | App-feeling, 3-5 destinations |
| Hamburger menu | Many destinations (avoid if possible) |
| Pull-to-refresh | List-based content |
| Swipe gestures | Stack navigation, dismissal |
| Bottom sheets | Replace modals on mobile |
| Native pickers | Date, time, color, file |
| Haptic feedback | Touch confirmation |
| Dark mode | System-aligned by default |

## App Store Optimization (ASO)

Like SEO for app stores:

- **Title** + subtitle/short description: target keywords.
- **Icon**: visually distinctive, test variants.
- **Screenshots**: first 2 most important (visible without scroll).
- **Preview video** (iOS) / Promo video (Play).
- **Ratings + reviews**: prompt at delight moments, not friction.
- **Localized** for major markets.

Tools: AppFollow, Sensor Tower, Storemaven for ASO experiments.

## Offline-first design

Mobile users have unreliable connections. Design for offline:
- **Optimistic UI**: write locally; sync when online.
- **Conflict resolution**: server-side or CRDT.
- **Cache strategy**: stale-while-revalidate by default.
- **Queue + retry**: pending mutations stored locally.

Libraries:
- **PouchDB / RxDB** — JS sync engines.
- **Realm** (now Atlas Device Sync) — native + sync.
- **WatermelonDB** — React Native local DB.

## Push notifications

Required for re-engagement on mobile (email open rates lower).

- **iOS**: APNs via Firebase / OneSignal.
- **Android**: FCM via Firebase / OneSignal.
- **Web push**: VAPID + Service Worker; limited on iOS.

Best practices:
- Permission ask AT FIRST VALUE, not first launch.
- User-controllable categories (per-feature opt-in).
- Don't over-send (3 per week max for most apps).
- Personalization > broadcast.

## Crash + perf monitoring

- **Crashlytics** (Firebase) — free, popular.
- **Sentry** — JS + native; integrates with React Native.
- **Embrace** — mobile-focused observability.
- **Datadog RUM Mobile** — paired with backend traces.

Track:
- Crash-free user rate (> 99%).
- ANR (Android-Not-Responding) rate.
- App start time (cold + warm).
- JS bundle load time (React Native).

## Anti-patterns

- **"Just wrap the website in a WebView"** — Apple rejection + bad UX.
- **Native build only for one platform** — half the audience excluded.
- **Same UX as web** — mobile patterns differ; respect them.
- **No offline strategy** — users hate "you're offline" screens.
- **Push spam** — uninstall driver.
- **No platform-aware UI** — iOS users hate Material; Android users hate
  iOS look-alike.
- **App-store-policy violations** — get banned.
- **Bundle size > 200MB** — won't install on cellular.

## Validation

- [ ] Platform decision documented + justified.
- [ ] Tech stack chosen + team trained.
- [ ] CI/CD wired (App Store Connect / Play Console).
- [ ] OTA update path established.
- [ ] App size < 100MB.
- [ ] Crash-free rate > 99%.
- [ ] ASO metadata + screenshots + localized for top markets.
- [ ] Offline-first pattern for any list / form.
- [ ] Push notification permission asked at right moment.
- [ ] Privacy Manifest (iOS) + Data Safety (Play) filled.
- [ ] Tested on budget Android device.
