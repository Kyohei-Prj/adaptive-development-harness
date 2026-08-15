# Workflow: Grill → Plan → Implement → Feedback

This project uses a 4-stage AI-driven workflow on top of OpenCode.

## Stages
0. **Grill (optional but recommended for anything non-trivial)** — `/grill <idea>` (uses the `grill` agent). Pure alignment interview, one question at a time, no docs written. Ends with a short design-concept summary. Close this session, then start a fresh one for Planning — don't run Plan inside the same session, and don't skip straight to `/plan` for anything with real design ambiguity.
1. **Planning** — `/plan <idea or grill summary>` (uses the `planner` agent). Produces `docs/<slug>/architecture.md`, `spec.md`, `implementation-plan.md`, and an empty `feedback-log.md`. Phases in `implementation-plan.md` are structured as **vertical slices** (each one crosses every layer to deliver one thin, reviewable, end-to-end piece of behavior) — not horizontal layers like "all schema, then all API, then all UI". Commit the docs manually before starting Implementation.
2. **Implementation** — `/implement-phase <n> <slug>` (uses the `lead` agent).
   `lead` creates and switches to `feature/<slug>-phase-<n>`, checks `feedback-log.md` for any open risks relevant to this phase and surfaces them as a heads-up, MUST delegate each task to the `task-implementer` subagent via the Task tool — one task at a time (unless tagged [parallel-with]) — rather than editing files itself, then commits the completed phase.
3. **Feedback** — `/review-phase <n> <slug>` (uses the `lead` agent).
   `lead` delegates the review to `phase-reviewer`, presents findings to the user, delegates confirmed blocking and non-blocking issues to `issue-resolver` sequentially, and only on confirmation delegates doc updates to `doc-updater`, then commits all fixes and doc updates. "Risks for future phases" are never delegated for fixing — they are speculative, so they're only recorded in `feedback-log.md`. Merging the feature branch to main is the user's responsibility.

**Automated alternative:** `/autorun <slug>` (uses the `lead` agent) runs the full Implementation → Feedback cycle for all phases. Within a phase it does not pause for confirmation — blocking/non-blocking issues are resolved automatically (risks are logged, not fixed). It pauses once per phase at a checkpoint before starting the next phase, and stops immediately if any subagent reports FAIL.

## Context hygiene rule
Any agent doing actual file edits during Implementation or Feedback must be a subagent invoked via Task, not the primary session. The primary session
holds summaries, not diffs.

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
  runs (including `/autorun`) viable at all.

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
