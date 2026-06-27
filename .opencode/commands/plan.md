---
description: Start the Planning stage for a new idea, feature, or bug fix
agent: planner
---
We are starting a new Planning session.

Idea: $ARGUMENTS

Steps:
1. Propose a short kebab-case slug for this work and confirm it with me.
2. Ask clarifying questions ONE AT A TIME until you have enough detail.
3. Once ready, write using the `planning-docs` skill:
   - docs/<slug>/architecture.md
   - docs/<slug>/spec.md
   - docs/<slug>/implementation-plan.md
   - docs/<slug>/feedback-log.md (header only, no entries yet)
4. Every task in implementation-plan.md MUST have a [type: tdd] or [type: smoke] tag. Use the planning-docs skill for classification rules.
5. Do not write any application code in this stage.
