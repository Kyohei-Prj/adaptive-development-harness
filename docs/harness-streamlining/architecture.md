# Architecture — harness-streamlining

## Overview
Collapse duplication across agent prompts, permission config, and AGENTS.md,
replacing per-copy maintenance with single sources of truth plus a permanent
static test suite. Depends on `harness-defects` having merged: the commit
invariant, patched denylists, and shipped-config reduction are the *baseline*
this slug deduplicates against. The core structural move is hoisting the
shared destructive-command denylist once into the shipped config's top-level
`permission.bash`, leaving only role deltas in agent files — gated by two
throwaway config-merge experiments, because the hoist is only safe if
OpenCode's documented layering (config files merge; agent frontmatter
overrides top-level, agent rules winning) actually holds in the installed
version. `scripts/doctor.sh` turns every structural claim in this repo into
a greppable/git-runnable check, including a pure-git simulation of the
worktree flow.

## Components
| Component | Responsibility | Tech |
|---|---|---|
| `.opencode/opencode.json` (shipped) | Single home of the shared destructive-command denylist (top-level `permission.bash`) after a passing gate experiment; keeps `$schema` + `watcher.ignore` from slug 1 | JSON config |
| `.opencode/agents/*.md` (8 bodies + frontmatter) | Frontmatter keeps role deltas only (reviewers: commit/add deny; lead: scoped merge/mv allow); bodies get the prose pass | agent files |
| `scripts/doctor.sh` | Harness-repo-only static test suite: 8 checks + invariant-marker presence + pure-git worktree simulation; never shipped, no CI in v1 | bash |
| `.opencode/skills/phase-lifecycle/SKILL.md` | Gains `<!-- invariant: … -->` marker comments in part B so positive-presence checks survive future condensation | skill doc |
| `AGENTS.md` | Diet to ≤80 lines (target ~60): operational navigation only | doc |
| `README.md` | Absorbs relocated essays (smart-zone, denylist rationale, sandbox why) — moved, never duplicated; agents-table reflects post-hoist shape | doc |
| `.opencode/agents/phase-reviewer.md` | Condensed inline "enforcement subset" of coding-standards; full skill stays the pull reference; sync human-owned | agent prompt |
| `.scratch/` gate experiments | Throwaway probes for config-merge + permission-merge behavior; results decide hoist vs fallback | throwaway bash/opencode runs |

## Data flow
Planning time: none. Run time: OpenCode resolves config layers (global →
project root → `.opencode` layer wins) → agents receive top-level denylist +
their role delta. Verification time: `scripts/doctor.sh` → resolves
permissions (`opencode debug config`, fallback: parse frontmatter + config)
→ greps structural invariants → runs the worktree simulation in `.scratch/`
→ exit 0 with simulation cleaned up, or non-zero keeping `.scratch/` output
for diagnosis.

## Data model
N/A. The "schema" is the expected-permissions role table encoded in
doctor.sh.

## External dependencies
OpenCode CLI — specifically `opencode debug config` (existence in the
installed version is an open question carried from slug 1; doctor.sh has a
frontmatter-parsing fallback either way). git plumbing for the simulation.

## Key decisions & trade-offs
- Decision: experiment-gate the denylist hoist — Why: docs-claim config
  merge + agent-wins precedence, but a hoist built on a wrong assumption
  silently removes all destructive-command protection — Alternatives: hoist
  on doc authority (rejected: silent-failure mode), never hoist (rejected:
  three drifting deny-list copies already proven in slug 1).
- Decision: fallback path if either experiment fails — keep per-agent lists,
  doctor.sh checks for drift between the copies instead. The slimming of
  *prose* proceeds regardless.
- Decision: accepted consequence — the `.opencode` layer out-votes a user's
  project-root config on conflicting patterns; documented in README.
- Decision: doctor.sh never shipped, no CI in v1 — Why: it asserts claims
  about this repo only; CI adds maintenance surface with no consumer yet —
  Alternatives: ship as a template (rejected: third parties can't run
  harness-internal checks meaningfully), CI from day one (deferred).
- Decision: `<!-- invariant: … -->` markers for positive-presence checks —
  Why: absence-checks (`no git add -A`) can't catch a condensation pass
  accidentally deleting a *required* step — Alternatives: none viable in
  prose.
- Decision: AGENTS.md = navigation, README = essays; "moved, never
  duplicated" — Why: the duplication *is* the defect class being removed.

## Open questions
- Does `opencode debug config` exist in the installed version (fallback
  chosen during doctor.sh implementation if not)?
- Exact post-hoist minimal role deltas per agent — finalized by Task 1.3's
  resolved-config diff, not by prose argument.
- Whether the phase-reviewer enforcement subset drifts from
  coding-standards enough to need automation later (v1 answer: human-owned
  sync; revisit at dogfood time).
