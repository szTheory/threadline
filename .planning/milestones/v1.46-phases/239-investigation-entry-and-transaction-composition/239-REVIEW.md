---
phase: 239-investigation-entry-and-transaction-composition
reviewed: 2026-10-10T08:33:31Z
depth: deep
candidate_sha: b97f0ab9523de8669e53310adc757f393cbbfd36
base_sha: 9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2
files_reviewed: 58
files_reviewed_list:
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts
  - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts
  - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts
  - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
  - examples/threadline_phoenix/e2e/support/operator-tab-zoom.ts
  - examples/threadline_phoenix/e2e/support/operator-zoom-extension/background.js
  - examples/threadline_phoenix/e2e/support/operator-zoom-extension/manifest.json
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-transaction-evidence.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts
  - examples/threadline_phoenix/test/test_helper.exs
  - lib/threadline/change_diff.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/stress_live/sections.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/timeline_live/filters.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/style/01_tokens.css
  - lib/threadline/operator_surface/style/03_page_home.css
  - lib/threadline/operator_surface/style/04_controls.css
  - lib/threadline/operator_surface/style/07_find_detail.css
  - lib/threadline/operator_surface/style/08_overlays_motion.css
  - lib/threadline/operator_surface/style/09_responsive.css
  - lib/threadline/operator_surface/ui/display.ex
  - lib/threadline/operator_surface/ui/overlay.ex
  - test/fixtures/operator_surface/README.md
  - test/fixtures/operator_surface/route-inventory.json
  - test/fixtures/operator_surface/source-surface-checklist.json
  - test/fixtures/style/README.md
  - test/fixtures/style/operator_surface.css
  - test/partition_weights.txt
  - test/threadline/change_diff_property_test.exs
  - test/threadline/change_diff_test.exs
  - test/threadline/operator_surface/live/start_live_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/operator_evidence_contract_test.exs
  - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  - test/threadline/operator_surface/rendered_output_contract_test.exs
  - test/threadline/operator_surface/style_byte_lock_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface/ui_test.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 239: Code Review Report

**Reviewed:** 2026-10-10T08:33:31Z  
**Depth:** deep  
**Files Reviewed:** 58  
**Status:** issues_found

## Narrative Findings (AI reviewer)

### Summary

The original deep review covered 58 files from candidate `aa7c218` and found no blocker. This closeout carries it forward to final candidate `b97f0ab9` and reviews the intervening changes. The redacted-diff copy path and canary coverage warning are resolved by `f72eb67e` and `fca97b14`: the synthetic secret now travels through the captured redaction fixture, and redacted diff tokens return no copy value before a title or fallback is read. The focused copy regression, canary evidence tests, and full final gate pass. Three non-blocking warnings remain: Timeline pagination and transaction row-history can still crash on database failures, and the zoom helper rejects a localhost loopback URL allowed by the runner.

## Resolved since the first review

### WR-01: [RESOLVED] Transaction diff copy affordance does not honor the redaction modifier

**Fix:** `f72eb67e` inserts the synthetic canary into the actual demo row that is redacted during the browser evidence flow. `fca97b14` makes `diff_full/1` return `nil` for redacted tokens before reading a title or visible-text fallback. The regression checks that a redacted field has no copy target, and the canary scans text, attributes, generated evidence, and screenshots. Focused ExUnit and evidence-manifest tests passed, followed by the full final gate.

### Remaining warnings

#### WR-02: [WARNING] Timeline pagination still raises on query failure

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:374-392`  
**Issue:** Initial filter loads now catch query exceptions and render a retryable error state, but `handle_event("next-page", ...)` calls `Query.timeline_page/2` and `preload_visible_context/3` directly. If the database disconnects after the first page, the next-page event raises through the LiveView and drops the operator session instead of surfacing the same recoverable failure state.
**Fix:** Handle query and preload failures in this event as well. Preserve already-rendered rows, disable further paging, and show a retryable message, or consistently route the failure through the existing query-error state.

#### WR-03: [WARNING] A transaction history deep link bypasses the new unavailable fallback

**File:** `lib/threadline/operator_surface/live/transaction_live.ex:41-79,133-193`; `lib/threadline/operator_surface/live/row_history_component.ex:40-67`  
**Issue:** When `incident_bundle/2` raises `DBConnection.ConnectionError`, `mount/3` assigns `unavailable: true`; `handle_params/3` still sets `show_history: true` for a history route. The render places the row-history component outside the `@unavailable` branch, so it queries `Threadline.row_history/3` and `Threadline.as_of/4` while the database is down. `RowHistoryComponent.update/2` rescues only `ArgumentError`, allowing the connection error to crash the LiveView and defeat the new fallback for this supported deep link.
**Fix:** Do not mount row history while the transaction is unavailable (and while it is not found), or make the component render a connection-unavailable state for both reads. Add a direct history-route test with the same injected connection failure used by the transaction fallback test.

#### WR-04: [WARNING] The zoom proof rejects a loopback host accepted by the E2E runner

**File:** `examples/threadline_phoenix/e2e/support/operator-tab-zoom.ts:81-88`; `examples/threadline_phoenix/e2e/run-e2e.sh:88-93`  
**Issue:** Evidence preflight accepts `E2E_BASE_URL=http://localhost:<PORT>` while binding the server to `127.0.0.1`, but `sendZoomRequest` only accepts tab URLs beginning with `http://127.0.0.1:`. The supported localhost configuration therefore passes runner preflight and fails when the zoom proof tries to verify browser zoom.
**Fix:** Parse the tab URL and accept `localhost` as well as `127.0.0.1`, while retaining the local-origin and configured-port checks.

---

_Reviewed: 2026-10-10T08:33:31Z_
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep_
