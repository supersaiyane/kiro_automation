---
id: diataxis_framework
version: 1.0.0
owners: [technical_writer]
tags: [documentation, diataxis, structure, tutorials, how-to, reference]
when_to_use: |
  Structuring a new product's documentation set. Use as the first
  decision before writing any pages — every page belongs to exactly
  one quadrant.
inputs:
  - product_capabilities: from prd, fe_code, be_code
outputs:
  - doc_map: page -> quadrant assignment
---

# The Diataxis Framework

Four quadrants on two axes (cognition + practice):

|                  | **Practical steps**       | **Theoretical knowledge**  |
|------------------|---------------------------|-----------------------------|
| **Learning**     | Tutorials                 | Concepts (explanation)      |
| **Working**      | How-to guides             | Reference                   |

- **Tutorials** — learning-oriented. The user wants to acquire skill.
  Hold their hand. "Build a hello-world bot in 10 minutes."
- **How-to** — task-oriented. The user already knows what they want.
  No teaching. "How to rotate the API key."
- **Reference** — information-oriented. Auto-generated where possible
  (API spec → OpenAPI page). Dry, exhaustive.
- **Concepts** — understanding-oriented. The "why" pages. Architecture
  overview, security model, glossary.

**Rule**: no page mixes two quadrants. A tutorial that bleeds into
reference loses the reader; a how-to that explains theory becomes a
concept doc by accident.

**Anti-patterns**
- A single "documentation" page that tries to do all four.
- API reference written by humans, drifting from the OpenAPI source.
- Tutorials that assume prior knowledge.
- How-to guides longer than 7 steps — split them.
