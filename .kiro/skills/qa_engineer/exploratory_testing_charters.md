---
id: exploratory_testing_charters
version: 1.0.0
owners: [qa_engineer]
tags: [exploratory-testing, charters, session-based, james-bach, sbtm]
when_to_use: |
  Scripted tests have run, automation is green, but you suspect
  bugs hiding in interactions and edge cases. Exploratory testing
  finds the bugs your test plan didn't anticipate. NOT a replacement
  for automation — a complement to it.
inputs:
  - feature_under_test, risk_areas, time_box
outputs:
  - "exploratory_findings: charter results + bug reports + heuristics for future automation"
---

# Exploratory Testing — Session-Based, Charter-Driven

> Scripted tests verify the things you ALREADY thought of. Exploratory
> testing finds the bugs you DIDN'T think of. Both are essential.
> Skip one, miss half the defects.

## What it is — and isn't

**Exploratory testing IS:**
- Simultaneous learning, test design, and execution.
- Time-boxed sessions with a written goal (the "charter").
- Documented results that feed back into automation.

**Exploratory testing is NOT:**
- Random clicking. That's "monkey testing" — different discipline.
- "We didn't write a plan." Charters ARE the plan, just short.
- A replacement for regression automation. It finds NEW bugs;
  automation prevents OLD bugs from coming back.

## Session-Based Test Management (SBTM, Bach + Bolton)

A session has structure:

```
CHARTER (the mission):
  "Explore the password reset flow with focus on
   account-takeover protection using burner emails
   and slow networks."

SETUP (env, data, accounts): 10 min
TBC (test bursts) + bug investigation: 60-80 min
DEBRIEF (summary, bug report, next charter): 10 min
```

Total: 90 minutes is the typical session "atom." Longer than that
and attention degrades; shorter and setup overhead dominates.

## The charter — a one-sentence mission

```
Explore <area>
With <tools/data/conditions>
To discover <information>
```

Examples:
- "Explore checkout WITH multiple-currency carts TO discover
  rounding bugs."
- "Explore session timeout WITH idle browsers + Wi-Fi flapping
  TO discover lost-work scenarios."
- "Explore admin permissions WITH a downgraded role TO discover
  privilege-escalation gaps."

Charters bias the session toward known-risky territory. A good test
manager generates 5-10 charters per feature based on risk analysis.

## Heuristics — the question generator

Use a heuristic checklist to NOT miss obvious classes:

### SFDIPOT (James Bach — covers everything once)
- **Structure**: code, files, hardware
- **Function**: features
- **Data**: inputs, edges, formats
- **Interfaces**: APIs, UI, system calls
- **Platforms**: OS, browser, device
- **Operations**: usage patterns, sequences
- **Time**: concurrency, ordering, delays, timezones

### CRUSSPIC STMPL (quality criteria)
Capability, Reliability, Usability, Security, Scalability,
Performance, Installability, Compatibility, Supportability,
Testability, Maintainability, Portability, Localizability.

### Test idea triggers
- Boundary: 0, 1, MAX, MAX+1, negative, empty, huge.
- Order: forward, reverse, interleaved, partial.
- Time: timezone, DST, leap year, midnight rollover, fast clock,
  slow clock.
- Identity: same user twice, different users same session, deleted
  user resurrected.
- Network: offline, slow, intermittent, gateway 502.
- Resource: out of disk, out of memory, no permissions.

## Note-taking during the session

Don't write a novel; record enough to debrief and reproduce. The
SBTM standard: an annotated transcript.

```
12:14  set up burner email b@mailinator.com
12:15  reset password → email arrived in 3s
12:16  ! second reset request returned old token; first reset link
       NO LONGER WORKS - is this intended? → CAPTURED BUG_001
12:20  tried link after 2hr — token expired correctly
12:35  rate limit: 5 resets/minute? Triggered at 6th. Good.
12:40  ! 7th reset returned 500 not 429 — BUG_002
```

`!` marks something interesting. `?` marks a question. `BUG_NNN`
ties to a tracker ticket.

Tools: ScreenToGif / Loom for screen capture (debug aid). For
APIs: save the request/response pairs. Don't try to type the whole
session — record and re-annotate after.

## Pairing — the 2x bug-find rate

Two testers in one session find more bugs than two solo sessions.
One drives, one observes + suggests. Roles rotate every 20 minutes.
Use it for high-risk features and to onboard new testers (the
observer learns by watching).

## Debrief — the part most teams skip

15 minutes after the session ends:

1. Walk the charter — was it completed? Partially?
2. List bugs found, with severity guess.
3. List "smells" — things suspect but no clear bug.
4. List "untested" — what didn't get touched, and why.
5. Generate NEXT charter from the smells.
6. Identify automation candidates — any bug found here should
   become a regression test.

The debrief is the data product. Without it, exploratory testing
is just billable hours.

## Bug reports from exploratory work

Standard format:

```
Title: Password reset second request invalidates the first link
Severity: Medium (UX confusion, no security impact)
Reproduce:
  1. Request password reset for user@x.com
  2. Receive email with link L1
  3. Within 5 minutes, request a second password reset
  4. Receive email with link L2
  5. Click L1 → "invalid token"
Expected: Either L1 still works (until used) OR the second request
  is denied with a clear message.
Actual: L1 silently dies; user has no indication of why.
Found by: exploratory session 2026-04-12-A, charter "auth-flow"
Repro rate: 5/5
Logs: [link to session capture]
```

## What gets automated, what stays exploratory

| Bug | Automate? |
|---|---|
| Deterministic, reproducible in < 30 lines | YES — regression test |
| Triggers under load only | YES — load test scenario |
| Requires human judgment ("this UI is confusing") | NO — exploratory only |
| Cross-system (timezone × auth × payment) | YES, if scriptable |
| Found by intuition with hard-to-reproduce steps | Investigate more first |

Goal: every exploratory finding becomes EITHER (a) an automated
regression test, OR (b) a documented heuristic for future charters.
Otherwise the bug class will return.

## Anti-patterns

- **"Just click around."** Without a charter, sessions wander and
  miss high-risk areas. Always start with a mission.
- **No debrief.** Findings vanish into Slack. SBTM produces a
  written artifact every session.
- **Single tester always exploring the same area.** Familiarity
  blinds. Rotate areas across testers.
- **Treating it as "manual regression."** Different goal. Manual
  regression repeats KNOWN steps. Exploratory invents NEW ones.
- **Skipping it because "automation covers us."** Automation tests
  the things you THOUGHT to write. Exploratory finds the rest.
- **No time-box.** A "session" that runs 4 hours produces
  fatigue-driven, low-quality output. 90 min max.

## Beating exploratory bias

Testers naturally explore where they're comfortable. Counter:

- Rotate charters across testers.
- Use the SFDIPOT/CRUSSPIC checklist to force coverage.
- Pair newer testers with senior on hard charters; vice versa for
  fresh perspective.
- Periodically run "blind" sessions where a tester gets ONLY the
  charter and product, no walkthrough.

## Validation that exploratory testing is delivering

- [ ] Each release has ≥ N session reports filed (calibrate N to
      team size and risk).
- [ ] At least one bug per release is found by exploratory and
      MISSED by automation.
- [ ] The bug→regression-test rate is ≥ 50% (most findings become
      durable safety nets).
- [ ] Charter list is updated based on post-release defects (the
      charters reflect what's ACTUALLY risky, not just what looks risky).
