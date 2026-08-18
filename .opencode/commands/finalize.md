---
description: Run one last full check across ALL of a slug's phases together before merging to main — catches integration issues no single phase review would see. Non-interactive by design so it also works headlessly at the end of scripts/autorun.sh.
agent: lead
---
Run a finalize check for `$1` before it gets merged to main.

Every phase so far was reviewed against its own fork point in isolation.
This command re-checks the whole feature branch as one unit — phase 1's
change interacting badly with phase 4's is exactly the kind of thing that
slips through per-phase review.

This command never pauses for confirmation — it may be invoked interactively or headlessly (`opencode run --agent lead "/finalize $1"` from `scripts/autorun.sh`), and there's no reliable way to tell which from inside the command, so it always behaves as if no one is available to ask.

Follow the `phase-lifecycle` skill for the mechanical procedures below (parts C, D).

Steps:
1. Read `docs/$1/phase-branches.md` to find Phase 1's Base (almost always `main`, but read it — don't assume).
2. Delegate to `phase-reviewer` in **finalize mode**: diff from Phase 1's Base to the current HEAD (the full accumulated range across every phase), not a single phase's fork point. Tell it explicitly this is a finalize run covering the whole slug.
3. Resolve ALL blocking issues automatically — do not ask which to resolve. Issue-resolution delegation, see `phase-lifecycle` skill, part C. Non-blocking findings and risks for future phases are not auto-fixed here; they're logged in step 4 only, same as a normal review.
   **If any issue-resolver reports FAIL: stop. Do not attempt further fixes.** Treat it as a deferred issue (logged in step 4) only if it's a non-blocking issue that somehow reached this step; a FAIL on an actual blocking issue means the branch is not merge-ready — report it plainly rather than declaring success.
4. Delegate to `doc-updater` to append a final feedback-log.md entry noting this was a finalize check across all phases: findings, resolutions applied, any deferred issues, and non-blocking findings/risks (logged, not fixed).
5. If everything above succeeded and there were actual changes to commit: `git add -A && git commit -m "finalize($1): pre-merge check"`. If the finalize check found nothing to fix, skip the commit.
6. Produce the final report (format below). If step 3 hit a FAIL on a blocking issue, the branch is NOT ready to merge — say so explicitly rather than defaulting to a generic "ready" message.

## Final report format

Follow the `phase-lifecycle` skill, part D, for the `AUTORUN_STATUS:` trailer format. Structure the response as:

```
## Finalize Report — $1

<summary: testing compliance, blocking issues found and resolved (or not), non-blocking findings/risks logged, doc changes applied, and whether the branch is ready to merge>

AUTORUN_STATUS: OK
```

or, if a blocking issue could not be resolved, replace the summary with what was found, what was resolved, and the full detail of what's still blocking, and use `AUTORUN_STATUS: FAIL: <reason>`.

If status is `OK`: merging to main remains my responsibility, and I should be reminded to run `/archive $1` after the merge.
