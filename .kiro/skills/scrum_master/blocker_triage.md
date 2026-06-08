---
id: blocker_triage
version: 1.0.0
owners: [scrum_master]
tags: [blockers, triage, escalation, dependency, unblocking]
when_to_use: |
  Any standup where someone says "I'm blocked on X." Daily, in
  practice. The SM owns the blocker register; engineers should not be
  hunting for owners three days into a block.
inputs:
  - blocker_raised: who, on what, since when
outputs:
  - triage_action: assigned owner + ETA + escalation point + workaround
---

# Blocker Triage

## The 24-hour rule

Any blocker open >24h has cost the team a sprint day. The SM's job is
to keep that number near zero. **If you don't know who owns every
open blocker, you have no blocker register; you have a list of
complaints.**

## Triage in five questions (in order)

1. **Is this actually a blocker, or a friction point?**
   - Blocker: you cannot make progress until it's resolved.
   - Friction: it slows you, but you can route around it.
   Re-classify before logging — friction items inflate the register
   and dilute urgency.

2. **What's the smallest change that unblocks?**
   - Often the answer is *not* "fix the root cause." It's "stub it,"
     "mock it," "use the staging endpoint," "bypass the gate for this
     ticket with approval."
   - The root-cause fix goes in the backlog. The unblock goes in
     today.

3. **Who has authority to resolve?**
   Not who *can* help — who can *decide*. There's a difference.
   Examples:
   - DB schema change pending review → DB owner (named human)
   - Vendor outage → Vendor account-exec + our SRE on-call
   - Cross-team dep slipping → That team's EM, not their IC
   - Spec ambiguity → PM (only the PM can change scope)

4. **What's the workaround?**
   Even if the resolver is engaged, document a workaround. Engineers
   should never wait idle. Examples:
   - Pair with someone on a different task
   - Pick up the next-prioritized story
   - Spike on the harder follow-on while waiting

5. **What's the escalation timer?**
   - 4h: ping the named owner publicly.
   - 24h: escalate to their EM.
   - 48h: surface in the leadership standup.
   - 72h: re-plan the sprint.

## The blocker register format

```
ID | Raised | By | On (story) | Owner | ETA | Workaround | Escalation step
B-42 | 2026-01-12 09:00 | @alice | US-117 | @bob (Payments EM) | 2026-01-13 17:00 | mock /charge endpoint, run with FF off | step 2 of 4 (EM pinged)
```

Public, append-only, **never** lives in DMs.

## Common blocker patterns + their default play

| Pattern | Default play |
|---|---|
| Waiting on another team's API | Mock the contract from their OpenAPI, raise a tracker on their board, keep building |
| Waiting on legal/compliance review | Time-box the review (4 business days), surface to GC if missed |
| Waiting on a hire | The hire isn't a blocker — *scope* is the blocker. Cut scope, file the headcount need |
| "I'm stuck on a bug" | Not a blocker. Pair-debug session within the team, 1-hour cap, then escalate |
| Vendor outage | Workaround the dependency (cache, fallback, degrade mode); the vendor is not on your timeline |
| Cross-team priority conflict | EM-to-EM call within 24h, written outcome — the PMs can't resolve this |

## What the SM does (and doesn't) do

**Does:**
- Track every blocker in the register, publicly.
- Drive the workaround conversation.
- Escalate on the schedule.
- Surface chronic-blocker patterns (same team, same dependency, three
  sprints in a row → architecture problem, not blocker problem).

**Doesn't:**
- Solve the blocker themselves. They're not the technical owner.
- Promise things on behalf of the resolver.
- Quietly accept a sprint slip without making the cost visible.

## Anti-patterns

- "Blocked" used as cover for "I haven't started." Ask for the diff.
- Blockers raised in DMs and not in the register. They evaporate.
- Standups that recite blockers but never assign owners. The SM is
  the assigner.
- Escalating to the wrong layer. Going to the CTO when an EM-to-EM
  conversation would resolve it burns capital and trains people to
  ignore you next time.
- The "blocker buddy" pattern — pairing two equally-blocked engineers
  and calling them unblocked.
- Long-tail blockers (open >7 days) without weekly leadership surfacing.
  Out of sight = silently structural.
