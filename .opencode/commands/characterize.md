---
description: "Characterization-first entry point for brownfield work: delegate to `characterizer`, which pins a target module's CURRENT behavior with passing tests and commits test files only"
agent: lead
---
Run the characterization of `$1`.

`characterizer` is the single authoritative carrier of the characterization ruleset — the read → capture → verify → commit rules, the no-behavior-change invariant, and the commit-test-files-only rule all live in its agent file and are deliberately not restated here. This command defines only what the command itself adds: argument handling, delegation, and the report format.

Steps:
1. `$1` is the path of the module to characterize. If it is empty, ask me for the target — never guess one.
2. Delegate to `characterizer` via the Task tool, passing the target path plus the pointers it expects (test framework and conventions, where its tests should live — see the "You will receive" note in its agent file).
3. Present its summary to me in the report format, three parts, named exactly as `characterizer`'s own summary block names them so the two files cannot drift:
   - **Behaviors captured** — its `Behaviors captured:` line, verbatim.
   - **Test files committed** — its `Files changed:` line, which must be test files only.
   - **Blind spots** — its `Blind spots:` line; an honest gap list beats an implied-complete green set.

   Do not filter or condense away any of the three parts. If `Test result:` reports FAIL or its `Denied command:` line is not "none", relay that verbatim too rather than softening it.
