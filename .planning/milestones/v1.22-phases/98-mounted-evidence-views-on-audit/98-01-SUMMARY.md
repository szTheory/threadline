---
phase: 98-mounted-evidence-views-on-audit
plan: 01
subsystem: ui
tags: [phoenix, liveview, operator-surface, evidence]
requires: []
provides:
  - mounted /audit/evidence route on the existing operator surface
  - overview-first evidence LiveView with URL-driven subject and history drill-down
  - mounted tests for overview, narrowing, history, unsupported, and empty-state flows
affects: [operator-surface, evidence, liveview]
tech-stack:
  added: []
  patterns: [shared mounted header navigation, URL-driven evidence drill-down]
key-files:
  created:
    - lib/threadline/operator_surface/live/evidence_live.ex
    - test/threadline/operator_surface/live/evidence_live_test.exs
  modified:
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/style.ex
patterns-established:
  - "Mounted evidence stays on one canonical /audit/evidence surface."
  - "Latest-first evidence navigation uses query params for subject and history state."
requirements-completed: [SURF-01, SURF-02]
duration: 1h
completed: 2026-05-26
---

# Phase 98: Mounted Evidence Views On `/audit` Summary

**Mounted `/audit/evidence` now answers the overview-first proof question with one LiveView, URL-driven drill-down, and truthful mounted fallbacks**

## Performance

- **Duration:** 1h
- **Started:** 2026-05-26T12:05:00Z
- **Completed:** 2026-05-26T13:07:30Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added the canonical `/audit/evidence` route inside the existing `/audit` surface.
- Built a thin `EvidenceLive` layer over `Threadline.Evidence` plus proof-presenter semantics, keeping latest, subject narrowing, and history on one mounted route.
- Added mounted tests for overview, drill-down, unsupported, and empty-state behavior.

## Task Commits

No task commits were created. The worktree already contained unrelated user changes across Phase 98 files, so execution stayed uncommitted to avoid bundling non-phase edits.

## Files Created/Modified
- `lib/threadline/operator_surface/live/evidence_live.ex` - mounted evidence overview/history LiveView
- `test/threadline/operator_surface/live/evidence_live_test.exs` - mounted proof for overview, narrowing, history, unsupported, and empty states
- `lib/threadline/operator_surface/router.ex` - canonical `/audit/evidence` route
- `lib/threadline/operator_surface/components/surface_header.ex` - shared evidence badge/link
- `lib/threadline/operator_surface/style.ex` - mounted evidence table and section styling

## Decisions Made
- Kept evidence on one sibling route under `/audit` instead of introducing another mounted page family.
- Used `Threadline.Evidence` for reads and `Threadline.Evidence.Proof` only for shared verdict presentation, preserving the single truth model.

## Deviations from Plan

### Auto-fixed Issues

**1. Dirty worktree commit boundary**
- **Found during:** Plan execution
- **Issue:** Phase target files already had unrelated local edits, making atomic task commits unsafe.
- **Fix:** Preserved the dirty tree, implemented the phase changes in place, and recorded the no-commit deviation in the summary.
- **Files modified:** phase target files only
- **Verification:** targeted LiveView and auth tests passed

---

**Total deviations:** 1 auto-fixed
**Impact on plan:** Implementation and targeted verification completed without widening scope. Only task-level commit capture was skipped to avoid mixing unrelated changes.

## Issues Encountered
- `mix verify.test` still fails on the known unrelated `Threadline.CiTopologyContractTest` alias-drift assertion in `mix.exs`, which predates this phase’s mounted evidence work.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Mounted evidence route, navigation, and tests are in place for host-gated parity work.
- Full-suite verification remains blocked by the known unrelated CI topology alias drift.

---
*Phase: 98-mounted-evidence-views-on-audit*
*Completed: 2026-05-26*
