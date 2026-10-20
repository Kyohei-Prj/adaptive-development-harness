# Feedback Log — workflow-patterns

<!-- Append one entry per reviewed phase. Never delete prior entries. -->

## 2026-10-20 — Phase 1 review (Spike task type + tracer-bullet Phase 0)

**Issues found:**
- No blocking issues. Phase passes. The Task 1.1 TDD red→green arc was independently reproduced (RED at the base branch and at the doctor-only commit `9a6c434`, GREEN once Tasks 1.2–1.4 landed), vocabulary drift is caught in both directions by the new `doctor.sh` check, and the Task 1.6 dogfood `findings.md` entry is committed with throwaway work kept under gitignored `.scratch/`. Five non-blocking issues found; all five dispositioned below (four fixed, one deferred).
- [non-blocking, FIXED] `README.md` prose/diagrams still described a two-value `[type: tdd]`/`[type: smoke]` vocabulary and omitted the new `[type: spike]` (lines ~73, ~89 ASCII-box captions; ~111 "Explicit over inferred"; ~478 implementation-plan task-line format). Fixed: prose synced to the three-value vocabulary; the two ASCII-box captions were genericized to preserve box-column alignment.
- [non-blocking, FIXED] `AGENTS.md:3` described the `planning-docs` skill as covering only `[type: tdd]`/`[type: smoke]` tag rules. Fixed: generalized to "`[type: …]` task-type tag rules" (in-line; file stays 32 lines).
- [non-blocking, FIXED] `scripts/doctor.sh` `check_tag_vocabulary_consistency` extracted ids with `[a-z|]+`, so an undeclared hyphenated id (e.g. `[type: q-and-a]`) in a consumer passed the "extra" (undefined-id) direction silently, contradicting the check's "never a silent skip" header comments. Fixed: id class widened to `[a-z|-]+` (verified: a hyphenated undeclared id now goes red; `[type: ...]`/`[type: …]` placeholders stay excluded; `[type: tdd|smoke]` still splits); both header comments corrected to state the guarantee accurately. No `[mode:]` entry added — that stays deferred to Task 2.4.
- [non-blocking, FIXED] `task-implementer.md` end-of-task summary `Finding:` field had no `n/a` escape for non-spike tasks (unlike every other field in the block). Fixed: field scoped to Spike with a `| n/a` option.

**Deferred issues (confirmed but not fixed this round):**
- Template-fence style inconsistency in `.opencode/skills/planning-docs/SKILL.md`: of the six inline doc templates in the "Templates" section, five (architecture, spec, implementation-plan, feedback-log, findings) are unfenced while `phase-branches.md` is fenced. The reviewer flagged the unfenced `findings.md` template (a second H1 renders mid-file). Deferred deliberately: the correct fix is ONE consistent fence style across the whole Templates section, which belongs to **Task 2.1** (the next change that edits this Templates section, to add the mode-tag vocabulary + Pattern Record). Fencing only `findings.md` now would create a different partial inconsistency. → Task 2.1: pick one style and apply it to all Templates-section templates.

**Risks for future phases:**
- **Task 2.4 inherits three known debts in one function** — add the `mode` dimension via the already-documented array extension point (correctly *absent* in this mode-free Phase 1 tree), consider carrying `README.md` in the set once its prose is fully vocabulary-complete, and note the parser still misses ids using characters outside `[a-z|-]` (digits/uppercase). Do all three in the same commit to keep the golden-list story coherent.
- **`INCONCLUSIVE` has no consumer-side gating semantics yet** — nothing in `lead`/`implement-phase*` says how an inconclusive spike gates its phase (proceed / defer dependents / fail). `architecture.md` already flags this as an open question; if a *load-bearing* spike (one a later task's approach depends on) comes back INCONCLUSIVE, write the outcome contract before then. (Appended to architecture.md "Open questions".)
- **Prose-drift is the systematic gap this phase exposes** — the four machine-checked carrying files stay green while unchecked narrative (README prose/diagrams, AGENTS.md) lags. Every remaining phase adds vocabulary; consider making README a carrying file once its format line mentions all ids so the check prevents recurrence.
- **Sequencing hazard is correctly planned but stays live** — the README counts line, AGENTS.md, and doctor.sh are shared surfaces across Phases 2–5 (the plan declines `[parallel-with]` for them). Keep the Phase 4.5 / 5.4 nested-repo dogfood prompts consistent with the Phase-1 spike's proven pattern; the spike finding's gitlink warning (an in-tree fixture can be committed as mode-160000) is a real hazard those prompts should cite.
- **`.scratch/` accumulates across dogfoods** (Phase 1 left `spike-nested-repo`, `spike-nested-wt`, `spike-outer-fake`, `vocab-tdd`, `vocab-verify*`; all gitignored) but nothing prunes it — a cleanup rule in the spike path would prevent unbounded growth in a long dogfooding repo. Speculative.

**Doc changes applied:**
- architecture.md: appended the INCONCLUSIVE-gating open question to "Open questions" (so it resurfaces via this log).
- feedback-log.md: this Phase 1 review entry.
- (Code/prompt fixes, applied by `issue-resolver`, outside doc-updater's whitelist: README.md vocabulary sync, AGENTS.md:3 wording, scripts/doctor.sh `[a-z|-]` regex + comment correction, task-implementer.md `Finding:` n/a escape.)

## 2026-10-20 — Phase 2 review (Pattern selection in /plan + [mode:] gate)

**Issues found:**
- No blocking issues. Phase passes. Task 2.3's TDD arc independently reproduced (0/22 at the base branch in a fresh tree → 22/22 at HEAD; live headless run refused at the gate with the exact `AUTORUN_STATUS: NEEDS_HUMAN: phase 1 is [mode: interactive]` trailer and zero git-state mutation); doctor green; the Phase 1 deferred fence-style item verified FIXED (one consistent fenced-`markdown` style across all six Templates-section templates); all three Task 2.4 doctor debts discharged in the single commit `f148d8a` (mode dimension via the documented array extension point with a comment on what is deliberately excluded; README.md carried on BOTH vocabulary dimensions; the `[a-z|-]`-outside-ids parser gap noted as documented caveat, per the debt's wording). Five non-blocking issues found; all five resolved (four by `issue-resolver`, one by this log's deletion note).
- [non-blocking, FIXED] `.opencode/commands/implement-phase.md` gate step 0 refused with `Run /interactive $2 $1` (slug+phase), contradicting spec FR7 / Task 4.2's single-arg `/interactive <slug|new>`. Fixed: dropped `$1` → `/interactive $2` (commit `715ad5a`).
- [non-blocking, FIXED] `.opencode/commands/autorun.md` per-phase repeat range "steps 2–10" excluded the per-phase report (step 11) and checkpoint (step 12) — a pre-existing off-by-two exposed by Phase 2's renumbering. Fixed: range now 2–12 (commit `f9f6e5b`).
- [non-blocking, FIXED] `scripts/doctor.sh` Pattern Record drift message had a garbled clause ("heading the template both consumers point at"). Fixed: "…heading both consumers point at" (commit `27e3bc8`).
- [non-blocking, FIXED] Task 2.3's 22-assertion static contract for the mode gate lived only in gitignored `.scratch/` — no durable FR4 regression check. Fixed: all 22 static assertions ported to `scripts/doctor.sh` as `check_mode_gate_contract` (CHECK 11; doctor checks 11→12; RED verified via three tamper probes on scratch copies — mangled trailer, deleted gate step, gate-after-branch-setup ordering); `.scratch/wp23-gate-test.sh` kept as historical reference (commit `b852f8c`). Phase 3.4's planned reviewer-prompt static check should follow this seam.
- [non-blocking, FIXED] `docs/wp-dogfood/` (Task 2.5 dogfood fixture) untracked with its delete-me note only inside the untracked file. Fixed by recording — see the fixture deletion note below; deliberately NOT committed (a committed temp slug would need removing later).

**Fixture deletion note:** `docs/wp-dogfood/` is a temporary untracked fixture (fixture plan + Pattern Record + one interactive phase for the mode-gate dogfood). DELETE at `/finalize workflow-patterns`; until then it shows as `?? docs/wp-dogfood/` in every `git status`.

**Deferred issues (confirmed but not fixed this round):**
- **None** — all five non-blocking issues were resolved this round.

**Risks for future phases:**
- **Four-questions prose now exists verbatim in ≥4 places** (`planner.md`, `plan.md`, the `planning-docs` template, the `wp-dogfood` fixture) while doctor only presence-checks the `## Pattern Record` heading — question wording can silently drift between carriers. Speculative.
- **Shared-paragraph duplication across the three implement command files grows each phase** — the gate paragraph is near-duplicated with internal step-number cross-references; if Phase 4 touches them again, consider hoisting shared mechanics into the `phase-lifecycle` skill.
- **`/review-phase*` intentionally does not gate on mode** — fine while interactive phases can't be implemented at all, but once Phase 4 makes an interactive phase produce commits, Phase 4 must decide whether `/review-phase` refuses or skips them.
- **Phase-complete commits carry empty bodies** (Phase 1 precedent), so anything the plan expects "noted in the phase summary" has no durable home — such notes should default to this feedback-log (as done for the wp-dogfood fixture deletion note above).
- **The new `check_mode_gate_contract` is a static prose contract** — windowed greps (e.g. `-A12`/`-A14`, carried verbatim from the scratch harness): a far-rewrapped gate paragraph could widen/narrow detection; governed by its update-together-with-a-reason failure messages.

**Doc changes applied:**
- spec.md: FR10 consumer sets split per dimension (`type`: SKILL/planner/plan/task-implementer/README; `mode`: SKILL/planner/plan/README), recording task-implementer's deliberate type-only status.
- implementation-plan.md: Task 4.2 pinned to the single-argument `/interactive <slug|new>` form.
- planning-docs SKILL.md: "MAY carry" reconciled with planner/plan "Tag every phase" (new plans tag every phase; absent = `sdd` default keeping pre-mode plans running).
- feedback-log.md: this Phase 2 review entry.
- (Code/prompt fixes, applied by `issue-resolver`, outside doc-updater's whitelist: implement-phase.md `/interactive` pointer, autorun.md repeat range, doctor.sh drift message, doctor.sh `check_mode_gate_contract`.)
