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
4. Propose an optional tracer-bullet Phase 0 for greenfield or architecture-unproven work, and `[type: spike]` tasks for open technical questions that could invalidate the plan; skip Phase 0 explicitly for brownfield or small slugs — see the planner's Phase 0 / spike rules and the `vertical-slicing` skill.
5. Every task in implementation-plan.md MUST have a [type: tdd], [type: smoke] or [type: spike] tag. Use the planning-docs skill for classification rules.
6. Do not write any application code in this stage.
