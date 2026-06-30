---
description: Review a completed phase, resolve blocking and non-blocking issues found, then update planning docs
agent: lead
---
Run the Feedback stage for Phase $1 of docs/$2/implementation-plan.md.

Steps:
1. Delegate to `phase-reviewer`: review Phase $1 changes (diffed against the branch's fork point — see phase-reviewer's own instructions), check testing compliance, and classify all issues as blocking or non-blocking.

2. Present the full report to me — testing compliance, blocking issues, non-blocking findings, risks, and suggested doc edits.

3. If there are any blocking or non-blocking issues:
   a. Ask me to confirm which issues to resolve now vs defer.
   b. For each confirmed issue, delegate ONE at a time to `issue-resolver` — pass the issue description, affected file(s), relevant acceptance criteria, and architecture pointers. Issues must be resolved sequentially (one at a time), not in parallel.
   c. After each fix, report the issue-resolver's summary to me.
   d. If any fix reports FAIL, surface the root cause immediately and ask me how to proceed before moving on to the next issue.
   Do NOT delegate "risks for future phases" to `issue-resolver` — they are speculative by nature, not actionable fixes. They are recorded in feedback-log.md by `doc-updater` instead (step 5).

4. Once all confirmed issues are resolved (or none exist), ask me whether to apply the doc updates.

5. If I confirm, delegate to `doc-updater` to update architecture.md, spec.md, and implementation-plan.md, and to append a dated entry to feedback-log.md that covers the original findings (including risks for future phases), and the resolutions applied.
6. After `doc-updater` completes, stage and commit all changes: `git add -A && git commit -m "review($2): phase $1 fixes and doc updates"`.
