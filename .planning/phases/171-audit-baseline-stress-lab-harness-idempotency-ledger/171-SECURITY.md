---
phase: 171-audit-baseline-stress-lab-harness-idempotency-ledger
phase_number: 171
phase_name: "Audit Baseline, Stress-Lab Harness & Idempotency Ledger"
audited: 2026-06-14
asvs_level: standard
block_on: open_threats
register_authored_at_plan_time: true
threats_total: 18
threats_closed: 18
threats_open: 0
unregistered_flags: 0
status: secured
---

# Phase 171 Security Verification

Plan-time threat mitigations were verified against implementation code and tests. Documentation-only intent was not accepted as closure.

## Threat Verification

| Threat ID | Plan | Category | Component | Disposition | Status | Evidence |
|---|---:|---|---|---|---|---|
| T-171-04 | 01 | Information Disclosure | `StressFixtures` | mitigate | CLOSED | Synthetic-only source guard refutes `ThreadlinePhoenix`, `Repo.`, `Ecto.Query`, `String.to_atom`, Storybook/Tailwind, and package registries in `test/threadline/operator_surface/stress_fixtures_test.exs:148`; direct `rg` over `lib/threadline/operator_surface/stress_fixtures.ex` returned no matches for those terms. |
| T-171-08 | 01 | Tampering | story ID registry | mitigate | CLOSED | Unique sorted story/ledger IDs and exact folded-todo reserved IDs are enforced in `test/threadline/operator_surface/stress_fixtures_test.exs:101` and `test/threadline/operator_surface/stress_fixtures_test.exs:142`. |
| T-171-09 | 01 | Denial of Service | `by_id/1`, `assigns_for/1` | mitigate | CLOSED | Unknown string lookup returns `:error` in `lib/threadline/operator_surface/stress_fixtures.ex:136`; unknown assigns return `{:error, :unknown_story}` in `lib/threadline/operator_surface/stress_fixtures.ex:158` and `lib/threadline/operator_surface/stress_fixtures.ex:213`; source guard refutes `String.to_atom` at `test/threadline/operator_surface/stress_fixtures_test.exs:155`. |
| T-171-SC | 01 | Tampering | package installs | mitigate | CLOSED | Plan 01 summary declares no tech-stack additions; package-registry source guard refutes `npmjs.com`, `hex.pm/packages`, and `pypi.org` in `test/threadline/operator_surface/stress_fixtures_test.exs:164`. |
| T-171-05 | 02 | Tampering | `.planning/design-system-ledger.json` | mitigate | CLOSED | Ledger schema/order and ratchet assertions enforce sorted IDs, required keys, `current_score >= ratchet_score`, locked IDs, minimum scores, and reset rationale in `test/threadline/operator_surface/stress_ledger_test.exs:81`, `test/threadline/operator_surface/stress_ledger_test.exs:101`, and `test/threadline/operator_surface/stress_ledger_test.exs:128`. |
| T-171-06 | 02 | Repudiation | `DESIGN-SYSTEM.md` projection | mitigate | CLOSED | Freshness test projects every ledger row into markdown and fails missing rows in `test/threadline/operator_surface/stress_ledger_test.exs:210`. |
| T-171-10 | 02 | Information Disclosure | ledger notes and fixture refs | mitigate | CLOSED | Ledger entries use `source: "Threadline.OperatorSurface.StressFixtures"` and fixture/story IDs, e.g. `.planning/design-system-ledger.json:1002`; forbidden external/service terms are refuted for ledger and projection in `test/threadline/operator_surface/stress_ledger_test.exs:221`. |
| T-171-SC | 02 | Tampering | package installs | mitigate | CLOSED | Plan 02 summary declares no tech-stack additions; no dependency/package install artifacts were introduced in ledger/projection tests. Existing dependency list is unchanged in `mix.exs:52`. |
| T-171-01 | 03 | Information Disclosure / Elevation of Privilege | `StressRouter.threadline_operator_surface_stress/2` | mitigate | CLOSED | Macro raises `CompileError` for `:prod` in `lib/threadline/operator_surface/stress_router.ex:17`; prod compile test verifies failure in `test/threadline/operator_surface/stress_router_test.exs:248`; example route is mounted under authenticated `/audit` scopes at `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:179` and `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:213`. |
| T-171-02 | 03 | Elevation of Privilege | `StressLive` navigation | mitigate | CLOSED | Stress macro uses `live_session :threadline_stress` with existing Auth and Coverage `on_mount` hooks in `lib/threadline/operator_surface/stress_router.ex:27`; unauthenticated route test refutes stress-lab HTML at `test/threadline/operator_surface/stress_router_test.exs:337`. |
| T-171-03 | 03 | Denial of Service | `StressLive.handle_params/3` | mitigate | CLOSED | Category/status/theme/viewport params use closed allowlists in `lib/threadline/operator_surface/live/stress_live.ex:10` and `lib/threadline/operator_surface/live/stress_live.ex:39`; story selection is constrained to visible stories in `lib/threadline/operator_surface/live/stress_live.ex:262`; unknown-param test passes without rendering attacker strings in `test/threadline/operator_surface/stress_router_test.exs:323`; stress source guard refutes `String.to_atom` in `test/threadline/operator_surface/stress_router_test.exs:366`. |
| T-171-11 | 03 | Spoofing / Tampering | route namespace helpers | mitigate | CLOSED | Macro scopes with `as: false` and `live_session :threadline_stress` in `lib/threadline/operator_surface/stress_router.ex:27`; route test verifies distinct session and no public `stress: true` option in `test/threadline/operator_surface/stress_router_test.exs:267`. |
| T-171-SC | 03 | Tampering | package installs | mitigate | CLOSED | Stress implementation uses existing Phoenix/LiveView/Jason surfaces; source guard refutes Storybook/Tailwind/visual-service deps in `test/threadline/operator_surface/stress_router_test.exs:366`; no public `stress: true` expansion is verified in `test/threadline/operator_surface/stress_router_test.exs:260`. |
| T-171-07 | 04 | Tampering / Repudiation | screenshot allowlist | mitigate | CLOSED | Playwright reads `.planning/design-system-ledger.json` at `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:8`, compares CI allowlist exactly and verifies baseline files in `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:214`; ExUnit verifies allowlist references ledger entries in `test/threadline/operator_surface/stress_ledger_test.exs:182`. |
| T-171-12 | 04 | Denial of Service | screenshot CI lane | mitigate | CLOSED | CI allowlist has exactly three dark/1024 entries in `.planning/design-system-ledger.json:1002`; screenshots skip outside `desktop-chromium`, set 1024 viewport, use `maxDiffPixelRatio: 0.01`, and mask only volatile selectors in `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:51` and `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:178`. |
| T-171-13 | 04 | Elevation of Privilege | browser auth path | mitigate | CLOSED | Browser test verifies unauthenticated `/audit/__stress` reaches login and does not render `stress-lab` in `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:77`; authenticated route asserts `operator-header` in `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:92`. |
| T-171-14 | 04 | Information Disclosure | screenshots and masks | mitigate | CLOSED | Browser screenshot targets use synthetic fixture stories from the ledger allowlist in `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:13`; masks are limited to `time`, `[data-dynamic="true"]`, and optional `stress-run-id` in `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:51`. |
| T-171-SC | 04 | Tampering | package installs | mitigate | CLOSED | Browser spec imports existing `@playwright/test` in `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:1`; focused alias only delegates to existing browser harness in `mix.exs:89` and `mix.exs:190`; light-lane config includes stress spec without new package config in `examples/threadline_phoenix/e2e/playwright.config.ts:23`. |

## Unregistered Flags

None. All `## Threat Flags` sections in `171-01-SUMMARY.md` through `171-04-SUMMARY.md` report no new unmapped attack surface.

## Accepted Risks

None.

## Transfer Documentation

None. No registered Phase 171 threats use `transfer` disposition.

## Audit Trail

| Date | Auditor | Result | Closed | Open |
|---|---|---|---:|---:|
| 2026-06-14 | Codex security auditor | SECURED | 18 | 0 |
