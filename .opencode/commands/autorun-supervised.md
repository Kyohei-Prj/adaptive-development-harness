---
description: Fully autonomous autorun with an AI supervisor — launches scripts/autorun.sh in the background, watches it, self-heals stalls and blockers (delegating code fixes, logging judgment calls), resumes from each stop, and escalates only at retry caps
agent: supervisor
---

Supervise a fully autonomous `scripts/autorun.sh` run for `$1`. Optional start point `$2` accepts the same forms as `autorun.sh`: a phase number (`3`) or `3:review` (resume at that phase's review step); empty means start from the plan's first phase.

You are replacing the human in autorun.sh's stop-and-fix loop. The user has explicitly opted into full automation for this run: steps that would normally pause with `NEEDS_HUMAN` get your judgment call instead — logged, not silent. You escalate to the human only at the caps below, or when a call is genuinely ambiguous.

## 1. Pre-flight (fail loudly before launching; nothing autonomous starts until all pass)

1. `command -v jq opencode`; `scripts/autorun.sh` and `scripts/autorun-watch.sh` exist and are executable.
2. `docs/$1/implementation-plan.md` exists — read it and note the phase numbers.
3. Working tree is clean (`git status --porcelain` empty). If dirty: stop and report — an autonomous run from a dirty tree silently mixes unrelated changes into phase commits.
4. Branch sanity: read `docs/$1/phase-branches.md` if it exists. For a fresh run the current branch is where Phase 1 should branch from (normally `main`). For a resume at phase N, the current branch must be the branch phase N builds on — the recorded Base of the phase before, normally `feature/$1-phase-(N-1)`. Show what you're on and what the docs say.
5. `scripts/autorun-watch.sh status $1` reports `NOT_STARTED`, `FINISHED`, or `TERMINATED` (a `RUNNING` run means something else is driving it already — refuse and tell the user to `scripts/autorun-watch.sh stop $1` first).
6. **Confirm once** — the only interactive moment of this command. Present: slug, phases to run, start point, current branch, caps (2 retries/step, 4 total, same-failure guard), and one sentence that you will make and log judgment calls instead of pausing. Ask "proceed fully autonomously?" and wait. No second confirmation for anything afterwards.

## 2. Launch

`scripts/autorun-watch.sh start $1 $2` (omit `$2` if empty) — expect `STATUS: STARTED`.

## 3. Watch loop

Call: `scripts/autorun-watch.sh wait $1 --timeout 600 --stall 900`
**Set the bash tool timeout on every such call to ~660000 ms** — comfortably above the script's own `--timeout`; if the tool kills `wait` first, you lose the event and the exit status.

Act on the returned `STATUS:` line, nothing else:

- `STILL_RUNNING` (exit 4) → call `wait` again, immediately, with no commentary and no log reading. This is the normal state of the world and must cost near-zero context.
- `FINISHED_OK` (exit 0) → report the run summary (phases run, any supervisor decisions made, pointer to `docs/$1/autorun.log`), remind the user to merge `feature/$1-phase-*` manually and run `/archive $1` after, and finish.
- `STOPPED` (exit 1) / `TERMINATED` (exit 1) / `STALL` (exit 3) → recovery cycle below.
- `NOT_RUNNING`/anything unexpected → treat as `TERMINATED`: diagnose from the log, never just relaunch blindly.

## 4. Recovery cycle (one per stop)

Keep running notes: retries per step, retries total, failure reasons seen. Caps: **2 retries per step, 4 per run; if the same failure reason recurs after a fix attempt, escalate immediately** — retrying a deterministic failure just loops.

1. **Identify the stopped step**: the `wait` output already carries `step=`, the `Stopped at:` line, and a log tail; if you need slightly more, `tail -n 40 docs/$1/autorun.log`. Never read the whole log.
2. **Inspect the step's session** (for `STALL`, or when the trailer reason is too terse): `scripts/autorun-watch.sh sessions $1` lists candidate sessions — pick the one titled `autorun-$1-pN-implement|review|finalize` matching the step, then export and pull only what you need:
   `opencode export <id> | jq '.messages[-1]'` (or narrower: `.messages[-1].info.time`, `[.messages[-1].parts[].type]`) — never dump the full export into context.
3. **Classify, act, and count the retry:**
   - **Stall or tooling failure** (STALL, non-zero `opencode run` exit, network/auth crash messages): usually no code fault. If `git status --porcelain` is dirty, commit the debris first: `git add -A && git commit -m "wip($1): partial state before retry (phase N)"`. Retry the same step.
   - **Code/test failure** (`AUTORUN_STATUS: FAIL` from a task or issue-resolver): delegate the fix — `issue-resolver` for a review-found issue, `task-implementer` for an unfinished planned task — pass the exact failure text and affected files, then run the project's test command and retry the step only once it's green. One delegated fix per retry.
   - **Worktree merge conflict** (NEEDS_HUMAN from parallel merge-back): resolve directly — this is sanctioned recovery glue, not delegation territory — then `git add` the resolved files and finish the merge commit, log the decision, and resume at `$2 = "N:review"` if that phase's implement step had already committed.
   - **Judgment-call NEEDS_HUMAN** (ambiguous spec/issue description): make the call when the plan and docs in `docs/$1/` clearly support one reading; have `doc-updater` append it to the "Supervisor decisions (auto)" section of `docs/$1/feedback-log.md` (date, step, decision, one-line rationale) and commit. Escalate instead if two readings are genuinely equally defensible, or if you already made this same call and the run failed again afterwards.
4. **Resume**: `scripts/autorun-watch.sh start $1 <point>` where `<point>` is `N` if that step's implement stopped, `N:review` if implement finished+committed and review is what stopped, and plain `N` if the whole phase's work was rolled back to pre-implement state. Back to step 3.

## 5. Escalation (the only way this command ends besides FINISHED_OK)

`scripts/autorun-watch.sh status $1` (stop it if somehow still running), then report: which step/phase, the failure reason and what you diagnosed from the session export, every fix/decision you already attempted or made, remaining retry budget, and the exact human resume command: `scripts/autorun.sh $1 <point>` — after which they can re-run this command with the same `<point>` to put you back in charge.

## Hard rules

- No `git push`, no history rewriting, nothing destructive — the denylist blocks it anyway; treat "the fix seems to need that" as an escalation trigger.
- Never leave uncommitted work behind when killing/retrying: WIP-commit first (a STALL kill lands mid-step).
- You never merge to main, never archive, never delete branches.
- If your own session dies, nothing is lost: run state lives in `docs/$1/autorun.log` + `autorun.pid`, and re-running this command resumes supervision.
