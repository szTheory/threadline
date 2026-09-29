---
phase: 209-collision-free-emission
reviewed: 2026-09-25T00:00:00Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/threadline/mix/trigger_migration.ex
  - CHANGELOG.md
  - priv/ci/notice_guard_canary.exs
  - test/support/legacy_trigger_sql.ex
  - test/support/migration_harness.ex
  - test/support/naming_generators.ex
  - test/support/notice_guard.ex
  - test/test_helper.exs
  - test/mix/tasks/threadline.incident_test.exs
  - test/mix/tasks/threadline/gen_triggers_test.exs
  - test/threadline/capture/collision_free_emission_test.exs
  - test/threadline/capture/legacy_function_upgrade_test.exs
  - test/threadline/capture/legacy_trigger_regeneration_test.exs
  - test/threadline/capture/naming_property_test.exs
  - test/threadline/capture/notice_guard_canary_test.exs
  - test/threadline/capture/notice_guard_test.exs
  - test/threadline/capture/trigger_rerun_test.exs
  - test/threadline/capture/trigger_sql_storage_schema_test.exs
  - test/threadline/mix/trigger_migration_property_test.exs
  - test/threadline/mix/trigger_migration_test.exs
findings:
  critical: 1
  warning: 2
  info: 6
  total: 9
status: issues_found
---

# Phase 209: Code Review Report

**Reviewed:** 2026-09-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 23
**Status:** issues_found

## Summary

Scope: every file in `git diff f4ac6404 HEAD` for phase 209, checked against
decisions D-01 to D-11 in 209-CONTEXT.md.

Most of the security-critical SQL holds up:
- Every emitted identifier passes through `StorageSchema.validate_identifier!`, which only accepts `[A-Za-z_][A-Za-z0-9_]*` of at most 63 bytes. Nothing interpolated into the `DO $$ … $$` bodies or the `'…'` literals can end a quote or a dollar-quote.
- The `to_regprocedure` and `to_regclass` literals quote both the schema and the name, so a mixed-case storage schema still resolves.
- No generated statement uses `CASCADE`.
- `up` runs in the order function, trigger, guard, retire, so the guard and every retire block see the final `tgfoid` of every table in the migration.
- `down` drops triggers before it runs any drop-if-unused block.
- `rerun?` matches on the `ON` clause and handles all three historical forms.
- The NoticeGuard positive and negative controls, and the nested-`mix test` canary, prove it fails the suite.

One regression blocks shipping, and I confirmed it on real PostgreSQL 14.17 in a scratch database, which I dropped afterwards. The owner guard (D-05) treats the trigger clones PostgreSQL creates on each partition of a partitioned table as "another table" using the function. As a result, any partitioned table in per-table mode (redaction rules or `--store-changed-from`) can no longer be migrated. Its HINT then tells the operator to regenerate the partitions, which is wrong advice.

Two pre-existing generator defects sit in code this phase rewrote and undermine its goal, so they are reported as warnings.

## Critical Issues

### CR-01: Owner guard fails every per-table migration of a partitioned table (partition trigger clones counted as foreign users)
**Status:** FIXED in `0cd1e0ec` (`AND t.tgparentid = 0` in both the owner guard and drop-if-unused blocks; real-PostgreSQL partitioned-table up/down test added in `collision_free_emission_test.exs`, proven red without the fix).


**File:** `lib/threadline/capture/trigger_sql.ex:178-188` (the same shape is at `:136-139`)
**Issue:** On PostgreSQL 13 and later, `CREATE [OR REPLACE] TRIGGER … FOR EACH ROW` on a partitioned table clones the trigger onto every partition. Each clone is a `pg_trigger` row with `tgrelid = <partition oid>` and the same `tgfoid`. `function_owner_guard/2` filters only `t.tgfoid = fn AND t.tgrelid <> owner`, so it counts every partition as a foreign table and runs `RAISE EXCEPTION`. The whole migration rolls back. Reproduced on PG 14.17:

```
CREATE TABLE events (id bigint, at date) PARTITION BY RANGE (at);
CREATE TABLE events_2026 PARTITION OF events FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE OR REPLACE TRIGGER "threadline_audit_events" … ON "public"."events" … EXECUTE FUNCTION "public"."threadline_capture_changes_events"();
-- guard DO block:
ERROR:  threadline: triggers on public.events_2026 also use the capture function of public.events and may now apply another table's redaction rules
HINT:  Regenerate those tables in the same command: mix threadline.gen.triggers --tables events,events_2026 (or regenerate events_2026 first).
```

Before phase 209 the same generated migration applied cleanly, because there was no guard. So this is a regression: any adopter who redacts a partitioned table cannot regenerate it, and the HINT sends them to regenerate partitions, which is wrong and could stack a second trigger on a partition. The D-01 block has the same unfiltered join, so its "kept … because triggers on …" WARNING also lists partitions. That is only cosmetic there, but it makes the WARNING misleading. No test covers a partitioned table.
**Fix:** Count only triggers that are not clones. `tgparentid` exists from PG 13 on, and the project already requires PG 14 for `CREATE OR REPLACE TRIGGER`. Apply this to both blocks:
```sql
  FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE t.tgfoid = fn AND t.tgparentid = 0 AND t.tgrelid <> owner;
```
Add a real-PostgreSQL test in `collision_free_emission_test.exs` that generates `--tables <partitioned>` with a mask and migrates it up and down through `MigrationHarness`. Because this SQL is frozen into adopters' migrations, the fix has to land before any release ships the current guard text.

## Warnings

### WR-01: `execute #{inspect(sql)}` silently truncates SQL longer than 4096 characters, so the migration file is corrupted
**Status:** FIXED in `7f42cd34` (`execute_line/1` and the install migration in `lib/threadline/capture/migration.ex` now inspect with `printable_limit: :infinity, limit: :infinity`; 40-mask-column test asserts no `<> ...`, the file parses, and the execute string equals `TriggerSQL.install_function_for_table/2`).


**File:** `lib/mix/tasks/threadline.gen.triggers.ex:466`
**Issue:** `inspect/1` defaults to `printable_limit: 4096`. A longer string is written as `"…" <> ...`, which is not the SQL. A per-table function is about 3,000 bytes with 2 mask columns and 1 exclude column, and each masked column adds about 100 bytes, because redaction is emitted twice and also in the `changed_from` array. A table with roughly 12 or more redacted columns therefore produces a migration that does not compile or run. Measured: with 40 mask columns the SQL is 7,599 bytes, and `inspect/1` ends with `'c" <> ...`. This predates phase 209, but phase 209 rewrote `execute_line/1` around it and made it the single path for all emitted SQL. The rerun parser (`normalize_source`) also relies on this encoding.
**Fix:**
```elixir
defp execute_line(sql), do: "    execute #{inspect(sql, printable_limit: :infinity, limit: :infinity)}"
```
Add a `gen_triggers_test` case with around 40 mask columns that compiles the generated file (`Code.string_to_quoted!/1`) and checks that the `execute` argument equals `TriggerSQL.install_function_for_table/2`.

### WR-02: The same table spelled two ways (`posts` and `public.posts`) gets the wrong redaction rules or loses them
**Status:** FIXED in `ca4de538` (config keys and `--tables` values resolve to one schema.table pair; one table under two config keys, or twice in `--tables`, raises `Mix.Error` naming the duplicates; four unit tests added). `RedactionPresenter` already normalises config keys through `parse_table_identifier`, but on two keys for one table it silently keeps one (via `Map.new`) rather than raising; left unchanged.


**File:** `lib/mix/tasks/threadline.gen.triggers.ex:177-186, 305`
**Issue:** Redaction config is looked up by the raw `--tables` string (`Map.get(capture_tables, table, [])`). `TriggerCaptureConfig` does not normalise its keys either. Two consequences follow:
- `--tables public.posts` with `config … tables: %{"posts" => [mask: …]}` produces a default-mode, unredacted trigger.
- `--tables posts,public.posts` emits a per-table function and then a second `CREATE OR REPLACE TRIGGER` for the same table on the global function. The last statement wins, so capture runs unredacted. The owner guard passes, and the per-table function is never retired because it is in `in_use`.

This predates phase 209, but it defeats the phase's security goal ("each table applies only its own rules").
**Fix:** Normalise both sides through `Naming.pair/1`, keying the config by `Naming.qualified/1` and the tables by pair. Then reject a `--tables` list in which two entries resolve to the same pair:
```elixir
dupes = pairs |> Enum.frequencies_by(&Naming.qualified/1) |> Enum.filter(fn {_, n} -> n > 1 end)
if dupes != [], do: Mix.raise("--tables lists the same table more than once: …")
```

## Info

### IN-01: NoticeGuard's at_exit overrides the exit status of an already-failing run

**File:** `test/support/notice_guard.ex:85`
**Issue:** `System.at_exit(fn _ -> exit({:shutdown, 1}) end)` also runs when `mix test` is already exiting with status 2 because tests failed, and changes the status to 1.
**Fix:** `System.at_exit(fn status -> if status == 0, do: exit({:shutdown, 1}) end)`.

### IN-02: The `client_min_messages` check rejects levels that still deliver NOTICEs

**File:** `test/test_helper.exs:46-59`
**Issue:** At `log` or `debug1` to `debug5`, PostgreSQL still sends NOTICE messages, but the check requires exactly `notice`. It fails safe, but it rejects valid setups. Separately, under `THREADLINE_PGBOUNCER_TOPOLOGY=1` the check is skipped while the guard stays attached.
**Fix:** Accept any of `~w(debug5 debug4 debug3 debug2 debug1 log notice)`.

### IN-03: `drop_function_if_unused/2` doc says the block "never raises"

**File:** `lib/threadline/capture/trigger_sql.ex:115-117`
**Issue:** `EXECUTE format('DROP FUNCTION %s', fn)` can still raise 2BP01 if a trigger is created between the check and the drop. D-01 accepts that race on purpose. The doc overstates the guarantee.
**Fix:** Say instead that the block does not raise for a function a trigger already uses, and that a concurrent new user makes the drop fail loudly and never cascade.

### IN-04: The owner-guard HINT can suggest a `--tables` value the task rejects

**File:** `lib/threadline/capture/trigger_sql.ex:179-180, 187`
**Issue:** `retables` is built from raw `nspname` and `relname`. A foreign trigger on a table whose name is not `[A-Za-z_][A-Za-z0-9_]*` (for example a hyphenated or quoted name) produces a HINT command that `parse_table_identifier/1` rejects.
**Fix:** Leave such tables out of the command and list them separately, or add a note that they need hand-written SQL.

### IN-05: The shared-name advisory ignores later regenerations

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:277-299`
**Issue:** `covered_pairs/1` includes every table any earlier migration ever covered. After `billing.invoices` has already moved to its hashed function, regenerating `billing_invoices` still prints "Regenerate both in one command". The advisory is noise in that case, which teaches operators to ignore it.
**Fix:** Skip a covered table when a later migration already regenerated it with a phase-209 migration, for example by checking whether that migration's source contains `Naming.function_name(q)`.

### IN-06: The moduledoc's naming rule omits the hash-tail exception

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:26-30` (also `trigger_sql.ex:49-52`)
**Issue:** The doc says that any public table of at most 36 bytes keeps `threadline_capture_changes_<table>`. `Naming.legacy_function?/1` also hashes a public table whose name ends in `_` followed by 12 lowercase hex characters.
**Fix:** Add ", unless its name itself ends in `_` and 12 hex characters".

---

_Reviewed: 2026-09-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
