---
phase: 209-collision-free-emission
plan: 03
subsystem: capture-generator
status: complete
tags: [capture, triggers, generator, security, orphan-safe-drop, real-postgres]
requires:
  - Threadline.Capture.Naming.function_name/1 and legacy_function_name/1 (phase 208)
  - Threadline.Mix.TriggerMigration.rerun?/2 keyed on the pair (plan 02)
  - Threadline.Test.NoticeGuard (plan 01), active and silent here
provides:
  - Threadline.Capture.TriggerSQL.drop_function_if_unused/2 (orphan-safe DO-block builder)
  - per-table function names via Naming.function_name/1 (private per_table_function_name/2)
  - TriggerSQL.drop_function_for_table/2 as a restricting drop (no cascade)
  - gen.triggers up order functions -> triggers -> retire blocks, and down with the DO drop for first-run per-table tables
  - Threadline.Test.MigrationHarness (generate!/2, migration_files/1, migrate_up/1, migrate_down/1, cleanup!/1, trigger_function/2, threadline_triggers/2, function_users/1, function_exists?/1, function_definition/1)
affects:
  - plan 04 (post-condition guard) runs after every re-point and reuses MigrationHarness for the upgrade fixtures
  - plan 05 rewrites the gen.triggers moduledoc paragraphs this plan leaves stale, plus the CHANGELOG
tech-stack:
  added: []
  patterns:
    - generated migrations compiled and run through Ecto.Migrator.up/down in tests, with ExUnit.CaptureLog at :warning to see DDL WARNINGs
    - retire set = legacy names + now-unused per-table names, deduplicated, minus every function a trigger in the migration now calls
key-files:
  created:
    - test/support/migration_harness.ex
    - test/threadline/capture/collision_free_emission_test.exs
  modified:
    - lib/threadline/capture/trigger_sql.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - test/threadline/capture/trigger_rerun_test.exs
    - test/threadline/capture/trigger_sql_storage_schema_test.exs
    - test/mix/tasks/threadline/gen_triggers_test.exs
decisions:
  - "The DO block ends with `END $$;`, as in the locked shape; Postgrex runs it as one statement with the leading comment line"
  - "migration_content/3 is split into function_ups/1, trigger_ups/1, retire_ups/1, down_body/2 and execute_line/1, so the task has no function near the 120-line cap"
  - "MigrationHarness.migrate_up/down reuse an already loaded migration module (read from the file's defmodule), so a rollback runs the exact code that was applied; cleanup!/1 purges it"
  - "In Task 1 the per_table_function_base helper was rewritten on Naming.suffix/1 (not deleted) so the fits-check kept working until Task 2 deleted both; the host_table_suffix pattern was gone after Task 1 either way"
metrics:
  duration: ~660s
  completed: 2026-09-25
actuals:
  tokens: 11100
  tasks: 2
  commits: 2
plan_head_before: 4827cae4a5f20fc37c9ab71a730edd29d84255ad
---

# Phase 209 Plan 03: Collision-Free Emission Summary

Each table now gets its own capture function, named by `Naming.function_name/1` from its (schema, table) pair. Every function drop the generator writes is an inline DO block. The block drops the function only when no `pg_trigger` row still uses it. Otherwise it keeps the function and prints a WARNING. Nothing cascades. Both behaviours are tested on real PostgreSQL through `Ecto.Migrator`.

## What was built

**Task 1 (tracer): per-table names from Naming** (commit f86512d3)
- `TriggerSQL.per_table_function_name/2` now pipes `Naming.function_name/1` → `validate_identifier!(:derived)` → `StorageSchema.function/2`. Results:
  - `public.billing_invoices` → `threadline_capture_changes_billing_invoices`
  - `billing.invoices` → `threadline_capture_changes_billing_invoices_9bba11019407`
  - `support.tickets` → `…_support_tickets_0a670b783726`
  - A long public table gets a hashed name. It used to raise `ArgumentError`.
- The `install_function_for_table/2` and `create_trigger/3` docs no longer promise a `threadline_capture_changes_<table>` shape.
- New `Threadline.Test.MigrationHarness`. It generates into a tmp dir, compiles the file, and runs `Ecto.Migrator.up/4` or `down/4`, returning `{result, log}`. Migrator logging is left on, so DDL WARNINGs reach the captured log. It also has catalog helpers that query by bare catalog names.
- `collision_free_emission_test.exs` SC1 tests, run on real PostgreSQL:
  - **Schema pair:** `public.billing_invoices` masks email and excludes notes; `billing.invoices` masks secret. Each insert applies only its own rules: `notes` is absent from one table's row and present, with its value, in the other's.
  - **36-byte-prefix pair:** each table gets a distinct hashed function with one user. One table excludes notes and the other masks it.
- The trigger_rerun "refused before writing" test was changed to "gets its own function".

**Task 2: orphan-safe drop, no cascade, retire ordering, first-run down** (commit 6f905add)
- `TriggerSQL.drop_function_if_unused/2` emits the locked D-01 block:
  - a leading comment line;
  - `to_regprocedure('"<storage>"."<name>"()')`, validated to 63 bytes or fewer;
  - `ORDER BY n.nspname, c.relname`;
  - `EXECUTE format('DROP FUNCTION %s', fn)` when no trigger uses the function, otherwise `RAISE WARNING 'threadline: kept % …; regenerate triggers for those tables'`.
- `drop_function_for_table/2` is now a restricting drop, and its doc says to drop the trigger first. `per_table_function_fits?/1`, `drop_orphan_function_for_table/2`, `per_table_function_base/1`, `@max_identifier_bytes` and `gen.triggers` `orphan_function_drop/1` are deleted.
- Order of `gen.triggers` `up`: per-table function creates, then every trigger, then the retire blocks.
  - The retire set is the legacy names of all tables, plus `Naming.function_name/1` for tables now on the global function, deduplicated.
  - Any function that a trigger in this migration calls is excluded.
- `down` drops the trigger of each first-run table. For a per-table table it then runs the DO drop of that table's function. Reruns still emit nothing.
- Tests:
  - **Unit:** DO-block text; quoting of a mixed-case schema; a 64-byte name raises.
  - **Generator:** exact up/down statement lists; retire blocks come after every trigger; a moved table retires its legacy name; nothing cascades in `up` or `down`, checked case-insensitively.
  - **Real PostgreSQL (DO block):** drops an unused function; keeps a used one and warns; with two tables using the function, the WARNING lists them sorted by schema, then table, and both triggers stay `tgenabled = 'O'`; an absent function is a no-op.
  - **Real PostgreSQL (retire):** two long default tables on a pre-validation shared 63-byte function both move to the global function, and the shared function is dropped.
  - **SC3 through Ecto.Migrator:**
    - Two tables share a 46-byte prefix, so their trigger names are byte-identical. Rolling back B leaves A with `[{cut, "O"}]`, and A's function still has A as its only user. B has no trigger and no function left.
    - When another table's trigger was hand-pointed at B's function, rolling B back keeps the function. The other trigger stays enabled, and the log contains `threadline: kept` and `public.billing_invoices`.

## Verification

- `mix test test/threadline/capture/collision_free_emission_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/capture/trigger_rerun_test.exs`: 18 tests, 0 failures (Task 1 gate).
- `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/operator_surface/policy_show_mix_test.exs test/threadline/source_size_contract_test.exs`: 9 properties, 184 tests, 0 failures.
- `mix verify.test`: exit 0, 9 properties, 1955 tests, 0 failures, 1 excluded (the allowed `pgbouncer_topology` tag). No 42622 output.
- `mix format --check-formatted`, `mix compile --warnings-as-errors` and `mix credo --strict` on the changed files: all clean.
- Red first. Task 1's new tests failed as expected:
  - the schema pair shared `threadline_capture_changes_billing_invoices`;
  - the long pair raised `ArgumentError` at 68 bytes;
  - `support.tickets` was unhashed.

  Task 2's new tests failed with `drop_function_if_unused` undefined. The hand-pointed SC3 rollback test also failed, because the cascading `down` removed the other table's trigger.
- Acceptance greps:
  - `CASCADE` appears 0 times in both lib files.
  - `def drop_function_if_unused`: 1.
  - `ORDER BY n.nspname, c.relname`: 1.
  - `RAISE WARNING`: 1.
  - Removed helper names: 0 in lib and test.
  - `Naming.function_name` in trigger_sql.ex: 3.
  - `threadline_capture_changes_<table>` in trigger_sql.ex: 0.
  - `log: false` in the harness: 0.

## Deviations from Plan

None in behavior. Minor notes:
- **Test-only:** the credo `--strict` nested-alias suggestions in `collision_free_emission_test.exs` (which Task 1 introduced) were fixed in the Task 2 commit.
- **SC3 same-trigger-name test:** Task 1's distinct function names already make it pass. The red evidence for SC3 is the hand-pointed test, which failed under the cascading `down`.

## Known Stubs

None.

## Known Issues / Notes for Later Plans

- The `gen.triggers` moduledoc paragraphs on these topics are now stale: per-table function names, the default-mode "drop never cascades … skipped when longer than 63 bytes", and the "Long table names … still rejected". This is expected. Plan 05 rewrites them together with the CHANGELOG, and no doc contract test depends on them.
- `ecto_sql` 3.14.0 logs DDL WARNINGs at the deprecated `:warn` level. The first WARNING that reaches Logger in a VM prints a one-time `the log level :warn is deprecated` stack trace to stderr. That output comes from the dependency, not a failure. It appears once during the real-PostgreSQL rollback tests.
- Flagged assumption (from the plan): retiring the legacy name of a non-public table keeps the function and warns when a 0.11-native public table legitimately owns that name. Plan 04 pins this with a test.

## Self-Check: PASSED

- FOUND: test/support/migration_harness.ex
- FOUND: test/threadline/capture/collision_free_emission_test.exs
- FOUND: f86512d3 (Task 1)
- FOUND: 6f905add (Task 2)
