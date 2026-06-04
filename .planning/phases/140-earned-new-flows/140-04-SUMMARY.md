---
phase: 140-earned-new-flows
plan: "04"
subsystem: operator-surface
tags: [phoenix-liveview, evidence, exports, proof-context, earned-flows]

requires:
  - phase: 140-earned-new-flows
    provides: "Plan 03 Timeline export context behavior in ExportStatusLive"
provides:
  - "EF3 Evidence proof-context carry-to-Exports affordance with P3/J6 trace attributes"
  - "Exports Evidence proof-context banner with validated subject, mode, and subject_ref_json"
  - "Evidence proof params kept separate from Timeline FilterParams and file export links"
  - "Regression coverage for malformed Evidence proof context and export authorization gating"
affects: [operator-surface, exports, evidence, earned-flows]

tech-stack:
  added: []
  patterns:
    - "Evidence carry URLs are built from an explicit source/subject/subject_ref_json/mode allowlist."
    - "ExportStatusLive keeps Evidence proof context in evidence_export_context, separate from timeline_export_context and FilterParams."

key-files:
  created:
    - ".planning/phases/140-earned-new-flows/140-04-SUMMARY.md"
  modified:
    - "lib/threadline/operator_surface/live/evidence_live.ex"
    - "lib/threadline/operator_surface/live/export_status_live.ex"
    - "test/threadline/operator_surface/live/evidence_live_test.exs"
    - "test/threadline/operator_surface/live/export_status_live_test.exs"

key-decisions:
  - "Evidence proof context is display/reopen context in Exports, not a Timeline export job or file filter input."
  - "The Evidence carry control is hidden behind both Evidence rendering and the existing Exports authorization flag."
  - "STATE.md and ROADMAP.md were intentionally not updated because the execution request explicitly excluded those files."

patterns-established:
  - "Evidence-to-Exports context: source=evidence -> explicit allowlist -> Evidence.Subject validation -> JSON object decode -> Evidence-shaped request validation."
  - "Evidence proof-context invalid input renders a visible banner error and never creates ExportJob rows."

requirements-completed: [POLISH-FLOWS]

duration: 7min
completed: 2026-06-04
---

# Phase 140 Plan 04: Evidence-to-Exports Handoff Summary

**Evidence proof/history context now carries into Exports as validated proof context without becoming Timeline export filters.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-04T15:52:00Z
- **Completed:** 2026-06-04T15:59:01Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a `Carry to Exports` Evidence affordance with `data-earned-flow="EF3"`, `data-persona="P3"`, and `data-jtbd="J6"`.
- Added an Exports Evidence proof-context banner with explicit subject, mode, subject ref, invalid-input errors, and a link back to Evidence.
- Kept Evidence-only params out of `FilterParams`, Timeline queue controls, and direct Timeline file export links.
- Added focused tests for proof-context allowlisting, malformed JSON/mode/subject input, auth gating, and Plan 03 Timeline context separation.

## Task Commits

1. **Task 1: Add Evidence proof-context handoff contracts** - `002ead7` (test)
2. **Task 2: Implement Evidence proof-context banner in Exports** - `b56c065` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/live/evidence_live.ex` - Builds the Evidence carry URL from parsed assigns and hides it when Exports is unauthorized.
- `lib/threadline/operator_surface/live/export_status_live.ex` - Parses and renders Evidence proof context separately from Timeline export context.
- `test/threadline/operator_surface/live/evidence_live_test.exs` - Covers Evidence carry links, allowed params, and export auth gating.
- `test/threadline/operator_surface/live/export_status_live_test.exs` - Covers Evidence context parsing, invalid input, no job creation, and no file-filter passthrough.
- `.planning/phases/140-earned-new-flows/140-04-SUMMARY.md` - Completion record.

## Decisions Made

- Evidence proof context is a handoff/reopen aid in Exports; it does not queue an `ExportJob` and does not imply a new Evidence export format.
- `source=evidence` disables Timeline context parsing for the request, so Evidence-only params cannot be silently interpreted as `FilterParams`.
- Summary-only planning metadata was committed for this plan; `.planning/STATE.md` and `.planning/ROADMAP.md` were left untouched per execution scope.

## Deviations from Plan

None - plan executed within the requested scope.

## Issues Encountered

- One RED test initially asserted the whole Evidence page lacked `subject_ref_json`; existing row-level proof-history links legitimately include that param. The assertion was narrowed to the Carry-to-Exports href before the GREEN commit.

## Verification

- RED gate: `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` failed with 4 expected new-contract failures before implementation.
- GREEN gate: `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` passed: 26 tests, 0 failures.
- Source check: `rg -n "source=evidence|evidence_export_context|data-earned-flow=\"EF3\"" lib/threadline/operator_surface/live/evidence_live.ex lib/threadline/operator_surface/live/export_status_live.ex` found the expected Evidence and Exports hooks.
- Guard check: `rg -n "subject_ref_json.*changes\\.(csv|json|ndjson)|changes\\.(csv|json|ndjson).*subject_ref_json" lib/threadline/operator_surface/live/export_status_live.ex lib/threadline/operator_surface/live/evidence_live.ex` returned no matches.

## Known Stubs

None.

## Threat Flags

None beyond the planned trust boundaries. The new surface accepts only `source`, `subject`, `subject_ref_json`, and `mode`; validates the Evidence subject inventory, JSON object shape, and mode; and does not persist or queue Evidence proof params.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05 can build on the closed EF3 handoff knowing Timeline and Evidence context are separate inside Exports. No new dependencies, migrations, routes, schemas, or file formats were introduced.

## Self-Check: PASSED

- Found `.planning/phases/140-earned-new-flows/140-04-SUMMARY.md`.
- Found task commits `002ead7` and `b56c065`.
- Confirmed expected source hooks with `rg`.
- Confirmed Evidence proof params are absent from direct Timeline file export links.

---
*Phase: 140-earned-new-flows*
*Completed: 2026-06-04*
