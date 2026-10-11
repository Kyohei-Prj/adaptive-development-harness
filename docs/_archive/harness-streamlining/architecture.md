# Architecture — harness-streamlining

## Overview
Collapse duplication across agent prompts, permission config, and AGENTS.md,
replacing per-copy maintenance with single sources of truth plus a permanent
static test suite. Depends on `harness-defects` having merged: the commit
invariant, patched denylists, and shipped-config reduction are the *baseline*
this slug deduplicates against. The core structural move was to hoist the
shared destructive-command denylist once into the shipped config's top-level
`permission.bash`, leaving only role deltas in agent files — gated by two
throwaway config-merge experiments, because a hoist built on a wrong
assumption about OpenCode's documented layering silently removes all
destructive-command protection. The gate FAILED: Phase 1's effective-action
probe showed an agent `"*": allow` catch-all out-voting config-layer denies
at execution — silently disarming every shared deny while the deny stays
*present* in `opencode debug agent` output, exactly the silent-failure mode
the gating existed to catch. The FR8 fallback was taken: per-agent
denylists retained, with a denylist-drift check in `scripts/doctor.sh`
(Phase 3) instead (evidence: `gate-experiments.md`).
`scripts/doctor.sh` turns every structural claim in this repo into
a greppable/git-runnable check, including a pure-git simulation of the
worktree flow.

## Components
| Component | Responsibility | Tech |
|---|---|---|
| `.opencode/opencode.json` (shipped) | Does NOT host the shared denylist — the gate experiment failed and the FR8 fallback was taken; keeps only `$schema` + `watcher.ignore` from slug 1 | JSON config |
| `.opencode/agents/*.md` (8 bodies + frontmatter) | Frontmatter keeps role deltas only (reviewers: commit/add deny; lead: scoped merge/mv allow); bodies get the prose pass | agent files |
| `scripts/doctor.sh` | Harness-repo-only static test suite: 8 checks + invariant-marker presence + pure-git worktree simulation; never shipped, no CI in v1 | bash |
| `.opencode/skills/phase-lifecycle/SKILL.md` | Gains `<!-- invariant: … -->` marker comments in part B so positive-presence checks survive future condensation | skill doc |
| `AGENTS.md` | Diet to ≤80 lines (target ~60): operational navigation only | doc |
| `README.md` | Absorbs relocated essays (smart-zone, denylist rationale, sandbox why) — moved, never duplicated; agents-table reflects the post-FALLBACK shape (per-agent denylists kept deliberately duplicated) | doc |
| `.opencode/agents/phase-reviewer.md` | Condensed inline "enforcement subset" of coding-standards; full skill stays the pull reference; sync human-owned | agent prompt |
| `.scratch/` gate experiments | Throwaway probes for config-merge + permission-merge behavior; results decide hoist vs fallback | throwaway bash/opencode runs |

## Data flow
Planning time: none. Run time: OpenCode resolves config layers (global →
project root → `.opencode` layer wins) → agents receive top-level denylist +
their role delta. Verification time: `scripts/doctor.sh` → parses
frontmatter bash streams against an order-sensitive golden (`opencode
debug config` deliberately unused — presence in resolved output proves
nothing; see doctor.sh check 1 header) → greps structural invariants →
runs the worktree simulation in `.scratch/`
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
- RESOLVED (Phase 1) — does `opencode debug config` exist in the installed
  version (fallback chosen during doctor.sh implementation if not)? Yes:
  used throughout Experiments A/B (v1.18.34) and the effective-action probe
  (v1.18.35); see `gate-experiments.md`.
- MOOTED (Phase 1) — exact post-hoist minimal role deltas per agent, to be
  finalized by Task 1.3's resolved-config diff: Task 1.3 stopped under the
  FR8 fallback; the alternative hoist shape that would revive this is
  documented in gate-experiments.md's Decision section.
- Whether the phase-reviewer enforcement subset drifts from
  coding-standards enough to need automation later (v1 answer: human-owned
  sync; revisit at dogfood time).
