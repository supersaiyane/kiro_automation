---
id: deployment_strategies
version: 1.0.0
owners: [devops_engineer, sre_engineer]
tags: [deploy, blue-green, canary, rolling, feature-flags, rollback]
when_to_use: |
  Choosing how a new version of a service reaches production. Default
  to progressive (canary) for any service that affects user traffic.
inputs:
  - service: traffic profile, statefulness, blast-radius tolerance
outputs:
  - deploy_strategy: stages, success criteria, automatic rollback rules
---

# Deployment Strategies

## The five strategies — when each fits

| Strategy | Mechanism | Rollback | Best for |
|---|---|---|---|
| **Recreate** | Stop old, start new | Re-deploy old | Dev / staging only — has downtime |
| **Rolling** | Replace N instances at a time | Re-deploy old; halt rolling forward | Default for stateless services if you accept brief mixed-version state |
| **Blue-Green** | Two full environments; flip the router | Instant via router flip back | Database-coupled or stateful services; releases that must be all-or-nothing |
| **Canary** | Send small % traffic to new; expand | Stop expansion, drain canary | Any change with blast-radius concern |
| **Shadow** | Mirror real traffic to new without affecting users | N/A — observe only | Validating a rewrite or a perf change |

Most modern stacks combine: blue-green at the infra level + canary at
the routing level + feature flags inside the app.

## The progressive canary template

The default for any production deploy:

```
stages:
  - name: canary
    weight: 1%
    duration: 10m
    success_criteria:
      - error_rate < 0.5%
      - p95_latency < 1.05 * baseline
      - no critical log patterns
    on_failure: rollback

  - name: expand
    weight: 10%
    duration: 20m
    success_criteria: same as above
    on_failure: rollback

  - name: half
    weight: 50%
    duration: 30m
    on_failure: rollback

  - name: full
    weight: 100%
```

Total deploy: ~1 hour from 1% to 100% under normal conditions. That's
the price of safety. Speeding it up is how you ship outages.

## Automatic rollback rules

Rollback automatically when ANY of:
- Error rate increase > 2× baseline for 2 minutes.
- p99 latency increase > 50% for 5 minutes.
- Health check failures > 5% of instances.
- A user-impact metric (checkout success, login success) drops > 5%.
- Any new ERROR-level log pattern with rate > 10/min.

Don't rely on humans to spot a regression during a 100% rollout. By
the time they look, the incident is in progress.

## Feature flags — the deployment / release decoupling

**Deploy ≠ release.** Ship the code dark; flip the flag separately.

- Default state: OFF.
- Initial release: enable for internal users (employee bool, beta
  cohort).
- Expand by traffic share (1%, 10%, 50%, 100%).
- Per-segment flags for staged release (geo, customer tier).
- Sunset old flags ruthlessly — every flag is a maintenance burden
  and a branch in the code that's secretly two code paths.

Use a real flag service (LaunchDarkly, Flagsmith, Statsig, ConfigCat,
or self-hosted). **Don't roll your own with env vars.** You'll lack
audit logs, kill switches, and bucket-stable hashing.

## Database deploys — the special case

Apps can be canaried; schemas cannot. The schema change is binary —
applied or not.

**Multi-step pattern for any non-trivial schema change**:
1. Deploy: app version N writes old schema, reads old schema.
2. Migration: add new schema element (nullable, additive).
3. Deploy: app version N+1 writes BOTH old + new, reads old.
4. Backfill: existing rows populated in new schema.
5. Deploy: app version N+2 writes both, reads new.
6. Verify reading old is no longer needed.
7. Deploy: app version N+3 writes new only.
8. Migration: drop old column.

Skipping any step = backward incompatible change = outage.

## Stateful services

If the service holds local state (in-memory cache, local files, sticky
sessions), rolling deploy creates the **mixed-version state** problem:
old and new format coexist; readers must handle both.

Default: make it stateless. Push state out to a backing store.

If you must keep state:
- Migrate state forward with the version (write-both, then drop).
- Blue-green with explicit state migration in the switchover window.

## Multi-region deploys

Don't promote globally. Stage per region:
- Test region (your smallest, lowest-priority) first.
- Bake for an hour with full canary completion.
- Then next region. Then next. Never simultaneous full-region pushes.

The Friday 5pm push to all regions is famous because it's a recipe.

## Anti-patterns

- "Just push to prod, it's a hotfix." Hotfixes still need a canary;
  the rollback path is *more* important under stress.
- Canary on traffic that doesn't represent the user mix (internal-only
  routes). Your "canary signal" is useless.
- Rolling deploy without health checks. New pods join the LB while
  still starting; users get 502s.
- Manual rollback via "ssh and revert symlink." That's how you lose
  the artifact-identity property. Automated rollback only.
- Big-bang Friday afternoon deploys. The on-call is at their weakest;
  rolling back at midnight is no fun.
- Feature flags that have been at 100% for 6 months. They're not
  flags; they're tech debt. Remove.
- One flag controlling 30 features ("the new flow"). When you need to
  roll back one bug, you toggle the whole flow off.
