# Phase Branches — workflow-patterns

Records each phase branch and the branch it was cut from. `phase-reviewer`
reads this for its diff baseline — never inferred from naming patterns.

| Phase | Branch | Base |
|---|---|---|
| 1 | feature/workflow-patterns-phase-1 | feature/workflow-patterns |
| 2 | feature/workflow-patterns-phase-2 | feature/workflow-patterns-phase-1 |
| 3 | feature/workflow-patterns-phase-3 | feature/workflow-patterns-phase-2 |
| 4 | feature/workflow-patterns-phase-4 | feature/workflow-patterns-phase-3 |
