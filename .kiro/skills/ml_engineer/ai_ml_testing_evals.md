---
id: ai_ml_testing_evals
version: 1.0.0
owners: [ml_engineer, qa_engineer]
tags: [evals, llm-judge, golden-dataset, regression, ragas, promptfoo]
when_to_use: |
  Any LLM / ML feature shipping to production. Unit tests don't cover
  stochastic models. "Looks good" testing regresses silently. Eval-
  driven development is the discipline of catching quality drift in
  CI, not on Twitter.
inputs:
  - feature_spec, sample_user_inputs, target_metrics
outputs:
  - "eval_suite: golden dataset + metrics + judges + CI gate + drift monitor"
---

# AI / ML Testing + Evaluation

> Traditional tests assert exact outputs. LLM outputs vary by run.
> You need EVALS: measurements over a held-out dataset, scored by
> rubric or LLM-as-judge, run on every change, gated in CI.

## The eval hierarchy

```
1. UNIT       — deterministic transforms (parser, prompt template render)
2. SCHEMA     — output validates against JSON schema
3. ASSERTIONS — programmatic checks ("response contains 'price'")
4. RUBRIC     — graded by LLM judge ("is this answer helpful? 1-5")
5. HUMAN      — sampled human review (gold standard)
6. PROD       — real user signal (thumbs, conversion, retention)
```

Use ALL — they catch different failures.

## Golden dataset — the foundation

A curated set of input → expected output (or expected behavior) pairs.

```yaml
# golden/summarize_v1.yaml
- id: case_001
  input:
    document: "..."
  expected:
    contains: ["pricing", "Q2"]
    not_contains: ["I cannot summarize"]
    schema_valid: true
    factuality_score_min: 0.8
  notes: "Standard summarization happy path"

- id: case_002
  input:
    document: "Empty document."
  expected:
    handles_edge_case: true
    response_length_max: 50
  notes: "Edge case: no content to summarize"

- id: case_003_pii
  input:
    document: "John Smith, SSN 123-45-6789, ..."
  expected:
    contains_pii: false
    response: "PII detected; cannot summarize"
  notes: "PII handling"
```

Golden set size:
- Minimum: 50 cases for a tiny feature.
- Recommended: 200-500 hand-curated diverse cases.
- Mature: 1000+ with auto-generated variations.

Build by:
- Collecting prod incidents + edge cases.
- Sampling production traffic + labeling.
- Synthesizing variations (paraphrase, edge cases via LLM).

## Metrics — match to task

### Classification / extraction

| Metric | Use |
|---|---|
| Accuracy | Balanced classes |
| Precision / recall / F1 | Imbalanced classes |
| Per-class metrics | When some classes matter more |
| Confusion matrix | Diagnostic |

### Generation (open-ended)

| Metric | Use |
|---|---|
| BLEU / ROUGE / METEOR | Translation, summary — overlap with reference |
| BERTScore | Semantic similarity |
| LLM-as-judge (rubric) | Helpfulness, faithfulness, tone |
| Schema validation | Structured output |
| Length / format constraints | Deterministic |

### RAG

| Metric | Use |
|---|---|
| Retrieval Recall@K | Are relevant docs retrieved? |
| Retrieval Precision@K | Are retrieved docs all relevant? |
| Faithfulness | Answer uses ONLY cited chunks? |
| Answer Relevance | Answer addresses the question? |
| Context Relevance | Retrieved context relevant to question? |

### Safety / Trust

| Metric | Use |
|---|---|
| Harmlessness | Doesn't produce toxic / unsafe content |
| Refusal rate | Appropriately refuses dangerous requests |
| Hallucination rate | Doesn't invent facts |
| PII leakage | Doesn't echo back PII inappropriately |

## LLM-as-judge

For subjective metrics, use a strong model to score:

```
SYSTEM: You are a strict evaluator. Score the following response on a
scale of 1-5 for FAITHFULNESS — does the answer use ONLY the
provided context, with no invented facts?

CONTEXT: <retrieved chunks>
QUESTION: <user question>
ANSWER: <model answer>

Output JSON: { "score": <int>, "reasoning": "<one sentence>" }
```

Best practices:
- Use a DIFFERENT (often stronger) model as judge.
- Calibrate against human ratings (sample 50, compare).
- Use STRICT rubrics; vague rubrics → unreliable scores.
- Run the judge MULTIPLE times per sample if noisy; average.

LLM-as-judge has well-documented biases (position, length, repetition).
Mitigate via pairwise comparison + permutation.

## Pairwise comparison

For preference judgments (which response is better?):

```
Given two responses A and B for the same question, which is better?
Output: "A" or "B" or "tie".

Question: ...
A: ...
B: ...
```

Run with BOTH orderings (A vs B and B vs A), only count "consistent
winner" cases. Reduces position bias.

Used by LMSYS Chatbot Arena, MT-Bench.

## Regression evaluation in CI

```yaml
# .github/workflows/eval.yml
- name: Run evals
  run: |
    promptfoo eval -c promptfooconfig.yaml --output result.json
    python scripts/check_regression.py result.json --threshold 0.05
```

Gates:
- BLOCK merge if avg score drops > 5% vs current main.
- BLOCK merge if ANY high-priority test case regresses.
- ALLOW with reviewer approval for intentional shifts.

Tool stack:
- **Promptfoo** (CLI, YAML-based, free, popular).
- **DeepEval** (Python, pytest-style).
- **Ragas** (RAG-specific).
- **TruLens** (Python, integrates with LangChain).
- **LangSmith** (LangChain's, robust).
- **Arize Phoenix** (OSS observability + evals).
- **Weave** (W&B's, growing).

## Eval-driven development

```
1. Define metric + golden dataset BEFORE writing the prompt.
2. Start with baseline (simple prompt). Score it.
3. Iterate prompt → re-score. Check delta.
4. Lock the prompt when score meets threshold.
5. CI evaluates on every change.
6. Production samples + judge feedback updates golden set.
```

The discipline: NO production change without an eval delta.

## Production observability — eval in flight

```python
# Sample 1% of prod traffic for live evals
if random.random() < 0.01:
    judge_score = llm_judge.score(prompt=user_input, response=model_output)
    metrics.gauge('faithfulness_score', judge_score, tags=['model:v3'])
```

Dashboard: rolling-window quality metric per model version. Alert on
drift.

User signal:
- Thumbs up/down in UI.
- Implicit (did user accept the response / followup?).
- Conversion delta if the AI feature impacts a funnel.

Pair quality eval + user signal — they catch different problems.

## Eval-driven prompt engineering

Workflow:

```
1. Hypothesis: "Adding 'be concise' to system prompt will improve
   user satisfaction without losing factuality."
2. Create prompt variant v4.
3. Run on golden dataset:
     - factuality: v3=0.85, v4=0.83 (small regression)
     - conciseness: v3=0.45, v4=0.78 (big win)
4. Run A/B on prod (small %): user thumbs-up rate +12%.
5. Promote v4 to production.
```

Each change is a small experiment with measurable impact.

## Anti-patterns

- **"Looks good" testing.** Will regress; you won't catch.
- **No golden dataset.** Can't measure improvement.
- **One number** (avg accuracy) hiding bimodal distribution.
- **LLM-as-judge without calibration.** Numbers feel real but aren't.
- **Eval suite that takes 1 hour to run.** Devs skip it.
- **Same eval set as training.** Overfit indicator missed.
- **Metrics not tied to user value.** "Higher BLEU but worse UX."
- **No regression gate in CI.** Silent drift.
- **Sampling no prod traffic for evals.** Synthetic data ≠ user data.
- **Eval as one-time check.** Models drift; sets need refresh.

## Validation

- [ ] Golden dataset exists + version-controlled.
- [ ] Metrics defined per feature (deterministic + rubric).
- [ ] LLM judge calibrated against human ratings.
- [ ] CI eval gate blocks regressions.
- [ ] Production sampled + scored continuously.
- [ ] User signal tied to model version.
- [ ] Eval suite runs in < 10 min in CI.
- [ ] At least one rubric metric measured for every LLM-touching
      feature.
- [ ] Golden set updated quarterly with new edge cases.
