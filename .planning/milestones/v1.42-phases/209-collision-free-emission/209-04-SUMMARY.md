---
phase: 209-collision-free-emission
plan: 04
subsystem: capture-generator
status: complete
tags: [capture, triggers, generator, security, upgrade, real-postgres, migrate-time-guard]
requires:
  - Threadline.Capture.TriggerSQL.drop_function_if_unused/2 and retire ordering (plan 03)
  - Threadline.Test.MigrationHarness (plan 03)
  - Threadline.Test.LegacyTriggerSQL frozen 0.9 / 0.10.2 statements (plan 02)
  - Threadline.Test.NoticeGuard (plan 01), active and silent here
provides:
  - Threadline.Capture.TriggerSQL.function_owner_guard/2 (post-condition guard DO-block builder)
  - gen.triggers up order functions -> triggers -> guard blocks -> retire blocks
  - test/threadline/capture/legacy_function_upgrade_test.exs (raise, moved-first, combined, long 0.9 pair, pinned current-release case)
affects:
  - plan 05 documents the migrate-time error and the safe orders in the gen.triggers moduledoc
  - the upgrade guide / release notes (later phase) must cover the migrate-time error and the pinned WARNING case
tech-stack:
  added: []
  patterns:
    - post-condition DO block that raises after all re-points, so the migration's single DDL transaction rolls back atomically
    - the HINT's --tables list is computed inside the DO block from pg_trigger (bare relname for public, schema.table otherwise)
key-files:
  created:
    - test/threadline/capture/legacy_function_upgrade_test.exs
  modified:
    - lib/threadline/capture/trigger_sql.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - test/threadline/capture/trigger_sql_storage_schema_test.exs
    - test/mix/tasks/threadline/gen_triggers_test.exs
    - test/support/migration_harness.ex
    - test/mix/tasks/threadline.incident_test.exs
decisions:
  - "Guard message: 'threadline: triggers on <others> also use the capture function of <schema.table> and may now apply another table''s redaction rules'; HINT: 'Regenerate those tables in the same command: mix threadline.gen.triggers --tables <owner>,<others> (or regenerate <others> first).'"
  - "The guard is emitted once per per-table table (default-mode tables get none), after every trigger and before every retire block"
  - "MigrationHarness lowers the global Logger level to :warning for the duration of a migration when something earlier raised it, so DDL WARNINGs are always captured"
metrics:
  duration: ~40m
  completed: 2026-09-25
actuals:
  tokens: 7321
  tasks: 2
  commits: 2
plan_head_before: 3a66ed0cf339fdaed073f4e48038c54c32ccbd77
---

# Phase 209 Plan 04: Migrate-Time Owner Guard Summary

Generated migrations now end their trigger work with a post-condition guard: if any trigger on another table still calls a per-table function the migration just wrote, the migration raises with a copy-pasteable `mix threadline.gen.triggers --tables ...` HINT and applies nothing. Every upgrade order over a 0.10.x shared function and a 0.9-era cut function is proven on real PostgreSQL through `Ecto.Migrator`.

## What was built

**Task 1 (tracer): owner guard end to end** (commit 59686cc4)
- `TriggerSQL.function_owner_guard(table, opts \\ [])`:
  - `to_regprocedure('"<storage>"."<Naming.function_name>"()')`, validated with `:derived` through the shared `per_table_function_name/2`;
  - `to_regclass('<StorageSchema.qualified_host_table>')` as the owner;
  - one `SELECT` over `pg_trigger` computing `others` (`format('%I.%I')`) and `retables` (bare for public), both `ORDER BY n.nspname, c.relname`, filtered by `t.tgfoid = fn AND t.tgrelid <> owner`;
  - `RAISE EXCEPTION ... USING HINT = format(...)`. No cascade anywhere (`grep -c CASCADE` = 0).
- `gen.triggers` `migration_content/3` now joins `function_ups`, `trigger_ups`, the new `guard_ups`, and `retire_ups`.
- Unit tests for the builder: public owner, schema owner (`billing.invoices` token), mixed-case storage schema.
- Generator tests updated in the same commit: the exact `--tables test_redaction_users,posts` up list includes the guard in its position. The `billing.invoices` moved-table test now pins the full up list, including its guard. The kinds test expects `:guard` before the retire blocks. The default-mode `posts` test asserts no guard.
- Real PostgreSQL: fixture = the storage-schema function `threadline_capture_changes_billing_invoices`, carrying billing.invoices's rules (mask secret, exclude notes), plus both frozen 0.10.2 triggers and a fixture migration listing both. Regenerating only `billing_invoices` raises `Postgrex.Error`. The message names `billing.invoices`, and the hint contains `mix threadline.gen.triggers --tables billing_invoices,billing.invoices` and `regenerate billing.invoices first`. The function definition and both tables' `tgfoid` are unchanged, and the version is not in `schema_migrations`. billing.invoices still captures with its old rules.

**Task 2: the safe orders** (commit f52ab3ba)
- **Moved table first:** `--tables billing.invoices` migrates. The table moves to `..._9bba11019407` and applies its own mask and exclude rules. The legacy function survives with `["public.billing_invoices"]` as its only user, and the log contains `threadline: kept` and `public.billing_invoices`. The down contains no `execute` or `DROP`, and after rollback both tables have exactly one trigger with `tgenabled = "O"`.
- **Combined after the refusal:** the refused migration raises, then `--tables billing_invoices,billing.invoices` migrates with no `threadline: kept`. Each function has exactly one trigger user. The legacy-named body contains `jsonb_build_object('email'` and neither `'secret'` nor `'notes'`. `notes` is present for public and absent for billing, and each table has one `"O"` trigger.
- **Long 0.9-era pair:** two 42-byte public names cut to one 63-byte storage-schema function, called by 0.9-form unqualified triggers, with a fixture migration that uses the uncut names. Regenerating one table alone migrates without raising, moves it to its hashed function, and warns that the other table still uses the shared function. Regenerating the other then drops the shared function.
- **Pinned current-release case:** a fresh `billing_invoices` install, then `billing.invoices` generated separately. Both migrate, and the second logs `threadline: kept` naming `public.billing_invoices`. Each table applies its own rules.

## Verification

- Task 1 red: the unit and generator tests failed with `function_owner_guard` undefined. The real-PG test failed with `Expected exception Postgrex.Error but nothing was raised`, because the migration applied and silently rewrote the shared body. Green: 50 tests, 0 failures.
- Task 2 had no natural red: these scenarios pin behavior that already exists (plan 03 retire rules and the Task 1 guard). A mutation check stood in for it. When the in-use exclusion was removed from `retire_ups`, the combined-run and pinned-case tests failed. The file was restored with `git checkout -- <file>`.
- `mix test legacy_function_upgrade_test gen_triggers_test collision_free_emission_test source_size_contract_test`: 63 tests, 0 failures.
- `mix verify.test` (seed 960367): exit 0, 9 properties, 1963 tests, 0 failures, 1 excluded. The same result held with seed 558619. No 42622 output.
- `mix compile --warnings-as-errors`, `mix format --check-formatted` and `mix credo --strict` on the changed files: all clean.
- Acceptance greps: `def function_owner_guard` 1; `RAISE EXCEPTION` 1; `USING HINT` 1; `TriggerSQL.function_owner_guard` in gen.triggers 2; `CASCADE` in trigger_sql.ex 0. All Task 2 substrings are present.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Captured migration WARNINGs were empty under some suite orders**
- **Found during:** Task 2, first `mix verify.test` (seed 558619). Four tests failed with `log == ""`: three new ones and plan 03's `collision_free_emission_test` "a function another table's trigger still uses is kept, with a warning".
- **Cause:** `Mix.Tasks.Threadline.Incident.run/1` with `--json` calls `Logger.configure(level: :error)`, and `threadline.incident_test.exs` never restored it. Every later `capture_log` in the VM missed warnings. Proven by forcing `Logger.configure(level: :error)` in the upgrade test's setup, which reproduced the same 3 failures. This defect existed before this plan and depends on test order.
- **Fix:** `MigrationHarness.migrate/2` temporarily lowers the global level to `:warning` when it is higher, and restores it afterwards. `incident_test.exs` restores the Logger level in `on_exit`. With the forced `:error` probe still in place, all 5 upgrade tests passed. The full suite then passed on both seeds.
- **Files modified:** test/support/migration_harness.ex, test/mix/tasks/threadline.incident_test.exs
- **Commit:** f52ab3ba
- **Not fixed (out of scope):** `lib/mix/tasks/threadline.incident.ex` still mutates the global Logger level for the rest of the VM when run with `--json`. That is harmless in a one-shot mix run but leaks in-process.

**2. [Rule 1 - Test precision] Existing refute in gen_triggers_test widened by the guard**
- The "per-table up keeps its function" test refuted any statement containing `threadline_capture_changes_test_redaction_users"()')`. Its intent is "no retire block targets the in-use function", but the guard legitimately contains that literal. The refute is now limited to statements whose kind is `:retire`. Commit 59686cc4.

## Known Stubs

None.

## Threat Flags

None. T-209-15, T-209-17 and T-209-18 are mitigated as planned. The guard names other tables only with `format('%I.%I')` and plain `relname`, and the generator literals are validated identifiers.

## Notes for Later Plans

- Plan 05: document the migrate-time error, the HINT, and the safe orders (both tables in one command, or the moved table first) in the gen.triggers moduledoc.
- The pinned current-release case still prints a WARNING even though both tables are correct, as the flagged assumption predicted. The upgrade guide should explain it.

## Self-Check: PASSED

- FOUND: test/threadline/capture/legacy_function_upgrade_test.exs
- FOUND: 59686cc4 (Task 1)
- FOUND: f52ab3ba (Task 2)
