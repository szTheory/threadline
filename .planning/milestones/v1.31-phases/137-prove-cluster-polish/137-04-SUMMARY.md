---
phase: 137-prove-cluster-polish
plan: 04
subsystem: ui
tags: [operator-surface, evidence, redaction, prove-cluster]
requires:
  - phase: 137-prove-cluster-polish
    provides: Plan 01 secondary ref primitive and shared presentation helpers
provides:
  - Status-led Evidence cards
  - Presentation-only failed export evidence labeling
  - Redaction assurance framing
affects: [evidence, policy-redaction, prove-cluster]
tech-stack:
  added: []
  patterns: [presentation-only proof labeling, assurance-framed grouped sections]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/evidence_live.ex
    - lib/threadline/operator_surface/live/policy_redaction_live.ex
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
key-decisions:
  - "Failed export evidence is labeled in EvidenceLive presentation only; Proof semantics remain untouched."
  - "Evidence card actions place Open proof history before support navigation."
  - "Redaction keeps presenter-driven grouped sections/details/remediation links while adopting assurance framing."
patterns-established:
  - "Evidence row builders can add display-only labels without changing proof vocabulary."
  - "Redaction remains the grouped assurance baseline for the Prove cluster."
requirements-completed: [POLISH-PROVE]
duration: 2min
completed: 2026-06-04
---

# Phase 137: Plan 04 Summary

**Evidence cards now lead with proof verdicts and history navigation while Redaction keeps the assurance baseline.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-04T07:38:04Z
- **Completed:** 2026-06-04T07:40:34Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Reordered Evidence cards so the verdict owner and display label lead before secondary mono subject refs and recorded time.
- Moved `Open proof history` before subject/support navigation in card actions.
- Added presentation-only `Failed export evidence` labeling for failed `export_delivery` records.
- Updated Policy Redaction to `Redaction assurance` framing while keeping presenter-driven section order, `details`, and remediation links.

## Task Commits

1. **Task 1: Reorder Evidence around proof verdicts and preserve Redaction as the assurance baseline** - `e123009` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/live/evidence_live.ex` - Status-led card order, secondary refs, action order, failed export display label.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` - Assurance title and diagnostic success copy.
- `test/threadline/operator_surface/live/evidence_live_test.exs` - Evidence hierarchy, failed export label, and action-order coverage.
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` - Assurance framing coverage with existing section/remediation assertions.

## Decisions Made

Kept `Threadline.Evidence.Proof` and `Threadline.Policy.RedactionPresenter` unchanged. All changes are LiveView presentation and test coverage.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The first action-order assertion compared against the global trust-rail `Open exports` link. The test was corrected to compare against the card-level support action occurrence.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs` - 9 tests, 0 failures
- `rg -n "Open proof history|Failed export evidence|Evidence of failed export|Redaction assurance" lib/threadline/operator_surface/live/evidence_live.ex lib/threadline/operator_surface/live/policy_redaction_live.ex` - passed

## Self-Check: PASSED

- Key files exist on disk.
- Commit `e123009` contains the implementation and tests.
- `lib/threadline/evidence/proof.ex` was not modified.

## Next Phase Readiness

All Phase 137 plans have summaries and are ready for post-wave and phase-level verification.

---
*Phase: 137-prove-cluster-polish*
*Completed: 2026-06-04*
