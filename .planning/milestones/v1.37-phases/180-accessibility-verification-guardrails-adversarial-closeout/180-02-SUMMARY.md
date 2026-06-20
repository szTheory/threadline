---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
plan: 02
subsystem: ui
tags: [accessibility, wai-aria-apg, phoenix-live-view, operator-surface, style-contracts]

requires:
  - phase: 180-accessibility-verification-guardrails-adversarial-closeout
    provides: Plan 180-01 rendered-state accessibility baseline for opened operator widgets.
provides:
  - A11Y-02 APG semantics contracts for actual Threadline widgets.
  - Native/non-applicable mapping assertions for native select/input/table behavior.
  - Non-color and target-size style guardrails for shell, pager, tabs, segmented controls, theme picker, and buttons.
affects: [phase-180, accessibility-verification, operator-surface, component-contracts]

tech-stack:
  added: []
  patterns:
    - Existing ExUnit component/UI/style contracts for APG and non-color guardrails.
    - Existing Playwright operator accessibility spec for rendered widget verification.

key-files:
  created:
    - .planning/phases/180-accessibility-verification-guardrails-adversarial-closeout/180-02-SUMMARY.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/component_contract_test.exs
    - test/threadline/operator_surface/ui_test.exs
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "APG guardrails stay implementation-specific: custom widgets get specific ARIA popup/relationship hooks, while native select/input/table behavior is asserted instead of role-inflated."
  - "Tabs and segmented controls use actual rendered selectors for target sizing and non-color selected-state cues; stale selector rules are removed."
  - "No dependencies, audit frameworks, public routes, public component APIs, or stress-route auth behavior were added."

patterns-established:
  - "A11Y-02 source contracts should assert actual rendered selectors and native/non-applicable cases, not generic APG checklists."
  - "Compact operator controls can retain dense workflow sizing while preserving explicit 32px/40px hit-area contracts."

requirements-completed: [A11Y-02]
duration: 10m 27s
completed: 2026-06-20
status: complete
---

# Phase 180 Plan 02: APG Component Semantics And Non-Color Guardrails Summary

**A11Y-02 guardrails now verify actual Threadline widget semantics, native/non-applicable behavior, non-color cues, and dense-but-bounded control targets.**

## Performance

- **Duration:** 10m 27s
- **Started:** 2026-06-20T01:08:24Z
- **Completed:** 2026-06-20T01:18:51Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added APG-focused ExUnit and Playwright checks for custom widget semantics: dropdown/menu, popover, accordion, tabs, combobox, dialog/drawer, alert/status, and native table/form behavior.
- Tightened `UI.*` semantics with specific popup types, accordion region linkage, combobox listbox declaration, and roving-tabindex/panel-link hooks for tabs.
- Added A11Y-02 style contracts for target sizes and non-color selected-state cues, then mapped tab and segmented-control CSS to the actual rendered selectors.

## Task Commits

1. **Task 1 RED: Add implementation-specific APG checks** - `c9f25e6` (`test`)
2. **Task 1 GREEN: Align custom widget APG semantics** - `e793825` (`fix`)
3. **Task 2 RED: Add target-size style guardrails** - `c4aeed5` (`test`)
4. **Task 2 GREEN: Map target-size CSS to actual controls** - `5847a7c` (`fix`)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - Extended rendered stress-widget assertions for popup type, accordion region, combobox popup, and popover trigger relationships.
- `lib/threadline/operator_surface/ui.ex` - Added specific ARIA popup types, accordion region semantics, combobox listbox popup semantics, and optional tab id/control roving-tabindex hooks.
- `lib/threadline/operator_surface/style.ex` - Retired stale segmented selectors and added actual `.tl-tab`/`.tl-segment` sizing and selected-state styles.
- `test/threadline/operator_surface/component_contract_test.exs` - Added A11Y-02 APG/native/non-applicability source contracts.
- `test/threadline/operator_surface/ui_test.exs` - Added rendered component assertions for APG popup, tab, accordion, and combobox semantics.
- `test/threadline/operator_surface/style_contract_test.exs` - Added bounded target-size and non-color selected-state style contracts.

## Verification

- `mix test test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/ui_test.exs` - passed, 89 tests, 0 failures.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` - passed, 21 tests, 0 failures.
- `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/ui_test.exs` - passed, 131 tests, 0 failures.
- `cd examples/threadline_phoenix && mix precommit` - failed with 95 tests, 7 inherited demo seed/walkthrough failures. These match the Plan 180-01 inherited failure class and are outside the changed A11Y-02 files.

## Decisions Made

- Kept native form/table behavior native: selects/search/date inputs and responsive data tables are asserted as native controls rather than forced into custom combobox/grid roles.
- Kept tab and segmented-control hit areas compact at the existing `--tl-control-height-compact` lane while locking them to actual selectors and adding non-color active cues.
- Left `components/surface_header.ex` unchanged after verification; its native `<details>` nav and radio theme picker already satisfy the native/non-color mapping for this plan.

## Deviations from Plan

None - plan executed within the listed A11Y-02 scope using existing ExUnit and Playwright harnesses. The Task 1 source fix touched `lib/threadline/operator_surface/ui.ex`, which is listed in plan frontmatter and was necessary to make the planned APG checks true.

## Issues Encountered

- RED evidence for Task 1: ExUnit failed on dropdown `aria-haspopup`, popover popup type, tab linkage/roving tabindex, accordion region, and combobox popup type; Playwright failed on the rendered stress dropdown receiving `aria-haspopup="true"` instead of `menu`.
- RED evidence for Task 2: style contracts failed because `.tl-tab` was missing and segmented-control CSS targeted stale `.tl-segmented__item` selectors instead of rendered `.tl-segment` markup.
- Example app `mix precommit` remains red for inherited demo seed/walkthrough tests:
  `WalkthroughEvidenceTest` WALK-04-02, `WalkthroughHappyPathTest` WALK-03-04, and five `ThreadlinePhoenix.DemoContractTest` seed/persona assertions. No A11Y-02 test, component, style, or Playwright assertion failed.

## Known Stubs

None. Stub-pattern scan found only intentional test empty values, Phoenix slot/condition checks, and the existing `placeholder` global-attribute allowlist; none are unresolved UI stubs or mock data paths.

## Auth Gates

None.

## Threat Notes

No new network endpoint, route, public component API, authorization path, file access path, schema change, package install, or browser audit framework was introduced. The changes alter browser-visible semantics and CSS affordances only.

## Next Phase Readiness

Plan 180-03 can build on green A11Y-02 contracts and focus on motion/reduced-motion guardrails. Plan 180-04 still owns full residual CI classification and adversarial closeout evidence.

## Self-Check: PASSED

- Verified the summary file and all modified task files exist.
- Verified task commits `c9f25e6`, `e793825`, `c4aeed5`, and `5847a7c` exist in git history.
- Verified no unrelated untracked files were staged or committed.

---
*Phase: 180-accessibility-verification-guardrails-adversarial-closeout*
*Completed: 2026-06-20*
