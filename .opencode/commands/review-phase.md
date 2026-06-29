---
description: Review a completed phase, resolve all issues and risks found, then update planning docs
agent: lead
---
Run the Feedback stage for Phase $1 of docs/$2/implementation-plan.md.

Steps:
1. Delegate to `phase-reviewer`: review Phase $1 changes (via git diff/log), check testing compliance, and classify all issues as blocking or non-blocking.

2. Present the full report to me — testing compliance, blocking issues, non-blocking findings, risks, and suggested doc edits.

3. If there are any issues or risks (blocking, non-blocking, or future-phase risks):
   a. Ask me to confirm which items to resolve now vs defer.
   b. For each confirmed item, delegate ONE at a time to `issue-resolver` — pass the issue or risk description, affected file(s), relevant acceptance criteria, and architecture pointers. Items must be resolved sequentially (one at a time), not in parallel.
   c. After each fix, report the issue-resolver's summary to me.
   d. If any fix reports FAIL, surface the root cause immediately and ask me how to proceed before moving on to the next item.

4. Once all confirmed items are resolved (or none exist), ask me whether to apply the doc updates.

5. If I confirm, delegate to `doc-updater` to update architecture.md, spec.md, and implementation-plan.md, and to append a dated entry to feedback-log.md that covers both the original findings and the resolutions applied.
6. After `doc-updater` completes, stage and commit all changes: `git add -A && git commit -m "review($2): phase $1 fixes and doc updates"`.
