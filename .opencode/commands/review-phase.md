---
description: Review a completed phase, resolve blocking and non-blocking issues found, then update planning docs
agent: lead
---
Run the Feedback stage for Phase $1 of docs/$2/implementation-plan.md.

Follow the `phase-lifecycle` skill for the mechanical procedures below — this command's policy: ask before resolving anything, resolve only what I confirm.

Steps:
1. Delegate to `phase-reviewer`: review Phase $1 changes (it reads `docs/$2/phase-branches.md` for the correct diff baseline itself), check testing compliance, and classify all issues as blocking or non-blocking.

2. Present the full report to me — testing compliance, blocking issues, non-blocking findings, risks, and suggested doc edits.

3. If there are any blocking or non-blocking issues:
   a. Ask me to confirm which issues to resolve now vs defer.
   b. Issue-resolution delegation — see `phase-lifecycle` skill, part C.
   c. After each fix, report the issue-resolver's summary to me. If any fix reports FAIL, surface the root cause immediately and ask me how to proceed before moving on to the next issue.
   d. Anything I decline to resolve now is a **deferred issue** (part C, point 4) — not dropped.

4. Once all confirmed issues are resolved (or none exist), ask me whether to apply the doc updates.

5. If I confirm, delegate to `doc-updater` to update architecture.md, spec.md, and implementation-plan.md, and to append a dated entry to feedback-log.md that covers the original findings, any deferred issues, risks for future phases, and the resolutions applied.
6. After `doc-updater` completes, stage and commit all changes: `git add -A && git commit -m "review($2): phase $1 fixes and doc updates"`.
