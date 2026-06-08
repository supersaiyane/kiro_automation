---
id: jtbd_interviews
version: 1.0.0
owners: [market_researcher]
tags: [market, jobs-to-be-done, jtbd, interview, segmentation]
when_to_use: |
  Defining target segments + the underlying jobs they're hiring this
  product to do. The first artifact in the DISCOVERY phase — every
  downstream role depends on the segments and jobs you name here.
inputs:
  - project_description: raw idea or brief
outputs:
  - target_segments: 2-3 personas with job statements
  - opportunity_areas: under- or over-served jobs
---

# Jobs To Be Done (JTBD)

**Premise**: customers don't buy products; they "hire" them to make
progress on a job. Find the job, not the demographic.

**Job statement template**

> When *situation*, I want to *motivation*, so I can *expected outcome*.

Example (a payments product):
> When **I'm chasing an overdue invoice for the 3rd time**, I want **the
> customer to be able to pay in one click without logging in**, so I can
> **stop spending 4 hours/week on collections**.

**Method**
1. Recruit 6-10 recent buyers/users of an adjacent product.
2. Ask only about the SITUATION that drove them to look. Never lead with
   feature questions.
3. Extract the job statement. The same situation often has 2-3 distinct
   jobs (e.g. emotional + functional + social).
4. Score each job for: frequency, importance, current satisfaction.
   Under-served jobs (high importance × low satisfaction) are the
   strongest opportunities.

**Anti-patterns**
- "We surveyed our customers and they said they want X" — selection
  bias of the worst kind. They're not your buyer's universe.
- Demographics-as-segments. "Young professionals in cities" is a
  bucket, not a job.
- Asking "would you buy this if it cost $X" — almost everyone says yes.
  Behavioral signal beats stated intent.
