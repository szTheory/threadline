---
phase: 184
slug: timeline-investigation-flow
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-28
updated: 2026-06-29
---

# Phase 184 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix, Phoenix.LiveViewTest, and Playwright browser proof |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` |
| **Browser proof command** | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-timeline-investigation-flow.spec.ts` |
| **Light/system browser command** | `mix verify.example_browser_light tests/operator-timeline-investigation-flow.spec.ts` |
| **Estimated runtime** | Focused Mix slice: under 60 seconds locally; browser proof: about 30 seconds locally after dependency setup |

---

## Sampling Rate

- **After every task commit:** Run the focused Mix slice for the touched Timeline contracts plus the narrow browser proof when route/focus/responsive behavior changes.
- **After every plan wave:** Run the focused Mix slice and the Phase 184 browser proof.
- **Before `/gsd:verify-work`:** Run the focused Mix slice, the Phase 184 browser proof, and the light/system browser lane.
- **Max feedback latency:** No three consecutive task commits without automated verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 184-01-01 | 01 | 1 | TIME-01 | T-184-01 | Timeline pivots use scoped query/export boundaries and do not expose unsafe row-history links | LiveView integration + browser route flow | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-timeline-investigation-flow.spec.ts` | Yes | covered |
| 184-02-01 | 02 | 1 | TIME-02 | T-184-02 | Filters, saved views, pager, row actions, long refs, and state copy remain operable across required viewports | LiveView/source contract + browser responsive/a11y | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/style_contract_test.exs && ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-timeline-investigation-flow.spec.ts` | Yes | covered |
| 184-03-01 | 03 | 2 | TIME-03 | T-184-03 | Incident-pressure copy is concise without hiding stale/error/empty meaning | Source contract + browser motion/responsive checks | `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs && mix verify.example_browser_light tests/operator-timeline-investigation-flow.spec.ts` | Yes | covered |

---

## Wave 0 Requirements

- [x] Add 320 px and 1440 px proof in a narrow Timeline-only browser spec.
- [x] Add explicit safe/unsafe row-history direct-link coverage in `test/threadline/operator_surface/live/timeline_live_test.exs`.
- [x] Add browser proof for keyboard-only operation covering filters, result rows, copy controls, pagination, drawer close/return, and route transitions.
- [x] If Timeline renders stale/last-good state directly, add LiveView/source coverage for that real branch; otherwise rely on the shared stale-state primitive proof.

---

## Automated Verification Evidence

| Command | Result | Status |
|---------|--------|--------|
| `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | 189 tests, 0 failures | pass |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-timeline-investigation-flow.spec.ts` | 27 tests, 0 failures | pass |
| `mix verify.example_browser_light tests/operator-timeline-investigation-flow.spec.ts` | 9 tests, 0 failures | pass |
| `mix verify.test` | 1150 tests, 2 known outside-scope residual failures, 1 excluded | residuals classified in `184-VERIFICATION.md` |

---

## Manual-Only Verifications

None required for Phase 184 completion. Operator copy and hierarchy judgment is supported by automated copy/source contracts and browser route/focus proof; any later human UAT can be recorded separately without blocking Nyquist compliance.

---

## Validation Audit 2026-06-29

| Metric | Count |
|--------|-------|
| Draft Wave 0 gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |
| Remaining automated gaps | 0 |

## Validation Sign-Off

- [x] All tasks have automated verification or documented residual classification.
- [x] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Browser proof covers 320, 375, 768, 1024, and 1440 px.
- [x] `nyquist_compliant: true` set in frontmatter once the Wave 0 gaps are closed.

**Approval:** approved 2026-06-29
