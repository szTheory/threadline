---
phase: 181-baseline-audit-and-guard-repair
date: 2026-06-26
status: classification-ledger
requirements: [BASE-01, BASE-02]
source_decisions: [D-181-02, D-181-03, D-181-04, D-181-05, D-181-06, D-181-07, D-181-08]
---

# Phase 181 Guard Repair Ledger

This ledger classifies stale guard findings before any repair plan changes tests, source contracts, screenshot baselines, or operator UI code. It is a repair-scope artifact, not a redesign brief.

No production decorators, classes, functions, CLI flags, structs, dataclass fields, public routes, public component APIs, package dependencies, schema fields, page hierarchy, copy polish, or screenshot rebaselines are introduced here.

## Scope

This artifact records source/test scan evidence, classifications, owners, and repair policy for Phase 181. It adapts the Phase 180 automated-evidence shape: record the tested surfaces, preserve the exact proof limits, and make residual work explicit instead of deleting or weakening guards.

The scan evidence proves only that the current source tree still contains the matched strings and selector families. It does not prove rendered behavior, visual correctness, real assistive-technology behavior, or operator task success.

## Repair Policy

| Decision | Policy |
|---|---|
| D-181-04 | Repair now only when the change restores an existing invariant or accepted v1.37/v1.38 contract. |
| D-181-05 | Allowed now: stale selector repair, stale active source-test prose repair, retired-contract rationale, stress ledger/projection freshness, route/auth/feature-gate source contracts, and additive semantic hooks when non-redesign. |
| D-181-06 | Deferred: Shell/Home/Timeline/Coverage IA, visual hierarchy, CTA strategy, copy polish, layout redesign, motion polish, broad screenshot rebaselining, route churn, data-testid removal/rename, capture/query/auth semantic changes, public component APIs, root Storybook dependency, Tailwind/shadcn migration, and runtime destructive redaction. |

## Classification Vocabulary

| Classification | Meaning | Default action |
|---|---|---|
| `repair-now` | Active guard/source prose or selector drift that should be fixed by a bounded Phase 181 repair plan. | Repair in the named owner plan, then rerun the owning source/browser check. |
| `intentional guard` | A skip, local-only guard, or bounded ratchet that is intentionally retained. | Keep; document why it is not a defect. |
| `later-phase owner` | Real finding whose fix would be page polish, IA, layout, copy, motion, or broad screenshot promotion. | Defer to the named later v1.38 page/closeout phase. |
| `false-positive fixture` | Invalid-looking string is a deliberate bad-param, stress, or adversarial fixture. | Keep; ensure future scans do not treat it as a production selector. |
| `retired with rationale` | Old contract wording is no longer a live failure contract and should be rewritten or retired with replacement proof. | Repair source prose/docs only; do not change behavior unless the owner plan proves current behavior drift. |

## Scan Evidence

| Command | Result | Disposition |
|---|---|---|
| `rg -n "RED today\|RED until\|removed contract\|stale selector\|#4521\|not-real\|test\\.skip\|skip\\(" test/threadline/operator_surface examples/threadline_phoenix/e2e/tests lib/threadline/operator_surface` | 27 matches across 10 files | All matches are classified below. |
| `rg -n "#45(18\|21)\|walk-acme-4521-close\|walk-retention-offboarded-co\|Coverage inspection is not available\|timeline-row\|transaction-link" examples/threadline_phoenix/e2e/tests test/threadline/operator_surface lib/threadline/operator_surface` | Additional old demo-seed and selector-family evidence | Included where it changes repair ownership or confirms the Plan 01 failure class. |

## Surfaces Tested

| Surface | Evidence |
|---|---|
| Example E2E operator smoke | `examples/threadline_phoenix/e2e/tests/operator.spec.ts` pins old demo story labels and current stable `timeline-row` / `transaction-link` ids. |
| Tier C screenshot packet | `operator-screenshots.spec.ts` failures recorded in `181-SCREENSHOT-INVENTORY.md`; current repair owner is stale Timeline discovery and support Coverage denied-state copy. |
| Local screenshot regression | `operator-screenshot-regression.spec.ts` uses intentional local-only and project-filtering skips. |
| Stress route semantics and screenshots | `operator-stress.spec.ts` keeps bad-param fixtures and a bounded desktop-only screenshot ratchet. |
| Source contract tests | `test/threadline/operator_surface/**/*_test.exs` contains historical Wave-0 RED comments and failure messages around now-established component/style/data-state/page contracts. |
| Operator surface source | `lib/threadline/operator_surface` confirms several old RED comments are stale because the referenced behavior now exists in source. |

## Finding Ledger

| ID | File / lines | Selector, copy, or contract family | Classification | Action | Owner |
|---|---|---|---|---|---|
| G-001 | `examples/threadline_phoenix/e2e/tests/operator.spec.ts:36` | Test title `row history on #4521 close reply shows redacted capture`; current implementation uses `walk-acme-4521-close`, `timeline-row`, `transaction-link`, and `ticket_replies` row-history discovery. | `repair-now` | Rename the test title and any nearby comments to current demo-story language or current seeded contract. Keep route paths and `data-testid` values stable unless a later phase records a breaking change. | 181-03 |
| G-002 | `examples/threadline_phoenix/e2e/tests/operator.spec.ts:59` | Test title `#4518 delete story opens deleter transaction`; not in the primary regex, but same old seed-specific assumption family surfaced by Plan 01 precommit residuals. | `repair-now` | Replace brittle incident-number title wording with stable delete-story/deleter transaction language if the behavior remains valid; otherwise record an explicit retired contract. | 181-03 |
| G-003 | `examples/threadline_phoenix/e2e/tests/operator.spec.ts:26, 39-44, 62-64` | Stable Timeline selector family: `timeline-row` and `transaction-link` discovery under demo correlations. | `later-phase owner` | Preserve selector contract for now. If current data discovery is stale, repair the E2E discovery in 181-03; Timeline workflow polish belongs to 184. | 181-03, 184 |
| G-004 | `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts:98, 101, 117, 168, 176` | Tier C screenshot failures from Plan 01: `timeline-row` with `tickets`, transaction navigation, `DELETE` row discovery, first Timeline row, and copy `Coverage inspection is not available`. | `repair-now` | Update screenshot packet discovery/copy assertions to current seeded rendered behavior, or retire the removed copy contract with rationale and replacement. Do not broaden screenshot CI baselines in this repair. | 181-03 |
| G-005 | `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:351, 556, 566` | Responsive route-discovery failure family: `transaction-link` and `timeline-row` are not found after the old `walk-acme-4521-close` setup. | `repair-now` | Repair discovery to current seeded data or current semantic route source. Keep the added `desktop-1024` row and the Shell/Home/Timeline/Coverage responsive matrix. | 181-03 |
| G-006 | `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts:5, 46, 67, 84`; `operator-earned-flows.spec.ts:5, 44, 47`; `operator-features.spec.ts:10`; `operator-phase-175-uat.spec.ts:15`; `operator-phase-135-uat.spec.ts:24, 40, 46, 70, 82` | Additional old demo-correlation and Timeline selector families found by extended scan; includes old support Coverage denied-state copy. | `repair-now` | Review with G-004/G-005 and repair only assertions that are stale against current seed/rendered truth. Preserve stable IDs when they still represent accepted operator contracts. | 181-03 |
| G-007 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:77` | `test.skip(!!process.env.CI, "visual screenshot baselines are platform-sensitive...")`. | `intentional guard` | Retain. This is the local-only visual baseline guard and is not a defect. It prevents platform-sensitive PNG churn in CI. | 181-08 |
| G-008 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:83` | `test.skip(testInfo.project.name === "chromium", "fixed guard runs on desktop/mobile projects")`. | `intentional guard` | Retain. This is project filtering so fixed desktop/mobile/light baselines use the intended Playwright projects. | 181-08 |
| G-009 | `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:127` | Bad-param fixture URL `/audit/__stress?story=not-real&category=not-real&theme=purple&viewport=9999`. | `false-positive fixture` | Retain. `not-real` is an adversarial invalid-param fixture proving stress route allowlists fold bad params without crashing; it is not a production selector. | 181-05 |
| G-010 | `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:258` | `test.skip(testInfo.project.name !== "desktop-chromium", "stress screenshot ratchet runs only on desktop-chromium")`. | `intentional guard` | Retain. The stress screenshot ratchet is intentionally bounded to the ledger-owned desktop Chromium cells. | 181-07 |
| G-011 | `test/threadline/operator_surface/data_state_mapping_wave0_test.exs:3, 17` | Historical Wave-0 RED text says no `data_state/1` exists. Source now contains `UI.data_state/1` and typed variants. | `repair-now` | Rewrite stale module docs to describe the current data-state ratchet and remove old RED claims. No behavior change unless verification proves drift. | 181-04 |
| G-012 | `test/threadline/operator_surface/card_nesting_regression_test.exs:7` | Historical RED text says Coverage still nests card-family surfaces. Current source/test contracts include flattened Coverage and retired `tl-coverage-command` CSS checks. | `repair-now` | Rewrite comment to current regression-lock language. Preserve the card-nesting guard. | 181-04 |
| G-013 | `test/threadline/operator_surface/breadcrumb_test.exs:115` | Historical RED comment says pages still use `Investigation path`; assertions already require `Breadcrumb`. | `repair-now` | Replace RED comment with current breadcrumb regression statement. Keep the `Investigation path` refute. | 181-04 |
| G-014 | `test/threadline/operator_surface/component_contract_test.exs:473, 487, 498` | Overlay scrim click-outside comments/failure text say scrim has no `phx-click`; current `ui.ex` has `phx-click` on `tl-modal-scrim` and `tl-drawer-scrim`. | `repair-now` | Rewrite comments and failure text to describe the current Esc + scrim-click ratchet. Do not change overlay behavior. | 181-04 |
| G-015 | `test/threadline/operator_surface/style_contract_test.exs:1410` | Overlay JS-transition utility classes comment says RED until Plan 04. Current `style.ex` defines utility classes and modal/drawer shells. | `repair-now` | Rewrite to current source-contract language and keep keyframe-vs-class-selector guard. | 181-04 |
| G-016 | `test/threadline/operator_surface/style_contract_test.exs:1466` | Grid-item centering comment says `.tl-container` / `.tl-home` are RED today. Current `style.ex` contains `justify-self: center`. | `repair-now` | Rewrite to current centering regression language. Preserve the `justify-self` assertions. | 181-04 |
| G-017 | `test/threadline/operator_surface/style_contract_test.exs:1548, 1572` | Desktop scroll offset comments/failure text say `.tl-target-row` remains pinned to mobile header token. Current `style.ex` has a desktop `.tl-target-row` override. | `repair-now` | Rewrite comments/failure text to current sticky-header offset ratchet. Preserve desktop scroll-margin proof. | 181-04 |
| G-018 | `test/threadline/operator_surface/style_contract_test.exs:1582, 1599` | Timeline fact spacing comments/failure text say raw `gap: 2px` remains. Current `style.ex` uses tokenized spacing for `.tl-timeline-fact`. | `repair-now` | Rewrite comments/failure text to current token-spacing ratchet. Preserve token-scale assertion. | 181-04 |
| G-019 | `test/threadline/operator_surface/stress_fixtures_test.exs:428, 450, 455, 458, 467` | PAGE-01 comments/failure text say page stories remain reserved or single-path. Current stress fixture tests list 11 subjects x 7 paths. | `repair-now` | Rewrite to current 77-page-story ratchet language; 181-06 owns any ledger/projection parity repair if the source contract later finds drift. | 181-04, 181-06 |
| G-020 | `test/threadline/operator_surface/live/retention_history_live_test.exs:319, 431, 434` | Retention destructive-flow and copy-equals-full comments say Plan 05 is still RED. Current source has server-side `prune_now`, modal form, auth refusal, and copy contracts. | `repair-now` | Rewrite comments to current fail-closed destructive-action and ref-copy regression language. Keep type-to-confirm, auth re-check, AuditAction, and full-value copy assertions. | 181-04 |

## Retained Guards

| Guard | Why retained | Owner |
|---|---|---|
| Local visual screenshot skip in `operator-screenshot-regression.spec.ts:77` | Local PNG baselines are platform-sensitive; CI uses semantic checks and bounded stress screenshots instead. | 181-08 |
| Project filter skip in `operator-screenshot-regression.spec.ts:83` | The fixed visual guard intentionally runs only in desktop/mobile/light projects that own stable viewport names. | 181-08 |
| Desktop-only stress screenshot skip in `operator-stress.spec.ts:258` | Stress CI pixel ratchet stays bounded to existing ledger-owned dark 1024px desktop cells per D-181-07/D-181-08. | 181-07 |
| Bad-param stress URL with `not-real` in `operator-stress.spec.ts:127` | This is an invalid-param fixture proving allowlist fallback and error tolerance. | 181-05 |

## Retired Or Reworded Contracts Required

| Contract family | Rationale | Replacement proof |
|---|---|---|
| Historical Wave-0 `RED today` / `RED until` comments in source tests | The behavior appears to have landed in prior phases, but the prose still describes old failure states. Leaving it active misleads future repair planning. | Current source assertions in the same tests plus current source: `UI.data_state/1`, breadcrumb landmark, scrim `phx-click`, overlay class selectors, `justify-self: center`, desktop `.tl-target-row`, tokenized timeline fact gap, 77 page stories, and retention `prune_now` flow. |
| Old issue-number demo story titles (`#4521`, `#4518`) | Incident-number labels are brittle seed fiction and have already produced residual evidence drift in Plan 01. | Current correlation/table/row discovery or retired-contract rationale in 181-03. |
| Support Coverage denied-state copy `Coverage inspection is not available` | Plan 01 recorded this as a rendered copy assertion drift. | Current denied-state rendered copy or explicit retirement in 181-03, with Coverage workflow polish deferred to 185. |

## Plan 03 Repair Evidence

| Finding | Commit-time file path | Replacement contract | Status |
|---|---|---|---|
| G-001 | `examples/threadline_phoenix/e2e/tests/operator.spec.ts` | Test title now uses `ticket_replies` semantics. The row-history path is discovered from `/audit/timeline?table=ticket_replies`, follows the row `transaction-link`, then opens the `ticket_replies` `row-history-link` and asserts `/history/ticket_replies/` plus `[REDACTED]`. | Repaired in 181-03. |
| G-002 | `examples/threadline_phoenix/e2e/tests/operator.spec.ts` | The old `#4518`/deleter-specific title is retired. The active replacement discovers a current `ticket_replies` `DELETE` row, opens its transaction, verifies a user actor link, and asserts the transaction change row still names `ticket_replies` and `DELETE`. | Repaired in 181-03. |
| G-003 | `examples/threadline_phoenix/e2e/tests/operator.spec.ts` | Timeline discovery no longer depends on the stale `walk-acme-4521-close` correlation or `tickets` text. It keeps stable `timeline-row` and `transaction-link` contracts under the current `ticket_replies` table filter. | Repaired in 181-03 for the owning active smoke spec; broader Timeline polish remains 184. |
| G-004 | `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` | The screenshot packet now uses the same `ticket_replies` table discovery, transaction navigation, row-history redaction check, current `DELETE` row discovery, and current support Coverage denied-state alert copy (`Coverage unavailable` plus `mix threadline.health.coverage`). | Repaired in 181-03 for the owning screenshot packet; no broad screenshot baseline expansion. |
| G-005 | `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | Residual stale-correlation family remains outside the Plan 03 declared file list. It is retained as scan ownership until a follow-up plan edits that file with the same current `ticket_replies` route-discovery contract. | Residual owner: 181 follow-up or Timeline phase 184 if repair requires layout/workflow scope. |
| G-006 | `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts`; `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`; `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts`; `examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts`; `examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts` | Additional stale demo-correlation families remain recorded but were not in the Plan 03 modified-file contract. Future repairs should preserve stable IDs and use current rendered `ticket_replies`/route-href discovery rather than old issue-number fiction. | Residual owner: 181 follow-up or owning page/UAT phase. |

## Plan 03 Residual Verification

| Command | Result | Residual owner / evidence |
|---|---|---|
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator.spec.ts tests/operator-screenshots.spec.ts` | Passed: 18/18 across `chromium`, `desktop-chromium`, and `mobile-chromium`. | Plan 03 repaired the declared active browser contracts. |
| `cd examples/threadline_phoenix && mix precommit` | Failed after the E2E repair. | Out of Plan 03 file scope: inherited Elixir demo-seed contract failures still expect old `#4521`/`#4518` May anchor rows, `agent2` window rows, and `org_memberships` actor attribution. Failing tests: `ThreadlinePhoenixWeb.WalkthroughEvidenceTest` WALK-04-02; `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` WALK-03-04; `ThreadlinePhoenix.DemoContractTest` D-05 persona setup, SEED-03 leaving-agent window, SEED-03 hero close transaction, SEED-05 delete incident, and SEED-03 redacted close reply. Owner: source/demo contract repair plan, not this E2E selector plan. |

## Plan 04 Source-Test Prose Repair Evidence

| Finding | Commit-time file path | Replacement contract | Status |
|---|---|---|---|
| G-011 | `test/threadline/operator_surface/data_state_mapping_wave0_test.exs` | Module docs now describe the current `UI.data_state/1` dispatcher and typed-reason data-state distinction instead of saying the dispatcher and variants do not exist. | Repaired in 181-04. |
| G-012 | `test/threadline/operator_surface/card_nesting_regression_test.exs` | Header comments now describe the permanent DATA-05/D-12 one-card-boundary regression guard and the already-flattened Coverage command shell. | Repaired in 181-04. |
| G-013 | `test/threadline/operator_surface/breadcrumb_test.exs` | Module docs and inline comments now describe the current Breadcrumb landmark contract and legacy-label refute without claiming drill-down pages still use `Investigation path`. | Repaired in 181-04. |
| G-014 | `test/threadline/operator_surface/component_contract_test.exs` | Overlay comments and assertion text now describe the current Esc + scrim `phx-click` ratchet, independent of focus hooks, without claiming scrims are still inert. | Repaired in 181-04. |
| G-015 | `test/threadline/operator_surface/style_contract_test.exs` | Overlay JS-transition utility comments now describe the current class-selector source contract and why keyframes alone cannot satisfy it. | Repaired in 181-04. |
| G-016 | `test/threadline/operator_surface/style_contract_test.exs` | Grid-item centering comments now describe the current `.tl-container` and `.tl-home` `justify-self: center` ratchet instead of the old left-push failure state. | Repaired in 181-04. |
| G-017 | `test/threadline/operator_surface/style_contract_test.exs` | Desktop scroll-offset comments and failure text now describe the current `.tl-target-row` desktop `--tl-header-height` reconciliation ratchet. | Repaired in 181-04. |
| G-018 | `test/threadline/operator_surface/style_contract_test.exs` | Timeline fact spacing comments and failure text now describe the current token-scale gap contract and forbid raw spacing drift. | Repaired in 181-04. |
| G-019 | `test/threadline/operator_surface/stress_fixtures_test.exs` | PAGE-01 comments, test title, and failure messages now describe the current 11-subject x 7-path current-story ratchet instead of reserved-baseline worklist prose. | Repaired in 181-04. |
| G-020 | `test/threadline/operator_surface/live/retention_history_live_test.exs` | Retention destructive-flow and copy-equals-full comments/test group names now describe the current fail-closed prune path, AuditAction recording, and full-value `UI.ref/1` copy contract. | Repaired in 181-04. |

Plan 04 also added a durable source-prose guard in `test/threadline/operator_surface/component_contract_test.exs` that scans these source-test files for stale scaffold markers before the targeted ExUnit slice runs.

## Plan 05 Source-Contract Evidence

| Contract | Commit-time file path | Replacement / locked proof | Status |
|---|---|---|---|
| Mounted operator route set and export auth boundary | `test/threadline/operator_surface/router_test.exs`; `lib/threadline/operator_surface/router.ex` | D-181-05 now has a focused source-contract test that compiles a mounted router, asserts the stable `/threadline` LiveView route set, asserts the four HTTP export controller routes, and pins `pipeline :threadline_exports` before `ExportController` routes with `ExportAuthPlug` in the root router source. | Repaired in 181-05. |
| Root package Storybook/stress production exclusion | `test/threadline/operator_surface/stress_router_test.exs`; `lib/threadline/operator_surface/router.ex`; `lib/threadline/operator_surface/stress_router.ex` | D-181-05 now has source contracts proving the root operator macro does not expose `/__stress`, story routes, PhoenixStorybook, `phoenix_storybook`, or Storybook; the stress macro stays in `live_session :threadline_stress`, runs `Auth` before `Coverage.OnMount`, and fails closed for prod. | Repaired in 181-05. |
| Feature-gated nav group IDs and single current nav source | `test/threadline/operator_surface/surface_header_test.exs`; `lib/threadline/operator_surface/components/surface_header.ex` | D-181-05 now locks stable `operator-nav-group-*` source IDs for Investigate, Audit readiness, Evidence & exports, and Theme groups. The IDs are additive semantic hooks only; existing destination IDs, route hrefs, copy, and the single `aria-current="page"` source remain unchanged. | Repaired in 181-05. |

## Later-Phase Ownership Boundaries

| Owner | What this ledger allows | What remains deferred |
|---|---|---|
| 181-03 | Repair stale E2E selectors, data discovery, and copy assertions to current rendered truth. | Timeline IA, mobile density, toolbar/filter hierarchy, and workflow redesign remain 184. |
| 181-04 | Repair active source-test prose and failure messages that still describe old RED states. | Behavior rewrites are not allowed unless a source contract proves current behavior drift. |
| 181-05 | Add/verify route, auth, export, feature-gate, optional-dependency, and stress boundary source contracts. | Capture/query/auth semantic changes remain out of scope. |
| 181-06 | Repair design-system ledger, projection, and stress fixture parity without score backslide. | Lowering ratchets, removing locked IDs, or dropping stories without reset rationale is prohibited. |
| 181-07 | Verify bounded stress screenshot freshness and retained CI allowlist cells. | Full page x path x theme x viewport pixel matrix remains out of scope. |
| 181-08..181-10 | Classify or promote accepted local screenshot packets only when inventory-backed. | Broad UI screenshot rebaselining without design ownership remains out of scope. |
| 183..187 | Own page IA, layout, copy polish, motion/a11y closeout, and docs alignment. | These phases must not reinterpret Phase 181 stale guard repair as permission for route/data-testid churn. |

## Limits Of Proof

This ledger proves that every current primary stale-scan hit has a file path, line or selector family, classification, action, and owner. It also records additional old seed/copy/selector families that Plan 01 exposed but the primary regex does not fully cover.

This ledger does not prove:

- The E2E suite is green.
- The screenshot packet can complete.
- The source contracts are already free of stale wording after repair.
- The operator UI is visually polished.
- Real assistive-technology UAT was run.

## Verification Notes

- Plan 03 edits only the active E2E files named in its file contract plus this ledger.
- No product UI polish or later-phase redesign was implemented.
- No packages were installed or upgraded.
- `test.skip` entries in this ledger are intentionally retained guards, not defects.
- Bad-param `not-real` strings are stress fixtures, not production selectors.
