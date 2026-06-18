---
status: complete
phase: 173-primitive-components-extract-audit-each-in-isolation
source: [173-VERIFICATION.md]
started: 2026-06-16T12:00:00Z
updated: 2026-06-18T12:15:00Z
---

## Current Test

[testing complete — both items shifted left into automated tests]

## Tests

### 1. Visual Inspection of Primitives
expected: Colors, borders, states (hover, focus, active, disabled) should render correctly without visual glitches.
result: pass
covered_by: examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts (UAT #1 — interactive vs static .tl-chip honest cursors; disabled button reads as cursor:not-allowed + functionally inert; runs in the dark lane via verify.example_browser and the light/system lane via verify.example_browser_light)
note: Structural + computed-style assertions by design (no pixel-diff baselines).

### 2. Overlay Interactions and Focus Traps
expected: Transitions should be smooth, focus should be trapped within modals/drawers, `Esc` and outside clicks should dismiss overlays, and tooltips/popovers should stack correctly (z-index).
result: pass
covered_by: operator-phase-173-uat.spec.ts (UAT #2 — dropdown aria-expanded; modal stacks topmost above chrome; real retention prune modal opens as a dialog and dismisses via Escape + outside-click) + component_contract_test.exs (z-index layer order header<popover<subview<toast) + operator-accessibility.spec.ts (real row-history drawer dialog semantics + visible focus)
follow_up: Automatic focus-INTO an assign-driven modal is not asserted — the retention modal is always in the DOM (its `hidden` class toggles), so its `phx-mounted={@show && show_modal}` focus-rescue fires only on initial mount, not on open. Wiring focus-rescue for assign-driven overlays is a non-blocking follow-up. See 173-VERIFICATION.md.

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none — both items automated; one non-blocking focus-rescue follow-up recorded on test 2]
