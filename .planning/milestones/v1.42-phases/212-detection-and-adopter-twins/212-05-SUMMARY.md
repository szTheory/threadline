---
phase: 212-detection-and-adopter-twins
plan: 05
subsystem: testing
tags: [ecto, postgresql, triggers, adopter-twin, example-app]

# Dependency graph
requires:
  - phase: 212-detection-and-adopter-twins
    provides: "Threadline.Health.trigger_findings/1 with all five finding codes (212-01/02/03)"
  - phase: 211-read-side-agreement
    provides: "Threadline.history/3 composite/override id argument shapes (D-01)"
provides:
  - "example app TWIN-01 fixture tables for every table shape (text PK, composite PK, no-PK/override, two-schema same-named table, 62-byte long name)"
  - "generator-produced fixture trigger migration pinned by a regenerate-diff contract test"
  - "per-shape Threadline.history/3 round trips including all six required edge cases"
  - "no trigger_findings/1 findings for any shape_* fixture"
  - "fixtures confined to the ExUnit lane, never reaching mix ecto.migrate or the browser lane"
affects: [212-06-hex-evaluator-twin, 213-upgrade-guide]

# Actuals (#2632)
actuals:
  tokens: 19204
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Fixture migrations directory outside priv/repo/migrations, applied only by test_helper.exs (up before suite, down in ExUnit.after_suite) so mix ecto.migrate / the browser lane never see them"
    - "THREADLINE_E2E=1 config guard: shape_fixture_tables is %{} in the browser lane, real entries otherwise, merged into :trigger_capture tables via Map.merge/2 (Config replaces maps, so config.exs would be dead here)"
    - "Regenerate-diff contract: seed a temp migrations dir with the committed non-generated siblings, call Mix.Tasks.Threadline.Gen.Triggers.run/1 directly, compare version-stripped basename + metadata-stripped AST, with an edited-copy control to prove the comparison isn't vacuous"

key-files:
  created:
    - examples/threadline_phoenix/priv/shape_fixtures/migrations/.formatter.exs
    - examples/threadline_phoenix/priv/shape_fixtures/migrations/20260926100000_create_shape_fixtures.exs
    - examples/threadline_phoenix/priv/shape_fixtures/migrations/20260926100001_threadline_triggers_shape_code_keyed_shape_composi_f2f800f9eb80.exs
    - examples/threadline_phoenix/test/support/shape_fixtures.ex
    - examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_migration_contract_test.exs
  modified:
    - examples/threadline_phoenix/config/test.exs
    - examples/threadline_phoenix/test/test_helper.exs

key-decisions:
  - "Followed the plan's D-19 deviation as instructed: the shape_join primary_key: override and the two shape_twin mask: entries live in config/test.exs, not config/config.exs, because Config replaces (rather than merges) the :trigger_capture tables map that config/test.exs already sets for ticket_replies/posts."
  - "Chose shape_long_name_padded_to_prove_sixty_byte_identifiers_work_ok (62 bytes) for the long-name fixture, confirmed via byte_size before committing."
  - "The tracer feedback gate (auto mode, workflow.auto_advance=true) re-ran Task 1's <verify> after commit; it passed, so Tasks 2 and 3 expanded on the proven slice without a checkpoint."

requirements-completed: [TWIN-01]

coverage:
  - id: D1
    description: "Every TWIN-01 table shape exists in the example app with a generator-produced (never hand-edited) trigger migration"
    requirement: "TWIN-01"
    verification:
      - kind: unit
        ref: "examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_migration_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each shape's insert/update/delete round-trips through Threadline.history/3, including composite keyword-list ids, the join override, cross-schema twin isolation, the 60-63 byte name boundary, empty-key, multi-byte encoding, ordering, and above-2^53 precision edges"
    requirement: "TWIN-01"
    verification:
      - kind: unit
        ref: "examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "trigger_findings/1 reports nothing for any shape_* fixture table"
    requirement: "TWIN-01"
    verification:
      - kind: unit
        ref: "examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs#trigger_findings/1 reports nothing for the fixture tables"
        status: pass
    human_judgment: false
  - id: D4
    description: "Fixtures never reach the browser lane: no shape_* table or shapes schema survives mix verify.example, and mix ecto.migrate (the browser lane's migration path) never touches priv/shape_fixtures/migrations"
    requirement: "TWIN-01"
    verification:
      - kind: unit
        ref: "psql check: select count(*) from pg_tables where tablename like 'shape\\_%' (0) after mix verify.example"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-09-26
status: complete
---

# Phase 212 Plan 05: Example App Adopter Twin (TWIN-01) Summary

**The example Phoenix app now carries a fixture table for every TWIN-01 shape (text PK, composite PK, no-PK/override, two-schema same-named table, 62-byte long name), each with a generator-produced trigger migration pinned by a regenerate-diff contract test, full history round trips, and zero health findings — all confined to the ExUnit lane so the frozen browser-lane screenshot baselines never see them.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-09-26T00:35:00Z (approx, first tool call)
- **Completed:** 2026-09-26T01:30:00Z (approx)
- **Tasks:** 3
- **Files modified:** 8 (6 created, 2 modified)

## Accomplishments
- Created `priv/shape_fixtures/migrations/` with hand-written DDL for `shape_code_keyed`, `shape_composite`, `shape_join` (+ `shape_join_pair` unique index), `shape_twin` (public and `shapes` schema), and the 62-byte `shape_long_name_padded_to_prove_sixty_byte_identifiers_work_ok` table.
- Generated the trigger migration for all six table specs via `mix threadline.gen.triggers` in the example app and committed it unedited (D-20).
- Added the `shape_join` `primary_key:` override and `shape_twin`/`shapes.shape_twin` `mask:` entries to `config/test.exs`, guarded to `%{}` when `THREADLINE_E2E=1`.
- Wired `test/test_helper.exs` to migrate the fixture path up before the suite and down in `ExUnit.after_suite`, verified by a direct psql check that no `shape_*` table survives.
- Wrote six Ecto schema modules (`CodeKeyed`, `Composite`, `Join`, `TwinPublic`, `TwinShapes`, `LongName`) in `test/support/shape_fixtures.ex`.
- Wrote 9 round-trip tests covering every shape and every named edge case (boundary, adjacency, empty, encoding, ordering, precision), plus a no-findings assertion for the fixtures.
- Wrote a 4-test regenerate-diff contract that pins the committed trigger migration against fresh generator output, including a non-vacuous edited-copy control.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer - fixture DDL, generator-produced trigger migration, suite-scoped migrate up/down** - `ffe84e7e` (feat)
2. **Task 2: Expand - round trips for every shape, edge cases, no findings** - `d14efe60` (test)
3. **Task 3: Expand - regenerate-diff contract for the committed fixture trigger migration** - `55260965` (test)

_No separate plan-metadata commit: `.planning/` is excluded from git in this repository per project convention (see CLAUDE.md / memory: never `git add .planning/`); this SUMMARY, STATE.md, and ROADMAP.md are hand-checked artifacts, not committed by this executor._

## Files Created/Modified
- `examples/threadline_phoenix/priv/shape_fixtures/migrations/.formatter.exs` - formatter config for the fixture migrations directory
- `examples/threadline_phoenix/priv/shape_fixtures/migrations/20260926100000_create_shape_fixtures.exs` - hand-written DDL for the six fixture shapes
- `examples/threadline_phoenix/priv/shape_fixtures/migrations/20260926100001_threadline_triggers_shape_code_keyed_shape_composi_f2f800f9eb80.exs` - unedited `mix threadline.gen.triggers` output
- `examples/threadline_phoenix/config/test.exs` - `shape_join` override + `shape_twin`/`shapes.shape_twin` masks, THREADLINE_E2E-guarded
- `examples/threadline_phoenix/test/test_helper.exs` - migrates the fixture path up/down around the ExUnit suite
- `examples/threadline_phoenix/test/support/shape_fixtures.ex` - the six fixture Ecto schemas
- `examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs` - 9 round-trip/edge-case/health tests
- `examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_migration_contract_test.exs` - 4-test regenerate-diff contract

## Decisions Made
- D-19 config placement deviation (recorded by the plan itself, honored as written): the `primary_key:` override and `mask:` entries live in `config/test.exs`, never `config/config.exs`, so the browser lane's `THREADLINE_E2E=1` guard can omit them entirely without fighting `Config`'s map-replacement semantics.
- Aliased `Mix.Tasks.Threadline.Gen.Triggers` as `Triggers` in the contract test (matching the existing `test/mix/tasks/threadline/gen_triggers_test.exs` precedent) to satisfy `mix credo --strict`'s alias-usage check, while keeping a moduledoc line naming the fully-qualified call so the plan's literal "calls Gen.Triggers.run" intent stays traceable in the source.
- Edited-copy control in the contract test targets the literal `"CREATE OR REPLACE TRIGGER"` (not `"CREATE TRIGGER"`, which never appears in PostgreSQL 14+ generator output) so the non-vacuousness assertion actually exercises a real character flip.

## Deviations from Plan

None beyond the plan's own recorded D-19 deviation (config/test.exs placement), which was implemented exactly as the plan specified.

## Issues Encountered
- The shared PostgreSQL instance on this machine intermittently hit `too_many_connections` (100 max) from unrelated concurrent projects' test suites (`rindle_smoke_app_*_test`, etc.), transiently failing `mix test` runs with no relation to this plan's changes. Resolved by waiting for `pg_stat_activity` to drop before retrying; no code or config change was needed.
- `mix credo --strict` initially flagged the contract test's fully-qualified `Mix.Tasks.Threadline.Gen.Triggers.run/1` call as a "Nested modules could be aliased" design suggestion; fixed by aliasing per existing repo precedent (see Decisions Made).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- TWIN-01 remains unticked in REQUIREMENTS.md as instructed; 212-06 (hex evaluator twin) completes it.
- The example app's fixture pattern (separate migrations path, THREADLINE_E2E config guard, regenerate-diff contract) is directly reusable for the hex evaluator's own minimal fixtures in 212-06.
- No blockers. Root `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix credo --strict` (touched files), `mix verify.example` (130 tests, 0 failures), and full root `mix test` (9 properties, 2184 tests, 0 failures, 1 excluded) all pass after this plan's last commit. Post-suite psql check confirms zero `shape_*` tables remain in `threadline_phoenix_test`.

---
*Phase: 212-detection-and-adopter-twins*
*Completed: 2026-09-26*

## Self-Check: PASSED

All created files verified present on disk; all three task commits (`ffe84e7e`, `d14efe60`, `55260965`) verified present in `git log --oneline --all`.
