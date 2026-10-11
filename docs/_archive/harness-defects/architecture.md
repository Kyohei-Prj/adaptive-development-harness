# Architecture — harness-defects

## Overview
Fix seven verified defects in the harness's git-safety, permission, and
control-flow mechanics. The central design move replaces discipline-by-prose
with structure: **every commit containing code is created by the agent that
wrote the code; `lead` commits only `docs/<slug>/`.** This one invariant
dissolves the worktree silent-work-loss bug, the `git add -A` sweep bug, and
the undefined interactive FAIL flow simultaneously. The product here is the
harness itself: prompt text, permission frontmatter, command/skill docs, and
shipped repo config. Slug 1 is deliberately defect fixes only — deduplication
and streamlining are deferred to `harness-streamlining` (slug 2).

## Components
| Component | Responsibility | Tech |
|---|---|---|
| `.opencode/agents/lead.md` | Commit scope shrinks to `git add docs/<slug>/`; explicit bookkeeping edit exception; phase-complete records checkbox flips; +plain `git push*` deny | agent prompt + YAML permission |
| `.opencode/agents/task-implementer.md`, `issue-resolver.md` | Commit own work with explicit file lists; +`branch -D` deny (prefix + anymatch) | agent prompt + YAML permission |
| `.opencode/skills/phase-lifecycle/SKILL.md` | Part B: commit on task branch before reporting done; git-verified (clean + landed) worktree removal, never `--force` | skill doc |
| `.opencode/commands/implement-phase.md` | Interactive FAIL semantics mirroring the `-auto` twin | command doc |
| `.opencode/agents/grill.md` | `task: {"*": deny, "explore": allow, "scout": allow}` + body + README row | YAML permission + prompt |
| `.opencode/agents/phase-reviewer.md` | Live `<fill in …>` placeholder deleted, defaults preserved | agent prompt |
| `.opencode/opencode.json` (shipped) | Reduced to `$schema` + `watcher.ignore`; personal config relocates to global config manually by the author | JSON config |
| `.gitignore` | Add `.worktrees/`, `.scratch/`, `**/autorun.log` (doublestar) | gitignore |
| `.opencode/commands/archive.md` | Note: `git mv` deliberately leaves `autorun.log` behind | command doc |
| `README.md`, `AGENTS.md` | Copy-instructions `.gitignore` line; Troubleshooting `git add -A` recovery rewritten to the invariant; docs follow-through | docs |

## Data flow (the invariant in one pass)
task-implementer writes code → commits on its branch (explicit paths, never
`-A`) → reports done → lead verifies `git status --porcelain` empty **and**
`git merge-base --is-ancestor <task-branch> <phase-branch>` → `git worktree
remove` → lead's phase-complete commit = `git add docs/<slug>/` only,
containing the phase-branches row + flipped checkboxes in
implementation-plan.md. Any task FAIL (interactive or -auto): stop
delegating, no commit, surface root cause, ask direction (interactive) or
stop (auto); skipped tasks become deferred issues carried into review's
feedback-log.

## Data model
N/A — config/prompt repo. Durable state lives in git branches and the
`docs/<slug>/` bookkeeping files (`implementation-plan.md` checkboxes,
`phase-branches.md`).

## External dependencies
OpenCode CLI (agent/command config resolution, Task tool), git plumbing
(`status --porcelain`, `merge-base --is-ancestor`, `check-ignore`,
`worktree remove`). No new dependencies introduced.

## Key decisions & trade-offs
- Decision: commit-authorship invariant (authors commit; lead docs-only) —
  Why: kills three defects at once and removes lead's need to know each
  task's file set — Alternatives considered: lead committing with
  task-reported file lists (rejected: trusts the summary — that *is* the
  original bug), `git add -A` with better timing (rejected: same sweep
  class).
- Decision: git-verified worktree teardown (`status --porcelain` +
  `merge-base --is-ancestor`), never `--force`; failure stops and reports —
  Why: structural guarantee instead of prompt discipline — Alternatives:
  always `--force` after merge (rejected: silently destroys uncommitted
  work).
- Decision: `**/autorun.log` doublestar in `.gitignore` — Why: log stays
  ignored after `/archive` moves `docs/` to `docs/_archive/` — Alternatives:
  `docs/*/autorun.log` (rejected: breaks on archive move).
- Decision: lead's widened edit exception is stated explicitly ("bookkeeping
  only: phase-branches rows + checkboxes, never content") — Why: the
  checkbox-flip duty widens lead's edit surface; without the explicit
  boundary it silently erodes lead's "never edits" rule.
- Decision: dogfood slug 1 through the repo's own `/plan → /implement-phase →
  /review-phase`, deliberately **no `[parallel-with]` tasks** (the workflow
  is editing its own definition while running it) — validation instead by a
  pure-git simulation of the worktree flow (Task 1.4).

## Open questions
- Whether the bookkeeping exception interacts with anything under
  `docs/<slug>/` that must *not* be committed (autorun.log — covered by the
  `.gitignore` entry; revisit if other runtime files appear).
- Whether `opencode debug config` exists in the installed OpenCode version
  (only exercised in slug 2; slug 1 verification parses frontmatter
  directly).
