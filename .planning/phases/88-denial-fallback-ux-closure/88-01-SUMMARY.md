---
phase: 88-denial-fallback-ux-closure
plan: "01"
subsystem: ui
tags: [phoenix-liveview, authorization, operator-surface, exports, testing]
requires:
  - phase: 87-canonical-mount-recipe-and-example-app-proof
    provides: canonical /audit mount and support-lane auth posture
provides:
  - shared unsupported-state descriptor contract for denied and unavailable operator surfaces
  - denied export route that stays aligned with hidden timeline affordances
  - explicit HTTP 403 export denial proof alongside LiveView denial proof
affects: [phase-89, docs, operator-surface, export-auth]
tech-stack:
  added: []
  patterns: [descriptor-driven unsupported views, exact-or-generic denial fallbacks]
key-files:
  created: [.planning/phases/88-denial-fallback-ux-closure/88-01-SUMMARY.md]
  modified:
    - lib/threadline/operator_surface/unsupported.ex
    - lib/threadline/operator_surface/components/unsupported_view.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - lib/threadline/operator_surface/live/policy_redaction_live.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
key-decisions:
  - "Moved unsupported and denied copy into a shared descriptor module instead of leaving literals embedded in each LiveView."
  - "Export denial emits an exact CLI fallback only for safely representable table/from/to state; actor-scoped and partial filters degrade to a generic hint."
patterns-established:
  - "Unsupported operator surfaces pass descriptor maps into UnsupportedView rather than title/body/fallback literals."
  - "Support-lane UI hiding is treated as convenience UX; direct HTTP exports remain guarded by explicit 403 assertions."
requirements-completed: [AUTH-01, UX-01]
duration: in-session
completed: 2026-05-25
---

# Phase 88: Denial / Fallback UX Closure Summary

**Descriptor-driven denial and unsupported operator screens now share one contract, while export denial stays truthful across LiveView affordances and HTTP enforcement.**

## Performance

- **Duration:** In-session continuation
- **Started:** 2026-05-25T05:00:00Z
- **Completed:** 2026-05-25T05:54:14Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Centralized unsupported and denied copy plus fallback metadata in `Threadline.OperatorSurface.Unsupported`.
- Rewired export, coverage, policy, and retention screens to use the shared descriptor contract instead of per-view literal drift.
- Added explicit proof that direct export requests can still return plain-text `403 forbidden` even while support-scoped timeline affordances stay hidden.

## Task Commits

No task commits were created in this run.

The worktree already contained in-progress edits across the same Phase 88 files, so creating atomic plan commits here would have mixed pre-existing user changes with this execution pass.

## Files Created/Modified

- `lib/threadline/operator_surface/unsupported.ex` - Shared denial/unavailability descriptors and export fallback derivation.
- `lib/threadline/operator_surface/components/unsupported_view.ex` - Descriptor-aware unsupported shell renderer.
- `lib/threadline/operator_surface/live/export_status_live.ex` - Denied export route now renders descriptor-driven exact-or-generic fallback guidance.
- `lib/threadline/operator_surface/live/coverage_live.ex` - Coverage denial route now renders a truthful unsupported state instead of redirecting away.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` - Policy route now uses the shared unsupported contract.
- `lib/threadline/operator_surface/live/retention_history_live.ex` - Retention route now uses the shared unsupported contract.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` - Added plain-text `403 forbidden` denial coverage.

## Decisions Made

- Used shell-escaped quoted arguments for exact fallback commands so the rendered CLI hints remain copy-paste safe.
- Required both `from` and `to` for an exact range-based denial fallback; partial ranges intentionally degrade to the generic export hint.

## Deviations from Plan

### Auto-fixed Issues

**1. Test expectation update for rendered CLI quoting**
- **Found during:** Verification
- **Issue:** LiveView escapes single quotes in rendered HTML, so exact-fallback assertions failed even though the output was correct.
- **Fix:** Updated the export denial test to assert the escaped HTML form.
- **Files modified:** `test/threadline/operator_surface/live/export_status_live_test.exs`
- **Verification:** Targeted operator-surface test slice passed.

---

**Total deviations:** 1 auto-fixed
**Impact on plan:** No scope change. The deviation only corrected verification to match the rendered output.

## Issues Encountered

- The Phase 88 worktree already contained related in-progress edits before execution started, so the implementation had to be reconciled with existing changes rather than built from a clean base.

## User Setup Required

None.

## Next Phase Readiness

- Phase 89 can now verify the denial/fallback contract against the shared descriptor API and the new HTTP denial proof.
- `.planning/STATE.md` was left untouched in this run because it already had unrelated in-progress edits.

---
*Phase: 88-denial-fallback-ux-closure*
*Completed: 2026-05-25*
