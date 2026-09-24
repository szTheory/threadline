---
phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc
plan: 01
subsystem: capture
tags: [postgresql, triggers, ddl, ecto, gen.triggers]

requires:
  - phase: 206-installer-migration-versions
    provides: "shared test DB harness conventions (no sandbox, no Ecto.Migrator, unique scratch table + on_exit)"
provides:
  - "TriggerSQL.create_trigger/3 emits CREATE OR REPLACE TRIGGER in :default and :per_table modes"
  - "TriggerSQL.drop_orphan_function_for_table/2: non-cascading per-table capture function drop"
  - "DB-tier test file proving rerun install, default->per_table re-point, orphan removal, loud refusal, no-op drop"
affects: [207-02 gen.triggers rerun emission, 207-03 docs/CHANGELOG]

actuals:
  tokens: 2035
  tasks: 2
  commits: 2
plan_head_before: 4454661b5f69036e837b71beb70efa3a3b27f284

tech-stack:
  added: []
  patterns:
    - "Identify a trigger's function via pg_trigger/pg_proc/pg_namespace join on nspname+proname, never regproc text"
    - "Send a relation name as $1::text::regclass (Postgrex encodes a bare regclass param as an oid)"

key-files:
  created:
    - test/threadline/capture/trigger_rerun_test.exs
  modified:
    - lib/threadline/capture/trigger_sql.ex
    - test/threadline/capture/trigger_sql_storage_schema_test.exs

key-decisions:
  - "Trigger DDL is CREATE OR REPLACE TRIGGER on every run; trigger name threadline_audit_<suffix> unchanged"
  - "Orphan per-table function drop has no CASCADE and reuses per_table_function_name/2; drop_function_for_table/2 keeps its CASCADE for existing callers"

patterns-established:
  - "Rerun DB tier: sibling test file with its own per-test trigger lifecycle rather than trigger_test.exs's shared setup_all trigger"

requirements-completed: [W1]

coverage:
  - id: D1
    description: "create_trigger/3 emits CREATE OR REPLACE TRIGGER and a second install applies on the real DB"
    requirement: "W1"
    verification:
      - kind: unit
        ref: "test/threadline/capture/trigger_sql_storage_schema_test.exs#qualified host tables create schema-qualified triggers"
        status: pass
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#installing the trigger twice succeeds"
        status: pass
    human_judgment: false
  - id: D2
    description: "A default-to-per-table rerun re-points pg_trigger.tgfoid to the per-table function and UPDATE records changed_from"
    requirement: "W1"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#a rerun re-points the trigger to the per-table function"
        status: pass
    human_judgment: false
  - id: D3
    description: "drop_orphan_function_for_table/2 removes the leftover per-table function, never cascades, refuses loudly while a trigger depends on it, and is a no-op when absent"
    requirement: "W1"
    verification:
      - kind: unit
        ref: "test/threadline/capture/trigger_sql_storage_schema_test.exs#orphan per-table function drop never cascades"
        status: pass
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#switching back to default mode removes the orphaned per-table function"
        status: pass
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#the orphan drop refuses to cascade into a live trigger"
        status: pass
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#the orphan drop is harmless when no per-table function exists"
        status: pass
    human_judgment: false
  - id: D4
    description: "Catalog introspection unchanged: no DDL-text parsing in lib; health, redaction-presenter catalog, policy.show, verify_coverage and all capture tests green without edits"
    requirement: "W1"
    verification:
      - kind: integration
        ref: "mix test test/threadline/capture/ test/threadline/health_test.exs test/threadline/policy/redaction_presenter_catalog_test.exs test/threadline/operator_surface/policy_show_mix_test.exs test/threadline/verify_coverage_task_test.exs (91 tests incl. release_artifact + call-site contracts, 0 failures)"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-09-24
status: complete
---

# Phase 207 Plan 01: Trigger rerun SQL (OR REPLACE + non-cascading orphan drop) Summary

**Audit trigger DDL now uses `CREATE OR REPLACE TRIGGER`, so a rerun trigger migration applies on PostgreSQL 14+ instead of failing with `already exists`. A new non-cascading `drop_orphan_function_for_table/2` removes a leftover per-table capture function, and 5 real-DB cases prove both.**

## Performance

- **Duration:** ~4 min of execution time
- **Started:** 2026-09-24T21:02:25Z
- **Completed:** 2026-09-24T21:06Z
- **Tasks:** 2
- **Files modified:** 3 (1 lib, 1 test edited, 1 test created)

## Accomplishments
- `create_trigger_sql/2` emits `CREATE OR REPLACE TRIGGER "threadline_audit_<suffix>"` for both modes. The trigger name, `AFTER INSERT OR UPDATE OR DELETE` and `FOR EACH ROW EXECUTE FUNCTION` are unchanged. The `@doc` states the PostgreSQL 14 floor.
- New public `TriggerSQL.drop_orphan_function_for_table/2` builds `DROP FUNCTION IF EXISTS "<storage_schema>"."threadline_capture_changes_<suffix>"()` through the existing `per_table_function_name/2`, with no CASCADE (T-207-01, T-207-02 mitigated).
- New `test/threadline/capture/trigger_rerun_test.exs` has 5 DB cases on a unique scratch table with `on_exit` cleanup and no sandbox or Migrator.

## Task Commits

1. **Task 1 (tracer): replace the audit trigger in place.** `1a9fbd53` (fix). The RED test and the GREEN fix are in one commit, per the plan's green-per-commit staging.
2. **Task 2: non-cascading orphan drop.** `918103fa` (fix). RED then GREEN, one commit.

Tracer feedback gate: auto mode was active. The Task 1 `<verify>` was re-run end to end and passed (16 tests, 0 failures, static clean), and only then did Task 2 start.

## RED proof

**Task 1** (`/Users/jon/.claude/jobs/77cf1bdd/tmp/207-01-t1-red.txt`, unmodified lib, exit 2):
```
  1) test qualified host tables create schema-qualified triggers (Threadline.Capture.TriggerSQLStorageSchemaTest)
     Assertion with =~ failed
     code:  assert sql =~ ~S"CREATE OR REPLACE TRIGGER \"threadline_audit_support_tickets\""
  2) test rerunning trigger installation installing the trigger twice succeeds (Threadline.Capture.TriggerRerunTest)
     ** (Postgrex.Error) ERROR 42710 (duplicate_object) trigger "threadline_audit_test_trigger_rerun_target" for relation "test_trigger_rerun_target" already exists
  3) test rerunning trigger installation a rerun re-points the trigger to the per-table function (Threadline.Capture.TriggerRerunTest)
     ** (Postgrex.Error) ERROR 42710 (duplicate_object) trigger "threadline_audit_test_trigger_rerun_target" for relation "test_trigger_rerun_target" already exists
16 tests, 3 failures
```
It was re-confirmed after the helper fix below, with only the lib line temporarily reverted (`207-01-t1-red-recheck.txt`): the same 3 failures, both DB cases on `already exists`, `16 tests, 3 failures`. The lib file was then restored byte-for-byte from a saved copy.

**Task 2** (`/Users/jon/.claude/jobs/77cf1bdd/tmp/207-01-t2-red.txt`, before the helper existed, exit 2):
```
  1) test orphan per-table function drop never cascades — ** (UndefinedFunctionError) ... drop_orphan_function_for_table/1 is undefined or private
  2) test ... the orphan drop is harmless when no per-table function exists — ** (UndefinedFunctionError)
  3) test ... the orphan drop refuses to cascade into a live trigger — Expected exception Postgrex.Error but got UndefinedFunctionError
  4) test ... switching back to default mode removes the orphaned per-table function — ** (UndefinedFunctionError)
11 tests, 4 failures
```

`gsd-tools check tdd-red-evidence` was run on the Task 1 record and returned `INVALID_RED / zero_tests_discovered`. That checker parses only node TAP output and cannot read ExUnit's summary: it counted 0 tests where ExUnit reported 16 tests, 3 failures. This is a format mismatch in the tool, not a bad RED. The named target tests failed on the planned error, and the plan's own RED acceptance criteria (`already exists`, `3 failures`, `UndefinedFunctionError`) all pass.

## D-04 grep (catalog introspection untouched)

`grep -rnE "pg_get_triggerdef|CREATE (OR REPLACE )?TRIGGER" lib/`:
```
lib/threadline/capture/trigger_sql.ex:125:    CREATE OR REPLACE TRIGGER #{StorageSchema.quote_ident(trigger_name)}
lib/mix/tasks/threadline.gen.triggers.ex:13:  Each invocation produces one migration file containing `CREATE TRIGGER`
```
There are only the two expected hits: the heredoc, and the gen.triggers moduledoc prose that plan 02 rewrites. `RedactionPresenter.fetch_deployed/2` and `Health.fetch_threadline_covered_tables/2` read only `tgfoid`/`tgname` from the catalogs. `git diff 1a9fbd53~1 -- lib/threadline/policy/redaction_presenter.ex lib/threadline/health.ex` is empty.

## Files Created/Modified
- `lib/threadline/capture/trigger_sql.ex`: OR REPLACE in `create_trigger_sql/2`, `@doc` sentence, new `drop_orphan_function_for_table/2`
- `test/threadline/capture/trigger_rerun_test.exs`: new DB tier, `Threadline.Capture.TriggerRerunTest`, with helpers `trigger_function/0`, `install_per_table_trigger!/0` and `per_table_function_count/0`
- `test/threadline/capture/trigger_sql_storage_schema_test.exs`: line-25 pin strengthened to OR REPLACE, plus the new test "orphan per-table function drop never cascades"

## Decisions Made
- Followed the plan. The helper is named `drop_orphan_function_for_table/2` and lives in a sibling DB-tier file, both as the plan chose.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `$1::regclass` parameter rejected by Postgrex**
- **Found during:** Task 1 (GREEN run)
- **Issue:** Postgrex encodes a `$1::regclass` parameter as an OID, so passing the table name as a binary raised `ArgumentError: you tried to use a binary for an oid type`. The RED run never reached this helper, because the second `create_trigger` raised first, so the bug stayed hidden until GREEN.
- **Fix:** Cast through text with `$1::text::regclass`. The function is still identified only by `nspname`/`proname` (no `regproc`, and grep confirms 0 hits).
- **Files modified:** test/threadline/capture/trigger_rerun_test.exs
- **Verification:** RED re-confirmed with the lib line temporarily reverted (3 failures on `already exists`), then GREEN with 16 tests and 0 failures.
- **Committed in:** 1a9fbd53

**2. [Additive] Two extra assertions beyond the behavior spec**
- Case 2 also asserts `change.op == "update"` and `changed_from["value"] == 1`. Case 4 also asserts that the per-table function count is still 1. Both strengthen the tests, and no existing assertion was weakened.

---

**Total deviations:** 1 auto-fixed (Rule 1, test helper), plus minor additive assertions
**Impact on plan:** None on scope. The lib changes match the plan exactly.

## Issues Encountered
- The TDD RED-evidence checker cannot parse ExUnit output (see RED proof). The RED was proven by the plan's criteria instead.

## Known Stubs
None.

## User Setup Required
None. No external service configuration is required.

## Next Phase Readiness
- Plan 02 can call `TriggerSQL.drop_orphan_function_for_table/2` from gen.triggers. Pass no opts, which matches `create_trigger/1`. Emit it after the table's `CREATE OR REPLACE TRIGGER` (Pitfall 3).
- Plan 02 rewrites the gen.triggers moduledoc (`lib/mix/tasks/threadline.gen.triggers.ex:13`), which still says `CREATE TRIGGER`.

---
*Phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc*
*Completed: 2026-09-24*

## Self-Check: PASSED
- FOUND: test/threadline/capture/trigger_rerun_test.exs, lib/threadline/capture/trigger_sql.ex, test/threadline/capture/trigger_sql_storage_schema_test.exs
- FOUND commits: 1a9fbd53, 918103fa (`git rev-list --count 4454661b..HEAD` = 2 before this SUMMARY commit)
