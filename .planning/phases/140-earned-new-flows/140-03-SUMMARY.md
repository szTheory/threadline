---
phase: 140-earned-new-flows
plan: "03"
subsystem: operator-surface
tags: [phoenix-liveview, exports, timeline, filter-params, export-auth]

requires:
  - phase: 140-earned-new-flows
    provides: "Existing Timeline filters, direct export endpoints, ExportStatus monitor, ExportJob queue path"
provides:
  - "EF3 Timeline carry-to-Exports affordance with P3/J6 trace attributes"
  - "Exports pre-populated Timeline context banner with allowlisted canonical filters"
  - "Actor-owned ExportJob queueing from carried Timeline context"
  - "Regression tests for invalid filters, unknown params, export auth denial, and direct endpoint guards"
affects: [operator-surface, exports, timeline, earned-flows]

tech-stack:
  added: []
  patterns:
    - "LiveView handoff params are parsed through FilterParams, validated by Query.validate_timeline_filters!/1, then canonicalized before persistence."
    - "Export actions remain behind existing threadline_exports_enabled/export authorization gates."

key-files:
  created:
    - ".planning/phases/140-earned-new-flows/140-03-SUMMARY.md"
  modified:
    - "lib/threadline/operator_surface/live/timeline_live.ex"
    - "lib/threadline/operator_surface/live/export_status_live.ex"
    - "test/threadline/operator_surface/live/timeline_live_test.exs"
    - "test/threadline/operator_surface/live/export_status_live_test.exs"
    - "test/threadline/operator_surface/controllers/export_controller_test.exs"

key-decisions:
  - "Carried Timeline context stores canonical URL filter strings in ExportJob.query_params so reopen/download surfaces preserve the exact allowlisted handoff context."
  - "The Timeline carry link is rendered inside the existing export-enabled branch so denied export auth hides it with CSV/JSON/NDJSON and background queue controls."
  - "STATE.md and ROADMAP.md were intentionally not updated because the execution request explicitly excluded those files."

patterns-established:
  - "Timeline-to-Exports context: FilterParams.filters_raw_from_params/1 -> FilterParams.parse/1 -> Query.validate_timeline_filters!/1 -> canonical query map."
  - "Exports LiveView context queueing mirrors Timeline background export adapter behavior without adding routes, formats, schemas, migrations, or dependencies."

requirements-completed: [POLISH-FLOWS]

duration: 4min
completed: 2026-06-04
---

# Phase 140 Plan 03: Timeline-to-Exports Handoff Summary

**Timeline filters now carry into Exports as a visible, allowlisted, queueable EF3 handoff context without weakening export auth.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-04T15:47:20Z
- **Completed:** 2026-06-04T15:51:18Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a `Carry to Exports` Timeline affordance with `data-earned-flow="EF3"`, `data-persona="P3"`, and `data-jtbd="J6"`.
- Added an Exports Timeline context banner that displays canonical allowed filter pairs before queue/download work.
- Added queueing from carried Timeline context into actor-owned `ExportJob` rows, using the existing queue adapter and error handling path.
- Preserved unknown-param dropping, invalid-filter rejection, export-auth hiding, and direct CSV/JSON/NDJSON controller guard behavior.

## Task Commits

1. **Task 1: Add Timeline carry-forward contracts** - `b014a18` (test)
2. **Task 2: Implement Timeline export context handoff** - `e4d84d6` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` - Adds the EF3 carry link beside existing Timeline export controls.
- `lib/threadline/operator_surface/live/export_status_live.ex` - Parses, validates, displays, and queues carried Timeline export context.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - Covers carry link canonical params and export-auth hiding.
- `test/threadline/operator_surface/live/export_status_live_test.exs` - Covers banner rendering, unknown-param dropping, invalid context, and actor-owned queueing.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` - Extends direct export invalid-filter/auth regression coverage.
- `.planning/phases/140-earned-new-flows/140-03-SUMMARY.md` - Completion record.

## Decisions Made

- Persisted carried context as canonical string params instead of parsed DateTime structs so the export monitor and reopen links preserve the Timeline URL handoff exactly.
- Rendered the carry link only inside the existing export-enabled branch, keeping denied export auth behavior aligned with the direct export controls.
- Skipped `.planning/STATE.md` and `.planning/ROADMAP.md` updates because the execution prompt explicitly forbade modifying them.

## Deviations from Plan

None - plan executed within the requested scope.

## Issues Encountered

None.

## Verification

- RED gate: `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs` failed with 4 expected new-contract failures before implementation.
- GREEN gate: same command passed after implementation and formatting: 64 tests, 0 failures.
- Source check: `rg -n "Carry to Exports|timeline_export_context|FilterParams|data-earned-flow=\"EF3\"" lib/threadline/operator_surface/live/timeline_live.ex lib/threadline/operator_surface/live/export_status_live.ex` found the expected Timeline and Exports hooks.
- Guard check: `rg -n "subject_ref_json" lib/threadline/operator_surface/live/export_status_live.ex` returned no matches.

## Known Stubs

None.

## Threat Flags

None beyond the planned trust boundaries. The new LiveView handoff uses existing `FilterParams`, `Query.validate_timeline_filters!/1`, `ExportJob`, actor ownership, and queue adapter paths; direct HTTP exports remain under `ExportAuthPlug`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 04 can build Evidence-specific context independently; this plan did not introduce Evidence proof params, formats, schemas, migrations, dependencies, or broad flow changes.

## Self-Check: PASSED

- Found `.planning/phases/140-earned-new-flows/140-03-SUMMARY.md`.
- Found task commits `b014a18` and `e4d84d6`.
- Confirmed expected source hooks with `rg`.
- Confirmed `subject_ref_json` is absent from `ExportStatusLive`.

---
*Phase: 140-earned-new-flows*
*Completed: 2026-06-04*
