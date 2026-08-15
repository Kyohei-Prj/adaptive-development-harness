---
description: Implement a phase by delegating each task to the task-implementer subagent
agent: lead
---
Implement Phase $1 of docs/$2/implementation-plan.md.

Steps:
0. Capture the current branch before creating anything new: `BASE=$(git branch --show-current)`. Then create and switch to a new branch: `git checkout -b feature/$2-phase-$1`.
   Record the base explicitly rather than assuming it from a naming pattern — append a row to `docs/$2/phase-branches.md` (create the file with its header first if this is Phase 1): `| $1 | feature/$2-phase-$1 | <value of BASE> |`. This file is what `phase-reviewer` reads later to know the correct diff baseline — do not skip it.
1. Read docs/$2/implementation-plan.md and find Phase $1's task list.
2. Read docs/$2/feedback-log.md if it exists. If it contains any "Risks for future phases" or "Deferred issues" entries relevant to Phase $1, surface them to me as a brief one-line heads-up before delegating tasks. This is informational only — do not block on it or ask for confirmation.
3. Group tasks by their `[parallel-with: ...]` tags. For each parallel group (2+ tasks tagged as parallel with each other):
   a. For each task in the group, create an isolated git worktree on its own branch off the current phase branch: `git worktree add -b task/$2-<task-id> .worktrees/$2-<task-id>`.
   b. Delegate each task to `task-implementer` via the Task tool, telling it explicitly: "Your working directory for this task is `.worktrees/$2-<task-id>` — cd there first, and don't touch files outside it."
   c. Once all tasks in the group report done, merge each task branch back into the phase branch **sequentially, one at a time** (never in parallel): `git merge task/$2-<task-id>`. If a merge conflict occurs, stop immediately, report the conflict to me, and wait for direction — do not attempt to resolve it automatically.
   d. After a successful merge, clean up: `git worktree remove .worktrees/$2-<task-id>` and `git branch -d task/$2-<task-id>`.
   Tasks with no `[parallel-with: ...]` tag run sequentially in the main working tree as before — do not create a worktree for a task that isn't part of a parallel group. For every delegation (parallel or sequential), pass: task description and acceptance criteria, the `[type: tdd]` or `[type: smoke]` tag (copied verbatim from the plan), and relevant file/architecture pointers.
4. Do not edit files yourself — delegate and track.
   Use `todowrite` to track task status if useful.
5. When all tasks are done, compile a phase summary from each task-implementer's summary block:
   - Task → Approach → Test result → Deviations/risks
   Flag any FAIL or deviation before declaring the phase ready for review.
6. Stage and commit all changes (including `phase-branches.md`): `git add -A && git commit -m "feat($2): phase $1 complete"`.
