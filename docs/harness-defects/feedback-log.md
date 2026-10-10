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
