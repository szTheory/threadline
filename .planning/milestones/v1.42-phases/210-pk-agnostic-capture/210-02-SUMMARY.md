---
phase: 210-pk-agnostic-capture
plan: 02
subsystem: capture
tags: [postgresql, plpgsql, trigger, primary-key, backward-compatibility]

requires:
  - phase: 210-pk-agnostic-capture
    provides: "Plan 01's PrimaryKeySQL.row_key_statements/0 (the TG_NARGS=0 legacy branch and the all-or-nothing TG_ARGV loop) and the DO-block trigger installer this plan proves compatibility against"
provides:
  - "Threadline.Test.LegacyTriggerSQL.v0_10_2_install_function/2: a byte-for-byte frozen copy of the 0.10.2 global capture function body, for use by any later real-PG legacy-compatibility test"
  - "Real-PG proof (legacy_trigger_pk_fallback_test.exs) that pre-0.11 no-argument triggers keep capturing exactly as before on id-keyed tables once the global function is refreshed"
  - "Real-PG proof that every unresolvable-key shape (no id column, NULL id, renamed argument column, NULL optional argument column) stores table_pk = {} and the host write always succeeds"
  - "Real-PG proof that CREATE OR REPLACE TRIGGER upgrades a frozen 0.10.2 trigger to a one-argument trigger in place, resolving the real key"
  - "Hand-off record for Phase 211 (read side) and Phase 212 (health/drift): both {} and {\"id\": null} are unresolved sentinels, matching must use = never @>, and a legacy no-argument trigger on a non-(id) table is an error-level catalog-detected finding"
affects: [211-read-side-pk-agnostic, 212-health-and-drift, 213-upgrade-guide]

actuals:
  tokens: 4238
  tasks: 2
  commits: 2
  plan_head_before: ffaaa469bee6a29cc5c2ef5e29c5c60ab9e3fcaa

tech-stack:
  added: []
  patterns:
    - "Frozen historical SQL fixture (LegacyTriggerSQL.v0_10_2_install_function/2) copied verbatim from the release tag via git show, never rendered by current code — same idiom as the existing v0_10_2_create_trigger/3 fixture"
    - "Pairwise real-PG equality test: run the same INSERT/UPDATE/DELETE sequence through both the frozen 0.10.2 function body and the refreshed current body, compare captured rows field by field"

key-files:
  created:
    - test/threadline/capture/legacy_trigger_pk_fallback_test.exs
  modified:
    - test/support/legacy_trigger_sql.ex

key-decisions:
  - "v0_10_2_install_function/2 builds its two storage-qualified table references (\"schema\".\"audit_transactions\" / \"schema\".\"audit_changes\") by plain string interpolation of the storage_schema argument, never through Threadline.StorageSchema or Threadline.Capture.TriggerSQL, per the fixture module's own never-calls-current-code contract"
  - "legacy_partial's full-key case is proven via INSERT (code='a', opt_col=NULL) then UPDATE opt_col='b' on the same row — not two separate rows — because code is the table's own primary key and the plan's specified expected value {\"code\" => \"a\", \"opt_col\" => \"b\"} requires the same code across both captured rows"

requirements-completed: [CAP-04]

coverage:
  - id: D1
    description: "A frozen 0.10.2 no-argument trigger, refreshed to call the new global function body, stores byte-identical op/table_pk/data_after/changed_fields/changed_from as the frozen 0.10.2 body on an id-keyed table (CAP-04, SC4)"
    requirement: "CAP-04"
    verification:
      - kind: integration
        ref: "test/threadline/capture/legacy_trigger_pk_fallback_test.exs#a frozen 0.10.2 trigger on an id table, refreshed with the new global function"
        status: pass
    human_judgment: false
  - id: D2
    description: "A uuid-keyed table with no id column stores {} under the new global function (write succeeds) and {\"id\": null} under the frozen 0.10.2 body for the same shape"
    requirement: "CAP-04"
    verification:
      - kind: integration
        ref: "test/threadline/capture/legacy_trigger_pk_fallback_test.exs#a uuid-keyed table with no id column, on a no-argument trigger"
        status: pass
    human_judgment: false
  - id: D3
    description: "A nullable id column with no primary key stores {\"id\": null} under both the frozen and the new function"
    requirement: "CAP-04"
    verification:
      - kind: integration
        ref: "test/threadline/capture/legacy_trigger_pk_fallback_test.exs#a no-argument trigger on a table with a nullable id column and no primary key"
        status: pass
    human_judgment: false
  - id: D4
    description: "A composite trigger-argument column renamed after install stores {} and the write succeeds"
    requirement: "CAP-04"
    verification:
      - kind: integration
        ref: "test/threadline/capture/legacy_trigger_pk_fallback_test.exs#a composite-argument trigger whose declared column is renamed after install"
        status: pass
    human_judgment: false
  - id: D5
    description: "A trigger with a NULL-able second argument column stores {} until both columns are set, never a partial key; proven load-bearing by a mutation check that failed two tests when the IS NULL early exit was removed"
    requirement: "CAP-04"
    verification:
      - kind: integration
        ref: "test/threadline/capture/legacy_trigger_pk_fallback_test.exs#a hand-written trigger with two argument columns, one optional"
        status: pass
    human_judgment: false
  - id: D6
    description: "Regenerating a frozen 0.10.2 trigger through mix threadline.gen.triggers + Ecto.Migrator.up swaps it to a one-argument trigger under the same name, tgnargs 1, resolving the real key"
    requirement: "CAP-04"
    verification:
      - kind: integration
        ref: "test/threadline/capture/legacy_trigger_pk_fallback_test.exs#regenerating a table with a frozen 0.10.2 trigger"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-09-25
status: complete
---

# Phase 210 Plan 02: PK-Agnostic Capture — Legacy Compatibility and Unresolvable-Key Fallback Summary

**Real-PG proof that every 0.10.x trigger keeps capturing exactly as before, every unresolvable primary key stores `{}` instead of aborting the host write, and `CREATE OR REPLACE TRIGGER` upgrades a frozen trigger to one-argument in place — pinned in `legacy_trigger_pk_fallback_test.exs` against a byte-frozen copy of the 0.10.2 function body.**

## Performance

- **Duration:** ~22 min
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- `Threadline.Test.LegacyTriggerSQL.v0_10_2_install_function/2` — a byte-for-byte frozen copy of the 0.10.2 global capture function body (`git show v0.10.2:lib/threadline/capture/trigger_sql.ex`), taking only a function reference and a plain storage-schema string, never calling into current `StorageSchema`, `TriggerSQL`, or `Naming` code
- `legacy_trigger_pk_fallback_test.exs` (6 tests, all real-PostgreSQL, `async: false`):
  - A frozen 0.10.2 no-argument trigger on an id table, refreshed with the current global function body, stores identical `op`/`table_pk`/`data_after`/`changed_fields`/`changed_from` as the frozen 0.10.2 body itself, pairwise across insert/update/delete
  - A uuid-keyed table with no `id` column stores `{}` under the new body on every write (insert succeeds, update succeeds, delete succeeds) and `{"id": null}` under the frozen body for the same shape
  - A nullable `id` column with no primary key stores `{"id": null}` under both the frozen and the new body
  - A composite trigger-argument column renamed after install stores `{}` and the write still succeeds
  - A hand-written trigger with args `('code', 'opt_col')` stores `{}` while `opt_col` is NULL and the full two-key map only once both are set — never a partial key
  - Regenerating a frozen 0.10.2 trigger through `mix threadline.gen.triggers` + `Ecto.Migrator.up/4` swaps it to a one-argument trigger under the same name (`tgnargs` 1, `trigger_args` `["id"]`), and the resolved key is captured on the next insert

## Task Commits

Each task was committed atomically:

1. **Task 1: Frozen 0.10.2 SQL on an id table stores byte-identical output under the new global body** — `01386c90` (test)
2. **Task 2: Unresolvable keys store {} and never fail the write; regeneration swaps arguments in place** — `31d6a870` (test)

**Plan metadata:** (this commit)

## Files Created/Modified

- `test/support/legacy_trigger_sql.ex` — added `v0_10_2_install_function/2`, the frozen 0.10.2 global capture function body fixture
- `test/threadline/capture/legacy_trigger_pk_fallback_test.exs` — new real-PG test file, 6 tests across the 5 fallback shapes plus the id-table byte-identical tracer

## Decisions Made

- `v0_10_2_install_function/2` builds its storage-qualified table references (`"schema"."audit_transactions"` / `"schema"."audit_changes"`) by plain string interpolation of a raw `storage_schema` argument, never through `Threadline.StorageSchema` or `Threadline.Capture.TriggerSQL`, matching the fixture module's own "never calls the current SQL or naming code" contract stated in its moduledoc
- The `legacy_partial` full-key case is proven with one row (`INSERT (code='a', opt_col=NULL)` then `UPDATE opt_col='b'`), not two separate rows, because `code` is the table's own primary key and the plan's specified expected value `%{"code" => "a", "opt_col" => "b"}` requires the same `code` on both captured rows

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in the plan's own acceptance-criteria script] `TriggerSQL|StorageSchema\.|Naming\.` grep cannot print 0**
- **Found during:** Task 1, verifying acceptance criteria
- **Issue:** The plan's acceptance criterion `grep -cE 'TriggerSQL|StorageSchema\.|Naming\.' test/support/legacy_trigger_sql.ex` prints 0 is unsatisfiable as literally written: the module's own name, `Threadline.Test.LegacyTriggerSQL`, contains the substring `TriggerSQL`, so even the pre-existing file (before any change in this plan) matches once on its `defmodule` line. Confirmed against the pre-plan committed file (`git show HEAD:...` before this plan's first commit) — it also printed 1, not 0.
- **Fix:** Wrote `v0_10_2_install_function/2`'s moduledoc and inline docs so they add no new match beyond the pre-existing baseline — the only remaining match is the unavoidable `defmodule Threadline.Test.LegacyTriggerSQL` line, same as before this plan. Final count: 1 (unchanged from baseline), not 0 as literally specified.
- **Files modified:** test/support/legacy_trigger_sql.ex
- **Verification:** `grep -cE 'TriggerSQL|StorageSchema\.|Naming\.' test/support/legacy_trigger_sql.ex` — 1, matching the pre-plan baseline exactly; the actual regression the check exists to catch (a call into current renderer/naming code) is verified absent by inspection and by every test passing against a fixture that never imports those modules.
- **Committed in:** 01386c90 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 unsatisfiable acceptance-criteria script, documented rather than silently ignored)
**Impact on plan:** No functional impact — the criterion's real intent (no call into current SQL/naming code) is fully met; only the literal grep count differs from the plan's stated target, for a reason present before this plan started.

## Mutation Check (Task 2)

Per the plan's action text, one mutation was applied and reverted to prove the partial-key guard is load-bearing:

- **Mutation:** removed the `IF (v_row ->> TG_ARGV[i]) IS NULL THEN v_table_pk := '{}'::jsonb; EXIT; END IF;` early exit from `PrimaryKeySQL.row_key_statements/0`'s `TG_ARGV` loop.
- **Failing tests:** `legacy_trigger_pk_fallback_test.exs`'s `"a composite-argument trigger whose declared column is renamed after install"` and `"a hand-written trigger with two argument columns, one optional"` both failed — the renamed-column case stored `%{"post_id" => "1", "tag_id" => nil}` instead of `%{}`, and the NULL-optional-column case stored `%{"code" => "a", "opt_col" => nil}` instead of `%{}`.
- **Restore:** `git checkout -- lib/threadline/capture/primary_key_sql.ex`; `git diff --stat lib/threadline/capture/primary_key_sql.ex` confirmed empty afterward.

## D-03 Statement (per plan output requirement)

The `{"id": null}` to `{}` change (a legacy no-argument trigger's output for a table with no usable `id` column, once refreshed to the new global function body) affects only rows that never had a usable identity. This is **not** a regression of the "keeps capturing exactly as before" criterion (SC4): on any table with a real, present `id` column, the legacy branch's output is byte-identical before and after the refresh, proven pairwise in this plan's Task 1 test. Rows with a meaningful key are unchanged; only rows whose key was already meaningless (`null`) change their stored sentinel from `{"id": null}` to `{}`.

## Hand-offs for Phase 211 and Phase 212 (per D-04, recorded verbatim)

- **Unresolved-key sentinel (read side and health, Phase 211/212):** both `{}` and `{"id": null}` must be treated as "unresolved." Legacy per-table redaction functions are frozen and keep writing `{"id": null}` until they are regenerated, so a reader or health check that only recognizes `{}` as unresolved will misclassify every un-regenerated legacy row.
- **Equality, never containment (Phase 211 read matching):** any `table_pk` comparison must use `=` equality, never the jsonb containment operator (`@>`), because `x @> '{}'` is true for every row — a `RowKey` must never build an empty map, and matching against one with `@>` would match everything.
- **Legacy no-argument trigger as a catalog-detected finding (Phase 212):** a legacy no-argument trigger installed on a table whose primary key is not exactly `(id)` is an **error-level** health finding. It must be detected from the catalog (`pg_trigger.tgargs`, `pg_index`), not by scanning `audit_changes` — the row data alone cannot distinguish "never had an id" from "had an id that happened to be NULL."

## Issues Encountered

None — all tests passed on first correct implementation after two small fixes: a missing `()` vs. duplicate-`()` mismatch in `function_ref`/`function_literal` usage for the hand-written `legacy_partial` trigger (caught immediately by `mix test`'s syntax error), and correcting `legacy_partial`'s full-key scenario to reuse one row via UPDATE rather than two separate INSERTs (to match the plan's specified expected key value on a primary-key column).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Ready for Plan 03 (CAP-03: turning the current PK-less-table intermediate state — a zero-argument trigger falling into the legacy branch — into a migrate-time refusal).
- Phase 211 (read side) and Phase 212 (health/drift) have their hand-offs recorded above and in `210-CONTEXT.md` D-04; no additional research needed from this plan.
- No blockers.

---
*Phase: 210-pk-agnostic-capture*
*Completed: 2026-09-25*

## Self-Check: PASSED

- FOUND: test/threadline/capture/legacy_trigger_pk_fallback_test.exs
- FOUND: test/support/legacy_trigger_sql.ex (v0_10_2_install_function/2)
- FOUND commit: 01386c90 (Task 1)
- FOUND commit: 31d6a870 (Task 2)
- Re-ran `mix test test/threadline/capture/legacy_trigger_pk_fallback_test.exs test/threadline/capture/legacy_trigger_regeneration_test.exs test/threadline/capture/trigger_pk_shapes_test.exs` — 23 tests, 0 failures
