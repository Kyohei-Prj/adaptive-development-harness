# Workflow: Grill → Plan → Implement → Feedback

This project uses a 4-stage AI-driven workflow on top of OpenCode.

## Stages
0. **Grill (optional but recommended for anything non-trivial)** — `/grill <idea>` (uses the `grill` agent). Pure alignment interview, one question at a time, no docs written. Ends with a short design-concept summary. Close this session, then start a fresh one for Planning — don't run Plan inside the same session, and don't skip straight to `/plan` for anything with real design ambiguity.
1. **Planning** — `/plan <idea or grill summary>` (uses the `planner` agent). Produces `docs/<slug>/architecture.md`, `spec.md`, `implementation-plan.md`, and an empty `feedback-log.md`. Phases in `implementation-plan.md` are structured as **vertical slices** (each one crosses every layer to deliver one thin, reviewable, end-to-end piece of behavior) — not horizontal layers like "all schema, then all API, then all UI". Commit the docs manually before starting Implementation.
2. **Implementation** — `/implement-phase <n> <slug>` (uses the `lead` agent).
   `lead` captures the current branch as this phase's base, creates and switches to `feature/<slug>-phase-<n>`, and records the base in `docs/<slug>/phase-branches.md` (never inferred later — this is what makes review's diff baseline reliable). It checks `feedback-log.md` for any open risks or deferred issues relevant to this phase and surfaces them as a heads-up, then MUST delegate each task to the `task-implementer` subagent via the Task tool. Tasks tagged `[parallel-with: ...]` run in isolated git worktrees under `.worktrees/` (one branch per task, merged back sequentially, never in parallel) rather than sharing the main working tree — everything else runs sequentially. `lead` never edits files itself; it commits the completed phase once all tasks report done.
3. **Feedback** — `/review-phase <n> <slug>` (uses the `lead` agent).
   `lead` delegates the review to `phase-reviewer` (which reads `phase-branches.md` for the correct diff baseline rather than guessing), presents findings to the user, delegates confirmed blocking and non-blocking issues to `issue-resolver` sequentially, and only on confirmation delegates doc updates to `doc-updater`, then commits all fixes and doc updates. "Risks for future phases" are speculative and are only ever logged. Issues the user declines to resolve now are **deferred, not dropped** — they're logged in `feedback-log.md` and resurface as a heads-up in a later phase the same way risks do. Merging the feature branch to main is the user's responsibility.

**Automated alternative:** `/autorun <slug>` (uses the `lead` agent) runs the full Implementation → Feedback cycle for all phases. Within a phase it does not pause for confirmation — blocking/non-blocking issues are resolved automatically (risks are logged, not fixed; anything skipped after a FAIL is logged as deferred, not dropped). It pauses once per phase at a checkpoint before starting the next phase, and stops immediately if any subagent reports FAIL or a parallel-task merge conflict occurs.

**Fully hands-off alternative:** `scripts/autorun.sh <slug>` — an external shell script (not an in-chat command) that drives `/implement-phase-auto`, `/review-phase-auto`, and `/finalize` via separate `opencode run` invocations, one process per phase. No checkpoints, no session ever accumulates across phases, output logged to `docs/<slug>/autorun.log`. Prefer this over `/autorun` for long plans — see the "Smart zone / dumb zone" section below for why.

**Before merging to main:** run `/finalize <slug>` — re-checks the whole feature branch as one unit (not phase-by-phase) to catch integration issues no single phase review would see.

**After merging to main:** run `/archive <slug>` to move `docs/<slug>/` to `docs/_archive/<slug>/`, so stale planning docs don't mislead a future `/grill` or `/plan` session for unrelated work.

**Periodically (not tied to any single slug):** run `/architecture-review [path]` — a whole-codebase scan for shallow-module sprawl and drift that accumulates gradually across many individually-fine phases. Per-phase review can't catch this; it's a separate, standalone pass.

## Context hygiene rule
Any agent doing actual file edits during Implementation or Feedback must be a subagent invoked via Task, not the primary session. The primary session
holds summaries, not diffs.

## Parallel task isolation
Tasks tagged `[parallel-with: ...]` in `implementation-plan.md` do NOT share
the main working tree. `lead` gives each one its own git worktree under
`.worktrees/<slug>-<task-id>` on its own branch, delegates to a separate
`task-implementer` instance pointed at that directory, and merges each
branch back into the phase branch sequentially once all tasks in the group
finish — never in parallel, and never automatically past a merge conflict
(that always stops and waits for the user). Add `.worktrees/` to your
project's `.gitignore` if it isn't covered already; it's already excluded
from `opencode.json`'s file watcher.

## Destructive-command guardrails
`lead`, `phase-reviewer`, `architecture-reviewer`, `task-implementer`, and
`issue-resolver` all use the same permission shape: `"*": allow` for bash,
with a denylist blocking the genuinely destructive commands outright
regardless of how a task is phrased — force-push, `rm -rf`/`rm -fr`,
`git reset --hard`, `git checkout -- .` / `git checkout --force`,
`git clean -f`, and forced branch deletion (`git branch -D`).
`phase-reviewer` and `architecture-reviewer` also deny `git commit`/
`git add`/`git push` outright, since they're read-only by design (`edit:
deny`) and the denylist closes the same door at the bash layer, which is a
separate channel from the edit tool. `lead` additionally restricts `git
merge` and `git mv` to the narrow patterns its own procedures actually use
(`git merge task/*`, `git mv docs/*/... docs/_archive/*/...`), denying the
unscoped versions.

If a task or issue fix seems to genuinely need a denied command, the agent
is instructed to stop and report rather than find a workaround — that
decision stays with you.

**Why allow-by-default instead of a narrow allowlist with `ask` as the
fallback:** an allowlist only covers the commands someone thought to list
in advance, and `ask` requires a human to answer — which works fine
interactively, but silently stalls forever when an agent is invoked
headlessly (`opencode run`, as `scripts/autorun.sh` does). Every agent that
might run in that headless path uses allow-by-default-with-denylist, not
allowlist-with-ask-fallback, for exactly this reason. `grill` is the one
deliberate exception (`webfetch: ask`) — it's interactive by design and
never invoked headlessly, so `ask` is correct there.

## Smart zone / dumb zone
LLM reasoning degrades well before the advertised context limit — treat
~100K tokens as a practical ceiling for any single session, not the vendor's
max. Watch your context usage (a token counter in the status line, or
`opencode`'s own usage indicator) and start a fresh session rather than let
a session run long:

- Close the `grill` session before starting `/plan`. Close the planning
  session before starting `/implement-phase`. Each subagent invocation via
  Task already gets its own fresh context by construction — don't undermine
  that by keeping one giant primary session open across an entire feature.
- Prefer starting a new session over relying on auto-compaction/summarization
  when a session gets long. A fresh session reading the committed docs is a
  deterministic, repeatable starting point; a compacted summary is not, and
  can quietly drop details that matter later. If `compaction.auto` is
  enabled in `opencode.json`, treat it as a safety net for sessions that ran
  longer than intended, not as a substitute for closing sessions between
  stages.
- This is also why `lead` is locked to delegating rather than editing files
  itself: keeping the orchestrating session small is what makes multi-phase
  runs viable at all — **with one exception.** The in-chat `/autorun`
  command still runs every phase inside one continuous `lead` session (a
  single checkpoint pause between phases, no restart), so on a long plan its
  own session can drift toward the smart-zone ceiling even though it never
  holds diffs. For a plan with many phases, prefer `scripts/autorun.sh`
  instead — it drives `/implement-phase-auto`, `/review-phase-auto`, and
  `/finalize` via separate `opencode run` calls, one process per phase, so
  every phase's orchestrating session is genuinely fresh rather than
  accumulated. `/autorun` remains a reasonable choice for short plans where
  staying in the loop matters more than long-run context hygiene.

## Docs
All planning docs for a unit of work live under `docs/<slug>/`. See the `planning-docs` skill for templates and task type tag rules.

**After all phases for a slug are merged to main**, consider moving
`docs/<slug>/` to `docs/_archive/<slug>/` (or deleting it) rather than
leaving it live in the tree indefinitely. Planning docs drift from reality
as code evolves after shipping; a future `/grill` or `/plan` session for
unrelated work that stumbles on stale docs and treats them as current can
get quietly misled by them. Closed GitHub/issue-tracker items with clear
"done" status are a safer long-term reference than a live-looking markdown
file. This is a judgment call, not an automated step — no agent in this
workflow archives docs on its own.

# Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Tools

**Use utility tools to facilitate development**

- Use `context7` MCP tool to refer to official documents for various framework/package.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
