---
id: agent_design_tool_use
version: 1.1.0
owners: [ml_engineer, architect, backend_lead]
tags: [agent, tool-use, function-calling, react, planner-executor, autonomy, agentic-rag, self-rag, crag, adaptive-rag]
when_to_use: |
  Building a product where the LLM doesn't just CHAT — it does THINGS
  (call APIs, query DBs, send emails, write code). Agentic systems
  are 2024-2026's frontier; getting the architecture right separates
  reliable products from runaway-cost demos.
inputs:
  - product_goals, available_tools, autonomy_level, risk_tolerance
outputs:
  - "agent_design: pattern + tool inventory + scoping + safety + observability"
---

# Agent Design + Tool Use

> An agent is an LLM with the ability to take actions in the world.
> That's incredibly powerful and incredibly dangerous. The senior
> craft is constraining the agent so it does what's intended and
> nothing else — without making it useless.

## What is an "agent"?

Spectrum, not binary:

```
1. CHAT-ONLY        — LLM responds; no actions.
2. SINGLE TOOL      — LLM calls ONE specific tool once.
3. MULTI-TOOL       — LLM picks from several tools per request.
4. PLANNER          — LLM plans steps, executes sequentially.
5. AUTONOMOUS LOOP  — LLM runs continuously, sets own goals.
```

Most production "agents" are tier 2-3. Tier 4-5 are research /
prototypes — beware shipping them to production without strong
guardrails.

## The ReAct pattern (Yao et al, 2022)

Reasoning + Acting interleaved:

```
Thought: I need to find the user's order status.
Action: lookup_order(order_id="42")
Observation: { status: "shipped", tracking: "..." }
Thought: I should also check delivery time.
Action: estimate_delivery(tracking="...")
Observation: { eta: "2026-05-30" }
Thought: I have enough to respond.
Final Answer: Your order #42 shipped and will arrive 2026-05-30.
```

Implementation: LLM loop with tool call → tool result fed back as next
turn's context.

## Planner-Executor pattern (Wang et al, 2023)

When tasks are complex, separate planning from execution:

```
PLANNER (one LLM call): break task into ordered steps.
  Step 1: lookup_order(42)
  Step 2: estimate_delivery using tracking from step 1
  Step 3: format response

EXECUTOR (loop): execute each step; re-plan if a step fails.
```

Better than ReAct when:
- Task has clear sub-tasks.
- Steps can be parallelized.
- You want to surface plan to user for approval.

## Tool definition

A "tool" is a function the LLM can call. Define each with:

```python
{
  "name": "lookup_order",
  "description": "Get order details by order ID. Returns status, items, total.",
  "parameters": {
    "type": "object",
    "properties": {
      "order_id": {"type": "string", "description": "UUID of the order"}
    },
    "required": ["order_id"]
  }
}
```

Best practices:
- **Descriptions are PROMPTS.** Write them as if the LLM is reading
  them (because it is).
- **One purpose per tool.** Don't bundle.
- **Validate args via JSON schema.** Reject malformed before exec.
- **Tools fail gracefully.** Return error messages the LLM can reason
  about, not exceptions.
- **Idempotency keys** for non-idempotent tools (don't double-charge
  if the agent retries).

## Scoping — the safety floor

```python
# BAD — give the agent every tool you have
all_tools = [send_email, delete_user, charge_card, post_to_slack, ...]

# GOOD — task-scoped tool set
def get_tools_for_task(task_type):
    if task_type == "customer_support":
        return [lookup_order, search_kb, send_followup_email]
    if task_type == "billing_inquiry":
        return [lookup_order, get_invoice]  # no destructive actions
    ...
```

Scope tools per task. NEVER give a customer-support agent the ability
to refund money (delegate to a human approval flow).

## Human-in-the-loop (HITL) for destructive actions

```python
async def charge_customer(args):
    if args.amount > 100:
        approval = await request_human_approval({
            'agent': 'billing_agent',
            'action': 'charge',
            'args': args,
            'reasoning': ...
        })
        if not approval.approved:
            return {"error": "human declined", "reason": approval.note}
    return await stripe.charge(**args)
```

Threshold rules:
- Money: above $X.
- User-visible action (email, post): always for v1; auto-approve over
  time.
- Data destruction: always.

## Safety + injection defense

(See `ai_ml_security_prompt_injection`.) Tool-call agents are PRIME
prompt-injection targets:

- Compromised tool result → injection into next LLM call.
- Attacker plants instruction in DB row the agent reads.
- "Search the web" → attacker's site has hostile instructions.

Defenses:
- **Tag tool outputs explicitly**: "Tool output (UNTRUSTED) follows:"
- **Content-filter tool outputs** before adding to context.
- **Network egress allowlist** for tools that fetch URLs.
- **Resource caps**: max tool calls per task, max tokens per loop.
- **Time-out** total agent run.

## State management for multi-turn

```python
class AgentState:
    user_id: str
    task_id: str
    messages: list[Message]      # full conversation
    plan: list[Step] | None      # if planner
    completed_steps: list[Step]
    tool_call_count: int
    cost_so_far_usd: float
    started_at: datetime
```

Persist across turns (Redis / DB). LangGraph handles this with
`StateGraph` (which is what your orchestrator uses internally!).

## Cost + DoS protection

Per task:

```python
@dataclass
class AgentBudget:
    max_tool_calls: int = 20
    max_tokens: int = 50_000
    max_duration_sec: int = 120
    max_cost_usd: float = 1.00

    def check(self, state):
        if state.tool_call_count >= self.max_tool_calls:
            raise BudgetExceeded("tool_calls")
        if state.cost_so_far_usd >= self.max_cost_usd:
            raise BudgetExceeded("cost")
        if (now() - state.started_at).total_seconds() >= self.max_duration_sec:
            raise BudgetExceeded("duration")
```

Without budgets, a runaway loop = surprise $10,000 bill. Per-user limit
on TOTAL daily agent cost.

## Observability — full trace per task

```
task_id: abc123
user_id: 42
turns:
  - role: user, content: "what's my order status?"
  - role: assistant, thought: "...", tool_call: lookup_order(id=42)
    tool_result: {...}, cost: 0.012
  - role: assistant, content: "your order shipped..."
total_tokens: 1840
total_cost_usd: 0.024
duration_ms: 4200
```

Tools: LangSmith, Helicone, Phoenix, Langfuse, Helicone, OpenTelemetry +
GenAI semconv. Replay-capable for debugging.

## Frameworks vs roll-your-own

| Framework | Strength |
|---|---|
| **LangGraph** | Graph-based, stateful, your orchestrator's stack |
| **LangChain** | Quick start, lots of integrations |
| **LlamaIndex** | RAG-heavy, agent extensions |
| **CrewAI** | Multi-agent collaboration |
| **AutoGen (Microsoft)** | Multi-agent research-y |
| **Anthropic Computer Use** | Browser / desktop control |
| **MCP (Model Context Protocol)** | Tool standard across providers |
| **DSPy** | Compile prompts to optimized programs |
| **Roll-your-own** | Production, you want full control |

For production agents: roll-your-own with LangGraph or DSPy under the
hood. The frameworks change fast; lock-in is real.

## MCP (Model Context Protocol)

Anthropic's standard for tools-as-servers. A tool implements MCP; any
LLM that speaks MCP can use it. Reduces N×M integration to N+M.

If you're building tools for a multi-LLM ecosystem (or want
re-usability), implement them as MCP servers.

## Evaluation specifically for agents

Beyond `ai_ml_testing_evals` general framework:

- **Task completion rate** — % of tasks reach a valid terminal state.
- **Tool call success rate** — tool calls return non-error.
- **Plan adherence** — does executor follow planner's steps?
- **Cost per task** — measured.
- **Steps to completion** — variable; tighter = better usually.
- **Recovery from tool errors** — agent handles failures gracefully?

## Specific agent types

### Customer support
- Tools: KB search, order lookup, ticket create.
- HITL: escalation, refunds.
- Eval: resolution rate, time to resolution.

### Coding assistant
- Tools: file read/write, test run, code search.
- HITL: PR creation, deletion.
- Eval: passes tests, doesn't break existing.

### Research / browsing
- Tools: web search, page fetch, summarize.
- HITL: action items (book, buy).
- Eval: factual accuracy of synthesis.

### Data analysis
- Tools: SQL query, chart render, calculate.
- HITL: cross-team data sharing.
- Eval: matches human analyst on golden set.

## Agentic RAG patterns (when retrieval IS the agent's primary action)

When the agent's main tool is retrieval, the linear-pipeline RAG of
the `vector_search_rag_architecture` skill becomes a **reasoning
loop**. Four production patterns dominate:

### Self-RAG — critic tokens (Asai et al, 2024)

The model emits inline reflection tokens that grade its own work:

```
[Retrieve?]   Yes/No  — should I retrieve here?
[Relevant?]   Yes/No  — is the retrieved info relevant?
[Supported?]  Fully/Partially/No — is my answer grounded in evidence?
[Useful?]     1-5     — is this answer actually useful?
```

If any check fails, the agent loops back to an earlier step. Trained
into the model via fine-tuning (Self-RAG checkpoint) OR prompted into
a frontier model via structured output.

### Corrective RAG (CRAG) — relevance grader + correction

```
                   User query
                       │
                       ▼
                 Retrieve top-K
                       │
                       ▼
              ┌──────────────────┐
              │ Relevance Grader │
              └────────┬─────────┘
                       │
            ┌──────────┼──────────┐
            ▼          ▼          ▼
        CORRECT    AMBIGUOUS    WRONG
            │          │          │
            ▼          ▼          ▼
        Generate   Supplement   Reformulate
        directly    with web    query + retry
                     search
```

```python
async def crag(query: str, max_corrections: int = 2) -> str:
    for attempt in range(max_corrections + 1):
        chunks = await retrieve(query, top_k=10)
        grade = await grade_relevance(query, chunks)

        if grade.verdict == "correct":
            return await generate(query, chunks)
        elif grade.verdict == "ambiguous":
            web = await web_search(query)
            return await generate(query, merge_dedupe(chunks, web))
        else:  # "wrong"
            query = await reformulate(query, reason=grade.reason)

    return await generate_with_caveat(query, chunks)
```

### Adaptive RAG — pipeline depth gated by classifier

Not every query deserves the full agentic loop. A lightweight
classifier picks the depth:

```
query → [classifier] → direct LLM | simple RAG | multi-hop | agentic
```

See skill `production_rag_at_scale` for the four-path router. The
key insight is **budget retrieval like cost** — if the classifier
says simple, run simple. Don't spend 8-12s on a question that
deserved 1s.

### Multi-hop reasoning loop

For questions like "Who is the CEO of the company that acquired
Figma?" — chain retrievals:

```
Hop 1: "Who acquired Figma?"         → Adobe
Hop 2: "CEO of Adobe"                 → Shantanu Narayen
```

The agent maintains a **state object** and updates its **sub-goal**
after every retrieval until the chain is complete. Cap at 3-5 hops
(see budget caps below) to avoid retrieval thrash.

### Reasoning-retrieval balance — the production trade-off

Every reasoning turn costs tokens and latency. Agentic RAG is
non-deterministic by design (a small query change picks a different
tool path → different answer format). Mitigations:

| Failure mode | Mitigation |
|---|---|
| Retrieval thrash (near-duplicate queries oscillating) | Limit to 3-5 iterations; track query uniqueness per session |
| Tool storms (10× tool calls in one turn) | Per-query tool-call limit + cost ceiling (see "Cost + DoS protection" above) |
| Context bloat (chunks accumulate past window) | Sliding window — drop oldest chunks when context > threshold |
| Non-determinism complaints | Constrained graphs (LangGraph, DSPy) — the *paths* are fixed, only the *choice* is stochastic |
| Latency spikes | Adaptive RAG — route easy queries to fast path; reserve agentic for hard |

**Budget rule of thumb:** a 3-4 iteration loop typically takes 8-12s
end-to-end. If your UX needs sub-3s response, route easy queries to
Adaptive's fast path and reserve the full loop for genuine multi-hop
questions.

See companion skills: `production_rag_at_scale` (routing + monitoring),
`vector_search_rag_architecture` (basic RAG), `graph_rag` (multi-hop
via graph traversal as an alternative to iterative retrieval).

## Anti-patterns

- **Give agent ALL tools, hope it picks wisely.** Will pick wrong.
- **No budget limit.** Runaway.
- **No human in loop for destructive.** Disaster waiting.
- **Tool that exec's LLM output.** RCE via injection.
- **Tools that leak secrets** in error messages.
- **No state persistence.** Multi-turn loses context.
- **No trace / logs.** Can't debug; can't improve.
- **Treating "AGI agent" as one model.** It's an orchestration problem.
- **Skipping eval — "the demo worked".** Demos and production diverge.
- **Agent without rate limit per user.** Cost + abuse risk.

## Validation

- [ ] Tool inventory documented; each tool scoped to task type.
- [ ] HITL for destructive actions.
- [ ] Per-task budget enforced.
- [ ] Tool output tagged as untrusted in agent context.
- [ ] Trace logged for every task; replay-capable.
- [ ] Eval metric for task completion + cost.
- [ ] Recovery from tool errors tested.
- [ ] Rate limit per user.
- [ ] State persisted across turns.
- [ ] Time-out on total run.
