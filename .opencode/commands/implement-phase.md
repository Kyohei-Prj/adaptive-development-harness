---
description: Implement a phase by delegating each task to the task-implementer subagent
agent: lead
---
Implement Phase $1 of docs/$2/implementation-plan.md.

Follow the `phase-lifecycle` skill for the mechanical procedures below — this command only states the policy specific to it (interactive, asks nothing in the normal flow but reports as it goes — a stop condition below is the only thing that prompts a question).

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
6. Stage and commit the doc changes (including `phase-branches.md`): `git add docs/$2/ && git commit -m "feat($2): phase $1 complete"`.

## Stop conditions — do not attempt to work around any of these

- **Any `task-implementer` reports FAIL.** Do not retry, do not reinterpret the task, do not skip it and continue to the next task.
- **A worktree merge conflict occurs** during parallel-task merge-back (`phase-lifecycle` part B, step 3). Never attempt automatic conflict resolution.
- **Any destructive-command refusal surfaces from a subagent** (see the hard-blocked commands paragraph in `task-implementer.md`) that blocks completing a task as described.

On any stop condition: do NOT commit. Stop delegating, surface the root cause to me in full — what was attempted, what succeeded before the stop, and exactly what stopped it — and ask me for direction instead of halting or working around it.

On any stop condition also record which tasks of Phase $1 ended up not completed — the failed one plus any later ones left undelegated under the direction I give — and surface that list to me alongside the root cause. Those tasks are **deferred, not dropped**: `/review-phase` logs them in `docs/$2/feedback-log.md` under "Deferred issues" exactly like ones I decline to resolve (`phase-lifecycle` part C, point 4 — it already treats a skip after a FAIL as a deferred issue, a real finding, not a speculative risk), and they resurface as a heads-up at the start of later phases.
