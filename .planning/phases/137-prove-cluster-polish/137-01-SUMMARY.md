---
phase: 137-prove-cluster-polish
plan: 01
subsystem: ui
tags: [operator-surface, presentation, css, prove-cluster]
requires:
  - phase: 136-design-system-hardening
    provides: dark token and interaction contrast baseline
provides:
  - Shared export readiness and action-label helpers
  - Shared secondary reference display metadata
  - Token-backed Prove cluster CSS primitives
affects: [exports, evidence, retention, policy-redaction]
tech-stack:
  added: []
  patterns: [pure presentation helpers, token-backed tl primitives]
key-files:
  created:
    - test/threadline/operator_surface/presentation_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
  modified:
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/operator_surface/style.ex
key-decisions:
  - "Export readiness remains pure presentation logic derived from status, file_path, and expires_at."
  - "Secondary refs expose full title metadata while truncating visible text for dense operator cards."
  - "Prove primitives reuse existing dark tokens and .tl-* architecture."
patterns-established:
  - "Presentation.export_readiness/2 owns derived export readiness buckets."
  - "Presentation.secondary_ref/2 owns visible/title metadata for actor, subject, and query refs."
  - ".tl-job-group, .tl-secondary-ref, and .tl-target-row are the Wave 2 shared CSS seams."
requirements-completed: [POLISH-PROVE]
duration: 14min
completed: 2026-06-04
---

# Phase 137: Plan 01 Summary

**Shared Prove-cluster readiness, reference, grouping, and target-row primitives for Wave 2 polish.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-06-04T07:18:00Z
- **Completed:** 2026-06-04T07:32:18Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added pure export readiness helpers for `Ready to hand off`, `Preparing`, `Needs attention`, and `Unavailable`, including rank, downloadable, and action-label contracts.
- Added secondary ref metadata that preserves the full value in `title` while middle-truncating visible actor/subject/query refs.
- Added token-backed `.tl-job-group`, `.tl-secondary-ref`, and `.tl-target-row` primitives with contract coverage.

## Task Commits

1. **Tasks 1-2: Shared readiness/ref helpers and Prove primitives** - `7b9e034` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/presentation.ex` - Added export readiness/action helpers and secondary ref metadata.
- `lib/threadline/operator_surface/style.ex` - Added grouped job, secondary ref, and target-row primitives.
- `test/threadline/operator_surface/presentation_test.exs` - Added direct helper coverage for readiness buckets, action labels, ranking, and ref metadata.
- `test/threadline/operator_surface/style_contract_test.exs` - Added contract checks for the new token-backed `.tl-*` primitives.

## Decisions Made

Followed the plan as specified. Export readiness remains presentation-only and does not alter persisted export job semantics or evidence proof vocabulary.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` - 31 tests, 0 failures
- `rg -n "Ready to hand off|Preparing download|Export expired|File unavailable|tl-job-group|tl-target-row" lib/threadline/operator_surface/presentation.ex lib/threadline/operator_surface/style.ex test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/style_contract_test.exs` - passed

## Self-Check: PASSED

- Key files exist on disk.
- Commit `7b9e034` contains the implementation and test files.
- No Repo calls, route construction, LiveView events, or proof vocabulary changes were added to `Presentation`.

## Next Phase Readiness

Wave 2 can consume `Presentation.export_readiness/2`, `Presentation.export_action_label/2`, `Presentation.secondary_ref/2`, `.tl-job-group`, `.tl-secondary-ref`, and `.tl-target-row`.

---
*Phase: 137-prove-cluster-polish*
*Completed: 2026-06-04*
