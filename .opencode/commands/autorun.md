---
description: Run all phases automatically — implement every task, review, resolve all blocking issues, and update docs for each phase before moving to the next, without pausing for confirmation
agent: lead
---
Run the full Implementation → Feedback cycle for every phase in docs/$1/implementation-plan.md automatically.
Do not pause for confirmation between steps. Stop and wait for the user only when a subagent reports FAIL.

Steps:
1. Read docs/$1/implementation-plan.md and identify all phases in order.

Repeat steps 2–9 for EACH phase N (in ascending order):

2. Create and switch to branch: `git checkout -b feature/$1-phase-N`.

3. Delegate each task in Phase N to `task-implementer` via the Task tool.
   Pass:
   - Task description and acceptance criteria
   - The `[type: tdd]` or `[type: smoke]` tag (verbatim from the plan)
   - Relevant file paths and architecture section references
   Tasks marked `[parallel-with: X]` may be delegated simultaneously; all others run sequentially.
   **If any task reports FAIL: stop immediately. Report the root cause and the full task summary to the user, and wait for direction before continuing.**

4. Compile the phase summary from each task-implementer's summary block:
   - Task → Approach → Test result → Deviations/risks
   Then commit: `git add -A && git commit -m "feat($1): phase N complete"`.

5. Delegate to `phase-reviewer` to review Phase N changes (via git diff/log), check testing compliance, and classify all issues as blocking or non-blocking.

6. Resolve ALL issues and risks (blocking, non-blocking, and future-phase risks) without asking for confirmation.
   For each item, delegate to `issue-resolver` one at a time — sequentially, never in parallel.
   Pass the issue or risk description, affected file(s), relevant acceptance criteria, and architecture pointers.
   **If any issue-resolver reports FAIL: stop immediately. Report the root cause and the issue summary to the user, and wait for direction before continuing.**

7. Delegate to `doc-updater` to apply all suggested doc edits and to append a dated entry to feedback-log.md covering both the original findings and all resolutions applied.

8. Commit all fixes and doc updates: `git add -A && git commit -m "review($1): phase N fixes and doc updates"`.

9. Report a progress summary for phase N to the user before continuing:
   - Implementation: task results (Approach → Test result → Deviations)
   - Review: blocking issues resolved, non-blocking findings, risks for future phases
   - Doc changes applied
   Then move on to phase N+1.

Once all phases are complete, report the full run summary and remind the user to merge the feature branches to main.
