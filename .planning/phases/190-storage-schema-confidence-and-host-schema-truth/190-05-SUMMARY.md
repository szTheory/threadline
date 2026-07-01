---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 05
subsystem: storage-schema
tags: [ecto, postgres, retention, pruner, storage-schema]

requires:
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: 190-02 prefix-free owned Ecto schemas and explicit storage-schema test helpers
provides:
  - Prefix-aware retention dry-run counts, destructive purge deletes, and run records
  - Prefix-aware retention pruner abandoned-run updates and scheduled purge calls
  - Dual-storage sentinel tests proving default threadline rows survive selected audit storage runs
affects: [phase-190, retention, pruning, governance, storage-schema]

tech-stack:
  added: []
  patterns:
    - Retention resolves storage options once from caller opts and reuses them at every Repo boundary
    - Pruner runtime stores a resolved storage schema and forwards it into retention purge calls
    - Retention/pruner tests seed audit and threadline rows through explicit repo_opts/1 sentinels

key-files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-05-SUMMARY.md
  modified:
    - lib/threadline/retention.ex
    - lib/threadline/retention/pruner.ex
    - test/threadline/retention_test.exs
    - test/threadline/retention/pruner_test.exs

key-decisions:
  - "Retention direct runs resolve storage_schema from opts, defaulting to global config, so tests and advanced callers can prove the selected storage prefix explicitly."
  - "The pruner resolves storage_schema at start and passes that same schema into scheduled retention purge calls; normal application behavior still follows the global configured storage schema when no explicit option is passed."

patterns-established:
  - "Dual-storage retention sentinel: audit rows are the target while threadline rows are the false-positive trap."
  - "Pruner runtime prefix contract: abandoned-run cleanup and triggered purge must share one resolved storage schema."

requirements-completed: [SCHEMA-01, SCHEMA-02]

duration: 9 min
completed: 2026-07-01
status: complete
---

# Phase 190 Plan 05: Retention and Pruning Storage Prefix Safety Summary

**Retention dry-runs, destructive purges, run records, and pruner updates now target the selected Threadline storage schema while preserving default-schema sentinels.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-01T20:11:12Z
- **Completed:** 2026-07-01T20:19:31Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added retention dual-schema sentinels proving dry-run counts, destructive deletes, and run records target `audit` storage while `threadline` rows remain untouched.
- Threaded one resolved retention `storage_opts` value through count, insert, update, delete, and orphan-transaction cleanup Repo calls.
- Added pruner sentinels proving abandoned-run startup cleanup and triggered purge runs use the selected storage schema only.
- Updated pruner runtime state to resolve `storage_schema` at start and forward it into scheduled retention purges.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Retention storage-schema sentinel tests** - `d8bc1e0d` (test)
2. **Task 1 GREEN: Retention storage-prefix plumbing** - `6c0332d3` (feat)
3. **Task 2 RED: Pruner storage-schema sentinel tests** - `60c8aa3a` (test)
4. **Task 2 GREEN: Pruner storage-prefix plumbing** - `ad5f0b86` (feat)

## Files Created/Modified

- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-05-SUMMARY.md` - Plan completion summary.
- `lib/threadline/retention.ex` - Resolves storage options from purge opts and reuses them for retention run records, dry-run counts, change deletes, and orphan transaction deletes.
- `lib/threadline/retention/pruner.ex` - Resolves the pruner storage schema at startup, uses it for abandoned-run updates, and forwards it to scheduled retention purges.
- `test/threadline/retention_test.exs` - Uses prefix-aware fixtures and adds audit/threadline sentinels for dry-run, purge, and retention run storage isolation.
- `test/threadline/retention/pruner_test.exs` - Uses prefix-aware fixtures and adds audit/threadline sentinels for startup cleanup and triggered purge storage isolation.

## Decisions Made

- Direct `Retention.purge/1` now honors an explicit `storage_schema:` option while preserving global configured storage as the normal default.
- The pruner stores the resolved storage schema string instead of just repo options so it can pass the same storage selection into `Retention.purge/1`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired retention/pruner fixtures after fixed owned prefixes were removed**
- **Found during:** Task 1 and Task 2 RED baseline runs
- **Issue:** Existing retention and pruner tests still used unprefixed `Repo` fixture/setup calls after Plan 190-02 removed fixed `@schema_prefix` attributes, causing Ecto to query missing `public.threadline_retention_runs`.
- **Fix:** Updated touched tests to seed, read, aggregate, and clean Threadline-owned rows through `repo_opts/1`.
- **Files modified:** `test/threadline/retention_test.exs`, `test/threadline/retention/pruner_test.exs`
- **Verification:** `mix test test/threadline/retention_test.exs test/threadline/retention/pruner_test.exs`
- **Committed in:** `d8bc1e0d`, `60c8aa3a`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** The repair was required to make the plan's storage-schema sentinel tests meaningful after prior Phase 190 prefix removal. No product scope expansion.

## Issues Encountered

- The existing retention/pruner tests failed before new sentinels could run because their unprefixed setup targeted `public` after owned schema prefixes were removed. This was fixed in the RED test commits.

## Known Stubs

None - stub scan found only ordinary test assertions for `nil` and empty collections plus existing process-availability logic.

## Threat Flags

None - the storage-prefix trust boundary was already in this plan's threat model (`T-190-11`, `T-190-12`) and was mitigated with explicit prefix plumbing plus dual-schema sentinel tests.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix compile --warnings-as-errors` - PASSED
- `mix test test/threadline/retention_test.exs test/threadline/retention/pruner_test.exs` - PASSED (12 tests, 0 failures)
- `mix format --check-formatted` - PASSED

## TDD Gate Compliance

- Task 1 RED failed on the new retention selected-storage sentinel tests, then GREEN passed after `Retention.purge/1` threaded resolved storage options through every Repo boundary.
- Task 2 RED failed on the new pruner selected-storage sentinel tests, then GREEN passed after the pruner resolved and forwarded the selected storage schema.

## Next Phase Readiness

Plan 190-05 closes retention/pruner storage-prefix behavior for the configured/custom storage path. Later Phase 190 plans can reuse the same dual-schema sentinel pattern for queued export jobs, operator reads, and final end-to-end `audit` storage proof.

## Self-Check: PASSED

- Found summary file path to be created: `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-05-SUMMARY.md`
- Found task commits: `d8bc1e0d`, `6c0332d3`, `60c8aa3a`, `ad5f0b86`
- Verified key modified files exist: `lib/threadline/retention.ex`, `lib/threadline/retention/pruner.ex`, `test/threadline/retention_test.exs`, `test/threadline/retention/pruner_test.exs`
- Final production/test worktree was clean before summary creation.

---
*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Completed: 2026-07-01*
