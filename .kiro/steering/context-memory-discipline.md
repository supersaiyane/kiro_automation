---
inclusion: always
---

# Context & Token Discipline (Core Rules)

Lean behavioral constraints loaded every session. Memory management and reporting
templates split into conditional files to reduce always-on context cost.

---

## 1. CONTEXT BUDGET ALLOCATION

| Section | Max % of Context | Strategy |
|---------|-----------------|----------|
| System prompt + steering | 15% | Always loaded, keep lean |
| Hook outputs | 10% | Cap length, most-recent-only |
| Memory (init_docs) | 15% | Retrieval-based: load RELEVANT only |
| Tool outputs (bash, reads) | 25% | Cap 80 lines, summarize, strip noise |
| Code generation (primary work) | 35% | Main output — this gets priority |

Enforcement: exceed cap → compress/truncate BEFORE proceeding. Maintain 10% headroom minimum.

---

## 2. CAVEMAN ULTRA — STRICT ENFORCEMENT

- Max 1 status sentence before acting. No preambles.
- Fragments > prose. Technical shorthand > full English.
- BANNED: "Let me...", "I'll now...", "Here's what I did", "Sure!", "Great question", "Absolutely"
- Q&A: 1-3 lines max unless user asks "explain" or "why"
- Self-check: "Can I cut 50% and lose zero info?" If yes → cut.

---

## 3. CONTEXT HEADROOM

- At 85% → "[HEADROOM WARNING]" + summary-only mode
- At 90% → FULL STOP. Checkpoint. Recommend new session.
- Collapse tool outputs to 1-line summaries after use.
- Each tool call ≈ 500 tokens. Budget accordingly.

| Exchanges | Action |
|-----------|--------|
| < 20 | Normal ops |
| 20-35 | Compress aggressively |
| 35-50 | Summary-only, no new reads unless editing |
| 50+ | MANDATORY checkpoint + fresh session |

---

## 4. SELF-ADAPTIVE CONTEXT PRUNING

KEEP IN FULL: files being modified, errors being debugged, current role artifacts.
SUMMARIZE TO 3 LINES: explored-but-not-modified, different subsystem, >15 exchanges old.
DISCARD: already-summarized tool output, dead-end exploration, processed hooks.

---

## 5. CONTINUOUS EVICTION (every 10 exchanges)

Score retained items (0-10): relevance(0-5) + recency(0-3) + uniqueness(0-2).
- Score < 4 → evict (1-line stub)
- Score 4-6 → compress (2-3 lines)
- Score 7-10 → keep full

---

## 6. STRICT AGENT ISOLATION

Subagent prompts < 2000 tokens total. Pass summaries only (max 500 tokens each).
Never pass: full docs they won't modify, other roles' outputs, conversation history, raw tool outputs.

---

## 7. TOKEN ESTIMATION (Per-Task Micro Report)

```
> Reads: X. Tier: Y. Estimated tokens saved: Z%.
```

Formula: savings_percent = (naive_total - actual_total) / naive_total × 100

---

## CONTEXT ROT THRESHOLDS

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Steering total lines | < 300 | 300-500 | > 500 |
| checkpoint.md entries | < 20 | 20-30 | > 30 |
| lessons.md entries | < 15 | 15-20 | > 20 |
| init_docs size | < 15KB | 15-25KB | > 25KB |
| Session exchanges | < 30 | 30-50 | > 50 |
| Tool calls | < 15 | 15-25 | > 25 |

Red = mandatory action (archive/split/fresh session).
