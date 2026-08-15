---
description: Start the Planning stage for a new idea, feature, or bug fix — ideally after a /grill alignment session
agent: planner
---
We are starting a new Planning session.

Idea / design concept: $ARGUMENTS

If this includes a design concept summary from a prior `/grill` session,
treat it as already-aligned input and transcribe it into docs rather than
re-litigating the design. If it's just a bare headline, say so and proceed
with direct clarifying questions.

Steps:
1. Propose a short kebab-case slug for this work and confirm it with me.
2. Ask any remaining clarifying questions ONE AT A TIME. For each question, provide up to 4 suggestions. Mark one as your recommended answer.
3. Once ready, write using the `planning-docs` skill:
   - docs/<slug>/architecture.md
   - docs/<slug>/spec.md
   - docs/<slug>/implementation-plan.md — phases structured as **vertical slices** (each phase crosses every layer needed for one thin, reviewable, end-to-end piece of behavior), not horizontal layers
   - docs/<slug>/feedback-log.md (header only, no entries yet)
4. Every task in implementation-plan.md MUST have a [type: tdd] or [type: smoke] tag. Use the planning-docs skill for classification rules.
5. Do not write any application code in this stage.
