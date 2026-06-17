---
phase: 174-form-components
plan: "05"
subsystem: ui
tags: [phoenix-component, liveview-js, wai-aria, forms, accessibility, operator-surface]

# Dependency graph
requires:
  - phase: 174-form-components
    provides: "UI component module (label, error, help, input, field, segmented_control) and ui_test.exs contract-test pattern"
provides:
  - "error_summary internal component — WAI-ARIA error-summary region linking each message to its field error id"
  - "field_group internal component — fieldset+legend wrapper reusing tl-filter-group classes (the wrapper 174-06 migrates timeline filter groups onto)"
  - "radio internal component — native shared-name radio group with distinct ids, checked selection, associated labels"
  - "switch internal component — native checkbox with role=switch + aria-checked, submits without JS"
  - "combobox internal component — role=combobox + listbox/option ARIA, Phoenix.LiveView.JS toggling only, graceful free-text degradation"
  - "search/date/number coverage proven as documented passthrough via the generic input clause"
  - "Per-component contract tests locking attrs/slots/states/a11y for every new component"
affects: [174-06-timeline-filter-migration, 175-shell-nav, 178-per-page-stress, 180-accessibility-closeout]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Native-HTML5-first form controls with ARIA semantics layered on top (no custom JS widgets)"
    - "Combobox ARIA state driven purely by Phoenix.LiveView.JS (toggle/toggle_attribute/set_attribute), mirroring popover/dropdown — zero third-party JS, graceful degradation"
    - "BEM class composition over new --tl-* tokens (tl-error-summary__*, tl-radio__*, tl-switch, tl-combobox__*) so style.ex parity test stays green"

key-files:
  created: []
  modified:
    - "lib/threadline/operator_surface/ui.ex — added error_summary, field_group, radio, switch, combobox"
    - "test/threadline/operator_surface/ui_test.exs — added describe blocks for error_summary, field_group, radio, switch, search, combobox"

key-decisions:
  - "search/date/number need no dedicated input clause — the generic input(assigns) default already emits type={@type} + tl-control; documented as passthrough and proven by tests"
  - "New components compose existing classes/BEM modifiers rather than introduce any new --tl-* token, keeping style.ex untouched and the brand-parity test green"
  - "Combobox confines JS to ARIA state only (Phoenix.LiveView.JS), keeping it CSP-safe and degradable to a free-text input — no Alpine, no new runtime deps"

patterns-established:
  - "Pattern 1: error_summary aggregates {field_id, message} tuples into a role=alert region; each message is an anchor href=#\\{field_id}-error linking to the field's error; empty list renders nothing"
  - "Pattern 2: switch is a styled native checkbox (role=switch + aria-checked) so it submits and degrades without JS"

requirements-completed: [COMP-04, COMP-06]

# Metrics
duration: 4min
completed: 2026-06-17
---

# Phase 174 Plan 05: Form Components Gap Closure Summary

**Added the five genuinely-missing operator-surface form components — error_summary, field_group, radio, switch, combobox (plus proven search/date/number passthrough) — each locked by a per-component contract test, with zero new --tl-* tokens and zero third-party JS.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-17T17:04:06Z
- **Completed:** 2026-06-17T17:07:24Z
- **Tasks:** 2 (both TDD)
- **Files modified:** 2

## Accomplishments
- `error_summary` — WAI-ARIA error-summary region (role=alert, aria-labelledby), each message anchored to its field error id, default/slot heading, renders nothing when empty.
- `field_group` — fieldset+legend wrapper reusing the existing `.tl-filter-group` / `.tl-filter-group__legend` classes; the wrapper 174-06 will migrate timeline raw fieldsets onto.
- `radio`, `switch`, `combobox` — native-degradable controls with correct ARIA/semantics; combobox toggling uses only Phoenix.LiveView.JS.
- `search`/`date`/`number` proven through the generic `input` clause (documented passthrough, asserted in tests).
- Every new component is locked by a `describe` contract test that fails CI on regression (COMP-06).

## Task Commits

Each task was committed atomically (TDD: test → feat):

1. **Task 1 (RED): failing tests for error_summary and field_group** - `98791fa` (test)
2. **Task 1 (GREEN): error_summary and field_group components** - `b75f551` (feat)
3. **Task 2 (RED): failing tests for radio, switch, combobox, search passthrough** - `1b95a6e` (test)
4. **Task 2 (GREEN): radio, switch, and combobox components** - `18e5c0a` (feat)

## Files Created/Modified
- `lib/threadline/operator_surface/ui.ex` - Added 5 internal components (error_summary, field_group, radio, switch, combobox) following the existing @doc false + attr/slot + ~H pattern.
- `test/threadline/operator_surface/ui_test.exs` - Added describe blocks for error_summary, field_group, radio, switch, search, combobox asserting attrs/slots/states/a11y.

## Decisions Made
- `search`/`date`/`number` need no dedicated `input` clause; the generic default already emits `type={@type}` + `tl-control`. Documented as passthrough and proven by tests (plan allowed either approach; passthrough is the minimal correct one).
- New components compose existing classes and add BEM modifier class names (not `--tl-*` tokens), so `style.ex` is untouched and the brand-parity test stays green.
- Combobox keeps JS confined to ARIA state via Phoenix.LiveView.JS, matching the popover/dropdown precedent — CSP-safe, no Alpine, no new deps.

## Deviations from Plan

None - plan executed exactly as written. (All Task 1 and Task 2 acceptance criteria met; no Rule 1-4 deviations triggered.)

## Issues Encountered
- Running `mix format` on the touched files reformatted large amounts of pre-existing code (the repo's `.formatter.exs` lacks `import_deps: [:phoenix, :phoenix_live_view]`, so `mix format` parenthesizes `attr`/`slot` macros — and the committed files were not previously format-clean under that config). This produced a ~900-line unrelated diff. Per the scope boundary, the formatter changes were reverted and the new components were written in the established unparenthesized `attr :x` style that the rest of `ui.ex` uses. style.ex was never touched.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- COMP-04 missing set is closed and COMP-06 (per-component contract tests) is satisfied for every new component.
- `field_group` is ready for 174-06 to migrate the timeline's raw `<fieldset class="tl-filter-group ...">` onto.
- Full operator_surface suite green (468 tests, 0 failures); `mix compile --warnings-as-errors` clean; no Alpine; style.ex unchanged.

## Self-Check: PASSED

- Files: `lib/threadline/operator_surface/ui.ex`, `test/threadline/operator_surface/ui_test.exs`, `174-05-SUMMARY.md` — all present.
- Commits: `98791fa`, `b75f551`, `1b95a6e`, `18e5c0a` — all present in git log.
- All 5 component defs (error_summary, field_group, radio, switch, combobox) present in ui.ex.

---
*Phase: 174-form-components*
*Completed: 2026-06-17*
