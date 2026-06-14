---
phase: 171
slug: audit-baseline-stress-lab-harness-idempotency-ledger
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-14
---

# Phase 171 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit for library contracts; Playwright for example-app browser semantics and bounded screenshots |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs` |
| **Full suite command** | `mix ci.all && mix verify.example_browser` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs`
- **After every plan wave:** Run `mix ci.all && mix verify.example_browser`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds for full wave feedback; under 30 seconds for the focused ExUnit lane once files exist

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 171-01-01 | 01 | 1 | DS-01 | T-171-01 | `/audit/__stress` compiles only in dev/test and is absent or compile-blocked in prod | ExUnit router contract | `mix test test/threadline/operator_surface/stress_router_test.exs` | no - W0 | pending |
| 171-01-02 | 01 | 1 | DS-01 | T-171-02 | Stress LiveView reuses authenticated operator shell, `on_mount` auth, `.threadline-ui`, and `data-tl-theme` | Playwright semantic | `mix verify.example_browser` | no - W0 | pending |
| 171-02-01 | 02 | 1 | DS-04 | T-171-04 | Static fixtures are synthetic, deterministic, stable-ID data and do not depend on live DB rows | ExUnit fixture contract | `mix test test/threadline/operator_surface/stress_fixtures_test.exs` | no - W0 | pending |
| 171-03-01 | 03 | 1 | DS-02 | T-171-05 | `DESIGN-SYSTEM.md` is fresh from the JSON ledger/story registry and inventories required item classes | ExUnit source/doc contract | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | no - W0 | pending |
| 171-03-02 | 03 | 1 | DS-03 | T-171-06 | Ledger schema, order, score ratchet, deletions, and explicit reset rationale are enforced | ExUnit ratchet contract | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | no - W0 | pending |
| 171-04-01 | 04 | 2 | DS-03 | T-171-07 | Screenshot allowlist is bounded, ledger-owned, deterministic, reduced-motion, and pinned to the example Playwright lane | Playwright screenshot | `mix verify.example_browser` | no - W0 | pending |

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/stress_router_test.exs` - DS-01 compile/route/auth gate tests.
- [ ] `test/threadline/operator_surface/stress_fixtures_test.exs` - DS-04 matrix completeness and assign-shape drift tests.
- [ ] `test/threadline/operator_surface/stress_ledger_test.exs` - DS-02 inventory freshness and DS-03 ledger ratchet tests.
- [ ] `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - DS-01 semantic route/auth/theme/viewport checks and DS-03 bounded screenshot allowlist.
- [ ] Optional Mix alias `verify.operator_stress` or documented `mix verify.example_browser` stress subset if a named phase gate keeps feedback faster.

Existing ExUnit, Jason, Phoenix/LiveView test support, and Playwright infrastructure cover the phase. No new test framework or runtime dependency is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | DS-01, DS-02, DS-03, DS-04 | All phase behaviors require automated proof through ExUnit or Playwright | N/A |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency under 180 seconds for full wave feedback.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-14
