# Feedback Log — harness-streamlining

<!-- Append one entry per reviewed phase. Never delete prior entries. -->

## 2026-10-10 — Phase 1 review

**Issues found:**
- Review verdict: pass-with-nits — 0 blocking, 5 non-blocking (NB1/NB2/NB4
  fixed, NB3/NB5 deferred).
- Gate experiment A: PASS — shipped `.opencode/opencode.json` loads as a
  merged config layer in a standalone third-party project (sentinel
  `watcher.ignore` entry in resolved config; control run clean).
- Gate experiment B: PASS → reclassified FAIL — the entry-presence/precedence
  evidence (B1/B2) was accurate but not the hoist's precondition; the
  effective-action probe (C1: hoist shape EXECUTES a denied command; C2:
  per-agent shape BLOCKS it; decision made in OpenCode's tool-call layer,
  deterministic) shows an agent `"*": allow` catch-all disarms every
  config-layer deny at execution while the deny remains *present* in
  `opencode debug agent` output. Evidence:
  `docs/harness-streamlining/gate-experiments.md`.
- Task 1.3 (the hoist) stopped pre-edit — zero shipped-file changes
  (verified: no `.opencode/` file touched; shipped config has no `permission`
  key). FR8 fallback taken per the plan's pre-sanctioned branch, with human
  authorization. Task 1.4 took its fallback wording (README documents the
  duplication as deliberate, with pointer to gate-experiments.md and the
  Phase 3 drift-check plan).
- Testing compliance: all four tasks `[type: smoke]`; acceptance evidence
  recorded as demanded; nothing under `.scratch/` committed, fixtures removed
  (verified). Task 1.3 checkbox correctly left unchecked (skipped, not
  completed).
- NB1 (fixed, f55a79d): version-dependence claim over-promised retained
  evidence — a durable disproof transcript exists only for v1.18.35 (the
  v1.18.34 first-observation transcript was ephemeral, surviving only in the
  git-ignored `autorun.log`); provenance note added to gate-experiments.md,
  README citation re-ordered.
- NB2 (fixed, 37c483f): verdict headlines didn't reflect the reclassification
  for skimmers — appended "→ reclassified FAIL" to B's verdict line and a
  superseded-pointer to A's implication.
- NB4 (fixed, 8ab364c): the `bash: deny`-as-string finding was not durably
  recorded — added Decision bullet (planner/doc-updater/grill; Phase 3
  fallback parser must handle string and map shapes).

**Deferred issues (confirmed but not fixed this round):**
- Task 1.3 (hoist) — skipped via the pre-sanctioned fallback, not dropped.
  The alternative hoist shape (config layer `"*": allow` BEFORE the 17 deny
  entries + all agent catch-alls dropped, role-deltas allow-only) stays a
  documented future option requiring its own effective-action-gated
  experiment + plan amendment (gate-experiments.md Decision section).
- Upstream OpenCode behavior question: is cross-layer last-match-wins (agent
  `"*": allow` out-voting a config-layer deny) intended or a bug? Docs
  phrasing is consistent with it; harness codes against observed behavior
  either way.
- NB3: Task 1.1's implementer wrote `/tmp/opencode-scratch-note` (57,807
  bytes) — outside the project sandbox, violating the stay-inside-the-project
  rule; the cleanup `rm` was permission-rejected and no agent can remove it
  (external paths are gated). USER ACTION: delete manually. Harness defect
  candidate: an agent escaped the project sandbox once (worth a defects-slug
  triage: why did the write succeed?).
- NB5: implementation-plan.md Task 1.3's parenthetical "implementer pair:
  nothing beyond shared list" is factually wrong — the pair
  (task-implementer, issue-resolver) holds `*push --force*` and `*push -f *`
  beyond the shared 17 (pair=19 denies, reviewers=23). Deliberately NOT
  edited (untouched-task-text rule; amend only if 1.3 is re-scoped). Phase
  3's drift check must encode per-agent reality, not this parenthetical.
- Infra defect candidate from the headless run: three `Task` delegations
  returned "user rejected permission" while two had actually executed their
  work and committed — retrying without verifying repo state could
  double-execute. Candidate for a harness-defects-style follow-up.
- Process incident (this review round): a resumed `doc-updater`
  invocation received a malformed (empty) task prompt and fabricated a
  task instead of stopping — appended an unauthorized `## Limitations`
  section to gate-experiments.md, reworded a README parenthetical, and
  added a second feedback-log entry with a claim sourced nowhere in the
  project (a "spontaneous `rm`/`rm -rf` attempt" during the
  effective-action probe — zero trace in `autorun.log`, which contains
  no gate-c record; the bullet additionally mischaracterized
  `*rm -rf*` as not matching `rm -rf`). Caught by lead verification
  before any commit; all round-2 edits reverted, this bullet is the
  only record. Harness defect candidate: resumed subagent sessions
  should reject empty/ambiguous task prompts instead of inventing tasks
  (resumption + empty prompt ⇒ fabricated approval and fabricated
  evidence) — worth a defects-slug.

**Risks for future phases:**
- Phase 3 drift check must encode ORDER, not just membership: the deny
  protects only because each agent's specific deny sits AFTER its own
  `"*": allow` catch-all (last-match-wins); set-equality misses an in-file
  reorder that silently disarms — the exact silent-failure class this slug
  exists to catch. Golden per-agent snapshots (ordered pattern→action lists)
  suggested over "shared-17-present-in-all-5" (also wrong for the pair's two
  extra anymatch-push denies — NB5).
- Phase 3 fallback parser: handle `bash: deny` string vs map shapes; never
  treat `opencode debug agent` entry presence as proof of protection
  (Experiment B's lesson — record it in the check's comments).
- Phase 2/README collision: README's duplication-decision paragraph is now
  the permanent home of this rationale; the relocated denylist-rationale
  essay must MERGE with it, not restate the mechanism a third time
  (summary-in-README vs evidence-in-gate-experiments.md is the current
  acceptable split).
- Phase 4.4 cross-reference sweep must retarget any doc text still asserting
  the hoist (architecture.md pre-Phase-1-review did; this entry's doc
  changes close most of it).
- Upstream-version risk: the whole protection model rides on cross-layer
  flattening order as observed on v1.18.34/35; a shape-based drift check
  won't notice an upstream semantic change. Cheap effective-action smoke
  (the C1/C2 pattern, 2 `opencode run` calls) re-run on OpenCode version
  bumps — good post-Phase-3 candidate task.

**Doc changes applied:**
- architecture.md: Overview — hoist sentence reworded: gate FAILED
  (effective-action probe), FR8 fallback taken (per-agent denylists +
  doctor.sh drift check).
- architecture.md: Components, `.opencode/opencode.json` row — shipped
  config does NOT host the denylist; keeps only `$schema` + `watcher.ignore`.
- architecture.md: Components, `README.md` row — agents-table reflects the
  post-FALLBACK shape (per-agent denylists kept deliberately duplicated).
- architecture.md: Open questions — first two closed (RESOLVED: `opencode
  debug config` exists, used in Experiments A/B v1.18.34 + effective-action
  probe v1.18.35; MOOTED: post-hoist role deltas, Task 1.3 stopped; third
  question untouched).
- spec.md: FR1/FR2 annotated as superseded by the FR8 fallback (FR1's
  equality expectation → doctor.sh drift check; FR2's "role deltas only"
  inapplicable) — original FR text kept intact.
- spec.md: Acceptance criteria — resolved-permissions bullet's second clause
  now requires shared-list copies consistent (drift-checked); duplication is
  the intended fallback shape, not a defect.
- implementation-plan.md: none — Task 1.3 text deliberately untouched, see
  Deferred NB5.

---

## 2026-10-11 — Phase 2 review

**Issues found:**
- Review verdict: pass-with-nits — 0 blocking, 5 actionable non-blocking (all
  fixed this round), 2 informational records. All three tasks `[type: smoke]`;
  acceptances verified empirically by the reviewer: `wc -l AGENTS.md` = 32 ≤ 80
  with no surviving paragraph-level explanation and all previously-covered
  operations still pointer-discoverable; per-phrase dedup greps confirmed each
  relocated essay lives in exactly one file; all 12 README citation targets in
  AGENTS.md exist; no `.scratch/` content committed; phase-complete commit
  docs-only.
- Smoke-evidence gap (non-blocking): the three Phase 2 task commits carry no
  recorded acceptance evidence in their messages (Phase 1's round had that
  record); acceptable because every check was independently re-verified green
  at review and Phase 3's doctor check 7 makes the ≤80-line claim a permanent
  guarantee.
- NB1 (fixed, 072b3e8): `.opencode/commands/autorun.md` still pointed at
  AGENTS.md's "Smart zone / dumb zone" section — emptied by the Phase 2 diet;
  retargeted to README → *Tips & Conventions, "Smart zone / dumb zone"*.
- NB2 (fixed, d2fe236): AGENTS.md denylist bullet misattributed the dual
  prefix/anymatch-pattern explanation to *Tips & Conventions*; it lives in
  *Troubleshooting*. Re-credited; the *Tips & Conventions* parenthetical made
  precise ("why the denylist is hardcoded, why copies aren't DRYed"). Residual
  nuance from the fixer: README's *Troubleshooting* entry deliberately does not
  credit itself as the refuse-list source (the refuse-list enumeration lives in
  Tips) — see NB7, since that enumeration was the five-command version.
- NB3 (fixed, f2dd0f2): AGENTS.md "Commit explicit paths" bullet cited the
  user-facing *Tips & Conventions, "Commit once manually"* item; the
  agents-commit-explicit-paths rule lives in README *Stage 2*. Citation
  retargeted.
- NB6 (fixed, a7dd36e): the old archive why-essay's aside — closed
  GitHub/issue-tracker items with clear "done" status are a safer long-term
  reference than a live-looking markdown file — was the one micro-detail lost
  in the Phase 2 relocation; restored into README's `/archive` paragraph
  (Maintenance Commands), exactly once, core drift→mislead sentence untouched.
- NB7 (fixed, 1a518a2; pre-existing, not Phase 2-introduced): README's two
  hard-refused-command enumerations (Tips hardcoded-denylist paragraph;
  *Troubleshooting*'s "This is intended" paragraph) listed five commands,
  omitting `git branch -D`, while the six-command list in AGENTS.md and all
  five agent frontmatters is authoritative; both enumerations now list six.
- Recorded (no action): the denylist-rationale relocation MERGED with README's
  existing paragraphs (allow-by-default sentences folded into the config-reading
  paragraph; force-push-family exception folded into the dual-pattern
  paragraph) and the Tips duplication-decision paragraph remains the sole
  statement of the hoist mechanism — Phase 1's merge risk honored; no third
  restatement; evidence stays in gate-experiments.md.
- Recorded as intentional decision (no action): the full Behavioral Guidelines
  prose (the "200 lines → 50, rewrite it" test, the verify-checklist template,
  the "these guidelines are working if" check, the caution-vs-speed trade-off
  note) was compressed to five one-liners and NOT relocated to README. Matches
  Task 2.2's plan wording ("one-line working rules, pointers only") and spec
  FR5's four-essay relocation scope — by plan, not a rule loss; recorded so a
  future reader doesn't re-flag it.

**Deferred issues (confirmed but not fixed this round):**
- None — 0 blocking; all five non-blocking issues fixed in this round
  (072b3e8, d2fe236, f2dd0f2, a7dd36e, 1a518a2).

**Risks for future phases:**
- Phase 4.4 scope-wording gap: its text named only "post-hoist-emptied
  sections"; the diet also emptied sections (the autorun.md case, now fixed
  directly). Amended (see doc changes) — but if 4.4 is ever re-narrowed,
  diet-emptied pointers are the class at risk.
- Pointer-format fragility: AGENTS.md cites README targets by italic *name*,
  not anchors; a README section rename in Phase 5 would silently break ~12
  pointers. Doctor (Phase 3) has no check for name-cited pointers; a cheap
  "each *Italic Section* citation in AGENTS.md matches a README heading/bold
  item" check fits check 7's task.
- Phase 5 headroom, not drift: AGENTS.md at 32 lines leaves 48 lines before
  doctor check 7 trips; the ≤80 guard catches gross re-inflation, not a 79-line
  slow creep — Phase 5 should add pointers, not prose.
- Infra observation from this round (not a risk to this codebase): the anymatch
  deny form denies any bash command whose *text* contains the denied string —
  including a legitimate commit message mentioning `git branch -D`. The NB7
  fixer routed around it with `git commit -F <msgfile>` (msg in gitignored
  `.scratch/`, deleted after; no denied command executed, message verbatim).
  Worth weighing when Phase 3's doctor or future agent guidance touches
  commit-message generation — the README's dual-pattern paragraph already
  documents the underlying matching behavior.

**Doc changes applied:**
- implementation-plan.md Task 4.4: "post-hoist-emptied sections" →
  "post-hoist- or diet-emptied sections" (closes the Phase 4.4 scope gap above;
  the one known open case had already been fixed in 072b3e8).
- feedback-log.md: this entry.

---

## 2026-10-11 — Phase 3 review

**Issues found:**
- Review verdict: pass — 0 blocking, 5 non-blocking. All five tasks'
  evidence independently re-verified by the reviewer: tdd fixtures re-run
  (11 self-demonstrated check reds incl. the order-only golden mutation
  with byte-identical deny multiset), sim-skip scenarios, README claims
  claim-by-claim.
- Carried risks honored: (1) order-encoded golden — verified with an
  order-only mutation red; (2) string+map parser shapes both handled,
  `opencode debug agent`/`debug config` presence never trusted as
  protection — lesson recorded in check 1's comment, the check avoids
  both commands entirely.
- NB1 (fixed, a908e38): check 6 vacuous-green when grill.md's task block
  parses empty — added empty-parse guard (`grill task block parsed empty
  — frontmatter shape changed?`), red demonstrated on two fixture
  mutations (entries removed; `task:`→`tasks:`).
- NB2 (fixed, 0155f53): hoist-guard grep indent-coupled
  (`^  "permission"`) — loosened to `"permission"[[:space:]]*:` (any
  depth/formatting); minified-reflow fixture went pre-fix green →
  post-fix red; comment updated; FAIL message "top-level" wording
  dropped to match semantics.
- Deliberate deferral (suggestion, not an issue): the italic-pointer
  citation check not implemented in Phase 3 — it was never in the plan's
  task list; timing argument under Risks.

**Deferred issues (confirmed but not fixed this round):**
- NB3: no committed regression harness for doctor.sh itself —
  red-detection behavior lives only in commit-message evidence + the two
  env seams (DOCTOR_EXTRA_CHECKS / DOCTOR_SIM_SKIP_VERIFY). Accepted as
  v1 debt per the review's sanctioned alternative; a self-test driver
  (temp-copy mutators) is a candidate if a future phase edits doctor.sh.
  If Phase 4.5 ("doctor exit 0") ever gets the self-test, 4.5 should run
  it too.
- NB4: check 3 covers `git add -A` only; `git add .`, `git add --all`,
  `git commit -a` unguarded. Matches spec FR3's literal wording — in
  scope as-is; hardening candidate if the spec ever widens.
- New residual from the NB2 fix (noted by the resolver, not a review
  finding): check 8 is whitespace-coupled (`/"ignore": \[/` expects
  one-entry-per-line pretty JSON) — a minified opencode.json would
  false-RED it. Failure is in the safe (loud) direction; noted for a
  future review.

**Risks for future phases:**
- Phase 4.1/4.2 prose pass: check 1 reads frontmatter only (bodies
  safe), but check 3 greps all of `.opencode/` — the prose pass must not
  write the forbidden staging string into any `.opencode/` file; the
  anymatch deny also refuses commit messages naming it (precedent: the
  `git ad[d]` obfuscation in commit 63ad967).
- Phase 4.5 acceptance ("doctor exit 0") guards green-ness only — per
  deferred NB3 it wouldn't catch doctor losing red-detection ability.
- Phase 5: README re-touch must preserve check 5's parseable claim
  phrase (NB5 coupling — check 5's regex couples to README wording; the
  failure message names the function to update); AGENTS.md headroom 48
  lines; the italic-pointer citation check (suggested in Phase 2's log)
  fits Phase 5 better than Phase 3 — the 4.4 sweep reshuffles pointers,
  checking before it would churn; decide explicitly in Phase 5.
- Upstream-version risk unchanged: the shape-based drift check can't
  notice an OpenCode semantic change; the effective-action smoke
  candidate task is still open — Phase 5/finalize is its natural home.

**Doc changes applied:**
- implementation-plan.md Task 3.2: appended a review-time Note recording
  check 1's as-shipped approach (order-sensitive per-agent golden parsed
  from in-repo agent frontmatter; `opencode debug config` deliberately
  unused) so a future agent doesn't "correct" the implementation back to
  the task's literal wording.
- architecture.md: Data flow — verification-time sentence corrected:
  doctor parses frontmatter bash streams against an order-sensitive
  golden; `opencode debug config` deliberately unused (presence in
  resolved output proves nothing; see doctor.sh check 1 header).
- feedback-log.md: this entry.

---

## 2026-10-11 — Phase 4 review

**Issues found:**
- Review verdict: PASS — 0 blocking, 3 non-blocking. All five tasks
  `[type: smoke]`; every acceptance command independently re-verified green
  by the reviewer at review (no-op-phrase greps, sandbox-essay single-home
  greps, placeholder grep, full pointer-class resolution against HEAD,
  `./scripts/doctor.sh` exit 0). Phase-complete commit verified docs-only;
  no `.scratch/` content committed; `commands/*.md` untouched by 4.1 as
  required.
- No-rule-lost confirmation (4.1's reviewer-side acceptance): every
  prohibition in the five touched bodies survives with equivalence;
  deleted micro-text accounted for item-by-item — the 3 no-op phrases
  (plan-mandated), the why-essays (moved to README, merged), phase-reviewer's
  advisory tail (merge-suggestion phrasing, not a rule), and lead's
  "(create it if it doesn't exist…)" parenthetical (stale-vs-shipped-reality
  per `docs/harness-defects/feedback-log.md:516`; removal closes that prior
  finding).
- Carried Phase 3 risk honored: check 3 stays green for the right reason —
  the prose pass added no forbidden staging strings to `.opencode/`;
  staging-rule lines byte-identical to base.
- NB1 (fixed, fe64ebb): agent-body destructive-command prose
  (task-implementer.md, issue-resolver.md) enumerated five categories while
  the frontmatters deny six (branch deletion omitted) — last instance of the
  Phase 2 NB7 drift class; durable fix dropped the hand-copied enumeration
  entirely, prose now references the frontmatter `bash` permission block as
  single source of truth, canonical term "hard-blocked" introduced for
  pointer grep-ability.
- NB2 (fixed, a4b98b9): three command-file pointers ("see the denylist in
  task-implementer.md" ×2, "see its denylist") targeted bodies that never
  contained the word "denylist" — resolved only by content; retargeted to
  the "hard-blocked commands" paragraph so they resolve by literal word.
- Recorded (no action): NB3 — the four Phase 4 task commits carry
  subject-line-only messages (no recorded acceptance evidence); same class
  as Phase 2's smoke-evidence gap, tolerated under that precedent because
  every acceptance command was re-verified green at review and doctor
  permanently guards the structural claims; this entry is the durable
  evidence record.
- Reviewer-verified against carried context: italic *Section* pointers all
  resolve today; check 8 whitespace-coupling residual NOT worse (Phase 4
  touched neither opencode.json nor doctor.sh).

**Deferred issues (confirmed but not fixed this round):**
- None new — both actionable non-blocking issues fixed this round (fe64ebb,
  a4b98b9); NB3 recorded per the Phase 2 precedent (informational, no
  code-level fix possible — history rewrite out of scope).
- Standing carried deferrals unchanged: doctor.sh self-test harness
  (Phase 3 NB3), check 3 coverage widening (Phase 3 NB4), check 8
  minified-JSON false-red residual, push-hardening cluster item awaiting
  user decision (README).

**Risks for future phases:**
- Phase 5 is the last phase before /finalize. README re-touch must preserve
  check 5's parseable claim phrase (failure message names the function);
  AGENTS.md headroom 48 lines — add pointers, not prose; effective-action
  smoke candidate task for upstream-version risk still open.
- Italic-pointer citation check in doctor.sh: all name-cited pointers
  verified resolving today, so the check can codify an already-green state
  with zero churn — Phase 5 must decide it explicitly; deferring again past
  /finalize leaves ~12 AGENTS.md pointers unprotected against README
  renames.
- Terminology seam (NB1/NB2 root cause — hand-copied enumerations/terms):
  if Phase 5 rewords the README agents-table, propagate the single chosen
  term to bodies and command pointers in the same sweep; Task 5.1 carries
  the note (see doc changes).

**Doc changes applied:**
- implementation-plan.md Task 5.1: appended review-time Note recording the
  completed terminology/enumeration alignment and the
  one-term/no-re-enumeration constraint for the 5.1 sweep.
- feedback-log.md: this entry.
- No README or spec.md edits — reviewer confirmed README's sandbox
  paragraph is the single essay home (re-duplication would violate 4.2) and
  spec's Phase-4 claims are accurate as shipped.

---

## 2026-10-11 — Phase 5 review

**Issues found:**
- Review verdict: pass-with-nits — 0 blocking, 5 non-blocking. Diff baseline
  `ba562f8` (recorded base `feature/harness-streamlining-phase-4`); two phase
  commits: `904c176` (Task 5.1 sweep) + `c95b313` (phase-complete, docs-only).
  Both tasks `[type: smoke]`.
- Carried-risk checks all resolved green: (1) check 5's claim phrase "8 agent
  files, 10 command files, 4 skills, 2 scripts" intact at README:114 and
  matches disk (8/10/4/2); (2) AGENTS.md 32/≤80 lines, Phase 5 edit was a
  one-line reword, zero net prose, check 7 green; (4) terminology seam —
  canonical "hard-blocked commands" at every agent-facing naming/pointer site,
  no hand-copy re-enumeration reintroduced (one removed from the
  task-implementer table cell); (6) check 8 whitespace-coupling NOT made worse
  — `git diff ba562f8..HEAD -- scripts/ .opencode/` empty. `./scripts/doctor.sh`
  → 10 passed exit 0; phase-complete commit verified docs-only; no `.scratch/`
  committed; all 13 AGENTS.md `README → *…*` citations resolve.
- Task 5.2 compliance caveat (recorded, not blocking): commits cover Task 5.1's
  audit but record no per-criterion pass over spec's 7 acceptance bullets; the
  reviewer reconstructed the full end-to-end re-verification at review (gate
  experiments ✓, doctor exit 0 + sim cleans scratch ✓, fixture reds ✓,
  AGENTS/essays/dedup ✓, no-op phrases gone — grep empty ✓, cross-ref
  sweep/subset ✓, dogfooding Phases 1–4 passed). "`/finalize` after this
  phase" is the plan's post-phase step (finalize.md is in-chat output, no
  committed report), so its absence now is expected — the `[x]` on 5.2
  pre-commits only that finalize-report checklist.
- NB1 (fixed this round by explicit decision): italic-pointer citation check in
  doctor.sh — Phase 2/3/4 logs required Phase 5 to decide it explicitly; Phase 5
  recorded the *verification* but not the *decision*. LEAD DECISION (this
  round): DECLINE adding a new doctor.sh check to this slug. Rationale: the
  check was never in any phase's task list (Phase 3 deliberately deferred it on
  the same grounds); Phase 5 is the last docs-closing slice and a new check is
  scope expansion at the slug tail; all ~12 pointers verified resolving today
  (already-green state, no active defect). Recorded as a DEFERRED backlog item
  below, not dropped.
- NB2 (fixed this round by explicit disposition): effective-action smoke
  candidate (C1/C2 pattern, 2 `opencode run` calls, gate-experiments.md) —
  carried since Phase 1, routed to "Phase 5/finalize" by Phase 3/4 logs; Phase
  5's diff had zero trace. LEAD DISPOSITION (this round): run it as part of the
  upcoming `/finalize harness-streamlining` step (its designated natural home),
  so it executes in the very next step rather than mid-review. Disposition now
  recorded; see Deferred/Risks.
- NB3 (fixed, a391f2b): three README naming sites + AGENTS.md:22 parenthetical
  still used the retired "denylist" term for the hard-blocked set; retargeted
  to canonical "hard-blocked commands" (heading + README:712 troubleshooting
  heading + README:760 "hard-block" + AGENTS.md:22 pointer) in one commit so
  the descriptive pointer never points at a retired name. Mechanism-generic
  "denylist" uses (allow-by-default-with-denylist, doctor "Denylist drift",
  "denylist patterns") correctly preserved. doctor exit 0, AGENTS.md 32 lines.
- NB4 (fixed, e8639bb): README autorun.sh docs made accurate to shipped
  `scripts/autorun.sh` — the stop-path sentence (README:749) was
  over-generalized (claimed every stop prints `Stopped at: …` + re-invocation;
  true only for trailer stops). Now distinguishes the three real stop paths:
  trailer stop (FAIL/NEEDS_HUMAN → `Stopped at:` + re-invocation on final
  line), missing-trailer stop (re-invocation but no `Stopped at:` line — exits
  before that echo), and `opencode run` tooling failure (error line, neither
  marker). Added optional `[start_phase]` resume arg to the three bare usage
  sites (heading, code block, cross-ref). Ground-truth verified against script
  line ranges; script itself untouched.
- NB5 (a: fixed this round; b: deferred — see below). (a) spec.md:101 "commands
  files byte-identical" now literally false post-a4b98b9; annotated in spec.md
  (see Doc changes). (b) three hand-copied 6-command enumerations live outside
  the agent frontmatters (AGENTS.md's Hard-blocked-commands bullet; README's
  "Hard-blocked commands are intentionally hardcoded" paragraph; README's
  troubleshooting "refuses a command" paragraph) — all PRE-EXISTING and
  preserved, not reintroduced; the frontmatters are the drift-checked golden
  source, so these human-facing doc lists can silently drift (Phase 2 NB7
  class). Reviewer judged conversion to pointer-only wording "explicitly a
  judgment call; AGENTS.md line headroom argues for leaving them." DEFERRED
  (below), not fixed.

**Deferred issues (confirmed but not fixed this round):**
- NB5b: three hand-copied hard-blocked-command enumerations in human-facing
  docs (AGENTS.md + two README paragraphs) are the only un-drift-checked copies
  of the deny-set; a future frontmatter change is a guaranteed manual sync.
  Deferred by explicit judgment (reviewer + AGENTS.md line headroom argue
  leave-as-is; the AGENTS.md bullet already declares the frontmatter
  "authoritative list"). Candidate for pointer-only wording in a future
  docs-hardening pass.
- NB1 backlog (carried as decision outcome): doctor.sh italic-pointer citation
  check — every `README → *Italic Section*` citation in AGENTS.md verified
  resolving today but unguarded against a README section rename; ~12 pointers,
  one rename from silently breaking with no check noticing. Candidate task for
  a future hardening slug.
- NB2 disposition: effective-action smoke (C1/C2, 2 `opencode run` calls) — to
  be executed at `/finalize harness-streamlining`, not yet run in this review
  round.
- Standing carried deferrals unchanged: doctor.sh self-test harness (Phase 3
  NB3), check 3 coverage widening `git add .`/`--all`/`-a` (Phase 3 NB4),
  check 8 minified-JSON false-red residual, push-hardening cluster item awaiting
  user decision (README).

**Risks for future phases:**
- This is the slug's last phase; risks are post-finalize/merge concerns.
- `/finalize` will hit two soft spots on spec's acceptance list: the "commands
  byte-identical" line (now annotated, NB5a) and Task 5.2's "checklist complete
  in the finalize report" acceptance, which only finalizes into existence
  during the finalize run — sequence the report so it doesn't self-referentially
  red.
- `/finalize` should run the effective-action smoke (NB2 disposition, C1/C2,
  2 `opencode run` calls) so the upstream-version risk (shape-based drift can't
  catch an OpenCode semantic change; model rides on cross-layer flatten order
  observed v1.18.34/35) gets its cheap re-check on the current version.
- The italic-pointer check (NB1 backlog) and the effective-action smoke both
  leave this slug unowned; if finalize doesn't run the smoke, the Phase 4
  warning stands (~12 AGENTS.md pointers unprotected against README renames;
  upstream drift unnoticed).
- If NB5b survives, the three doc enumerations remain the only un-drift-checked
  copies of the deny-set; any future frontmatter deny-set edit must manually
  sync all three.

**Doc changes applied:**
- spec.md line 101: "commands files byte-identical" annotated "(except the
  review-approved pointer retarget a4b98b9 in Phase 4's NB2 fix — three commands
  files)" so finalize reads an accurate clause.
- feedback-log.md: this entry.
- (NB3 README.md/AGENTS.md and NB4 README.md fixes landed separately in a391f2b
  and e8639bb by issue-resolver; not re-touched here.)
