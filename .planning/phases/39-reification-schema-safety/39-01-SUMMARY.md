---
phase: 39-reification-schema-safety
plan: 01
subsystem: query
tags: [elixir, ecto, as_of, schema-loading, time-travel]

# Dependency graph
requires:
  - phase: 38-core-as-of-reconstruction
    provides: snapshot-first map output and delete/genesis-gap handling
provides:
  - opt-in struct reification for `Threadline.as_of/4`
  - loose historical loading via Ecto-native casting
  - explicit cast error tuples for invalid snapshots
affects: [phase 40, time-travel docs, schema-drift handling]

# Tech tracking
tech-stack:
  added: []
  patterns: [Ecto.embedded_load/3, opt-in cast flag, explicit cast-error tuple]

key-files:
  created: [.planning/phases/39-reification-schema-safety/39-01-PLAN.md, .planning/phases/39-reification-schema-safety/39-01-SUMMARY.md, .planning/phases/39-reification-schema-safety/39-CONTEXT.md]
  modified: [.planning/STATE.md, .planning/ROADMAP.md, .planning/REQUIREMENTS.md, lib/threadline/query.ex, test/threadline/query_test.exs]

decisions:
  - "Keep the default `as_of/4` return shape map-only; enable struct reification only behind `cast: true`."
  - "Use `Ecto.embedded_load/3` so unknown historical keys are ignored and current schema defaults still apply."
  - "Return `{:error, {:cast_error, message}}` when a historical snapshot cannot be loaded into the current schema."

metrics:
  duration: 20m
  completed: 2026-04-25
---

# Phase 39: Reification & Schema Safety Summary

**Opt-in struct reification for `as_of/4` with loose Ecto loading and explicit cast failures**

## Performance

- **Duration:** 20m
- **Completed:** 2026-04-25
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added regression coverage for `cast: true`, loose historical loading, and explicit cast failure handling.
- Implemented cast-aware snapshot loading in `Threadline.Query.as_of/4` using `Ecto.embedded_load/3`.
- Preserved the phase 38 default map contract plus delete/genesis-gap behavior.

## Task Commits

1. **Task 1: Lock the cast contract in failing tests** - `51af704` (test)
2. **Task 2: Add cast-aware reconstruction to the query path** - `68e830e` (feat)

## Files Created/Modified
- `.planning/phases/39-reification-schema-safety/39-01-PLAN.md` - executable phase plan
- `.planning/phases/39-reification-schema-safety/39-01-SUMMARY.md` - execution summary
- `lib/threadline/query.ex` - cast-aware `as_of/4` loader
- `test/threadline/query_test.exs` - struct reification and drift coverage

## Decisions Made
- `cast: true` returns a plain schema struct inside the existing `{:ok, _}` tuple.
- Unknown historical fields are ignored rather than preserved.
- Invalid loads return an explicit cast-error tuple instead of falling back to maps.

## Deviations from Plan

None - the phase executed as planned.

## Issues Encountered

- `mix precommit` was not available in this repo, so formatting was verified with `mix format --check-formatted` and behavior with `mix test test/threadline/query_test.exs --seed 0`.

## Self-Check

PASSED

- FOUND: `.planning/phases/39-reification-schema-safety/39-01-SUMMARY.md`
- FOUND: commits `51af704` and `68e830e`

---
*Phase: 39-reification-schema-safety*
*Completed: 2026-04-25*
