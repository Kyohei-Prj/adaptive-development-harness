---
description: "Run the interactive pair loop for a slug: discuss → one small implement step → I inspect → commit → decisions.md entry — the entry point the [mode: interactive] mode gate points to"
agent: pair
---
Run the interactive pair loop for `$1`. This command takes exactly ONE argument — the slug, or the word `new`. There is deliberately no phase argument: the mode gate in `implement-phase` refuses an `[mode: interactive]` phase by pointing at `/interactive <slug>` alone, because the pair loop is a per-slug human-paced loop, not per-phase batched delegation.

## Resolve the slug before the first loop step

1. `$1` is `new` → propose a short kebab-case slug for what we're working on, confirm it with me, then create a minimal slug dir `docs/<slug>/` containing ONLY `decisions.md` — a `# Decisions — <slug>` header and no entries yet — then commit that one file (`git add docs/<slug>/decisions.md && git commit -m "docs(<slug>): start decision log"`), so the bootstrap is never left sitting untracked on the loop's branch. Do NOT create the other planning docs: architecture/spec/implementation-plan are what `/plan` produces later if this work graduates to SDD.
2. `docs/$1/decisions.md` exists → this is a continuation: read `docs/$1/decisions.md` end-to-end before anything else. Earlier entries are aligned input — don't re-litigate a logged decision unless I raise it.
3. `$1` looks like a slug but `docs/$1/decisions.md` doesn't exist → ask me whether this is new work; if yes, bootstrap exactly as in case 1, if no, stop and re-confirm the slug.

Then state the working branch: whatever branch is checked out now is the loop's branch — never a phase branch, never a new worktree (your rules). If `git status` shows unrelated uncommitted changes, flag them before the first step so per-step explicit-path commits never mix with them.

## The loop protocol — five steps, repeated until we stop

1. **Discuss** — agree the ONE next small step: what to change, why, what done looks like. Wait for my go-ahead before touching any file.
2. **Implement one small step** — only the step just discussed. Bigger chunks may go to `task-implementer`/`explore` delegation, but the delegation's output still goes through step 3 like any other step.
3. **I inspect** — show me what changed (summary plus a targeted look at the diff), then WAIT for my explicit approval. This is the inspect-after-each-step rule: never implement two steps without my inspection between them, never batch steps up for one end-of-session review.
4. **Commit** — once I approve, immediately stage exactly the paths this step touched (`git add <path> ...`) and commit: one reviewable commit per approved step, explicit paths only, never an unapproved step.
5. **Log** — append this step's decision to `docs/<slug>/decisions.md` as a dated mini-ADR entry (decision / why / alternatives considered; append-only, never rewrite earlier entries — the `planning-docs` skill owns the exact entry format), and commit that entry immediately after the step's commit, so the loop never ends with a decision sitting uncommitted.

After step 5, return to step 1. Say the word and we stop anytime — `docs/<slug>/decisions.md` is the durable record and becomes `/plan`'s aligned input when this work graduates to the delegated flow.
