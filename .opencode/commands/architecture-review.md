---
description: Run a whole-codebase architecture scan (shallow modules, dead code, naming drift) independent of any single phase — run this periodically, not just after each phase review
agent: lead
---
Delegate to `architecture-reviewer` to scan the codebase for architecture
drift.

Scope: $ARGUMENTS (a path to focus on, or empty to scan the whole repo).

Steps:
1. Delegate to `architecture-reviewer` via the Task tool, passing the scope if one was given.
2. Present the findings to me as-is — do not filter, summarize away, or act on them yourself.
3. This is diagnostic only. If I want any finding acted on, turn it into a tagged task in the relevant `implementation-plan.md` (or a new small slug of its own via `/plan` if it's substantial) rather than fixing it inline here — `architecture-reviewer` doesn't edit files, and neither should you in this command.
