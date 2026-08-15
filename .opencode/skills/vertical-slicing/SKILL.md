---
name: vertical-slicing
description: How to structure implementation-plan.md phases as vertical slices (tracer bullets) instead of horizontal layers, so every phase produces reviewable end-to-end feedback
---
## The problem

Left to its own tendencies, an agent (and many humans) will plan work
horizontally: all schema first, then all service/API code, then all
frontend. This feels tidy but produces zero feedback until the very last
phase, when every layer gets wired together for the first time — exactly
when integration bugs are most expensive to find.

## The fix: vertical slices

Also called tracer bullets. Each phase should cut through every layer the
feature touches — schema, service, API, UI — to deliver one thin but
*complete* piece of real behavior. After the phase ships, there should be
something a human can actually exercise (click, curl, run) end to end.

## Test for a phase

Ask: "After this phase merges, can someone outside the team see or use
something real?"

- **Yes** → it's a vertical slice. Good.
- **No** ("the schema is ready" / "the service layer is done") → it's a
  horizontal layer wearing a phase's clothing. Either merge it forward into
  the slice it enables, or, if it's genuinely foundational and blocking
  everything else (e.g. auth scaffolding with no user-visible behavior of
  its own), mark it explicitly as infrastructure and keep it as small as
  possible — don't let infrastructure phases sprawl into "all the schema
  the whole feature will ever need."

## Example

Building a gamification feature ("earn points for completing lessons,
streaks, a leaderboard"):

**Horizontal (avoid):**
- Phase 1: Gamification DB schema + service layer
- Phase 2: Points API endpoints
- Phase 3: Streak logic
- Phase 4: Dashboard UI

Nothing is reviewable until Phase 4. Any wrong assumption made in Phase 1
about the schema won't surface until three phases later.

**Vertical (prefer):**
- Phase 1: Award points for lesson completion, visible on the dashboard
  (thin schema + service + one API route + minimal UI — but *real*, end to
  end)
- Phase 2: Streak tracking, wired into the same completion flow and visible
  alongside points
- Phase 3: Retroactive backfill for existing records
- Phase 4: Leaderboard
- Phase 5: Polish and edge cases

Each phase after Phase 1 extends something already working, rather than
assembling parts that have never been connected.

## Applying this in implementation-plan.md

- State the phase's Goal as user-visible or system-visible behavior, not a
  layer name. Use the phrase "vertical slice" in the goal line as a
  deliberate steering cue.
- If a phase's task list only touches one architectural layer, treat that
  as a signal to re-slice before finalizing the plan — not a rule to break
  reflexively; some phases (e.g. one-time infra setup) are legitimately
  layer-only, but they should be the exception, explicitly called out, not
  the default shape of every phase.
- Mark cross-phase blocking relationships explicitly so `[parallel-with: X]`
  tags in later phases can be trusted.
