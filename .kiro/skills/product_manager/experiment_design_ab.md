---
id: experiment_design_ab
version: 1.0.0
owners: [product_manager]
tags: [experiment, ab-testing, statistics, growth, causal-inference]
when_to_use: |
  Any product change whose impact on the NSM (or a guardrail) is
  uncertain. Default to experimenting unless the change is a
  bug fix or a regulatory requirement.
inputs:
  - hypothesis: precise, falsifiable statement
  - primary_metric: from the L2/L3 input tree
  - guardrails: list
outputs:
  - experiment_spec: variants, traffic split, MDE, sample size, stop rules
  - decision: ship / kill / iterate, with the math behind it
---

# A/B Experiment Design

## The hypothesis (the one sentence everyone forgets)

Pattern:
> "We believe **[change]** will cause **[primary metric]** to move by
> at least **[MDE]** for **[user segment]** within **[duration]**,
> because **[mechanism]**. We'll know we're wrong if **[guardrail]**
> regresses or **[primary metric]** doesn't move."

If you can't write that sentence, you don't know what you're testing.

## Sample size: don't fly blind

You need three numbers before launch:

- **Baseline rate** of the metric (e.g. 12% conversion).
- **MDE** (Minimum Detectable Effect) — the smallest movement that's
  worth shipping (typical: 5-10% relative).
- **Alpha + power** — 0.05 and 0.80 are the defaults; tighten for
  irreversible changes.

Plug into a sample-size calculator. If the required sample/duration is
>4 weeks, your MDE is unrealistic for your traffic; either pick a higher
MDE (with a stronger intervention) or pick a more sensitive metric.

## Traffic allocation

- **50/50** when you have traffic. Maximum statistical power per sample.
- **Holdout** (e.g. 95% treatment, 5% control) only when you've already
  shipped to most users and need to *measure* what the change did.
- **Sequential ramp** (1% → 10% → 50% → 100%) for risky changes. The 1%
  stage tests for catastrophic bugs, not for statistical signal.

## Guardrails

Pre-declared. The experiment can succeed on the primary metric **and
still be killed** if a guardrail regresses beyond its tolerance.
Common guardrails:

- Page latency p95
- Crash rate
- Refund / chargeback rate
- Support ticket volume
- Bounce rate
- Sessions per user (catch addictive but harmful patterns)

Each guardrail has a tolerance ("p95 latency must not rise >5%").

## Stop rules (before launch, not during)

1. **Catastrophic guardrail**: kill at any sample size if a guardrail
   regresses >X%.
2. **No primary movement at full duration**: ship the control, not the
   treatment. (And not "iterate" — that's the default cop-out.)
3. **Significant primary movement at full duration**: ship the
   treatment after PR/eng/security sign-off.

**Do not peek and stop early.** Sequential testing without a corrected
significance threshold (Bonferroni / O'Brien-Fleming) inflates false
positives 3-5x. If you need to peek, switch to a Bayesian or
mSPRT framework before launch.

## Three statistical gotchas

1. **SRM (Sample Ratio Mismatch)** — assigned 50/50, observed 47/53?
   Your assignment is broken. Kill the test; don't read the result.
2. **Simpson's paradox** — overall metric moves one way, every segment
   moves the other. Always cut by segment (mobile vs. web, new vs.
   returning, region).
3. **Novelty effect** — new things look good for a week. Run 2-4
   business cycles minimum.

## Post-experiment writeup template

```
Title: <one-line hypothesis result>
Hypothesis: <restate>
Result: shipped / killed / iterate
Primary metric: <baseline> → <treatment>, p=<value>, 95% CI [low, high]
Segments cut: mobile/web, new/returning, top-3 countries
Guardrails: all green / list regressions
What we learned: <2-3 sentences>
What we'll do next: <one decision>
```

The "what we learned" is the most-cited part six months later. Spend
time on it.

## Anti-patterns

- HiPPO (Highest-Paid Person's Opinion) overruling stat sig results.
  Don't ship without the test; don't kill without the data.
- "It's directionally positive" with p=0.4. That's noise.
- Running 30 simultaneous tests. Each one contaminates the others;
  the system-wide false-discovery rate is huge.
- No segment cuts. Average effect can mask 20% of users getting harm.
- Treating "no significant difference" as "no effect". Often it just
  means underpowered. Report the CI, not just the p.
- Re-running until you get significance. That's p-hacking, not science.
