---
id: continuous_discovery_habits
version: 1.0.0
owners: [product_manager]
tags: [discovery, teresa-torres, opportunity-solution-tree, outcomes, jtbd]
when_to_use: |
  When the team is shipping features without confidence they'll move
  the metric. When stakeholders pitch solutions before defining the
  customer problem. When discovery is event-driven ("we'll do user
  research before this big launch") instead of continuous.
inputs:
  - desired_outcome: a business / product metric to move
outputs:
  - opportunity_solution_tree: outcome → opportunities → solutions → experiments
---

# Continuous Discovery Habits (Teresa Torres)

> Continuous discovery = weekly touchpoints with customers, run by the
> product trio (PM + design + eng), to keep the outcome → opportunity →
> solution chain honest.

## The four habits

1. **Weekly customer interviews.** At least one per week. Recorded,
   transcribed, reviewed by the trio. The bar is "talked to a real
   customer," not "read a survey."
2. **Map opportunities continuously.** Every interview adds entries to
   the opportunity solution tree (below). Don't wait for a "research
   project" — discovery is an ongoing flow, not a project phase.
3. **Test assumptions BEFORE building.** Each solution rests on a stack
   of assumptions (desirability, viability, feasibility, usability,
   ethicality). Identify the riskiest and run a cheap experiment first.
4. **Compare solutions, don't fall in love with one.** For each
   opportunity, brainstorm ≥ 3 candidate solutions. Score on
   feasibility + impact + confidence. Pick the best — but always
   start from at least 3.

## The Opportunity Solution Tree

```
                  Desired Outcome
                (one business metric)
                        |
        ┌───────────────┼───────────────┐
   Opportunity     Opportunity     Opportunity
   (customer       (customer       (customer
    need / pain)    need / pain)    need / pain)
        |               |               |
   ┌────┼────┐     ┌────┼────┐     ┌────┼────┐
   Sol  Sol  Sol   Sol  Sol  Sol   Sol  Sol  Sol
    |   |   |       |   |   |       |   |   |
   Exp Exp Exp     Exp Exp Exp     Exp Exp Exp  (assumption tests)
```

### Rules of the tree

- **Root = one outcome**, not many. A team that "owns" 5 metrics owns
  none.
- **Opportunities are CUSTOMER needs/pain points**, in the customer's
  voice. Not "users want a dashboard"; "users need to see this week's
  spend vs. budget before their Monday status meeting."
- **Solutions are options**, not commitments. Many will be killed by
  assumption tests. Keep them in the tree even after killing for the
  record of "we considered X, ruled it out because Y."
- **Experiments test the riskiest assumption first.** If the experiment
  fails, the solution branch is pruned — that's a successful experiment.

## Weekly cadence

| Day | Activity |
|---|---|
| Mon | Trio reviews last week's interview notes; updates the tree. |
| Tue/Wed | 1-2 customer interviews (45 min each, recorded). |
| Thu | Assumption test launches (prototype test, fake-door, smoke test). |
| Fri | Trio synthesis: what did we learn, what's our riskiest assumption now? |

## Anti-patterns

- **Solution-first thinking.** "We're going to build X" before naming
  the opportunity. Find the opportunity backwards: which need does X
  serve? If it serves none, kill it.
- **One big "research sprint" per quarter.** Discovery insights age
  out; treat them like fresh produce.
- **Surveys without follow-up interviews.** Surveys quantify; they
  don't reveal motivations or context. Use both.
- **Asking customers what to build** ("what features do you want?").
  They'll tell you, and they'll be wrong. Ask about their context,
  what they're trying to do, what they tried last time.
- **A solution tree drawn once and forgotten.** It's a living artifact.
  If it hasn't been updated this week, it's wrong.

## Validation that the practice is working

- The product trio can NAME their current riskiest assumption.
- Every story going into a sprint traces back to a specific opportunity.
- "Why aren't we building X?" is answerable by pointing at the tree.
- The team has killed at least one solution per quarter via testing.
