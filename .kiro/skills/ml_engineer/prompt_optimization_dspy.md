---
id: prompt_optimization_dspy
version: 1.0.0
owners: [ml_engineer, senior_engineer_be]
tags: [prompt-engineering, dspy, optimization, llm, evals, compilation]
when_to_use: |
  When hand-tuning prompts has plateaued: you have a labelled eval set
  (or LLM-as-judge), the prompt is non-trivial (≥3 instruction sections
  or few-shot examples), and you'd benefit from a system that searches
  the prompt space instead of you doing it manually. Especially valuable
  for multi-step pipelines (RAG → classify → extract → format) where
  hand-tuning each stage is intractable.
inputs:
  - task_signature, training_examples, eval_metric, target_model
outputs:
  - "compiled_program: dspy.Module with optimized prompts + few-shot exemplars + traces"
---

# Prompt Optimization with DSPy

> Most production LLM systems are still hand-written prompts. DSPy
> treats prompts as **compilation targets** — you declare a pipeline
> as Python code, and DSPy's optimizer searches the space of prompts
> and few-shot exemplars that maximize your metric. The output is a
> compiled program that beats hand-written baselines by 10-40% on
> typical tasks, without you touching a string.

## When DSPy is worth it

| Indicator | Switch to DSPy? |
|---|---|
| Prompt is < 1 paragraph, single LLM call | ❌ Hand-write |
| Multi-step pipeline (3+ LLM calls, each with different role) | ✅ Yes |
| You have ≥20 labelled examples (or a reliable judge) | ✅ Yes |
| You're tuning few-shot exemplar selection by hand | ✅ Yes |
| You need to swap models (GPT-5 → Sonnet 4.6 → Llama-4) without re-tuning | ✅ Yes |
| Prompt evolves often; hand-tuning drifts | ✅ Yes |
| You don't have an eval set | ❌ Build the eval first |

## Core abstractions

```python
import dspy

# 1. Signature — declares input/output schema, NO prompt text
class GenerateClarifierQuestions(dspy.Signature):
    """Given a vague brief, produce 3-5 high-leverage clarifying questions."""
    brief: str = dspy.InputField(desc="customer's raw project brief")
    questions: list[str] = dspy.OutputField(desc="3-5 questions, short and specific")

# 2. Module — pipes signatures together; this IS your program
class Clarifier(dspy.Module):
    def __init__(self):
        super().__init__()
        self.generate = dspy.ChainOfThought(GenerateClarifierQuestions)
    def forward(self, brief: str):
        return self.generate(brief=brief)

# 3. Metric — your evaluation function (LLM-as-judge or programmatic)
def clarifier_metric(example, pred, trace=None) -> float:
    # Returns 0.0 - 1.0
    return judge_questions_quality(example.brief, pred.questions)

# 4. Compile — DSPy searches prompts + exemplars to maximize the metric
from dspy.teleprompt import BootstrapFewShotWithRandomSearch

compiler = BootstrapFewShotWithRandomSearch(
    metric=clarifier_metric,
    max_bootstrapped_demos=4,
    num_candidate_programs=8,
)
compiled_clarifier = compiler.compile(
    student=Clarifier(),
    trainset=train_examples,   # list of dspy.Example
    valset=val_examples,
)
# compiled_clarifier is a saved program: prompts + few-shot exemplars + traces
```

## The optimizer ladder — pick the right one

| Optimizer | Cost | When to use |
|---|---|---|
| `LabeledFewShot` | Free | You have curated exemplars, just want DSPy to format the prompt |
| `BootstrapFewShot` | ~$1-5 | Standard starting point: bootstraps few-shot from your trainset |
| `BootstrapFewShotWithRandomSearch` | ~$5-30 | Bootstraps + searches over candidate programs |
| `MIPROv2` | ~$30-200 | Bayesian search over instructions AND exemplars; best results |
| `BootstrapFinetune` | $$$$ | Distill the compiled program into a fine-tuned smaller model |

**Rule of thumb:** start with `BootstrapFewShot`, escalate to `MIPROv2`
only if metric still plateaus.

## Production workflow

```
┌──────────────────────────────────────────────────┐
│ 1. Define Signatures (Python contracts)         │
│ 2. Wire Modules (the pipeline)                  │
│ 3. Build eval set (50-500 examples)             │
│ 4. Pick metric (programmatic OR llm-as-judge)   │
│ 5. Compile (run optimizer offline, costs $$$)   │
│ 6. Save compiled program to disk                │
│ 7. Load at runtime — runs like a normal program │
└──────────────────────────────────────────────────┘
```

**Critical:** compilation happens **offline**, not at serving time.
The compiled program is a JSON-serialized artifact you check into the
prompt registry (versioned, alongside hand-written prompts).

```python
# Offline: compile once
compiled_clarifier.save("artifacts/clarifier.v3.json")

# Online: load and run
clarifier = Clarifier()
clarifier.load("artifacts/clarifier.v3.json")
result = clarifier(brief="make me an app")
```

## Model-portability — the underrated win

The same compiled program runs on any DSPy-supported model:

```python
dspy.configure(lm=dspy.LM("openai/gpt-5"))         # compile against GPT-5
# ... later, swap to Claude:
dspy.configure(lm=dspy.LM("anthropic/claude-sonnet-4-6"))
# Recompile? Often NOT — the optimized exemplars usually transfer.
# Recompile only if metric drops noticeably (>5%) on the new model.
```

This is huge for cost optimization: tune on GPT-5, deploy on Sonnet 4.6
if cheaper, fall back to local Llama-4 if both fail.

## Integrating with this repo's prompt registry

The `clarifier.py` uses a `PROMPT_REGISTRY` dict keyed by stable IDs
(e.g., `clarifier.questions.v2`). DSPy-compiled prompts slot in as
additional versions:

```python
# Hand-written
PROMPT_REGISTRY["clarifier.questions.v2"] = HAND_WRITTEN_PROMPT

# DSPy-compiled (loaded from artifact at import time)
_dspy_clarifier = Clarifier()
_dspy_clarifier.load("artifacts/clarifier_questions.v3.json")
PROMPT_REGISTRY["clarifier.questions.v3-dspy"] = _dspy_clarifier
```

A/B test the two via the same env-var switch (`CLARIFIER_PROMPT_QUESTIONS`).

## Anti-patterns

- **Compiling without an eval set.** DSPy needs a metric to optimize
  against. No eval set = no optimization.
- **Using LLM-as-judge with the same model you're compiling for.**
  Self-judging inflates scores. Use a different model family, or
  programmatic checks.
- **Compiling at request time.** Compilation is a build-time step,
  costs real money, takes minutes-to-hours. Serve the artifact.
- **Re-compiling on every prompt tweak.** If you're hand-editing the
  Signature docstring on every iteration, you're not letting DSPy do
  its job. Tweak the Module structure / metric, then recompile.
- **Skipping versioning.** Compiled programs are just as version-able
  as hand-written prompts; check the JSON artifact into the prompt
  registry with a stable ID.
- **Treating DSPy as magic.** It's a search algorithm over prompts. If
  your metric is broken, optimization will find prompts that game the
  metric, not prompts that solve the task.

## Validation

- [ ] Eval set exists with ≥50 examples (more for complex tasks).
- [ ] Metric is well-calibrated (sanity-check on hand-written baseline).
- [ ] Compilation is an offline build step, not request-time.
- [ ] Compiled artifact is versioned and stored in the prompt registry.
- [ ] A/B test compares DSPy-compiled vs hand-written baseline.
- [ ] Model portability verified (compile on A, validate on B).
- [ ] Observability hooked into the compiled program's traces.

## References

- DSPy docs: https://dspy.ai
- Khattab et al. "DSPy: Compiling Declarative Language Model Calls into Self-Improving Pipelines" (2024)
- See also: `prompt_engineering_production.md` for the manual side of the same problem space.
