# Specification — harness-streamlining

## Goal
The harness's structural claims (shared denylist, read-only tool whitelist,
doc-length limits, gitignore coverage, git-verified worktree steps) stop
being prose promises and become statically checkable facts; duplication
across agent files, config, and AGENTS.md is collapsed to single sources of
truth.

## In scope
- Two throwaway gate experiments in `.scratch/`: (A) shipped
  `.opencode/opencode.json` loads as a merged config layer for a third-party
  project; (B) agent-frontmatter permissions merge over top-level with agent
  rules winning. Either fails → hoist is skipped; denylist dedup falls back
  to doctor-only duplicate-checking.
- Denylist hoist: shared destructive-command list once in shipped config's
  top-level `permission.bash`; agent frontmatter keeps role deltas
  (reviewers: commit/add deny; lead: scoped merge/mv allows); README
  documents the ".opencode layer out-votes user root config" consequence.
- `scripts/doctor.sh` — permanent static test suite (harness-repo-only,
  never shipped, no CI in v1), 8 checks + invariant-marker presence +
  pure-git worktree simulation flow.
- AGENTS.md diet: ≤80 lines (target ~60), operational navigation only;
  smart-zone/denylist/autorun essays relocated into README and deduplicated.
- Sandbox/external_directory prose: bodies keep a 2-line imperative;
  why-essays move to README's existing sections (moved, never duplicated).
- phase-reviewer keeps a condensed inline "enforcement subset" of
  coding-standards; full skill stays the pull reference; sync human-owned
  (doctor only checks placeholder-absence).
- Prose pass over the 8 agent bodies only: prohibitions paired with
  positive targets; 3 no-op phrases deleted ("keep it tight" ×2,
  "Be concise" ×1); hard-boundary statements stay plain prohibitions;
  commands files excluded.
- Cross-reference sweep so prose like "see the denylist in
  task-implementer.md" doesn't point at post-hoist empty sections.
- End-of-slug docs follow-through: README + AGENTS.md updated to shipped
  reality.

## Out of scope
- Behavior changes — none; this slug is structure-preserving (any behavior
  change is a defect and belongs in a defects-style fix).
- CI integration of doctor.sh (explicitly v1-out); shipping doctor.sh to
  third-party users; prose pass over `commands/*.md` or skills (except
  phase-lifecycle invariant markers).
- Changing what any agent's role deltas protect (the denylist's *content*
  is slug 1's finalized shape; only its *location* moves).

## Functional requirements
1. FR1: After the hoist, every bash agent's resolved permission set equals
   its slug-1 pre-hoist set (role deltas + shared list = same effective
   rules), verified by doctor.sh check 1. [Phase 1: superseded by the FR8
   fallback — gate experiment B was reclassified FAIL and the hoist was not
   applied; under the taken fallback branch, FR1's equality expectation is
   replaced by doctor.sh's denylist-drift check over the per-agent copies.]
2. FR2: Agent frontmatter contains only role deltas after the hoist — no
   duplicated shared-list entries. [Phase 1: superseded by the FR8 fallback —
   the "role deltas only" expectation does not apply under the taken branch;
   per-agent shared-list duplication is the intended shipped state (see
   README).]
3. FR3: doctor.sh implements exactly these checks and exits non-zero on any
   failure: (1) role-table permissions via `opencode debug config` (fallback:
   parse frontmatter + config), (2) no `<fill in` under `.opencode/`,
   (3) no `git add -A`, (4) `.gitignore` entries present, (5) file-count
   claims in docs match reality (updated: 2 scripts now), (6) grill task
   whitelist ⊆ {explore, scout}, (7) AGENTS.md ≤ 80 lines, (8) shipped
   watcher entries present. Plus: positive-presence check that
   `<!-- invariant: … -->` markers exist in phase-lifecycle part B.
4. FR4: doctor.sh runs the pure-git worktree-flow simulation in `.scratch/`:
   cleaned on pass, kept on fail; simulation asserts slug 1's
   clean+landed-verification behavior.
5. FR5: AGENTS.md ≤ 80 lines of operational navigation; all relocated
   content present in README (moved, not duplicated — no essay appears in
   both files).
6. FR6: Agent bodies: sandbox rule reduced to a 2-line imperative; zero
   occurrences of the 3 no-op phrases; hard-boundary statements remain plain
   prohibitions; commands files untouched.
7. FR7: No cross-reference points to a denylist section that the hoist
   emptied; sweep verified by grep over "denylist"/"permission" references.
8. FR8: Gate-experiment results (PASS/FAIL each) and the resulting
   hoist/fallback decision are recorded in feedback-log.md at Phase 1
   review; under fallback, doctor.sh gains a denylist-drift check instead
   of the hoist-presence expectation in check 1.

## Non-functional requirements
- Context cost: agent bodies net-shorter after the prose pass; frontmatter
  is config (free) either way.
- Zero behavior drift: same effective permissions and procedures before/after
  the slug (except the intended condensation of prose).

## Acceptance criteria
- [ ] Gate experiments run in `.scratch/`, results recorded; hoist applied
      or documented fallback taken.
- [ ] `scripts/doctor.sh` exits 0 on the post-slug repo; each check
      demonstrated to fail on a deliberately-violated fixture copy;
      simulation cleans `.scratch/` on pass, keeps it on fail.
- [ ] Resolved permissions (debug config or fallback parse) match the role
      table; agent files' shared-list copies are consistent (drift-checked) —
      the duplication itself is the intended fallback shape, not a defect.
- [ ] AGENTS.md ≤ 80 lines; README contains the relocated essays; grep
      proves no essay duplicated across the two files.
- [ ] 3 no-op phrases gone (grep); commands files byte-identical; 8 agent
      bodies pass the prose-pass review in `/review-phase`.
- [ ] Cross-reference sweep clean; phase-reviewer enforcement subset present
      and no `<fill in` reintroduced.
- [ ] Dogfooding: `/review-phase` passes each phase; `/finalize` clean.

## Constraints / assumptions
- Starts only after `harness-defects` merges to main; assumes its shipped
  baseline (slim shipped config, patched denylists, no placeholder).
- Gate experiments are throwaway: nothing under `.scratch/` is ever
  committed; opencode runs during experiments must not require `~/.config`
  writes (author's global config untouched — the sandbox rule applies).
- If experiment (A) or (B) fails, the plan's Phase 1 switches to the
  fallback branch (FR8) — that is a planned branch, not a failure.
- Facts verified during grill (don't re-derive): config files merge, not
  replace (global → root → .opencode layer wins); agent frontmatter merges
  over global with agent rules taking precedence (docs-stated — this is
  exactly what experiment B re-verifies for the installed version);
  `opencode debug config` prints resolved config; agent YAML frontmatter is
  config, not prompt; explore/scout are the read-only built-ins.
