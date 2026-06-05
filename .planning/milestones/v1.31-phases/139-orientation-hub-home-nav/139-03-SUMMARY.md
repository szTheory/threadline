---
phase: 139-orientation-hub-home-nav
plan: "03"
subsystem: testing
tags: [playwright, e2e, mobile, operator-surface, navigation]

requires:
  - phase: 139-orientation-hub-home-nav
    plan: "01"
    provides: "Grouped SurfaceHeader IA, data-testid nav links, and mobile scroll-container ownership"
  - phase: 139-orientation-hub-home-nav
    plan: "02"
    provides: "Home orientation hub, health row, and saved-view resume content"
provides:
  - "Focused 375px browser UAT for Home orientation and saved-view resume"
  - "375px header reachability proof across representative operator screens"
  - "Home-origin click proof for every enabled header destination"
affects: [phase-139-verification, phase-142-boundary, operator-surface-e2e]

tech-stack:
  added: []
  patterns:
    - "Playwright mobile UAT uses local login and no-overflow helpers copied from existing specs"
    - "Header reachability treats .tl-topbar__nav as the intentional horizontal scroll container"

key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts
    - .planning/phases/139-orientation-hub-home-nav/139-03-SUMMARY.md
  modified: []

key-decisions:
  - "Kept the browser proof scoped to Home/nav orientation and avoided Phase 142 table, drawer, filter, and screenshot assertions."
  - "Asserted root document overflow only; .tl-topbar__nav remains the intentional horizontal scroll container."

patterns-established:
  - "Destination reachability is checked by scrolling operator-nav-* links into view and asserting their exact hrefs."
  - "Home nav activation is proven by clicking each enabled header destination from /audit and returning to Home between clicks."

requirements-completed: [POLISH-HOME]

duration: 4min
completed: 2026-06-04
---

# Phase 139 Plan 03: Mobile Home/Nav Browser UAT Summary

**Focused Playwright proof that 375px Home orientation and grouped header navigation are reachable without document-level horizontal overflow.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-04T14:50:31Z
- **Completed:** 2026-06-04T14:54:09Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `operator-home-nav-mobile.spec.ts` with Home headline, Find/Verify/Prove cards/actions, health row, saved-view resume, and no-form assertions.
- Added reachability checks for Timeline, Coverage, Evidence, Redaction, Retention, and Exports from `/audit`, `/audit/timeline`, `/audit/coverage`, `/audit/evidence`, `/audit/policy/redaction`, `/audit/policy/retention`, and `/audit/exports`.
- Added Home-origin click coverage for every enabled header destination, returning to `/audit` between clicks.
- Verified root document horizontal overflow after Home and every representative screen while leaving `.tl-topbar__nav` as the intentional scroll container.

## Task Commits

1. **Task 1: Add Home orientation mobile UAT** - `40168fa` (test)
2. **Task 2: Add 375px nav reachability across representative screens** - `92d66b9` (test)

**Plan metadata:** recorded in the final docs commit for this summary.

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` - Focused Playwright mobile UAT for Home orientation and header nav reachability.
- `.planning/phases/139-orientation-hub-home-nav/139-03-SUMMARY.md` - Execution summary.

## Decisions Made

- Reused local e2e helper patterns instead of introducing shared helper churn.
- Used exact role/text assertions where health links share destination words with Home action links.
- Did not use screenshot baselines, table stacking assertions, filter drawer checks, or broader responsive matrix coverage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Tightened ambiguous Home text selectors**
- **Found during:** Task 1 (Add Home orientation mobile UAT)
- **Issue:** `getByText("Prove")` matched both the Prove card kicker and the `Prove and export` heading.
- **Fix:** Switched Find/Verify/Prove label checks to exact text matching.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts`
- **Verification:** Re-ran the focused Playwright spec; the next failure moved to a separate ambiguous Exports action selector.
- **Committed in:** `40168fa`

**2. [Rule 1 - Bug] Tightened ambiguous Exports action selector**
- **Found during:** Task 1 (Add Home orientation mobile UAT)
- **Issue:** The Home health row can include an Exports link, so `getByRole("link", { name: "Exports" })` matched both health and action links.
- **Fix:** Switched Home action link assertions to exact accessible names.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts`
- **Verification:** `E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` passed before the Task 1 commit.
- **Committed in:** `40168fa`

---

**Total deviations:** 2 auto-fixed (2 bugs).
**Impact on plan:** Both fixes corrected selector precision in the planned browser UAT. No app code, dependencies, screenshots, or Phase 142 scope were added.

## Issues Encountered

- The example app was not already running on `http://127.0.0.1:4002`. The test database was created/migrated/seeded manually and `MIX_ENV=test PORT=4002 THREADLINE_E2E=1 mix phx.server` was started without invoking the e2e helper script's `git clean` path.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None found in created or modified files.

## Threat Flags

None. No new endpoints, routes, schemas, auth paths, file access patterns, or trust-boundary behavior were introduced.

## Verification Evidence

- Example app availability: `curl --max-time 1 -fsS http://127.0.0.1:4002/users/log_in` - PASS.
- Required browser verification: `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` - PASS, 9 tests, 0 failures.
- Stub scan: `rg -n "TODO|FIXME|placeholder|coming soon|not available|=\\[\\]|=\\{\\}|=null|=\\"\\"" examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` - PASS, no matches.

## Next Phase Readiness

Phase 139 now has browser proof for the Home/nav orientation slice. Phase 142 remains responsible for the broader responsive sweep, including table stacking, filter drawer behavior, and screenshot or matrix-style coverage.

## Self-Check: PASSED

- Created e2e spec exists: `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts`.
- Created summary exists: `.planning/phases/139-orientation-hub-home-nav/139-03-SUMMARY.md`.
- Task commits found in git log: `40168fa`, `92d66b9`.
- Example app availability confirmed at `http://127.0.0.1:4002/users/log_in`.
- Required browser verification passed after both task commits.

---
*Phase: 139-orientation-hub-home-nav*
*Completed: 2026-06-04*
