---
id: feature_flags_safely
version: 1.0.0
owners: [senior_engineer, sre, product_manager]
tags: [feature-flags, progressive-delivery, kill-switch, dark-launch, exposure-bias]
when_to_use: |
  Shipping anything with non-trivial blast radius — new endpoint,
  new pricing logic, new auth flow, schema migration with a
  read-side change. Flags decouple deploy from release and turn
  many production incidents into "flip a switch" not "deploy a
  rollback."
inputs:
  - feature_scope, blast_radius, rollback_signal
outputs:
  - "flag_plan: flag taxonomy + rollout schedule + cleanup deadline"
---

# Feature Flags Without Drowning In Them

> Feature flags decouple DEPLOY (binary in prod) from RELEASE
> (traffic seeing the new behavior). They are also the #1 source
> of dead code in mature systems if not managed.

## The four flag types (different lifecycles)

| Type | Lifetime | Purpose | Owner |
|---|---|---|---|
| Release flag | Days–weeks | Hide work-in-progress; progressive rollout | Engineer |
| Experiment flag | Weeks | A/B test, statistical sample | PM/Data |
| Ops/kill-switch | Permanent | Disable a feature in an incident | SRE |
| Permissioning flag | Permanent | Customer tier / beta access | Product |

**Mixing these is the bug.** A release flag must be removed.
A kill switch is forever. Confusing them = dead flags everywhere.

## The release flag lifecycle (the one that's misused most)

```
1. Create flag, default OFF.
2. Deploy code behind the flag. Default-OFF protects prod.
3. Internal toggle ON → dogfood.
4. 1% of users.
5. 10%, 50%, 100% with health checks between steps.
6. Flag is at 100% for 7 days → DELETE the flag AND the code path.
```

Step 6 is where teams fail. Without enforced cleanup:
- The code has two paths forever.
- The "old" path bit-rots; nobody knows if you can actually revert.
- Mental model: "kill switch." But it's not — it was a release flag.

Enforce step 6 via a flag-cleanup-bot: an issue auto-created when a
release flag has been at 100% for 14 days; assigned to the original
author; blocked from merge if older than 60 days.

## The kill switch (permanent, intentional)

For things that NEED a stop-the-world: payments, AI inference,
expensive features. Keep them. Audit them quarterly:

- Owner is current.
- The kill path has been TESTED (synthetic toggle in staging,
  recently).
- Default state is correct.
- Documented in the on-call runbook.

A kill switch you've never tested is not a kill switch — it's
hopeful code.

## Targeting safely

Roll out by:

1. **Internal users** first. Free signal, low cost.
2. **% of users via stable hash** (`hash(user_id) % 100 < N`). Same
   user gets the same answer on every request (no flapping).
3. **Specific segments**: beta program, single tenant, region.
4. **Always-on for safety overrides** — e.g., `force_old_path` for
   one specific user if they have a corrupted profile under the new
   logic.

NEVER roll out by IP or by request-random. Both flap; users will
see the new feature on one click and the old on the next.

## Progressive delivery — measurable health gates

Don't just bump from 10% → 50%. Each step has:

- **A wait period** — at least one full traffic cycle (≥ 1 hour
  during business; longer for low-volume features).
- **Health metrics** — error rate, p99 latency, business KPI
  (conversion, revenue). If any deteriorates, AUTO-ROLLBACK.
- **Stop condition** — "if rollback fires twice in a row, halt
  the rollout pending review."

LaunchDarkly, Statsig, Unleash, OpenFeature + Flagsmith all support
this natively. Building your own works but cuts into feature work.

## Exposure logging (the audit trail)

When a user gets a flag value, LOG it (sampled is fine):

```
flag_exposure: {
  flag: "new_checkout",
  user_id: 42,
  variant: "treatment",
  ts: 2026-04-12T18:33:01Z
}
```

This lets you:
- Reproduce a bug from a specific user.
- Run A/B analysis on real exposures, not on assumptions.
- Audit "which customers saw the broken version" during an incident.

## Dark launches (read for stress test, ignore the result)

Need to validate a new service path under real traffic before
serving it? Dark launch:

```
result_new = call_new_path(request)   # under flag, in shadow
result_old = call_old_path(request)
diff = compare(result_old, result_new)
log_diff(diff)
return result_old   # users still get the old answer
```

You collect real-world correctness + perf data without risking a
single user response. Run for days, fix the diffs, THEN flip the
flag to actually return result_new.

## Flag taxonomy in code

```python
# good — flag is intent-revealing, has a context
if flags.is_enabled("checkout_use_new_pricing_engine", user=user, default=False):
    return new_pricing(request)
return old_pricing(request)

# bad — flag name is too generic; default is implicit
if flag("feature_a"):
    ...
```

Rules:
- Name: `<area>_<verb>_<noun>` — `checkout_use_new_pricing_engine`.
- Always pass a context (user, tenant, request).
- Always pass an explicit default. Never rely on the flag service
  being reachable.
- Wrap reads in a thin internal API; don't import the vendor SDK
  in 200 files.

## The fallback when the flag service is down

If the flag SaaS is unreachable, your code MUST:
- Cache the last-known value per flag with a TTL.
- Beyond TTL, return the explicit default.
- Log loudly. Sometimes the flag service is the canary that you've
  lost network egress.

A flag service outage taking down YOUR service is the worst kind
of irony.

## Anti-patterns

- **Flags as configuration** ("max_widgets = 100"). That's config,
  not a flag. Use a config system; flags are for behavioral toggles
  and rollouts.
- **Nested flags 5 deep.** Code becomes unreadable; combinatorial
  explosion of "what configuration is in prod right now?" Refactor.
- **Flags shared across services without coordination.** Service A
  flips to NEW, service B is still OLD, they disagree on shape. Either
  the flag must propagate atomically, or design the new shape to be
  forward+backward compatible (Postel's law).
- **Flag in the HOT loop.** Cache the value per-request, not per-call.
  Flag library reads inside tight inner loops kill p99.
- **No cleanup deadline.** Flag count grows monotonically; the
  flag dashboard becomes a graveyard.
- **Same flag = release AND kill switch.** Pick one role per flag.

## Validation that flags are well-managed

- [ ] No release flag has been at 100% for > 60 days.
- [ ] Every kill switch was exercised in the last quarter.
- [ ] Flag count is stable or shrinking, not growing.
- [ ] No two services have hard-coded assumptions that contradict
      each other when one is ON and the other is OFF.
- [ ] An engineer can answer "what flags are 100% in prod right now
      that ALSO have code paths for OFF?" in < 5 minutes (dashboard
      exists).
