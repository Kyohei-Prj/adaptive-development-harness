---
description: Implement a phase by delegating each task to the task-implementer subagent
agent: lead
---
Implement Phase $1 of docs/$2/implementation-plan.md.

Follow the `phase-lifecycle` skill for the mechanical procedures below — this command only states the policy specific to it (interactive, asks nothing but reports as it goes).

Steps:
0. Phase branch setup — see `phase-lifecycle` skill, part A. (Slug: $2, phase: $1.)
1. Read docs/$2/implementation-plan.md and find Phase $1's task list.
2. Read docs/$2/feedback-log.md if it exists. If it contains any "Risks for future phases" or "Deferred issues" entries relevant to Phase $1, surface them to me as a brief one-line heads-up before delegating tasks. This is informational only — do not block on it or ask for confirmation.
3. Delegate tasks — see `phase-lifecycle` skill, part B, for parallel `[parallel-with: ...]` groups (worktree isolation, sequential merge-back, stop on conflict). Tasks with no such tag run sequentially in the main working tree.
4. Do not edit files yourself — delegate and track.
   Use `todowrite` to track task status if useful.
5. When all tasks are done, compile a phase summary from each task-implementer's summary block:
   - Task → Approach → Test result → Deviations/risks
   Flag any FAIL or deviation before declaring the phase ready for review.
6. Stage and commit all changes (including `phase-branches.md`): `git add -A && git commit -m "feat($2): phase $1 complete"`.
