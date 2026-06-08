---
id: onboarding_documentation
version: 1.0.0
owners: [technical_writer, engineering_manager]
tags: [onboarding, docs, day-one, getting-started, time-to-first-pr]
when_to_use: |
  Writing onboarding docs for a new team, a new project, or a new
  product. The metric is "time to first meaningful contribution"
  — the gap between Day 1 and Day-first-PR-merged. Onboarding
  docs that don't reduce that gap are decoration.
inputs:
  - target_role, existing_docs, common_day1_questions
outputs:
  - "onboarding_kit: ordered guide + checklist + troubleshooting + ownership map"
---

# Onboarding Documentation — Time-To-First-PR As The Metric

> The goal of onboarding docs is not to document. It's to get a
> new person from "first day" to "first meaningful contribution"
> faster than they would alone. If your docs aren't moving that
> number, they aren't working.

## The two onboarding audiences (different docs)

| Audience | What they need |
|---|---|
| New engineering hire | Local env, codebase tour, how-to-deploy, contributing guide |
| New product user | Account setup, key concepts, first task, where to learn more |

Different audiences need different docs. Don't merge them.

## The new-engineer onboarding kit

The directory:

```
ONBOARDING/
├── README.md                  ← entry point + journey overview
├── 01-day-one.md              ← first 4 hours
├── 02-local-env.md            ← exact commands to run
├── 03-codebase-tour.md        ← architecture mental model
├── 04-our-workflow.md         ← branching, PRs, deploys
├── 05-on-call-intro.md        ← we don't expect you to be on-call
├── 06-first-issue.md          ← curated "good first issue"
├── glossary.md                ← internal acronyms, project codenames
├── contacts.md                ← who owns what
└── troubleshooting.md         ← top 10 Day-1 errors + fixes
```

The numbered files are sequential. Day 1 follows them in order.

## Day-one.md — the most important file

The new hire opens THIS first. It should fit on one screen and end
with a working "hello world" change.

```markdown
# Welcome — your first 4 hours

## Hour 1: Accounts
You should have invites to:
- [ ] Slack: #team-engineering and #project-X
- [ ] GitHub: org/x and org/x-infra
- [ ] AWS / GCP: org-prod and org-staging (read-only at first)
- [ ] PagerDuty (no rotation yet)

If anything is missing, ping @manager-name immediately.

## Hour 2: Local environment
Follow `02-local-env.md`. Stop reading this and do it now.

## Hour 3: First PR
Follow `06-first-issue.md`. The curated first issue is small but
real — typo fix or test addition in `src/foo.py`. You will:
1. Open a branch.
2. Make the change.
3. Open a PR.
4. Get it reviewed and merged.

## Hour 4: Welcome lunch / 1:1 with @manager-name.

## End of day 1
You will have:
- A working local env.
- One PR merged.
- A view of the codebase.
```

Time-bound, actionable, ending in a concrete win. THAT'S onboarding.

## Local env doc — copy-paste-able commands

```markdown
# Local environment setup

## Prereqs
- macOS Sonoma or Ubuntu 22.04+
- Python 3.11 (`brew install python@3.11`)
- Docker Desktop running

## Setup
```bash
git clone git@github.com:org/x.git
cd x
./scripts/bootstrap.sh
```

Expected output: "All good — try `make run`."

## Run it
```bash
make run
```
Hit http://localhost:8080 — you should see "Hello, world."

## Troubleshooting

**"Port 8080 already in use"** → `lsof -i :8080` to find the
process. Kill it or change the port: `PORT=8081 make run`.

**"command not found: make"** (macOS) → `xcode-select --install`.

For everything else, see `troubleshooting.md` or ask in #help-eng.
```

Every command is copy-paste-able. Every expected output is named.
Every common failure has a fix.

## Codebase tour — the mental model

This is where most onboarding docs fail. They list directories
instead of giving a mental model.

```markdown
# Codebase tour

## The 30-second model
We have THREE services:
- **api**: handles HTTP requests, talks to DB
- **worker**: processes async jobs from the queue
- **web**: the React frontend served to users

All three live in this monorepo at `services/{api,worker,web}/`.

## How a request flows
A user clicking "create order" in `web` triggers:
1. POST /orders → `api/orders/create.py`
2. Validates + writes to DB → `api/db/orders.py`
3. Publishes `order.created` event → `api/events.py`
4. `worker/order_created_handler.py` picks it up
5. Sends confirmation email, updates inventory

Read those 5 files (in order) and you have 80% of the model.
```

Tell a STORY through the code. Pick one user action, trace it.
"Five files in order" is more useful than 30 README files.

## The first issue — curated, not random

A new hire's first issue is curated by the manager. Properties:

- **Small**: 50-200 lines of changes max.
- **Touches the canonical path**: forces them to learn the
  common workflow, not an edge case.
- **Well-defined**: acceptance criteria written, no ambiguity.
- **Has a reviewer assigned**: someone who can review same day.
- **Tagged `good first issue`**: collected for new hires; not
  user-facing.

A typo fix, a test for an under-tested module, a missing log line —
all good. A "rewrite the auth layer" is NOT a first issue, ever.

## Contacts + ownership map

```markdown
# Who to ask

| Topic | Person | Backup | Slack |
|---|---|---|---|
| Local env issues | @sara | @priya | #help-eng |
| Architecture questions | @julian (lead) | @ravi | #arch |
| Production incidents | on-call rotation | — | #incidents |
| HR / time off | @manager-name | — | DM only |
| Codebase: `api/` | @julian | @priya | — |
| Codebase: `worker/` | @ravi | @hema | — |
| Codebase: `web/` | @sara | @dan | — |
```

A new hire who knows who to ask is unblocked 10x faster.

## Glossary — defuse the acronym mines

Every team has internal language. New hires nod through it for
weeks. A glossary fixes this in one Confluence page:

```markdown
**OST** — Opportunity Solution Tree (our PM framework).
**DRAFT** — internal codename for the rewrite of `api`.
**Capybara** — internal name for our staging cluster.
**Bot-rot** — informal: when a runbook step has been broken
  for so long nobody remembers what it was supposed to do.
**P1 / P0** — incident severity. P0 = stop everything.
```

Maintained by the team. Updated when a new term appears more than
twice.

## The 30 / 60 / 90 plan

The hiring manager owns this — not the docs. But onboarding docs
should support it:

- **Day 30**: shipping small features, attending all team meetings,
  knows the team. Manager 1:1 reviews onboarding completeness.
- **Day 60**: owning a feature, on-call shadow.
- **Day 90**: full IC contribution; on-call primary; suggested
  process improvement based on fresh eyes.

The "fresh eyes" output is a gold-mine — what did onboarding miss?
Capture it; update the docs.

## Updating the docs continuously

Docs decay fast. Two rules:

1. **The newest hire updates the docs.** They JUST hit every pothole.
   Their first PR after onboarding should be doc fixes.
2. **Each retrospective reviews "what onboarding question came up
   this sprint?"** Answer → doc update.

A team that says "our docs are outdated" hasn't connected onboarding
to doc ownership.

## Anti-patterns

- **A 50-page handbook nobody reads.** Sequential, hour-by-hour
  beats the encyclopedia.
- **"Ask in Slack" as the documentation.** Wastes the team's time
  daily and doesn't scale.
- **A first task that requires understanding the whole system.**
  Day 1 is for "get my dev env running," not "redesign auth."
- **Onboarding doc owned by HR, content owned by no one.** Always
  has a tech owner.
- **Welcome packet stops at week 1.** Week 2-4 is when most
  new hires get blocked. Cover that too.
- **No buddy / mentor.** A peer who's been there 6 months is the
  single biggest unblock for a new hire.
- **Pretending the org is simpler than it is.** "We just ship."
  New hires read "we just ship" and discover 7 approval steps;
  trust erodes. Be honest.

## Validation that onboarding works

- [ ] Time-to-first-merged-PR is measured. Goal: < 3 working days.
- [ ] New hires after week 1 report feeling productive (NPS-style
      survey at week 2 and week 8).
- [ ] The last 3 hires' first PRs included doc fixes from their
      onboarding experience.
- [ ] Contacts map is up to date (no "person left 6 months ago").
- [ ] Glossary covers every acronym used in the team's last 10
      planning docs.
- [ ] Local env setup completes in < 1 hour for a new hire on a
      standard machine.
