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
3. Pattern selection: ask the blueprint's four questions — one at a time — **How well do I know *what* to build?**, **How well do I know *how*?**, **How expensive is a mistake?**, **Is "done" machine-checkable?** — and record the answers as the Pattern Record at the top of implementation-plan.md (format: the `planning-docs` skill template). Tag every phase `[mode: sdd]`, `[mode: interactive]` or `[mode: autorun]` with a one-line rationale; absent tag = `[mode: sdd]` (default). Feed the answers into the proposals: low "know how" → `[type: spike]` task(s) and/or a tracer-bullet Phase 0 (step 5); high mistake cost → flag it in the Pattern Record and draft the scenarios into `acceptance.md` with `Status: Draft` (the `planning-docs` skill owns the template; step 8 is the approval gate); machine-checkable "done" → propose `[mode: autorun]` for suitable phases. See the planner's Pattern selection section for the full step.
4. Once ready, write using the `planning-docs` skill:
   - docs/<slug>/architecture.md
   - docs/<slug>/spec.md
   - docs/<slug>/implementation-plan.md — Pattern Record at the top, phases structured as **vertical slices** (each phase crosses every layer needed for one thin, reviewable, end-to-end piece of behavior), not horizontal layers, every phase tagged `[mode: …]` per step 3
   - docs/<slug>/acceptance.md — only when the Pattern Record flags high mistake cost (numbered Given/When/Then scenarios, `Status: Draft`; the `planning-docs` skill owns the template; step 8 is the approval gate)
   - docs/<slug>/feedback-log.md (header only, no entries yet)
5. Propose an optional tracer-bullet Phase 0 for greenfield or architecture-unproven work, and `[type: spike]` tasks for open technical questions that could invalidate the plan; skip Phase 0 explicitly for brownfield or small slugs — see the planner's Phase 0 / spike rules and the `vertical-slicing` skill.
6. Every task in implementation-plan.md MUST have a [type: tdd], [type: smoke] or [type: spike] tag. Use the planning-docs skill for classification rules.
7. Do not write any application code in this stage.
8. End with the acceptance approval step: if you drafted docs/<slug>/acceptance.md, present the scenarios and ask me for explicit approval — only I flip its Status line, `Status: Draft` → `Status: Approved YYYY-MM-DD` (no agent edits that line). A required acceptance.md still in `Draft` blocks implementation — Implementation must not start on it; the phase review enforces this. Skip the step when no acceptance.md was drafted. See the planner's Acceptance scenarios section for the full rule.
