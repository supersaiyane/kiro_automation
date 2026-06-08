---
id: code_review_excellence
version: 1.0.0
owners: [senior_engineer_fe, senior_engineer_be]
tags: [code-review, pr, github, mentorship, quality]
when_to_use: |
  Every PR you author and every PR you review. Code review is the
  single highest-leverage quality activity in a software org. Skill
  it deliberately.
inputs:
  - pull_request: diff + description
outputs:
  - review_comments: structured by severity + the approval decision
---

# Code Review Excellence

## What review IS and ISN'T

**Is:**
- Defect prevention.
- Knowledge transfer (junior → senior AND senior → junior).
- A second pair of eyes on architecture creep.
- The cultural ledger — what gets approved becomes the standard.

**Isn't:**
- A taste contest.
- A blocker on petty style (the linter handles that).
- The author's first introduction to the requirements.
- A place to refight architecture decisions made in design review.

## As an AUTHOR — make the review possible

1. **Small PRs.** <400 lines diff. Reviewers' defect-detection drops
   sharply beyond ~500 lines.
2. **One concern per PR.** Refactor and feature in separate PRs.
3. **Write a real description.** What changed, why, how to test,
   what's NOT covered. Link the issue.
4. **Self-review first.** Read your own diff before requesting review.
   You'll catch half the issues.
5. **Annotate non-obvious decisions** with PR-line comments explaining
   why (the *why* doesn't belong in code comments; it belongs on the
   PR).
6. **Tests in the same PR.** No "tests will come in a follow-up."
   They won't.
7. **Choose reviewers deliberately.** Domain owner + one fresh eyes.
   Not "everyone in the channel."

## As a REVIEWER — leave the codebase better

### Read in this order
1. **PR description and tests first.** What is the PR trying to do?
2. **Public API and interfaces.** Are they shaped right?
3. **Implementation.** Now check the details.
4. **Edge cases.** What's NOT tested?

### Comment severity tags

Use tags in the comment so authors can triage:

- **[Blocking]** — must fix before merge. Bug, security issue,
  breaks contract.
- **[Suggestion]** — strong opinion; author can push back with
  reasons. Default: address it.
- **[Nit]** — taste / style. Optional. Don't block on nits.
- **[Question]** — you don't understand; the answer might be in the
  code or might reveal a missing comment / refactor.
- **[Praise]** — call out genuinely good work. (Yes, do this.)

### What to look for, in priority order

1. **Correctness** — does it do what the description says?
2. **Security** — input validation, authz checks, secrets, injection.
3. **Edge cases** — empty input, null, max length, concurrent access.
4. **Tests** — are they meaningful? Would they catch the bug the
   author was paid to fix?
5. **Naming** — does the name match what the thing does?
6. **API design** — once it's merged, you can't change it cheaply.
7. **Performance** — only if it's a known hot path. Don't speculate.
8. **Readability** — would a new hire understand this in 6 months?
9. **Style** — linter's job; don't waste cycles here.

### Things to never say

- "I would have done it differently." — irrelevant; explain why their
  way is wrong if it is.
- "Why didn't you …" — phrased as accusation. Use "Have you considered…"
- "This is wrong" — say *why* it's wrong and what right looks like.
- "LGTM 🚀" on a 1,500-line PR you spent 5 minutes on. That's lying.

## Approval discipline

- **Approve only what you've read.** If you skimmed, say "skimmed,
  approving the parts I read in detail" — name them.
- **One approval doesn't mean ship.** Domain owner + fresh eyes. CI
  green. Security review where required.
- **Block when blocking matters.** Don't be the reviewer everyone
  routes around.
- **Resolve threads as the author.** Don't let reviewers resolve their
  own threads unless they've verified the fix.

## Async expectations

- First review within 4 business hours of the request, or a "I'll get
  to it by EOD" reply.
- Author response to comments within 1 business day.
- A PR open >5 business days = something's wrong. Find out what.

## Anti-patterns

- The 1,500-line PR that "needs to merge by EOD." Refuse it. The
  refusal trains better PR hygiene.
- LGTM stamps from a senior who didn't read. Worse than no review —
  it gives false confidence.
- Re-litigating design decisions made in the design doc. Take it to
  a follow-up; don't block the PR.
- Comment threads that turn into design discussions. After 3 replies,
  move to a sync call; capture the decision back on the PR.
- "Nits only" reviews that miss a security bug. Calibrate where you
  spend attention.
- Bikeshedding (`if (x === undefined)` vs `if (typeof x === 'undefined'`)
  while the actual auth check is missing.
- Author merges their own PR with one rubber-stamp. No solo decisions
  on production code.
