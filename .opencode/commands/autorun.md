---
description: Run all phases automatically — implement every task, review, resolve blocking and non-blocking issues, and update docs for each phase before pausing for a checkpoint, or stopping on FAIL
agent: lead
---
Run the full Implementation → Feedback cycle for every phase in docs/$1/implementation-plan.md automatically, inside this one session.

Follow the `phase-lifecycle` skill for the mechanical procedures below — this command's policy: no confirmation within a phase (resolve all blocking/non-blocking issues automatically), one checkpoint between phases. For a long plan, prefer `scripts/autorun.sh` instead — it gets the same hands-off behavior with a genuinely fresh session per phase rather than one accumulating session for the whole run (README → *Tips & Conventions, "Smart zone / dumb zone"*).

Steps:
1. Read docs/$1/implementation-plan.md and identify all phases in order.

Repeat steps 2–12 for EACH phase N (in ascending order):

2. Mode gate — before touching git for phase N, read its `[mode: …]` tag from the `## Phase N — …` heading area (on the heading line or immediately under it) in docs/$1/implementation-plan.md; tag semantics: the `planning-docs` skill, "Phase mode tags". `[mode: sdd]`, `[mode: autorun]`, or an absent tag (= `[mode: sdd]`, backward compatible — proceed exactly as today) → this phase continues with the steps below unchanged. `[mode: interactive]` → stop the whole run at this phase: do not run phase branch setup, do not delegate, do not commit, and do not skip ahead to later phases silently — the run halts at the blocking phase and its trailer names it. The gate sits before step 3 on purpose: a refusal mutates no git state (no phase branch, no `phase-branches.md` row, no worktree) and leaves nothing to commit. End the response with the refusal explanation (this phase belongs to the human pair loop at `/interactive`, which lands in a later phase of this workflow-patterns work — until it ships, the refusal stands on its own and the pointer is forward-looking) and exactly this trailer line: `AUTORUN_STATUS: NEEDS_HUMAN: phase N is [mode: interactive]`.

3. Phase branch setup — see `phase-lifecycle` skill, part A. (Slug: $1, phase: N.)

4. Read docs/$1/feedback-log.md if it exists. If it contains any "Risks for future phases" or "Deferred issues" entries relevant to Phase N, surface them as a brief one-line heads-up before delegating tasks. This is informational only — do not block on it or ask for confirmation.

5. Delegate tasks — see `phase-lifecycle` skill, part B, for parallel `[parallel-with: ...]` groups. **If any task reports FAIL: stop immediately.** Report the root cause and the full task summary to the user, and wait for direction before continuing.

6. Compile the phase summary from each task-implementer's summary block:
   - Task → Approach → Test result → Deviations/risks
   Then commit the doc changes (including `phase-branches.md`): `git add docs/$1/ && git commit -m "feat($1): phase N complete"`.

7. Delegate to `phase-reviewer` to review Phase N changes, check testing compliance, and classify all issues as blocking or non-blocking.

8. Resolve ALL blocking and non-blocking issues without asking for confirmation — issue-resolution delegation, see `phase-lifecycle` skill, part C. **If any issue-resolver reports FAIL: stop immediately.** Report the root cause and the issue summary to the user, and wait for direction before continuing. If the user's direction is to skip that issue and proceed, it's a deferred issue (part C, point 4) — not dropped.

9. Delegate to `doc-updater` to apply all suggested doc edits and to append a dated entry to feedback-log.md covering the original findings, any deferred issues, risks for future phases, and all resolutions applied.

10. Commit the doc updates: `git add docs/$1/ && git commit -m "review($1): phase N fixes and doc updates"`.

11. Report a progress summary for phase N to the user:
    - Implementation: task results (Approach → Test result → Deviations)
    - Review: blocking/non-blocking issues resolved, risks for future phases (logged, not fixed), deferred issues
    - Doc changes applied

12. **Checkpoint:** ask the user to confirm before continuing to phase N+1 ("Phase N complete. Continue to phase N+1?"). Wait for their reply before proceeding. This is the one pause point in an otherwise hands-off run — it exists so a multi-phase run doesn't go fully out of sight.

Once all phases are complete, report the full run summary and remind the user to run `/finalize $1` before merging, and `/archive $1` after merging to main.
