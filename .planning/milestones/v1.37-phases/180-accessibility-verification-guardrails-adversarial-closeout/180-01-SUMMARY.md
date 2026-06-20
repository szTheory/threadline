---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
plan: 01
subsystem: ui
tags: [accessibility, playwright, phoenix-live-view, operator-surface, focus-management]

requires:
  - phase: 179-microcopy-information-architecture-sweep
    provides: Operator copy and IA baseline verified before accessibility closeout.
provides:
  - Rendered A11Y-01 browser coverage for opened operator states.
  - Shared modal/drawer focus-entry and drawer description semantics.
  - Stress-route rendered fixtures for forms, menu, table/data panel, alert/status, modal, and drawer checks.
affects: [phase-180, accessibility-verification, operator-surface, stress-route]

tech-stack:
  added: []
  patterns:
    - Existing Playwright role/name/focus assertions for rendered accessibility evidence.
    - Existing Phoenix.LiveView.JS focus helpers for overlay entry and restoration.

key-files:
  created:
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-01-SUMMARY.md
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/deferred-items.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - lib/threadline/operator_surface/live/stress_live.ex

key-decisions:
  - "Use the existing Playwright operator accessibility spec for rendered-state A11Y-01 proof; no axe scan or new dependency was added."
  - "Use shared LiveView JS overlay helpers for focus entry/restoration where possible, with stress-route-only fixtures for missing rendered state coverage."
  - "Classify `mix precommit` demo seed failures as inherited/non-owned because they occur in demo contract and walkthrough tests untouched by Plan 180-01."

patterns-established:
  - "Rendered accessibility checks should assert role/name, visible focus, restored focus, and overflow from browser-visible state."
  - "Stress-route fixtures can cover missing design-system rendered states without expanding public routes or component APIs."

requirements-completed: [A11Y-01]

duration: 2h 58m
completed: 2026-06-20
status: complete
---

# Phase 180 Plan 01: A11Y-01 Rendered-State Coverage Summary

**Rendered operator accessibility coverage for opened dialogs, drawers, menus, disclosure, tabs, form controls, alerts, status regions, tables, shell nav, and mobile nav using the existing Playwright harness.**

## Performance

- **Duration:** 2h 58m
- **Started:** 2026-06-19T22:05:55Z
- **Completed:** 2026-06-20T01:04:05Z
- **Tasks:** 2
- **Files changed:** 6

## Accomplishments

- Tightened `operator-accessibility.spec.ts` to document every D-04 rendered-state category as covered or explicitly bounded.
- Added browser-visible assertions for accessible names, keyboard-opened state, visible non-obscured focus, focus restoration, and no horizontal overflow.
- Fixed shared overlay behavior so drawers expose stable descriptions and overlays can target a specific initial focus element.
- Updated retention prune modal behavior so opening the destructive confirmation moves focus into the confirm input and restores focus to the launcher.
- Extended the authenticated stress route with rendered search/combobox/error-summary/data-panel/menu/modal/drawer fixtures required by A11Y-01 without adding dependencies or routes.

## Task Commits

1. **Task 1: Tighten browser coverage for rendered A11Y-01 states** - `c0f2d88` (`test`)
2. **Task 2: Apply narrow rendered-state accessibility fixes** - `67420a1` (`fix`)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - Added D-04 coverage inventory and rendered-state assertions for focus, names, keyboard state, overflow, and stress fixtures.
- `lib/threadline/operator_surface/ui.ex` - Added drawer labelling/description attributes and `data-tl-initial-focus` support to modal/drawer show helpers.
- `lib/threadline/operator_surface/live/retention_history_live.ex` - Preserved destructive-action flow while adding focus push/restore and conditional modal mounting for focus entry.
- `lib/threadline/operator_surface/live/stress_live.ex` - Added rendered stress fixtures for form controls, error summary, data panel/table, dropdown menu items, and closable modal/drawer focus checks.
- `.planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/deferred-items.md` - Captured inherited `mix precommit` failures outside this plan.
- `.planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-01-SUMMARY.md` - Execution summary.

## Verification

- `mix compile --warnings-as-errors` - passed.
- `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/stress_router_test.exs` - passed, 102 tests, 0 failures.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` - passed, 21 tests, 0 failures.
- `THREADLINE_E2E_THEME=system ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` - passed, 7 tests, 0 failures.
- RED evidence after Task 1: the default browser run failed before source fixes, including retention modal focus entry, mobile shell navigation state, row-history drawer focus, and stress rendered-state gaps.

## Decisions Made

- Kept A11Y-01 evidence in the existing Playwright file and existing Phoenix/ExUnit harnesses, matching the plan's no-new-framework constraint.
- Used the authenticated stress route for fixture coverage where the current operator flows did not naturally render every D-04 category in one stable browser path.
- Closed stress overlays through existing `UI.hide_modal/2` and `UI.hide_drawer/2` helpers from focused buttons so the rendered test proves keyboard close plus focus restoration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Retention prune modal did not move focus into the opened dialog**
- **Found during:** Task 2
- **Issue:** The modal was already mounted while hidden, so `phx-mounted` focus commands did not rerun when `show` flipped true.
- **Fix:** Mount the retention modal only while open, add `data-tl-initial-focus` to the confirm input, and push focus from destructive-action launchers.
- **Files modified:** `lib/threadline/operator_surface/live/retention_history_live.ex`
- **Verification:** Required browser runs pass in default and system lanes.
- **Committed in:** `67420a1`

**2. [Rule 2 - Missing Critical] Stress route lacked rendered fixtures for several D-04 accessibility states**
- **Found during:** Task 2
- **Issue:** The existing stress matrix did not expose enough rendered combobox/search/error-summary/table/menu/modal/drawer state for A11Y-01 browser proof.
- **Fix:** Added fixture-only controls, data panel/table, menu items, and labelled/described modal/drawer content without adding routes or dependencies.
- **Files modified:** `lib/threadline/operator_surface/live/stress_live.ex`
- **Verification:** Required browser runs pass in default and system lanes.
- **Committed in:** `67420a1`

**3. [Rule 1 - Bug] Shared drawer semantics lacked a stable description hook**
- **Found during:** Task 2
- **Issue:** Shared drawer wrapper had modal role/state but no stable `aria-describedby` contract for rendered drawer descriptions.
- **Fix:** Added `aria-labelledby`/`aria-describedby` matching the existing `#{id}-title` and `#{id}-description` overlay convention.
- **Files modified:** `lib/threadline/operator_surface/ui.ex`
- **Verification:** Focused ExUnit and required browser runs passed.
- **Committed in:** `67420a1`

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical coverage fixture)
**Impact on plan:** All fixes were required to make the planned rendered-state assertions true; no dependencies, public route changes, public component API changes, or stress-route auth changes were introduced.

## Issues Encountered

- `mix precommit` from `examples/threadline_phoenix` failed after plan-owned verification passed: 95 tests ran, 7 failed in demo seed/walkthrough tests unrelated to the changed accessibility files. Evidence is recorded in `deferred-items.md`. This was classified as inherited/non-owned because Plan 180-01 did not touch demo seed data, walkthrough tests, audit capture, or seed contract logic.

## Known Stubs

- `lib/threadline/operator_surface/live/stress_live.ex:270` - `UI.avatar src=""` is a pre-existing stress fixture that intentionally exercises avatar fallback rendering; it does not block A11Y-01.
- `lib/threadline/operator_surface/ui.ex:1439` - `placeholder` appears in the component's allowed global attribute list, not as placeholder UI copy or unwired data.

## Auth Gates

None.

## Threat Notes

No new network endpoint, public route, authorization path, file access path, or schema trust boundary was introduced. The existing authenticated stress route and fail-closed stress-router behavior were preserved.

## Next Phase Readiness

Plan 180-02 can use the rendered coverage baseline to focus on APG semantics, non-color cues, and touch target checks. Phase 180-04 still owns final closeout evidence and inherited failure classification across the full milestone.

## Self-Check: PASSED

- Verified summary, deferred-items file, and all modified task files exist.
- Verified task commits `c0f2d88` and `67420a1` exist in git history.
- Verified only expected planning docs plus the user-specified unrelated untracked files remain uncommitted before state updates.

---
*Phase: 180-accessibility-verification-guardrails-adversarial-closeout*
*Completed: 2026-06-20*
