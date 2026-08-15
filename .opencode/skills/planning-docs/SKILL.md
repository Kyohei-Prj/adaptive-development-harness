---
name: planning-docs
description: Templates and conventions for the architecture, spec, implementation-plan, and feedback-log docs, including task type tag rules for the TDD/Smoke testing system
---
## File locations
docs/<slug>/architecture.md
docs/<slug>/spec.md
docs/<slug>/implementation-plan.md
docs/<slug>/feedback-log.md
docs/<slug>/phase-branches.md   (created by `lead`, not `planner` — see below)

`<slug>` = short kebab-case id agreed during Planning.

## Task type tags

Every task in `implementation-plan.md` MUST carry a `[type: ...]` tag.
The `task-implementer` subagent uses it to choose its testing approach.

| Tag | Use when the task involves |
|---|---|
| `[type: tdd]` | Business logic, validation, algorithms, data transforms, domain rules, service layers, stateful or error-prone operations |
| `[type: smoke]` | Scaffolding, boilerplate, config files, directory setup, dependency installs, DB migrations, static assets, simple wiring with no domain logic |

**Defaulting:** when genuinely uncertain, use `[type: tdd]`.
The implementer will also self-classify if the tag is absent, but an
explicit tag at planning time is more reliable.

Tags stack: `[type: tdd] [parallel-with: 1.1]` is valid.

## Editing rules
- During Feedback, make targeted edits — never regenerate a doc from scratch.
- Always append a dated entry to feedback-log.md when architecture/spec/plan
  changes as a result of phase feedback.

## Templates

### architecture.md
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

---

### spec.md
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

---

### implementation-plan.md
# Implementation Plan — <slug>

## Phase 1 — <name>
**Goal:** ...
**Tasks:**
- [ ] Task 1.1: ... (acceptance: ...) [type: tdd]
- [ ] Task 1.2: ... (acceptance: ...) [type: smoke]
- [ ] Task 1.3: ... (acceptance: ...) [type: tdd] [parallel-with: 1.2]

## Phase 2 — <name>
**Goal:** ...
**Tasks:**
- [ ] Task 2.1: ... (acceptance: ...) [type: smoke]
- [ ] Task 2.2: ... (acceptance: ...) [type: tdd]

## Phase N — <name>
**Goal:** ...
**Tasks:**
- [ ] Task N.1: ... (acceptance: ...) [type: tdd]

## Dependencies between phases
Note anything that must complete before later phases can start.

---

### feedback-log.md
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
