# Workflow: Grill → Plan → Implement → Feedback

4-stage AI-driven workflow on top of OpenCode. This file is navigation only — full prose lives in README.md (sections cited inline). All planning docs for a unit of work live under `docs/<slug>/`; templates and `[type: …]` task-type tag rules: the `planning-docs` skill.

## Stages

0. **Grill** (optional; recommended for anything non-trivial) — `/grill <idea>`: alignment interview, no docs written; close the session, then start Plan fresh. README → *The Stages, Stage 0*.
1. **Plan** — `/plan <idea or grill summary>`: `planner` writes `docs/<slug>/` — architecture, spec, implementation-plan (phases as vertical slices), feedback-log; commit the docs manually before Implementing. README → *Stage 1*.
2. **Implement** — `/implement-phase <n> <slug>`: `lead` records the phase base in `docs/<slug>/phase-branches.md`, creates `feature/<slug>-phase-<n>`, delegates every task to `task-implementer`, ends with a docs-only phase-complete commit; `[parallel-with]` tasks run in worktrees under `.worktrees/`, merged back sequentially. README → *Stage 2*; mechanics: the `phase-lifecycle` skill.
3. **Feedback** — `/review-phase <n> <slug>`: `lead` runs `phase-reviewer` (read-only, diffs against the recorded base) → `issue-resolver` → `doc-updater`; merging to main is the user's job. README → *Stage 3*.

## Automation & maintenance

- `/autorun <slug>` — full Implement → Feedback cycle for all phases in one `lead` session, one checkpoint per phase. README → *Automated Full Run, Option A*.
- `scripts/autorun.sh <slug>` — fully hands-off: one fresh `opencode run` process per phase, output to `docs/<slug>/autorun.log`; preferred over `/autorun` for long plans. README → *Automated Full Run, Option B*.
- `/finalize <slug>` before merging to main; `/archive <slug>` after merging (judgment call — nothing archives automatically); `/architecture-review [path]` periodically, tied to no slug. README → *Maintenance Commands*.

## Working rules

- **Context hygiene** — content edits happen only in Task subagents; primary sessions hold summaries, not diffs (`lead`'s bookkeeping edits are the sole exception). README → *Tips & Conventions, "Smart zone / dumb zone"*.
- **Stay inside the project directory** — nothing outside the repo; scratch work goes in `.scratch/` at the project root. README → *Tips & Conventions, "Agents stay inside the project directory, on purpose"*.
- **Hard-blocked commands** — force-push, `rm -rf`, `git reset --hard`, `git checkout -- .`/`--force`, `git clean -f`, `git branch -D` are hard-blocked for every bash agent regardless of task phrasing; authoritative list: each agent's own frontmatter `bash` block; per-agent permission tables: README → *Agents Reference* and `.opencode/agents/*.md`. If a task genuinely needs a denied command: stop and report — that decision stays with the user. README → *Tips & Conventions* (why the hard-blocked commands are hardcoded, why copies aren't DRYed), *Troubleshooting* (dual prefix/anymatch patterns).
- **Commit explicit paths** — each agent commits only its own work as its end-of-task step; never `git add .`/`-A`; `lead` commits only `docs/<slug>/`. README → *Stage 2*.
- **Deferred, not dropped** — issues declined at review and tasks skipped after a FAIL are logged in `feedback-log.md` and resurface as a heads-up in later phases. README → *Stage 3*.

# Behavioral Guidelines

1. **Think before coding** — state assumptions; present interpretations instead of picking silently; ask instead of guessing.
2. **Simplicity first** — minimum code that solves the problem; no speculative features, abstractions, or configurability.
3. **Surgical changes** — touch only what the task needs, match existing style; remove only orphans your change creates, mention (don't delete) pre-existing dead code.
4. **Goal-driven execution** — turn tasks into verifiable goals (failing test, check) and loop until verified.
5. **Tools** — use the `context7` MCP tool for up-to-date library/framework docs.
