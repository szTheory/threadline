---
phase: 139
slug: orientation-hub-home-nav
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
---

# Phase 139 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `139-RESEARCH.md` Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest; Playwright through the example app E2E suite |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Browser UAT command** | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` |
| **Estimated runtime** | Focused ExUnit under 60 seconds; browser UAT depends on the example app already running on port 4002 |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit command named in the task's `<verify><automated>` block.
- **After every plan wave:** Run all focused ExUnit checks for completed waves; after Plan 03 exists, run the browser UAT command.
- **Before `$gsd-verify-work`:** Run the focused ExUnit set plus the Home/nav mobile browser spec, and record any unavailable example-app service explicitly.
- **Max feedback latency:** no more than one task without an automated focused verification command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 139-01-01 | 139-01 | 1 | POLISH-HOME | T-139-01 / T-139-02 / T-139-03 | Header preserves feature flags, scope chip, coverage badge, skip link, brand Home link, and single active state | component | `mix test test/threadline/operator_surface/surface_header_test.exs` | no - Wave 0 creates | pending |
| 139-01-02 | 139-01 | 1 | POLISH-HOME | T-139-01 / T-139-04 | CSS-only scrollable grouped nav keeps labels and enabled destinations reachable at 375px without new JS state | component + style contract | `mix test test/threadline/operator_surface/surface_header_test.exs test/threadline/operator_surface/style_contract_test.exs` | partial - style contract exists | pending |
| 139-02-01 | 139-02 | 2 | POLISH-HOME | T-139-05 / T-139-06 / T-139-07 | Home saved views and failed-export health stay actor-scoped; Phase 140 input flows stay absent; F-302 topbar count vs Home recovery/action role is executable | LiveView + source contract | `mix test test/threadline/operator_surface/live/start_live_test.exs` | no - Wave 0 creates | pending |
| 139-02-02 | 139-02 | 2 | POLISH-HOME | T-139-05 / T-139-06 / T-139-08 | Home health is severity-aware, quiet when clear, and does not duplicate the topbar coverage badge as the same count/role | LiveView + style contract | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs` | partial - style contract exists | pending |
| 139-03-01 | 139-03 | 3 | POLISH-HOME | T-139-09 / T-139-10 | Browser UAT proves Home orientation and no Phase 140 form/input leakage at 375px | Playwright | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` | no - Wave 0 creates | pending |
| 139-03-02 | 139-03 | 3 | POLISH-HOME | T-139-09 / T-139-11 | Browser UAT proves every enabled nav destination and group label is reachable from representative screens at 375px | Playwright | `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` | no - Wave 0 creates | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/surface_header_test.exs` - header IA, group labels, feature flags, scope chip, coverage badge, Exports handoff, and active state.
- [ ] `test/threadline/operator_surface/live/start_live_test.exs` - Home orientation, health severity, F-302 topbar/Home coverage role distinction, saved-view resume links, actor isolation, and Phase 140 non-leakage.
- [ ] Extend `test/threadline/operator_surface/style_contract_test.exs` - Phase 139 topbar/Home scoped token-backed CSS primitives.
- [ ] `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` - 375px Home orientation and nav reachability.

---

## Phase Requirement to Test Map

| Req ID | Behavior | Primary Plan | Automated Proof |
|--------|----------|--------------|-----------------|
| POLISH-HOME | Header active state, feature-flag visibility, brand Home link, skip link, scope chip, coverage badge, and Find / Verify / Prove grouping | 139-01 | `mix test test/threadline/operator_surface/surface_header_test.exs` |
| POLISH-HOME | Existing CSS-only scrollable grouped nav preserves labels and all enabled destinations at 375px | 139-01, 139-03 | `mix test test/threadline/operator_surface/style_contract_test.exs` plus `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-home-nav-mobile.spec.ts` |
| POLISH-HOME | Home cards keep Find / Verify / Prove families and link only to existing destinations without implying Phase 140 flows | 139-02, 139-03 | `mix test test/threadline/operator_surface/live/start_live_test.exs` plus browser UAT |
| POLISH-HOME | Home health is quiet when clear, severity-aware when unhealthy, and differentiates F-302 coverage health from the topbar badge count/role | 139-02 | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/style_contract_test.exs` |
| POLISH-HOME | Actor-owned saved views render as resume affordances and other actors' saved views do not leak | 139-02, 139-03 | `mix test test/threadline/operator_surface/live/start_live_test.exs` plus browser UAT |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final visual comfort of the scrollable grouped nav | POLISH-HOME | Automated checks prove reachability and overflow; final scan quality can benefit from viewport inspection | Inspect `/audit`, `/audit/timeline`, `/audit/coverage`, `/audit/evidence`, `/audit/policy/redaction`, `/audit/policy/retention`, and `/audit/exports` at 375px after the Playwright spec is green. Confirm labels remain understandable and Retention/Exports are not visually lost. |
| Home card copy persona fit | POLISH-HOME | Tests can block forbidden flows and required destinations, but copy quality still needs a human first-scan read | Confirm Find / Verify / Prove cards orient P1-P5 to existing actions only and do not imply record lookup, correlation paste, export loop, or row-history entry flows. |

---

## Validation Sign-Off

- [x] All planned task families have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers missing ExUnit, style-contract, and Playwright files.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded to focused ExUnit per task and one focused browser spec after the example app is available.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** planner-bound 2026-06-04; checker to confirm.
