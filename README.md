# AI-Driven Development Workflow

A lightweight, four-stage workflow built on top of [OpenCode](https://opencode.ai/docs) that takes an idea from concept to working code. A human and AI agent collaborate through **Grill → Planning → Implementation → Feedback**, with context isolation enforced through sub-agent delegation and a structured document trail committed alongside the code.

The Grill stage, the vertical-slice phase structure, the reviewer's
fresh-context + stronger-model setup, and the push/pull split on coding
standards are adapted from Matt Pocock's public AI-coding workflow
(alignment interviews before planning docs, tracer-bullet phases,
never-review-in-the-implementer's-context). See [Tips & Conventions](#tips--conventions) for where each idea shows up and why.

---

## Table of Contents

- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [The Stages](#the-stages)
  - [Stage 0 — Grill (optional)](#stage-0--grill-optional-recommended-for-anything-non-trivial)
  - [Stage 1 — Planning](#stage-1--planning)
  - [Stage 2 — Implementation](#stage-2--implementation)
  - [Stage 3 — Feedback](#stage-3--feedback)
- [Maintenance Commands](#maintenance-commands)
- [doctor.sh — static self-check suite](#doctorsh--static-self-check-suite-harness-repo-only)
- [Agents Reference](#agents-reference)
- [Commands Reference](#commands-reference)
- [Task Type System](#task-type-system)
- [Document Templates](#document-templates)
- [Shared Mechanics](#shared-mechanics)
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
│  Stage 0 · GRILL (optional)    (grill agent)│
│                                             │
│  Pure alignment interview, one question     │
│  at a time. No docs, no code — just a       │
│  shared design concept.                     │
│                                             │
│  Output: design concept summary (ephemeral) │
└──────────────────┬──────────────────────────┘
                   │  close session, start fresh
                   ▼
┌─────────────────────────────────────────────┐
│  Stage 1 · PLANNING          (planner agent)│
│                                             │
│  Transcribes the aligned design concept     │
│  into docs. Phases are vertical slices —    │
│  each crosses every layer to deliver one    │
│  thin, reviewable, end-to-end behavior.     │
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
│  A path per task-type tag.                  │
│                                             │
│  Output: working code + passing tests       │
└──────────────────┬──────────────────────────┘
                   │  phase committed to git
                   ▼
┌─────────────────────────────────────────────┐
│  Stage 3 · FEEDBACK             (lead agent)│
│                                             │
│  phase-reviewer diffs against the branch's  │
│  fork point. Classifies blocking/non-       │
│  blocking. Checks testing compliance.       │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  For each confirmed blocking/       │    │
│  │  non-blocking issue: issue-resolver │    │
│  │  fixes it. Risks for                │    │
│  │  future phases are logged, not      │    │
│  │  fixed — they're speculative.       │    │
│  └─────────────────────────────────────┘    │
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

- **Alignment before artifacts** — `grill` interviews you about the design with no doc-writing reward in sight, so it can't rush the interview to get to a deliverable. `planner` only starts once that alignment exists (or flags that it doesn't). Splitting these into separate agents/sessions is deliberate: an agent that can see the next step tends to shortcut the current one.
- **Vertical slices over horizontal layers** — `implementation-plan.md` phases are structured to cross every layer (schema → service → API → UI) and produce something reviewable after each phase, not "all the schema, then all the API, then all the UI."
- **Context hygiene / smart zone** — the primary (lead) session never holds diffs; all content edits happen inside sub-agent child sessions (lead's own edits are the bookkeeping exception only: the `phase-branches.md` rows and `implementation-plan.md` checkbox flips), and the lead only receives task summaries. More generally, keep any single session under ~100K tokens of practical use — start fresh between Grill/Plan/Implement rather than letting one session run the whole feature. See [Tips & Conventions](#tips--conventions).
- **Reviewer runs dumber-proof** — `phase-reviewer` always runs in a fresh subagent context (never appended to the implementer's session) and can be pinned to a stronger model than the implementer, so review reasoning isn't capped by whatever context state the implementer left behind.
- **Push vs pull standards** — coding standards are pulled on demand by `task-implementer`/`issue-resolver` (loaded only if they're uncertain) but pushed inline into `phase-reviewer` (always enforced, since the reviewer is the one gate that must not skip them).
- **Explicit over inferred** — task type (`[type: tdd]` / `[type: smoke]` / `[type: spike]`), parallelism (`[parallel-with: X]`), and phase goals are written into the plan at planning time, not decided at runtime. Reviewer findings are classified as blocking or non-blocking at review time, not interpreted by the lead.
- **Mechanics live in one place** — phase-branch setup, worktree-isolated parallel execution, and issue-resolution delegation are the same underlying procedures whether triggered by `/implement-phase`, `/autorun`, or the headless `*-auto` commands. They're defined once in the `phase-lifecycle` skill and referenced everywhere, not copy-pasted per command — six near-identical copies is exactly the situation that lets one silently drift from the rest.
- **Document-first, but not permanent** — architecture, spec, and implementation plan are the source of truth during a unit of work. They evolve via the Feedback stage, never silently — and once a slug's phases are all merged, consider archiving `docs/<slug>/` rather than leaving it live to go stale and mislead a future session.
- **Minimal footprint, not minimal correctness** — 10 agent files, 12 command files, 4 skills, 2 scripts. More surface area than a bare-bones setup, but every piece exists because a leaner version of this repo actually hit the problem it solves (a guessed diff baseline, a copy-pasted procedure that drifted, an unattended session with no destructive-command guardrail). No plugins, no MCP servers required beyond what you already had.

---

## Prerequisites

- [OpenCode](https://opencode.ai/docs) installed and configured
- Git initialized in your project root (`git init`)
- A configured AI provider in OpenCode (Anthropic, OpenAI, etc.)
- `jq` on `PATH` if you plan to use `scripts/autorun.sh` (`apt install jq` / `brew install jq`) — required to correctly parse `opencode run --format json`'s event stream; the script checks for it and fails fast with a clear message if it's missing

---

## Directory Structure

```
your-project/
├── AGENTS.md                            # Shared workflow rules, inherited by all agents
├── .gitignore                           # Keeps the harness's ephemeral artifacts (.worktrees/, .scratch/, **/autorun.log) out of commits
├── .worktrees/                          # Ephemeral — per-task git worktrees for [parallel-with] groups (gitignored — in the shipped `.gitignore`)
├── .scratch/                            # Ephemeral — agent scratch space, kept inside the project so it never needs the external_directory permission (gitignored — in the shipped `.gitignore`)
├── .opencode/
│   ├── opencode.json                    # Shipped config carries only `$schema` + `watcher.ignore` — anything machine-specific belongs in your global OpenCode config
│   ├── agents/
│   │   ├── grill.md                     # Primary — Grill (alignment) stage
│   │   ├── planner.md                   # Primary — Planning stage
│   │   ├── lead.md                      # Primary — Implementation & Feedback
│   │   ├── pair.md                      # Primary — interactive pair loop (human-approved steps)
│   │   ├── task-implementer.md          # Subagent — executes one planned coding task
│   │   ├── phase-reviewer.md            # Subagent — classifies issues, read-only review
│   │   ├── issue-resolver.md            # Subagent — fixes one blocking or non-blocking issue
│   │   ├── doc-updater.md               # Subagent — applies approved doc edits
│   │   ├── architecture-reviewer.md     # Subagent — whole-codebase architecture scan, read-only
│   │   └── characterizer.md             # Subagent — pins one target module's CURRENT behavior with characterization tests
│   ├── commands/
│   │   ├── grill.md                     # /grill <idea>
│   │   ├── plan.md                      # /plan <idea or grill summary>
│   │   ├── implement-phase.md           # /implement-phase <n> <slug>
│   │   ├── review-phase.md              # /review-phase <n> <slug>
│   │   ├── interactive.md               # /interactive <slug|new>
│   │   ├── characterize.md              # /characterize <path>
│   │   ├── autorun.md                   # /autorun <slug> (in-chat, one checkpoint per phase)
│   │   ├── implement-phase-auto.md      # /implement-phase-auto <n> <slug> (headless — used by scripts/autorun.sh)
│   │   ├── review-phase-auto.md         # /review-phase-auto <n> <slug> (headless — used by scripts/autorun.sh)
│   │   ├── finalize.md                  # /finalize <slug>
│   │   ├── archive.md                   # /archive <slug>
│   │   └── architecture-review.md       # /architecture-review [path]
│   └── skills/
│       ├── planning-docs/
│       │   └── SKILL.md                 # Doc templates + task type tag rules
│       ├── vertical-slicing/
│       │   └── SKILL.md                 # Tracer-bullet phase design, pulled by planner
│       ├── coding-standards/
│       │   └── SKILL.md                 # Project conventions — pulled by implementers, pushed into reviewer
│       └── phase-lifecycle/
│           └── SKILL.md                 # Phase-branch setup, worktree/parallel-task mechanics, issue-resolution delegation, status-trailer format — single source of truth pulled by all 6 phase-related commands
├── scripts/
│   ├── autorun.sh                       # Fully hands-off driver: one `opencode run` process per phase, genuinely fresh context each time
│   └── doctor.sh                        # Static self-check suite for this repo (harness-repo-only — never shipped to user projects)
└── docs/
    ├── _archive/                        # Merged slugs' docs, moved here by /archive to avoid stale-doc drift
    └── <slug>/                          # One folder per feature/fix/project
        ├── architecture.md
        ├── spec.md
        ├── implementation-plan.md
        ├── feedback-log.md
        └── phase-branches.md            # Written by `lead`: records each phase's exact diff base
```

`<slug>` is a short kebab-case name agreed with the planner at the start of every planning session (e.g. `todo-app`, `csv-export`, `fix-login-race`). It connects docs, git branches, and commits for a single unit of work.

---

## The Stages

### Stage 0 — Grill (optional, recommended for anything non-trivial)

**Agent:** `grill`  
**Trigger:** `/grill <headline description of the idea>`  
**Output:** a design concept summary (ephemeral — not committed, not a doc)

`grill` interviews you about the idea one question at a time, giving its own recommended answer with each question, until you've reached genuine shared understanding — typically 15-40+ exchanges for anything with real design ambiguity. It cannot write files or code, and deliberately doesn't know what `/plan` will do with its output — an agent that can see the doc-writing reward coming tends to rush the interview to get there. When you're aligned, it produces a short plain-language summary and tells you to close the session and start `/plan` fresh.

Skip this for trivial changes — `/plan` will just ask a question or two directly if you go straight there.

### Stage 1 — Planning

**Agent:** `planner`  
**Trigger:** `/plan <headline, or a pasted grill summary>`  
**Output:** four committed docs under `docs/<slug>/`

The planner expects a prior grill summary as input — it transcribes an already-aligned design into docs rather than re-negotiating it, asking only for gaps the summary didn't resolve. Given a bare headline with no grill summary, it still works, asking clarifying questions directly, but flags that grilling first tends to produce a better-aligned plan. It writes:

- `architecture.md` — components, data model, data flow, key decisions
- `spec.md` — functional and non-functional requirements, acceptance criteria, in/out of scope
- `implementation-plan.md` — phased task list structured as **vertical slices** (each phase crosses every layer to deliver one thin, reviewable, end-to-end piece of behavior — not "all schema, then all API, then all UI"), each task tagged `[type: tdd]`, `[type: smoke]`, or `[type: spike]`
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
**Output:** working code with tests, each task committed by its `task-implementer` as it finishes, plus a docs-only phase-complete commit from `lead`

`lead` reads the phase's task list. Before delegating the first task, it captures the current branch as this phase's base, creates `feature/<slug>-phase-<n>`, and appends a row to `docs/<slug>/phase-branches.md` recording that base explicitly — this is what lets `phase-reviewer` compute a reliable diff baseline later without guessing. It then checks `feedback-log.md` for any "Risks for future phases" or "Deferred issues" entries relevant to this phase and surfaces them to you as a brief heads-up — informational only, it doesn't pause or ask for confirmation.

For each task, `lead` delegates to `task-implementer` via the Task tool, passing the task description, acceptance criteria, `[type: ...]` tag, and relevant file pointers.

`task-implementer` chooses its path based on the tag:

- `[type: tdd]` → write failing tests → implement → green
- `[type: smoke]` → implement → run a minimal smoke check

Tasks marked `[parallel-with: X]` are handled differently from everything else: `lead` gives each one its own git worktree under `.worktrees/<slug>-<task-id>` on a dedicated branch, delegates a separate `task-implementer` instance pointed at that directory, and — once every task in the group reports done — merges each branch back into the phase branch **sequentially, one at a time, never in parallel**. If a merge conflict occurs, `lead` stops immediately and waits for you rather than attempting to resolve it. This keeps genuinely-parallel work from racing on the same files; tasks with no `[parallel-with]` tag just run sequentially in the main working tree as before.

If a `task-implementer` reports **FAIL**, `lead` stops delegating the rest of the phase — no retry, no workaround, no phase commit — surfaces the root cause, and asks your direction: fix, skip, or adjust. Tasks that end up not completed are recorded and land under "Deferred issues" in the review's `feedback-log.md` entry, not dropped (see [Stage 3](#stage-3--feedback)).

`lead` compiles a phase summary from each task-implementer's summary block and presents it to you before declaring the phase ready for review.

`lead` then creates the phase-complete commit automatically (`feat(<slug>): phase <n> complete`) — docs-only: `git add docs/<slug>/`, the `phase-branches.md` row and this phase's checkbox flips in `implementation-plan.md`, nothing else. No code is swept in: each `task-implementer` committed its own work with explicit paths as its end-of-task step, and `lead` commits only `docs/<slug>/`. The reviewer diffs this branch against the recorded fork point — see [Stage 3](#stage-3--feedback) — so this commit must exist before review runs.

---

### Stage 3 — Feedback

**Agent:** `lead` (delegates to `phase-reviewer` → `issue-resolver` per blocking/non-blocking issue → `doc-updater`)  
**Trigger:** `/review-phase <n> <slug>`  
**Output:** fixed code + updated docs + a new entry in `feedback-log.md`

`phase-reviewer` reads `docs/<slug>/phase-branches.md` to find this phase's exact base branch — never inferred from naming conventions, always read from the record `lead` wrote during Implementation — finds the fork point (`git merge-base`), and diffs against that. It checks test results and reports in order:

1. **Testing compliance** — did TDD tasks produce tests? Did smoke tasks run a check?
2. **Acceptance scenario compliance** — if the slug has an `acceptance.md`: green evidence per scenario plus the diff lock (an unlogged scenario change is blocking); "n/a — no acceptance.md for this slug" when it doesn't
3. **Blocking issues** — each with affected file(s) and a one-sentence reason it must be resolved before the next phase starts
4. **Non-blocking findings** — tech debt, minor risks, improvements that don't prevent continuing
5. **Risks for future phases** — architecture drift, scope creep, concerns about upcoming phases
6. **Suggested doc edits** — concrete, targeted changes to the affected docs

`lead` presents the full report and asks you to confirm which blocking and non-blocking issues to resolve. For each confirmed issue, `issue-resolver` is delegated one at a time — sequentially, never in parallel — and reports back with the same summary format as `task-implementer`. If any fix reports FAIL, `lead` surfaces the root cause and waits for your direction before moving on. **"Risks for future phases" are never delegated to `issue-resolver`** — they're speculative concerns about work that hasn't happened yet, not bugs to fix. They're recorded in `feedback-log.md` instead.

Any issue you decline to resolve now isn't dropped — it's logged as a **deferred issue**, a distinct category from "risks for future phases" (a deferred issue is a confirmed real finding against code that already exists; a risk is speculative concern about work that hasn't happened yet). The same applies to implementation tasks skipped after a FAIL during Implementation: `/implement-phase` records them, and `/review-phase` logs them under "Deferred issues" exactly like declined ones. Deferred issues resurface as a heads-up in later phases the same way risks do.

Once all confirmed issues are resolved, `lead` asks whether to apply the doc updates. On your confirmation, `doc-updater` makes the targeted edits and appends a dated entry to `feedback-log.md` covering the original findings, deferred issues, logged risks, and the resolutions applied. `lead` then commits automatically — docs-only (`git add docs/<slug>/`, message `review(<slug>): phase <n> fixes and doc updates`); each fix was already committed by the `issue-resolver` that wrote it, since `lead` commits only `docs/<slug>/`.

Repeat **Implementation → Feedback** for each phase until the plan is complete. Once every phase is done, run `/finalize <slug>` before merging — see below — and `/archive <slug>` after merging to main.

---

### Automated Full Run (optional)

There are two ways to automate the Implementation → Feedback loop across every phase, trading off differently between hands-off convenience and session-freshness discipline. Both build on everything above — same worktree isolation, same denylist, same deferred-issue/risk logging.

#### Option A — `/autorun <slug>` (in-chat, one checkpoint per phase)

If you trust the plan and want to skip the within-phase confirmations but still want to stay roughly in the loop, `/autorun` runs the entire Implementation → Feedback cycle for every phase inside **one continuous `lead` session**, with a single checkpoint between phases. `lead` iterates through all phases in order; for each phase it:

1. Captures the current branch as this phase's base and records it in `phase-branches.md`, then creates the `feature/<slug>-phase-N` branch
2. Checks `feedback-log.md` for relevant open risks and deferred issues, and surfaces them as a heads-up (informational only)
3. Delegates all tasks to `task-implementer` (same TDD / Smoke rules apply); `[parallel-with]` groups run in isolated worktrees, merged back sequentially (same as `/implement-phase`)
4. Creates the docs-only phase-complete commit (`git add docs/<slug>/`; each `task-implementer` already committed its own code)
5. Delegates review to `phase-reviewer` (diffed against the recorded base in `phase-branches.md`)
6. Resolves **all** blocking and non-blocking issues via `issue-resolver` (sequentially, no confirmation). Risks for future phases are not delegated — they're logged in `feedback-log.md` by `doc-updater` instead. If a FAIL is skipped by your direction rather than fixed, it's logged as a deferred issue, not dropped.
7. Delegates doc updates to `doc-updater`
8. Commits the doc updates (each `issue-resolver` already committed its own fix)
9. Reports a per-phase progress summary
10. **Pauses and asks you to confirm before starting the next phase** — this is the one checkpoint in an otherwise hands-off run, so a multi-phase run never disappears from view entirely.

The only times `lead` stops and waits for you are:
- A `task-implementer` reports **FAIL** — it cannot proceed until you decide whether to fix, skip, or adjust the task.
- An `issue-resolver` reports **FAIL** — it cannot proceed until you decide how to handle the unresolved issue.
- A parallel-task merge conflict occurs — it will not attempt to resolve this automatically.
- The end-of-phase checkpoint, before each new phase begins.

When all phases are complete, `lead` reports a full run summary and reminds you to run `/finalize <slug>` before merging, and `/archive <slug>` after.

**The trade-off:** because everything happens in one `lead` session, that session's own context accumulates a summary per phase for the life of the run. Fine for a short plan; on a long one (8+ phases), the orchestrating session itself can drift toward the smart zone ceiling even though it never holds full diffs — see [Smart zone / dumb zone](#tips--conventions) below.

#### Option B (experimental) — `scripts/autorun.sh <slug> [start_phase]` (headless, genuinely fresh session per phase)

For long plans, or for true unattended automation (CI, a cron job, "kick it off before you leave for the day") — with no checkpoint pauses at all, not even Option A's between-phase one — use the driver script instead:

```bash
scripts/autorun.sh <slug> [start_phase]   # [start_phase] is an optional resume point — see Troubleshooting
```

This isn't an in-chat command — it's a bash script that calls the `opencode` CLI's non-interactive mode (`opencode run --agent lead`) once per phase-step. Each call is its own **process**, with its own fresh context — the same property you'd get from manually closing a session and starting another, except nothing here has to remember to do it. Concretely, for each phase N it runs (the commands go through `--command`, not as `/slash` strings — `opencode run` doesn't resolve slash syntax):

```bash
opencode run --agent lead --format json --command implement-phase-auto "N <slug>"
opencode run --agent lead --format json --command review-phase-auto "N <slug>"
```

and once the phase loop finishes, calls `/finalize <slug>` once. `implement-phase-auto` and `review-phase-auto` are non-interactive twins of `implement-phase`/`review-phase` — same steps, same worktree/denylist/deferred-issue behavior, but never pausing for confirmation, and always ending their response with a machine-readable trailer the script parses:

```
AUTORUN_STATUS: OK
AUTORUN_STATUS: FAIL: <reason>
AUTORUN_STATUS: NEEDS_HUMAN: <reason>
```

The script stops immediately (non-zero exit) on anything other than `OK` — including a missing trailer, which it treats as `NEEDS_HUMAN` rather than assuming success. Everything is logged to `docs/<slug>/autorun.log`, since there's no live chat to watch. On a stop, review the log, fix whatever's wrong (manually, or by resuming interactively with `/implement-phase`/`/review-phase` for that specific phase), then re-run with the next phase's number as a second argument — `scripts/autorun.sh <slug> <start_phase>` skips every phase before it, so already-committed phases aren't redone.

**Requirements:** the `opencode` CLI on `PATH`, with headless auth already configured (`opencode auth login` or the relevant provider environment variables), and `jq` on `PATH` (the script checks for this and fails fast with a clear message if missing). Smoke-test with `opencode run --agent lead "echo hi"` before a real run — some `opencode` versions/platforms have had `run` require a pre-existing session rather than creating one automatically; the script's header comment has a link to the relevant issue if you hit this.

**How status detection actually works, and why `jq` matters:** `opencode run --format json` streams one JSON object per line, with different `type`s — `text` for the model's actual output, `tool_use` for a tool call's full input/output (which can be huge — e.g. an entire file's contents if the agent reads one), `step_finish`, `error`. The script uses `jq` to pull out only the `type=="text"` events and take the last one — the model's real final response — before looking for the `AUTORUN_STATUS:` trailer in it. An earlier version of this script skipped that step and just grepped the raw JSONL for the string `AUTORUN_STATUS:`, which broke in a subtle way: when `lead` reads the `phase-lifecycle` skill (which documents the trailer format with a literal example block), that skill's own text shows up in a `tool_use` event's output, and a naive grep can't tell "the skill describing the format" from "the agent's actual report." Worse, JSON encodes embedded newlines as the literal two characters `\n`, not real line breaks, so the match can run on for dozens of lines past where it looks like it should stop. Parsing the event stream properly with `jq` sidesteps both problems by construction — it only ever looks at genuine model output, never tool payloads.

**Use `/implement-phase`/`/review-phase` individually** when you want to inspect or adjust things between phases; **use `/autorun`** for a short plan where you want to stay roughly in the loop; **use `scripts/autorun.sh`** for a long plan or genuinely unattended automation where fresh-session discipline matters more than live visibility.

---

## Maintenance Commands

Three commands sit outside the per-phase Implementation ↔ Feedback loop — one runs once per slug before merging, one runs once per slug after merging, and one runs periodically and isn't tied to any single slug at all.

**`/finalize <slug>`** — run once, after the last phase's Feedback stage, before you merge to main. Every phase up to now was reviewed against its own fork point in isolation; this re-diffs the *entire* feature branch (from Phase 1's base to current HEAD) as one unit through `phase-reviewer`, catching integration issues that no single phase review could see (e.g. phase 1's schema choice conflicting with phase 4's query pattern). Any blocking issues found go through the same `issue-resolver` confirm-and-fix loop as a normal review.

**`/archive <slug>`** — run once, after you've actually merged the feature branch to main. Moves `docs/<slug>/` to `docs/_archive/<slug>/` (never deletes) so a future `/grill` or `/plan` session for unrelated work doesn't stumble on docs that have drifted from the merged reality and mistake them for current — closed GitHub/issue-tracker items with clear "done" status are a safer long-term reference than a live-looking markdown file. Nothing in this workflow does this automatically — it's a deliberate manual step.

**`/architecture-review [path]`** — run periodically, independent of any slug. `phase-reviewer`'s per-phase architecture check only ever sees one phase's diff; shallow-module sprawl and naming drift typically accumulate a little at a time across many individually-reasonable phases, so no single phase review trips on it. This delegates to the dedicated `architecture-reviewer` subagent, which scans the whole codebase (or a given path) for shallow-module clusters, dead code, and naming drift, and reports findings only — it never edits anything. Turn any finding you want acted on into a tagged task in the relevant plan, or a new slug of its own via `/plan` if it's substantial.

---

## doctor.sh — static self-check suite (harness repo only)

This repo makes a pile of *structural* claims about itself — denylist copies stay in sync, no shipped prompt suggests bulk staging, `AGENTS.md` stays a ≤80-line navigation file, README file counts match disk, `.gitignore` keeps protecting the scratch dirs, load-bearing procedure steps survive every prose-condensation pass — and prose claims rot silently: any refactor can break one and nothing notices. `scripts/doctor.sh` turns each claim into an executable check, so "the harness is still self-consistent" is one green/red command instead of a grep-and-pray exercise. It takes no arguments and runs from any cwd: the repo root is resolved from the script's own location, so it always checks the checkout it lives in.

```bash
scripts/doctor.sh
```

**What it checks** — nine static checks, then a simulation stage:

1. **Denylist drift** — every agent file's parsed `bash:` permission stream matches the recorded golden exactly, *in order* (a deny only protects when it sits after its agent's `"*": allow` catch-all — presence in resolved output proves nothing), and the failed shared-denylist hoist stays failed: no top-level `permission` key in the shipped config.
2. **No unfinished prompts** — no `<fill in` template placeholder anywhere under `.opencode/`.
3. **No sweep-staging in prompts** — no `git add -A` under `.opencode/`; shipped prompts stage explicit paths only.
4. **Scratch protection** — the harness's three shipped `.gitignore` lines (`.worktrees/`, `.scratch/`, `**/autorun.log`) are still present.
5. **README honesty** — the Minimal-footprint counts and the directory tree's `scripts/` listing match the files on disk.
6. **`grill` containment** — grill's task whitelist stays within `{explore, scout}`, never an implementation- or review-side subagent.
7. **AGENTS.md budget** — ≤80 lines; past that budget it's a tax, not a map.
8. **Watcher entries** — the 11 shipped `watcher.ignore` entries are still present in `.opencode/opencode.json`; presence-only, because the rot this guards is an accidental removal, not a deliberate addition.
9. **Invariant markers** — the two `<!-- invariant: … -->` markers in the `phase-lifecycle` skill are present: the positive-presence counterweight to the absence-checks, so a condensation pass can't silently *delete* a required step.

Then the **worktree-flow simulation** exercises the git discipline of `phase-lifecycle` part B against a throwaway `git init` repo, asserting four scenarios: a dirty worktree → cleanup refuses; commit + sequential merge → the gate passes and cleanup lands the merge; a docs-only lead commit is correctly discriminated from a mixed docs+code commit; committed-but-unmerged work is never cleaned up. Pure git throughout — it never invokes `opencode` and never touches the harness repo's own git state. Nothing fails fast: the complete list of broken steps is the diagnosis.

**Exit codes and scratch lifecycle.** `0` — all green; the simulation's scratch dir (`.scratch/doctor-sim/`) is cleaned up. `1` — at least one step failed; `.scratch/doctor-sim/` is **kept**, fixture tree and decision trace included, for diagnosis. `2` — usage/environment error (an argument was given, the script isn't inside a harness-repo checkout, or `DOCTOR_EXTRA_CHECKS` names a missing file).

**When to run it.** After any structural edit to `.opencode/` (agents, commands, skills, config), `AGENTS.md`, the three shipped `.gitignore` lines, or anywhere the README states a file count — those are exactly the claims that rot. It's cheap — measured ~0.3 s wall on this machine, most of it the simulation's throwaway git repo — so during harness development or a dogfooding phase run, consult it as the one green/red answer to "did my edit break a self-consistency claim?", not a release-day ceremony.

**Extending or demonstrating it.** Two environment-variable seams exist so neither artificial pass/fail fixtures nor deliberate broken-check demos have to be committed into the script: `DOCTOR_EXTRA_CHECKS=<path>` sources extra checks on top of the shipped ones, and `DOCTOR_SIM_SKIP_VERIFY=1` drops the simulation's verification step to reproduce the silent work-loss bug that step exists to prevent. Both are unset in normal use; the script's header comment documents them.

**Harness-only, and why no CI in v1.** doctor.sh asserts claims about *this* repo's own files — a project that merely adopted the harness has nothing for it to check — so it deliberately stays out of the [copy list](#step-1--open-opencode-and-initialize) and ships to nobody. Wiring it into CI would add maintenance surface with no consumer yet; the decision and its rejected alternatives are recorded under "Key decisions & trade-offs" in `docs/_archive/harness-streamlining/architecture.md`.

**Requirements:** bash ≥ 4.4 and git ≥ 2.32 (the version the simulation's hermetic `GIT_CONFIG_*` config isolation reaches); nothing else.

---

## Agents Reference

| Agent | Mode | Role | Permissions |
|---|---|---|---|
| `grill` | primary | Alignment-only interview, no docs, no code | edit: deny · bash: deny · webfetch: ask · task: explore/scout only |
| `planner` | primary | Transcribes an aligned design concept into docs, structured as vertical slices | edit: allow · bash: deny · webfetch: allow |
| `lead` | primary | Orchestrates, delegates, summarizes; owns worktree creation/merge for parallel task groups and `phase-branches.md` | edit: allow (bookkeeping only — `phase-branches.md` rows + `implementation-plan.md` checkbox flips, by convention) · bash: allow with hard-blocked commands + push + scope denials · webfetch: allow · task: whitelisted 6 subagents only |
| `pair` | primary | Runs the interactive pair loop — discuss → implement one small human-approved step → the human inspects → commit; one reviewable commit per step, every decision logged to `docs/<slug>/decisions.md`; stays on the current branch, never a phase branch or worktree | edit/bash/webfetch: allow with hard-blocked commands · task: `task-implementer`/`explore` only |
| `task-implementer` | subagent | Implements one planned task (TDD or Smoke); pulls `coding-standards` if unsure; may be pointed at a git worktree for parallel work | edit/bash/webfetch: allow with hard-blocked commands · task: deny |
| `phase-reviewer` | subagent | Read-only review, diffs against the base recorded in `phase-branches.md`, classifies blocking/non-blocking issues, compliance + architecture check; standards pushed inline; optionally pinned to a stronger model; also runs in finalize mode for `/finalize` | edit: deny · bash: allow with hard-blocked commands + commit/add/push denials |
| `issue-resolver` | subagent | Fixes one blocking or non-blocking issue found by reviewer (TDD or Smoke) — does not act on speculative future-phase risks; same hard-blocked commands as `task-implementer` | edit/bash/webfetch: allow · task: deny |
| `doc-updater` | subagent | Applies approved doc edits after issues are resolved, including deferred-issue entries | edit: allow (docs only) · bash: deny |
| `architecture-reviewer` | subagent | Whole-codebase architecture scan (shallow modules, dead code, naming drift), independent of any phase; read-only | edit: deny · bash: allow with hard-blocked commands + commit/add/push denials |
| `characterizer` | subagent | Characterizes one target module for brownfield work — writes tests pinning its CURRENT behavior (quirks and bugs included), passing against the unmodified code; zero behavior change, commits test files only; pulls `coding-standards` if unsure | edit/bash/webfetch: allow with hard-blocked commands · task: deny |

`lead` is locked to its six named subagents — it cannot invoke any other subagent. `grill` is likewise locked down — it can spawn only the read-only `explore`/`scout` subagents, never the implementation agents (`scout` is optional in some installs; the allow entry is a harmless no-op when absent). None of the subagents can spawn further subagents, preventing unbounded delegation chains. `grill` and `planner` are separate primary agents used in separate sessions — closing one before opening the next is what keeps each session's context small and keeps `grill` from rushing to a deliverable.

**Every agent that can run headlessly (all of the above except `grill` and `planner`) uses allow-by-default-with-denylist for bash (or, like `doc-updater`, denies bash outright — full deny stalls nothing), never allowlist-with-`ask`-fallback.** An allowlist only covers the commands someone thought to list in advance, and `ask` requires a human to answer — which works fine interactively but silently stalls forever when an agent is invoked headlessly (`opencode run`, as `scripts/autorun.sh` does), with no one there to answer it — exactly the failure mode if you invoke the script against an agent still configured the old way. `grill`'s `webfetch: ask` is the one deliberate exception, since it's interactive-only by design.

---

## Commands Reference

| Command | Agent invoked | Arguments | Purpose |
|---|---|---|---|
| `/grill <idea>` | `grill` | Free-text idea | Alignment interview before any docs exist (optional, recommended for non-trivial work) |
| `/plan <idea or grill summary>` | `planner` | Free-text headline or pasted design-concept summary | Start a Planning session |
| `/implement-phase <n> <slug>` | `lead` | Phase number, slug | Implement one phase by delegating tasks (interactive) |
| `/review-phase <n> <slug>` | `lead` | Phase number, slug | Review a phase and update docs (interactive) |
| `/interactive <slug\|new>` | `pair` | Slug, or `new` to start one | Human-paced pair loop for a slug — one inspected, approved step at a time, decisions logged to `decisions.md`; the entry point `[mode: interactive]` phases are routed to instead of delegated tasks |
| `/characterize <path>` | `lead` | Path of the module to characterize | Brownfield entry point — delegates to `characterizer`, which pins the module's CURRENT behavior with passing tests (zero behavior change) and commits test files only |
| `/autorun <slug>` | `lead` | Slug | Implement **all** phases and run Feedback for each automatically, one checkpoint per phase, single continuous session |
| `/implement-phase-auto <n> <slug>` | `lead` | Phase number, slug | Headless twin of `/implement-phase` — no confirmation, ends with `AUTORUN_STATUS:` trailer. Used by `scripts/autorun.sh`; not usually invoked directly. |
| `/review-phase-auto <n> <slug>` | `lead` | Phase number, slug | Headless twin of `/review-phase` — auto-resolves all issues, ends with `AUTORUN_STATUS:` trailer. Used by `scripts/autorun.sh`; not usually invoked directly. |
| `/finalize <slug>` | `lead` | Slug | Whole-branch check across all phases together, before merging to main. Non-interactive; usable standalone or headlessly. |
| `/archive <slug>` | `lead` | Slug | Move a merged slug's docs to `docs/_archive/`, after merging to main |
| `/architecture-review [path]` | `lead` | Optional path | Whole-codebase (or scoped) architecture scan, run periodically, not tied to a slug |

`scripts/autorun.sh <slug> [start_phase]` (a bash script, not an in-chat command; `[start_phase]` is an optional resume point — see [Troubleshooting](#troubleshooting)) drives `/implement-phase-auto`, `/review-phase-auto`, and `/finalize` via separate `opencode run` processes — one process per phase, so each phase's orchestrating session is genuinely fresh rather than accumulated across the whole run. See [Automated Full Run](#automated-full-run-optional).

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

### `[type: spike]`

For time-boxed investigation of an open question — feasibility, unknown tech, risky design calls — producing a durable finding rather than shipped code.

```
Investigate in .scratch/ → record the finding → commit the entry
```

A `[type: spike]` task carries `(question: ..., exit: ...)` instead of `(acceptance: ...)`; throwaway code stays in `.scratch/`. The deliverable is a dated entry in `docs/<slug>/findings.md` — question, approach, answer, decision — appended and committed by the spike's `task-implementer` as its end-of-task step. If the exit criterion can't be met inside the time-box, the implementer reports `INCONCLUSIVE`, not `FAIL` — an inconclusive spike is a valid outcome, not a failure.

Use for: feasibility checks, probes into unfamiliar technology, risky design calls that a later task's approach depends on.

### Stacking tags

Tags compose:

```
- [ ] Task 2.3: Set up auth middleware (acceptance: ...) [type: tdd] [parallel-with: 2.2]
```

### Classification fallback

If a task has no type tag, `task-implementer` classifies it using the same heuristics (TDD when in doubt). However, explicit tags at planning time are more reliable than runtime inference — the planner should never leave a task untagged.

### Mode tags

Phases — not tasks — carry `[mode: …]` tags, written on the `## Phase N — <name>` heading line. A mode says *who* implements the phase; it is orthogonal to the task-level `[type: …]` vocabulary.

```
- `[mode: sdd]` → delegated `task-implementer` subagents — the default SDD flow
- `[mode: interactive]` → a human pair loop (`/interactive`)
- `[mode: autorun]` → the unattended run (`/autorun`, `scripts/autorun.sh`)
```

**An absent tag means `[mode: sdd]`** — every plan written before mode tags existed keeps running unchanged. The gate on the automation side: `/implement-phase*` given a `[mode: interactive]` phase refuse to delegate and point to `/interactive`, and a headless run halts at that phase with a `NEEDS_HUMAN` status trailer rather than skipping ahead silently; `/review-phase*` refuse such a phase too — it has no phase branch and therefore no `phase-branches.md` diff baseline, because the human at each step of the loop was that phase's review gate. The vocabulary's source of truth is the `planning-docs` skill ("Phase mode tags"). The Pattern Record's four answers fix these tags — and one of them, mistake cost, has a consequence outside the mode vocabulary: a high answer makes the planner draft exact acceptance scenarios in [`acceptance.md`](#document-templates).

---

## Document Templates

All templates are embedded in `.opencode/skills/planning-docs/SKILL.md` and are available to the `planner` and `doc-updater` agents on demand. Abbreviated structure:

**`architecture.md`** — Overview · Components table · Data flow · Data model · External dependencies · Key decisions & trade-offs · Open questions

**`spec.md`** — Goal · In scope / Out of scope · Functional requirements · Non-functional requirements · Acceptance criteria · Constraints & assumptions

**`implementation-plan.md`** — One section per phase, each with a goal and a task list. Every task: `- [ ] Task N.M: <description> (acceptance: <criteria>) [type: tdd|smoke|spike]`; a `[type: spike]` task replaces `(acceptance: <criteria>)` with `(question: ..., exit: ...)`.

**`acceptance.md`** — Conditional: only for slugs whose Pattern Record flags high mistake cost. Numbered Given/When/Then scenarios the implementation is verified against — coarse acceptance criteria stay in `spec.md`. Header carries `Status: Draft` → `Status: Approved YYYY-MM-DD`, flipped only by the human at the `/plan` approval step.

**`findings.md`** — Not written by `planner`: the spike's `task-implementer` appends a dated entry — question, approach, answer, decision — per `[type: spike]` task as its end-of-task step, append-only, with the throwaway spike code itself kept in gitignored `.scratch/`.

**`decisions.md`** — Not written by `planner`: the `pair` agent appends a dated mini-ADR entry — decision, why, alternatives considered — per decision made during a `/interactive` loop, append-only, and read end-to-end by `planner` as aligned input if the work graduates to `/plan`.

**`feedback-log.md`** — Append-only. One dated entry per reviewed phase: issues found, deferred issues, risks for future phases, doc changes applied.

**`phase-branches.md`** — Written by `lead`, not `planner`. One row per phase: phase number, its branch, and the exact base branch it was created from — read by `phase-reviewer` for its diff baseline instead of inferring it.

---

## Shared Mechanics

`implement-phase`, `implement-phase-auto`, `autorun`, `review-phase`, `review-phase-auto`, and `finalize` all perform the same three underlying procedures — phase-branch setup, worktree-isolated parallel task execution, and issue-resolution delegation — differing only in *policy* (ask first vs. auto-resolve, checkpoint vs. no checkpoint) and, for the three headless commands, the `AUTORUN_STATUS` trailer. Rather than each command file describing these mechanics independently (which is how earlier drafts of this repo worked, and which had already started to drift — one copy quietly lost part of the conflict-handling instructions during an edit that touched only its siblings), they're defined once in `.opencode/skills/phase-lifecycle/SKILL.md` and referenced by name. If you need to change how worktrees are created, how issues get delegated, or the status-trailer format, edit that skill file — not the six command files that reference it.

---

## Full Worked Example

**Scenario:** Build a simple ToDo web app — Python/FastAPI backend, TypeScript/TailwindCSS/Next.js frontend, SQLite, runs locally.

### Step 1 — Open OpenCode and initialize

```bash
cd todo-project
git init
opencode
```

Copy the agent, command, and skill files into `.opencode/`, `AGENTS.md` into the project root, and `scripts/autorun.sh` if you plan to use headless automation (see [Directory Structure](#directory-structure) for the full layout, and [Prerequisites](#prerequisites) for what needs to be installed first). For `.gitignore`, merge the harness's three lines into your existing `.gitignore` rather than copying the harness's file over yours — or just copy it in as-is for a fresh repo with no `.gitignore` yet. The `.gitignore` belongs in the copy list even though it isn't a workflow file: it keeps the harness's own ephemeral artifacts — `.worktrees/`, `.scratch/`, `**/autorun.log` — out of your commits.

The project-level `opencode.json` shipped with this harness intentionally contains only `$schema` and the `watcher.ignore` list. Anything machine-specific — lsp/formatter toggles, MCP servers, provider definitions, compaction settings — belongs in your global OpenCode config (`~/.config/opencode/opencode.json`), which you maintain yourself; the harness never touches it.

### Step 1.5 (optional) — Grill first

For a small app like this, planning questions alone are probably enough. For something with more design ambiguity, you'd run:

```
/grill ToDo web app — FastAPI backend, Next.js + TailwindCSS frontend
```

and go through the alignment interview, then close that session and paste the resulting design-concept summary into `/plan` below. The rest of this walkthrough skips straight to `/plan` since the example is simple enough not to need it.

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

`lead` then creates the docs-only phase-complete commit — `feat(todo-app): phase 1 complete`, covering `phase-branches.md` plus the phase's checkbox flips (each task's code was already committed by its implementer).

### Step 4 — Review Phase 1

```
/review-phase 1 todo-app
```

`lead` delegates to `phase-reviewer`, which diffs the phase branch against its fork point and checks test results, then reports:

```
Testing compliance:
  Task 1.1 [smoke] — smoke check present ✓
  Task 1.2 [tdd]   — 8 new tests, all passing ✓
  Task 1.3 [tdd]   — 12 new tests, all passing ✓

Acceptance scenario compliance: n/a — no acceptance.md for this slug

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

> There are 2 issues to resolve: 1 blocking, 1 non-blocking. (The future-phase risk is speculative and will just be logged.) Which would you like to address now?

```
Resolve both.
```

`lead` delegates to `issue-resolver` for each, one at a time. First the blocking issue — `issue-resolver` applies the TDD path, writes a failing test asserting 204, fixes the route handler, runs pytest green:

```
Approach:       TDD
Issue fixed:    DELETE /todos/{id} now returns 204 No Content
Files changed:  app/routes/todos.py, tests/test_routes.py
Tests written:  tests/test_routes.py : test_delete_todo_returns_204
Test result:    PASS (pytest tests/test_routes.py::test_delete_todo_returns_204)
Deviations:     none
Residual risks: none
```

`lead` reports the resolution, then resolves the non-blocking finding the same way, and asks:

> Both issues resolved. Apply the doc updates?

```
Yes, apply them.
```

`doc-updater` makes the targeted edits and appends a single dated entry to `feedback-log.md` covering the original findings (including the future-phase risk, which stays logged rather than fixed) and the two resolutions applied.

### Step 5 — Continue

```
/implement-phase 2 todo-app
```

Before delegating Phase 2's first task, `lead` checks `feedback-log.md` and notices the `created_at` risk logged during Phase 1's review:

> Heads-up: Phase 1's review flagged a risk that `created_at` was missing from the Todo response schema and may cause a breaking change later. `implementation-plan.md` already has a task for it in this phase — proceeding.

This is informational only — `lead` doesn't pause for confirmation, it just continues into the phase's tasks.

```
/review-phase 2 todo-app
/implement-phase 3 todo-app
...
```

---

## Tips & Conventions

**Run `/grill` before `/plan` for anything with real design ambiguity.** For a one-line bug fix or trivial task, skip straight to `/plan` — the planner will just ask a question or two directly. For anything where you're not sure yet what "done" looks like, grill first. Close the grill session before opening `/plan`; don't try to plan inside the same session.

**Smart zone / dumb zone.** LLM reasoning degrades well before the advertised context limit — treat ~100K tokens as a practical ceiling for any single session, not the vendor's max. Watch your context usage (a token counter in the status line, or `opencode`'s own usage indicator) and start a fresh session rather than let a session run long. Closing sessions at stage boundaries already gets you most of this, and each subagent invocation via Task already gets its own fresh context by construction — keeping one giant primary session open across an entire feature undermines that. Prefer starting fresh over relying on auto-compaction/summarization: a fresh session reading the committed docs is a deterministic, repeatable starting point; a compacted summary is not, and can quietly drop details that matter later — a stance Pocock's workflow takes deliberately. Treat `compaction.auto` in `opencode.json` as a safety net for sessions that ran longer than intended, not a substitute for closing sessions between stages; whether to disable it outright is a genuine trade-off, and this repo doesn't force either choice.

**Pin `phase-reviewer` to your strongest available model** (`model:` field in its frontmatter) if your provider setup has a cost/capability tier, and leave `task-implementer`/`issue-resolver` on your faster default. Verify it's actually taking effect — some OpenCode versions have had subagents-via-Task inherit the parent's model instead of their own; a quick `opencode agent list` or a deliberately-wrong-answer test will confirm.

**Prefer `scripts/autorun.sh` over `/autorun` for long plans.** `/autorun` runs every phase inside one continuous `lead` session — hands-off within a phase, but that session's own context still accumulates a summary per phase for the life of the run, which can drift toward the smart zone ceiling on an 8+ phase plan. `scripts/autorun.sh` gets a genuinely fresh session per phase by using `opencode run` process boundaries instead — see [Automated Full Run](#automated-full-run-optional). Smoke-test `opencode run --agent lead "echo hi"` once before trusting it with a real multi-phase run.

**Keep `/plan` arguments to a headline.** One line sets the topic; the planner's questions fill in the rest. Long arguments with special characters can confuse the command parser.

**Commit once manually:** after Planning (the four docs). Everything after that is handled automatically — branching and `lead`'s docs-only phase/review commits (`git add docs/<slug>/`), plus the code commits each `task-implementer`/`issue-resolver` makes for its own work. Your only other git responsibility is merging the feature branch to main when all phases are done.

**Close the planner session before implementing.** The `lead` agent needs a fresh primary session. Running `/implement-phase` inside a planner session uses an agent with `bash: deny`, which will block every sub-agent delegation.

**Tagging is the planner's job, not the implementer's.** The `task-implementer` has a classification fallback, but it's less reliable than an explicit tag. Push back on the planner if it produces tasks without tags.

**Blocking vs non-blocking is the reviewer's call, not yours.** The `phase-reviewer` classifies issues before you see them. You decide which blocking and non-blocking issues to confirm for resolution — but you don't need to triage the raw list yourself. "Risks for future phases" are a separate category that's never delegated for fixing — they're speculative concerns, not bugs, so they just get logged. Anything you decline to resolve now becomes a **deferred issue** instead — a distinct, logged category (a confirmed real finding, not a speculative risk) that resurfaces as a heads-up in later phases the same way risks do.

**Issue resolution is always sequential.** `issue-resolver` runs one fix at a time. If you have three issues to resolve, expect three resolution cycles before the doc update. This is intentional — each fix may affect the next.

**Logged risks and deferred issues resurface automatically, but only as a heads-up.** At the start of each phase, `lead` checks `feedback-log.md` for relevant open risks and deferred issues and mentions them before delegating tasks. It won't act on them itself — if one needs real work, add it as a tagged task in `implementation-plan.md` (the reviewer's "suggested doc edits" often do this for you).

**Parallel tasks run in worktrees, not the shared tree.** `[parallel-with: X]` tags trigger isolated git worktrees under `.worktrees/`, one branch per task, merged back sequentially — never in parallel. The shipped `.gitignore` already ignores it (for a project adopting the harness into an existing repo, it's one of the three lines to merge in); it's also already excluded from the file watcher in `opencode.json`. If a merge conflict happens during the merge-back, `lead` stops and hands it to you rather than resolving it itself.

**Agents stay inside the project directory, on purpose.** `lead`, `task-implementer`, and `issue-resolver` are instructed to never `cd` outside the repo — any exploratory or scratch work (probing whether a package installs cleanly or a tool version is compatible before delegating a real task, a throwaway build) goes in `.scratch/` at the project root instead. This isn't just tidiness: OpenCode gates file operations outside the project root behind a separate `external_directory` permission that no agent here has, and that gate auto-rejects with no one around to approve it in a headless run. Even if the gate weren't there, keeping an unattended agent's reach inside the repo is simply the smaller blast radius. The shipped `.gitignore` already ignores it (for a project adopting the harness into an existing repo, it's one of the three lines to merge in); it's also already excluded from the file watcher.

**Hard-blocked commands are intentionally hardcoded, not configurable per-task.** `task-implementer` and `issue-resolver` will refuse force-push, `rm -rf`, `git reset --hard`, `git checkout -- .`/`--force`, `git clean -f`, and `git branch -D` no matter how the task is phrased, including during unattended `/autorun` runs. If a task genuinely needs one of these, do it yourself.

**That denylist is deliberately duplicated across the 7 bash-agent files — don't "DRY" it up.** Hoisting it once into the shipped config's top-level `permission.bash` was gate-experimented and **proven unsafe**: an agent frontmatter's `"*": allow` catch-all out-votes config-layer denies at execution time (v1.18.35; first observed on v1.18.34), silently disarming every shared deny — and the deny still *appears* in `opencode debug agent` output, so presence checks can't catch it. The gate experiments and the disproof probe are recorded in `docs/_archive/harness-streamlining/gate-experiments.md`. A `scripts/doctor.sh` drift check keeps the copies in sync today — it ships as [check 1 of the static self-check suite](#doctorsh--static-self-check-suite-harness-repo-only).

**`/finalize` and `/archive` are manual, on purpose.** Nothing in this workflow merges to main or archives docs automatically — `/finalize` prepares the branch, you merge it, then `/archive` cleans up. `lead` will remind you of both at the natural points (end of `/autorun`, end of the last `/review-phase`), but won't run either without you invoking them.

**`/architecture-review` isn't part of the per-slug loop.** Run it whenever, on whatever cadence makes sense for the size of your codebase — weekly, before a big new slug starts, whatever. It's diagnostic only; turn findings you want acted on into tasks yourself.

**Use `@explore` or `@scout` for quick lookups.** If you need to check something in the codebase during Implementation without spinning up a `task-implementer`, the built-in `@explore` and `@scout` subagents are available and lighter-weight.

**One slug per unit of work.** A slug connects docs, git branches, and commit messages. Using the same slug throughout (`git checkout -b feat/todo-app`, `git commit -m "feat(todo-app): ..."`) keeps the history readable.

**Docs evolve; don't regenerate them.** The `doc-updater` makes targeted edits. If a doc needs a large structural change, do it in a Feedback step with your explicit confirmation — never ask any agent to rewrite a doc from scratch mid-project.

---

## Troubleshooting

**`/implement-phase` does nothing or errors on bash commands**  
You're likely still in the planner session (`bash: deny`). Close it and start a new session, then re-run the command.

**`phase-reviewer` reports "unable to determine diff baseline"**  
Either the phase wasn't committed before running `/review-phase`, or `docs/<slug>/phase-branches.md` is missing the row for this phase — `lead` should have written it during `/implement-phase`. If code files are missing from the phase commit, let their author re-commit them: the `task-implementer`/`issue-resolver` that wrote them commits the missed files itself with explicit paths, as its end-of-task step already requires. Never sweep them in with a blanket add — code commits belong to the agent that wrote the code, and `lead` commits only `docs/<slug>/`. If it's `lead`'s docs-only phase-complete commit that was missed or incomplete, redo it scoped: `git add docs/<slug>/ && git commit -m "feat(<slug>): phase <n> complete"`. If the `phase-branches.md` row is genuinely missing, add it manually (`| n | feature/<slug>-phase-n | <correct base> |`) before re-running review; don't let the reviewer guess.

**`task-implementer` or `issue-resolver` refuses a command, citing the hard-blocked commands**  
This is intended — force-push, `rm -rf`, `git reset --hard`, `git checkout -- .`/`--force`, `git clean -f`, and `git branch -D` are hard-blocked for both agents regardless of task phrasing. If the task genuinely needs one of these, run it yourself; don't try to phrase around the block.

**A worktree merge conflict stops `/implement-phase` or `/autorun` mid-phase**  
Expected — `lead` never attempts automatic conflict resolution for parallel-task merges. Resolve the conflict yourself in the phase branch, then tell `lead` to continue (or re-run the command; already-merged tasks won't be re-delegated since their worktrees are already cleaned up).

**A leftover `.worktrees/<slug>-<task-id>` directory or `task/<slug>-<task-id>` branch after an interrupted run**  
`lead` only cleans these up after a successful merge, so an interrupted parallel group can leave them behind. Safe to remove manually: `git worktree remove .worktrees/<slug>-<task-id> --force` (only if the work is already merged or you're discarding it) and `git branch -D task/<slug>-<task-id>`.

**`task-implementer` reports FAIL and stops**  
This is the intended behavior — `lead` stops delegating the rest of the phase, commits nothing, and asks for your direction. Read the root cause in the summary, then direct it: fix the failing test (`lead` re-delegates the task), adjust the task description or update the plan, or skip. Skipped tasks are recorded and `/review-phase` logs them as deferred issues — not dropped. If the session already ended before you decided, re-run `/implement-phase` for that phase — `lead` will re-delegate the unfinished tasks.

**`issue-resolver` reports FAIL and stops**  
Same principle. Read the root cause, decide whether the issue description was ambiguous or the fix is genuinely hard. You can rephrase the issue and ask `lead` to retry, defer it (it'll be logged as a deferred issue and resurface next phase), or fix it manually and tell `lead` to proceed.

**A task has no `[type: ...]` tag**  
`task-implementer` will self-classify (defaulting to TDD when uncertain) and state its classification at the start of its response. You can correct it by responding to the lead with the right type before the next task is delegated. Fix the tag in `implementation-plan.md` for the record.

**The `lead` agent tries to edit files directly**  
Remind it: `Delegate this to task-implementer via the Task tool. Do not edit files in this session.` There's no prompt to decline here: `lead`'s `edit` permission is `allow` by design, scoped by its instructions to bookkeeping only (the `phase-branches.md` rows and `implementation-plan.md` checkbox flips), so any other edit it attempts is an instruction violation — redirect it rather than expecting a permission block.

**Docs have diverged from the code**  
Run `/review-phase <last-completed-n> <slug>` even if you skipped it earlier. The `phase-reviewer` will surface the divergence and `doc-updater` will reconcile it.

**`/plan` or `/grill` for a new slug pulls in stale context from an old, related feature**  
Check whether that old slug's docs are still sitting live under `docs/<old-slug>/`. If it's already merged, run `/archive <old-slug>` — a live-looking doc for finished work is exactly the stale-context trap archiving exists to prevent.

**`scripts/autorun.sh` reports `Error: 'opencode run' itself failed (non-zero exit)` or a connection/auth error**  
This is a tooling failure, not an `AUTORUN_STATUS: FAIL` from the agent — `opencode` itself couldn't run (an `opencode` missing from `PATH` surfaces here too, with the shell's "command not found" text in the logged output). Confirm it's on `PATH` and headless auth is configured: `opencode run --agent lead "echo hi"` should work standalone before you trust the script with a real run.

**`scripts/autorun.sh` stops with "no AUTORUN_STATUS trailer found"**  
The script treats a missing trailer as `NEEDS_HUMAN` rather than assuming success — this is deliberate fail-closed behavior, not a bug. Check `docs/<slug>/autorun.log` for the full output of that step; either the command produced an unexpected response format (check for a recent edit to `implement-phase-auto.md`/`review-phase-auto.md`/`finalize.md` that dropped the trailer instructions) or something genuinely went sideways mid-response.

**`scripts/autorun.sh` reports a status that doesn't match what actually happened** (e.g. claims `OK` when a task clearly failed, or the log shows garbled text mixed with line numbers like `104:`, `105:`)  
This was a real bug in an earlier version of the script: it grepped the *raw* `opencode run --format json` output directly for the string `AUTORUN_STATUS:`, which can also appear inside a `tool_use` event's payload — most commonly when `lead` reads the `phase-lifecycle` skill itself, since that skill's own documentation includes a literal example of the trailer format. A naive grep can't distinguish "the skill describing the format" from "the agent's actual report," and since JSON encodes embedded newlines as literal `\n` characters rather than real line breaks, the match can run on for many lines past where it looks like it should stop — which is exactly where line-numbered garbage like `104: AUTORUN_STATUS: FAIL...` comes from (that's the skill file's own content, not a real error). The fix is to actually parse the JSONL with `jq` and pull out only `type=="text"` events (the model's real output) before searching for the trailer — which is what the script does now. If you're seeing this, confirm `jq` is installed and check `docs/<slug>/autorun.log` for a "Warning: could not extract a final text response via jq" line — that means it silently fell back to the old, unreliable raw-grep path, and the result should be treated with suspicion.

**`scripts/autorun.sh` stopped partway through and I want to resume**  
A trailer stop (`AUTORUN_STATUS: FAIL` / `NEEDS_HUMAN`) is logged as `Stopped at: Phase N: <step>` with the exact re-invocation on the final line; a missing trailer (treated as `NEEDS_HUMAN` — see that entry above) prints the re-invocation but no `Stopped at:` line; an `opencode run` tooling failure (see that entry above) prints neither — the error line itself is what to read. Fix whatever stopped it, then run `scripts/autorun.sh <slug> <next-phase-number>` — that second argument skips every phase before it, so committed phases aren't redone. The script never creates or switches branches, and phases stack (each branches off the previous phase's branch), so before resuming, check out the branch the next phase should build on. Or resume interactively from that point with `/implement-phase`/`/review-phase`.

**`opencode run` reports "Session not found" or similar, even for a trivial prompt**  
Some `opencode` versions/platforms have had `run` require a pre-existing session rather than creating one automatically (there's a link to the relevant tracking issue in `scripts/autorun.sh`'s header comment). Check `opencode run --help` and `opencode session --help` for your installed version; if this affects you, the script needs a small change to create a session explicitly per phase before running the command against it.

**`scripts/autorun.sh` hangs indefinitely (not a clean FAIL, just never returns) on a step that works fine interactively**  
This is almost always a permission set to `ask` somewhere in the agent chain that step exercises. `ask` needs a human to answer, and there's no one there in a headless `opencode run` — it doesn't error, it just waits forever (or times out at whatever your shell/CI's own limit is, which can look like a hang for a long time). `lead`, `phase-reviewer`, and `architecture-reviewer` are all configured allow-by-default-with-denylist specifically to avoid this — if you've customized any of their `permission:` blocks (or added a new subagent to the headless path), check for a lingering `"*": ask` bash fallback or an `edit: ask` you meant to loosen. Also check for stale *prompt text* telling the agent to "ask first" even if the permission itself is `allow` — a fixed permission doesn't help if the agent's own instructions still tell it to pause and wait for confirmation that will never come (this exact bug existed in `lead.md` at one point: `edit: allow` in the frontmatter, but body text still said "ask first").

**`docs/<slug>/autorun.log` shows `permission requested: external_directory (...); auto-rejecting`, and the step never completes as expected**  
An agent tried to touch a path outside the project directory — most commonly `cd /tmp` for some scratch/exploratory work (testing whether a package installs cleanly before committing to a real task, for example). OpenCode gates any file operation outside the project root behind a separate `external_directory` permission, distinct from `bash`/`edit`/`webfetch` — no agent in this harness has it granted, on purpose (broad filesystem access outside the repo is a real risk for an agent running unattended). `lead`, `task-implementer`, and `issue-resolver` are all explicitly instructed to stay inside the project directory and use `.scratch/` at the project root instead of `/tmp` for anything exploratory — if you're hitting this, either that instruction didn't take (worth a look at whether it's still present in your copy of the agent file) or the agent found some other reason to reach outside the sandbox. Don't "fix" this by granting `external_directory` — redirect the behavior inward instead; it's the safer fix and the one this harness is built around.

**`scripts/autorun.sh` stopped on a bash command that looks harmless (`bun run …`, a compound `cd … && git …`) rather than working around it**  
Headless `opencode run` auto-rejects a command whose permission it can't safely resolve unattended, and the commonest trigger is a compound one-liner (`cd <path> && …; cd .. && git …`) that opencode won't approve blind — not a hard-blocked dangerous command. `lead`, `task-implementer`, and `issue-resolver` now classify a refusal before reacting: a **hard-block denylist** command (`rm -rf`, force-push, `reset --hard`, `git clean -f`, branch deletion, `worktree remove --force`) still stops for you (by design — see the "Hard-blocked commands" rule), but an **incidental auto-reject** gets one semantics-preserving retry first (`git -C <path> …` instead of `cd <path> && git …`; stay in place instead of `cd ..`; split the one-liner). The one-rewrite budget is deliberate — enough to recover the compound-command case without letting an unattended agent keep probing. If the rewrite is refused again, or the path is genuinely outside the repo (`external_directory`, so no safe rewrite exists), the agent stops with `NEEDS_HUMAN`/`FAIL` and the subagent's summary carries the original command plus what it tried under `Denied command:`.

**A denied bash command still went through** (e.g. something that should have hit the `rm -rf` hard-block didn't)  
Check whether the actual command was a **compound** one — `cd somewhere && rm -rf thing`, or anything chained with `&&`/`;`/`|`. The denylist patterns exist in two forms per dangerous command: a prefix match (`"rm -rf*"`) and a match-anywhere-in-the-string version (`"*rm -rf*"`). Only the second form catches a dangerous command that isn't literally the first thing in the string. If you've added your own deny patterns, make sure to add both forms — a prefix-only pattern has a real gap for exactly the kind of multi-step one-liner an agent naturally writes when probing an environment. One exception to the dual-listing rule in the shipped agent files: the `task-implementer`/`issue-resolver`/`pair`/`characterizer` force-push family ships without an exact anymatch counterpart — `git push origin +*` has none, and `*push -f *` demands a trailing space — so compound variants of exactly those patterns are not fully covered there. Closing that gap (a `"*git push*"` deny on that family, as `lead` already carries) was deliberately not taken: the harness-streamlining spec (FR6) scoped those four agent files to `branch -D` plus force-push variants and routed the broader push-hardening to a user decision.

