---
id: blameless_postmortem
version: 1.0.0
owners: [sre_engineer, scrum_master]
tags: [postmortem, incident, sre, learning]
when_to_use: |
  Within 1 business day of any user-visible incident, or for any near-
  miss with the potential to become one.
inputs:
  - incident_timeline: detection -> mitigation -> resolution events
outputs:
  - postmortem: timeline, root cause, contributing factors, action items
---

# Blameless Postmortem

**Rule**: assume every actor did the best they could with the information
they had. Document the system condition that allowed the mistake to be
possible, not the person who tripped on it.

**Template**

```
# Postmortem: <incident title>

## Summary
1–3 sentences: what broke, who saw it, how long.

## Timeline (UTC)
- HH:MM  event
- HH:MM  detection signal fired
- HH:MM  on-call paged
- HH:MM  mitigation deployed
- HH:MM  resolved

## Root Cause
The mechanism. Not "X clicked deploy"; "deploy lacked staging gate AND
the config diff was not surfaced in the PR."

## Contributing Factors
- Anything that made the incident worse or harder to fix.

## What went well
- Detection was fast.
- Rollback worked first try.

## Action items
- [ ] owner | due-date | description (each must be testable)

## Lessons
- One paragraph that the team will reread next year.
```

**Anti-patterns**
- "Action item: be more careful." Not actionable.
- A postmortem that names a person as the cause.
- Action items with no owner or no due date.
- Lessons that are obvious in hindsight but had no warning system.
