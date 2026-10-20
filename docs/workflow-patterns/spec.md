# Specification — workflow-patterns

## Goal

The harness gains five pattern primitives from `docs/workflow-patterns-blueprint.md` (spike task type + tracer-bullet Phase 0, pattern selection with `[mode:]` tags, locked acceptance scenarios, a sanctioned `/interactive` pair loop with a decision log, and `/characterize` for brownfield work), each usable end-to-end and validated by `scripts/doctor.sh` plus one dogfood run.

## In scope

- `[type: spike]` task tag, Spike path in `task-implementer`, `docs/<slug>/findings.md`, tracer-bullet Phase 0 guidance in planner + `vertical-slicing` skill
- Pattern-selection step in `/plan` (blueprint's four questions) → Pattern Record + `[mode: sdd|interactive|autorun]` phase tags; mode gate in implement/autorun commands
- `docs/<slug>/acceptance.md`: planner-drafted Given/When/Then scenarios, explicit human approval, read-only for implementers, enforced by `phase-reviewer` diff check
- `/interactive` command + `pair` primary agent + `docs/<slug>/decisions.md` decision log
- `/characterize <path>` command + `characterizer` subagent (current-behavior tests, zero behavior change)
- README (Task Type System, Mode tags, Document Templates, Agents/Commands references, counts line) and AGENTS.md updates; new `doctor.sh` static checks

## Out of scope

- Blueprint gaps beyond 1–5 (batch/fan-out as a first-class command, ADR tooling, eval-driven development)
- Changes to grill, archive, finalize semantics; changes to `[type: tdd]`/`[type: smoke]` behavior; changes to existing phase-branch/worktree mechanics
- Any runtime enforcement machinery (hooks, file ACLs) — locks are instruction-level + reviewer diff, per agreed decision
- Hash-verified acceptance lock

## Functional requirements

1. **Spike task type.** `implementation-plan.md` tasks may carry `[type: spike]` with `(question: …, exit: …)` instead of `(acceptance: …)`. `task-implementer` recognizes the tag (Step 0 table), runs a time-boxed investigation, confines throwaway code to `.scratch/`, and appends a dated entry (question / approach / answer / decision) to `docs/<slug>/findings.md`, committing it. An unanswered question is reported as `INCONCLUSIVE` with what was tried — not FAIL. The vocabulary appears in exactly one source of truth (`planning-docs` skill) and consistent copies elsewhere are enforced by doctor.
2. **Tracer-bullet Phase 0.** `planner` and the `vertical-slicing` skill recommend an optional Phase 0 — the thinnest real, end-to-end slice through the riskiest boundaries, real dependencies, no mocks — for greenfield or architecture-unproven slugs; explicitly optional for brownfield/small slugs.
3. **Pattern selection.** `/plan` asks the blueprint's four questions (know *what*? know *how*? mistake cost? machine-checkable done?), records answers as a Pattern Record in `implementation-plan.md`, and tags every phase `[mode: sdd]` (default), `[mode: interactive]`, or `[mode: autorun]`. Answers feed back into the plan: low "know how" → propose spikes/Phase 0; high mistake cost → propose acceptance scenarios; machine-checkable → propose `[mode: autorun]` for suitable phases.
4. **Mode gate.** `implement-phase`, `implement-phase-auto`, and `autorun.md` read the phase's mode tag: `[mode: interactive]` → do not delegate; in interactive commands stop and point to `/interactive`; in headless commands emit `AUTORUN_STATUS: NEEDS_HUMAN: …`. `sdd` and `autorun` proceed as today. Absent tag = `sdd` (backward compatible with existing plans).
5. **Acceptance scenarios.** When the Pattern Record calls for them, `planner` drafts `docs/<slug>/acceptance.md` (numbered Given/When/Then scenarios; header `Status: Draft`). `/plan` ends with an explicit human approval step flipping it to `Status: Approved YYYY-MM-DD`; implementation must not start on a Draft file that this slug's plan expects approved.
6. **Acceptance lock.** `task-implementer` and `issue-resolver` treat `acceptance.md` as read-only (never edit, even to "fix" a wrong scenario — report it). `doc-updater` may edit it only when the user explicitly approved scenario changes, and every such edit gets a `feedback-log.md` entry. `phase-reviewer` adds an "Acceptance scenario compliance" section: (a) each scenario has green evidence (test/e2e check) or is listed as uncovered, (b) `git diff <base>...HEAD -- docs/<slug>/acceptance.md` is empty unless a matching approval is logged; an unlogged change is **blocking**.
7. **Interactive mode.** New `/interactive <slug|new>` command running the `pair` primary agent: single-session loop of discuss → implement small step → human inspects → repeat; small direct edits allowed; each human-approved step is committed (explicit paths, never `git add .`); every decision appended to `docs/<slug>/decisions.md` (decision / why / alternatives). No phase branches. `planner` reads an existing `decisions.md` as input when work graduates to `/plan`.
8. **Characterization.** New `/characterize <path>` command: `lead` delegates to a `characterizer` subagent (added to its task whitelist) that explores the target, writes tests capturing *current* behavior — including quirks, no behavior fixes — verifies they pass against unmodified code, and commits only test files plus a short summary report of discovered behaviors.
9. **Docs and nav.** README: `[type: spike]` + Mode tags subsections, Document Templates entries for the three new files, Agents/Commands reference rows, counts line updated to the real post-work totals (expected: 10 agent files, 12 command files, 4 skills, 2 scripts). AGENTS.md stays ≤ 80 lines (doctor check) — one-line mentions of `/interactive` and `/characterize` only.
10. **Doctor.** New static check(s): tag vocabulary (`tdd|smoke|spike`) and mode vocabulary (`sdd|interactive|autorun`) are defined once in `planning-docs` and referenced consistently by their carrying files — `type` by `planner`, `plan.md`, `task-implementer`, and `README.md`; `mode` by `planner`, `plan.md`, and `README.md` (`task-implementer` is deliberately a `type`-only carrier: modes are phase-level, so it carries no `[mode: …]` refs); existing checks (counts, denylist drift, invariant markers) stay green across all phases.

## Non-functional requirements

- **Guardrails:** `pair` and `characterizer` ship the full standard denylist duplicated in their frontmatter (README:689 — duplication is deliberate); doctor check 1 passes.
- **Reliability:** no behavior change for existing slugs/plans without new tags; headless contract (trailer format, fail-closed) unchanged.
- **Compatibility:** existing opencode agent/command/skill file formats only; no plugins, no new MCP servers.

## Acceptance criteria

- [ ] A `[type: spike]` task dispatched to `task-implementer` classifies as Spike, confines throwaway work to `.scratch/`, and appends a well-formed entry to `findings.md` (FR1, dogfood run)
- [ ] `planner` guidance produces a tracer-bullet Phase 0 recommendation for an unproven-architecture scenario and omits it for a brownfield one (FR2)
- [ ] `/plan` flow records a Pattern Record and `[mode:]` tag on every phase; an `[mode: interactive]` phase makes `implement-phase` refuse and `implement-phase-auto` emit `NEEDS_HUMAN` (FR3, FR4)
- [ ] With `acceptance.md` present: reviewer flags an unapproved scenario edit as blocking and a logged-approval edit as acceptable; implementer prompts state read-only (FR5, FR6)
- [ ] `/interactive` completes one full discuss→implement→inspect loop in a throwaway repo, with a `decisions.md` entry and a per-step commit (FR7)
- [ ] `/characterize <target>` yields passing tests and a behavior-zero diff outside test files (FR8)
- [ ] `scripts/doctor.sh` exits green; README counts match `find` counts; AGENTS.md ≤ 80 lines (FR9, FR10)

## Constraints / assumptions

- This repo's test suite is `scripts/doctor.sh` + one manual dogfood run per new entry point; there is no unit-test runner for prose.
- `.scratch/` is gitignored and is the only scratch location (agent working rules); throwaway code never enters tracked paths.
- opencode behavior as pinned by the repo (denylist dual-prefix patterns, last-match-wins frontmatter permissions).
- The blueprint (`docs/workflow-patterns-blueprint.md`) is the aligned design-concept input for this slug; gaps 1–5 in its stated order map to Phases 1–5.
- Commits during Implementation follow existing conventions (explicit paths; the harness's own repo style: `feat:`/`fix:`/`docs:`).
