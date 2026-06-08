---
id: incident_command_system
version: 1.0.0
owners: [sre, security_engineer, backend_lead]
tags: [incident-command, ics, fema, ic, scribe, comms-lead, oncall]
when_to_use: |
  Any incident large enough to need more than one human (SEV-2+).
  Without explicit roles, large incidents devolve into a Slack
  channel of overlapping action, lost context, and no decision
  authority. ICS is the FEMA-derived structure that wildfire and
  hurricane responders use; SRE adopted it because it works.
inputs:
  - incident_underway, severity, available_responders
outputs:
  - "incident_command_rolling: IC + ops + comms + scribe assigned, timeline kept, decisions logged"
---

# Incident Command System (SRE adaptation of FEMA ICS)

> The biggest incidents fail at COORDINATION, not at root-cause.
> ICS predefines who decides, who communicates, who acts, and who
> records — so the first 10 minutes don't burn solving "who's in
> charge?"

## The four core roles

Every SEV-2+ incident has these four roles, even if one human
plays two of them for the first 5 minutes:

| Role | Responsibility | Anti-responsibility |
|---|---|---|
| Incident Commander (IC) | Decides. Coordinates. Prevents chaos. | Doesn't fix the bug. |
| Ops Lead | Hands-on remediation. | Doesn't talk to stakeholders. |
| Comms Lead | Status updates to customers/exec/team. | Doesn't make technical decisions. |
| Scribe | Writes the timeline. Records decisions. | Doesn't act, doesn't decide. |

For very large incidents, add **Planning** (next-phase prep) and
**Liaison** (cross-team coordinator).

**Critical rule**: no role is the same person as another. If you
only have 2 people, IC + scribe; second person is Ops. Comms
goes to "delayed batch" until someone else joins.

## The IC's job in 5 actions

1. **Declare the incident.** "I am IC. This is SEV-2. War room
   is #inc-2026-04-12."
2. **Assign roles.** "@alice is Ops. @bob is Comms. @carol is
   Scribe."
3. **Set the cadence.** "Status update every 15 minutes in this
   channel."
4. **Make decisions.** Hear options, decide quickly, move on.
5. **Hand off cleanly when tired.** Long incidents need IC rotation.

The IC does NOT debug. The IC's value is keeping everyone else
unblocked.

## The "war room" — Slack channel discipline

Single channel per incident:

```
#inc-2026-04-12-checkout-503s
```

Standardized first messages from the IC:

```
:rotating_light: SEV-2 INCIDENT DECLARED :rotating_light:
- IC:     @alice (me)
- Ops:    @bob
- Comms:  @carol
- Scribe: @dan
- Symptom: 503 rate on /checkout = 18% (normal: < 0.1%)
- Customer impact: 1 in 5 checkouts failing
- Started: 18:42 UTC (35 min ago)
- War room: this channel. Status update every 15 min.
- Investigating: rollback of release v1.42.0 in progress.
```

Then enforce:
- ALL technical discussion in the channel (no DMs, no zoom-only).
- @here pings for the team, not @channel.
- Side conversations move to threads.
- The IC's word is final on direction. Disagreement → debate
  fast, decide, move on.

## The scribe's timeline (the most valuable artifact)

```
18:42  symptom first noticed in Datadog (high 503 rate)
18:47  on-call paged
18:51  IC declared SEV-2, war room opened
18:55  hypothesis: recent v1.42.0 release; rolling back
19:02  rollback to v1.41.7 complete
19:05  503 rate dropping — 12% → 4%
19:11  503 rate at baseline (< 0.1%); confirming on multiple regions
19:18  all regions clean; declaring INCIDENT-CLOSED
       owners assigned for postmortem (alice, bob)
       follow-up actions captured in #incident-tracker
```

Rules for the scribe:
- UTC timestamps always.
- Decisions, hypotheses, actions, results. NOT chatter.
- Quote the IC verbatim on decisions: "IC decision: rollback".
- DOES NOT investigate. Pure observer.

The timeline goes verbatim into the postmortem.

## Comms lead — the customer side

External comms cadence:

```
0-15 min:    "We're investigating reports of issues with X."
15-60 min:   "We've identified the issue affecting X; working on a fix."
60+ min:     "Update at <time>: progress + next update at <time>."
Resolution:  "We've resolved the issue. Postmortem coming."
```

Rules:
- Never speculate on cause.
- Never name a third party.
- Always commit to a NEXT update time, then meet it.
- Internal comms (exec, customer success) gets MORE detail at the
  same cadence.

If legal/regulated, Comms loops in legal counsel BEFORE the first
public message.

## Severity matrix (calibrate to YOUR business)

| SEV | Definition | Response |
|---|---|---|
| 1 | Total outage, customer data risk, regulatory exposure | All hands, IC immediately, exec paged |
| 2 | Major degradation, large customer impact | Full ICS team, IC immediately |
| 3 | Partial degradation, scoped customer impact | IC + ops, comms only if visible |
| 4 | Internal issue, no customer impact | One on-call, ticket only |

Sev assignment is the IC's call early; it's revisable as
information arrives. Err high; downgrade later.

## Handoff (long incidents)

After 2-3 hours, the IC is degrading. Hand off:

```
Outgoing IC: Bob, you have IC. Here's where we are:
  - SEV-2 still active.
  - Hypothesis 3 (DB lock contention) being investigated by Carol.
  - Rollback was tried at 19:02 and didn't help — DON'T retry.
  - Next external comm due 21:00 (in 22 min) — already drafted.
  - Pending decisions: do we engage AWS support? (yes if no
    progress by 21:15)

New IC: I have IC. Acknowledged.
```

Outgoing IC steps fully out of the role (they can stay in the
war room as observer). Two ICs = no IC.

## Decision logging — for the postmortem

Every IC decision goes in the channel:

```
@alice [IC decision] Rolling back to v1.41.7. Authorizing now.
  Rationale: 503 rate spiked at the v1.42.0 deploy time.
  Risk: undoes the customer fix for issue Z; we accept this.
```

Postmortems debate decisions later. Decisions made under pressure
deserve transparency about what was known at the time.

## Tabletop drills (monthly)

A scenario card, 90 minutes, real war room channel, real ICS roles.
Run by someone who's not on-call this week. Variations:

- "DB primary failover took 18 min; replica lag has built up; do
  we cut over or wait?"
- "Customer reports data leak in their account. What do we do
  in the first 30 minutes?"
- "Auth service is throwing 5xx on 30% of requests, no obvious
  recent change. Start investigating."

After-drill debrief:
- Was the IC clear? Did Ops feel directed?
- What slowed the response? (Bad runbook? Missing dashboard?
  Unclear ownership?)
- What gets fixed BEFORE the next drill?

## Anti-patterns

- **No IC.** Everyone investigates, nobody coordinates, dupes
  effort, drops the ball on comms.
- **IC also debugging.** Cognitive overload; one of the two fails.
- **DMs flying around.** Decisions made out of channel disappear
  from the timeline.
- **Comms via VP.** Exec wants to broadcast updates personally;
  fine, but the official record is the channel, and Comms still
  drafts.
- **No timeline.** Postmortem becomes "what happened?" via memory
  reconstruction. Useless.
- **Premature root-cause naming.** "It's definitely Redis" before
  evidence — locks the team into one hypothesis.
- **Skipping the postmortem because it "got fixed."** The
  postmortem is the value extraction; without it, you'll repeat
  the incident.

## Post-incident — the first 24 hours

Within 24h of resolution:
- IC posts a one-paragraph summary in #incidents (or equivalent).
- Action items from the war-room timeline are filed as tickets,
  assigned, prioritized.
- Postmortem is scheduled within 5 business days.

Postmortem itself — see `engineering:incident-response` for the
detailed structure.

## Validation that ICS is in muscle memory

- [ ] On-call can name the four ICS roles without looking them up.
- [ ] Last incident had all four roles assigned in the first
      10 minutes.
- [ ] The scribe's timeline is the canonical record (no separate
      "real timeline" reconstructed later).
- [ ] IC rotation happened on any incident longer than 3 hours.
- [ ] Tabletop drills are running monthly with multiple SEVs covered.
- [ ] Postmortems consistently cite the war-room timeline rather
      than reconstructing from chat archeology.
