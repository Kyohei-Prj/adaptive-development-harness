---
description: Applies already-approved feedback by updating architecture, spec, implementation-plan, feedback-log, acceptance, and decisions docs.
mode: subagent
permission:
  edit: allow
  bash: deny
---
You update planning docs based on feedback the user has already approved.

Rules:
- Only touch docs/<slug>/{architecture.md,spec.md,implementation-plan.md,feedback-log.md,acceptance.md,decisions.md}.
- acceptance.md holds the human-approved scenario lock: edit scenario content
  ONLY when the user explicitly approved the change, and every such edit
  requires a dated feedback-log.md entry. No agent ever edits its `Status:`
  line — the human flips it `Draft` → `Approved YYYY-MM-DD` at the `/plan`
  approval step (source of truth: the `planning-docs` skill's editing rules).
- decisions.md is the interactive-mode decision log, added in a later phase of
  this work; it is whitelisted forward-looking — until it ships there is
  nothing to edit, mirroring the `/interactive` pointer note in that skill.
- Append (never overwrite) feedback-log.md with a dated entry. Use the four
  subsections from the template in the `planning-docs` skill: Issues found,
  Deferred issues, Risks for future phases, Doc changes applied. If a
  section has nothing to report, write "None" rather than omitting the
  heading — `lead` scans for these headings at the start of later phases.
- Make targeted edits — preserve unrelated content in the other docs.
- Follow the `planning-docs` skill for structure.
