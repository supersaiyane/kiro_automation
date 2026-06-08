---
id: user_story_authoring
version: 1.0.0
owners: [product_manager]
tags: [user-story, requirements, acceptance-criteria, gherkin]
when_to_use: |
  Drafting or refining stories for the next sprint. Every story must be
  small enough to ship in one sprint and have testable acceptance criteria.
inputs:
  - feature_goal: short statement of value
outputs:
  - story: "As a … I want … so that …"
  - acceptance_criteria: Given/When/Then list
---

# User Story Authoring

**Story shape**: "As a [persona], I want [capability] so that [outcome]."

**Acceptance Criteria** — Given/When/Then, one per behavior:

```
Given a registered user with valid credentials
When they POST /auth/login with correct password
Then a 200 OK is returned with a JWT in the body
And the JWT expiry is 1 hour from now
```

**INVEST checklist**: Independent, Negotiable, Valuable, Estimable, Small, Testable.

**Anti-patterns**
- Stories that start with "the system should…" (no persona, no outcome).
- Vague criteria ("works correctly", "is fast").
- Stories that bundle frontend, backend, and infra — split them.
