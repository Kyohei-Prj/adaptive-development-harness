# AI-Driven Development Patterns and When to Use Them

Each pattern is a different answer to the same question: **where does the human sit in the loop, and what evidence closes each cycle?** The patterns below run from tight human control to near-full autonomy. I've included what each is best at, where it breaks, and how it maps to your OpenCode setup.

## Quick selector

| Situation | Start with |
|---|---|
| Don't know what to build | Exploratory prototyping / vibe coding |
| Don't know if it's feasible | Spike / tracer bullet |
| Know what, unsure how | Interactive plan/build loop |
| Know what and how, clear tasks | Spec-driven vertical slices (your harness) |
| Behavior must be exact | Acceptance-test-first |
| Existing messy codebase | Characterization-first / strangler |
| Large repetitive change | Batch/fan-out automation |
| Work is well-defined and verifiable | Autonomous run with a gate |

## The patterns

**1. Exploratory prototyping ("vibe coding")**
Prompt, look at the result, steer by feel. No docs, minimal tests, throwaway by default.
- *Use when:* requirements are unknown, you need to see something to know what you want, demos, UI feel, learning a domain.
- *Breaks when:* the prototype quietly becomes production. Decide up front that it gets thrown away or rewritten.
- *Output to keep:* what you learned, not the code.

**2. Spike / feasibility probe**
Time-boxed throwaway code that answers one technical question ("does this API support X?", "can this handle 10k events/sec?"). Output is a written finding and a decision.
- *Use when:* an unfamiliar library, external API, performance target, or integration could invalidate the design.
- *Breaks when:* no question is stated, so it sprawls. Write the question and the exit criterion first.

**3. Tracer bullet / walking skeleton**
The thinnest real end-to-end slice through the riskiest boundaries (UI → API → DB → external service), using real dependencies rather than mocks.
- *Use when:* greenfield, multiple interacting components, architecture still unproven.
- *Breaks when:* it's built with mocks that hide exactly the risky boundary.
- *Difference from a spike:* a spike is thrown away; a tracer bullet is kept and grown.

**4. Interactive pair loop (your plan mode → build mode)**
Human and agent in one session: discuss a small change, implement it, you inspect, repeat. Plan and build are separated but the human reviews every step.
- *Use when:* high ambiguity, design decisions emerging as you code, unfamiliar territory, small-to-medium changes, anything where you're still forming the requirement.
- *Breaks when:* the session grows past the smart zone, or decisions live only in chat. Persist decisions in a file.
- *Cost:* your attention. It doesn't scale to long autonomous work.

**5. Spec-driven development (SDD)**
Write the requirements/architecture/plan first; agents implement from the docs. This is the core of your current workflow.
- *Use when:* requirements are stable and understood, work divides into clear tasks, multiple sessions or contributors need shared truth.
- *Breaks when:* the spec is written before the unknowns are resolved (your failure case). Pair it with spikes or rolling waves.
- *Variant:* **rolling-wave SDD**, where only the next 1-2 phases are detailed and later phases stay coarse.

**6. Vertical-slice incremental delivery**
Each phase crosses every layer and produces something runnable. Usually combined with SDD.
- *Use when:* you want reviewable, demoable progress and early integration feedback.
- *Breaks when:* slices are too big. Size them by uncertainty.

**7. Test-driven development with agents**
Agent writes failing tests, then implementation.
- *Use when:* business logic, algorithms, data transforms, anything with clear input/output rules.
- *Breaks when:* the same agent writes both, so the tests just encode its interpretation. Mitigate by having a different agent or you write/approve the tests.

**8. Acceptance-test-first (outer-loop BDD)**
Human-approved end-to-end scenarios (Given/When/Then) written before implementation and locked from the implementer. Unit TDD happens inside.
- *Use when:* the product-level behavior must be exact, there are many interacting requirements, or you've been burned by "tests pass, product wrong."
- *Breaks when:* scenarios are vague or auto-generated and never reviewed by you.

**9. Characterization-first (legacy/brownfield)**
Before changing anything, have the agent explore the code and write tests that capture current behavior. Then modify under that safety net.
- *Use when:* undocumented or legacy code, refactors, migrations.
- *Breaks when:* you skip it and trust the agent's reading of the code.

**10. Strangler / incremental migration**
Replace a system piece by piece behind a stable interface, running old and new side by side, comparing outputs.
- *Use when:* rewrites, framework or language migrations, replacing a component with live users.
- *Breaks when:* no equivalence check exists between old and new.

**11. Batch / fan-out automation**
One well-specified transformation applied across many files or repos by parallel agents (worktrees), each verified by the same check.
- *Use when:* API renames, lint fixes, dependency upgrades, mass doc or test generation, codemods.
- *Breaks when:* the transformation isn't uniform. Pilot on 3 files first.

**12. Generator-critic / independent review**
A separate agent (fresh context, ideally stronger model) reviews or attacks the output. Variants: red-team agent, adversarial tester, second-opinion design review.
- *Use when:* risky or security-sensitive changes, or as a quality gate on any pattern.
- *Breaks when:* the reviewer sees the same assumptions and spec errors the implementer did. It catches execution errors better than requirement errors.

**13. Autonomous long-run (hands-off)**
Agent loops against a machine-checkable goal (tests, benchmarks, build) with minimal human input. Your `/autorun` and `autorun.sh`.
- *Use when:* the plan is validated, completion criteria are objective, failure is cheap and reversible.
- *Breaks when:* the criteria are subjective or the plan is wrong. It just builds the wrong thing faster. Earn autonomy by first running phases interactively.

**14. Documentation-/decision-led (ADR) development**
Record decisions, alternatives, and rationale as the durable artifact; code follows.
- *Use when:* many sessions, many decisions, team handoffs, or architecture that will be revisited.
- *Breaks when:* docs are treated as permanent and drift. Archive or reconcile them.

**15. Eval-driven development (for AI-feature projects)**
When the product itself is LLM-based, write evals (datasets, graders) first and iterate prompts/architecture against them.
- *Use when:* the output is probabilistic and unit tests can't define "correct."
- *Breaks when:* the eval set is small or unrepresentative.

## Switching by project phase

A typical complex greenfield project might move like this:

| Project phase | Pattern(s) | Human involvement |
|---|---|---|
| Discovery | Grill + exploratory prototyping | High |
| De-risking | Spikes, then a tracer bullet | High |
| Foundation | Interactive pair loop + ADR log | High |
| Build-out of well-understood features | Rolling-wave SDD + vertical slices + TDD, with acceptance tests | Medium (demo gate per phase) |
| Repetitive/mechanical work | Fan-out automation, autonomous run | Low |
| Hardening | Independent review, architecture review, e2e acceptance | Medium |
| Maintenance | Characterization-first, strangler for big changes | Medium |

## Choosing by project characteristics

Ask four questions:

1. **How well do I know *what* to build?** Low → prototype or grill. High → spec.
2. **How well do I know *how*?** Low → spike or tracer bullet. High → vertical slices.
3. **How expensive is a mistake?** High → acceptance tests, independent review, human gates. Low → more autonomy.
4. **Is "done" machine-checkable?** Yes → TDD, autonomous run, fan-out. No → keep the human in the loop.

**Rule of thumb for switching:** move toward more autonomy as uncertainty drops and verifiability rises; move back toward the interactive loop whenever a review surfaces a surprise or a phase's results contradict the plan. Treat a surprise as a signal to change patterns, not as a deviation to log and push through.

## Applying it to your OpenCode setup

Your harness currently covers patterns 5, 6, 7, 12, 13, and parts of 14. Gaps worth filling, roughly in priority order:

1. **Spike task type** and a tracer-bullet Phase 0 (patterns 2, 3)
2. **Acceptance-test-first** with locked, human-approved scenarios (8)
3. **A documented "interactive mode" entry point** so your plan/build loop is a sanctioned pattern with a decision-log file, not a fallback (4, 14)
4. **Characterization-first command** for brownfield work (9)
5. **Pattern selection step in `/plan`**: the planner asks the four questions above and records the chosen pattern per phase in `implementation-plan.md` (for example `[mode: interactive]`, `[mode: sdd]`, `[mode: autorun]`)
