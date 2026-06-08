---
id: audience_adaptation
version: 1.0.0
owners: [technical_writer]
tags: [documentation, audience, end-user, developer, operator, segmentation]
when_to_use: |
  Same product, multiple audiences. Adapt depth, voice, and content
  set per audience — never publish one merged page hoping everyone
  finds what they need.
inputs:
  - product_capabilities + audience_segments
outputs:
  - per_audience_pages: end-user / developer / operator tracks
---

# Audience Adaptation

**Three default audiences. Decide explicitly which a page is for.**

| Audience      | Wants to              | Tone         | Depth | Code samples? |
|---------------|------------------------|--------------|-------|----------------|
| End user      | Get value, fast        | Reassuring   | Shallow | No            |
| Developer     | Integrate / extend     | Direct       | Deep  | Yes (every page) |
| Operator      | Keep it running        | Imperative   | Medium | Configs + commands |

**Translation table (eng → audience)**

| Engineering says               | End-user reads               | Developer reads              | Operator reads               |
|--------------------------------|------------------------------|------------------------------|------------------------------|
| "WebSocket push via Redis pub/sub" | "Get notified the moment something changes" | "Subscribe to `events.*` topics via `wss://api/...`" | "Redis is on the critical path for notifications" |
| "JWT refresh every 60 min"     | "You stay logged in"         | "Call `POST /auth/refresh` before expiry" | "Watch `auth.refresh_failures` SLI" |
| "Postgres replica lag < 1s"    | (don't expose)               | "Reads may lag writes briefly" | "Alert if replica lag > 5s" |

**Page header convention**

Every page starts with `**For:** <audience>`. Search and navigation
filter on it. Pages that try to serve everyone serve no one.

**Anti-patterns**
- Cross-audience knowledge bleeds (developer detail in end-user docs,
  marketing tone in operator runbooks).
- Translating engineering into marketing fluff — pick one register,
  stick to it.
- Hidden assumptions about prior knowledge. "Familiarity with X
  assumed" is OK if X is named in the page header.
