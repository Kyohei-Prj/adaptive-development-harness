# Implementation Plan — workflow-patterns

Execution note: this slug dogfoods the harness — phases run via `/implement-phase <n> workflow-patterns`. Per-phase verification is always: `scripts/doctor.sh` green **plus** that phase's dogfood task actually exercising the new primitive end to end.

## Phase 1 — Spike task type + tracer-bullet Phase 0
**Goal:** Vertical slice: a `[type: spike]` task flows from plan vocabulary → `task-implementer`'s new Spike path → committed `findings.md` entry, with doctor.sh enforcing the vocabulary and planner/vertical-slicing guidance recommending tracer-bullet Phase 0 — after this phase, a spike task is dispatchable and its finding lands as a durable artifact.
**Tasks:**
- [x] Task 1.1: Add a tag/mode-vocabulary consistency check to `scripts/doctor.sh` (vocabulary defined once in `planning-docs`; `planner`, `plan.md`, `task-implementer` must agree) — must run RED against the pre-change tree (acceptance: red before Tasks 1.2–1.5 land, green after; `doctor.sh` exit code 0 at phase end) [type: tdd]
- [x] Task 1.2: Extend `planning-docs` skill: `[type: spike]` table row, `(question: …, exit: …)` task syntax, `findings.md` template (dated entries: question / approach / answer / decision) (acceptance: skill contains all three; no other doc references a vocabulary not in the skill) [type: smoke]
- [x] Task 1.3: Add Spike path to `task-implementer` (Step 0 table row + section): time-boxed investigation, throwaway code confined to `.scratch/`, `INCONCLUSIVE` (not FAIL) when the exit criterion can't be met, appends and commits the `findings.md` entry (acceptance: prompt contains the path with containment + INCONCLUSIVE rules; summary block gains a `Finding:` line) [type: smoke]
- [x] Task 1.4: Tracer-bullet + spike guidance: `planner.md` and `plan.md` gain "when to propose Phase 0 / spikes" rules; `vertical-slicing` skill gains a tracer-bullet subsection incl. spike-vs-tracer-bullet distinction (acceptance: planner text recommends Phase 0 for unproven architecture and omits it for brownfield; skill states "spike is thrown away; tracer bullet is kept and grown") [type: smoke]
- [x] Task 1.5: README: `[type: spike]` subsection in Task Type System (accepted: doctor green, incl. 1.1's check; counts line unchanged) [type: smoke]
- [x] Task 1.6: Dogfood: dispatch `task-implementer` on a real ≤10-min `[type: spike]` task (e.g. answer a small library-capability question) (acceptance: output starts `Approach: Spike`, throwaway work stayed under `.scratch/` (`git status` clean outside `docs/workflow-patterns/`), `docs/workflow-patterns/findings.md` exists with one well-formed entry and is committed) [type: smoke]

Blocking: 1.1 first (red), then 1.2–1.5 (green), then 1.6. Within phase: 1.2 before 1.3/1.4 (they reference the vocabulary).

## Phase 2 — Pattern selection in `/plan` + `[mode:]` gate
**Goal:** Vertical slice: `/plan` asks the blueprint's four questions, records a Pattern Record and per-phase `[mode: sdd|interactive|autorun]` tags, and the implement/autorun commands consume them — after this phase, a `[mode: interactive]` phase visibly refuses delegation (and emits `NEEDS_HUMAN` headless), so pattern choice has real downstream force.
**Tasks:**
- [x] Task 2.1: `planning-docs` skill: mode-tag vocabulary + Pattern Record block in the `implementation-plan.md` template (four questions + answers + per-phase mode rationale) (acceptance: template shows the Pattern Record section and all three mode tags with semantics, absent tag = `sdd`) [type: smoke]
- [x] Task 2.2: `planner.md` + `plan.md`: pattern-selection step — ask the four questions, write the Pattern Record, tag every phase; answers feed proposals (low "how" → spike/Phase 0; high mistake cost → offer acceptance scenarios; machine-checkable → offer `[mode: autorun]`) (acceptance: planner and command texts enumerate the four questions and the tag defaults; a run through the guidance on a sample brief yields a Pattern Record + tagged phases) [type: smoke]
- [x] Task 2.3: Mode gate in `implement-phase.md`, `implement-phase-auto.md`, `autorun.md`: `[mode: interactive]` → stop before delegating, point to `/interactive`; headless variants emit `AUTORUN_STATUS: NEEDS_HUMAN: phase <n> is [mode: interactive]`; `sdd`/`autorun`/absent proceed unchanged (acceptance: fixture dry-run — a scratch fixture plan with an interactive phase produces the refusal text interactively and the trailer line from the auto command; `sdd` fixture unaffected) [type: tdd]
- [x] Task 2.4: Extend Task 1.1's doctor check to mode vocabulary + Pattern Record heading; README: "Mode tags" subsection under Task Type System (acceptance: doctor green with the extension; README subsection exists) [type: smoke]
- [x] Task 2.5: Dogfood: temporary fixture slug `docs/wp-dogfood/` (fixture plan + Pattern Record) — run `/plan` guidance on a sample idea text to produce the fixture's Pattern Record, then run `implement-phase-auto 1 wp-dogfood` against an interactive phase (acceptance: `NEEDS_HUMAN` trailer observed; fixture noted in the phase summary for user deletion) [type: smoke]

Blocking: Phase 1 → Phase 2; within phase: 2.1 → 2.2 → 2.3/2.4 → 2.5.

## Phase 3 — Acceptance-test-first with locked scenarios
**Goal:** Vertical slice: `acceptance.md` is drafted during planning, flipped to `Status: Approved` only by the human, read-only for implementers, and `phase-reviewer` blocks a phase on any unapproved scenario edit — after this phase, "tests pass, product wrong" has an enforced outer gate.
**Tasks:**
- [x] Task 3.1: `planning-docs` skill: `acceptance.md` template — `Status: Draft` / `Status: Approved YYYY-MM-DD` header, numbered Given/When/Then scenarios, relationship note (coarse spec criteria stay in spec.md) (acceptance: template exists; skill's editing rules name who may change Status) [type: smoke]
- [x] Task 3.2: `planner.md` + `plan.md`: draft scenarios when the Pattern Record flags high mistake cost / exact behavior; explicit end-of-`/plan` human-approval step; note that implementation must not start on a required-but-Draft file (acceptance: planner/command text covers draft, gate, and the Draft-means-stop rule) [type: smoke]
- [x] Task 3.3: The lock: `task-implementer` + `issue-resolver` gain a read-only rule for `acceptance.md` (report suspect scenarios, never edit); `doc-updater` whitelist grows to `acceptance.md` (approved edits only, with a mandatory feedback-log entry) and `decisions.md` (acceptance: three agent files updated; doc-updater rule enumerates the new whitelist) [type: smoke]
- [x] Task 3.4: `phase-reviewer`: "Acceptance scenario compliance" report section — green evidence per scenario (or flagged uncovered); `git diff <base>...HEAD -- docs/<slug>/acceptance.md` must be empty unless a matching approval is logged in `feedback-log.md`, unlogged change = blocking; `review-phase.md` gains one line surfacing the section (acceptance: fixture run — with the Phase 2 dogfood fixture, a tampered scenario copy produces a blocking finding, a logged-approval edit does not; a doctor static check verifies the section + diff rule exist in the reviewer prompt) [type: tdd]
- [x] Task 3.5: README: `acceptance.md` in Document Templates; cross-links from Mode tags subsection (mistake-cost → acceptance) (acceptance: doctor green; templates section lists the new doc) [type: smoke]

Blocking: Phase 2 → Phase 3 (Pattern Record drives when scenarios exist); within phase: 3.1 → 3.2 → 3.3/3.4 → 3.5.

## Phase 4 — Interactive mode: `/interactive` + `pair` + decision log
**Goal:** Vertical slice: one full pair loop (discuss → small implement step → human inspects → commit → `decisions.md` entry) is exercisable through a real command with a real agent — after this phase the plan/build loop is a sanctioned first-class pattern, and its decision log is a readable input for graduation to `/plan`.
**Tasks:**
- [ ] Task 4.1: `.opencode/agents/pair.md`: primary agent; `edit: allow`; full standard denylist duplicated verbatim in frontmatter (README:689 rule); `task:` whitelist `task-implementer` + `explore` for occasional bigger chunks; rules: current-branch work, no phase branches, commit each human-approved step with explicit paths (`git add <paths>` never `.`/`-A`), append every decision to `docs/<slug>/decisions.md`, hold summaries not diffs in context (acceptance: frontmatter parses via `opencode debug agent`; doctor check 1 green with the new file) [type: smoke]
- [ ] Task 4.2: `.opencode/commands/interactive.md`: `/interactive <slug|new>` (single argument — no phase argument) — bootstraps or continues `docs/<slug>/decisions.md` (creates minimal slug dir with just `decisions.md` for `new`), states the loop protocol and the inspect-after-each-step rule (acceptance: command file lists `agent: pair`; loop steps 1–5 explicit) [type: smoke]
- [ ] Task 4.3: `planning-docs`: `decisions.md` template (dated mini-ADR entries: decision / why / alternatives considered); `planner.md`: read an existing `decisions.md` as aligned input before asking questions (acceptance: template in skill; planner text references it) [type: smoke]
- [ ] Task 4.4: README Agents/Commands reference rows for `pair` + `/interactive`, counts line → 9 agent files, 11 command files; AGENTS.md one-line mention (≤ 80 lines total) (acceptance: doctor green — counts check passes with the new totals) [type: smoke]
- [ ] Task 4.5: Dogfood: run `/interactive` against a throwaway nested git repo under `.scratch/` (acceptance: one complete loop — a real edit, a human-approved commit on the nested repo, a `decisions.md` entry; `git status` of the outer repo unchanged by the loop) [type: smoke]

Blocking: Phase 2 → Phase 4 (mode gate's pointer to `/interactive` becomes live); within phase: 4.1 → 4.2 → 4.3 → 4.4 → 4.5.

## Phase 5 — Characterization-first: `/characterize`
**Goal:** Vertical slice: `/characterize <path>` runs end to end — `characterizer` explores a module and commits passing current-behavior tests with a zero behavior diff — after this phase the brownfield entry point exists and the blueprint's gap list is closed.
**Tasks:**
- [ ] Task 5.1: `.opencode/agents/characterizer.md`: subagent; full standard denylist duplicated; rule set: read target → write tests capturing **current** behavior including quirks and bugs (no fixes, no judgment refactors) → all tests pass against unmodified code → commit only test files; summary lists captured behaviors + observed quirks + blind spots (acceptance: doctor check 1 green; rules text states the no-behavior-change invariant and the commit-tests-only rule) [type: smoke]
- [ ] Task 5.2: `.opencode/commands/characterize.md` (`/characterize <path>`; `agent: lead`) delegating to `characterizer`; `lead.md` task whitelist adds `characterizer` (acceptance: whitelist map includes it; command file states report format: behaviors captured, test files committed, blind spots) [type: smoke]
- [ ] Task 5.3: README Commands reference + counts line → 10 agent files, 12 command files; AGENTS.md "Maintenance Commands" one-liner (acceptance: doctor green with final totals; AGENTS.md ≤ 80 lines) [type: smoke]
- [ ] Task 5.4: Dogfood: `/characterize` a small sample module in a throwaway nested repo under `.scratch/` (acceptance: committed tests pass on the untouched module; diff touches test files only; summary names at least one quirk/edge behavior) [type: smoke]

Blocking: Phase 1 → Phase 5 (doctor infrastructure). Independent of Phases 2–4 — could `[parallel-with: 3, 4]` in principle, but Phases 3–5 all edit README/AGENTS/doctor shared surfaces, so run sequentially unless done with worktree isolation.

## Dependencies between phases

- **1 → 2**: mode vocabulary piggybacks on Task 1.1's consistency check and the plan-template evolution.
- **2 → 3**: the Pattern Record (Phase 2) is what triggers acceptance-scenario drafting; the lock's approval flow reuses the feedback-log conventions Phase 2's template establishes.
- **2 → 4**: the mode gate (2.3) points at `/interactive`, which lands in 4.2; until Phase 4 ships the pointer is forward-looking (accepted within this slug's phase order).
- **4 → 5 / 3 → 5**: no hard dependency; sequencing avoids concurrent edits to README counts line, AGENTS.md, and doctor.sh.
- **Ordering deviation from blueprint priority noted**: blueprint lists acceptance (its gap 2) before interactive (its gap 3), but the mode vocabulary is the routing layer both plug into, so pattern-selection lands as Phase 2. Revisit if the user wants strict blueprint order.
