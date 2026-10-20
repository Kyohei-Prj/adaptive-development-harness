---
name: planning-docs
description: Templates and conventions for the architecture, spec, implementation-plan, feedback-log, and findings docs, including task type tag rules for the tdd/smoke/spike task types and phase mode tag rules for the sdd/interactive/autorun modes
---
## File locations
docs/<slug>/architecture.md
docs/<slug>/spec.md
docs/<slug>/implementation-plan.md
docs/<slug>/feedback-log.md
docs/<slug>/phase-branches.md   (created by `lead`, not `planner` — see below)
docs/<slug>/findings.md         (appended by the spike's `task-implementer`, not `planner` — see below)

`<slug>` = short kebab-case id agreed during Planning.

## Task type tags

Every task in `implementation-plan.md` MUST carry a `[type: ...]` tag.
The `task-implementer` subagent uses it to choose its testing approach.

| Tag | Use when the task involves |
|---|---|
| `[type: tdd]` | Business logic, validation, algorithms, data transforms, domain rules, service layers, stateful or error-prone operations |
| `[type: smoke]` | Scaffolding, boilerplate, config files, directory setup, dependency installs, DB migrations, static assets, simple wiring with no domain logic |
| `[type: spike]` | Time-boxed investigation of an open question — feasibility, unknown tech, risky design calls — producing a durable finding; throwaway code stays in `.scratch/` |

A `[type: spike]` task carries `(question: ..., exit: ...)` instead of
`(acceptance: ...)`; its deliverable is a `findings.md` entry, not shipped code.

**Defaulting:** when genuinely uncertain, use `[type: tdd]`.
The implementer will also self-classify if the tag is absent, but an
explicit tag at planning time is more reliable.

Tags stack: `[type: tdd] [parallel-with: 1.1]` is valid.

## Phase mode tags

Every phase in `implementation-plan.md` MAY carry a `[mode: ...]` tag.
Unlike task-level `[type: …]` tags, `[mode: …]` is **phase-level**: one tag
per phase, written on the `## Phase N — <name>` heading line (or immediately
under it), mirroring how `[type: …]` tags sit on task lines. Modes say *who*
implements the phase — orthogonal to the task-level `[type: …]` vocabulary.

| Tag | Who implements | What happens |
|---|---|---|
| `[mode: sdd]` | delegated `task-implementer` subagents | default — `/implement-phase` delegates as it always has |
| `[mode: interactive]` | a human pair loop | `/implement-phase*` refuse to delegate and point to `/interactive` |
| `[mode: autorun]` | the unattended run | `/autorun` / `scripts/autorun.sh`; suitable when "done" is machine-checkable |

**Absent tag = `[mode: sdd]`** — backward compatible with every plan written
before mode tags existed: an untagged phase runs the existing delegated SDD
flow unchanged.

`/interactive`, the interactive-mode entry point `[mode: interactive]`
points to, is added in a later phase of this work — until it ships, the
refusal stands on its own and the pointer is forward-looking.

## Editing rules
- During Feedback, make targeted edits — never regenerate a doc from scratch.
- Always append a dated entry to feedback-log.md when architecture/spec/plan
  changes as a result of phase feedback.

## Templates

Each template below sits in a fenced `markdown` code block: copy the block
verbatim into the new doc, then replace the `...` placeholders. One fence
style for every template here — don't mix fenced and unfenced.

### architecture.md
```markdown
# Architecture — <slug>

## Overview
One paragraph: what this is and why.

## Components
| Component | Responsibility | Tech |
|---|---|---|
| | | |

## Data flow
Describe how data moves through the system (diagram-as-text is fine).

## Data model
Key entities/tables and relationships.

## External dependencies
APIs, libraries, services this relies on.

## Key decisions & trade-offs
- Decision: ... — Why: ... — Alternatives considered: ...

## Open questions
Anything still uncertain, to revisit during Feedback.
```

---

### spec.md
```markdown
# Specification — <slug>

## Goal
What success looks like, in one or two sentences.

## In scope
- ...

## Out of scope
- ...

## Functional requirements
1. ...

## Non-functional requirements
- Performance:
- Security:
- Reliability:

## Acceptance criteria
- [ ] ...

## Constraints / assumptions
- ...
```

---

### implementation-plan.md
```markdown
# Implementation Plan — <slug>

## Pattern Record

<!-- The blueprint's four questions, answered once per slug at Planning.
     The answers steer the plan and together fix every phase's [mode: …]
     tag; tag semantics: the "Phase mode tags" section of this skill. -->

1. **How well do I know *what* to build?** ... (Low → prototype or grill; High → spec)
2. **How well do I know *how*?** ... (Low → spike or tracer bullet; High → vertical slices)
3. **How expensive is a mistake?** ... (High → acceptance tests, human gates; Low → more autonomy)
4. **Is "done" machine-checkable?** ... (Yes → TDD, autonomous run; No → human in the loop)

**Per-phase mode rationale** — one line per phase, naming its `[mode: …]`
tag and why the answers above chose it:

- Phase 1 `[mode: sdd]`: ...
- Phase 2 `[mode: interactive]`: ...
- Phase 3 `[mode: autorun]`: ...

## Phase 1 — <name> [mode: sdd]
**Goal:** ...
**Tasks:**
- [ ] Task 1.1: ... (acceptance: ...) [type: tdd]
- [ ] Task 1.2: ... (acceptance: ...) [type: smoke]
- [ ] Task 1.3: ... (acceptance: ...) [type: tdd] [parallel-with: 1.2]
- [ ] Task 1.4: ... (question: ..., exit: ...) [type: spike]

## Phase 2 — <name> [mode: interactive]
**Goal:** ...
**Tasks:**
- [ ] Task 2.1: ... (acceptance: ...) [type: smoke]
- [ ] Task 2.2: ... (acceptance: ...) [type: tdd]

## Phase N — <name>
<!-- no tag on this heading = `[mode: sdd]` — the default -->
**Goal:** ...
**Tasks:**
- [ ] Task N.1: ... (acceptance: ...) [type: tdd]

## Dependencies between phases
Note anything that must complete before later phases can start.
```

---

### feedback-log.md
```markdown
# Feedback Log — <slug>

<!-- Append one entry per reviewed phase. Never delete prior entries. -->

## YYYY-MM-DD — Phase <n> review
**Issues found:**
- ...

**Deferred issues (confirmed but not fixed this round):**
- ...

**Risks for future phases:**
- ...

**Doc changes applied:**
- architecture.md: ...
- spec.md: ...
- implementation-plan.md: ...
```

---

### phase-branches.md

Not written by `planner` — `lead` creates this file's header the first
time `/implement-phase` runs for a slug (Phase 1), and appends one row per
phase after that. It exists so `phase-reviewer` never has to guess or infer
a phase's diff baseline from branch-naming conventions — the actual base
branch, captured at the moment each phase branch was created, is recorded
here instead.

```markdown
# Phase Branches — <slug>

| Phase | Branch | Base |
|---|---|---|
| 1 | feature/<slug>-phase-1 | main |
| 2 | feature/<slug>-phase-2 | feature/<slug>-phase-1 |
```

"Base" is whatever branch was checked out immediately before `lead` ran
`git checkout -b feature/<slug>-phase-<n>` — captured programmatically
(`git branch --show-current` right before the checkout), never assumed
from a naming pattern. This file is committed as part of each phase's
commit, so it survives across sessions.

---

### findings.md

Not written by `planner` — the spike's `task-implementer` appends one dated
entry per `[type: spike]` task as its end-of-task step and commits it.
Append-only: one entry per spike, prior entries never rewritten.

```markdown
# Findings — <slug>

## YYYY-MM-DD — Task <n.m>
**Question:** ...

**Approach:** ...

**Answer:** ...

**Decision:** ...
```
