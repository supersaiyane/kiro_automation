---
id: estimation_techniques
version: 1.0.0
owners: [scrum_master, product_manager, backend_lead]
tags: [estimation, story-points, planning-poker, t-shirts, no-estimates, cone-of-uncertainty]
when_to_use: |
  Sprint planning, roadmap planning, or capacity discussion. Bad
  estimation breaks roadmaps; over-estimation breaks trust; refusing
  to estimate frustrates stakeholders who need to plan. Pick a
  technique deliberately — it's not "story points or nothing."
inputs:
  - team_velocity_history, work_breakdown, planning_horizon
outputs:
  - "estimation_strategy: technique + cadence + how to communicate uncertainty"
---

# Estimation — From Story Points to #NoEstimates

> Estimates are a tool, not a contract. They communicate
> uncertainty and inform planning. When teams treat them as
> commitments, the whole system breaks.

## The cone of uncertainty (Boehm)

```
Variance multiplier (high) to (low):
  Project inception:  4x        0.25x
  Approved product:   2x        0.5x
  Requirements done:  1.5x      0.66x
  Design done:        1.25x     0.8x
  Coded:              1.1x      0.9x
  Tested:             1.0x      1.0x
```

A 4-week estimate at project inception is anywhere between 1 and
16 weeks. Same task estimated AFTER design narrows to 5 weeks ±25%.

**Implication**: don't ask for accurate estimates BEFORE the work
is understood. The estimate isn't a person problem — it's
information you don't have yet.

## Five techniques — match to context

| Technique | Granularity | Effort | When |
|---|---|---|---|
| Story points + planning poker | Per-story | Medium | Standard sprint planning |
| T-shirt sizing | Per-epic | Low | Roadmap / quarterly |
| Days/weeks | Per-task | Low | Small, well-understood work |
| #NoEstimates (count work items) | Per-story | None | Mature teams w/ flow metrics |
| Three-point (PERT: optimistic/likely/pessimistic) | Per-task | High | High-uncertainty critical path |

## Story points + planning poker

The classic. Numbers from a Fibonacci-like sequence (1, 2, 3, 5, 8,
13, 20, 40, 100). Larger gaps at higher numbers force "this is big,
break it down" conversations.

Workflow:
1. PO reads the story.
2. Team discusses (briefly) — what's involved, edge cases.
3. EACH person picks a card secretly.
4. Reveal simultaneously.
5. If spread is wide, low and high voters explain. Re-vote.
6. Converge or split the story.

The VALUE is the conversation, not the number. A team that goes
"3, 3, 3, 3, 3" without discussion is going through motions.

**Points are not hours**. They reflect: complexity + risk +
unknowns + effort. A 1-day task with high unknowns might be 5
points; a 3-day task that's pure crank-it-out might be 3.

## T-shirt sizing (XS / S / M / L / XL)

For roadmap-level planning, when stories aren't even fully written:

- XS: ≤ 2 days
- S: < 1 week
- M: ~1-2 weeks
- L: ~3-4 weeks
- XL: needs to be broken down (it's an epic, not a story)

Coarse, fast, less false precision than numerical points. Good for
quarterly planning where the work isn't refined yet.

## #NoEstimates — count work items instead

The argument: if your team breaks work into similar-sized stories
(through INVEST refinement), throughput becomes predictable from
COUNT alone:

> "We complete ~12 stories per sprint. There are 36 stories in the
> next epic. ETA: 3 sprints."

When it works:
- Refinement produces consistently-sized stories.
- Stories are 1-3 days each, not 1-3 weeks.
- Flow metrics (cycle time, throughput, WIP) are tracked.

When it doesn't:
- Stories vary wildly in size — count is meaningless.
- The work is unfamiliar (high unknowns can't be hidden in averages).

#NoEstimates is BEST for mature teams shipping similar work.
It's WORST for cross-functional epics with new tech.

## Three-point (PERT)

For long-pole tasks where you must communicate uncertainty:

```
Optimistic (O):  best case = 3 days
Likely (M):                  6 days
Pessimistic (P): worst case = 15 days

Expected = (O + 4M + P) / 6 = 7 days
Std dev  = (P - O) / 6      = 2 days

So: 7 days ± 2 days (~70% confidence)
```

Use sparingly — it's expensive. Reserve for: critical path items in
a project plan, deadlines being negotiated with execs.

## Velocity — what it is and isn't

Velocity = story points completed per sprint, averaged over 3+ sprints.

USE it for:
- Capacity planning (how much can we PROBABLY fit in the next sprint).
- Forecasting (3 epics of 80 points each at 25/sprint = ~10 sprints).

DON'T use it for:
- Comparing teams (Team A's 30 ≠ Team B's 30).
- Performance reviews (rewards inflation).
- Hard commitments. It's a probabilistic forecast, not a contract.

Velocity that's monotonically increasing is suspicious — usually
estimate inflation, not real productivity.

## Communicating estimates upward

A good estimate to leadership:

> "Our best guess is 4-6 sprints. Confidence ~70%. Risks that could
> push to 8: third-party API latency (haven't validated), unknown
> data migration scope (we'll know after spike A). We'll re-estimate
> after each of those."

Bad:
> "It'll take 5 sprints."

The bad version becomes a commitment. The good version stays an
estimate even as it tightens.

## Spikes — how to estimate the unestimable

When a story is too unknown to point ("integrate with vendor X"),
spike it:

- **Time-boxed** (1-3 days max).
- **Outcome**: enough understanding to estimate, NOT to implement.
- **Result**: a story that's now estimable.

Spikes are how you handle the wide end of the cone of uncertainty
without pretending you can estimate.

## Anti-patterns

- **Estimates as commitments**. Velocity is a forecast, not a
  promise. Reward accuracy of forecasts over completion of every
  story.
- **Sandbagging** (intentionally over-estimating to look good).
  Corrupts the data.
- **Re-estimating completed work** to "make velocity look better."
  History should be honest.
- **"Story points are hours"**. Once you do this conversion, the
  team will start gaming hours. Don't.
- **Estimates given before refinement**. Premature; the cone is too
  wide.
- **Manager challenges every estimate**. Team learns to inflate
  defensively. Trust the team's estimate, hold them accountable to
  the forecast (in aggregate).
- **One person estimates for the whole team**. Misses risks others
  see. Use poker / consensus.
- **Estimates without WHEN**. "5 points" means nothing without
  velocity context. Convert to calendar at communication time.

## When to NOT estimate at all

- Bug fixes — they don't estimate well, and estimating creates
  perverse incentives ("I'll claim it's 3 points so I have margin").
- One-day chores (less than overhead of estimating).
- Pure research (size doesn't predict; time-box instead).
- Trivial UI tweaks.

If 80% of stories are trivially small, you don't need points.
You need flow metrics.

## What to track over time

- **Velocity trend** — stable / up / down. If trending down, dig
  into why.
- **Forecast accuracy** — were last quarter's forecasts within ±20%?
- **Cycle time** — how long from "started" to "done". The leading
  indicator of velocity.
- **WIP** — high WIP = high cycle time. Limit it.

A team with stable velocity AND stable cycle time AND ±20% forecast
accuracy is mature.

## Validation that estimation is healthy

- [ ] Velocity has been stable (±20%) for 3+ sprints.
- [ ] Forecasts to stakeholders include uncertainty range, not
      single numbers.
- [ ] No story has been > L / 13 points without being broken down.
- [ ] No estimate is used as a performance metric for individuals.
- [ ] Spikes are used when uncertainty is high; nobody pretends
      to estimate the unknowable.
- [ ] Retrospectives review accuracy: did our 13-pointers really
      take longer than our 5-pointers?
