# AI-Driven Development Workflow

A lightweight, three-stage workflow built on top of [OpenCode](https://opencode.ai/docs) that takes an idea from concept to working code. A human and AI agent collaborate through **Planning → Implementation → Feedback**, with context isolation enforced through sub-agent delegation and a structured document trail committed alongside the code.

---

## Table of Contents

- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [The Three Stages](#the-three-stages)
  - [Stage 1 — Planning](#stage-1--planning)
  - [Stage 2 — Implementation](#stage-2--implementation)
  - [Stage 3 — Feedback](#stage-3--feedback)
- [Agents Reference](#agents-reference)
- [Commands Reference](#commands-reference)
- [Task Type System](#task-type-system)
- [Document Templates](#document-templates)
- [Full Worked Example](#full-worked-example)
- [Tips & Conventions](#tips--conventions)
- [Troubleshooting](#troubleshooting)

---

## How It Works

```
User idea
    │
    ▼
┌─────────────────────────────────────────────┐
│  Stage 1 · PLANNING          (planner agent)│
│                                             │
│  One clarifying question at a time          │
│  until requirements are clear.              │
│                                             │
│  Output: architecture.md                    │
│          spec.md                            │
│          implementation-plan.md             │
│          feedback-log.md (empty)            │
└──────────────────┬──────────────────────────┘
                   │  docs committed to git
                   ▼
┌─────────────────────────────────────────────┐
│  Stage 2 · IMPLEMENTATION       (lead agent)│
│                                             │
│  Phase by phase.                            │
│  Each task → task-implementer subagent      │
│  TDD path or Smoke path per task type tag.  │
│                                             │
│  Output: working code + passing tests       │
└──────────────────┬──────────────────────────┘
                   │  phase committed to git
                   ▼
┌─────────────────────────────────────────────┐
│  Stage 3 · FEEDBACK             (lead agent)│
│                                             │
│  phase-reviewer inspects the git diff.      │
│  Classifies issues as blocking/non-blocking.│
│  Checks testing compliance per task tag.    │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │  For each confirmed issue or risk:      │ │
│ │  issue-resolver fixes it (TDD/Smoke)    │ │
│ │  lead reports result before next        │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│  doc-updater applies approved doc changes.  │
│                                             │
│  Output: fixed code + updated docs          │
│          + feedback-log entry               │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
          Repeat for next phase
```

**Key design principles:**

- **Context hygiene** — the primary (lead) session never holds diffs. All file edits happen inside sub-agent child sessions. The lead only receives task summaries.
- **Explicit over inferred** — task type (`[type: tdd]` / `[type: smoke]`), parallelism (`[parallel-with: X]`), and phase goals are written into the plan at planning time, not decided at runtime. Reviewer findings are classified as blocking or non-blocking at review time, not interpreted by the lead.
- **Document-first** — architecture, spec, and implementation plan are the source of truth throughout. They evolve via the Feedback stage, never silently.
- **Minimal footprint** — 5 agent files, 3 command files, 1 skill. No plugins, no MCP servers, no external services.

---

## Prerequisites

- [OpenCode](https://opencode.ai/docs) installed and configured
- Git initialized in your project root (`git init`)
- A configured AI provider in OpenCode (Anthropic, OpenAI, etc.)

---

## Directory Structure

```
your-project/
├── AGENTS.md                            # Shared workflow rules, inherited by all agents
├── .opencode/
│   ├── agents/
│   │   ├── planner.md                   # Primary — Planning stage
│   │   ├── lead.md                      # Primary — Implementation & Feedback
│   │   ├── task-implementer.md          # Subagent — executes one planned coding task
│   │   ├── phase-reviewer.md            # Subagent — classifies issues, read-only review
│   │   ├── issue-resolver.md            # Subagent — fixes one issue or risk (blocking, non-blocking, future-phase)
│   │   └── doc-updater.md               # Subagent — applies approved doc edits
│   ├── commands/
│   │   ├── plan.md                      # /plan <idea>
│   │   ├── implement-phase.md           # /implement-phase <n> <slug>
│   │   └── review-phase.md              # /review-phase <n> <slug>
│   └── skills/
│       └── planning-docs/
│           └── SKILL.md                 # Doc templates + task type tag rules
└── docs/
    ├── _templates/                      # Source templates (optional reference copies)
    └── <slug>/                          # One folder per feature/fix/project
        ├── architecture.md
        ├── spec.md
        ├── implementation-plan.md
        └── feedback-log.md
```

`<slug>` is a short kebab-case name agreed with the planner at the start of every planning session (e.g. `todo-app`, `csv-export`, `fix-login-race`). It connects docs, git branches, and commits for a single unit of work.

---

## The Three Stages

### Stage 1 — Planning

**Agent:** `planner`  
**Trigger:** `/plan <headline description of the idea>`  
**Output:** four committed docs under `docs/<slug>/`

The planner asks one clarifying question at a time until it has enough information to write:

- `architecture.md` — components, data model, data flow, key decisions
- `spec.md` — functional and non-functional requirements, acceptance criteria, in/out of scope
- `implementation-plan.md` — phased task list, each task tagged `[type: tdd]` or `[type: smoke]`
- `feedback-log.md` — empty log, ready to receive entries during Feedback

Keep the initial `/plan` argument to a headline (one line). Elaborate through the planner's follow-up questions.

**Commit before moving on:**

```bash
git add docs/<slug>/
git commit -m "plan: <slug> — initial planning docs"
```

Then close the planner session before starting Implementation. The `lead` agent needs a fresh primary session with no planner context.

---

### Stage 2 — Implementation

**Agent:** `lead` (delegates to `task-implementer` subagent)  
**Trigger:** `/implement-phase <n> <slug>`  
**Output:** working code with tests, committed after the phase is done

`lead` reads the phase's task list and delegates each task to `task-implementer` via the Task tool — one task per sub-agent invocation, passing the task description, acceptance criteria, `[type: ...]` tag, and relevant file pointers.

`task-implementer` chooses its path based on the tag:

- `[type: tdd]` → write failing tests → implement → green
- `[type: smoke]` → implement → run a minimal smoke check

Tasks marked `[parallel-with: X]` in the plan may be delegated simultaneously. All others run sequentially.

`lead` compiles a phase summary from each task-implementer's summary block and presents it to you before declaring the phase ready for review.

`lead` then commits the completed phase automatically (`feat(<slug>): phase <n> complete`). The reviewer uses this commit as its diff baseline.

---

### Stage 3 — Feedback

**Agent:** `lead` (delegates to `phase-reviewer` → `issue-resolver` per blocking issue → `doc-updater`)  
**Trigger:** `/review-phase <n> <slug>`  
**Output:** fixed code + updated docs + a new entry in `feedback-log.md`

`phase-reviewer` inspects the actual git diff and test results for the phase. It reports in order:

1. **Testing compliance** — did TDD tasks produce tests? Did smoke tasks run a check?
2. **Blocking issues** — each with affected file(s) and a one-sentence reason it must be resolved before the next phase starts
3. **Non-blocking findings** — tech debt, minor risks, improvements that don't prevent continuing
4. **Risks for future phases** — architecture drift, scope creep, concerns about upcoming phases
5. **Suggested doc edits** — concrete, targeted changes to the affected docs

`lead` presents the full report and asks you to confirm which items to resolve. For each confirmed item — whether blocking, non-blocking, or a future-phase risk — `issue-resolver` is delegated one at a time — sequentially, never in parallel — and reports back with the same summary format as `task-implementer`. If any fix reports FAIL, `lead` surfaces the root cause and waits for your direction before moving on.

Once all confirmed items are resolved, `lead` asks whether to apply the doc updates. On your confirmation, `doc-updater` makes the targeted edits and appends a dated entry to `feedback-log.md` covering both the original findings and the resolutions applied. `lead` then commits all fixes and doc updates automatically (`review(<slug>): phase <n> fixes and doc updates`).

When all phases are complete, merge the feature branch to main yourself.

Repeat **Implementation → Feedback** for each phase until the plan is complete.

---

### Automated Full Run (optional)

**Trigger:** `/autorun <slug>`

If you trust the plan and want to skip the per-phase checkpoints, `/autorun` runs the entire Implementation → Feedback cycle for every phase in one go. `lead` iterates through all phases in order; for each phase it:

1. Creates the `feature/<slug>-phase-N` branch
2. Delegates all tasks to `task-implementer` (same TDD / Smoke rules apply)
3. Commits the completed phase
4. Delegates review to `phase-reviewer`
5. Resolves **all** issues and risks (blocking, non-blocking, and future-phase risks) via `issue-resolver` (sequentially, no confirmation)
6. Delegates doc updates to `doc-updater`
7. Commits fixes and doc updates
8. Reports a per-phase progress summary, then moves to the next phase

The only times `lead` stops and waits for you are:
- A `task-implementer` reports **FAIL** — it cannot proceed until you decide whether to fix, skip, or adjust the task.
- An `issue-resolver` reports **FAIL** — it cannot proceed until you decide how to handle the unresolved blocker.

When all phases are complete, `lead` reports a full run summary and reminds you to merge to main.

Use `/implement-phase` and `/review-phase` individually when you want to inspect or adjust things between phases; use `/autorun` when you want to let the agent go end-to-end.

---

## Agents Reference

| Agent | Mode | Role | Permissions |
|---|---|---|---|
| `planner` | primary | Asks questions, writes initial docs | edit: allow · bash: deny · webfetch: ask |
| `lead` | primary | Orchestrates, delegates, summarizes | edit/bash: ask · task: whitelisted 4 subagents only |
| `task-implementer` | subagent | Implements one planned task (TDD or Smoke) | edit/bash/webfetch: allow · task: deny |
| `phase-reviewer` | subagent | Read-only review, classifies blocking/non-blocking issues, compliance check | edit: deny · bash: read-only git + test commands only |
| `issue-resolver` | subagent | Fixes one issue or risk found by reviewer — blocking, non-blocking, or future-phase risk (TDD or Smoke) | edit/bash/webfetch: allow · task: deny |
| `doc-updater` | subagent | Applies approved doc edits after issues are resolved | edit: allow (docs only) · bash: deny |

`lead` is locked to its four named subagents — it cannot invoke any other subagent. Neither `task-implementer` nor `issue-resolver` can spawn further subagents, preventing unbounded delegation chains.

---

## Commands Reference

| Command | Agent invoked | Arguments | Purpose |
|---|---|---|---|
| `/plan <idea>` | `planner` | Free-text headline | Start a Planning session |
| `/implement-phase <n> <slug>` | `lead` | Phase number, slug | Implement one phase by delegating tasks |
| `/review-phase <n> <slug>` | `lead` | Phase number, slug | Review a phase and update docs |
| `/autorun <slug>` | `lead` | Slug | Implement **all** phases and run Feedback for each automatically |

---

## Task Type System

Every task in `implementation-plan.md` carries an explicit type tag that controls which path `task-implementer` takes.

### `[type: tdd]`

For anything involving business logic, domain rules, or non-trivial behaviour.

```
Red → Green → (minimal refactor) → commit
```

The implementer writes failing tests *first*, then implements to make them pass. If tests are still red after two focused attempts, it stops and reports rather than hacking around the failure.

Use for: validation logic, algorithms, API handlers, service layers, data transforms, error-handling paths, stateful operations.

### `[type: smoke]`

For structural or wiring work where correctness means "it assembled correctly", not "it behaves correctly under all conditions".

```
Implement → run one minimal smoke check → commit
```

The smoke check can be as simple as a Python import, a `curl` healthcheck, or a file existence test. Its purpose is to confirm the scaffolding didn't break the build, not to exercise logic.

Use for: project scaffolding, directory structure, config files, dependency installs, DB migrations, static assets, environment wiring.

### Stacking tags

Tags compose:

```
- [ ] Task 2.3: Set up auth middleware (acceptance: ...) [type: tdd] [parallel-with: 2.2]
```

### Classification fallback

If a task has no type tag, `task-implementer` classifies it using the same heuristics (TDD when in doubt). However, explicit tags at planning time are more reliable than runtime inference — the planner should never leave a task untagged.

---

## Document Templates

All templates are embedded in `.opencode/skills/planning-docs/SKILL.md` and are available to the `planner` and `doc-updater` agents on demand. Abbreviated structure:

**`architecture.md`** — Overview · Components table · Data flow · Data model · External dependencies · Key decisions & trade-offs · Open questions

**`spec.md`** — Goal · In scope / Out of scope · Functional requirements · Non-functional requirements · Acceptance criteria · Constraints & assumptions

**`implementation-plan.md`** — One section per phase, each with a goal and a task list. Every task: `- [ ] Task N.M: <description> (acceptance: <criteria>) [type: tdd|smoke]`

**`feedback-log.md`** — Append-only. One dated entry per reviewed phase: issues found, risks for future phases, doc changes applied.

---

## Full Worked Example

**Scenario:** Build a simple ToDo web app — Python/FastAPI backend, TypeScript/TailwindCSS/Next.js frontend, SQLite, runs locally.

### Step 1 — Open OpenCode and initialize

```bash
cd todo-project
git init
opencode
```

Copy the agent, command, and skill files into `.opencode/` and `AGENTS.md` into the project root as described in [Setup](#setup).

### Step 2 — Start planning

```
/plan ToDo web app — FastAPI backend, Next.js + TailwindCSS frontend
```

The `planner` agent responds:

> I'll use the slug `todo-app`. Does that work?

```
Yes, that works.
```

> What database would you like to use?

```
SQLite — this runs locally.
```

> Should the app run as a containerized service, or just as local processes?

```
Local processes, no containers.
```

> Do you need user authentication, or is this single-user?

```
Single-user, no auth needed.
```

> I have enough to proceed. Writing docs now...

The planner writes `docs/todo-app/architecture.md`, `spec.md`, `implementation-plan.md`, and `feedback-log.md`.

Review them. Request any wording changes in plain language ("make Phase 1 focus only on the database layer"). Then:

```bash
git add docs/todo-app/
git commit -m "plan: todo-app — initial planning docs"
```

Close the planner session.

### Step 3 — Implement Phase 1

```
/implement-phase 1 todo-app
```

`lead` reads Phase 1's tasks from `docs/todo-app/implementation-plan.md`, for example:

```
- [ ] Task 1.1: Define SQLite schema and create DB init script (acceptance: tables exist on startup) [type: smoke]
- [ ] Task 1.2: Implement Todo CRUD service layer (acceptance: create/read/update/delete all work correctly) [type: tdd]
- [ ] Task 1.3: Implement FastAPI route handlers for /todos (acceptance: all endpoints return correct status codes) [type: tdd]
```

`lead` delegates Task 1.1 to `task-implementer` (Smoke path: creates schema, runs `python -c "from app.db import init_db; init_db()"`). Then Task 1.2 (TDD: writes `test_todo_service.py`, runs pytest red → implements → green). Then Task 1.3 (TDD: writes route tests → implements → green).

`lead` compiles and presents the phase summary:

```
Task 1.1 — Smoke — PASS (python init_db import check)
Task 1.2 — TDD   — PASS (pytest test_todo_service.py — 8 tests)
Task 1.3 — TDD   — PASS (pytest test_routes.py — 12 tests)
Deviations: none
```

`lead` then commits automatically: `feat(todo-app): phase 1 complete`.

### Step 4 — Review Phase 1

```
/review-phase 1 todo-app
```

`lead` delegates to `phase-reviewer`, which inspects the git diff and test results and reports:

```
Testing compliance:
  Task 1.1 [smoke] — smoke check present ✓
  Task 1.2 [tdd]   — 8 new tests, all passing ✓
  Task 1.3 [tdd]   — 12 new tests, all passing ✓

Blocking issues:
  - Issue: DELETE /todos/{id} returns 200 instead of 204
    Affected: app/routes/todos.py
    Blocking because: violates spec.md acceptance criterion
      "DELETE returns 204 No Content"

Non-blocking findings:
  - The Todo response schema omits a `created_at` field the frontend
    may need for sorting. Low risk for Phase 2 but worth tracking.

Risks for future phases:
  - If created_at is added later it will be a breaking API change.

Suggested doc edits:
  implementation-plan.md: Add task to Phase 2 for created_at in response schema
```

`lead` presents this and asks:

> There are 3 items to resolve: 1 blocking issue, 1 non-blocking finding, and 1 future-phase risk. Which would you like to address now?

```
Resolve all of them.
```

`lead` delegates to `issue-resolver` for each item, one at a time. First the blocking issue — `issue-resolver` applies the TDD path, writes a failing test asserting 204, fixes the route handler, runs pytest green:

```
Approach:       TDD
Issue fixed:    DELETE /todos/{id} now returns 204 No Content
Files changed:  app/routes/todos.py, tests/test_routes.py
Tests written:  tests/test_routes.py : test_delete_todo_returns_204
Test result:    PASS (pytest tests/test_routes.py::test_delete_todo_returns_204)
Deviations:     none
Residual risks: none
```

`lead` reports the resolution and asks:

> Blocking issue resolved. Apply the doc updates?

```
Yes, apply them.
```

`doc-updater` makes the targeted edits and appends a single dated entry to `feedback-log.md` covering both the original findings and the fix applied.

### Step 5 — Continue

```
/implement-phase 2 todo-app
/review-phase 2 todo-app
/implement-phase 3 todo-app
...
```

---

## Additional Tools

**rtk** output commpression tool
```bash
cargo install --git https://github.com/rtk-ai/rtk
rtk init -g --opencode
```

**opencode-dcp** conversation context manager
```bash
opencode plugin @tarquinen/opencode-dcp@latest --global
```

---

## Tips & Conventions

**Keep `/plan` arguments to a headline.** One line sets the topic; the planner's questions fill in the rest. Long arguments with special characters can confuse the command parser.

**Commit once manually:** after Planning (the four docs). Everything after that — branching, phase commits, and review commits — is handled by `lead` automatically. Your only other git responsibility is merging the feature branch to main when all phases are done.

**Close the planner session before implementing.** The `lead` agent needs a fresh primary session. Running `/implement-phase` inside a planner session uses an agent with `bash: deny`, which will block every sub-agent delegation.

**Tagging is the planner's job, not the implementer's.** The `task-implementer` has a classification fallback, but it's less reliable than an explicit tag. Push back on the planner if it produces tasks without tags.

**Blocking vs non-blocking is the reviewer's call, not yours.** The `phase-reviewer` classifies issues and risks before you see them. You decide which items to confirm for resolution — but you don't need to triage the raw list yourself.

**Issue resolution is always sequential.** `issue-resolver` runs one fix at a time. If you have three items to resolve, expect three resolution cycles before the doc update. This is intentional — each fix may affect the next.

**Use `@explore` or `@scout` for quick lookups.** If you need to check something in the codebase during Implementation without spinning up a `task-implementer`, the built-in `@explore` and `@scout` subagents are available and lighter-weight.

**One slug per unit of work.** A slug connects docs, git branches, and commit messages. Using the same slug throughout (`git checkout -b feat/todo-app`, `git commit -m "feat(todo-app): ..."`) keeps the history readable.

**Docs evolve; don't regenerate them.** The `doc-updater` makes targeted edits. If a doc needs a large structural change, do it in a Feedback step with your explicit confirmation — never ask any agent to rewrite a doc from scratch mid-project.

---

## Troubleshooting

**`/implement-phase` does nothing or errors on bash commands**  
You're likely still in the planner session (`bash: deny`). Close it and start a new session, then re-run the command.

**`phase-reviewer` reports "unable to determine diff baseline"**  
The phase wasn't committed before running `/review-phase`. Run `git add -A && git commit -m "feat(<slug>): phase <n> complete"` then re-run.

**`task-implementer` reports FAIL and stops**  
This is the intended behavior. Read the root cause in the summary, decide whether to fix the failing test, adjust the task description, or update the plan. Then re-run `/implement-phase` for that phase — `lead` will re-delegate the failed task.

**`issue-resolver` reports FAIL and stops**  
Same principle. Read the root cause, decide whether the issue description was ambiguous or the fix is genuinely hard. You can rephrase the issue and ask `lead` to retry, defer it (treat as non-blocking for now and note it in the feedback log), or fix it manually and tell `lead` to proceed.

**A task has no `[type: ...]` tag**  
`task-implementer` will self-classify (defaulting to TDD when uncertain) and state its classification at the start of its response. You can correct it by responding to the lead with the right type before the next task is delegated. Fix the tag in `implementation-plan.md` for the record.

**The `lead` agent tries to edit files directly**  
Remind it: `Delegate this to task-implementer via the Task tool. Do not edit files in this session.` The `edit: ask` permission means it will prompt you first — decline and redirect.

**Docs have diverged from the code**  
Run `/review-phase <last-completed-n> <slug>` even if you skipped it earlier. The `phase-reviewer` will surface the divergence and `doc-updater` will reconcile it.
