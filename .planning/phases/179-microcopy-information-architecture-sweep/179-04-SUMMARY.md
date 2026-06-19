---
phase: 179-microcopy-information-architecture-sweep
plan: 04
subsystem: ui
tags: [microcopy, information-architecture, phoenix-liveview, operator-surface, timeline, accessibility]

requires:
  - phase: 179-microcopy-information-architecture-sweep
    provides: "Phase 179 shared microcopy rules, prior shell/Home copy contracts, and investigation readiness terminology from 179-01 through 179-03"
provides:
  - "Dense Timeline workflow copy that keeps filters, results, investigation actions, and exports before explanatory guidance"
  - "Actionable Timeline invalid-filter and unknown-table messages that name the failed object and next action"
  - "ExUnit and Playwright coverage for URL-backed advanced filters, sentence-case workflow guidance, direct transaction/row-history flows, and accessible Timeline labels"
affects: [operator-surface, timeline, copy, accessibility, phase-179]

tech-stack:
  added: []
  patterns:
    - "Timeline explanatory copy stays below the working surface; tests assert DOM order rather than relying on visual position alone"
    - "Timeline filter errors identify the filter target before repeating the parser detail"

key-files:
  created:
    - .planning/phases/179-microcopy-information-architecture-sweep/179-04-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - .planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md

key-decisions:
  - "Kept Timeline power-user controls and links in place, demoting only the explanatory journey copy below filters, results, and export actions."
  - "Made invalid filter and unknown-table copy name the object that failed while preserving the underlying parser/audited-table detail."
  - "Updated the browser accessibility spec to current shell, retention modal, and seeded Timeline contracts instead of carrying stale assertions from older UI behavior."

patterns-established:
  - "Sentence-case Timeline workflow guidance replaces all-caps instructional labels."
  - "Plan-owned e2e assertions should discover row-history flows from currently seeded rows instead of fixed historical demo windows."

requirements-completed: [COPY-01, COPY-02, COPY-03]

duration: 25min
completed: 2026-06-19
status: complete
---

# Phase 179 Plan 04: Timeline Microcopy Summary

**Timeline investigation copy now keeps dense operator controls first while using actionable, sentence-case guidance for filters, unknown tables, transaction links, row history, and exports.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-06-19T19:41:00Z
- **Completed:** 2026-06-19T20:06:08Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Replaced the all-caps `FIND / EXPLAIN / PACKAGE` legend with the required sentence-case Timeline workflow line below the working surface.
- Updated invalid-filter and unknown-table messages to name the failed object and tell operators what to do next.
- Added/updated ExUnit assertions for dense DOM order, URL-backed advanced disclosure, invalid correlation-id copy, and unknown-table copy.
- Updated the operator accessibility Playwright spec to prove current Timeline labels, workflow copy, direct transaction/row-history paths, nav accessibility, and retention modal semantics.

## Task Commits

1. **Task 1 RED: Preserve dense Timeline workflow while reducing explanatory copy** - `d03f0c6` (`test`)
2. **Task 1 GREEN: Preserve dense Timeline workflow while reducing explanatory copy** - `34bd204` (`feat`)

_Note: Task 1 was a TDD task, so it intentionally has separate RED and GREEN commits._

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` - Timeline workflow line, actionable invalid-filter copy, and actionable unknown-table copy.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - Rendered copy contracts for invalid filters, unknown tables, DOM order, and no all-caps journey labels.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - Browser assertions for current Timeline labels, workflow line, nav shell accessibility, retention modal semantics, and seeded row-history discovery.
- `.planning/phases/179-microcopy-information-architecture-sweep/deferred-items.md` - Logged out-of-scope `mix ci.all` failures discovered during validation.

## Verification

- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs` - passed, `43 tests, 0 failures`.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` - passed, `12 passed`.
- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/live` - passed, `137 tests, 0 failures`.
- `mix ci.all` - failed on out-of-scope pre-existing project charter/demo seed/example assertions; details recorded in `deferred-items.md`.

## Decisions Made

- Kept the Timeline page dense: filters, active summary, result status, investigation checks, export actions, saved views, and rows remain before explanatory guidance.
- Used filter-target detection in `invalid_filter_message/1` so parser errors stay informative without making the operator infer which field needs correction.
- Kept unknown-table guidance local to Timeline and preserved the audited-table list when available.
- Adjusted plan-owned browser assertions to the current UI contracts for shell disclosure, retention confirmation modal, and seeded row-history discovery.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Refreshed stale browser assertions in the plan-owned accessibility spec**
- **Found during:** Task 1 GREEN verification.
- **Issue:** The plan-local Playwright command failed on stale assertions for the operator shell role, lowercase label names, the old retention `data-confirm` contract, and a fixed historical demo row-history URL that is empty in the current seed.
- **Fix:** Updated the browser spec to assert the current shell `aria-label`, sentence-case labels, real retention modal semantics, and row-history discovery through currently seeded `ticket_replies` Timeline rows.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`
- **Verification:** Full `operator-accessibility.spec.ts` e2e suite passed across `chromium`, `desktop-chromium`, and `mobile-chromium`.
- **Committed in:** `34bd204`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to make the plan-owned e2e verification assert the current Timeline accessibility surface. No new route, dependency, public API, LiveComponent, copy registry, filter, export flow, or Timeline capability was introduced.

## Issues Encountered

- `mix ci.all` still fails outside this plan on milestone charter wording and example demo seed/walkthrough/evidence assertions. These failures were already present in earlier Phase 179 summaries and remain unrelated to the Timeline files owned by 179-04.

## Known Stubs

None. Stub scan found only the existing saved-view input placeholder text (`Name this view...`), which is an intentional form placeholder, not a data-rendering stub.

## Threat Flags

None. This plan changed Timeline copy and tests only; it introduced no new network endpoint, auth path, file access pattern, schema boundary, dependency, or public API.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Timeline copy now satisfies COPY-01 through COPY-03 for dense investigation and can be used as the copy-density reference for the remaining Phase 179 plans. Remaining full-suite failures are tracked as deferred out-of-scope items, not blockers for Timeline copy completion.

## Self-Check: PASSED

- Verified summary file exists.
- Verified modified plan-owned files exist.
- Verified deferred-items tracking file exists.
- Verified task commits exist: `d03f0c6`, `34bd204`.

---
*Phase: 179-microcopy-information-architecture-sweep*
*Completed: 2026-06-19*
