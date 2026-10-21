---
description: Review a completed phase, resolve blocking and non-blocking issues found, then update planning docs
agent: lead
---
Run the Feedback stage for Phase $1 of docs/$2/implementation-plan.md.

Follow the `phase-lifecycle` skill for the mechanical procedures below — this command's policy: ask before resolving anything, resolve only what I confirm.

Steps:
0. Mode gate — read Phase $1's `[mode: …]` tag from its `## Phase $1 — …` heading area (on the heading line or immediately under it) in `docs/$2/implementation-plan.md` before anything else; tag semantics: the `planning-docs` skill, "Phase mode tags". `[mode: sdd]`, `[mode: autorun]`, or an absent tag (= `[mode: sdd]`, backward compatible — review exactly as today) → continue with the steps below unchanged. `[mode: interactive]` → **refuse the review**: print "Phase $1 of $2 is `[mode: interactive]` — a human pair-loop phase, and the lead refuses to review it. Such a phase has no phase branch and therefore no `phase-branches.md` diff baseline, which is by design and not a setup problem for the lead to fix: its review gate was you, the human, at each step of the `/interactive` loop, and `docs/$2/decisions.md` is its durable record." and stop — do not delegate to `phase-reviewer`, do not resolve, do not commit. Refusing mutates no git state: the gate sits before step 1, so nothing has been delegated and there is nothing to undo.
1. Delegate to `phase-reviewer`: review Phase $1 changes (it reads `docs/$2/phase-branches.md` for the correct diff baseline itself), check testing compliance, and classify all issues as blocking or non-blocking.
   Ensure its report carries the **Acceptance scenario compliance** section — per-scenario green evidence or an explicit uncovered flag, plus the `acceptance.md` diff lock (an unlogged scenario change is blocking; "n/a — no acceptance.md for this slug" when the file is absent) — and pass it any non-`n/a` `Acceptance concerns:` lines from this phase's task summaries **if you have them**; you usually won't, since the reviewer runs in a fresh session, which is why those lines also live in the task commit bodies for it to read itself.

2. Present the full report to me — testing compliance, acceptance scenario compliance, blocking issues, non-blocking findings, risks, and suggested doc edits.

3. If there are any blocking or non-blocking issues:
   a. Ask me to confirm which issues to resolve now vs defer.
   b. Issue-resolution delegation — see `phase-lifecycle` skill, part C.
   c. After each fix, report the issue-resolver's summary to me. If any fix reports FAIL, surface the root cause immediately and ask me how to proceed before moving on to the next issue.
   d. Anything I decline to resolve now is a **deferred issue** (part C, point 4) — not dropped.

4. Once all confirmed issues are resolved (or none exist), ask me whether to apply the doc updates.

5. If I confirm, delegate to `doc-updater` to update architecture.md, spec.md, and implementation-plan.md, and to append a dated entry to feedback-log.md that covers the original findings, any tasks that implement-phase recorded as skipped after a stop, any deferred issues, risks for future phases, and the resolutions applied.
6. After `doc-updater` completes, stage and commit the doc changes: `git add docs/$2/ && git commit -m "review($2): phase $1 fixes and doc updates"`.
