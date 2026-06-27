---
name: planning-docs
description: Templates and conventions for the architecture, spec, implementation-plan, and feedback-log docs, including task type tag rules for the TDD/Smoke testing system
---
## File locations
docs/<slug>/architecture.md
docs/<slug>/spec.md
docs/<slug>/implementation-plan.md
docs/<slug>/feedback-log.md

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

**Risks for future phases:**
- ...

**Doc changes applied:**
- architecture.md: ...
- spec.md: ...
- implementation-plan.md: ...
