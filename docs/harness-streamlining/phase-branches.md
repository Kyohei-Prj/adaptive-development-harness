# Phase Branches — harness-streamlining

Records each phase branch and the branch it was cut from. `phase-reviewer`
reads this for its diff baseline — never inferred from naming patterns.

| Phase | Branch | Base |
|---|---|---|
| 1 | feature/harness-streamlining-phase-1 | harness-streamlining |
| 2 | feature/harness-streamlining-phase-2 | feature/harness-streamlining-phase-1 |
| 3 | feature/harness-streamlining-phase-3 | feature/harness-streamlining-phase-2 |
| 4 | feature/harness-streamlining-phase-4 | feature/harness-streamlining-phase-3 |
| 5 | feature/harness-streamlining-phase-5 | feature/harness-streamlining-phase-4 |
