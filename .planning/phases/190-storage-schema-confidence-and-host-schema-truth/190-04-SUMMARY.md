---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 04
subsystem: storage-schema
tags: [ecto, postgres, export, operator-surface]

requires:
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: 190-02 prefix-free owned Ecto schemas and explicit storage-schema test helpers
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: 190-03 prefix-aware export reads through Threadline.Export
provides:
  - Prefix-stable queued export job fetch, status transition, and stream orchestration
  - Prefix-stable export cleanup and abandoned-run reconciliation
  - Prefix-aware export download lookup that preserves actor authorization
affects: [phase-190, export, governance, operator-surface]

tech-stack:
  added: []
  patterns:
    - "Background export paths resolve the configured storage schema once and reuse that prefix for all job operations."
    - "Dual-schema sentinel tests use matching UUIDs across audit and threadline to catch wrong-prefix reads, updates, and deletes."

key-files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-04-SUMMARY.md
  modified:
    - lib/threadline/export/orchestrator.ex
    - lib/threadline/export/cleanup_task.ex
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - test/threadline/export/orchestrator_test.exs
    - test/threadline/export/cleanup_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs

key-decisions:
  - "Queued export and cleanup runtimes resolve storage_schema once per run/state instead of re-reading global config for each Repo operation."
  - "Export downloads resolve the configured storage schema before lookup and apply actor authorization only after the prefix-scoped fetch."

patterns-established:
  - "Storage-prefix stability tests may flip global config mid-operation to prove a path is using its resolved prefix."
  - "Export governance fixtures must insert/read owned schemas through repo_opts/1 after fixed @schema_prefix removal."

requirements-completed: [SCHEMA-01, SCHEMA-02]

duration: 15 min
completed: 2026-07-01
status: complete
---

# Phase 190 Plan 04: Queued Export Storage Schema Summary

**Queued export jobs, cleanup, and download lookup now use deliberate storage-prefix selection under custom `audit` schemas.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-01T20:33:00Z
- **Completed:** 2026-07-01T20:48:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Queued export orchestration now resolves the configured storage schema once per run and reuses that prefix for job fetches, status transitions, and export stream reads.
- Export cleanup stores the selected storage schema in GenServer state and reuses it for abandoned-run reconciliation, expired-job selection, and deletion.
- Export download lookup now resolves the configured storage schema before fetching the job, then preserves existing actor authorization and delivery behavior.
- Added dual-schema sentinel tests covering wrong-prefix job updates, cleanup deletes, download lookup, and wrong-actor denial.

## Task Commits

1. **Task 1 RED: queued export and cleanup storage-schema contracts** - `3f1815b5` (test)
2. **Task 1 GREEN: queued export storage-prefix stability** - `12a06e56` (feat)
3. **Task 2 RED: export download storage-schema contracts** - `0290c089` (test)
4. **Task 2 GREEN: prefix-aware download lookup helper** - `27176698` (feat)

## Files Created/Modified

- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-04-SUMMARY.md` - Plan completion summary.
- `lib/threadline/export/orchestrator.ex` - Captures the selected storage schema once and passes it through export-job reads, writes, and stream export rows.
- `lib/threadline/export/cleanup_task.ex` - Stores the selected storage schema in cleanup state and reuses one resolved prefix for cleanup/reconcile Repo operations.
- `lib/threadline/operator_surface/controllers/export_controller.ex` - Fetches export jobs through a prefix-aware helper before actor authorization.
- `test/threadline/export/orchestrator_test.exs` - Adds queued export dual-schema sentinel tests and prefix-explicit fixtures.
- `test/threadline/export/cleanup_test.exs` - Adds cleanup dual-schema sentinel tests and prefix-explicit fixtures.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` - Adds configured-storage download sentinels and prefix-explicit controller fixtures.

## Decisions Made

- Queued export jobs use the globally configured storage schema at worker run time, captured once for the full operation.
- Cleanup captures the selected storage schema at GenServer init and carries it in state, matching the retention pruner pattern from Plan 190-05.
- Download lookup keeps the authorization check after the prefix-scoped fetch so a default-schema sentinel cannot satisfy actor authorization under `storage_schema: "audit"`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired focused export fixtures after fixed-prefix removal**
- **Found during:** Task 1 and Task 2 RED baseline runs.
- **Issue:** Existing focused export/controller tests inserted or deleted owned Threadline schemas without repo prefix options after Plan 190-02 removed fixed `@schema_prefix "threadline"`.
- **Fix:** Updated touched fixtures and cleanup setup to use `repo_opts/1` and `clean_storage_schemas!/0` so tests target `threadline` or `audit` deliberately.
- **Files modified:** `test/threadline/export/orchestrator_test.exs`, `test/threadline/export/cleanup_test.exs`, `test/threadline/operator_surface/controllers/export_controller_test.exs`
- **Verification:** Focused Task 1 and Task 2 test commands pass.
- **Committed in:** `3f1815b5`, `0290c089`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** Required to make the plan's storage-prefix tests meaningful after the Phase 190 prefix model change. No product scope expansion.

## Issues Encountered

None remaining. Initial focused controller/export tests exposed expected prefix-free fixture failures, then the repaired fixtures allowed the new storage-schema assertions to exercise the intended behavior.

## Known Stubs

None. Stub scan found only existing user-facing unavailable-download copy, not placeholder or unwired UI behavior.

## Threat Flags

None. The new background-worker and controller trust boundaries were already covered by `T-190-09` and `T-190-10`; this plan mitigated them with resolved prefix reuse and actor authorization preservation.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix compile --warnings-as-errors` - PASSED
- `mix test test/threadline/export/orchestrator_test.exs test/threadline/export/cleanup_test.exs` - PASSED (8 tests, 0 failures)
- `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` - PASSED (23 tests, 0 failures)
- `mix format --check-formatted` - PASSED

## TDD Gate Compliance

- Task 1 RED failed on the new dual-schema assertions: the audit export job stayed `running` after config drift, and the audit cleanup row was not deleted. GREEN passed after the worker and cleanup reused resolved storage prefixes.
- Task 2 RED failed on the new controller source contract requiring a resolved-prefix download lookup helper. GREEN passed after the helper was added and behavior sentinels confirmed audit download/authorization behavior.

## Next Phase Readiness

Queued export, cleanup, and download governance paths are ready for the remaining Phase 190 operator storage-read and final dual-schema proof plans. `SCHEMA-01` remains milestone-level pending until Plan 190-10 completes the full end-to-end proof.

## Self-Check: PASSED

- Summary path created: `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-04-SUMMARY.md`
- Task commits found: `3f1815b5`, `12a06e56`, `0290c089`, `27176698`
- Final production/test worktree was clean before summary creation.

---
*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Completed: 2026-07-01*
