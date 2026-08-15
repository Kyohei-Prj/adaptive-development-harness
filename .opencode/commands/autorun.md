---
description: Run all phases automatically — implement every task, review, resolve blocking and non-blocking issues, and update docs for each phase before pausing for a checkpoint, or stopping on FAIL
agent: lead
---
Run the full Implementation → Feedback cycle for every phase in docs/$1/implementation-plan.md automatically.
Do not pause for confirmation *within* a phase. Stop and wait for the user when a subagent reports FAIL, or at the end-of-phase checkpoint (step 11).

Steps:
1. Read docs/$1/implementation-plan.md and identify all phases in order.

Repeat steps 2–11 for EACH phase N (in ascending order):

2. Capture the current branch before creating anything new: `BASE=$(git branch --show-current)`. Then create and switch to branch: `git checkout -b feature/$1-phase-N`.
   Append a row to `docs/$1/phase-branches.md` (create with header if this is Phase 1): `| N | feature/$1-phase-N | <value of BASE> |`. `phase-reviewer` reads this file for its diff baseline — do not skip it.

3. Read docs/$1/feedback-log.md if it exists. If it contains any "Risks for future phases" or "Deferred issues" entries relevant to Phase N, surface them as a brief one-line heads-up before delegating tasks. This is informational only — do not block on it or ask for confirmation.

4. Group Phase N's tasks by `[parallel-with: ...]` tags.
   For each parallel group (2+ tasks tagged parallel with each other):
   a. For each task, create an isolated worktree on its own branch off the phase branch: `git worktree add -b task/$1-<task-id> .worktrees/$1-<task-id>`.
   b. Delegate each task to `task-implementer` via the Task tool, telling it its working directory is `.worktrees/$1-<task-id>` — cd there first, don't touch files outside it.
   c. Once all tasks in the group report done, merge each task branch back sequentially, one at a time: `git merge task/$1-<task-id>`. **If a merge conflict occurs: stop immediately, report it to the user, and wait for direction — do not auto-resolve.**
   d. After a successful merge, clean up: `git worktree remove .worktrees/$1-<task-id>` and `git branch -d task/$1-<task-id>`.
   Tasks with no `[parallel-with: ...]` tag run sequentially in the main working tree.
   For every delegation, pass:
   - Task description and acceptance criteria
   - The `[type: tdd]` or `[type: smoke]` tag (verbatim from the plan)
   - Relevant file paths and architecture section references
   **If any task reports FAIL: stop immediately. Report the root cause and the full task summary to the user, and wait for direction before continuing.**

5. Compile the phase summary from each task-implementer's summary block:
   - Task → Approach → Test result → Deviations/risks
   Then commit (including `phase-branches.md`): `git add -A && git commit -m "feat($1): phase N complete"`.

6. Delegate to `phase-reviewer` to review Phase N changes (diffed against the branch's fork point — see phase-reviewer's own instructions), check testing compliance, and classify all issues as blocking or non-blocking.

7. Resolve ALL blocking and non-blocking issues without asking for confirmation.
   For each issue, delegate to `issue-resolver` one at a time — sequentially, never in parallel.
   Pass the issue description, affected file(s), relevant acceptance criteria, and architecture pointers.
   Do NOT delegate "risks for future phases" to `issue-resolver` — they are speculative, not actionable fixes. They are recorded in feedback-log.md by `doc-updater` instead (step 8).
   **If any issue-resolver reports FAIL: stop immediately. Report the root cause and the issue summary to the user, and wait for direction before continuing.** If the user's direction is to skip that issue and proceed, treat it as a **deferred issue** (not silently dropped) — it must be logged in step 8, not just abandoned.

8. Delegate to `doc-updater` to apply all suggested doc edits and to append a dated entry to feedback-log.md covering the original findings, any deferred issues (issues confirmed as real but not fixed this round, whether skipped after a FAIL or otherwise), risks for future phases, and all resolutions applied.

9. Commit all fixes and doc updates: `git add -A && git commit -m "review($1): phase N fixes and doc updates"`.

10. Report a progress summary for phase N to the user:
    - Implementation: task results (Approach → Test result → Deviations)
    - Review: blocking/non-blocking issues resolved, risks for future phases (logged, not fixed)
    - Doc changes applied

11. **Checkpoint:** ask the user to confirm before continuing to phase N+1 ("Phase N complete. Continue to phase N+1?"). Wait for their reply before proceeding. This is the one pause point in an otherwise hands-off run — it exists so a multi-phase run doesn't go fully out of sight.

Once all phases are complete, report the full run summary and remind the user to run `/finalize $1` before merging, and `/archive $1` after merging to main.
