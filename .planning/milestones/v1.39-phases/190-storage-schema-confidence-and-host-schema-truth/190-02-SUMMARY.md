---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 02
subsystem: storage-schema
tags: [ecto, postgres, schema-prefix, tests, storage-schema]

requires:
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: 190-01 quoted generated migration storage-schema contracts
provides:
  - Prefix-free Threadline-owned Ecto schemas
  - Static source and runtime contracts against reintroducing fixed default prefixes
  - Explicit storage-schema test helpers for default and custom Threadline storage
affects: [phase-190, query-tests, test-support, storage-schema]

tech-stack:
  added: []
  patterns:
    - Owned Threadline schemas do not declare fixed storage prefixes
    - Test fixtures use Threadline.StorageSchema.repo_opts/1 for owned storage rows
    - Storage-schema test helpers restore app config after temporary overrides

key-files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-02-SUMMARY.md
    - test/threadline/storage_schema_prefix_contract_test.exs
    - test/support/storage_schema_case.ex
  modified:
    - lib/threadline/capture/audit_transaction.ex
    - lib/threadline/capture/audit_change.ex
    - lib/threadline/semantics/audit_action.ex
    - lib/threadline/governance/evidence_record.ex
    - lib/threadline/governance/export_job.ex
    - lib/threadline/governance/retention_run.ex
    - lib/threadline/governance/saved_view.ex
    - test/support/data_case.ex
    - test/threadline/query_test.exs

key-decisions:
  - "Threadline-owned Ecto schemas now rely on Repo prefix options instead of fixed @schema_prefix attributes."
  - "Storage-schema test support is explicit and test-only; it does not add a production fallback or Repo hook."

patterns-established:
  - "Owned schema prefix contract: source files and __schema__(:prefix) are both checked."
  - "Dual-storage cleanup: Threadline test support cleans threadline and audit in FK-safe order when schemas exist."

requirements-completed: [SCHEMA-02]

duration: 8min
completed: 2026-07-01
status: complete
---

# Phase 190 Plan 02: Remove Owned Fixed Prefixes and Add Explicit Storage-Schema Test Support Summary

**Threadline-owned Ecto schemas are prefix-free, source-locked against fixed default prefixes, and backed by explicit test helpers for default and custom storage schemas.**

## Performance

- **Duration:** 8min
- **Started:** 2026-07-01T19:48:40Z
- **Completed:** 2026-07-01T19:56:35Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Removed `@schema_prefix "threadline"` from all seven Threadline-owned Ecto schemas while preserving table sources, fields, primary keys, associations, and changesets.
- Added `storage_schema_prefix_contract_test.exs` to fail on either source-level fixed-prefix reintroduction or runtime `__schema__(:prefix)` drift.
- Added `Threadline.StorageSchemaCase` with explicit repo options, temporary config override restoration, custom `audit` storage setup, and FK-safe cleanup for `threadline` and `audit`.
- Updated DataCase cleanup and QueryTest fixtures to seed Threadline-owned rows through explicit storage-prefix options after fixed prefixes were removed.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Owned schema prefix contract** - `e9a8ff0f` (test)
2. **Task 1 GREEN: Remove fixed owned schema prefixes** - `b1e12313` (feat)
3. **Task 2 RED: Storage-schema test helper contract** - `e78e8b45` (test)
4. **Task 2 GREEN: Explicit storage-schema test support** - `2467bc20` (test)

## Files Created/Modified

- `test/threadline/storage_schema_prefix_contract_test.exs` - Static and runtime contracts for prefix-free owned schemas plus storage-schema test helper behavior.
- `test/support/storage_schema_case.ex` - Test-only helpers for explicit repo prefix options, temporary storage config overrides, schema preparation, and cleanup.
- `test/support/data_case.ex` - Uses storage-schema-aware cleanup instead of unprefixed deletes.
- `test/threadline/query_test.exs` - Seeds owned rows through `repo_opts()` so tests target Threadline storage explicitly.
- `lib/threadline/capture/audit_transaction.ex` - Removed fixed default prefix.
- `lib/threadline/capture/audit_change.ex` - Removed fixed default prefix.
- `lib/threadline/semantics/audit_action.ex` - Removed fixed default prefix.
- `lib/threadline/governance/evidence_record.ex` - Removed fixed default prefix.
- `lib/threadline/governance/export_job.ex` - Removed fixed default prefix.
- `lib/threadline/governance/retention_run.ex` - Removed fixed default prefix.
- `lib/threadline/governance/saved_view.ex` - Removed fixed default prefix.

## Decisions Made

- Used explicit per-operation `StorageSchema.repo_opts/1` in tests rather than a Repo default hook or PostgreSQL `search_path`, keeping omitted prefix plumbing visible.
- Kept custom `audit` schema preparation in `test/support` only; production storage routing remains owned by later Phase 190 plans.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated QueryTest fixtures to use explicit storage prefixes**
- **Found during:** Task 2 (Make storage test support explicit)
- **Issue:** After fixed schema prefixes were removed, `test/threadline/query_test.exs` fixture inserts without repo prefix options targeted `public.audit_transactions` and `public.audit_actions`, causing the plan-required `query_test` verification to fail.
- **Fix:** Imported `Threadline.StorageSchemaCase` through `DataCase` and updated local QueryTest fixture inserts to pass `repo_opts()`.
- **Files modified:** `test/support/data_case.ex`, `test/threadline/query_test.exs`
- **Verification:** `mix test test/threadline/storage_schema_prefix_contract_test.exs test/threadline/query_test.exs`
- **Committed in:** `2467bc20`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** The fix was required by the plan's own verification command and stayed within explicit test-support behavior for SCHEMA-02.

## Issues Encountered

- `mix format --check-formatted` initially flagged formatter-only changes in the new helper and one query fixture line. `mix format` was applied and the Task 2 implementation commit was amended before final verification.

## Known Stubs

None - stub scan found no placeholder/TODO-style stubs in modified files. The scan only matched ordinary test assertions for `nil` and empty-list behavior.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix compile --warnings-as-errors` - PASSED
- `bash -lc '! rg -n "@schema_prefix \"threadline\"" lib/threadline/capture/audit_transaction.ex lib/threadline/capture/audit_change.ex lib/threadline/semantics/audit_action.ex lib/threadline/governance/evidence_record.ex lib/threadline/governance/export_job.ex lib/threadline/governance/retention_run.ex lib/threadline/governance/saved_view.ex'` - PASSED
- `mix test test/threadline/storage_schema_prefix_contract_test.exs test/threadline/query_test.exs` - PASSED (59 tests, 0 failures)
- `mix format --check-formatted` - PASSED

## TDD Gate Compliance

- Task 1 RED failed for fixed source/runtime prefixes, then GREEN passed after removing seven `@schema_prefix "threadline"` attributes.
- Task 2 RED failed because `Threadline.StorageSchemaCase` did not exist, then GREEN passed after adding explicit test support and prefix-aware fixtures.

## Threat Flags

None - no new production network, auth, file-access, or trust-boundary surface was introduced. Test-helper database schema setup is the planned mitigation for T-190-06.

## Next Phase Readiness

Plan 190-02 closes the structural fixed-prefix risk for SCHEMA-02. Later Phase 190 plans can now wire production Repo operations, preloads, export, retention, and operator reads against `StorageSchema.repo_opts/1` without schema modules silently forcing `threadline`.

## Self-Check: PASSED

- Found summary file path to be created: `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-02-SUMMARY.md`
- Found task commits: `e9a8ff0f`, `b1e12313`, `e78e8b45`, `2467bc20`
- Final worktree check before summary write was clean.

---
*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Completed: 2026-07-01*
