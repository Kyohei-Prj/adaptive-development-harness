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

## 2026-10-10 — Phase 3 review — Enforcement hardening

Reviewer verdict: **PASS** — all three `[type: smoke]` tasks met their
literal acceptance criteria; the diff `feature/harness-defects-phase-2..3`
is 4 commits, +18/−6 across 7 files — surgical. No blocking issues; 3
non-blocking, all resolved in-review.

**Issues found:**
- [non-blocking] NB-1: lead.md's Task 3.1 `git push*` deny is prefix-only —
  an `&&`-chained push (e.g. `cd x && git push origin main`) passes lead's
  denylist while the reviewer agents carry the broader `*git push*`
  anymatch; AGENTS.md's own dual-pattern rationale says lead should have
  had both forms.
- [non-blocking] NB-2: branch-deletion anymatch string drift — the
  implementer pair used `*git branch -D*` where lead/phase-reviewer/
  architecture-reviewer use `*branch -D*`; "one shared shape" is true
  functionally but false as strings, which is what the frontmatter is made
  of.
- [non-blocking] NB-3: README agents-reference prose (L352) describes only
  lead's subagent lock — grill's new explore/scout whitelist is undocumented
  in prose (the table row itself is correct).
- Testing compliance: PASS on all three `[type: smoke]` tasks (YAML parse +
  grep re-verification per task; the phase's implementation run ended
  `AUTORUN_STATUS: OK`). Empirical bonus: during this review the anymatch
  denies literally blocked reviewer AND resolver probe commands — the
  denylist works end to end.
- Invariant checks: phase-complete commit `6066bef` is docs-only
  (implementation-plan.md checkbox flips + phase-branches row 3 only);
  `docs/harness-defects/autorun.log` touched by 0 commits across the range —
  specific-file staging held through Phase 3 (3rd consecutive phase);
  commit-message template matches.
- Prior-phase risks: R-1 partially honored (lead surfaced the heads-up, kept
  specific-file staging, and explicitly recorded the pull-forward decision
  as un-taken in the unattended run — this review closes it, see Doc
  changes); R-2/R-3/R-4 and the Phase 1 carries all honored/verified PASS.

**Resolutions applied:**
- `62751d2` (NB-1): `"*git push*": deny` anymatch added to lead.md after
  `*branch -D*`, mirroring phase-reviewer:30; 1-line diff; the existing
  prefix denies and scoped merge/mv allows untouched.
- `f984f7a` (NB-2): the implementer pair's anymatch widened to `*branch -D*`
  — unification direction judgment: the BROAD string (strictly more denied,
  never weaker; matches lead/phase-reviewer/architecture-reviewer;
  narrowing the other three would have weakened guardrails). All five
  agents are now string-identical on both branch-deletion patterns.
- `f3c2f31` (NB-3): one sentence added to the README L352 paragraph noting
  grill's explore/scout lock, including the scout-optional no-op note; the
  table row L343 was already correct.

**Deferred issues (confirmed but not fixed this round):**
- AGENTS.md guardrails sentence ("phase-reviewer and architecture-reviewer
  *also* deny `git commit`/ `git add`/ `git push`") now under-describes
  lead's post-3.1+`62751d2` push surface. Resolution = routed, not fixed
  here: AGENTS.md drift is Task 5.3's declared sweep scope (and Phase 4 may
  touch permission-adjacent docs again); added to 5.3 as an explicit item
  this round so it carries rather than drops.

**Risks for future phases:**
- R-1 disposition RECORDED (was "decision due before Phase 3"): pull-forward
  NOT taken (Phase 3 was merged); Task 4.1 executes first in Phase 4; until
  it lands, the autorun.log sweep window stays live THROUGH PHASE 4'S OWN
  IMPLEMENTATION AND REVIEW COMMITS — every lead docs commit until 4.1 ships
  must stage specific files, never a bare `git add docs/harness-defects/`.
  Phase 4 inherits a decision, not another "due before".
- Long-form bypass: `git branch --delete --force` evades the `-D` deny in
  all five files (as does `--delete -f`); out of spec scope — candidate for
  a future hardening pass / harness-streamlining, not for this slug.
- Deliberate residual: the implementer pair has no plain-push deny at all
  (spec FR6 scoped only branch -D, force-push variants) — the "push is never
  an agent operation" intent is only half-enforced there; candidate for user
  decision at 5.3 or in harness-streamlining.

**Doc changes applied:**
- implementation-plan.md: Task 4.1's pull-forward trigger resolved to a
  recorded decision (not pulled forward; executes first in Phase 4;
  specific-file staging mandate extended to review-stage commits); Task 5.3
  gained the AGENTS.md push-deny-sentence sweep item; Task 3.4 added
  (`[x]` `[type: smoke]`) recording the three in-review fixes
  (`62751d2`/`f984f7a`/`f3c2f31`), mirroring the Task 1.5/2.3 pattern;
   Phase 3 Goal annotated.
- architecture.md: none.
- spec.md: none.

---

## 2026-10-10 — Phase 4 review — Shipped-state hygiene

Reviewer verdict: **PASS** — 0 blocking, 5 non-blocking, **all 5 resolved in
this pass — nothing deferred**. Diff base `feature/harness-defects-phase-3`
(per `phase-branches.md`). All five Phase 4 tasks are `[type: smoke]`; the
reviewer independently re-ran every acceptance check at HEAD — `git
check-ignore` hits for all three patterns including
`docs/_archive/x/autorun.log` and a root-level `autorun.log`;
`grep -rn "<fill in" .opencode/` → 0 hits; the shipped JSON parses with
top-level keys exactly `$schema` + `watcher` and `watcher.ignore`
byte-identical; "OpenCode still starts" confirmed at config-parse level.
Lead's `af68e02` touched only `implementation-plan.md` + `phase-branches.md`
with explicit-path staging — 4th consecutive phase holding that invariant.

**Issues found:**
- [non-blocking] NB-1: `.opencode/commands/archive.md` step 4 contradicted
  step 3 — Task 4.2 added a note to step 3 that gitignored files
  (`autorun.log`) stay behind at the live path `docs/$1/`, so the directory
  still exists on disk after `git mv`; step 4 still claimed "`docs/$1/` no
  longer exists to stage anyway". The conclusion (no `git add` needed) was
  right; the reason was false.
- [non-blocking] NB-2: `.opencode/skills/coding-standards/SKILL.md:74-76`
  cited `opencode.json`'s `formatter: true`, a key Task 4.5 removed from
  shipped config (OpenCode's formatter is default-on, which is why the key
  was redundant).
- [non-blocking] NB-3: README "Directory Structure" (the copy step's
  self-declared "full layout") listed neither root `.gitignore` nor
  `.opencode/opencode.json`, even though this phase made both part of the
  copy story; and the `.worktrees/`/`.scratch/` annotations plus the prose
  paragraphs on parallel-worktrees and scratch-space still said "Add … to
  your `.gitignore`" — advice the shipped `.gitignore` already satisfies.
- [non-blocking] NB-4: README copy step implied copying the harness
  `.gitignore` over an adopting project's own, which would clobber it.
- [non-blocking] NB-5: phase-complete commit-message drift — `af68e02` read
  `feat(harness-defects): phase 4 harness-defects complete` (slug duplicated
  into the description) vs. `feat(harness-defects): phase <n> complete` in
  Phases 2–3.
- Testing compliance: PASS on all five `[type: smoke]` tasks — checks
  re-derived independently at HEAD (verdict paragraph).
- Invariant checks: phase-complete commit `af68e02` is docs-only
  (`implementation-plan.md` + `phase-branches.md`) with explicit-path
  staging — 4th consecutive phase the sweep invariant holds; the
  commit-message template drifted (NB-5) and was pinned at source.
- Diffstat re-check (reviewer checked because it looked alarming):
  `.opencode/opencode.json` shows 0 insertions / 101 deletions but was
  **trimmed, not deleted** — still tracked at HEAD, valid JSON, exactly
  `$schema` + `watcher`. Consistent with FR10 and the README copy story.

**Resolutions applied:**
- `9c7abb6` (NB-1): archive.md step 4's reason restated on tracked-file /
  stageability semantics — the no-`git add` conclusion holds because there
  are no *tracked* files left to stage, not because the directory is gone.
- `a9c6dc9` (NB-2): coding-standards SKILL.md now cites the default-on
  formatter behavior instead of the removed `formatter:` key; the
  convention's substance unchanged. `grep -rn "formatter:"` now matches
  nothing outside `docs/`.
- `3708c13` (NB-3): root `.gitignore` and `.opencode/opencode.json` added to
  the Directory-Structure tree; the `.worktrees/`/`.scratch/` annotations and
  both prose spots reworded from instruction to shipped fact.
- `924c5a8` (NB-4): README copy step now says merge the three lines into an
  existing `.gitignore`; copy-in only for a fresh repo.
- `77e8ba9` (NB-5): canonical shape `feat(<slug>): phase <n> complete` pinned
  in `phase-lifecycle/SKILL.md` part A (slug once, as the conventional-commit
  scope, never repeated in the description). Root cause: the shape existed
  only in the three command files (`implement-phase.md:19`,
  `implement-phase-auto.md:17`, `autorun.md:22`) and was absent from the skill
  that is the declared single source of truth for phase mechanics and already
  discusses this same commit; the command files were intentionally left
  untouched since their `$1`/`$2` forms are correct; `af68e02` left as
  history.

**Deferred issues (confirmed but not fixed this round):**
- None — all five non-blocking findings were resolved in this review pass;
  nothing was skipped, so nothing is deferred.

**Risks for future phases:**
- R-1 disposition: **PERMANENTLY CLOSED** — closed by `4e5d440` (Task 4.1,
  the phase's first commit, exactly as the Phase 3 entry decided). The
  `**/autorun.log` ignore pattern makes `git add -A`-style sweeps
  structurally unable to pick the log up again, so the specific-file-staging
  mandate no longer needs to be carried as live context into Phase 5 or
  `/finalize`; supersedes the still-open R-1 wording in the Phase 3 entry.
- R-5 (slug 2 / FR10 interaction): `docs/harness-streamlining/architecture.md:21`
  plans to make the shipped `opencode.json` the "single home of the shared
  denylist", i.e. deliberately breaks "exactly two keys" and the README
  sentence this phase just fixed. Slug 2 must amend that README sentence and
  its own "docs' file-count claims match reality" acceptance check in the
  same change, or it re-opens the contradiction Phase 4 closed.
- R-6 (post-archive residue): by Task 4.2's design, a live `docs/<slug>/`
  containing only `autorun.log` lingers after `/archive`. The leave-behind
  note explains it to the *archiving agent*, not to the next reader — a
  later `/grill`/`/plan` session scanning `docs/` could still read that
  residue directory as active. Watch whether it bites when this slug itself
  is archived.
- R-7 (`autorun.log` never rotates): correctly ignored now, but ~1.26 MB and
  append-only. Harmless to git, a nuisance for grepping. Rotation/truncation
  convention belongs to a later slug, not this one.

**Doc changes applied:**
- implementation-plan.md: Task 5.3 annotated — the Phase 4 review pass
  already fixed in-repo four of the items its sweep would otherwise look for
  (archive.md step-4 reason / NB-1, coding-standards `formatter:` pointer /
  NB-2, README full-layout tree + the obsolete "add to your `.gitignore`"
  advice / NB-3, `.gitignore` copy-vs-merge wording / NB-4), rephrased so 5.3
  verifies rather than redoes them; its Phase-3 carry (AGENTS.md
  destructive-command-guardrails sentence under-describing `lead`'s push
  denies) stays owned by 5.3. Task 4.5 annotated — also deleted the README
  sentence "The default config in this repo has it on" (lead-sanctioned
  in-run scope extension, previously recorded only in the commit body),
  matching how Tasks 1.5/2.3/3.4 record in-run extras. Task 4.1 annotated —
  executed first in the phase per the Phase 3 R-1 decision, closing the sweep
  window before any later phase commit could sweep.
- architecture.md: none — reviewer confirmed it already describes the shipped
  end-state accurately.
- spec.md: none — reviewer confirmed it already describes the shipped
  end-state accurately.

---

## 2026-10-10 — Phase 5 review — Consistency pass + docs follow-through

Reviewer verdict: **PASS** — 0 blocking, 1 non-blocking, resolved in this
pass. Diff base `feature/harness-defects-phase-4` (per `phase-branches.md`);
4 commits, +46/−36 across 5 files. All three `[type: smoke]` tasks
re-derived independently at HEAD: 5.1 PASS (lead.md:130 pointer now resolves
to phase-lifecycle part B; the old command-file pairing is 0 hits repo-wide);
5.2 PASS (README:672 recovery = author-agent re-commit +
`git add docs/<slug>/` redo, no `add -A` left anywhere in README/AGENTS);
5.3 PASS (guardrails sentence verified against all 8 agent frontmatters; the
four "verify, don't redo" Phase-4 items confirmed in place, not redone —
`9c7abb6`/`a9c6dc9`/`3708c13`/`924c5a8`). Spec acceptance list re-verified
end to end: FR1–FR10 all confirmed at HEAD
(grep/glob/check-ignore/JSON-parse checks); two acceptance criteria are
legitimately PENDING rather than failing — "each phase passes /review-phase"
(completed by this review) and "/finalize clean" — both spec checkboxes get
ticked at `/finalize`, not before.

**Issues found:**
- [non-blocking] NB-1: `AGENTS.md:78-85` — the "Each denied pattern is
  listed twice" claim is not literally true for the
  `task-implementer`/`issue-resolver` push family: `git push origin +*` has
  no anymatch counterpart and `*push -f *` demands a trailing space, so
  compound variants (`cd x && git push origin +main`) evade the pair's
  denylist; `lead` unaffected (`git push*` + `*git push*` both present).
  Pre-existing paragraph, not introduced by Phase 5 — surfaced by the
  whole-slug sweep.
- Testing compliance: PASS on all three `[type: smoke]` tasks — every
  acceptance check re-derived independently at HEAD (verdict paragraph).
- Invariant checks: phase-complete commit `507c208` is docs-only
  (`implementation-plan.md` 3 checkbox flips + `phase-branches.md` row 5)
  and its message `feat(harness-defects): phase 5 complete` matches the
  template pinned in part A — 5th consecutive phase holding the
  authorship invariant; task commits `dd8b97f`/`bc3b8a8`/`240412a` each
  scoped-path by their author. Note: this is also the first review where
  lead's literal `git add docs/harness-defects/` staging is safe — the
  `**/autorun.log` ignore (`4e5d440`, Task 4.1) means the live log can no
  longer be swept; Phase 4's R-1 "PERMANENTLY CLOSED" disposition is
  re-confirmed operationally.
- Prior-risk verification (all closed/verified): Phase 2 R-2 stale pointer
  CLOSED (5.1); Phase 2 R-3 twin FAIL-section parity VERIFIED byte-identical
  across implement-phase.md:21-25 / implement-phase-auto.md:19-23, the
  differences exactly the sanctioned set, twins untouched in this range;
  Phase 2 R-4 deferral language CLOSED (AGENTS.md stage 3 + README:261 now
  cover declines AND skipped-after-FAIL tasks, consistent with part C
  point 4); Phase 3 carry — AGENTS.md push-deny sentence CLOSED (rewritten
  AGENTS.md:64-72 matches lead.md frontmatter exactly; the sweep
  additionally corrected two README table cells the old text contradicted —
  the reviewers' `git add` deny, lead's `webfetch: allow`). Phase 2 NB-2
  twin duplication: not re-raised (routed to `harness-streamlining`), sync
  confirmed. Phase 3/4 residuals: prior disposition stands (see deferred
  below).

**Resolutions applied:**
- `9b896a3` (NB-1): AGENTS.md dual-listing paragraph qualified — one 8-line
  insertion spelling out the exact pair exception and marking the mechanics
  fix (`"*git push*"` deny on the pair) as a queued decision deliberately
  not taken in this slug (spec FR6 scope + prior routing). The agent
  frontmatter was deliberately NOT touched — that mechanics change belongs
  to the push-hardening decision below.

**Deferred issues (confirmed but not fixed this round):**
- **Push-hardening cluster — 3 logged candidates, now formally bundled as
  ONE routed decision** (user / `harness-streamlining`; all three touch the
  same 2 frontmatters, so resolve them together or not at all):
  (a) [this review, NB-1 mechanics half] the pair has no `"*git push*"`
  anymatch, so compound `git push origin +*` / trailing-`-f` variants evade;
  (b) [Phase 3 R] the pair has no plain-push deny at all ("push is never an
  agent operation" is only half-enforced there) — `*git push*` closes (a)
  and (b) in one line; (c) [Phase 3 R] long-form
  `git branch --delete --force` / `--delete -f` evades the `-D` deny in all
  five files. NB-1's doc half (the AGENTS.md overclaim) is FIXED at
  `9b896a3`; only the mechanics stay deferred.

**Risks for future phases:**
- R-5 carried from Phase 4 (`harness-streamlining` / FR10): making the
  shipped `opencode.json` the denylist's "single home" deliberately breaks
  "exactly two keys" + README:459 — that slug must amend both in one change.
- R-6 carried (post-archive residue): this slug's own `/archive` is the
  first real test — `docs/harness-defects/` will linger on disk containing
  only the ignored `autorun.log`; watch whether a later `/grill`/`/plan`
  session misreads it as active.
- R-7 carried: `autorun.log` never rotates (append-only, ~1.26 MB) — later
  slug.
- Pending spec criteria: spec.md's acceptance list stays unticked until
  `/finalize` re-verifies the two pending items ("each phase passes
  /review-phase", "/finalize clean") and ticks them there.

**Doc changes applied:**
- implementation-plan.md: Task 5.3 annotated — sweep executed at the Phase 5
  review (the four Phase-4 verify-don't-redo items confirmed, the guardrails
  sentence + 2 README table cells corrected by the phase's own commits,
  NB-1's dual-listing nuance resolved in-review at `9b896a3` with its
  mechanics half routed into the push-hardening cluster).
- architecture.md: none — L26 already matches shipped reality.
- spec.md: none — tick acceptance items at `/finalize` only.

---
