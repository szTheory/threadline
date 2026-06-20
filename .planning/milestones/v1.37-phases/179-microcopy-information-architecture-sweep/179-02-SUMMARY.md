---
phase: 179-microcopy-information-architecture-sweep
plan: 02
subsystem: ui
tags: [microcopy, state-copy, accessibility, phoenix-liveview, operator-surface]

requires:
  - phase: 179-microcopy-information-architecture-sweep
    provides: Guard-first shell/Home copy contracts and route-stable IA relabeling from 179-01
provides:
  - Sentence-case shared state templates for data, stale, validation, and unsupported states
  - Focusable validation summaries with links to invalid fields
  - Distinct permission, unavailable, redacted, pruned, no-data, stale, and generic error copy
  - Full-value copy-affordance contract preservation for `UI.ref/1`
affects: [operator-surface, phase-179, copy, accessibility, shared-ui-helpers]

tech-stack:
  added: []
  patterns:
    - Guard-first TDD for shared microcopy helpers
    - Controlled state templates in existing private function components
    - Severity-based ARIA roles for shared state surfaces

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/unsupported.ex
    - lib/threadline/operator_surface/components/unsupported_view.ex
    - test/threadline/operator_surface/ui_test.exs
    - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/component_contract_test.exs
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs

key-decisions:
  - "Shared state grammar stayed inside existing UI, Unsupported, UnsupportedView, and Presentation-adjacent helper contracts; no copy registry, dependency, LiveComponent, route, or capability was added."
  - "Validation summaries now focus the summary container and link messages to invalid field ids, keeping the existing `{field_id, message}` assign shape."
  - "Unsupported and export-denied states render as alert-level unavailable/permission states while full forensic copy targets remain bound to exact values."

patterns-established:
  - "State copy states what happened, names the audit object, and gives the operator a next action."
  - "Unavailable/redacted/pruned copy explicitly says it is not a permissions issue; export denial copy remains distinct permission copy."

requirements-completed: [COPY-01, COPY-02, COPY-03]

duration: 8m 9s
completed: 2026-06-19
status: complete
---

# Phase 179 Plan 02: Shared State Copy Templates Summary

**Shared operator-state copy templates with focusable validation summaries and sentence-case unsupported descriptors**

## Performance

- **Duration:** 8m 9s
- **Started:** 2026-06-19T15:56:16Z
- **Completed:** 2026-06-19T16:04:25Z
- **Tasks:** 1 TDD task
- **Files modified:** 12

## Accomplishments

- Normalized `UI.data_state/1`, `UI.stale_banner/1`, `UI.error_summary/1`, `Unsupported.descriptor/1`, `Unsupported.export_denied_descriptor/1`, and `UnsupportedView.unsupported_view/1` to Phase 179 copy templates.
- Added validation-summary focus behavior and changed error-summary links to target invalid fields directly.
- Preserved `UI.ref/1` full-value `data-tl-copy` behavior and expanded copy-contract coverage around unsupported descriptors and status-label fallback.
- Updated directly affected LiveView assertions for Coverage, Evidence, Exports, Redaction, and Retention unsupported states.

## Task Commits

TDD commits for the single task:

1. **Task 1 RED: Normalize shared state and unsupported templates** - `76aa345` (test)
2. **Task 1 GREEN: Normalize shared state and unsupported templates** - `b52ee04` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/ui.ex` - Sentence-case data-state, stale, empty, generic error, and focusable validation-summary behavior.
- `lib/threadline/operator_surface/unsupported.ex` - Sentence-case unavailable/export-denied descriptor copy.
- `lib/threadline/operator_surface/components/unsupported_view.ex` - Alert semantics and sentence-case default unsupported view copy.
- `test/threadline/operator_surface/ui_test.exs` - State template, stale banner, validation-summary, and full-copy target assertions.
- `test/threadline/operator_surface/data_state_mapping_wave0_test.exs` - Updated data-state mapping expectations.
- `test/threadline/operator_surface/copy_contract_test.exs` - Unsupported descriptor and status-label contract coverage.
- `test/threadline/operator_surface/component_contract_test.exs` - Component contract assertions aligned with new shared templates.
- `test/threadline/operator_surface/live/coverage_live_test.exs` - Coverage unsupported copy expectations.
- `test/threadline/operator_surface/live/evidence_live_test.exs` - Evidence unsupported copy expectations.
- `test/threadline/operator_surface/live/export_status_live_test.exs` - Export permission-copy expectations.
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` - Redaction unsupported copy expectations.
- `test/threadline/operator_surface/live/retention_history_live_test.exs` - Retention unsupported copy expectations.

## Decisions Made

- Added an optional `object_label` to `UI.stale_banner/1` with a default of `audit data`, preserving existing call sites while allowing object-specific stale copy.
- Kept `UI.error_summary/1` assign shape unchanged; `{field_id, message}` now links to `#{field_id}` instead of `#{field_id}-error`.
- Treated unsupported/unavailable and export-denied surfaces as `role="alert"` because they require operator attention and are distinct from routine empty/status states.

## Verification

- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/data_state_mapping_wave0_test.exs` - RED before implementation: 75 tests, 9 expected failures.
- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/data_state_mapping_wave0_test.exs` - PASS after implementation: 75 tests, 0 failures.
- `mix test test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs` - PASS, 83 tests.
- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/live` - PASS, 135 tests.
- Acceptance source checks confirmed required state templates, alert/status roles, validation-summary focus attributes, field links, unsupported descriptors, and exact `data-tl-copy` bindings.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first affected LiveView/component sweep found three stale component-contract assertions for old generic state copy. They were updated to the new shared grammar and the suite passed.
- `mix ci.all` was not run for this plan; Phase 179 validation carries it as the before-verify-work gate, and 179-01 already recorded unrelated full-suite issues in `deferred-items.md`.

## Known Stubs

None. Stub-pattern scan hits were existing test fixtures, test-local empty assigns, and literal field names such as `mask placeholder`; no runtime stub blocks this plan's goal.

## Threat Flags

None. This plan changed rendered copy, ARIA roles, focus targets, and tests only; it introduced no new endpoint, auth path, file access pattern, schema change, dependency, or trust boundary.

## Authentication Gates

None.

## TDD Gate Compliance

- RED commit present before implementation: `76aa345`.
- GREEN commit present after RED: `b52ee04`.
- REFACTOR commit not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 179-03. Shared state helpers now carry the controlled grammar that page-specific actor, transaction, row-history, and coverage copy can build on.

## Self-Check: PASSED

- Verified summary path exists: `.planning/phases/179-microcopy-information-architecture-sweep/179-02-SUMMARY.md`.
- Verified task commits exist in git history: `76aa345`, `b52ee04`.
- Verified modified runtime files exist: `ui.ex`, `unsupported.ex`, `unsupported_view.ex`.
- Verified plan-local and carried-forward LiveView copy suites pass.

---
*Phase: 179-microcopy-information-architecture-sweep*
*Completed: 2026-06-19*
