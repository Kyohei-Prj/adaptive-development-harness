---
description: "Non-interactive variant of /review-phase, for use from scripts/autorun.sh via `opencode run` — resolves all confirmed issues automatically, no checkpoints, ends with an AUTORUN_STATUS trailer"
agent: lead
---
Review Phase $1 of `$2` and resolve everything that's resolvable, non-interactively.

This command is meant to be invoked non-interactively (`opencode run --agent lead "/review-phase-auto $1 $2"`), as one step of `scripts/autorun.sh`. There is no human present to ask which issues to resolve — resolve ALL blocking and non-blocking issues found. Never pause for confirmation.

Follow the `phase-lifecycle` skill for the mechanical procedures below (parts C, D).

Steps:
1. Delegate to `phase-reviewer` to review Phase $1's changes (it reads `docs/$2/phase-branches.md` for the correct diff baseline itself), check testing compliance, and classify all issues as blocking or non-blocking.
2. Resolve ALL blocking and non-blocking issues — issue-resolution delegation, see `phase-lifecycle` skill, part C.
3. Delegate to `doc-updater` to apply all suggested doc edits and append a dated entry to feedback-log.md covering: the original findings, any deferred issues (an issue skipped per the exception below, or otherwise, is deferred — not dropped), risks for future phases, and all resolutions applied.
4. If everything above succeeded: stage and commit all changes: `git add -A && git commit -m "review($2): phase $1 fixes and doc updates"`. Then produce the final report (see format below) with status `OK`.

## Stop conditions — do not attempt to work around any of these

- **Any `issue-resolver` reports FAIL.** Do not retry indefinitely, do not reinterpret the issue.
  - Exception: if the failure is isolated to one non-blocking issue and every blocking issue was resolved successfully, you may treat that single issue as a **deferred issue** (logged via `doc-updater` in step 3) and continue — a stalled non-blocking cosmetic fix shouldn't halt an otherwise-successful automated run. Any FAIL on a **blocking** issue always stops the whole run; never defer a blocking issue automatically.
- **Any destructive-command refusal surfaces** from `issue-resolver` (see its denylist) that blocks resolving a blocking issue as described.

On a stop condition that isn't the single-non-blocking-issue exception above: do NOT commit. Produce the final report with status `FAIL` (genuine failure) or `NEEDS_HUMAN` (a judgment call, e.g. an ambiguous issue description that needs human interpretation), with enough detail that a human reading only this output can act on it later without having watched the run.

## Final report format

Follow the `phase-lifecycle` skill, part D, for the `AUTORUN_STATUS:` trailer format. Structure the response as:

```
## Phase $1 Review Report — $2

<review summary: blocking/non-blocking issues resolved, any deferred issues, risks for future phases logged, doc changes applied>

AUTORUN_STATUS: OK
```

or, on a stop condition, replace the summary line with what was found, what was resolved before the stop, and the full detail of what stopped it, and use `AUTORUN_STATUS: FAIL: <reason>` or `AUTORUN_STATUS: NEEDS_HUMAN: <reason>` as appropriate.
