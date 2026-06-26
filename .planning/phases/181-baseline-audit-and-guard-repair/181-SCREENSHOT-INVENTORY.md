---
phase: 181-baseline-audit-and-guard-repair
date: 2026-06-26
status: complete-with-classified-residual-ci
requirements: [BASE-01, BASE-02, BASE-03]
evidence_tiers: [Tier B, Tier C]
---

# Phase 181 Screenshot Inventory

This inventory records the bounded screenshot and rendered-slice evidence collected across Phase 181. It keeps the existing `screenshot_allowlist` bounded, separates ledger-owned CI screenshot baselines from local Tier C packet screenshots, and records residual full-suite failures as owned follow-up work instead of deleting or weakening coverage.

## Capture

- Packet directory: `.planning/phases/181-baseline-audit-and-guard-repair/screenshots/`
- Durable name source: `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts`
- Helper behavior: `OPERATOR_SCREENSHOT_DIR` writes durable files named `{name}__default__1280.png`, `{name}__default__375.png`, or `{name}__light__1280.png` depending on Playwright project.
- Generated PNG disposition: the complete Tier C page packet below is intentionally committed as planning evidence. It contains 36 top-level page PNGs plus the four selected local-only stress-state PNGs. These files are not `toHaveScreenshot` baselines and do not expand CI pixel coverage.
- Path correction: `run-e2e.sh` runs Playwright from `examples/threadline_phoenix/e2e`, so relative `OPERATOR_SCREENSHOT_DIR=.planning/...` initially emitted under `examples/threadline_phoenix/e2e/.planning/...`. Those generated PNGs were moved to the root phase directory above; use an absolute path in future reruns if writing directly to root is required.

## Commands Run

| Lane | Command | Result | Notes |
|---|---|---|---|
| Tier C default packet | `OPERATOR_SCREENSHOT_DIR="$(pwd)/.planning/phases/181-baseline-audit-and-guard-repair/screenshots" ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts` | Passed: 6 passed | Generated/updated the complete default desktop/mobile packet for all 12 durable page names. |
| Tier C light packet | `THREADLINE_E2E_THEME=system OPERATOR_SCREENSHOT_DIR="$(pwd)/.planning/phases/181-baseline-audit-and-guard-repair/screenshots" ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshots.spec.ts` | Passed: 2 passed | `run-e2e.sh` selected `desktop-chromium-light`; generated/updated `__light__1280` PNGs for all 12 durable page names. |
| Tier B 320/1440 route sweep and 1024 centering cells | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-phase-178-uat.spec.ts --grep "stays within viewport at 320 \\+ 1440|column 2 at 1024"` | Passed: 27 passed | Covers `/audit`, Timeline, Coverage, Evidence, Exports, Redaction, and Retention at 320/1440 plus Home/transaction centering at 1024. |
| Tier B responsive Shell/Home/Timeline/Coverage slice | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-responsive-mobile-first.spec.ts --grep "operator responsive matrix: (phone|tablet|desktop-1024)|Timeline row-first command surface"` | Passed: 30 passed | New `desktop-1024` row is green; stale Timeline-row discovery, Coverage command-shell, Evidence heading, and 1024 gutter assertions were repaired to current rendered truth. |
| Example-app precommit | `cd examples/threadline_phoenix && mix precommit` | Failed: 96 tests, 7 failures | Failures are demo-seed/audit-transaction query assertions; no Elixir source or seed code changed in Plan 01. |

## Plan 07 Stress Guard Freshness

| Lane | Command | Result | Notes |
|---|---|---|---|
| Tier B ledger-owned stress screenshot guard | `mix verify.operator_stress` | Passed: 42 passed, 9 skipped | The three ledger-owned desktop Chromium screenshot cells matched current rendered truth. No CI baseline PNG update was needed. |
| Tier C selected stress-state packet | `OPERATOR_STRESS_SCREENSHOT_DIR=.planning/phases/181-baseline-audit-and-guard-repair/screenshots/stress-states ./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-stress.spec.ts --grep "selected Tier C stress state packet"` | Passed: 1 passed, 2 skipped | Captured the local-only dark 1024px desktop packet for the selected D-181-07 happy/error/permission/boundary story IDs. Non-desktop projects skip intentionally. |
| Example-app precommit after stress spec/packet changes | `mix precommit` from `examples/threadline_phoenix` | Failed: 96 tests, 7 failures | Same inherited demo-seed/walkthrough contract residuals recorded by Plans 01 and 03; no Elixir source, seed, capture, query, auth, route, dependency, public API, or runtime operator UI code changed in Plan 07. |

### Plan 07 Local-Only Selected Stress-State Packet

These PNGs are Phase 181 local evidence under `.planning/`; they are not `toHaveScreenshot` baselines and are not part of `.planning/design-system-ledger.json` `screenshot_allowlist.ci`.

| Story ID | Evidence kind | Project | Theme | Viewport | Path | Dimensions | Status | Rationale |
|---|---|---|---|---:|---|---:|---|---|
| `page.home.happy` | happy | `desktop-chromium` | dark | 1024 | `screenshots/stress-states/stress-page-home-happy-dark-1024.png` | 752 x 478 | local-only phase packet, committed as planning evidence | Confirms the existing happy page baseline story is represented in the stress route before page polish. |
| `state.unavailable-down` | error | `desktop-chromium` | dark | 1024 | `screenshots/stress-states/stress-state-unavailable-down-dark-1024.png` | 752 x 6761 | local-only phase packet, committed as planning evidence | Captures source-down/error data-state evidence without promoting it to CI pixels. |
| `state.permission-denied` | permission | `desktop-chromium` | dark | 1024 | `screenshots/stress-states/stress-state-permission-denied-dark-1024.png` | 752 x 6761 | local-only phase packet, committed as planning evidence | Captures permission-denied state evidence without expanding the screenshot allowlist. |
| `state.pagination-boundary` | boundary | `desktop-chromium` | dark | 1024 | `screenshots/stress-states/stress-state-pagination-boundary-dark-1024.png` | 752 x 6737 | local-only phase packet, committed as planning evidence | Captures pagination-boundary state evidence for D-181-07 Tier C review. |

## Plan 08 Local Screenshot Regression Guard

| Lane | Command | Result | Notes |
|---|---|---|---|
| Local screenshot regression guard | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts` | Passed: 10 passed, 5 skipped | Existing committed local baselines matched current rendered truth for desktop/mobile Home, dense Timeline, row-history, Exports, and Retention. The generic `chromium` project skipped intentionally; the guard remains local-only and was not promoted to CI. |
| Example-app precommit after local screenshot-regression verification | `mix precommit` from `examples/threadline_phoenix` | Failed: 96 tests, 7 failures | Same inherited demo-seed/walkthrough contract residuals recorded by Plans 01 and 07; no Elixir source, seed, capture, query, auth, route, dependency, public API, Playwright spec, or PNG baseline changed in Plan 08. |

### Plan 08 Local Baseline Classification

All rows below are existing `operator-screenshot-regression.spec.ts` Playwright snapshot baselines. Plan 08 did not update PNG files, did not add baseline cells, and did not move any local baseline into the CI allowlist. No accepted update was discovered for Plan 09 or Plan 10.

| Surface | Project | Viewport | Snapshot path | Classification | Rationale |
|---|---|---:|---|---|---|
| Home | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/home-desktop-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no Home desktop PNG update is accepted for Plan 09. |
| Home | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/home-mobile-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no Home mobile PNG update is accepted for Plan 09. |
| Dense Timeline | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/timeline-dense-desktop-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no dense Timeline desktop PNG update is accepted for Plan 09. |
| Dense Timeline | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/timeline-dense-mobile-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no dense Timeline mobile PNG update is accepted for Plan 09. |
| Row history | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/row-history-desktop-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no row-history desktop PNG update is accepted for Plan 10. |
| Row history | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/row-history-mobile-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no row-history mobile PNG update is accepted for Plan 10. |
| Exports | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/exports-desktop-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no Exports desktop PNG update is accepted for Plan 10. |
| Exports | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/exports-mobile-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no Exports mobile PNG update is accepted for Plan 10. |
| Retention | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/retention-desktop-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no Retention desktop PNG update is accepted for Plan 10. |
| Retention | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/retention-mobile-chromium.png` | current committed local baseline | Guard reached screenshot comparison and passed; no Retention mobile PNG update is accepted for Plan 10. |

### Plan 09 Home and Dense Timeline No-Update Confirmation

Plan 09 re-ran the bounded Home/dense Timeline subset after reading the Plan 08 classification rows. No `--update-snapshots` command was run because Plan 08 classified all four target PNGs as current committed local baselines with no accepted update.

| Lane | Command | Result | Notes |
|---|---|---|---|
| Home/dense Timeline subset | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts --grep "global chrome\|dense Timeline"` | Passed: 4 passed, 2 skipped | Desktop/mobile Home and dense Timeline baselines matched current rendered truth. Generic `chromium` skips remained intentional. No PNG files, Playwright specs, stress screenshots, ledger rows, or CI allowlist entries changed. |
| Example-app precommit after Plan 09 verification | `mix precommit` from `examples/threadline_phoenix` | Failed: 96 tests, 7 failures | Same inherited demo-seed/walkthrough contract residuals recorded by Plans 01, 07, and 08. Plan 09 changed only this inventory evidence and did not modify Elixir source, seed data, capture/query/auth behavior, route paths, Playwright specs, or PNG baselines. |

| Surface | Project | Viewport | Snapshot path | Committed status | Plan 09 disposition |
|---|---|---:|---|---|---|
| Home | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/home-desktop-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 09 subset passed. |
| Home | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/home-mobile-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 09 subset passed. |
| Dense Timeline | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/timeline-dense-desktop-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 09 subset passed. |
| Dense Timeline | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/timeline-dense-mobile-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 09 subset passed. |

### Plan 10 Row-history, Exports, and Retention No-Update Confirmation

Plan 10 re-ran the bounded Row-history/Exports/Retention subset after reading the Plan 08 classification rows. No `--update-snapshots` command was run because Plan 08 classified all six target PNGs as current committed local baselines with no accepted update.

| Lane | Command | Result | Notes |
|---|---|---|---|
| Row-history/Exports/Retention subset | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-screenshot-regression.spec.ts --grep "row-history\|Exports\|Retention"` | Passed: 6 passed, 3 skipped | Desktop/mobile Row-history, Exports, and Retention baselines matched current rendered truth. Generic `chromium` skips remained intentional. No PNG files, Playwright specs, stress screenshots, ledger rows, or CI allowlist entries changed. |
| Example-app precommit after Plan 10 verification | `mix precommit` from `examples/threadline_phoenix` | Failed: 96 tests, 7 failures | Same inherited demo-seed/walkthrough contract residuals recorded by Plans 01, 07, 08, and 09. Plan 10 changed only this inventory evidence and did not modify Elixir source, seed data, capture/query/auth behavior, route paths, Playwright specs, or PNG baselines. |

| Surface | Project | Viewport | Snapshot path | Committed status | Plan 10 disposition |
|---|---|---:|---|---|---|
| Row history | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/row-history-desktop-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 10 subset passed. |
| Row history | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/row-history-mobile-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 10 subset passed. |
| Exports | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/exports-desktop-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 10 subset passed. |
| Exports | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/exports-mobile-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 10 subset passed. |
| Retention | `desktop-chromium` | 1280 x 900 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/retention-desktop-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 10 subset passed. |
| Retention | `mobile-chromium` | 375 x 812 | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots/retention-mobile-chromium.png` | unchanged committed local baseline | Left untouched; Plan 08 accepted no update and the Plan 10 subset passed. |

### Plan 08 Intentional Skips

| Project | Tests skipped | Disposition | Rationale |
|---|---:|---|---|
| `chromium` | 5 | intentional local guard skip | `operator-screenshot-regression.spec.ts` skips the generic Chromium project so fixed local baselines only run on `desktop-chromium` and `mobile-chromium`; the full guard is still skipped on CI because these PNG baselines are platform-sensitive. |

## Tier C Local Packet Matrix

| Durable name | `__default__1280` | `__default__375` | `__light__1280` | Status |
|---|---|---|---|---|
| `home` | committed, 1280 x 1281 | committed, 375 x 2013 | committed, 1280 x 1281 | Shell/Home dark/default and light-lane evidence present. |
| `timeline` | committed, 1280 x 2571 | committed, 375 x 5509 | committed, 1280 x 2402 | Timeline default and light-lane evidence present. |
| `timeline-empty` | committed, 1280 x 901 | committed, 375 x 1530 | committed, 1280 x 901 | Timeline empty-state default and light-lane evidence present. |
| `timeline-dense` | committed | committed | committed | Current `ticket_replies` discovery replaced the stale `walk-acme-4521-close`/`tickets` assumption. |
| `transaction` | committed | committed | committed | Transaction route is discovered from the current Timeline `transaction-link`. |
| `row-history` | committed | committed | committed | Row-history route is discovered from the current `ticket_replies` transaction row. |
| `actor` | committed | committed | committed | Actor detail packet evidence present. |
| `evidence` | committed | committed | committed | Evidence page packet evidence present. |
| `coverage` | committed | committed | committed | Coverage page packet evidence present in default and `desktop-chromium-light` lanes. |
| `exports` | committed | committed | committed | Exports packet evidence present. |
| `redaction` | committed | committed | committed | Redaction packet evidence present. |
| `retention` | committed | committed | committed | Retention packet evidence present. |

## Light-Lane Review Cells

| Review cell | Evidence | Disposition |
|---|---|---|
| Shell/Home | `screenshots/home__light__1280.png` | Present; includes shell, header, nav, theme picker, and Home content in the `desktop-chromium-light` lane. |
| Timeline | `screenshots/timeline__light__1280.png`, `screenshots/timeline-empty__light__1280.png`, `screenshots/timeline-dense__light__1280.png` | Present for default, empty, and dense states. |
| Coverage | `screenshots/coverage__light__1280.png` | Present; Coverage review evidence is complete for the light lane. |
| Shell/Home/Timeline/Coverage responsive slice | `operator-responsive-mobile-first.spec.ts` includes phone, tablet, and `desktop-1024` rows | Passed: 30 passed after current-seed route discovery and flattened Coverage assertions were repaired. |

## Tier B Rendered Slice Evidence

| Spec | Scope | Result | Disposition |
|---|---|---|---|
| `operator-phase-178-uat.spec.ts` | Phase 178 route sweep at 320 + 1440 and column-2 centering at 1024 | Passed: 27 passed | Current source/rendered no-overflow proof remains usable for the bounded route sweep. |
| `operator-responsive-mobile-first.spec.ts` | Shell/Home/Timeline/Coverage responsive matrix at 375, 768, and `desktop-1024`; Timeline row-first command surface | Passed: 30 passed | Additive `desktop-1024` row is executable and green. Route discovery now uses current `ticket_replies` data and exact current page contracts. |

### Rendered-Slice Failures Repaired

| Command | Prior failing assertion | Final disposition | Owner |
|---|---|---|---|
| `operator-screenshots.spec.ts` default and light packet commands | `operator-screenshots.spec.ts:98` waited for `getByTestId("timeline-row").filter({ hasText: "tickets" }).first()` after `correlation_id=walk-acme-4521-close`; no element found. | Repaired before closeout; final default packet passed 6 tests and final light packet passed 2 tests. Current contract uses `ticket_replies` discovery and transaction/row-history links from rendered data. | 181-03 / verified in 181-11 |
| `operator-screenshots.spec.ts` default and light packet commands | `operator-screenshots.spec.ts:176` waited for text `Coverage inspection is not available`; no element found after support-user Coverage visit. | Repaired before closeout; final packet captures Coverage in default and `desktop-chromium-light` lanes using current rendered copy/availability semantics. | 181-03 / verified in 181-11 |
| `operator-responsive-mobile-first.spec.ts` responsive command | `operator-responsive-mobile-first.spec.ts` timed out waiting for `transaction-link` / `timeline-row` after the old `walk-acme-4521-close` correlation filter. | Repaired in Plan 181-11; final bounded responsive command passed 30 tests across `chromium`, `desktop-chromium`, and `mobile-chromium`. | 181-11 |
| `operator-responsive-mobile-first.spec.ts` responsive command | Coverage command-shell, Evidence heading, and 1024 gutter assertions referenced retired or overly broad contracts. | Repaired in Plan 181-11 to target flattened Coverage page sections, exact Evidence heading, visible button typography, and the 1280px gutter breakpoint. | 181-11 |

## Tier B CI Screenshot Allowlist

These remain ledger-owned CI baselines. Plans 01 and 07 did not expand or rebaseline the allowlist.

| Baseline | Ledger ID | Theme | Viewport | Path |
|---|---|---|---:|---|
| `stress-page-home-happy-dark-1024.png` | `page.home.happy` | dark | 1024 | `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-page-home-happy-dark-1024-desktop-chromium.png` |
| `stress-page-timeline-empty-dark-1024.png` | `page.timeline.empty` | dark | 1024 | `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-page-timeline-empty-dark-1024-desktop-chromium.png` |
| `stress-footgun-transaction-desktop-centering-dark-1024.png` | `footgun.transaction-page-left-push-desktop` | dark | 1024 | `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/stress-footgun-transaction-desktop-centering-dark-1024-desktop-chromium.png` |

## Example-App Precommit Failure

`mix precommit` was run from `examples/threadline_phoenix` after the Plan 01 E2E spec change and re-run during Plans 07 and 08 after local screenshot guard work. It failed with 96 tests, 7 failures, all in existing demo-seed/audit-transaction evidence tests:

| Test file | Failure class | Disposition |
|---|---|---|
| `test/threadline_phoenix_web/walkthrough_evidence_test.exs` | Missing #4521 close transaction / row-history evidence query result. | Not caused by Plans 01, 07, or 08; inventory records the failure for 181 guard repair and later verification. |
| `test/threadline_phoenix_web/walkthrough_happy_path_test.exs` | Missing #4518 hard-delete audit transaction. | Not caused by Plans 01, 07, or 08; no Elixir seed, capture, query, auth, Playwright spec, or PNG baseline changed in Plan 08. |
| `test/threadline_phoenix/demo_contract_test.exs` | Missing leaving-agent audit transactions, org_membership actor attribution rows, #4521 close/redaction rows, and #4518 delete row. | Not caused by Plans 01, 07, or 08; same current demo-seed drift class surfaced by earlier rendered screenshot and precommit evidence. |

## Related Specs

- `operator-screenshots.spec.ts` owns Tier C durable packet generation and the durable names: `actor`, `coverage`, `evidence`, `exports`, `home`, `redaction`, `retention`, `row-history`, `timeline`, `timeline-dense`, `timeline-empty`, and `transaction`.
- `operator-screenshot-regression.spec.ts` remains the local-only visual regression guard and was not promoted to a full CI matrix.
- `operator-stress.spec.ts` owns the bounded stress screenshot ratchet and `screenshot_allowlist` contract.
- `operator-phase-178-uat.spec.ts` owns the 320/1440 route sweep and 1024 column-centering cells.
- `operator-responsive-mobile-first.spec.ts` now includes the bounded `desktop-1024` viewport row alongside phone, tablet, and desktop.

## Unexplained Deltas

None. This plan did not compare final images against prior local packet PNGs. Missing packet cells are recorded as command failures with owners instead of being treated as visual deltas.
