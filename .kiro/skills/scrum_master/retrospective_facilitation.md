---
id: retrospective_facilitation
version: 1.0.0
owners: [scrum_master, engineering_manager]
tags: [retro, facilitation, kaizen, safety, action-items]
when_to_use: |
  End of a sprint, end of a project, after an incident, or any
  time a team needs to reflect and improve. A retro WITHOUT
  facilitation is "complaint session." A retro WITH facilitation
  and tracked action items is the highest-leverage hour of the
  sprint.
inputs:
  - team_psyhological_safety, sprint_events, prior_action_items
outputs:
  - "retro_outcome: ranked themes + 1-3 action items with owners + dates + tracking"
---

# Retrospective Facilitation — Pull, Don't Push

> A facilitator's job in a retro is NOT to share their opinion.
> It's to make the team's thinking visible to itself and end with
> 1-3 concrete actions someone owns.

## Preconditions — without these, don't run a retro

1. **Psychological safety**. If people fear retaliation, they
   won't share. Build it BEFORE running the retro:
   - Manager-as-facilitator dampens candor; rotate facilitation.
   - Establish "Vegas rules" (what's said stays in the retro
     unless agreed otherwise).
   - Prime Directive (Norm Kerth): "Regardless of what we discover,
     we understand and truly believe that everyone did the best job
     they could, given what they knew at the time, their skills and
     abilities, the resources available, and the situation at hand."
2. **A real time-box**. 60-90 min for a 2-week sprint. Less = rushed.
   More = fatigue.
3. **All teammates present**. Cross-section view; absences distort.
4. **Last retro's actions reviewed first**. Otherwise retros are
   theater.

## The 5-stage Esther Derby / Diana Larsen format

```
1. SET THE STAGE      (5-10 min)
2. GATHER DATA        (15-25 min)
3. GENERATE INSIGHTS  (15-25 min)
4. DECIDE WHAT TO DO  (10-15 min)
5. CLOSE              (5 min)
```

The biggest mistake: skipping straight to "what should we change?"
without first GATHERING DATA. You end up debating opinions instead
of working from evidence.

### Stage 1 — Set the stage
- Recap the sprint goal, timebox, and prime directive.
- Check-in question (one word: "how are you feeling about this
  sprint?"). Gets every voice in the room early. Silent people in
  the first 5 min usually stay silent for the whole retro.

### Stage 2 — Gather data
Pick ONE format per retro; rotate to keep it fresh:

- **Glad / Sad / Mad**: simple, emotion-led.
- **Start / Stop / Continue**: action-oriented.
- **4Ls** (Liked, Learned, Lacked, Longed For): reflective.
- **Mad / Sad / Glad / Afraid**: adds future-facing.
- **Sailboat**: anchors (what's slowing us), winds (helping us),
  islands (goal), rocks (risks ahead).
- **Timeline**: lay out the sprint chronologically; team marks
  high/low moments. Surfaces patterns scripted formats miss.

Silent writing for 5-7 min (everyone post-its independently). Then
each person reads their items. Cluster on the wall by theme. The
clustering itself surfaces what the team thinks matters.

### Stage 3 — Generate insights
This is the "why" stage. For the top 2-3 clusters:
- 5 Whys.
- "What happens upstream of this?"
- "What would have to be true for this to be different?"

Beware: it's tempting to jump to "we should fix this" before
understanding cause. Resist.

### Stage 4 — Decide what to do
- Vote on which theme to act on (dot voting, 3 votes / person).
- For the WINNING theme(s), generate concrete actions.
- Each action MUST have: owner, due date, success criterion.
- **Max 1-3 actions per retro**. Five actions = none done.

### Stage 5 — Close
- Plus / Delta on the retro itself (kaizen on the kaizen).
- Anyone want to flag something for next time?
- Thank the team. Walk out.

## The action item is the deliverable

A retro produces ONE OR TWO action items, each:

- One owner (not "the team").
- A due date (within 2 weeks ideally).
- A success criterion ("we have a checklist", "the build runs in
  < 5 min", "we've had no after-hours pages from this service").
- Tracked WHERE THE TEAM CAN SEE IT (top of next retro's deck;
  pinned in Slack; ticket in the board).

Reviewing them at the NEXT retro is the discipline that proves
retros are worth doing.

## Anti-patterns

- **Manager as facilitator AND participant**. Power dynamics kill
  candor. Rotate.
- **Whole team venting for 60 min**. Without converging on action,
  team learns retros are pointless and disengages.
- **5+ action items**. None will get done. Pick 1-3.
- **No owner**. Group ownership = no ownership.
- **No follow-up**. Last retro's actions need to be reviewed first
  every time, with status.
- **Same format every sprint**. Boredom = disengagement. Rotate.
- **Skipping the retro for "schedule"**. The sprint where you skip
  the retro is the one you NEED it.
- **Action items that require leadership approval but weren't
  raised with them**. Filter for "we can do this ourselves" vs
  "this needs to escalate" before assigning.

## Special retros

### Post-incident retro (different from postmortem)
- Postmortem = the document (root cause, action items).
- Retro = the team conversation about HOW THE TEAM responded
  (decision speed, communication, on-call experience).
  Often run AFTER the postmortem is written.

### Project / epic retro
After a long initiative ends: WIDER scope, look at decisions made
6+ months ago, what we'd do differently. Use a timeline format.

### Quarterly / annual
Zoom out from sprint-level to team-process level. "What patterns
have we seen all quarter?" Themes-only, no sprint-specifics.

## Remote / hybrid retros

- A digital whiteboard (Miro, Figjam, Mural, Whiteboard.io) replaces
  the sticky wall.
- Silent writing happens in the tool. Then each person reads aloud
  on video.
- Voting via the tool's dot feature.
- **Camera on rules** for the facilitator at minimum. Engagement
  is dramatically worse with cameras off.
- Schedule for the LATEST timezone-friendly slot; the global
  team is in the room.

## Facilitator's calibration checklist

Each retro, the facilitator should:
- Make sure every person spoke at least once in stages 1 and 2.
- Pull on quiet voices ("Pat, what's your read?").
- Cut off ramblers gently ("Great point — let's capture that on
  a sticky and move on").
- Avoid sharing personal opinions on themes; you're the facilitator
  this hour, not a contributor.
- Park tangents in a "parking lot"; come back if time permits.
- Keep the timebox honest. End on time. EVERY TIME.

## Validation that retros are paying off

- [ ] Action items from previous retros have ≥ 70% completion rate.
- [ ] No retro in the last quarter produced 5+ action items.
- [ ] The same theme hasn't appeared 4+ retros in a row without
      visible progress (sign that the action items aren't working).
- [ ] Team members can name a CONCRETE change that came from a
      retro in the last 6 weeks.
- [ ] Facilitation rotates; not always the same person.
- [ ] Retro happens consistently — at least 80% of sprints, never
      skipped two in a row.
