---
id: toil_reduction
version: 1.0.0
owners: [sre, devops_engineer, backend_lead]
tags: [toil, sre, automation, ops-load, google-sre-book]
when_to_use: |
  On-call is burning out, the team complains about "ops work eating
  our sprints," or you can't tell whether the team's busy-ness is
  generating value or just keeping the lights on. Toil reduction
  is the SRE discipline of converting repetitive ops work into
  automation OR into the product roadmap.
inputs:
  - oncall_logs, ticket_categories, weekly_time_audit
outputs:
  - "toil_program: toil inventory + reduction targets + automation backlog + 50%-cap policy"
---

# Toil Reduction — Google SRE's 50% Rule, In Practice

> Toil is the work tied to running a service that is manual,
> repetitive, automatable, tactical, devoid of enduring value, and
> scales linearly with growth. Google SRE caps toil at 50% of an
> SRE's time. The other 50% must be engineering toil out of
> existence.

## Toil — the Google definition (precise)

A piece of work is toil if it has at least one of:

- **Manual** — a human has to do it.
- **Repetitive** — done over and over.
- **Automatable** — a machine could in principle do it.
- **Tactical** — interrupt-driven, reactive.
- **No enduring value** — the service is in the same state
  afterward.
- **O(n) with service growth** — twice the customers = twice the work.

Examples that ARE toil:
- Restarting a service when it OOMs.
- Manually rolling certs.
- Running the same diagnostic script per incident.
- Onboarding a new customer via a 12-step manual playbook.

Examples that ARE NOT toil:
- Capacity planning (engineering, not repetitive).
- Postmortem writing (enduring value).
- Designing a new service.
- Code review (judgment work).

Distinguishing toil from valuable ops work is the first step. A
"manual deploy" might feel like toil but if it has approval
checkpoints, it's controlled ops.

## Measuring toil — you can't reduce what you don't track

Two methods, pick one:

### Method A: Tag every ticket
Each incident, change ticket, support escalation gets a `toil:yes|no`
label and a time estimate. Reporting tool sums per quarter.

### Method B: Time-diary sampling
Once a week, each SRE answers: "of my hours last week, what %
was toil?" Calibrate via examples. Less precise but lower friction.

Either way, produce a chart:

```
                Toil % of SRE time, by quarter
   60% ┤                            ▓▓▓▓
        │              ▓▓▓▓        ▓▓▓▓
   50% ┤━━━━━━━━━━━━━━ cap ━━━━━━━━━━━━━━
        │ ▓▓▓▓        ▓▓▓▓
   40% ┤ ▓▓▓▓ ▓▓▓▓
        │ ▓▓▓▓ ▓▓▓▓
   30% ┤
        └─────┬─────┬─────┬─────┬─────┬───
              Q1    Q2    Q3    Q4    Q1
```

If toil crosses the cap, the team STOPS feature work (or platform
project work) until it's back under.

## The toil hierarchy of automation

Not all toil is worth automating. Rank by:

```
Toil score = (hours_per_year × pain_score) − (automation_cost)
```

| Frequency | Time per | Total / yr | Worth it? |
|---|---|---|---|
| Daily | 15 min | 65 hrs | YES — high ROI |
| Weekly | 1 hour | 50 hrs | YES |
| Monthly | 4 hours | 50 hrs | MAYBE — depends on automation cost |
| Quarterly | 8 hours | 30 hrs | RARELY worth it |
| Yearly | 40 hours | 40 hrs | RARELY (specifics matter) |

A one-off 40-hour task that won't recur is NOT toil — it's project work.

## The four reduction strategies

### 1. Eliminate
The cheapest fix. Question the work's existence.
- "Why do we restart this service nightly?" → fix the leak.
- "Why are we onboarding customers manually?" → self-serve onboarding.

### 2. Automate
A script, runbook automation, k8s operator, scheduled job.
- Toil: certificates rotated quarterly manually → cert-manager.
- Toil: deploy approval via Slack message → policy-as-code in CI.

### 3. Self-serve
Push the work out of SRE into the team that needs it.
- Toil: SRE provisions every DB → IDP-with-Crossplane self-service.
- Toil: SRE approves every flag flip → developer flag dashboard.

### 4. Re-architect
Sometimes the only fix is to make the system itself less toilsome.
- Toil: rebalancing shards monthly → use a database that auto-shards.
- Toil: stitching log files from N hosts → centralized log aggregation.

## The toil budget conversation with leadership

Leaders ask "why is the team slow?" Toil charts answer:

> "Last quarter, 62% of SRE hours went to toil. Top three categories:
> (1) cert rotation across 47 services, (2) onboarding 23 new
> customers manually, (3) responding to false-positive alerts. We
> are investing 6 engineer-weeks this quarter to drive all three
> categories below 5% of the toil pie. Expected output: SRE
> capacity for feature work goes from 38% to 60%."

This makes toil reduction a strategic investment, not a back-office grumble.

## The auto-remediation trap

"We'll just have a bot restart the service when it OOMs."

That's not toil reduction — that's HIDING the toil. The underlying
bug is still there, the human just doesn't see it. Symptoms of
this trap:
- Increasing automated restarts over time.
- The "fix" depends on the bot working perfectly.
- Postmortems mention "auto-remediation kept us afloat for weeks."

Auto-remediation is fine SHORT-TERM while the real fix is being
built. Set a deadline.

## Quarterly toil review

Cadence:

1. Pull the toil log for the quarter.
2. Rank categories by total hours.
3. For each top-5 category, decide: eliminate / automate /
   self-serve / re-architect / accept (with reason).
4. Each decision becomes a tracked engineering ticket with owner +
   due date.
5. Next quarter: same review. Did the categories move down?

Without the review-and-action loop, toil tracking is decoration.

## Anti-patterns

- **"It's not toil, it's important."** Plenty of toil IS important.
  The point is it shouldn't require a human.
- **Automating bad processes faster.** If the underlying process
  is wrong, automation just makes the wrong thing happen more.
  Eliminate first, automate second.
- **Toil-reduction projects with no deadline.** Becomes someone's
  20% project that never ships.
- **Counting project work as toil reduction.** "We built a new
  service" is not toil reduction — it's project work. Measure the
  actual toil hours saved.
- **SREs as the only ones tracking toil.** Stream teams have toil
  too. Spread the discipline.
- **The 50% cap as a target instead of a ceiling.** The goal is
  ZERO toil; the cap is a backstop.

## When the team is drowning RIGHT NOW

Emergency triage:
1. **Freeze feature work** for one week.
2. The whole team picks the #1 toil category by time.
3. Sprint to eliminate it (eliminate > automate > self-serve).
4. Resume feature work with that category gone.

Doing this once a quarter, focused, beats a year of "we'll get to it."

## Validation that toil reduction is real

- [ ] Toil % of SRE time is tracked and trending down.
- [ ] No category that consumed > 20 hrs / quarter is unaddressed
      in the current backlog.
- [ ] Auto-remediation has a sunset date and the underlying bug
      ticket is open.
- [ ] On-call satisfaction is improving (survey quarterly).
- [ ] SREs are working on projects with ≥ 6-month half-life
      (real engineering), not just keeping the lights on.
