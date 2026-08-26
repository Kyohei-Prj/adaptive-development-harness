---
name: phase-lifecycle
description: Shared mechanics for phase branch setup, parallel-task worktree execution, and issue-resolution delegation. Pulled by lead from implement-phase, implement-phase-auto, autorun, review-phase, review-phase-auto, and finalize — this is the single source of truth for these procedures; the command files should only state what's unique to them (confirmation policy, report format), not re-describe the mechanics.
---
> This skill exists because these three procedures used to be copy-pasted
> almost verbatim across six command files, and had already started to
> drift (inconsistent step numbering, one copy quietly losing a piece of
> the conflict-handling instruction). If you're editing the mechanics of
> phase-branch setup, worktree handling, or issue delegation, edit them
> **here** — the command files reference this skill by name and shouldn't
> contain their own copy of the steps below.

## A. Phase branch setup

Before delegating any task for a new phase N of slug `<slug>`:

1. Capture the current branch before creating anything new:
   `BASE=$(git branch --show-current)`
2. Create and switch to the phase branch:
   `git checkout -b feature/<slug>-phase-N`
3. Record the base explicitly — never let a later step infer it from a
   naming pattern. Append a row to `docs/<slug>/phase-branches.md`,
   creating the file with its header first if this is Phase 1:
   `| N | feature/<slug>-phase-N | <value of BASE> |`

This file is what `phase-reviewer` reads later for its diff baseline — a
missing or skipped row means review can't determine what changed in this
phase versus what changed in a prior one. Commit it along with the rest of
the phase's changes; don't leave it staged-but-uncommitted.

## B. Parallel task execution (worktrees)

Applies whenever a phase's task list includes `[parallel-with: ...]` tags.

Group tasks by their `[parallel-with: ...]` tags. Tasks with no such tag
run sequentially in the main working tree, exactly as before — do not
create a worktree for a task that isn't part of a parallel group.

For each parallel group (2+ tasks tagged parallel with each other):

1. For each task in the group, create an isolated git worktree on its own
   branch off the current phase branch:
   `git worktree add -b task/<slug>-<task-id> .worktrees/<slug>-<task-id>`
2. Delegate each task to `task-implementer` via the Task tool, telling it
   explicitly: "Your working directory for this task is
   `.worktrees/<slug>-<task-id>` — cd there first, and don't touch files
   outside it."
3. Once **all** tasks in the group report done, merge each task branch
   back into the phase branch **sequentially, one at a time — never in
   parallel**: `git merge task/<slug>-<task-id>`.
   **If a merge conflict occurs at any point: stop immediately. Do not
   attempt to resolve it automatically.** In an interactive command, report
   the conflict and wait for direction. In a headless command, this is a
   `NEEDS_HUMAN` stop condition (see the `phase-lifecycle` status-trailer
   section, part D) — the run cannot continue unattended past a conflict.
4. After a successful merge, clean up:
   `git worktree remove .worktrees/<slug>-<task-id>` and
   `git branch -d task/<slug>-<task-id>`.

For every delegation in this procedure (parallel or sequential), pass:
task description and acceptance criteria, the `[type: tdd]` or
`[type: smoke]` tag (copied verbatim from the plan), and relevant
file/architecture pointers.

## C. Issue-resolution delegation

Applies whenever `phase-reviewer` (or, for `/finalize`, `phase-reviewer` in
finalize mode) has returned blocking and/or non-blocking issues.

The mechanics are always the same regardless of confirmation policy:

1. Issues are resolved **one at a time, sequentially — never in parallel.**
   Delegate each to `issue-resolver` via the Task tool, passing the issue
   description, affected file(s), relevant acceptance criteria, and
   architecture pointers.
2. **Never delegate "risks for future phases" to `issue-resolver`.** They
   are speculative concerns about work that hasn't happened yet, not bugs
   to fix — they only ever get logged by `doc-updater`, never acted on.
3. If `issue-resolver` reports FAIL on an issue: stop attempting that
   issue. What happens next depends on which command called this
   procedure — see that command's own stop-condition / confirmation rules
   (this skill only covers the delegation mechanics, not what "stop" means
   for a given caller).
4. Any issue that ends up not fixed — whether declined by the user in an
   interactive command, or skipped after a FAIL in a headless one — is a
   **deferred issue**, not a dropped one. It must be logged by
   `doc-updater` in the same feedback-log.md entry as everything else, in
   its own "Deferred issues" section, distinct from "risks for future
   phases" (a deferred issue is a confirmed real finding against code that
   already exists; a risk is a speculative concern about work that hasn't
   happened yet). Deferred issues resurface as a heads-up at the start of
   later phases the same way risks do.

## D. Status trailer format (headless commands only)

Applies to `implement-phase-auto`, `review-phase-auto`, and `finalize` —
any command that may be invoked via `opencode run` from `scripts/autorun.sh`
with no human present to ask anything of.

Always end the response with exactly one of these as the literal last line:

```
AUTORUN_STATUS: OK
AUTORUN_STATUS: FAIL: <one-line reason>
AUTORUN_STATUS: NEEDS_HUMAN: <one-line reason>
```

- `OK` — the step completed and committed successfully.
- `FAIL` — a genuine failure (a task or issue-resolver reported FAIL and
  it wasn't safe to skip).
- `NEEDS_HUMAN` — nothing is broken, but something requires a judgment
  call an unattended run shouldn't make alone (a worktree merge conflict,
  an ambiguous issue description, etc.).

Produce this trailer every time, whether the command was invoked
interactively or headlessly — there's no reliable way to tell which from
inside the command, and omitting it in a headless run makes
`scripts/autorun.sh` fail closed (treated as `NEEDS_HUMAN`) rather than
silently assuming success. In an interactive session a human just ignores
the line; that's a fine default to fail toward.

**Do not write anything after the trailer line — no closing remark, no
offer to continue, no question.** The trailer must be the literal end of
the entire response, not just the end of the "report" part of it. This
matters even beyond readability: `scripts/autorun.sh` extracts every
`text` segment you produce in the turn and searches all of it for this
line, so a trailing remark won't make the script miss the trailer — but a
human skimming the transcript later may end up reading a trailing "let me
know if..." as if it were still part of an unfinished response. Say
everything you need to say, then stop.
