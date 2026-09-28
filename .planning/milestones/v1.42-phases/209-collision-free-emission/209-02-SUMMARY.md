---
phase: 209-collision-free-emission
plan: 02
subsystem: capture-generator
status: complete
tags: [capture, triggers, generator, rerun-detection, property-testing]
requires:
  - Threadline.Test.NoticeGuard (plan 01), active but silent here: no real-PG DDL
provides:
  - Threadline.Mix.TriggerMigration.parse_triggers/1 (@doc false)
  - Threadline.Mix.TriggerMigration.rerun?/2 keyed on the (schema, table) pair
  - Threadline.Test.LegacyTriggerSQL (frozen 0.9.0 / 0.10.0 / 0.10.2 trigger renderers + migration_source/3)
  - Threadline.Test.NamingGenerators (pair_gen/0, pair_of_pairs_gen/0, ident/1, fixed_ident/1, public/1)
affects:
  - later plans reuse parse_triggers/1 for the sibling-exposure advisory scan and LegacyTriggerSQL for real-PG upgrade fixtures
tech-stack:
  added: []
  patterns:
    - regex held as a source string in a module attribute and compiled at call time with the "i" flag
    - frozen historical-SQL fixtures in test/support that reference no current module
    - round-trip property built from the current TriggerSQL.create_trigger output
key-files:
  created:
    - test/support/legacy_trigger_sql.ex
    - test/support/naming_generators.ex
    - test/threadline/mix/trigger_migration_property_test.exs
  modified:
    - lib/threadline/mix/trigger_migration.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - test/threadline/mix/trigger_migration_test.exs
    - test/mix/tasks/threadline/gen_triggers_test.exs
    - test/threadline/capture/naming_property_test.exs
decisions:
  - "Unquoted identifiers are lowercased with String.downcase(_, :ascii), the same ASCII-only folding PostgreSQL does"
  - "The parse clause for a qualified ON clause has a `table != \"\"` guard, so an empty trailing capture cannot be read as schema.table (Regex.scan omits trailing unmatched groups today, and the guard keeps that safe if it ever stops)"
  - "Moved generators keep their bodies and bias unchanged; ident/fixed_ident/public/pair_gen/pair_of_pairs_gen became public, and prefix36/tail_gen/swapcase stay private"
metrics:
  duration: 405s
  completed: 2026-09-25
actuals:
  tokens: 7100
  tasks: 2
  commits: 2
plan_head_before: 74c6e7cf1120cd666eba74eaa44899aaff89ef38
---

# Phase 209 Plan 02: Rerun Detection by ON Clause Summary

`mix threadline.gen.triggers` now treats a table as regenerated only when an earlier migration has a `CREATE [OR REPLACE] [CONSTRAINT] TRIGGER threadline_audit_…` statement whose ON clause names that exact (schema, table). It no longer compares trigger names. This removes the 46-byte shared-prefix false positive and the public.a_b vs a.b false positive. It still recognizes all three historical trigger forms.

## Tasks

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | ON-clause rerun detection end to end through the Mix task (tracer) | 1ba8944b | lib/threadline/mix/trigger_migration.ex, lib/mix/tasks/threadline.gen.triggers.ex, test/support/legacy_trigger_sql.ex, test/threadline/mix/trigger_migration_test.exs, test/mix/tasks/threadline/gen_triggers_test.exs |
| 2 | Round-trip property over the biased pair generators, shared with the naming property test | ac13cebe | test/support/naming_generators.ex, test/threadline/capture/naming_property_test.exs, test/threadline/mix/trigger_migration_property_test.exs |

## TDD evidence

- **Task 1 RED:** `trigger_migration_test.exs` had 29 tests and 15 failures. They failed with `UndefinedFunctionError … parse_triggers/1` and with `ArgumentError: not a bitstring` from the old `rerun?(String.t(), …)` when it was given a pair. The new describe "rerun detection by table" in `gen_triggers_test.exs` had 3 failures: the 46-byte pair, a_b then a.b, and a.b then a_b. Each failed on `refute output =~ "already have a Threadline trigger migration"`. The 0.9 hex_evaluator case already passed, as expected.
- **Task 1 GREEN:** 62 tests, 0 failures across both files. Tracer gate: I re-ran the verify command end to end before committing, and it was still green.
- **Task 2 RED:** the property test did not compile because `Threadline.Test.NamingGenerators` was undefined. **GREEN:** 9 properties, 29 tests, 0 failures (7 naming + 2 rerun).
- **Mutation check (Task 2):** I temporarily made `rerun?` ignore the schema. The "another table's … never a rerun" property failed after 12 runs. I restored the file with `git checkout -- lib/threadline/mix/trigger_migration.ex`.

## Verification

- Plan verify commands: Task 1 gave 62 tests, 0 failures. Task 2 gave 9 properties, 29 tests, 0 failures.
- `mix verify.test`: `9 properties, 1943 tests, 0 failures, 1 excluded`. NoticeGuard printed no truncation report.
- `mix compile --warnings-as-errors` is clean. `mix format --check-formatted` is clean. `mix credo --strict` found no issues in any touched file.
- Acceptance greps:
  - `def parse_triggers` = 1
  - `rerun?(pair, scan.sources)` = 1
  - `rerun?(Naming.trigger_name` = 0
  - no current-module references in legacy_trigger_sql.ex
  - no planning vocabulary in the touched lib and support files
  - NamingGenerators is defined; `defp pair_of_pairs_gen` = 0 in the naming test
  - property test has `TriggerSQL.create_trigger` = 1 and `async: true` = 1

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed the unused `Naming` alias from gen.triggers**
- **Found during:** Task 1
- **Issue:** the call site no longer calls `Naming.trigger_name`, so `mix compile --warnings-as-errors` failed on the unused alias.
- **Fix:** I dropped `Naming` from the `alias Threadline.Capture.{…}` line.
- **Files modified:** lib/mix/tasks/threadline.gen.triggers.ex
- **Commit:** 1ba8944b

Everything else followed the plan. A few extras beyond the listed behaviors:
- a direct `parse_triggers/1` shape test
- an explicit "unqualified ON matches any schema" test
- a Mix-level test for the reverse order (a.b then a_b)
- a Mix-level test that the 0.9 fixture's rerun message names `posts` and that the new migration's down is empty

The new property test sets `max_runs: 300`. The naming properties use the StreamData default.

## Known Stubs

None.

## Threat Flags

None. The change only reads text at generation time, with a bounded 300-character window. Host files are still never compiled or evaluated.

## Self-Check: PASSED

- FOUND: test/support/legacy_trigger_sql.ex, test/support/naming_generators.ex, test/threadline/mix/trigger_migration_property_test.exs
- FOUND commits: 1ba8944b, ac13cebe (`git rev-list --count 74c6e7cf..HEAD` = 2)
