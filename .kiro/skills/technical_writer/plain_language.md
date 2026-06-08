---
id: plain_language
version: 1.0.0
owners: [technical_writer]
tags: [documentation, plain-language, readability, style, clarity]
when_to_use: |
  Any user-facing prose — error messages, empty states, onboarding,
  changelogs, release notes, in-product copy. Pair with the diataxis
  framework for structure.
inputs:
  - draft_text: the prose to review or write
outputs:
  - revised_text: shorter, clearer, audience-appropriate
---

# Plain Language

**Six rules. Apply every time.**

1. **Active voice.** "We log every event" — not "Events are logged."
2. **Subject-verb-object near the start.** Don't bury the actor.
3. **Short sentences.** Aim for 15-20 words. Anything over 28 is a
   refactor candidate.
4. **One idea per sentence.** Commas + "and" stitching three thoughts
   together = three sentences.
5. **Concrete over abstract.** "Returns within 200ms" beats "fast
   response time."
6. **Cut the modifier.** "Robust", "seamless", "powerful", "next-
   generation", "best-in-class" add zero information.

**Reading-level target**

- End-user docs: 8th-grade reading level (use Flesch-Kincaid).
- Developer docs: 11th-grade. They can handle "polymorphism" — but
  introduce it once, with a one-line definition.
- Operator runbooks: imperative voice. Step 1, Step 2, no fluff.

**Anti-patterns**
- Marketing voice in product docs.
- Apologetic hedges ("you might want to consider").
- "Simply" — if it were simple, you wouldn't be writing this.
- "Just" — same.
- Long paragraphs. Three sentences is a paragraph; six is a wall.
