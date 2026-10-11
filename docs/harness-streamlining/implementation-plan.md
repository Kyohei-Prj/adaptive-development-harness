# Implementation Plan — harness-streamlining

Preconditions: `harness-defects` merged to main. Executed via the repo's own
`/implement-phase <n> harness-streamlining` → `/review-phase` cycle. All
phases sequential — no `[parallel-with]` tags (Phase 1's outcome gates the
plan's shape; later phases share README and phase-lifecycle). Task tags:
only `doctor.sh` work is `[type: tdd]` (script logic with real branching);
everything else is prose/config → `[type: smoke]`.

## Phase 1 — Config layering proven, denylist hoisted (or fallback taken)
**Goal:** Vertical slice of the enforcement-config layer delivering the
end-to-end behavior *a third-party project gets the destructive-command
guardrails from one place* — including the proof that the config layering
making that possible actually works, and the fully-planned fallback branch
if it doesn't. After this phase, `opencode debug config` (or the fallback
parse) shows the same effective permission sets as slug 1's per-file lists.
**Tasks:**
- [x] Task 1.1: Gate experiment A (throwaway, `.scratch/gate-a/`): minimal
      fake third-party project copying the shipped `.opencode/opencode.json`
      with a sentinel `watcher.ignore` entry; run `opencode debug config`
      there; PASS = sentinel present in resolved config. Record PASS/FAIL +
      evidence in the task report (Phase 1 review logs it in feedback-log).
      Clean up `.scratch/`. (acceptance: recorded verdict with the debug
      output excerpt; nothing under `.scratch/` committed) [type: smoke]
- [x] Task 1.2: Gate experiment B (throwaway, `.scratch/gate-b/`): top-level
      `permission.bash` deny of a harmless sentinel pattern + throwaway
      agent frontmatter allowing it; PASS = resolved config shows agent rule
      winning. Same recording/cleanup rules. (acceptance: recorded verdict
      + evidence) [type: smoke]
- [ ] Task 1.3: Hoist (only if A∧B PASS): shared destructive-command denylist
      written once into shipped config top-level `permission.bash`; strip
      shared entries from all 5 bash agents' frontmatter, keeping role
      deltas (reviewers: commit/add/push deny; lead: scoped merge/mv allows;
      implementer pair: nothing beyond shared list); verify every agent's
      resolved set equals its pre-hoist set (diff resolved-config snapshots
      before/after). (acceptance: before/after resolved-permission diff
      empty of semantic change; zero shared-list entries left in agent
      files) [type: smoke]
- [x] Task 1.4: README: document the hoist + consequence — the `.opencode`
      layer out-votes a user's project-root config on conflicting patterns;
      note where to override. Under fallback (A∨B FAIL): instead record the
      fallback decision (per-agent lists retained; doctor gains a
      drift-check) and skip 1.3. (acceptance: README matches the branch
      actually taken; fallback decision also captured for feedback-log via
      review) [type: smoke]

Blocking: 1.1/1.2 → 1.3 → 1.4. This phase gates Phase 3 (doctor's role
table must encode the post-hoist/fallback shape) and Phase 2 (README is
shared between 1.4 and the diet tasks; sequential to avoid collisions).

## Phase 2 — AGENTS.md diet, essays relocated to README
**Goal:** Vertical slice of the documentation layer: *AGENTS.md becomes
operational navigation (stage list, one-line rules, pointers), ≤80 lines,
with every relocated essay living exactly once in README.* Reviewable by
opening both files side by side. (Not yet statically checked — Phase 3's
doctor turns this into a permanent guarantee.)
**Tasks:**
- [x] Task 2.1: Relocate smart-zone, denylist-rationale (dual prefix+
      anymatch explanation, allow-by-default rationale), autorun.sh
      dumb-zone, and parallel-isolation essays from AGENTS.md into README's
      existing sections, deduplicating against what README already says.
      (acceptance: each essay appears in exactly one file — grep a
      distinctive phrase from each in both files hits exactly one) [type: smoke]
- [x] Task 2.2: Rewrite AGENTS.md to ≤80 lines (target ~60): stage list,
      one-line working rules, pointers only. (acceptance: `wc -l` ≤ 80; no
      paragraph-level explanation survives; all previously-covered
      operations still discoverable via pointer) [type: smoke]
- [x] Task 2.3: Sandbox/external_directory split prep: leave AGENTS.md's
      sandbox section as a one-line pointer (full treatment of agent-body
      2-line imperatives is Phase 4). (acceptance: no why-essay remains in
      AGENTS.md) [type: smoke]

Blocking: after Phase 1 (README already carries 1.4's hoist doc; avoids
README edit collisions).

## Phase 3 — doctor.sh: the permanent static test suite goes green
**Goal:** Vertical slice across the whole harness making every structural
claim executable: `scripts/doctor.sh` runs 8 static checks + invariant-
marker presence + the pure-git worktree simulation, and exits 0 on the
post-diet repo — a single command any future phase can consult.
**Tasks:**
- [ ] Task 3.1: doctor.sh skeleton + flow: check registry, per-check
      pass/fail output, non-zero exit on any failure, run from repo root or
      any cwd; `.scratch/doctor-sim/` kept on fail / cleaned on pass; header
      doc comment ("harness-repo-only; never shipped; no CI in v1").
      (acceptance: exit codes correct on an artificially-failing check;
      fixture cleanup behavior verified both ways) [type: tdd]
- [ ] Task 3.2: The 8 checks: (1) role-table permissions via
      `opencode debug config` with frontmatter+config-parse fallback (pick
      the fallback if slug 1's open question shows debug config absent);
      (2) no `<fill in` under `.opencode/`; (3) no `git add -A`;
      (4) `.gitignore` entries; (5) docs' file-count claims match reality
      (2 scripts now — update claims in the same task); (6) grill whitelist
      ⊆ {explore, scout}; (7) AGENTS.md ≤ 80; (8) shipped watcher entries.
      Each check verified against a deliberately-violated fixture copy in
      `.scratch/`. (acceptance: all 8 green on repo; each individually
      demonstrated red on its fixture) [type: tdd]
- [ ] Task 3.3: Positive-presence check + markers: add
      `<!-- invariant: … -->` comments to phase-lifecycle part B's
      commit-before-report and clean+landed-verification steps; doctor
      asserts marker presence. (acceptance: check green; deleting a marker
      locally flips it) [type: tdd]
- [ ] Task 3.4: Pure-git worktree simulation: scripted init repo in
      `.scratch/` exercising slug 1's part-B flow (dirty → refuse; commit+
      merge → remove; docs-only lead commit); wired into doctor.sh flow.
      (acceptance: simulation passes on correct flow; a fixture that drops
      the verification step makes it fail) [type: tdd]
- [ ] Task 3.5: README: doctor.sh usage section (what it checks, when to
      run it, harness-only status, why no CI in v1); copy-instructions list
      still excludes scripts/doctor.sh. (acceptance: README accurate;
      doctor.sh absent from the shipped-file copy list) [type: smoke]

Blocking: needs Phase 1 (permission shape) and Phase 2 (check 7 green at
landing). Under the slug-1-fallback branch, check 1 becomes a drift-check
between per-agent copies (FR8) — same task, adapted expectations.

## Phase 4 — Agent-body prose pass + cross-reference sweep
**Goal:** Vertical slice of the prompt layer: the 8 agent bodies read as
tightened-but-behavior-identical instructions — prohibitions paired with
positive targets, no filler, sandbox rule as a 2-line imperative, no dead
pointers — with doctor.sh green as the regression net.
**Tasks:**
- [ ] Task 4.1: Prose pass over the 8 agent bodies: pair prohibitions with
      positive targets ("never git add -A — commit explicit paths"); delete
      the 3 no-op phrases ("keep it tight" ×2, "Be concise" ×1); hard-
      boundary statements stay plain prohibitions; commands/*.md untouched.
      (acceptance: grep finds 0 no-op phrases; `git diff` touches only
      agents/*.md among prose files; reviewer confirms no rule lost) [type: smoke]
- [ ] Task 4.2: Sandbox/external_directory: each body reduced to a 2-line
      imperative; why-essay appended to README's existing sandbox section
      (moved, never duplicated). (acceptance: bodies contain no why-prose
      beyond 2 lines; essay in README only) [type: smoke]
- [ ] Task 4.3: phase-reviewer enforcement subset: condensed inline coding-
      standards checklist replacing any residual full-skill restatement;
      full skill stays the pull reference. (acceptance: subset present,
      placeholder still absent; no `<fill in` reintroduced) [type: smoke]
- [ ] Task 4.4: Cross-reference sweep: grep all "denylist", "permission",
      "see … .md" references; retarget anything pointing at post-hoist-
      emptied sections to the shipped config or the skill. (acceptance:
      every reference resolves to a section that exists post-slug) [type: smoke]
- [ ] Task 4.5: Re-run `scripts/doctor.sh`. (acceptance: exit 0) [type: smoke]

Blocking: after Phase 3 (regression net exists; hoist shape known).

## Phase 5 — Docs follow-through
**Goal:** Explicitly-allowed layer-only closing slice: README + AGENTS.md
describe the streamlined harness as shipped — agents table shows post-hoist
permission shape, file lists match reality (2 scripts), no stale
duplication reintroduced by Phases 1–4.
**Tasks:**
- [ ] Task 5.1: Docs follow-through sweep: update README agents-table +
      copy-instructions + any count claims to shipped reality; AGENTS.md
      stays ≤80 (doctor re-run). (acceptance: no doc statement contradicts
      shipped files; doctor exit 0) [type: smoke]
- [ ] Task 5.2: Spec acceptance-criteria re-verification end to end;
      `/finalize harness-streamlining` after this phase. (acceptance:
      checklist complete in the finalize report) [type: smoke]

Blocking: last phase of the slug.

## Dependencies between phases
- Phase 1 gates Phase 3 (doctor's role table = post-hoist or post-fallback
  shape) and its experiment verdict is the phase's key output.
- Phase 2 gates Phase 3 (check 7 must be green at Phase 3 landing).
- Phase 3 gates Phase 4 (doctor.sh is 4.5's regression net) and Phase 5.
- `harness-defects` must be merged before this slug starts; this slug's
  `/finalize` runs after Phase 5; merge to main is the user's call.
- No `[parallel-with]` tags: sequential dogfooding + shared README/
  phase-lifecycle files make isolation more cost than benefit.
