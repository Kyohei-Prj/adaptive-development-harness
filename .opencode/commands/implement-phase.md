---
description: Implement a phase by delegating each task to the task-implementer subagent
agent: lead
---
Implement Phase $1 of docs/$2/implementation-plan.md.

Steps:
0. Create and switch to a new branch: `git checkout -b feature/$2-phase-$1`.
1. Read docs/$2/implementation-plan.md and find Phase $1's task list.
2. For EACH task, delegate it via the Task tool to `task-implementer`.
   Pass:
   - Task description and acceptance criteria
   - The `[type: tdd]` or `[type: smoke]` tag (copy it verbatim from the plan)
   - Relevant file paths and architecture section references
   Tasks marked `[parallel-with: X]` may be delegated simultaneously; all others run sequentially.
3. Do not edit files yourself — delegate and track.
   Use `todowrite` to track task status if useful.
4. When all tasks are done, compile a phase summary from each task-implementer's summary block:
   - Task → Approach → Test result → Deviations/risks
   Flag any FAIL or deviation before declaring the phase ready for review.
5. Stage and commit all changes: `git add -A && git commit -m "feat($2): phase $1 complete"`.
