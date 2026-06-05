---
phase: 140-earned-new-flows
plan: "05"
subsystem: example-browser
tags: [playwright, e2e, earned-flows, operator-surface]

requires:
  - phase: 140-earned-new-flows
    plan: "02"
    provides: "Home record-first and correlation earned-flow controls"
  - phase: 140-earned-new-flows
    plan: "04"
    provides: "Evidence-to-Exports proof-context handoff"
provides:
  - "Focused browser UAT for EF1, EF2, EF3, and EF4"
  - "Example app LiveView browser bootstrap required for operator-surface forms"
affects: [operator-surface, example-app, browser-uat]

tech-stack:
  added: []
  patterns:
    - "Use pinned Phoenix and Phoenix LiveView static assets from existing Hex dependencies."
    - "Focused Playwright spec discovers seeded row-history data through existing Timeline/Transaction UI before testing Home and direct routes."

key-files:
  created:
    - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
    - examples/threadline_phoenix/priv/static/assets/app.js
    - examples/threadline_phoenix/priv/static/assets/phoenix.mjs
    - examples/threadline_phoenix/priv/static/assets/phoenix_live_view.esm.js
    - .planning/phases/140-earned-new-flows/140-05-SUMMARY.md
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/components/layouts/app.html.heex
    - examples/threadline_phoenix/config/test.exs

key-decisions:
  - "Keep the browser UAT focused on earned flows only: no motion, screenshot baseline, or broad responsive assertions."
  - "Load LiveView JS in the no-asset-pipeline example app by serving static files copied from pinned Hex deps."
  - "Allow loopback E2E origin in MIX_ENV=test so LiveView websocket connections work on 127.0.0.1:4002."

requirements-completed: [POLISH-FLOWS]

duration: resumed
completed: 2026-06-04
---

# Phase 140 Plan 05: Earned-Flow Browser UAT Summary

Focused browser UAT now proves the four Phase 140 earned flows end to end in the example app.

## Accomplishments

- Added `operator-earned-flows.spec.ts` covering:
  - EF1 Home record-first lookup reaches `/audit/rows/:table/:record_id`.
  - EF2 direct first-class row-history opens without first opening a transaction.
  - EF4 Home correlation paste lands on Timeline with the existing `correlation_id` filter.
  - EF3 filtered Timeline context carries into Exports.
  - EF3 filtered Evidence proof context carries into Exports.
- Reused seeded `walk-acme-4521-close` and discovered a stable `ticket_replies` record id through the existing Timeline/Transaction row-history link.
- Wired the example app layout to load Phoenix/LiveView JS and a CSRF token so operator-surface `phx-submit` forms work in a real browser.
- Allowed `127.0.0.1:4002` websocket origin in `MIX_ENV=test`, matching the E2E server URL.

## Task Commits

1. **Task 1: Add focused earned-flow Playwright spec** - `745073f`, `6adc27d`
2. **Task 2: Fix browser LiveView binding and complete verification** - `5cc0983`

## Verification Evidence

- Combined Phase 140 ExUnit gate:
  - `mix test test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/style_contract_test.exs`
  - Result: **119 tests, 0 failures**
- Focused LiveView regression after the browser asset fix:
  - `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs`
  - Result: **19 tests, 0 failures**
- Example app setup:
  - `PORT=4002 MIX_ENV=test THREADLINE_E2E=1 mix ecto.create || true`
  - `PORT=4002 MIX_ENV=test THREADLINE_E2E=1 mix ecto.migrate`
  - `PORT=4002 MIX_ENV=test THREADLINE_E2E=1 mix demo.reset`
  - `PORT=4002 MIX_ENV=test THREADLINE_E2E=1 mix phx.server`
- LiveView browser binding check:
  - Authenticated `/audit` reported `window.liveSocket == true`, `window.Phoenix == true`, and loaded `/assets/app.js`.
- Browser UAT:
  - `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-earned-flows.spec.ts`
  - Result: **15 tests, 0 failures**

## Deviations from Plan

The plan originally scoped implementation to the Playwright spec only. The first browser run exposed that the example app rendered LiveView roots without browser JS, so Home `phx-submit` forms could not work in E2E. Because EF1 and EF4 require real LiveView form submission, the fix added the smallest app-side LiveView bootstrap using already-pinned Phoenix dependencies.

## Known Stubs

None.

## Threat Flags

None. No new package dependencies, external CDNs, migrations, or network endpoints were introduced. The test-origin change is limited to `MIX_ENV=test`.

## User Setup Required

None beyond the normal example app E2E setup.

## Self-Check

PASSED.

---
*Phase: 140-earned-new-flows*
*Completed: 2026-06-04*
