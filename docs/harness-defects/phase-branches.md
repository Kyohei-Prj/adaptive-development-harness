# Phase Branches — harness-defects

Records each phase branch and the branch it was cut from. `phase-reviewer`
reads this for its diff baseline — never inferred from naming patterns.

| Phase | Branch | Base |
|---|---|---|
| 1 | feature/harness-defects-phase-1 | harness-defects |
| 2 | feature/harness-defects-phase-2 | feature/harness-defects-phase-1 |
| 3 | feature/harness-defects-phase-3 | feature/harness-defects-phase-2 |
| 4 | feature/harness-defects-phase-4 | feature/harness-defects-phase-3 |
