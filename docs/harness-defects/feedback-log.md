# Feedback Log — harness-defects

<!-- Append one entry per reviewed phase. Never delete prior entries. -->

## 2026-10-10 — Phase 1 review — The commit-authorship invariant, end to end

Reviewer verdict: **Needs fixes** — all four Phase 1 tasks passed their
literal acceptance criteria and the four in-scope agent/skill files are
internally coherent (1.1↔1.3 coupling verified; 1.4's smoke sim re-derived
clean), but the commit-authorship invariant stopped at lead.md: 8
`git add -A` commit steps in lead's own command files survived. All
findings (1 blocking + 2 non-blocking) were resolved during this review.

**Issues found:**
- [blocking] FR1 violation ("no agent procedure anywhere instructs or
  permits `git add -A`"): 8 `git add -A` commit sites in lead's own command
  files under `.opencode/commands/` (implement-phase.md,
  implement-phase-auto.md, review-phase.md, review-phase-auto.md,
  autorun.md ×2, finalize.md) survived Phase 1, with no Phase 2–5 task
  owning the fix.
- [non-blocking] phase-lifecycle SKILL.md part A said "Commit it along with
  the rest of the phase's changes" — pre-invariant framing, inconsistent
  with lead's docs-only phase-complete commit shape.
- [non-blocking] phase-lifecycle SKILL.md part B step 4: the post-merge
  worktree check `git status --porcelain` "run in that worktree" could pass
  vacuously from the main tree.
- Testing compliance: PASS on all four `[type: smoke]` tasks. 1.4's
  throwaway-sim evidence re-derived: `.scratch/wt-sim/` gone, nothing
  sim-related ever committed; the stray-untracked-file assertion is
  empirically corroborated by `docs/harness-defects/autorun.log` itself
  sitting untracked and uncommitted through the phase-complete commit.

**Resolutions applied:**
- `0fe836a` (blocking): all 8 `git add -A` sites in `.opencode/commands/`
  replaced with `git add docs/<slug>/` pathspecs; archive.md got the
  documented special case (bare `git commit` relying on `git mv`'s own
  staging, since `docs/<slug>/` no longer exists at that point); lead.md's
  "three of your commit points" enumeration generalized to four (archive
  commit added). Verified: `grep -rn "git add -A" .opencode/` → zero hits.
- `7f1f7d0` (non-blocking): phase-lifecycle SKILL.md part A now states the
  docs-only phase-complete commit shape.
- `ee51113` (non-blocking): phase-lifecycle SKILL.md part B step 4's
  post-merge check spelled out explicitly as
  `git -C .worktrees/<slug>-<task-id> status --porcelain`.

**Deferred issues (confirmed but not fixed this round):**
- None — all findings resolved in-review.

**Risks for future phases:**
- autorun.log sweep window (Phases 2–3): lead's docs-only commit shape
  `git add docs/<slug>/` stages everything under the slug dir, including
  the live un-ignored `docs/harness-defects/autorun.log` written by
  `scripts/autorun.sh`; the `.gitignore` entry is only Task 4.1. Until 4.1
  lands, lead must exclude `autorun.log` from its docs commits (stage
  specific files) — and consider pulling Task 4.1 forward if the automated
  run keeps logging to this path (it will).
- Phase 2 file collision on `implement-phase.md` /
  `implement-phase-auto.md`: Task 2.1's FAIL-semantics edits land on files
  carrying the review's remediated commit-step lines — mitigated by doing
  the remediation now, before Phase 2; noted so 2.1 rebases mentally on the
  new commit-step text.
- lead.md's stale worktree-mechanics pointer (→ command files instead of
  the phase-lifecycle skill) is now load-bearing, since part B is the sole
  source of the hardened flow — Task 5.1 must not miss it.
- AGENTS.md / README drift already owned by Tasks 5.2/5.3, restated so the
  sweep can't miss them: AGENTS.md "lead never edits files itself" (doubly
  false now: bookkeeping exception + it commits), AGENTS.md "commits all
  fixes and doc updates", README Troubleshooting still prescribes
  `git add -A` recovery.
- Bootstrap-commit observation: Phase 1's own commit `7a777da` bundles
  code+docs in one lead commit (its implementers ran under pre-invariant
  instructions, and lead.md was itself one of the edited files —
  unavoidable bootstrap). Phase 2's review must verify lead's
  phase-complete commit contains ONLY `docs/harness-defects/` — first real
  (non-simulated) exercise of the invariant.
- Commit-message template drift: phase commit `7a777da` used
  `feat: phase 1 harness-defects complete` instead of the template
  `feat(<slug>): phase <n> complete` — same bootstrap cause; future phases
  should match templates.

**Doc changes applied:**
- implementation-plan.md: added Task 1.5 (`[x]` `[type: smoke]`) recording
  the command-file commit-step remediation resolved in-review (`0fe836a`);
  Phase 1 Goal annotated — sweep closure completed by Task 1.5, added
  during Phase 1 review; Task 4.1 annotated as also closing the
  autorun.log-sweep window that is live through Phases 2–3.
- architecture.md: none.
- spec.md: none.

---

## 2026-10-10 — Phase 2 review — Interactive FAIL parity

Reviewer verdict: **PASS** — no blocking issues. Both `[type: smoke]` tasks
met their acceptance criteria; the FAIL sections of implement-phase.md and
implement-phase-auto.md are semantically identical except the sanctioned
stop→ask difference, and the deferral chain is present across all five files
with one implicit link (NB-1) tightened during this review. +11/−1 in one
command file — surgical.

**Issues found:**
- [non-blocking] NB-1: the deferral chain's receiver half was implicit —
  FR5 asserted, not wired. implement-phase.md's new carry-over paragraph
  says `/review-phase` logs skipped-after-FAIL tasks under "Deferred
  issues", but every receiver text (phase-lifecycle part C point 4,
  review-phase.md steps 3d/5, doc-updater) scoped deferral to review
  *issues*; the only carrier of the skip list was the human who witnessed
  the stop.
- [non-blocking] NB-2: the stop-condition list is now verbatim-duplicated
  across implement-phase.md / implement-phase-auto.md — tech debt against
  the skill's "command files state only what's unique to them" charter;
  zero divergence today.
- [non-blocking] NB-3: implement-phase.md's part-C-point-4 citation
  overstated what point 4 literally said (issue-only coverage) — a fresh
  reader checking the cite hits the mismatch.
- Testing compliance: PASS on both `[type: smoke]` tasks (text verifiably
  present in the committed files; `grep -rn "git add -A" .opencode/` → 0
  hits re-verified; the phase's implementation run ended
  `AUTORUN_STATUS: OK`).
- Phase 1 feedback-log risks verified: (a) commit-authorship invariant PASS
  — lead's phase-complete commit `834dc09` contains ONLY
  `docs/harness-defects/implementation-plan.md` + `phase-branches.md`
  (first real, non-simulated exercise; the pre-existing live `autorun.log`
  was correctly NOT swept — lead staged specific files per the Phase 1
  mitigation, so the invariant survived a realistic attempt to break it);
  (b) commit-message template PASS —
  `feat(harness-defects): phase 2 complete` matches the template, Phase 1
  drift gone; (c) Phase 1's `git add docs/<slug>/` remediation survived
  Task 2.1's edits — PASS.

**Resolutions applied:**
- `949ed47` (NB-1 + NB-3): phase-lifecycle SKILL.md part C point 4 extended
  with one clause making implementation tasks skipped after a FAIL
  explicitly deferred issues — making implement-phase.md's cite literally
  true (NB-3 resolved by fixing the cited text, not the citation);
  review-phase.md step 5's coverage list gained the landing-spot clause
  "any tasks that implement-phase recorded as skipped after a stop".
  Judgment: the clause is deliberately NOT mirrored into
  review-phase-auto.md step 3 — autorun.sh halts before a headless review
  ever runs after an implement stop, and implement-phase-auto.md has no
  skip-recording step to reference (Task 2.2 was interactive-scoped); the
  headless path inherits the broadened part C point 4.

**Deferred issues (confirmed but not fixed this round):**
- NB-2 (stop-condition twin duplication): resolution = routed, not fixed
  here — the hoist is explicitly `harness-streamlining`'s declared scope
  (its spec: "duplication across agent files, config, and AGENTS.md is
  collapsed to single sources of truth"), and harness-defects' own spec
  puts "dedup / agent-file slimming" out of scope. Logged here so it
  carries to that slug rather than being dropped; until then the two twins
  are byte-identical (verified this review) and Phase 5.3's sweep is the
  in-slug checkpoint that must keep them in sync.

**Risks for future phases:**
- R-1 (imminent, operational — carried from Phase 1, trigger now
  demonstrably fired): `docs/harness-defects/autorun.log` is actively
  written by scripts/autorun.sh and un-ignored until Task 4.1;
  `git add docs/<slug>/` executed literally WILL sweep the live log. Lead
  must keep staging specific files. Task 4.1's own pull-forward trigger
  ("reconsider sequencing if the automated run keeps logging to this path")
  is empirically met — decision due before Phase 3, not optional-by-default.
- R-2: lead.md's stale worktree-mechanics pointer got more load-bearing —
  Phase 2 added conflict/stop text to implement-phase.md, so the pointer
  now resolves to a policy-level duplicate rather than the skill's part B;
  Task 5.1 must retarget it.
- R-3: twin-drift watch for Phase 5.3 — the sweep must verify both FAIL
  sections for byte-parity (except the sanctioned ask/trailer difference
  and the deferred-tasks paragraph, interactive-only by design) AND the
  deferral chain's new part-C/review-phase wording from `949ed47`; if the
  twins' stop-condition lists are ever hoisted (see deferred NB-2), do both
  twins or neither.
- R-4: AGENTS.md / README deferral language is narrower than shipped
  (declines only, no skipped-after-FAIL tasks) — owned by Task 5.3's sweep
  alongside its existing carry-overs; also, if a future phase ever adds
  skip-recording to implement-phase-auto.md, review-phase-auto.md step 3's
  coverage list needs the mirror clause in the same change.

**Doc changes applied:**
- implementation-plan.md: added Task 2.3 (`[x]` `[type: smoke]`) recording
  the receiver-half wiring resolved in-review (`949ed47`), mirroring the
  Task 1.5 pattern; Phase 2 Goal annotated — receiver-half wiring added
  during Phase 2 review; Task 4.1 annotated — its pull-forward trigger was
  observed during the Phase 2 review (log active through the review
  commits), decision due before Phase 3 starts.
- architecture.md: none.
- spec.md: none.

---
