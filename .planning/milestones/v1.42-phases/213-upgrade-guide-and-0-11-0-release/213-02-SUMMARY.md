---
phase: 213-upgrade-guide-and-0-11-0-release
plan: 02
subsystem: testing
tags: [postgres-triggers, migration, doc-contract, real-pg, rollback]

requires:
  - phase: 213-upgrade-guide-and-0-11-0-release
    provides: "guides/upgrading-to-0.11.md's marker-wrapped backfill (single-column, composite) and rollback-cleanup SQL blocks, from 213-01"
provides:
  - "test/threadline/upgrade_backfill_test.exs: real-PG proof that the guide's own extracted backfill SQL resolves legacy INSERT/UPDATE rows for id, non-id, and composite keys, leaves DELETE rows and the id-keyed table untouched, is idempotent, and survives batch interruption"
  - "test/threadline/upgrade_backfill_test.exs: proof that a shared-function pair regenerates cleanly into two distinct functions, a timestamptz-keyed table is refused at migrate time and keeps its legacy trigger, the row-history index migration applies, and trigger_findings/trigger_coverage report exactly the documented shape"
  - "test/threadline/upgrade_rollback_test.exs: real-PG catalog proof that Ecto.Migrator :down, all: true over the full upgraded fixture (using the guide's edited down for the shared pair) leaves no orphan capture function and drops no foreign trigger"
  - "test/support/legacy_trigger_sql.ex: v0_10_2_drop_function_for_table/2, the frozen byte-for-byte 0.10.2 cascading function-drop statement"
  - "guides/upgrading-to-0.11.md: corrected Step 2 prose about pk_drift on refused-type tables (the test proved a legacy no-argument trigger on a non-id key DOES report pk_drift, as the finding-code table already said)"
affects: [213-03 (release lane needs this proof in place before landing)]

actuals:
  tokens: 11600
  tasks: 3
  commits: 3
  plan_head_before: 0fe8584940852efe624714013755dc00836ddfe1

tech-stack:
  added: []
  patterns:
    - "Marker-extraction-and-substitute pattern for testing published guide SQL: File.read! + String.split on the guide's own literal HTML-comment markers, then String.replace/3 only for the guide's own documented angle-bracket placeholders — never a hand-duplicated copy of the SQL."
    - "Ecto.Migrator.run(repo, path, :down, all: true) as the catalog-level rollback proof pattern, distinct from the existing single-migration Harness.migrate_up/migrate_down round trips; requires Code.compiler_options(ignore_module_conflict: true) around the call because the same migration modules were already compiled once by MigrationHarness.migrate_up/1."

key-files:
  created:
    - test/threadline/upgrade_backfill_test.exs
    - test/threadline/upgrade_rollback_test.exs
  modified:
    - test/support/legacy_trigger_sql.ex
    - guides/upgrading-to-0.11.md

key-decisions:
  - "Task 2's 'run the single-column block for the non-id table' instruction was satisfied with a fresh table (upg_widgets) inside the comprehensive multi-table fixture, distinct from Task 1's isolated upg_documents tracer, so the multi-table default-mode regenerate command is exercised against a non-id table too, not just the id-keyed and composite ones."
  - "The interruption edge (stop after one batch, rerun to completion) is proven by asserting the final resolved keys are exactly the values that must, by construction, match a table's data_after — since the backfill's WHERE clause makes every row's resolved key a pure function of its own data_after, this is equivalent to comparing against a hypothetical uninterrupted run without needing to execute one twice."
  - "v0_10_2_drop_function_for_table/2 takes (function_name, storage_schema) and interpolates directly (not through the current StorageSchema renderer), matching v0_10_2_install_function/2's own style, so a future change to StorageSchema.function/2 cannot quietly change this frozen fixture."

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "The guide's exact single-column and composite backfill SQL, extracted by marker only, resolves legacy INSERT/UPDATE rows on real PostgreSQL for a non-id table, a composite-key table, and (as a no-op) an id-keyed table; DELETE rows and a rerun are proven untouched; a batch interruption resolves to the identical final state."
    requirement: "REL-02"
    verification:
      - kind: integration
        ref: "test/threadline/upgrade_backfill_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "A shared 0.10.x per-table capture function pair regenerates together into two distinct functions with no shared_capture_function finding; a timestamptz-keyed table is refused at migrate time naming the column and keeps its legacy trigger; the row-history index migration applies and is valid; trigger_findings/trigger_coverage report the documented shape over the whole fixture."
    requirement: "REL-02"
    verification:
      - kind: integration
        ref: "test/threadline/upgrade_backfill_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Rolling back the whole upgraded fixture (Ecto.Migrator :down, all: true, using the guide's edited shared-pair down) leaves no orphan threadline_capture_changes_* function and drops no foreign (non-Threadline) trigger, proven against pg_proc/pg_trigger directly."
    requirement: "REL-02"
    verification:
      - kind: integration
        ref: "test/threadline/upgrade_rollback_test.exs"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-09-26
status: complete
---

# Phase 213 Plan 02: Upgrade Guide and 0.11.0 Release Summary

**Real-PG proof that `guides/upgrading-to-0.11.md`'s published upgrade steps and marker-wrapped backfill/rollback SQL work exactly as written against a seeded 0.10.x fixture, including a full `Ecto.Migrator :down, all: true` catalog proof that no capture function is orphaned and no foreign trigger is dropped.**

## Performance

- **Duration:** ~55min
- **Started:** 2026-09-26T~13:20Z
- **Completed:** 2026-09-26T~14:15Z
- **Tasks:** 3
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `test/threadline/upgrade_backfill_test.exs`: a tracer proving the guide's single-column backfill SQL (extracted by its own markers, only documented placeholders substituted) on a non-id-keyed table, plus a comprehensive second test proving every remaining D-08 fixture shape — id-keyed (untouched), composite (backfilled with the composite block), a shared-function pair (regenerated together into two distinct functions), a timestamptz table (refused at migrate time, kept on its legacy trigger), the row-history index, `trigger_findings`/`trigger_coverage`, and the batch-interruption edge
- `test/threadline/upgrade_rollback_test.exs`: the first live-catalog rollback-all proof in the repo — seeds a default-mode table and a 0.10.x shared-function pair plus two foreign (non-Threadline) triggers, runs the full documented upgrade, then rolls everything back with `Ecto.Migrator.run(..., :down, all: true)` using the guide's own edited down for the shared pair (its trigger drops, then the verbatim rollback-cleanup SQL) — no orphan function, no dropped foreign trigger
- `test/support/legacy_trigger_sql.ex` gained `v0_10_2_drop_function_for_table/2`, the frozen byte-for-byte 0.10.2 cascading drop statement, so the rollback test can assert on the documented hazard as text without ever running it
- Corrected one guide sentence in `guides/upgrading-to-0.11.md` Step 2 that claimed a refused-type table would not show a `pk_drift` finding; the live proof shows a legacy no-argument trigger on a non-`id` real key does report `pk_drift` (matching what the finding-code table already documented) — prose now says so plainly instead of contradicting the table above it
- REL-02 ticked complete in `REQUIREMENTS.md` (checkbox + traceability); REL-03 stays Pending for the release-lane plan (213-03)

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): the guide's single-column backfill SQL on a non-id table** - `da4d2b3f` (test)
2. **Task 2: id, composite, shared pair, timestamptz, index, health, interruption** - `3df2e0e9` (test)
3. **Task 3: rollback-all catalog proof with foreign triggers** - `6887a21e` (test)

**Plan metadata:** (this commit, docs)

## Files Created/Modified
- `test/threadline/upgrade_backfill_test.exs` - Real-PG upgrade + guide-extracted backfill proof (all D-08 fixture shapes)
- `test/threadline/upgrade_rollback_test.exs` - Real-PG rollback-all catalog proof (no orphan function, foreign triggers survive)
- `test/support/legacy_trigger_sql.ex` - Added `v0_10_2_drop_function_for_table/2`
- `guides/upgrading-to-0.11.md` - Corrected the Step 2 `pk_drift`-on-refused-type sentence

## Decisions Made
- Used a fresh, dedicated non-id table (`upg_widgets`) for Task 2's multi-table default-mode regenerate command, rather than reusing Task 1's `upg_documents`, so the "regenerate several default-mode tables together" path is itself exercised against a non-id shape, not just replayed from Task 1's isolated single-table case.
- Proved the interruption edge without executing two full runs to compare: since the backfill's guard makes each row's resolved key a pure function of only that row's own `data_after`, asserting the final state matches the values `data_after` implies is equivalent to comparing against a hypothetical uninterrupted run.
- Kept the frozen `v0_10_2_drop_function_for_table/2` renderer's interpolation style identical to `v0_10_2_install_function/2` (direct string interpolation of a pre-quoted schema/name, never through `StorageSchema`), so a future change to the current-release SQL renderers cannot silently change what this fixture asserts about 0.10.2's actual behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixture triggers for the id-keyed, composite, non-id, and timestamptz tables initially called the wrong (unqualified `public`) function name**
- **Found during:** Task 2, first test run
- **Issue:** `LegacyTriggerSQL.v0_10_2_create_trigger/3`'s `function_ref` defaults to the unqualified `"public"."threadline_capture_changes"()` when omitted, but the test's actual storage schema is `"threadline"` (per `config/test.exs`); the fixture inserts failed with `relation "public.audit_transactions" does not exist`.
- **Fix:** Passed the storage-qualified function reference explicitly (`StorageSchema.function("threadline_capture_changes") <> "()"`) to every live-DB trigger-creation call, matching the pattern Task 1's tracer already used correctly.
- **Files modified:** `test/threadline/upgrade_backfill_test.exs`
- **Committed in:** `3df2e0e9` (part of Task 2 commit)

**2. [Rule 1 - Bug] Rollback test's foreign-trigger snapshot query encoded a table name as an oid**
- **Found during:** Task 3, first test run
- **Issue:** `Postgrex` encodes a bare `regclass`-typed query parameter as an integer oid when given a binary, per the documented Postgrex oid-type-encoding gotcha (already noted in `MigrationHarness`'s own moduledoc); the query raised `ArgumentError`.
- **Fix:** Cast the parameter as `$1::text::regclass`, matching `MigrationHarness.regclass_text/2`'s existing pattern.
- **Files modified:** `test/threadline/upgrade_rollback_test.exs`
- **Committed in:** `6887a21e` (part of Task 3 commit)

**3. [Rule 1 - Bug] `billing` schema not created before the shared-pair fixture table in the rollback test**
- **Found during:** Task 3, first test run
- **Issue:** `billing.invoices`' `CREATE TABLE` failed with `schema "billing" does not exist` — the rollback test's fixture setup omitted the `CREATE SCHEMA IF NOT EXISTS billing` statement the backfill test's analogous fixture already has.
- **Fix:** Added `Repo.query!("CREATE SCHEMA IF NOT EXISTS billing")` before creating the shared-pair tables.
- **Files modified:** `test/threadline/upgrade_rollback_test.exs`
- **Committed in:** `6887a21e` (part of Task 3 commit)

**4. [Rule 1 - Bug] Guide prose contradicted its own finding-code table on refused-type `pk_drift`**
- **Found during:** Task 2, health assertions
- **Issue:** `guides/upgrading-to-0.11.md` Step 2 claimed a refused-type table "is not expected to show a `pk_drift` ... error for that reason alone," but the `pk_drift` row in the Step 5 finding-code table already documents that "a legacy trigger with no arguments on a table whose real key is not `id` reports this code too." The live proof (an `upg_readings` table with a `timestamptz` key, refused at migrate time, keeping its legacy no-argument trigger) confirmed `trigger_findings` does report `pk_drift` here — the Step 2 sentence was simply wrong.
- **Fix:** Rewrote the Step 2 paragraph to state plainly that `trigger_coverage` still counts the table as covered, but `trigger_findings` does report it under the documented `pk_drift` row, and that this is expected, not a sign of a separate problem.
- **Files modified:** `guides/upgrading-to-0.11.md`
- **Verification:** `mix test test/threadline/upgrade_backfill_test.exs test/threadline/upgrading_to_0_11_doc_contract_test.exs` (13 tests, 0 failures) — the doc-contract test does not pin the corrected sentence's exact wording, so no contract update was needed.
- **Committed in:** `3df2e0e9` (part of Task 2 commit)

---

**Total deviations:** 4 auto-fixed (all Rule 1 bugs in test fixtures or guide prose, found and fixed during the plan's own verify loop)
**Impact on plan:** All four were necessary to get the proof running and accurate. No scope creep — no product code was touched; the one guide edit corrects a factual claim the test itself disproved, per the plan's explicit instruction to fix wrong prose rather than weaken an assertion.

## Issues Encountered
None beyond the deviations above.

## User Setup Required
None - no external service configuration required.

## Rollback proof result

**GREEN.** `Ecto.Migrator.run(Repo, tmp_migrations_path, :down, all: true, log: false)` over the full fixture (a default-mode table, a 0.10.x shared-function pair regenerated together, and the row-history index migration) left:
- no function matching `threadline_capture_changes_%` in the storage schema that was not present in the pre-fixture baseline;
- no Threadline trigger on any fixture table;
- both foreign (non-Threadline) triggers — one on an audited table, one on an unaudited table — present with identical `{tgname, tgfoid, tgenabled}` before and after.

No architectural or product-code change was needed; the rollback-cleanup SQL published in the guide, run as the shared pair's edited `down`, worked exactly as documented on the first real attempt (after the two fixture-setup bugs above were fixed).

## Observation for the planner (no fix, no new test)

Reading `down_body/2` in `lib/mix/tasks/threadline.gen.triggers.ex`: a migration chain made only of 0.11 migrations — a first-run default-mode trigger migration for a table, followed later by a rerun that adds a per-table capture function for that same table (e.g. adding `mask`/`exclude` rules) — would, on `Ecto.Migrator :down, all: true`, leave the **rerun's** per-table function without a trigger after rollback. `down_body/2` only emits function-drop statements for `first_run_specs` (tables not in `rerun_tables`); a rerun's `down` is a no-op by design (the comment explains capture intentionally stays on with the rerun's policy). But `all: true` also rolls back the **first-run** migration underneath it, dropping the table's trigger entirely — at which point the rerun's per-table function, which no code path ever drops, is orphaned. This is a first-run-then-rerun chain entirely within 0.11 (no 0.10.x fixture involved), distinct from the phase-209 shared-function hazard this plan's fixture covers, and is out of this plan's scope per the dispatch instruction (record-only). No test added; no product code changed.

## Next Phase Readiness
- REL-02 is complete: the upgrade guide's documented procedure and SQL are proven on real PostgreSQL, including the rollback-all catalog proof.
- Full `mix test` suite: 2207 tests, 0 failures (`mix verify.test`, run after all three tasks). `mix format --check-formatted` and `mix verify.credo` both exit 0 across the whole repo.
- 213-03 (release lane) can now cite this plan's proof when compiling the local pre-land gate list; REL-03 remains Pending, a maintainer action, until the release actually ships.
- The `down_body/2` first-run-then-rerun observation above is available for the planner to triage into a future phase or backlog item; it is not this milestone's concern.

---
*Phase: 213-upgrade-guide-and-0-11-0-release*
*Completed: 2026-09-26*

## Self-Check: PASSED
All claimed files (`test/threadline/upgrade_backfill_test.exs`, `test/threadline/upgrade_rollback_test.exs`, `test/support/legacy_trigger_sql.ex`, `guides/upgrading-to-0.11.md`) and task commit hashes (`da4d2b3f`, `3df2e0e9`, `6887a21e`) verified present.
