---
phase: 181-baseline-audit-and-guard-repair
verified: 2026-06-26
status: passed-with-classified-ci-residuals
requirements: [BASE-01, BASE-02, BASE-03]
---

# Phase 181 Verification

## Verdict

Phase 181 is complete for the baseline audit and guard-repair scope. The targeted source contracts, stress browser guard, Tier B rendered slices, local screenshot packet capture, selected Tier C stress packet, screenshot regression guard, and stale-scan closeout passed or produced only intentional skip rows.

`mix ci.all` is not green. The final aggregate run exposed two root failures and the existing example-app demo-seed/walkthrough failures. These are classified below instead of being hidden:

- Root `test/threadline/operator_surface/formless_pages_test.exs:56` fails because `coverage_live.ex` now contains schema form markup introduced before Plan 181-11; this file was not changed by Plan 181-11. It remains a root contract/coverage ownership residual.
- Root `test/threadline/v1_23_charter_doc_contract_test.exs:15` is the inherited PROJECT milestone wording residual already classified by Phase 180.
- Example-app failures remain the inherited demo-seed/walkthrough residuals around old #4521/#4518 anchors, leaving-agent window rows, and org-membership actor attribution. They are unchanged in ownership from earlier Phase 181 summaries.

No real screen-reader UAT or human assistive-technology run occurred.

## Tiered Proof

| Tier | Evidence | Proves | Does Not Prove |
|------|----------|--------|----------------|
| Tier A: Source contracts | `mix test test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/style_contract_test.exs` -> 91 tests, 0 failures | Stress ledger/router/fixtures, surface header, source style contracts, and guard syntax remain coherent after Phase 181 guard repair | Browser rendering, screenshots, real keyboard execution, or AT behavior |
| Tier B: Browser rendered checks | `mix verify.operator_stress` -> 42 passed, 9 skipped; `operator-phase-178-uat.spec.ts` bounded grep -> 27 passed; `operator-responsive-mobile-first.spec.ts` bounded grep -> 30 passed | `/audit/__stress` browser guard, all real mounted top-level `/audit` routes at 320 and 1440, Shell/Home/Timeline/Coverage at 375, 768, and 1024 via `desktop-1024`, dynamic detail routes via current `ticket_replies` seed data, and no root horizontal overflow | Exhaustive browser/device/OS matrix, pixel diffs for every path, or real AT |
| Tier C: Local screenshot packet | Default screenshot capture -> 6 passed; `THREADLINE_E2E_THEME=system` light-lane screenshot capture -> 2 passed; selected stress packet -> 1 passed, 2 skipped; screenshot regression guard -> 10 passed, 5 skipped | Local-only dark/default, system light, mobile/desktop screenshot evidence exists for the Phase 181 packet, plus selected `/audit/__stress` state proof | CI screenshot allowlist coverage for selected stress states; cross-platform pixel stability |

## Tier B Route Matrix

| Coverage Slice | Command | Result | Notes |
|----------------|---------|--------|-------|
| All real mounted top-level `/audit` pages at 320 and 1440 | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-phase-178-uat.spec.ts --grep "stays within viewport at 320 \\+ 1440|column 2 at 1024"` | 27 passed | Covers `/audit`, `/audit/timeline`, `/audit/coverage`, `/audit/evidence`, `/audit/exports`, `/audit/policy/redaction`, and `/audit/policy/retention` at the 320 floor and 1440 ceiling, plus 1024 centering cells. Detail pages are discovered by the responsive matrix below. |
| Shell/Home/Timeline/Coverage at 375, 768, and 1024 | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-responsive-mobile-first.spec.ts --grep "operator responsive matrix: (phone|tablet|desktop-1024)|Timeline row-first command surface"` | 30 passed | Includes bounded `desktop-1024` row and shell checks. The guard was repaired to use the current `ticket_replies` seed, exact Evidence heading, flattened Coverage layout, and 1280px gutter breakpoint. |
| Dynamic detail routes | Same responsive command | 30 passed | Discovers current transaction, row-history, actor, evidence, redaction, retention, exports, coverage, timeline, and home routes from real seeded data. |

## Tier C Local Screenshot Packet

| Artifact Slice | Command | Result | Locality |
|----------------|---------|--------|----------|
| Default packet | `OPERATOR_SCREENSHOT_DIR="$(pwd)/.planning/phases/181-baseline-audit-and-guard-repair/screenshots" ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts` | 6 passed | Wrote/updated 36 top-level PNGs including desktop/mobile default captures. |
| Light-lane packet | `THREADLINE_E2E_THEME=system OPERATOR_SCREENSHOT_DIR="$(pwd)/.planning/phases/181-baseline-audit-and-guard-repair/screenshots" ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts` | 2 passed | Wrote `__light__1280` captures under the `desktop-chromium-light` lane. |
| Selected stress states | `OPERATOR_STRESS_SCREENSHOT_DIR=.planning/phases/181-baseline-audit-and-guard-repair/screenshots/stress-states ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-stress.spec.ts --grep "selected Tier C stress state packet"` | 1 passed, 2 skipped | Local-only packet includes `page.home.happy`, `state.unavailable-down`, `state.permission-denied`, and `state.pagination-boundary`. CI screenshot allowlist was not expanded for these selected states. |
| Screenshot regression guard | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts` | 10 passed, 5 skipped | Confirms accepted CI screenshot baselines remain stable and separate from the local Phase 181 packet. |

## Verification Commands

| Command | Result |
|---------|--------|
| `mix test test/threadline/operator_surface/stress_ledger_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/style_contract_test.exs` | 91 tests, 0 failures |
| `mix verify.operator_stress` | 42 passed, 9 skipped |
| `OPERATOR_SCREENSHOT_DIR="$(pwd)/.planning/phases/181-baseline-audit-and-guard-repair/screenshots" ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts` | 6 passed |
| `THREADLINE_E2E_THEME=system OPERATOR_SCREENSHOT_DIR="$(pwd)/.planning/phases/181-baseline-audit-and-guard-repair/screenshots" ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts` | 2 passed in `desktop-chromium-light`; light files include `__light__1280` |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-phase-178-uat.spec.ts --grep "stays within viewport at 320 \\+ 1440|column 2 at 1024"` | 27 passed |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-responsive-mobile-first.spec.ts --grep "operator responsive matrix: (phone|tablet|desktop-1024)|Timeline row-first command surface"` | 30 passed |
| `OPERATOR_STRESS_SCREENSHOT_DIR=.planning/phases/181-baseline-audit-and-guard-repair/screenshots/stress-states ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-stress.spec.ts --grep "selected Tier C stress state packet"` | 1 passed, 2 skipped |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts` | 10 passed, 5 skipped |
| `rg -n "RED today|RED until|removed contract|stale selector|#4521|not-real|test\\.skip|skip\\(" test/threadline/operator_surface examples/threadline_phoenix/e2e/tests lib/threadline/operator_surface` | Only expected hits: `operator-stress.spec.ts` invalid-route `not-real` fixture and intentional Playwright `test.skip` rows in stress/screenshot guards |
| `cd examples/threadline_phoenix && mix precommit` | Failed: 96 tests, 7 failures in inherited demo-seed/walkthrough contract rows |
| `cd examples/threadline_phoenix && mix ci.all` | Failed before test execution: Mix task `ci.all` is not defined in the example app |
| `mix ci.all` | Failed. Root `verify.test`: 1129 tests, 2 failures, 1 excluded; trigger coverage check: 1/1 expected tables covered; `verify.example`: 96 tests, 7 failures; aggregate stopped with `verify.example failed (2)` |

## Residual Classification

| Residual | Current Evidence | Classification | Owner |
|----------|------------------|----------------|-------|
| `test/threadline/operator_surface/formless_pages_test.exs:56` | Root `mix ci.all` reports `coverage_live.ex` contains `["<input", "<form"]`; `git blame` shows schema form lines from commit `917e3320 feat: polish operator UI and open v1.38`, not Plan 181-11 | Non-green root contract residual, not hidden as passed. Blocks full green CI until coverage/formless ownership is reconciled. | Future coverage/formless contract repair |
| `test/threadline/v1_23_charter_doc_contract_test.exs:15` | Root `mix ci.all` still expects old PROJECT milestone wording | Inherited Phase 179/180 documentation residual | Project charter/doc-contract repair |
| Example app `ThreadlinePhoenixWeb.WalkthroughEvidenceTest` WALK-04-02 | Missing #4521 close transaction / row-history evidence query result | Inherited demo-seed/walkthrough residual already recorded by Phase 181 Plans 01, 03, 07, 08, 09, and 10 | Demo seed/walkthrough repair |
| Example app `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` WALK-03-04 | Missing #4518 delete timestamp/evidence expectation | Same inherited demo-seed/walkthrough residual | Demo seed/walkthrough repair |
| Example app `ThreadlinePhoenix.DemoContractTest` D-05, SEED-03, SEED-05 rows | Missing old #4521 close rows, #4518 delete row, `agent2` window count, and `org_memberships` actor attribution | Same inherited demo-seed/walkthrough residual | Demo seed/walkthrough repair |

## Requirement Closure

| Requirement | Status | Evidence |
|-------------|--------|----------|
| BASE-01 | Complete with classified residual CI | Baseline packet now has executable source, stress, screenshot, Tier B, responsive, and stale-scan command evidence. Residual full-suite failures are classified instead of relabeled green. |
| BASE-02 | Complete | Screenshot inventory and local packet evidence cover durable names, default/light lane output, local-only stress-state screenshots, and the unchanged CI screenshot allowlist boundary. |
| BASE-03 | Complete | Research and guard repair connect PhoenixStorybook as example/dev-lane research, `/audit/__stress` as the canonical runtime stress harness, nav IA and operator personas from the Phase 181 packet, APG/WCAG source/browser guardrails from Phase 180, and motion guardrails without claiming real AT UAT. |

## Residual Risk

Full CI remains red until the owner of each classified residual repairs the coverage/formless source contract, PROJECT charter wording contract, and example-app demo-seed/walkthrough contracts. Phase 181's targeted operator-surface baseline evidence is green, but downstream release readiness should continue to treat `mix ci.all` as non-green.

## Proof Limits

- Automated browser and source tests prove sampled rendered behavior, source contracts, and screenshot packet production. They do not prove every host app, every OS/browser combination, every seeded data variation, or production data behavior.
- Automated APG/WCAG checks and browser accessibility-tree evidence from Phase 180 remain guardrails only. They do not prove real screen-reader announcement timing, verbosity, rotor behavior, or human UAT.
- The selected Tier C stress screenshots are local audit evidence. The CI screenshot allowlist was not expanded for `page.home.happy`, `state.unavailable-down`, `state.permission-denied`, or `state.pagination-boundary`.
- `mix ci.all` remains non-green for the residuals classified above; this verification closes Phase 181 by exact residual ownership, not by pretending the aggregate suite passed.
