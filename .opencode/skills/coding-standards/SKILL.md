---
name: coding-standards
description: Project coding standards (naming, module shape, error handling, style) — reference this when writing or fixing code if unsure of project conventions
---
> Edit this file to reflect your actual project conventions. It's written as
> a **pull** resource: `task-implementer` and `issue-resolver` load it only
> when they need it, so it costs nothing in sessions that don't touch it.
> The same content (or a trimmed version) is duplicated, deliberately, as a
> **push** resource inline in `phase-reviewer.md`, so the reviewer always
> enforces it without needing to remember to go look it up. If you edit
> this file, update phase-reviewer.md's inline copy too — see the note
> there.

## Module shape

Prefer fewer, larger ("deep") modules with a small public interface and
real logic hidden behind it, over many small ("shallow") files that each
expose most of their internals. Shallow modules are hard to test in
isolation and hard for an agent to navigate — reviewing them requires
tracing a dependency graph instead of understanding one module's shape.

Signals a module has gone shallow and should be merged/consolidated:
- Several single-purpose files that are only ever imported together
- A test file that has to mock three sibling modules to test one behavior
- An interface that re-exports most of its internal functions

## Naming

- Files: match the language's dominant convention rather than picking one
  globally — `snake_case.py` for Python, `kebab-case.ts` for TS
  modules/components, unless the framework forces otherwise (e.g. Next.js
  route file conventions).
- Variables/functions: `camelCase` in TS/JS, `snake_case` in Python.
  Booleans read as a yes/no question: `isActive`, `has_permission` — not
  `active`, `permission_flag`.
- Functions are verbs, types are nouns: `calculateTotal()` not
  `totalCalculation()`; `UserSession` not `SessionUserData`.
- No abbreviations that aren't domain-standard: `user` not `usr`, `request`
  not `req` — except where the ecosystem itself uses the abbreviation
  idiomatically (`req`/`res` in Express handlers, `db` for a database
  handle).
- Match vocabulary to `architecture.md`. If the architecture doc calls
  something a "session," the code shouldn't call it a "context" in one
  file and a "session" in another — naming drift between docs, code, and
  UI is a real cost, not a nitpick.
- Test names state the behavior, not the mechanism:
  `returns_204_on_successful_delete`, not `test_delete_2`.

## Error handling

- Fail loud in development, fail safe in user-facing production paths.
  Never swallow exceptions silently — if you catch something, either
  handle it meaningfully or re-raise/re-throw with added context.
- Use typed/structured errors, not bare strings. Python: custom exception
  classes per failure category (`ValidationError`, `NotFoundError`), not
  `raise Exception("bad input")`. TS: discriminated result types or typed
  Error subclasses, not throwing raw objects.
- Validate at the boundary, trust internally. Input validation (API
  request bodies, CLI args, external data) happens once at the edge of
  the system; internal functions can assume their inputs are already
  valid rather than re-checking everywhere.
- No empty catch blocks, ever. If a failure is genuinely ignorable, catch
  it explicitly and comment *why* it's safe to ignore — an empty catch is
  indistinguishable from a forgotten one.
- Errors carry enough context to debug without reproducing: include the
  relevant identifier (which user, which record, which request) in the
  error message or structured log fields — not just "operation failed."
- Don't use exceptions for expected control flow. "Item not found" in a
  lookup that regularly misses is a `None`/`Option` return, not a thrown
  exception; exceptions are for the unexpected.

## Style

- Formatter is the source of truth, not personal preference. Whatever
  `opencode.json`'s `formatter: true` wires up (Prettier for TS,
  Black/Ruff for Python) — run it, don't hand-format, don't argue with it
  in review.
- Imports: standard library → third-party → local, each group separated
  by a blank line, alphabetized within groups. Prefer configuring the
  linter/formatter (isort, eslint-plugin-import) to enforce this
  automatically over relying on agents to remember it by hand.
- One export per file for primary abstractions (a class, a main
  component, a service) — internal helper functions can stay unexported
  in the same file rather than spawning a new shallow module (ties back
  to the deep-modules guidance above).
- Comments explain *why*, not *what*: `// retry here because the upstream
  API rate-limits in bursts`, not `// increment counter`. If code needs a
  comment to explain what it does, that's usually a sign to rename
  something instead.
- No commented-out code committed. Delete it — git history is the
  archive, not the file itself.
- Line length: 100 for TS, 88–100 for Python (Black's 88 or Ruff's
  configurable default) — whatever the formatter enforces; don't fight it
  manually.

## Testing

- Tests live alongside the code they test unless the project convention
  says otherwise.
- Use the AAA pattern (Arrange/Act/Assert) — see task-implementer.md and
  issue-resolver.md for the detailed rules already baked into those agents.
