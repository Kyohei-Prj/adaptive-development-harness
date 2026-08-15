---
description: Run one last full check across ALL of a slug's phases together before merging to main — catches integration issues no single phase review would see
agent: lead
---
Run a finalize check for `$1` before it gets merged to main.

Every phase so far was reviewed against its own fork point in isolation.
This command re-checks the whole feature branch as one unit — phase 1's
change interacting badly with phase 4's is exactly the kind of thing that
slips through per-phase review.

Steps:
1. Read `docs/$1/phase-branches.md` to find Phase 1's Base (almost always `main`, but read it — don't assume).
2. Delegate to `phase-reviewer` in **finalize mode**: diff from Phase 1's Base to the current HEAD (the full accumulated range across every phase), not a single phase's fork point. Tell it explicitly this is a finalize run covering the whole slug.
3. Present the full report to me — testing compliance, blocking issues, non-blocking findings, and any architecture concerns, same categories as a normal phase review.
4. If there are blocking issues: ask which to resolve now, then delegate to `issue-resolver` one at a time (sequentially), same as `/review-phase`. Any issue I decline is a deferred issue — don't drop it.
5. Once blocking issues are resolved (or none exist), delegate to `doc-updater` to append a final feedback-log.md entry noting this was a finalize check across all phases, covering any deferred issues.
6. Commit: `git add -A && git commit -m "finalize($1): pre-merge check"` — but only if there were actual changes to commit; skip the commit if the finalize check found nothing to fix.
7. Tell me the branch is ready to merge to main (merging remains my responsibility), and remind me to run `/archive $1` after the merge.
