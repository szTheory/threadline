---
phase: 184-timeline-investigation-flow
status: complete-targeted-green-broad-residuals-classified
verified: 2026-06-28
requirements: [TIME-01, TIME-02, TIME-03]
plans: [184-01, 184-02, 184-03]
---

# Phase 184 Verification Closeout

## Final Verdict

Phase 184 is verified for the Timeline investigation workflow at the targeted source and browser levels. The new browser proof passes the required dark/default and system/light lanes, covers 320, 375, 768, 1024, and 1440 px, and proves keyboard, drawer focus, URL recovery, row-history, copy, direct export anchors, theme, reduced motion, and no horizontal overflow.

Broad aliases are not green. Their non-green results are classified below and are not reported as Phase 184 passes.

## Command Evidence

| Command | Result | Evidence |
|---|---:|---|
| `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | PASS | 188 tests, 0 failures. |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-timeline-investigation-flow.spec.ts` | PASS | 27 passed after the final mobile summary/facts compatibility fix. |
| `mix verify.example_browser_light tests/operator-timeline-investigation-flow.spec.ts` | PASS | 9 passed in `desktop-chromium-light`. |
| `cd examples/threadline_phoenix/e2e && npx playwright test --list tests/operator-timeline-investigation-flow.spec.ts` | PASS | 27 tests listed in 1 file across `chromium`, `desktop-chromium`, and `mobile-chromium`; the spec is also matched by `desktop-chromium-light`. |
| `mix verify.format` | PASS | Exit 0, no formatter output. |
| `mix verify.credo` | PASS | Checked 230 source files; found no issues. |
| `mix verify.test` | FAIL, classified residuals | 1149 tests, 2 failures, 1 excluded: `test/threadline/operator_surface/formless_pages_test.exs` flags existing `coverage_live.ex` form controls; `test/threadline/v1_23_charter_doc_contract_test.exs` expects stale v1.37 wording while `.planning/PROJECT.md` is on v1.38. |
| `mix verify.format && mix verify.credo && mix verify.test && mix verify.example_browser -- operator-responsive-mobile-first.spec.ts operator-accessibility.spec.ts operator-earned-flows.spec.ts operator-find-mobile.spec.ts` | FAIL before browser tail | Format and credo passed; `mix verify.test` failed with the same 1149 tests, 2 failures, 1 excluded, so the `&&` browser tail did not run. |
| `mix verify.example_browser` | NON-GREEN / interrupted broad evidence | The broad 498-test browser alias received SIGTERM mid-suite after 190 listed cases. The Phase 184 spec passed inside the run at cases 153-161; observed failures were existing broad specs including stale `walk-acme-4521-close` Timeline fixture expectations, Coverage mobile/remediation, legacy overlay/theme/pager/responsive/screenshot/register checks. Not counted green. |
| `mix verify.example_browser_light` | FAIL, classified residuals | 108 tests: 97 passed, 7 failed, 4 skipped. Phase 184 light cases 100-108 all passed. Failures were Phase 177 offline CSS, missing light-lane screenshot baselines, and existing screenshot locators around `Exports` strict names. |
| `mix ci.all` | FAIL, classified residuals | Root format/credo/compile reached tests; `mix verify.test` showed 1149 tests, 2 failures, 1 excluded; `verify.threadline` passed its canary coverage table; `verify.example` failed with 109 tests, 7 demo-seed/walkthrough failures. |
| `cd examples/threadline_phoenix && MIX_ENV=test mix precommit` | FAIL, classified residuals | 109 tests, 7 failures in demo-seed/walkthrough contracts for #4521 close, #4518 delete, agent window, and persona actor attribution. |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-find-mobile.spec.ts --grep "timeline dense mobile keeps filters"` | PASS | 3 passed; confirms the existing mobile filter-summary proof remained green after the Phase 184 phone compaction fix. |

## Viewport Evidence

| Width | Evidence |
|---:|---|
| 320 | `operator-timeline-investigation-flow.spec.ts` verifies no horizontal overflow, visible row content in the first viewport, reachable row action after scroll, compact command surface, drawer width, keyboard path, copy/export metadata, and reduced motion. |
| 375 | Same proof as 320; the first row remains visible with at least 40 px in viewport. |
| 768 | Tablet viewport passes with row-first scan, filters, drawer, route transitions, and no overflow. |
| 1024 | Desktop viewport passes row scan, keyboard, drawer, exports, and no overflow. |
| 1440 | Wide desktop viewport passes without broad matrix or screenshot baseline expansion. |

## Keyboard and Browser Evidence

- Keyboard-only flow tabs through shell focus, starter filters, `Filters`, reset, `Apply`, row actor/correlation/copy controls, `Open transaction`, row-history when routeable, pager controls, and drawer fields.
- Escape closes the drawer and returns focus to `Filters`.
- URL-backed filters survive Apply and browser back/forward.
- Route transitions prove transaction open, direct safe row-history, correlation Timeline pivot, and Carry to Exports.
- Direct CSV, JSON, and NDJSON anchors are real download links with the current `table` and `correlation_id` query.
- Full-value copy controls include accessible names such as `Copy correlation id` and `data-tl-copy` values equal to source refs.
- Reduced-motion browser proof confirms Timeline rows remain static with no row entrance animation or layout jump.
- Dark/default targeted run and system/light targeted run both pass with `.threadline-ui[data-tl-theme]`.

## Source Contract Evidence

| Area | Evidence |
|---|---|
| TIME-01 workflow | Plan 184-01 source tests and Plan 184-03 browser proof cover filter -> scan -> open transaction or row-history -> export current view. |
| TIME-02 resilience | Plan 184-02 source contracts cover state/copy/layout; Plan 184-03 covers required viewports, keyboard, drawer, pager, copy controls, and route transitions. |
| TIME-03 copy/motion | Plan 184-02 copy/style contracts and Plan 184-03 reduced-motion proof cover concise copy, full-value copy controls, and static rows. |
| Light lane wiring | `examples/threadline_phoenix/e2e/playwright.config.ts` adds only `/operator-timeline-investigation-flow\.spec\.ts/` to the existing `desktop-chromium-light` `testMatch`; no new Playwright project was created. |
| Screenshot posture | The new Phase 184 spec contains no `toHaveScreenshot`, `screenshot`, or snapshot assertions, and no screenshot baseline was intentionally added. Generated broad-alias light snapshots were removed as artifacts. |
| Boundary posture | No package install, schema migration, schema push task, public component API, route churn, data-testid rename, Storybook route, stress route, or adjacent page polish was introduced for Phase 184. |

## Decision Coverage

| Decisions | Coverage |
|---|---|
| D-184-01, D-184-02, D-184-03, D-184-04 | Starter filters, drawer-only advanced filters, batch Apply, and URL recovery are covered by source contracts and browser navigation assertions. |
| D-184-05, D-184-06, D-184-07 | No command grammar or side rail was introduced; result facts remain useful and non-repetitive, with redundant phone facts hidden only at narrow widths to preserve first-row visibility. |
| D-184-08, D-184-09, D-184-10, D-184-11, D-184-12, D-184-13, D-184-14, D-184-15 | Hybrid rows, primary transaction action, safe row-history, actor/correlation pivots, full-value copy controls, no dense table, no hidden primary pivots, and no row animation are covered. |
| D-184-16, D-184-17, D-184-18, D-184-19, D-184-20, D-184-21, D-184-22 | Drawer utilities, saved views, Carry/Queue/Download, direct export links, Coverage/Evidence secondary checks, and Exports IA boundary are preserved. |
| D-184-23, D-184-24, D-184-25, D-184-26, D-184-27, D-184-28 | Timeline-critical state lattice, generic shared-state boundary, distinct state copy, stale-state non-fabrication, and layered verification are recorded through Plans 02 and 03. |
| D-184-29, D-184-30, D-184-31, D-184-32, D-184-33 | Personas, JTBD, domain language, backend-detail hiding, and calm brand posture are covered by copy/source contracts and browser workflow proof. |
| D-184-34, D-184-35, D-184-36, D-184-37, D-184-38 | Existing private LiveView/component boundaries, route/test-id/theme stability, existing assets, and no dependency/migration/theme-router changes are preserved. |

## Threat Evidence

| Threat | Evidence |
|---|---|
| T-184-01 | Source tests prove safe routeable row-history gating and export controller boundaries; browser proof opens row-history only when routeable. |
| T-184-02 | Filter params are submitted via batch Apply and URL-backed keys; no result-changing `phx-change` filtering was added. |
| T-184-03 | Browser proof verifies Carry to Exports and direct download links carry current `table` and `correlation_id` context. |
| T-184-04 | HEEx-rendered row refs/copy controls expose full values through `data-tl-copy` and accessible names. |
| T-184-05 | Queue/export feedback remains in existing Plan 01 source boundary; no background export authority moved into LiveView. |
| T-184-06 | Plan 02 source contracts distinguish first-run, filtered, future, and scoped copy; no fake Timeline stale branch was added. |
| T-184-07 | Long refs are wrapped/truncated visually while preserving full copied values. |
| T-184-08 | Browser proof covers 320/375/768/1024/1440, no overflow, drawer width, Escape close, focus return, pager, and keyboard path. |
| T-184-09 | Export unavailable/failure remains an existing state/source boundary; broad non-green Coverage/Exports screenshot failures are classified, not treated as green. |
| T-184-10 | Reduced-motion browser proof and style/source contracts record no Timeline row animation or layout jump. |
| T-184-SC | No package-manager install was run and no dependency was added. |

## Requirement Closure

| Requirement | Status | Evidence |
|---|---|---|
| TIME-01 | Closed for Phase 184 | Targeted source suite plus browser proof cover filter, scan, open transaction/row-history, and export current view. |
| TIME-02 | Closed for Phase 184 | Required viewports, keyboard-only operation, drawer, pager, copy controls, route transitions, and no overflow are covered by the new browser proof; state/long-ref contracts are covered by Plan 02. |
| TIME-03 | Closed for Phase 184 | Copy vocabulary, full-value copy controls, reduced motion, no row animation, and no layout jump are covered by Plan 02 and Plan 03 evidence. |

## Residual Risk Classification

| Residual | Owner / Scope | Evidence | Classification |
|---|---|---|---|
| Coverage page form controls | Coverage surface, outside 184-03 | `mix verify.test`: `coverage_live.ex` contains `<input` and `<form>` per `formless_pages_test.exs`. | Inherited residual; user explicitly said not to edit Coverage in 184-03. |
| Stale v1.23 planning-doc contract | Planning docs contract, outside 184-03 | `mix verify.test`: `v1_23_charter_doc_contract_test.exs` expects old v1.37 wording while `.planning/PROJECT.md` is v1.38. | Inherited residual; user explicitly said not to edit `.planning/PROJECT.md`. |
| Example app demo-seed walkthrough failures | Example seed/contracts, outside Timeline browser proof | `mix ci.all` / example `precommit`: 109 tests, 7 failures around #4521 close, #4518 delete, agent window count, and persona actor attribution. | Broad residual; not fixed because 184-03 scope is Timeline proof and closeout. |
| Broad `mix verify.example_browser` | Existing broad browser suite, mixed scope | SIGTERM mid-suite after 190/498 listed cases; Phase 184 cases passed; legacy failures observed in stale Timeline fixture, Coverage, overlay/theme/pager/responsive/screenshot/register specs. | Non-green broad evidence; not counted as pass. |
| Broad `mix verify.example_browser_light` | Existing broad light lane, screenshot/offline contracts | 97 passed, 7 failed, 4 skipped; Phase 184 light cases all passed. | Non-green broad evidence; screenshot baselines and unrelated offline/screenshot strictness remain outside 184-03. |

## Source Coverage Audit

| Source | Coverage |
|---|---|
| `184-CONTEXT.md` | D-184-01 through D-184-38 mapped above; rejected broad screenshot/dependency/route churn boundaries preserved. |
| `184-RESEARCH.md` | Focused browser proof chosen over broad screenshot matrix; no package additions; no custom widgets. |
| `184-VALIDATION.md` | Wave 0 browser gaps for 320/1440 and keyboard proof closed by `operator-timeline-investigation-flow.spec.ts`. Full-suite command remains non-green only because classified residuals block it. |
| `184-UI-SPEC.md` | TIME-01/TIME-02/TIME-03 test expectations are covered by source and browser evidence. |
| `184-01-SUMMARY.md` | Row-first command, safe row-history, and export handoff source contracts are verified. |
| `184-02-SUMMARY.md` | State lattice, copy, long-ref, and responsive/motion source contracts are verified. |

## Schema, Package, Screenshot, and API Notes

- No schema-relevant files changed, so no schema push task was required.
- No package-manager install command added or changed project dependencies.
- No screenshot baseline was intentionally created for Phase 184.
- No public component API, production Storybook route, stress route, route path, URL key, or `data-testid` rename was introduced.
