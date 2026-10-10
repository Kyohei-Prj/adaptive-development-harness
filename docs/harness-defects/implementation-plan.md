# Implementation Plan — harness-defects

Dogfooding note: this slug is executed by the repo's own
`/implement-phase <n> harness-defects` → `/review-phase <n> harness-defects`.
**No `[parallel-with]` tags anywhere** (deliberate: the workflow is editing
its own definition; see spec Constraints). All tasks are prose/config
edits → `[type: smoke]`; the one scripted verification (1.4) is a smoke
check too. Phases run strictly in numeric order.

## Phase 1 — The commit-authorship invariant, end to end
**Goal:** Vertical slice delivering one behavior across every artifact that
composes it: *code commits are created by the agent that wrote the code;
lead commits only `docs/<slug>/`; worktree removal is git-verified.* After
this phase, reading + exercising the workflow shows no sweepable surface and
no silently-lost worktree work (sweep closure completed by Task 1.5, added
during Phase 1 review). (Closes defects: worktree silent work loss,
`git add -A` sweep.)
**Tasks:**
- [x] Task 1.1: phase-lifecycle SKILL.md part B — instruct the isolated
      worker to commit on its task branch before reporting done; add lead's
      pre-removal verification: `git status --porcelain` empty AND
      `git merge-base --is-ancestor <task-branch> <phase-branch>`; any
      failure → stop and report, never `git worktree remove --force`;
      summary format unchanged. (acceptance: part B contains both git
      commands and the no-`--force` rule; worker-commit instruction present;
      diff touches only the worktree section) [type: smoke]
- [x] Task 1.2: task-implementer.md + issue-resolver.md — end-of-task step:
      commit your own work on the current branch with an explicit file list,
      never `git add -A` / any `-A`. (acceptance: both bodies state the
      commit-your-work step with explicit-path requirement; no `-A` anywhere
      in either file) [type: smoke]
- [x] Task 1.3: lead.md — all commit points (phase-complete, review,
      finalize) changed to `git add docs/<slug>/` only; phase-complete also
      flips the phase's checkboxes in implementation-plan.md and records the
      phase-branches row within that same docs-only commit; add the explicit
      edit exception: "bookkeeping only — phase-branches rows + checkboxes,
      never content". (acceptance: no lead commit instruction uses anything
      but `docs/<slug>/`; exception wording present; `-A` gone from lead.md) [type: smoke]
- [x] Task 1.4: Pure-git simulation in `.scratch/wt-sim/` (throwaway repo,
      never committed): follow the edited part B literally — dirty worktree
      → verification refuses removal and stops; committed+merged branch →
      verification passes and removal succeeds; run lead's new commit shape
      with a stray untracked file under `.scratch/` and confirm it lands in
      no commit. Evidence = commands + output in the task report. (acceptance:
       all three assertions pass; `.scratch/wt-sim/` cleaned up) [type: smoke]
- [x] Task 1.5: command-file commit steps → docs-only shape: replace the 8
      `git add -A` sites in `.opencode/commands/` lead commands with
      `git add docs/<slug>/` (archive.md: bare `git commit` after
      `git mv`); generalize lead.md's commit-points enumeration to four.
      Found by Phase 1 review; resolved in-review `0fe836a`. (acceptance:
      `grep -rn "git add -A" .opencode/` → zero hits; lead.md enumerates
      four commit points incl. the archive commit) [type: smoke]

Blocking: 1.1 ↔ 1.3 textually coupled (worker commits vs lead verifies);
do 1.4 last.

## Phase 2 — Interactive FAIL parity
**Goal:** Vertical slice of control flow: interactive `/implement-phase`
handles a failed task exactly like its `-auto` twin (stop delegating, commit
nothing, surface root cause) with the single intentional difference — it
asks the user for direction instead of halting — and skipped tasks become
deferred issues review carries in the feedback-log (receiver-half wiring
completed by Task 2.3, added during Phase 2 review). (Closes defect:
undefined interactive FAIL flow.)
**Tasks:**
- [x] Task 2.1: implement-phase.md — FAIL semantics mirroring
      implement-phase-auto.md: on FAIL, stop delegating, no commit, surface
      root cause, ask direction. (acceptance: the two command files' FAIL
      sections are semantically identical except stop→ask; no other
      behavioral drift) [type: smoke]
- [x] Task 2.2: Skips become deferred issues — instruct lead to record
      tasks skipped after a FAIL so `/review-phase` logs them in
      feedback-log.md like declined issues. (acceptance: carry-over
      instruction present in implement-phase.md and consistent with
      review-phase.md + AGENTS.md deferral language) [type: smoke]
- [x] Task 2.3: Wire the deferred-tasks carry-over chain's receiver half —
      phase-lifecycle part C point 4 broadened to name implementation tasks
      skipped after a FAIL; review-phase.md step 5 coverage list names the
      skipped-tasks landing spot. Found by Phase 2 review; resolved
      in-review `949ed47` (closes NB-1/NB-3). (acceptance: part C point 4
      and review-phase.md step 5 both name skipped-after-FAIL tasks;
      implement-phase.md's citation is literally true) [type: smoke]

Blocking: after Phase 1 (FAIL wording references the new commit scoping).

## Phase 3 — Enforcement hardening
**Goal:** Vertical slice of the permission layer: the YAML denylists
actually match the one-shared-shape AGENTS.md claims — closing the two drift
holes — and grill's subagent reach is whitelisted (string-identity +
compound-push closure completed by Task 3.4, added during Phase 3 review).
(Closes defects: lead missing plain push deny; implementer pair missing
branch -D; grill over-broad task permission.)
**Tasks:**
- [x] Task 3.1: lead.md frontmatter — add plain `git push*` deny alongside
      existing entries. (acceptance: pattern present; existing entries and
      scoped merge/mv allows untouched) [type: smoke]
- [x] Task 3.2: task-implementer.md + issue-resolver.md frontmatter — add
      `git branch -D*` **prefix** and `*git branch -D*`-style **anymatch**
      entries. (acceptance: both forms in both files, mirroring the existing
      dual-pattern convention) [type: smoke]
- [x] Task 3.3: grill.md — `task: {"*": deny, "explore": allow, "scout":
      allow}`; one body line explaining the whitelist (scout may be absent
      in some installs — harmless no-op); README agents-table row updated.
      (acceptance: frontmatter matches exactly; README row shows the
      whitelist, not `task: allow`) [type: smoke]
- [x] Task 3.4: permission-shape hardening found by the Phase 3 review,
      resolved in-review: lead.md gains the anymatch `"*git push*": deny`
      closing the `&&`-chained push hole left by 3.1's prefix-only deny
      (`62751d2`); task-implementer.md + issue-resolver.md anymatch
      branch-deletion key unified to the broader `*branch -D*` form so all
      five denylisted agents are string-identical (`f984f7a`); README
      agents-reference prose extended with grill's explore/scout task lock
      (`f3c2f31`). (acceptance: all five denylisted agents string-identical
      on both branch-deletion patterns; no other permission entries
      changed) [type: smoke]

Blocking: independent of Phases 1–2 content-wise; ordered after for
sequential dogfooding.

## Phase 4 — Shipped-state hygiene
**Goal:** Vertical slice of what a third party actually gets when they copy
the repo: gitignore covers the agents' scratch/log artifacts, the shipped
config contains no personal settings, no live template placeholder ships.
(Closes defects: gitignore gaps + post-archive autorun.log visibility;
phase-reviewer `<fill in>` placeholder; personal config in shipped file.)
**Tasks:**
- [x] Task 4.1: .gitignore — add `.worktrees/`, `.scratch/`,
      `**/autorun.log` (this task also closes the `autorun.log`-sweep
      window that opens at Phase 1 and is live through Phases 2–3: lead's
      docs-only `git add docs/<slug>/` commit stages the live log until
      this lands — see feedback-log risk; reconsider this task's sequencing
      if the automated run keeps logging to this path — trigger observed
      during Phase 2 review (log active through the review commits),
      decision recorded at Phase 3 review: NOT pulled forward — Phase 3 was
      already merged at review time; Task 4.1 executes first in Phase 4;
      until it lands, every lead docs commit (implementation AND review
      stage) must stage specific files, never a bare
      `git add docs/harness-defects/`). Executed first in Phase 4 as decided
      (`4e5d440`, the phase's first commit), closing the sweep window before
      any later phase commit could sweep — R-1 now permanently closed (see
      feedback-log). (acceptance:
      `git check-ignore -v` hits all three, including
      `docs/_archive/x/autorun.log`) [type: smoke]
- [x] Task 4.2: archive.md — note that `git mv docs/… docs/_archive/…`
      deliberately leaves `autorun.log` behind (it's gitignored; the
      historical log stays at its live path or is discarded, by design).
      (acceptance: note present in archive.md) [type: smoke]
- [x] Task 4.3: README copy-instructions — add the `.gitignore` line to the
      copy list. (acceptance: copy list includes .gitignore with a one-line
      rationale) [type: smoke]
- [x] Task 4.4: phase-reviewer.md — delete the live `<fill in …>`
      placeholder, preserving the surrounding defaults it annotated.
      (acceptance: no `<fill in` in `.opencode/` (grep); defaults intact) [type: smoke]
- [x] Task 4.5: `.opencode/opencode.json` — reduce to `$schema` +
      `watcher.ignore` entries only; README documents that the author moves
      personal lsp/mcp/provider/compaction entries to global config
      manually (documentation of a manual step — no agent touches
      `~/.config`). In-run scope extension (lead-sanctioned): also deleted
      the README sentence "The default config in this repo has it on" —
      previously recorded only in the commit body. (acceptance: shipped JSON
      has exactly the two keys; OpenCode still starts in this repo; README
      note present) [type: smoke]

Blocking: independent content-wise; after Phase 1 so `.gitignore` rationale
can reference the new worktree flow.

## Phase 5 — Consistency pass + docs follow-through
**Goal:** Explicitly-allowed layer-only closing slice: after all fixes ship,
one unit of work makes cross-references and the two top-level docs describe
the shipped harness as a whole — the per-phase doc touches can't catch
whole-slug drift.
**Tasks:**
- [ ] Task 5.1: lead.md stale pointer — worktree mechanics pointer targets
      the phase-lifecycle skill, not command files. (acceptance: pointer
      corrected; no other pointer regressions) [type: smoke]
- [ ] Task 5.2: README Troubleshooting — `git add -A` recovery step
      rewritten for the new invariant (recovery now: author-agent re-commits
      missed files; lead's docs-only commit is redone with
      `git add docs/<slug>/`). (acceptance: recovery text matches FR1–FR3) [type: smoke]
- [ ] Task 5.3: Docs follow-through — sweep README + AGENTS.md against every
      Phase 1–4 change (commit model, FAIL semantics, permission sets,
      .gitignore, shipped config); update claims to shipped reality. Four
      items the sweep would otherwise chase were already fixed in-repo by the
      Phase 4 review pass — verify, do not redo: archive.md step-4 reason
      (NB-1 `9c7abb6`), coding-standards `formatter:` pointer (NB-2
      `a9c6dc9`), README full-layout tree + the now-obsolete "add to your
      `.gitignore`" advice (NB-3 `3708c13`), and the `.gitignore` copy-vs-merge
      wording (NB-4 `924c5a8`); the AGENTS.md carry item below is NOT one of
      them and remains owned by 5.3. Carry
      item from the Phase 3 review: the AGENTS.md "Destructive-command
      guardrails" sentence claiming "`phase-reviewer` and
      `architecture-reviewer` also deny `git commit`/ `git add`/ `git push`
      outright" now under-describes `lead`, which since Phase 3 Task 3.1 +
      the review's anymatch follow-up denies plain AND compound `git push`
      too — update that sentence's scope. No length-diet or
      restructuring here (slug 2's job). (acceptance: no
      statement contradicts the shipped mechanics; spec acceptance list
      re-verified end to end) [type: smoke]

Blocking: last phase of the slug.

## Dependencies between phases
- Phase 1 → Phase 2: FAIL-parity text references the new commit scoping.
- Phase 1 → Phase 4: `.gitignore`/README rationale references the new
  worktree flow.
- Phases 1–4 → Phase 5: consistency sweep covers all of them.
- `/finalize harness-defects` runs after Phase 5; merge to main is the
  user's call. **`harness-streamlining` starts only after this slug
  merges.**
