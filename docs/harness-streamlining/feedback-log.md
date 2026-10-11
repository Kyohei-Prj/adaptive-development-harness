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
