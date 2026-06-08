---
id: chaos_engineering
version: 1.0.0
owners: [sre_engineer, devops_engineer]
tags: [chaos, resilience, fault-injection, game-day, dependency]
when_to_use: |
  Once a service has SLOs, a deployment pipeline, and an on-call
  rotation — but you don't know what really happens when its
  dependencies fail. Chaos turns "we think it's resilient" into
  "we've proven it."
inputs:
  - service + dependency graph + recovery SLOs
outputs:
  - experiment_plan: hypothesis, blast radius, runbook, success criteria
---

# Chaos Engineering

## The principles (from netflix's Principles of Chaos)

1. **Build a hypothesis about steady-state behavior.** What metric
   should NOT change when you inject the fault?
2. **Vary real-world events.** Network latency, CPU saturation,
   instance death, DNS failure — what actually happens in prod.
3. **Run experiments in production.** Or as close as you can. Staging
   doesn't have prod load, prod traffic mix, or prod weird states.
4. **Automate experiments to run continuously.** A one-off game day
   is theater. Continuous = signal.
5. **Minimize blast radius.** Smallest possible scope; ready to abort.

## The maturity ladder

Don't start at the top. Climb deliberately.

| Level | What you do | Example |
|---|---|---|
| 0 | Tabletop game-days, no actual injection | "What if Redis dies?" — walk through |
| 1 | Inject in dev / staging only | Kill an instance in staging |
| 2 | Manual injection in prod during business hours, with abort | Kill 1 pod in prod, observe, restore |
| 3 | Scheduled prod experiments with auto-abort on SLO breach | Weekly: induce DB replica failover in prod off-hours |
| 4 | Continuous chaos (Chaos Monkey-style) | Random instance kills during business hours |

Most orgs benefit immensely from levels 1-2. Don't aspire to level 4
without first having levels 1-3 stable.

## The experiment template

```
NAME: <name>
HYPOTHESIS:
  Under <failure mode>, the system should maintain <SLO metric>
  within <tolerance>, by <mechanism>.

STEADY-STATE METRIC:
  <metric> = <baseline value>

FAILURE MODE:
  <specific: not "Redis fails" but "the primary Redis node's process
  is SIGKILL'd at T=0">

BLAST RADIUS:
  <scope: which service, which pod, which fraction of traffic>

ABORT CRITERIA:
  - Customer-impacting SLO drops below <X>
  - On-call paged for any reason
  - Steady-state metric deviates beyond <tolerance>

RUNBOOK:
  T-1h: announce in #ops; on-call aware
  T-15m: pre-checks (no in-progress incidents)
  T=0:   inject
  T+5m:  measure
  T+10m: stop injection, observe recovery
  T+30m: write up findings

ROLLBACK PLAN:
  <exact steps to restore — must be tested>

OBSERVABILITY:
  Dashboards, alerts, log queries pre-wired
```

## The five experiments every service should run before claiming prod-ready

1. **Dependency failure.** Each downstream returns 5xx for 30s. Does
   the service degrade gracefully or cascade?
2. **Dependency slowness.** Each downstream injects 5s latency. Do
   timeouts work? Do circuit breakers trip?
3. **Pod death.** Kill 1, 2, N pods. Does load balancing recover? How
   long?
4. **Resource exhaustion.** Saturate CPU or memory on one pod. Does
   the rest of the fleet handle the diverted load?
5. **Network partition.** Drop traffic between two services for 30s.
   How does the system behave when the partition heals?

If any of these surprise you, you've found work.

## Tools

- **Chaos Toolkit** — open source, runner + YAML experiments.
- **LitmusChaos** — Kubernetes-native, lots of pre-built experiments.
- **AWS Fault Injection Simulator** / GCP equivalent.
- **Gremlin** — commercial, broadest set of injectors.
- **Toxiproxy** — TCP-level proxy for injecting latency, dropped
  packets, timeouts at the network layer.
- **`tc netem`** — Linux kernel network emulator; precise control for
  in-test simulations.

## Game-day playbook (the human version)

Quarterly cadence. Half a day.

1. Pick a scenario from a list of "things that could happen."
2. SREs design the experiment; engineering team is the responder.
3. Run the experiment. SRE plays observer; engineering team plays
   on-call.
4. Did they detect? In how long? Did the runbook work? Were dashboards
   useful? Did escalation paths function?
5. Retro: 5 things to fix. Action items with owners.

Game-days are training, not auditing. Don't grade.

## Anti-patterns

- Running chaos in prod during peak hours without a clear abort. You
  caused a real outage with a costume.
- "We did a chaos experiment in 2022." Stale; the system has changed.
- Experiments without a measurable steady-state. You ran an event;
  you didn't measure anything.
- Game-days where SREs both inject AND respond. You're not training
  the response, you're showing off.
- Abort criteria that are "vibes." Set the threshold in the runbook;
  decide BEFORE injection.
- Hiding the experiment from on-call. They get paged on the real
  noise of a real fault — not knowing it's planned wastes the page.
- Skipping the writeup. The artifact is the lesson; without it,
  someone else hits the same wall next quarter.
- Designing experiments only against happy-day paths. The interesting
  failures are the cross-team ones (dependency-of-dependency).
