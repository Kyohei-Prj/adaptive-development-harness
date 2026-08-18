---
description: "Non-interactive variant of /implement-phase, for use from scripts/autorun.sh via `opencode run` — no checkpoints, ends with an AUTORUN_STATUS trailer instead of asking the user anything"
agent: lead
---
Implement Phase $1 of docs/$2/implementation-plan.md.

This command is meant to be invoked non-interactively (`opencode run --agent lead "/implement-phase-auto $1 $2"`), as one step of `scripts/autorun.sh`. There is no human present to ask anything of. Never pause for confirmation.

Follow the `phase-lifecycle` skill for the mechanical procedures below (parts A, B, D).

Steps:
1. Phase branch setup — see `phase-lifecycle` skill, part A. (Slug: $2, phase: $1.)
2. Read docs/$2/implementation-plan.md and find Phase $1's task list.
3. Read docs/$2/feedback-log.md if it exists. If it contains "Risks for future phases" or "Deferred issues" entries relevant to Phase $1, include them in the final report (below) as a heads-up. Purely informational — never blocks.
4. Delegate tasks — see `phase-lifecycle` skill, part B, for parallel `[parallel-with: ...]` groups (worktree isolation, sequential merge-back). A merge conflict here is a stop condition (below), not something to resolve automatically.
5. Compile the phase summary from each task-implementer's summary block: Task → Approach → Test result → Deviations/risks.
6. If everything above succeeded with no unresolved problems: stage and commit all changes (including `phase-branches.md`): `git add -A && git commit -m "feat($2): phase $1 complete"`. Then produce the final report (see format below) with status `OK`.

## Stop conditions — do not attempt to work around any of these

- **Any `task-implementer` reports FAIL.** Do not retry, do not reinterpret the task, do not skip it and continue to the next task.
- **A worktree merge conflict occurs** during parallel-task merge-back (`phase-lifecycle` part B, step 3). Never attempt automatic conflict resolution.
- **Any destructive-command refusal surfaces from a subagent** (see the denylist in `task-implementer.md`) that blocks completing a task as described.

On any stop condition: do NOT commit. Produce the final report with status `FAIL` (for a task/tool failure) or `NEEDS_HUMAN` (for a merge conflict or a genuine judgment call — something that isn't broken, but shouldn't be decided unattended), with enough detail in the reason that a human reading only this output later can act on it without needing to have watched the run.

## Final report format

Follow the `phase-lifecycle` skill, part D, for the `AUTORUN_STATUS:` trailer format. Structure the response as:

```
## Phase $1 Implementation Report — $2

<phase summary: task results, and any risks/deferred-issues heads-up from step 3>

AUTORUN_STATUS: OK
```

or, on a stop condition, replace the summary line with what was attempted, what succeeded before the stop, and the full detail of what stopped it, and use `AUTORUN_STATUS: FAIL: <reason>` or `AUTORUN_STATUS: NEEDS_HUMAN: <reason>` as appropriate.
