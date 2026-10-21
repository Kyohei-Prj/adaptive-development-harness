# Architecture — workflow-patterns

## Overview

Extends the OpenCode workflow harness with the five pattern primitives identified as gaps in `docs/workflow-patterns-blueprint.md`: a `[type: spike]` task type with tracer-bullet Phase 0 guidance, a pattern-selection step in `/plan` recording per-phase `[mode: …]` tags, human-approved-and-locked acceptance scenarios, a sanctioned interactive pair-loop entry point with a decision log, and a characterization-first command for brownfield work. The harness already covers blueprint patterns 5, 6, 7, 12, 13, and parts of 14; this work fills gaps 1–5 without changing the existing Grill → Plan → Implement → Feedback flow for anyone who doesn't opt in.

## Components

| Component | Responsibility | Tech |
|---|---|---|
| `planning-docs` skill | Single source of truth for tag vocabulary (`[type: spike]`, `[mode: …]`) and templates for the three new docs: `findings.md`, `acceptance.md`, `decisions.md` | Markdown skill |
| `task-implementer` | New third execution path: Spike (question + exit criterion → findings entry, throwaway code confined to `.scratch/`) | Agent prompt |
| `planner` + `/plan` | Pattern-selection step: ask the blueprint's four questions, record a Pattern Record, tag phases `[mode: …]`, propose tracer-bullet Phase 0, draft-and-gate `acceptance.md` | Agent prompt + command |
| `lead` + `implement-phase{,-auto}` + `autorun{.sh,.md}` | Mode gate: `[mode: interactive]` phases refuse delegation (headless → `NEEDS_HUMAN`) and point to `/interactive` | Prompts + bash |
| `phase-reviewer` | New "Acceptance scenario compliance" report section; locks `acceptance.md` via base-diff | Agent prompt |
| `doc-updater` | File whitelist grows to `acceptance.md` + `decisions.md` (approved edits only) | Agent prompt |
| `pair` agent + `/interactive` | Sanctioned single-session pair loop: discuss → implement small step → human inspects; appends `decisions.md` | Primary agent + command |
| `characterizer` agent + `/characterize` | Brownfield safety net: tests capturing current behavior, zero behavior change | Subagent + command |
| `doctor.sh` | New static checks: tag-vocabulary consistency across files; existing count/denylist/invariant checks kept green | bash |
| README / AGENTS.md | Docs + navigation; README.md:114 counts line must match actual file counts | Markdown |

## Data flow

```
/grill → /plan ── 4 questions → Pattern Record + [mode:] tags in implementation-plan.md
            └── (if chosen) draft acceptance.md ──human approves──> Status: Approved
  /implement-phase N → mode gate → [mode: interactive]? → refuse, point to /interactive
                     → else delegate tasks:
                         [type: spike] → code in .scratch/, findings appended to docs/<slug>/findings.md
                         [type: tdd|smoke] → unchanged
  /review-phase N → phase-reviewer: acceptance.md unmodified since approval? scenarios green?
  /interactive   → pair edits small steps on current branch, appends docs/<slug>/decisions.md
                   (decisions.md becomes /plan input when work graduates to SDD)
  /characterize <path> → characterizer writes+commits characterization tests only
```

## Data model

No database. The durable artifacts are files under `docs/<slug>/`:

- `findings.md` — append-only, one dated entry per spike: question, approach, answer, decision. Written by the spike's `task-implementer`.
- `acceptance.md` — Given/When/Then scenarios with stable IDs (A1, A2, …), header `Status: Draft` → `Status: Approved YYYY-MM-DD`. Locked from implementers.
- `decisions.md` — append-only mini-ADR entries (decision / why / alternatives), written by `pair`.
- `implementation-plan.md` — gains a Pattern Record section (slug-level) and `[mode: …]` tags (phase-level).

Relationships: `acceptance.md` scenarios are evidence-checked by `phase-reviewer` each phase; unauthorized diffs require a matching approval entry in `feedback-log.md`.

## External dependencies

None new. opencode ≥ current repo version (agent/command/skill file formats, `opencode debug agent` as used by doctor.sh), git worktrees, existing `.scratch/` gitignore entry.

## Key decisions & trade-offs

- **Spike is a `task-implementer` path, not a new agent** — Why: the `[type: …]` tag already routes implementer paths; a separate `spiker` agent duplicates the per-agent denylist and most of the prompt. — Alternatives: dedicated spike agent.
- **Acceptance lock is instruction + reviewer `git diff`, not hash-verified** — Why: matches the harness's existing trust model (prompts + reviewer checks, no enforcement machinery); hash adds ceremony for a threat (a rogue agent editing scenarios) the instruction layer already covers in every other lock. — Alternatives: content-hash header verified by reviewer.
- **`[mode: …]` is phase-level; acceptance is presence-of-`acceptance.md`** — Why: modes are about *who implements* (human pair vs delegated vs unattended); acceptance scenarios are an orthogonal evidence layer. A separate `[mode: acceptance]` tag would mix the two axes. — Alternatives: one combined mode enum.
- **`pair` is a new primary agent, not `lead` with looser rules** — Why: `lead`'s `edit: allow` is deliberately bookkeeping-only; giving it content edits would dissolve its core invariant. — Alternatives: parameterized lead.
- **`pair` works on the current branch, no phase branches** — Why: the pair loop's review gate is the human watching every step; phase-branch machinery is for unreviewed batch delegation. — Alternatives: per-loop feature branch.
- **`pair` is exempt from the review machinery — the human inspecting each loop step *is* the review gate** — Why: an `[mode: interactive]` phase therefore gets no phase branch and no `phase-branches.md` baseline row, so `/review-phase*` refuse such a phase instead of dead-ending on a missing baseline (the refuse rule, added in the Phase 4 review round, commit `50833eb`); the phase's durable record is `docs/<slug>/decisions.md`; and `pair`, while it holds `edit: allow`, is bound by the `acceptance.md` read-only lock like the other content-writing agents (`96e5ef3`). This closes the refuse-vs-skip question carried forward from the Phase 2 and Phase 3 reviews. — Alternatives: review without a baseline; silently skipping interactive phases. — **Pending the user's ratification at `/finalize`:** the decision was taken by the automated Phase 4 run applying the reviewer's recommendation — an unattended judgment call, not a user decision.
- **Mode gate refuses `[mode: interactive]` rather than auto-launching `/interactive`** — Why: a command chain can't reproduce the human side of the loop; refusing with a pointer keeps the contract honest.
- **New bash agents copy the standard denylist verbatim** — Why: per README:689, hoisting to config is proven unsafe (`"*": allow` out-votes config denies); doctor check 1 keeps copies synced. — Alternatives: none viable.
- **Doctor.sh is the test suite** — Why: this repo's logic *is* static structure; prose rules get consistency checks (like the existing denylist-drift and invariant-marker checks). — Alternatives: none.
- **Dogfood harness for Phase 4/5 smoke checks: nested throwaway repo under gitignored `.scratch/`, all git ops via explicit `git -C <path>`** — Why: a real in-tree micro-change nests a repo that can be accidentally staged and committed as a mode-160000 gitlink (reproduced by the Task 1.6 spike, `findings.md` 2026-10-20 entry), while `.scratch/` is provably invisible to the outer repo's `status`/`add` and the nested repo is fully independent in hooks/config/branch/worktrees; cited by the Phase 4.5 dogfood (2026-10-21 entry), and Phase 5.4's dogfood prompt now cites it too. — Alternatives: real micro-change in-tree.

## Open questions

- Should a spike finding that invalidates `architecture.md` be a hard stop condition for the phase, or reported as a deviation/risk (current choice: deviation, lead surfaces it)? Revisit in Feedback.
- Is `Status: Approved` in `acceptance.md` enough, or should `phase-reviewer` also require the approval date to postdate the last scenario edit? Current choice: reviewer diff-detects edits instead; date is informational.
- How should the phase gate on a Spike result of `INCONCLUSIVE` — proceed, defer dependent tasks, or fail the phase — and does a *load-bearing* spike (one a later task's approach depends on) gate differently than an exploratory one? Current choice: none defined (lead surfaces it as a deviation). Revisit before any load-bearing spike ships.
