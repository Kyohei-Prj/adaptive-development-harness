---
description: Run all phases automatically — implement every task, review, resolve blocking and non-blocking issues, and update docs for each phase before pausing for a checkpoint, or stopping on FAIL
agent: lead
---
Run the full Implementation → Feedback cycle for every phase in docs/$1/implementation-plan.md automatically.
Do not pause for confirmation *within* a phase. Stop and wait for the user when a subagent reports FAIL, or at the end-of-phase checkpoint (step 11).

Steps:
1. Read docs/$1/implementation-plan.md and identify all phases in order.

Repeat steps 2–11 for EACH phase N (in ascending order):

2. Create and switch to branch: `git checkout -b feature/$1-phase-N`.

3. Read docs/$1/feedback-log.md if it exists. If it contains any "Risks for future phases" entries relevant to Phase N, surface them as a brief one-line heads-up before delegating tasks. This is informational only — do not block on it or ask for confirmation.

4. Delegate each task in Phase N to `task-implementer` via the Task tool.
   Pass:
   - Task description and acceptance criteria
   - The `[type: tdd]` or `[type: smoke]` tag (verbatim from the plan)
   - Relevant file paths and architecture section references
   Tasks marked `[parallel-with: X]` may be delegated simultaneously; all others run sequentially.
   **If any task reports FAIL: stop immediately. Report the root cause and the full task summary to the user, and wait for direction before continuing.**

5. Compile the phase summary from each task-implementer's summary block:
   - Task → Approach → Test result → Deviations/risks
   Then commit: `git add -A && git commit -m "feat($1): phase N complete"`.

6. Delegate to `phase-reviewer` to review Phase N changes (diffed against the branch's fork point — see phase-reviewer's own instructions), check testing compliance, and classify all issues as blocking or non-blocking.

7. Resolve ALL blocking and non-blocking issues without asking for confirmation.
   For each issue, delegate to `issue-resolver` one at a time — sequentially, never in parallel.
   Pass the issue description, affected file(s), relevant acceptance criteria, and architecture pointers.
   Do NOT delegate "risks for future phases" to `issue-resolver` — they are speculative, not actionable fixes. They are recorded in feedback-log.md by `doc-updater` instead (step 8).
   **If any issue-resolver reports FAIL: stop immediately. Report the root cause and the issue summary to the user, and wait for direction before continuing.**

8. Delegate to `doc-updater` to apply all suggested doc edits and to append a dated entry to feedback-log.md covering the original findings (including risks for future phases) and all resolutions applied.

9. Commit all fixes and doc updates: `git add -A && git commit -m "review($1): phase N fixes and doc updates"`.

10. Report a progress summary for phase N to the user:
    - Implementation: task results (Approach → Test result → Deviations)
    - Review: blocking/non-blocking issues resolved, risks for future phases (logged, not fixed)
    - Doc changes applied

11. **Checkpoint:** ask the user to confirm before continuing to phase N+1 ("Phase N complete. Continue to phase N+1?"). Wait for their reply before proceeding. This is the one pause point in an otherwise hands-off run — it exists so a multi-phase run doesn't go fully out of sight.

Once all phases are complete, report the full run summary and remind the user to merge the feature branches to main.
