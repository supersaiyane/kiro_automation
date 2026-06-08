---
id: long_term_memory_systems
version: 1.0.0
owners: [ml_engineer, architect, backend_lead]
tags: [memory, episodic, semantic, knowledge-graph, vector-search, multi-tenancy, gdpr, retrieval]
when_to_use: |
  Designing an LLM product that must persist information across sessions
  for the same user / tenant / workspace. Examples: assistants that
  remember user preferences, agents that learn from prior trajectories,
  multi-sprint planners that recall earlier decisions. NOT needed for
  single-turn or single-session products.
inputs:
  - product_use_case, user_model, multi_tenant_topology, retention_policy
outputs:
  - "memory_architecture: store choice + schema + decay policy + ACL model + GDPR plan"
---

# Long-Term Memory Systems

> A chatbot without long-term memory is a Tamagotchi that resets every
> morning. The interesting products start the day knowing what the user
> said yesterday — and last quarter. The hard part isn't storing the
> data, it's deciding **what** to store, how to retrieve it without
> drowning the prompt, when to forget, and how to make absolutely sure
> tenant A never sees tenant B's memories.

## The three memory tiers

```
L1 — Working memory          (current request only)
       └─ context window, fits in prompt
L2 — Session memory          (this conversation, hours)
       └─ in-process state, Redis with TTL
L3 — Long-term memory        (across sessions, days→years)   ← THIS SKILL
       └─ vector DB + knowledge graph + relational store
```

L1 and L2 are mechanical — paged-in / paged-out, no retrieval magic.
L3 is the system this skill governs.

## Episodic vs semantic memory

Borrowed from cognitive science; both belong in L3, but they look very
different on disk and at retrieval time.

| | **Episodic** | **Semantic** |
|---|---|---|
| What it stores | Trajectories: sequences of events + outcomes | Facts about entities + relationships |
| Example | `(2026-04-12, user="om", action="built React app with shadcn", outcome="success")` | `(user="om", HAS_PREFERENCE, dark_mode)` |
| Storage | Vector DB (chunks of conversation summaries) | Knowledge graph (Neo4j, AWS Neptune, Memgraph) |
| Retrieval | Semantic similarity ("find a similar past trajectory") | Graph traversal ("what do I know about this entity?") |
| Cost to write | Cheap (embed + insert) | Expensive (entity extraction LLM call) |
| Cost to query | Cheap (ANN search) | Cheap-to-medium (Cypher / Gremlin) |

**Rule:** if the question is "have I seen something like this before?", that's episodic. If the question is "what do I know about entity X and what's it connected to?", that's semantic.

## Hybrid vector + graph storage

The pattern most production systems converge on:

```
┌─────────────────────────────────────────────────────────────┐
│  WRITE PATH                                                 │
│                                                             │
│  user_turn ──► [Fact Extractor LLM] ──► triplets            │
│       │                                  │                  │
│       │                                  ▼                  │
│       │                               Knowledge Graph       │
│       │                               (entities + edges)    │
│       │                                                     │
│       └─► [Summarize trajectory] ──► Vector DB              │
│                                      (episodic chunks       │
│                                       with tenant_id meta)  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  READ PATH (HybridGraphRAG)                                 │
│                                                             │
│  query ──► [Vector ANN] ──► candidate chunks                │
│              │                  │                           │
│              │                  ▼                           │
│              │              entity IDs in chunks            │
│              │                  │                           │
│              │                  ▼                           │
│              └──► [Graph traversal 1-2 hops] ──► extra      │
│                                                   connected │
│                                                   facts     │
│                                                                 │
│  Merged context ──► reranker ──► prompt                     │
└─────────────────────────────────────────────────────────────┘
```

**Why both:** vector search finds *related* memories (fuzzy meaning).
Graph traversal finds *connected* memories (deterministic structure).
A query for "Project Alpha" via vector finds the name; via graph it
also pulls the 10 developers, the deadline, and the linked repos.

## Pruning, decay, and forgetting

Memory is a liability if it grows unchecked. The retrieval precision
of an over-stuffed memory degrades worse than no memory at all
("catastrophic forgetting via index overload").

| Mechanism | Implementation | When |
|---|---|---|
| **Temporal decay** | Multiply relevance score by `e^(-λ·age_days)` at retrieval time | Always — keeps fresh memories on top |
| **Consolidation** | Background job merges N memories about the same entity into one high-quality summary node | Weekly, or when entity has >20 memories |
| **Quality-weighted retrieval** | Memories with `verification_score > 0.8` (set by supervisor agent or user thumbs-up) ranked above raw logs | When you have a feedback loop |
| **Hard expiry (TTL)** | Low-value memories (e.g., "user mentioned it's raining") deleted after 24h | For low-signal observations |
| **GDPR-driven forgetting** | Hard delete of every episodic chunk + every semantic triplet WHERE user_id = X | On data subject deletion request — see Privacy below |

## Multi-tenancy — the #1 security failure mode

Cross-session leakage is the most catastrophic failure for a memory
system: tenant A receives tenant B's preferences in the prompt, model
sees both, leaks data. This is **never** acceptable, never a "should-fix",
always P0.

**Rules:**

1. `tenant_id` (or `user_id` for B2C) is a **hard partition key** in vector DB metadata — every query MUST include it as an equality filter. No exceptions.
2. Never trust the LLM to filter retrieved memories by user. The DB does it before the LLM sees anything.
3. Knowledge graph: tag every node and edge with `tenant_id`; queries scoped via Cypher `MATCH (n {tenant_id: $tid})`.
4. Post-retrieval assertion: every retrieved chunk's metadata `tenant_id` is verified against the request `tenant_id` before injecting into the prompt. Mismatched chunks raise `SecurityError`.
5. Audit log every retrieval: `(timestamp, user_id, tenant_id, chunk_ids, query_hash)` — required for SOC 2 + GDPR.

**Isolation models** (depth of separation vs cost):

| Model | Index layout | When |
|---|---|---|
| **Silo** | One vector index + one graph DB per tenant | Enterprise, regulated industries, $$$$ |
| **Pool** | Shared index, mandatory `tenant_id` filter | SMB SaaS, cost-sensitive, $ |
| **Bridge** | Top N enterprise tenants get silos, rest share a pool | Mixed customer base, $$ |

See also: skill `data_security_encryption_classification` for at-rest encryption + key per tenant.

## GDPR / CCPA right-to-be-forgotten

```python
async def forget_user(user_id: str, tenant_id: str) -> ForgetReport:
    """Hard delete every memory associated with a user. Idempotent."""

    # 1. Vector DB — delete every chunk
    deleted_vectors = await vector_db.delete(
        filter={"user_id": user_id, "tenant_id": tenant_id}
    )

    # 2. Knowledge graph — delete every node + every edge touching the user
    deleted_graph_nodes = await graph.execute(
        "MATCH (n {user_id: $uid, tenant_id: $tid}) "
        "DETACH DELETE n",
        uid=user_id, tid=tenant_id,
    )

    # 3. Relational metadata — delete sessions, transcripts, audit (or
    #    anonymise audit, per legal counsel; see legal skill).
    deleted_rows = await db.execute(
        "DELETE FROM sessions WHERE user_id = $1 AND tenant_id = $2",
        user_id, tenant_id,
    )

    # 4. Object storage cold logs — schedule deletion via lifecycle policy
    await s3.tag_for_delete(prefix=f"raw_logs/{tenant_id}/{user_id}/")

    return ForgetReport(
        vectors=deleted_vectors,
        graph_nodes=deleted_graph_nodes,
        rows=deleted_rows,
        s3_prefix_scheduled=True,
        completed_at=datetime.utcnow(),
    )
```

Persist this report — auditors will ask for proof of deletion.

## Reference architectures by maturity

```
Tier 0 — None
  Single-turn product. Don't build memory. Stateless prompt + RAG.

Tier 1 — Session-only (L2)
  Redis with TTL=session length. Conversation history goes into prompt
  while session is open; vanishes when the user logs out.

Tier 2 — Episodic only
  Add a vector DB. On session end, summarize the conversation and store
  the summary as one chunk with metadata {user_id, tenant_id, ts}.
  At session start, ANN-search the last N relevant chunks. Cheap, gets
  80% of the perceived "memory" value.

Tier 3 — Hybrid episodic + semantic
  Add a knowledge graph. Run a fact extractor on each turn; insert
  triplets (entity, relation, entity). At retrieval, do vector + 1-hop
  graph expansion. Good for personalization, agentic memory.

Tier 4 — Full Mem0-class system
  Add periodic reflection (daily background job consolidates and
  proactively reminds), conflict resolution, entity linking across
  channels (Slack, Discord, email). See skill agentic_memory_mem0.
```

Most teams should aim for Tier 2 first, only push to Tier 3-4 once the
business value is proven and the eval set shows the gap.

## Anti-patterns

- **No tenant filter on the DB query.** Trusting the LLM to filter. Inevitable cross-tenant leak.
- **Storing raw conversation logs in the vector DB.** Token-heavy, low retrieval precision. Store **summaries**; keep raw in cold storage (S3) for forensics.
- **No decay or consolidation.** Memory grows forever; retrieval precision asymptotes to noise. Catastrophic forgetting via index overload.
- **Embedding the user's full conversation history into the prompt every turn.** That's not memory, that's expensive scrollback. Use retrieval.
- **One global knowledge graph for all tenants.** Cypher injection or a missing filter and you've leaked.
- **GDPR delete = soft delete.** Not legal. Hard delete or anonymise.
- **Treating "memory" as a single store.** Episodic and semantic want different DBs; conflating them produces bad fits for both.
- **Memory of low-confidence facts.** If your fact extractor said `(user, LIKES, blue)` because the user once mentioned blue in passing, you'll surface this irrelevantly forever. Store extractor confidence and threshold at retrieval.

## Validation

- [ ] Tier chosen explicitly (0/1/2/3/4) — documented in ADR.
- [ ] `tenant_id` / `user_id` is a mandatory filter in every retrieval query.
- [ ] Post-retrieval assertion verifies tenant match before prompt injection.
- [ ] Audit log entries created per retrieval.
- [ ] Decay policy specified (TTL or λ).
- [ ] Consolidation job scheduled.
- [ ] GDPR / CCPA forget endpoint implemented + tested with E2E hard-delete proof.
- [ ] Encryption-at-rest + key-per-tenant for silo / bridge models.
- [ ] Eval set tests memory recall AND no-cross-tenant-leak as separate metrics.
- [ ] Cold storage retention policy aligned with privacy regulations.

## References

- Neo4j. "Knowledge Graphs for Generative AI" (2025)
- Pinecone. "The Managed Memory Layer" (2025)
- GraphRAG. "Reasoning over Relationships" (2024/2025)
- See also skills: `agentic_memory_mem0`, `graph_rag`, `privacy_engineering_gdpr_ccpa`, `data_security_encryption_classification`.
