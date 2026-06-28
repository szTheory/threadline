---
phase: 183-shell-navigation-and-home-orientation
plan: 03
status: complete
verified: 2026-06-28
requirements:
  - SHELL-01
  - SHELL-02
  - SHELL-03
---

# Phase 183 Verification Closeout

## Verdict

PASS with classified residuals.

Phase 183's targeted source contracts and dedicated browser perception proof are green for SHELL-01, SHELL-02, and SHELL-03 in the dark/default and system/light lanes. The broad verification commands are not all green; their failures are classified below and are not reported as Phase 183 shell/Home success.

No broad screenshot matrix, public component API, route churn, data-testid churn, new UI dependency, or adjacent page content polish was introduced by Phase 183 closeout.

## Command Evidence

| Command | Status | Evidence | Classification |
|---------|--------|----------|----------------|
| `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/skip_link_test.exs test/threadline/operator_surface/surface_header_csp_test.exs test/threadline/operator_surface/router_test.exs` | PASS | Final rerun after formatting fix: 121 tests, 0 failures. | Phase 183 source contracts green. |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-shell-home-phase183.spec.ts` | PASS | 27 passed across `chromium`, `desktop-chromium`, and `mobile-chromium`. | Phase 183 dark/default browser perception green. |
| `mix verify.example_browser_light tests/operator-shell-home-phase183.spec.ts` | PASS | 9 passed on `desktop-chromium-light`. | Phase 183 system/light browser perception green. |
| `mix verify.threadline` | FAIL | Exits with `** (Mix) Threadline: set :ecto_repos in config - no Ecto repository is configured to run verify_coverage.` | Command-environment residual for the standalone alias invocation; not a shell/Home behavior failure. |
| `mix verify.example_browser` | FAIL | 403 passed, 14 skipped, 54 failed. The dedicated `operator-shell-home-phase183` spec passed in the broad run. | Broad browser residuals outside the Phase 183 shell/Home target: earned-flow export context, copy button, mobile find, support coverage denial, Phase 173 dropdown, Phase 175 native details/sticky/pager, Phase 177 reconnect/offline CSS, responsive page gutters, screenshot, and register UX strict-locator failures. |
| `mix verify.example_browser_light` | FAIL | 88 passed, 4 skipped, 7 failed. The dedicated `operator-shell-home-phase183` light lane passed. | Broad light residuals outside Phase 183 target: Phase 177 reconnect/offline CSS, missing `desktop-chromium-light` screenshot baselines, and Exports heading strict-locator failures. Generated light screenshot candidates were not accepted or committed. |
| `mix ci.all` | FAIL | Initial run failed at `mix format --check-formatted`; after formatting `test/threadline/operator_surface/style_contract_test.exs`, rerun reached `verify.example` and failed with 109 tests, 7 failures. | Phase 183 source format gate fixed. Remaining failures are inherited example demo-seed/walkthrough residuals: row-history/redaction evidence for ticket 4521, hard-delete visibility for ticket 4518, missing `org_memberships` actor rows, and missing leaving-agent/close-reply audit rows. Browser lanes were not reached by this alias because `verify.example` stopped first. |
| `cd examples/threadline_phoenix && MIX_ENV=test mix precommit` | FAIL | 109 tests, 8 failures. | Required example app alias ran. Residuals match the inherited demo-seed/walkthrough area plus a 60s timeout while seeding `retention_run` evidence in `Mix.Tasks.Threadline.EvidenceShowExampleTest`. |
| `test -s .planning/phases/183-shell-navigation-and-home-orientation/183-VERIFICATION.md && rg -n "SHELL-01\|SHELL-02\|SHELL-03\|D-183-01\|D-183-28\|operator-shell-home-phase183\|320\|375\|768\|1024\|1280\|1440\|mix verify.example_browser_light\|mix ci.all\|MIX_ENV=test mix precommit\|T-183-01\|T-183-05\|schema push task" .planning/phases/183-shell-navigation-and-home-orientation/183-VERIFICATION.md` | PASS | Required-token audit returned matches for all requested requirement, decision, viewport, command, threat, and schema-change markers. | Closeout artifact presence and required-token audit green. |

## Browser Perception Evidence

| Viewport | Theme Lane | Evidence | Requirement Closure |
|----------|------------|----------|---------------------|
| 320 | dark/default | `operator-shell-home-phase183` mobile helper opens the native disclosure by keyboard/pointer path, verifies labeled navigation, validates visible theme controls, and asserts no horizontal overflow. | SHELL-01, SHELL-03 |
| 375 | dark/default | Mobile disclosure nav remains labeled and usable; Home task hierarchy and launcher validation stay visible without overflow. | SHELL-01, SHELL-02, SHELL-03 |
| 768 | dark/default | Desktop/tablet rail helper requires the rail panel to be visible without opening the disclosure. | SHELL-01, SHELL-03 |
| 1024 | dark/default | Desktop shell rail, active non-color cue, topbar status, theme picker, and Home launcher hierarchy remain stable. | SHELL-01, SHELL-02, SHELL-03 |
| 1280 | dark/default | Desktop rail and Home launcher hierarchy remain visible and scannable; adjacent shell route checks stay scoped to shell invariants. | SHELL-01, SHELL-02, SHELL-03 |
| 1440 | dark/default | Wide Home/shell perception cell proves primary investigation, readiness, proof/governance, health, EF1, EF4, and saved-view resume paths without adding screenshot baselines. | SHELL-02, SHELL-03 |
| desktop light | system/light | `mix verify.example_browser_light tests/operator-shell-home-phase183.spec.ts` passes 9 tests on `desktop-chromium-light`; selected theme state is verified in browser. | SHELL-03 |

## Theme Evidence

| Theme | Evidence | Result |
|-------|----------|--------|
| dark/default | Dedicated browser proof passed through `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-shell-home-phase183.spec.ts` with 27 passed. | Green |
| system/light | Dedicated browser proof passed through `mix verify.example_browser_light tests/operator-shell-home-phase183.spec.ts` with 9 passed. | Green |
| selected-state contract | Source CSP/theme contracts verify native form POST, `_csrf_token`, selected radio state, and no inline theme event handlers. Browser proof verifies the selected cue. | Green |

## Source Contract Evidence

| Source Test | Evidence | Requirement Closure |
|-------------|----------|---------------------|
| `SurfaceHeaderTest` | Preserves one obvious shell surface, status/topbar copy, feature-gated groups, route/auth boundaries, and private shell composition. | SHELL-01, SHELL-03 |
| `StartLiveTest` | Proves Home is a task-led launcher with investigation, readiness, proof/governance, health, EF1, EF4, and saved-view resume paths. | SHELL-02 |
| `StyleContractTest` | Proves desktop rail visibility, native disclosure boundary, active non-color cue, focus cue, sticky offsets, and overflow behavior. | SHELL-01, SHELL-03 |
| `CopyContractTest` | Locks calm operator vocabulary and prevents redundant generic CTA drift. | SHELL-02 |
| `ComponentContractTest` | Keeps shell/Home pieces private and prevents public component API expansion. | SHELL-01, SHELL-02, SHELL-03 |
| `SkipLinkTest` | Proves skip link target and focus behavior. | SHELL-03 |
| `SurfaceHeaderCspTest` | Proves CSRF-backed theme POST and no inline handlers. | SHELL-03, T-183-02 |
| `RouterTest` | Proves route/auth boundaries remain intact. | SHELL-03, T-183-01 |

## Requirement Closure

| Requirement | Status | Evidence |
|-------------|--------|----------|
| SHELL-01 | Closed | Source contracts and browser proof show one obvious global operator navigation surface, visible desktop/tablet rail at 768/1024/1280/1440, and clearly labeled native disclosure at 320/375. |
| SHELL-02 | Closed | Source contracts and browser proof show `/audit` Home is a task-led launcher with primary investigation, readiness, proof/governance, health, EF1, EF4, and saved-view resume paths. |
| SHELL-03 | Closed | Source contracts and browser proof show active state, feature gates, skip link, theme picker, topbar status, focus, and overflow stability across dark/default, system/light, and 320-1440px coverage. |

## Decision Coverage

| Decision | Status | Evidence |
|----------|--------|----------|
| D-183-01 | Covered | Plan 183-02 retuned `UI.shell/1`, `SurfaceHeader.surface_header/1`, `StartLive`, and scoped `.threadline-ui` CSS in place; closeout confirms contracts remain green. |
| D-183-02 | Covered | Component contracts keep shell/Home components private; no public component API was introduced. |
| D-183-03 | Covered | No larger extraction was required beyond private helpers already covered by tests. |
| D-183-04 | Covered | Retuning was driven by browser proof and source contracts, not speculative restructuring. |
| D-183-05 | Covered | No new UI dependency, migration, Tailwind, shadcn, icon package, or drawer dependency was introduced. |
| D-183-06 | Covered | Layered verification includes source contracts, LiveView tests, dedicated Playwright lanes, and this closeout. |
| D-183-07 | Covered | `operator-shell-home-phase183` is the narrow browser supplement for missing perception cells. |
| D-183-08 | Covered | No broad screenshot matrix or screenshot baseline expansion was introduced. |
| D-183-09 | Covered | Browser assertions use roles, names, selected state, semantic controls, and computed style rather than visual-only claims. |
| D-183-10 | Covered | Source tests lock copy and style contracts. |
| D-183-11 | Covered | Adjacent page navigation checks remain in scope for shell consistency. |
| D-183-12 | Covered | Adjacent page content/workflow polish remains out of scope. |
| D-183-13 | Covered | Shell-blocker exception was limited to shell invariants. |
| D-183-14 | Covered | Broad adjacent-route failures are classified as page-content or legacy test ownership when they are not shell invariants. |
| D-183-15 | Covered | Phase 183 used the planned three-plan split and wave structure. |
| D-183-16 | Covered | Browser organization uses one narrow Phase 183 spec with shared helpers. |
| D-183-17 | Covered | Copy, selectors, routes, feature gates, native controls, `data-tl-theme`, and private boundary are preserved. |
| D-183-18 | Covered | UI-SPEC was treated as design contract and CONTEXT as decision record. |
| D-183-19 | Covered | Home orientation follows operator jobs and arrival context. |
| D-183-20 | Covered | Locked Home hierarchy is covered by source and browser assertions. |
| D-183-21 | Covered | Backend details stay hidden unless necessary for operator action. |
| D-183-22 | Covered | Copy contracts preserve calm, exact vocabulary. |
| D-183-23 | Covered | Brand posture is preserved through existing token-backed CSS. |
| D-183-24 | Covered | Implementation remains idiomatic Phoenix LiveView with private function components and native controls. |
| D-183-25 | Covered | Host-mounted dashboard auth and route boundaries remain covered by router/source contracts. |
| D-183-26 | Covered | Home uses a user-needs-first task launcher shape. |
| D-183-27 | Covered | Mature design-system lessons are applied through the existing token/private component system, without new dependencies. |
| D-183-28 | Covered | Known audit/operator UI footguns are guarded by source contracts, browser proof, residual classification, and no route/API/test-id churn. |

## Security Threat Evidence

| Threat | Status | Evidence |
|--------|--------|----------|
| T-183-01 feature-gate exposure | Mitigated | Source contracts verify disabled feature groups are absent and router/auth boundaries remain stable. Browser proof exercises feature-gated shell destinations without introducing new routes. |
| T-183-02 CSRF/inline theme mutation | Mitigated | `SurfaceHeaderCspTest` verifies native POST, `_csrf_token`, native radios, selected option semantics, and no inline event handlers; browser proof verifies selected state. |
| T-183-03 launcher validation | Mitigated | Source and browser contracts verify mapped-table validation, blank and overlong correlation handling, canonical navigation, and validation copy for EF1/EF4 launchers. |
| T-183-04 focus/overflow denial | Mitigated | Skip link, focus cues, sticky offset, and 320px no-overflow are covered by source and browser tests. |
| T-183-05 HEEx/XSS safety | Mitigated | Shell/Home remain private Phoenix function components rendered through HEEx; no raw HTML-string rendering or public template API was introduced. |

## Residual Risk Classification

| Residual | Owner / Scope | Classification |
|----------|---------------|----------------|
| `mix verify.threadline` standalone `:ecto_repos` error | Root alias/test environment configuration | Non-green command-environment residual. It does not invalidate Phase 183 shell/Home source or browser evidence. |
| `mix verify.example_browser` 54 failures | Existing example browser suites outside the dedicated Phase 183 spec | Non-green broad-lane residual. Dedicated Phase 183 spec is green inside the broad run; failures are in earned-flow export context, copy button, mobile find, support coverage denial, Phase 173, Phase 175, Phase 177, responsive page-content/gutter, screenshot, and register UX areas. |
| `mix verify.example_browser_light` 7 failures | Existing light screenshot/reconnect/Exports areas | Non-green broad-light residual. Dedicated Phase 183 light spec is green; generated light screenshot candidates were removed and not committed. |
| `mix ci.all` 7 example failures | Inherited demo-seed/walkthrough contracts | Non-green broad CI residual. Format gate caused by this plan's touched source test was fixed; remaining failures are not shell/Home regressions. |
| `MIX_ENV=test mix precommit` 8 example failures | Inherited demo-seed/walkthrough contracts plus seed timeout | Non-green example-app precommit residual. Required alias was run and recorded honestly. |

## Adjacent Route Scope Classification

Adjacent route checks used in `operator-shell-home-phase183` are shell invariant checks: they verify the rail/disclosure, active state, topbar, skip link, theme picker, and overflow behavior on representative adjacent pages. No adjacent page content polish was introduced.

The broad browser failures in responsive, screenshot, Exports, register UX, earned-flow, Phase 173, Phase 175, and Phase 177 suites are deferred page-content or legacy workflow ownership unless they violate the shell invariants above. They are not reclassified as Phase 183 shell blockers.

## Screenshot Posture

Phase 183 did not add a broad screenshot matrix or commit screenshot baselines. The dedicated `operator-shell-home-phase183` proof uses semantic/browser perception assertions rather than screenshots. The broad light suite generated missing `desktop-chromium-light` screenshot candidates during verification, but those generated files were not accepted or committed.

## Package Install Note

No package-manager install was introduced as a Phase 183 implementation step, and no new UI dependency was added or committed. The existing example Playwright harness may run its normal dependency/bootstrap commands during verification; that did not create a Phase 183 package change.

## Schema Change Note

No schema, migration, SQL trigger, config struct field, route table, or persistent data model file changed in Phase 183 closeout. No schema push task was required.

## Source Coverage Audit Conclusion

The Phase 183 closeout covers SHELL-01, SHELL-02, SHELL-03, D-183-01 through D-183-28, and T-183-01 through T-183-05. Targeted evidence is green. Broad non-green commands are recorded as residuals with scope and owner classification.
