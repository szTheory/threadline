---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 06
subsystem: operator-surface
tags: [elixir, phoenix-liveview, ecto, postgres, storage-schema]

requires:
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: storage schema resolver and prior prefixed service paths
provides:
  - Operator LiveView reads and writes use configured Threadline storage schema.
  - Timeline preloads, saved views, exports, evidence, retention, actor, and Home reads ignore default-schema sentinels.
  - Focused TDD coverage for operator storage-schema behavior.
affects: [operator-surface, storage-schema, evidence, retention, exports, actor-history]

tech-stack:
  added: []
  patterns:
    - StorageSchema.repo_opts(storage_schema: StorageSchema.get()) at operator Repo boundaries.
    - Explicit storage_schema opts forwarded through delegated Threadline service calls.
    - Cross-schema sentinel tests for operator LiveViews.

key-files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-06-SUMMARY.md
  modified:
    - lib/threadline/evidence.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/live/evidence_live.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - lib/threadline/operator_surface/live/start_live.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/live/actor_live_test.exs

key-decisions:
  - "Operator LiveViews resolve storage schema locally at the Repo/service boundary instead of relying on implicit default prefixes."
  - "Evidence storage schema is carried as service options, not user-facing evidence filters."
  - "Existing authorization scope, feature gates, route params, and operator copy were preserved while adding prefix options."

patterns-established:
  - "Use explicit storage opts for LiveView Repo reads, writes, and preloads touching Threadline-owned tables."
  - "When a LiveView delegates to Threadline service APIs, pass storage_schema in options alongside repo/scope."
  - "Use audit-vs-threadline sentinel rows in operator tests to prove configured-storage isolation."

requirements-completed: [SCHEMA-01, SCHEMA-02]

duration: 1h 39m
completed: 2026-07-01
status: complete
---

# Phase 190 Plan 06: Operator Storage Schema Summary

**Operator LiveViews now read, write, preload, and delegate through the configured Threadline storage schema instead of silently falling back to default storage.**

## Performance

- **Duration:** 1h 39m
- **Started:** 2026-07-01T20:53:35Z
- **Completed:** 2026-07-01T22:33:04Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- Timeline saved views, export job creation/update, export status reads, and visible Timeline preloads now use configured storage options.
- Evidence, retention history, Home health/resume reads, and actor history/summary reads now pass resolved storage schema options.
- Added focused TDD coverage proving configured `audit` storage rows render while default `threadline` sentinel rows are ignored.
- Fixed Evidence overview delegation so storage options are preserved when overview fan-outs call subject-specific evidence reads.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Timeline and Export Status storage tests** - `01938968` (test)
2. **Task 1 GREEN: Timeline and Export Status storage implementation** - `7faea511` (feat)
3. **Task 2 RED: Evidence, Retention, Home, and Actor storage tests** - `f462ce9a` (test)
4. **Task 2 GREEN: Remaining operator storage implementation** - `a4409107` (feat)

_Note: This was a TDD plan, so each task has a test commit followed by an implementation commit._

## Files Created/Modified

- `lib/threadline/evidence.ex` - Preserves storage schema options through Evidence overview subject fan-out.
- `lib/threadline/operator_surface/live/timeline_live.ex` - Uses configured storage opts for saved views, export jobs, and Timeline preloads.
- `lib/threadline/operator_surface/live/export_status_live.ex` - Uses configured storage opts for export job reads and queue updates.
- `lib/threadline/operator_surface/live/evidence_live.ex` - Passes storage schema options into Evidence service reads.
- `lib/threadline/operator_surface/live/retention_history_live.ex` - Uses configured storage opts for retention reads and destructive audit action recording.
- `lib/threadline/operator_surface/live/start_live.ex` - Uses configured storage opts for Home failed-export, retention, and saved-view reads.
- `lib/threadline/operator_surface/live/actor_live.ex` - Passes storage schema options into actor history calls and actor summary preloads.
- `test/threadline/operator_surface/live/*_test.exs` - Adds source-contract and cross-schema sentinel coverage, plus prefix-aware fixtures.

## Decisions Made

- Keep storage schema resolution local to operator LiveView boundaries rather than adding user-facing copy about prefixes.
- Preserve existing auth scope and feature-gate behavior by appending storage options to current repo/scope/query option lists.
- Treat Evidence overview option loss as a Rule 1 service bug because it blocked the configured-storage Evidence page behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired prefix-free test fixtures**
- **Found during:** Tasks 1 and 2
- **Issue:** Existing LiveView tests deleted and inserted Threadline-owned tables without repo prefix options after prior Phase 190 changes removed fixed schema prefixes, causing missing-table crashes before RED assertions could run.
- **Fix:** Updated planned test files to use `repo_opts()` and explicit `repo_opts("audit")` / `repo_opts("threadline")` sentinel inserts.
- **Files modified:** `test/threadline/operator_surface/live/timeline_live_test.exs`, `export_status_live_test.exs`, `evidence_live_test.exs`, `retention_history_live_test.exs`, `start_live_test.exs`, `actor_live_test.exs`
- **Verification:** Focused Task 1 and Task 2 test suites reached expected RED failures, then passed after implementation.
- **Committed in:** `01938968`, `f462ce9a`

**2. [Rule 1 - Bug] Corrected sentinel test setup mistakes**
- **Found during:** Tasks 1 and 2
- **Issue:** Some new sentinel assertions initially used ambient storage opts or unsupported Evidence subject names, so they did not prove the intended default-vs-configured storage isolation.
- **Fix:** Made sentinel rows explicitly target `audit` or `threadline`; changed Evidence sentinel coverage to use supported `retention_run` subjects differentiated by subject ref.
- **Files modified:** `test/threadline/operator_surface/live/export_status_live_test.exs`, `test/threadline/operator_surface/live/evidence_live_test.exs`
- **Verification:** Cross-schema sentinel tests pass in both focused operator test groups.
- **Committed in:** `7faea511`, `a4409107`

**3. [Rule 1 - Bug] Preserved Evidence overview storage options**
- **Found during:** Task 2
- **Issue:** `Threadline.Evidence.list_overview/2` accepted storage options but dropped them when delegating to `list_latest_subject_refs/3`, so EvidenceLive overview still missed configured-storage evidence rows.
- **Fix:** Forwarded the resolved repo plus original option list into subject-specific Evidence reads.
- **Files modified:** `lib/threadline/evidence.ex`
- **Verification:** EvidenceLive configured-storage sentinel test and full Task 2 focused suite pass.
- **Committed in:** `a4409107`

---

**Total deviations:** 3 auto-fixed issues (1 blocking fixture repair, 2 bugs)
**Impact on plan:** All auto-fixes were required for correctness and verification. No architectural change or package installation was introduced.

## Issues Encountered

- Existing tests had to be brought forward to the new prefix-free storage setup before meaningful RED failures could be observed.
- Evidence overview required a small service-level fix so the LiveView could honor the configured storage schema without treating `storage_schema` as a user filter.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix compile --warnings-as-errors` - passed
- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` - passed, 64 tests
- `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs` - passed, 67 tests
- `mix format --check-formatted` - passed

## Known Stubs

None. The stub scan found only existing UI placeholders and empty-state comparisons, not incomplete plan behavior.

## Self-Check: PASSED

- Summary file created at `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-06-SUMMARY.md`
- Required commits found: `01938968`, `7faea511`, `f462ce9a`, `a4409107`
- Verification commands passed after the final task commit.

## Next Phase Readiness

Plan 190-06 is ready for downstream Phase 190 proof work. Plan 190-10 can use these operator sentinel tests as implementation evidence for custom storage-schema confidence.

---
*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Completed: 2026-07-01*
