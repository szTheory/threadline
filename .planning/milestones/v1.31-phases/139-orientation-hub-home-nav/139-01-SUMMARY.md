---
phase: 139-orientation-hub-home-nav
plan: "01"
subsystem: ui
tags: [phoenix-liveview, operator-surface, navigation, css-contracts]

requires:
  - phase: 136-design-system-hardening
    provides: dark-only scoped token primitives
  - phase: 137-prove-cluster-polish
    provides: Prove cluster handoff language and ordering
  - phase: 138-find-cluster-polish
    provides: mobile operator-surface reachability patterns
provides:
  - Feature-flag-aware SurfaceHeader IA contracts for Find, Verify, and Prove
  - Exports handoff styling primitive for the Prove cluster
  - Mobile-reachable grouped nav labels in the base topbar CSS
affects: [phase-139-home, phase-139-mobile-uat, operator-surface-header]

tech-stack:
  added: []
  patterns:
    - Phoenix component contracts via render_component/2
    - Scoped .tl-* CSS contract tests

key-files:
  created:
    - test/threadline/operator_surface/surface_header_test.exs
    - .planning/phases/139-orientation-hub-home-nav/139-01-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "Exports remains a normal feature-flagged nav link, but is wrapped with tl-topbar__nav-handoff so it reads as the Prove deliverable destination."
  - "Mobile base CSS keeps Find / Verify / Prove labels visible inside the existing scrollable topbar nav instead of adding JS or a disclosure menu."

patterns-established:
  - "SurfaceHeader active-state contracts assert exactly one aria-current page for destination atoms and none for :start."
  - "Phase-specific topbar CSS is guarded by string contracts for token usage and dependency/theme drift."

requirements-completed: [POLISH-HOME]

duration: 2h19m
completed: 2026-06-04
---

# Phase 139 Plan 01: Surface Header IA Summary

**Shared operator SurfaceHeader now locks Find / Verify / Prove orientation, Prove Exports handoff semantics, and mobile-reachable grouped nav labels.**

## Performance

- **Duration:** 2h19m
- **Started:** 2026-06-04T12:20:40Z
- **Completed:** 2026-06-04T14:39:20Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added direct `render_component/2` contracts for header grouping, feature flags, preserved Home/skip/scope/coverage affordances, and current-page active states.
- Marked Exports as the Prove handoff destination with `tl-topbar__nav-handoff` while preserving the existing `nav_link/1` architecture and feature flag gate.
- Updated the base topbar CSS so group labels are visible in the mobile scrollable nav, with token-backed handoff separation and style contracts.

## Task Commits

1. **Task 1: Add SurfaceHeader IA contracts** - `d2cc5d9` (test)
2. **Task 2: Implement grouped nav handoff and mobile reachability primitives** - `84d7576` (feat)

**Plan metadata:** recorded in the final docs commit for this summary

## Files Created/Modified

- `test/threadline/operator_surface/surface_header_test.exs` - Component contracts for IA labels, active states, feature flags, and preserved header affordances.
- `lib/threadline/operator_surface/components/surface_header.ex` - Exports link wrapped in `tl-topbar__nav-handoff`.
- `lib/threadline/operator_surface/style.ex` - Mobile-visible nav labels and token-backed handoff separator.
- `test/threadline/operator_surface/style_contract_test.exs` - Phase 139 topbar selector, token, and prohibited-pattern contracts.
- `.planning/phases/139-orientation-hub-home-nav/139-01-SUMMARY.md` - Execution summary.

## Decisions Made

- Exports was separated with a wrapper class instead of changing the private `nav_link/1` API, keeping existing link attributes, `aria-current`, and test IDs intact.
- The existing scrollable grouped topbar remains the mobile pattern for 375px reachability; no JS behavior, routes, dependencies, or disclosure state were added.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed RED test helper argument order**
- **Found during:** Task 1 (Add SurfaceHeader IA contracts)
- **Issue:** The first RED run exposed `Regex.scan/3` arguments reversed in the new `aria_current_count/1` helper, which made active-state tests fail before reaching the planned implementation gap.
- **Fix:** Corrected the helper to call `Regex.scan(regex, html)`.
- **Files modified:** `test/threadline/operator_surface/surface_header_test.exs`
- **Verification:** `mix test test/threadline/operator_surface/surface_header_test.exs` then failed only on the intended missing `tl-topbar__nav-handoff` assertion.
- **Committed in:** `d2cc5d9`

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The fix kept the RED gate meaningful and did not change scope.

## Issues Encountered

None beyond the auto-fixed RED helper issue documented above.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None found in created or modified files.

## Verification

- `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/style_contract_test.exs` - PASS, 11 tests, 0 failures.
- `rg -n "tl-topbar__nav-handoff|aria-current|operator-nav-exports" lib/threadline/operator_surface/components/surface_header.ex lib/threadline/operator_surface/style.ex test/threadline/operator_surface/surface_header_test.exs` - PASS, expected component, CSS, and test references found.
- `rg -n "@tailwind|from shadcn|prefers-color-scheme|color-scheme: light" lib/threadline/operator_surface/style.ex` - PASS, no matches.

## Self-Check: PASSED

- Created summary file exists: `.planning/phases/139-orientation-hub-home-nav/139-01-SUMMARY.md`.
- Task commits exist in git log: `d2cc5d9`, `84d7576`.
- Required focused verification passed after both task commits.

## Next Phase Readiness

Plan 139-02 can consume the locked header IA: Home remains the brand link, `:start` has no active nav item, destinations remain feature-flagged, and Exports now has a stable Prove handoff primitive for Home copy and mobile UAT.

---
*Phase: 139-orientation-hub-home-nav*
*Completed: 2026-06-04*
