---
id: agentic_memory_mem0
version: 1.0.0
owners: [ml_engineer, architect, backend_lead]
tags: [memory, agentic, mem0, zep, letta, cognee, personalization, langgraph]
when_to_use: |
  You've validated that long-term memory is needed (skill:
  long_term_memory_systems → Tier 2+) and now you're choosing the
  layer that turns raw conversation logs into curated insights with
  entity resolution, deduplication, and temporal weighting. Build vs
  buy decision; library comparison.
inputs:
  - product_use_case, scale, channels, latency_budget, build_vs_buy_constraints
outputs:
  - "memory_layer_choice: vendor + integration pattern + identity model + retention"
---

# Agentic Memory with Mem0 (and peers)

> Long-term memory storage (vectors, graphs) is solved. The unsolved
> middleware is the **digest layer** that turns "transcript of every
> conversation" into "what does the system actually believe about this
> user." Mem0, Zep, Letta, and Cognee are the production category.
> Build-vs-buy is the central question — they offer hardened APIs for
> entity linking, temporal weighting, and conflict resolution that take
> 3-6 months to get right yourself.

## The shift: from passive logs to active memory

Traditional memory stores everything: "The user said they like blue
coffee mugs at 14:32 on Tuesday." Agentic memory stores the **insight**:

```
(user, preferred_mug_color, blue)  [confidence=0.92, last_seen=2026-05-12, source_turn=#1847]
```

The transformation pipeline is the value-add — none of these tools
*invented* vector DBs or knowledge graphs; they invented the digest
loop on top.

## The digest loop (universal across vendors)

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   user_turn ─►  L1 working memory (current context)          │
│                  │                                           │
│                  ▼                                           │
│              ┌──────────────────┐                            │
│              │  Memory Agent    │  (background, async)       │
│              │  (small LLM)     │                            │
│              └────────┬─────────┘                            │
│                       │                                      │
│        ┌──────────────┼──────────────┐                       │
│        ▼              ▼              ▼                       │
│   1. EXTRACT     2. COMPARE     3. MERGE/UPDATE              │
│   "did anything   "does this    "if conflict, update         │
│    memorable      already       with new timestamp;          │
│    happen?"      exist in L3?"   if new, insert"             │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

Every vendor implements this loop. The differences are in:

- **Identity resolution:** is the user in Slack "om" the same as the user in Discord "om.bharatiya"?
- **Temporal weighting:** when conflicting facts arrive ("user lives in NYC" vs "user lives in SF"), which wins?
- **Conflict resolution:** when a fact contradicts an existing one, do we replace, version, or expire?
- **Periodic reflection:** does the system run a background job to consolidate or proactively surface goals?

## Vendor comparison (May 2026)

| | **Mem0** | **Zep** | **Letta (formerly MemGPT)** | **Cognee** |
|---|---|---|---|---|
| **Sweet spot** | Broadest standalone memory layer | Temporal-aware production pipelines | Long-running agents needing OS-style paging | Knowledge-graph-first RAG |
| **Storage backend** | Vector DB (Qdrant default) + optional graph | Temporal knowledge graph | Memory hierarchies with paging | Pure knowledge graph |
| **Identity resolution** | Built-in `user_id` + linking API | Strong temporal entity resolution | Per-agent memory namespaces | Graph-native |
| **Hosted offering** | Yes (Mem0 Platform) | Yes (Zep Cloud) | Self-hosted primary | Self-hosted primary |
| **Open source** | Yes (Apache 2.0) | Yes (Apache 2.0) | Yes (Apache 2.0) | Yes (Apache 2.0) |
| **Best for** | "Just give me memory" | Multi-turn agents needing time-aware recall | Long-context agents (debugging, research) | Knowledge-base-heavy products |
| **Latency overhead** | ~100ms per write | ~150-300ms per write (extraction) | ~50ms (in-memory pages) | ~200-400ms (graph traversal) |

**Default pick:** Mem0 — broadest API surface, easiest to drop in. Move
to Zep when you need temporal correctness ("what did user believe
last month"). Move to Letta for agents that need OS-style virtual
memory paging. Move to Cognee when the knowledge graph IS the product.

## Self-updating memories — periodic reflection

Beyond the per-turn digest, modern systems run a **reflection job**:

```python
# Conceptual — runs once daily per active user
async def reflection_pass(user_id: str):
    # 1. Pull all "active goal" nodes
    goals = await mem.search(user_id, type="goal", status="active")

    # 2. For each goal, check if there's new evidence
    for goal in goals:
        new_facts = await mem.search(
            user_id,
            since=goal.last_check,
            related_to=goal.entities,
        )

        if new_facts:
            # 3. Either auto-update the goal or surface a proactive reminder
            if goal.auto_update:
                await mem.update(goal.id, last_evidence=new_facts)
            else:
                await reminder_queue.push(
                    user_id=user_id,
                    message=f"Quick check-in on '{goal.title}' — any update?",
                )

    # 4. Consolidate: merge clusters of duplicate facts about the same entity
    await mem.consolidate(user_id, dry_run=False)
```

Example: user said "I need to finish the budget by Friday" on Monday.
Reflection on Thursday surfaces a proactive nudge: "How is the budget
coming along?" This is the qualitative difference between "the bot
that has memory" and "the bot that's actually useful."

## Integration patterns

### With LangGraph (this repo's pattern)

```python
# state_models.py — add a memory slot to SprintState
@dataclass(frozen=True)
class UserContext:
    user_id: str
    tenant_id: str
    preferences: dict[str, Any] = field(default_factory=dict)
    history_summary: str = ""

# node implementation
async def hydrate_memory_node(state: SprintState) -> dict:
    """Runs before any role node; pulls user context from Mem0."""
    from mem0 import MemoryClient
    mem = MemoryClient()

    # Returns ranked list of relevant memories — pre-filtered by user_id
    memories = mem.search(
        query=state.original_brief,
        user_id=state.user_id,
        limit=20,
    )

    # Filter by relevance score (Mem0 returns a score per memory)
    relevant = [m for m in memories if m["score"] > 0.85]

    return {
        "user_context": UserContext(
            user_id=state.user_id,
            tenant_id=state.tenant_id,
            preferences=_extract_prefs(relevant),
            history_summary=_summarize(relevant, max_tokens=500),
        )
    }

# write-back happens at sprint end
async def persist_learnings_node(state: SprintState) -> dict:
    from mem0 import MemoryClient
    mem = MemoryClient()

    # Add the full sprint summary as an episodic memory
    mem.add(
        messages=[
            {"role": "user", "content": state.original_brief},
            {"role": "assistant", "content": state.final_summary},
        ],
        user_id=state.user_id,
        metadata={
            "tenant_id": state.tenant_id,
            "sprint_id": state.sprint_id,
            "quality": state.quality_score,
        },
    )

    return {}
```

### Cross-channel identity

User opens a ticket in Intercom, then follows up in Slack, then drops
an email. Without identity resolution, three memory namespaces. With it,
one user, three sources.

```python
# Mem0 example
mem.link_users(
    primary_id="user_internal_42",
    aliases=[
        {"source": "intercom", "external_id": "om_intercom_99"},
        {"source": "slack", "external_id": "U0123456"},
        {"source": "email", "external_id": "om@example.com"},
    ],
)
```

Configure this once during user signup; all subsequent writes/reads
across channels resolve to the same memory bucket.

## Cost model

For a chat product with 100K MAU, 20 turns/user/month:

| Component | Calls/mo | Unit cost | Total |
|---|---|---|---|
| Extraction (small LLM, 200 tok in / 50 tok out) | 2M | $0.0001 | $200 |
| Embedding (text-embedding-3-small, ~256 tok) | 2M | $0.0000026 | $5 |
| Vector storage (Qdrant, 1M vectors @ 1536-dim) | — | ~$100/mo | $100 |
| Mem0 Platform (if hosted, includes above) | 2M ops | $0.0004 | $800 |

**Break-even:** below ~500K memory ops/mo, hosted Mem0 is cheaper than
self-hosted (eng time dominates). Above that, self-hosting pays off if
you have the engineers to operate Qdrant + a worker pool.

## Thresholded relevance — avoid memory fatigue

The most common failure mode in agentic memory is **memory fatigue**:
the agent surfaces irrelevant past facts on every turn, polluting
context and confusing the LLM. Mitigations (Mem0's defaults are
roughly):

- Only inject memories with relevance score > 0.85.
- Cap injected memories at 5 per turn.
- **Negative retrieval:** instruct the LLM to consult memory ONLY when it would (a) directly contradict a potential hallucination, or (b) answer something the user didn't restate.
- Periodic pruning of low-value memories (e.g., observations like "user mentioned it's raining" → auto-delete after 24h).

## Anti-patterns

- **Storing every turn as a memory.** That's logging, not memory. The whole point of these tools is **selective digest**.
- **Cross-tenant `user_id` collisions.** "om" in tenant A and "om" in tenant B share memories unless you compose the key. Always use `(tenant_id, user_id)` as the partition.
- **Confidence-blind retrieval.** A memory the extractor was 30% sure about should not surface with the same weight as one it was 95% sure about.
- **Synchronous extraction in the request path.** Adds 100-300ms to user-perceived latency. Run extraction as a background task; eventual consistency is fine for memory.
- **No conflict-resolution policy.** What happens when user says "I live in NYC" Monday and "I just moved to SF" Friday? Default to *last-write-wins-with-timestamp*; let humans escalate when needed.
- **Treating Mem0 as a black box.** Production teams need to log every memory write/read with the source turn and confidence — for debugging AND for GDPR right-to-be-forgotten.
- **No reflection job.** Without periodic consolidation, you accumulate 10 copies of the same fact, retrieval precision drops.

## Validation

- [ ] Vendor chosen explicitly (build / Mem0 / Zep / Letta / Cognee) with rationale documented.
- [ ] Identity model: `(tenant_id, user_id)` as composite key.
- [ ] Cross-channel linking configured if multi-channel product.
- [ ] Extraction runs async, off the request critical path.
- [ ] Relevance threshold ≥ 0.85 at retrieval.
- [ ] Cap on memories injected per turn (default 5).
- [ ] Reflection / consolidation job scheduled.
- [ ] Confidence stored on every memory; thresholded at retrieval.
- [ ] Memory write/read audit log per skill `long_term_memory_systems`.
- [ ] GDPR forget endpoint propagates to the memory vendor's API.

## References

- Mem0. "Learning User Preferences across Sessions" (2025)
- Zep. "Temporal Knowledge Graphs for Production Agents" (2025)
- Letta (formerly MemGPT). "Memory Hierarchies for Long-Running Agents" (2024)
- Cognee. "Knowledge-Graph-First RAG" (2025)
- See also skills: `long_term_memory_systems`, `graph_rag`, `agent_design_tool_use`.
