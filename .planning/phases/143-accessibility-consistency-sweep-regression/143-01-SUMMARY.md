# Phase 143-01 Summary: Accessibility Primitive Baseline

## Scope

Locked the first accessibility baseline for the operator surface with source-level contracts and a focused browser regression spec.

## Changes

- Added source contracts for dark-surface WCAG AA contrast across core text/status tokens.
- Added source contracts for visible focus selectors and non-color status chip affordances.
- Added a focused Playwright accessibility baseline covering:
  - skip-link keyboard flow
  - Home lookup form accessible names
  - Timeline filter labels and nav current state
  - Actor segmented-control pressed state
  - Retention destructive confirmation affordance
  - Row-history dialog semantics and focus
  - status/verdict chip labels and non-color shape
- Made the shared skip link move focus to `#tl-main`.
- Added `tabindex="-1"` to operator main landmarks so skip-link targets are programmatically focusable.
- Made Actor activity window buttons emit explicit `aria-pressed` string states.

## Verification

- `mix test test/threadline/operator_surface/style_contract_test.exs`
  - 19 tests, 0 failures
- `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-accessibility.spec.ts`
  - 12 tests, 0 failures
- Static scan:
  - `rg -n "outline:\\s*none|box-shadow:\\s*none|aria-label|aria-current|aria-pressed|focus-visible" lib/threadline/operator_surface examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`
  - confirmed focus/ARIA coverage and no blanket `.threadline-ui * { outline: none }`
- Main target scan:
  - `rg -n "id=\"tl-main\"|tabindex=\"-1\"" lib/threadline/operator_surface/live -g '*.ex'`
  - confirmed operator mains expose focusable skip-link targets
- Port check:
  - `lsof -nP -iTCP:4002 -sTCP:LISTEN || true`
  - no listener after focused browser verification

## Deviations

- Expanded implementation scope beyond style contracts and browser spec into the shared header and operator LiveViews because the baseline spec found real runtime gaps in skip-link focus and Actor segmented-control state.
- No route, seed, dependency, screenshot, or package changes.
