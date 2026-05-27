---
phase: 96-evidence-persistence-and-public-api
plan: 02
subsystem: api
tags: [evidence, queries, ecto, projections]
requires:
  - phase: 96
    provides: public evidence write boundary and normalized record shape
provides:
  - generic evidence history helpers
  - latest-per-subject-ref projections
  - stable list and singular return shapes
affects: [phase-97, phase-98, evidence-readers, operator-surface]
tech-stack:
  added: []
  patterns: [history-first reads, latest-as-projection, explicit filter validation]
key-files:
  created: []
  modified:
    - lib/threadline/evidence.ex
    - test/threadline/evidence_test.exs
key-decisions:
  - "Kept history canonical and implemented `latest_*` helpers as ordered projections over append-only rows."
  - "Rejected unknown read filter keys loudly instead of silently ignoring them."
patterns-established:
  - "List helpers stay list-shaped and singular helpers stay singular regardless of options."
  - "Evidence query helpers validate subject, subject_ref, datetime, limit, and repo inputs before hitting Ecto."
requirements-completed: [PROOF-01]
duration: 4min
completed: 2026-05-25
---

# Phase 96: Evidence Persistence And Public API Summary

**The evidence context now exposes both canonical history reads and explicit latest projections without introducing mutable current-state storage.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-25T19:53:00Z
- **Completed:** 2026-05-25T19:56:23Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `list_history/2`, `list_subject_ref_history/4`, `list_latest_subject_refs/3`, and `get_latest_subject_ref/3` to `Threadline.Evidence`.
- Kept history helpers list-shaped, latest-overview helpers list-shaped, and singular latest helpers singular so later CLI and mounted consumers inherit one honest contract.
- Added focused tests proving append-only history remains available behind the latest projections and that unknown filter keys fail loud.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add generic history reads with explicit filters and stable return shapes** - Not committed in this run because the working tree already contained unrelated local changes.
2. **Task 2: Add explicit overview and singular latest helpers as append-only query projections** - Not committed in this run because the working tree already contained unrelated local changes.

**Plan metadata:** Not committed in this run.

## Files Created/Modified
- `lib/threadline/evidence.ex` - Added the read-side query helpers, filter validation, and latest projection logic.
- `test/threadline/evidence_test.exs` - Added history/latest proof for return-shape stability, miss cases, and explicit filter errors.

## Decisions Made
- Used the same explicit `repo:` and validation posture as the existing query/export APIs instead of inventing a new option-heavy DSL.
- Sorted latest projections by `recorded_at` and `id` after selecting the newest row per subject reference so later consumers get deterministic results.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed conflicting default-argument definitions in the new read helper overloads**
- **Found during:** Task 1 (Add generic history reads with explicit filters and stable return shapes)
- **Issue:** The first function overloads for `list_subject_ref_history` and `list_latest_subject_refs` conflicted with default-argument definitions and failed compilation.
- **Fix:** Split the arity-3 and arity-4 helpers cleanly so the convenience overloads delegate without conflicting defaults.
- **Files modified:** `lib/threadline/evidence.ex`
- **Verification:** `mix test test/threadline/evidence_test.exs --max-failures 1`
- **Committed in:** Not committed in this run.

---

**Total deviations:** 1 auto-fixed (1 blocking compile issue).
**Impact on plan:** No scope creep. The fix only corrected the public helper overload shape needed to satisfy the planned API.

## Issues Encountered

`mix verify.test` still fails on the current tree for an unrelated pre-existing assertion in `test/threadline/ci_topology_contract_test.exs` that expects a narrower `verify.doc_contract` alias string in the already-modified `mix.exs`. The phase-local evidence proof band passed, so the evidence work was left intact and the unrelated alias drift was not changed here.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 97 can reuse the same public evidence context for no-Phoenix proof generation instead of building its own reducers or mutable caches.

---
*Phase: 96-evidence-persistence-and-public-api*
*Completed: 2026-05-25*
