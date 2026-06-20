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
| **Focused browser command** | `mix verify.operator_stress` after Plan 171-04 creates the alias; until then use `mix verify.example_browser -- operator-stress.spec.ts` as the equivalent subset |
| **Full suite command** | `mix ci.all && mix verify.example_browser && (cd examples/threadline_phoenix && mix precommit)` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs`
- **After browser-task commits:** Run `mix verify.operator_stress`; before the alias exists, run `mix verify.example_browser -- operator-stress.spec.ts`
- **After every plan wave:** Run `mix ci.all && mix verify.example_browser`; after waves that touch `examples/threadline_phoenix`, also run `(cd examples/threadline_phoenix && mix precommit)`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds for full wave feedback; under 30 seconds for the focused ExUnit lane once files exist

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 171-01-01 | 01 | 1 | DS-04 | T-171-04, T-171-08, T-171-09 | Fixture tests prove static synthetic data, sorted IDs, no user-input atom conversion, and future-owned folded cases | ExUnit fixture contract | `mix test test/threadline/operator_surface/stress_fixtures_test.exs` | no - W0 | pending |
| 171-01-02 | 01 | 1 | DS-01, DS-04 | T-171-04, T-171-08, T-171-09 | Fixture registry implements DS-04 matrix and has story/reserved-placeholder coverage for every planned ledger inventory entry | ExUnit fixture contract | `mix test test/threadline/operator_surface/stress_fixtures_test.exs` | no - W0 | pending |
| 171-02-01 | 02 | 2 | DS-01, DS-02, DS-03, DS-04 | T-171-05, T-171-06, T-171-10 | Ledger tests define JSON schema, sorted entries, ratchet semantics, bidirectional fixture/story round-trip, allowlist shape, and markdown freshness | ExUnit source/doc contract | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | no - W0 | pending |
| 171-02-02 | 02 | 2 | DS-01, DS-02, DS-03, DS-04 | T-171-05, T-171-06, T-171-10 | JSON ledger and DESIGN-SYSTEM projection satisfy ratchet, freshness, and ledger-to-renderable-story coverage contracts | ExUnit ratchet contract | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | no - W0 | pending |
| 171-03-01 | 03 | 3 | DS-01 | T-171-01, T-171-02, T-171-03, T-171-11 | Router tests prove dev/test route, real prod compile failure, auth reuse, no public `stress: true`, and safe params | ExUnit router contract | `mix test test/threadline/operator_surface/stress_router_test.exs` | no - W0 | pending |
| 171-03-02 | 03 | 3 | DS-01, DS-02, DS-03, DS-04 | T-171-01, T-171-02, T-171-03 | Stress router and LiveView render every ledger-owned fixture story or reserved placeholder through authenticated operator shell | ExUnit route/render contract | `mix test test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs` | no - W0 | pending |
| 171-04-01 | 04 | 4 | DS-01, DS-03, DS-04 | T-171-13, T-171-14 | Browser semantics prove auth, shell/theme, safe params, reserved cases, and viewport no-overflow | Playwright semantic | `mix verify.operator_stress` | no - W0 | pending |
| 171-04-02 | 04 | 4 | DS-03 | T-171-07, T-171-12, T-171-14 | Screenshot allowlist is exactly three dark/1024 ledger-owned baselines with reduced motion and masks | Playwright screenshot + ExUnit ledger | `mix test test/threadline/operator_surface/stress_ledger_test.exs && mix verify.operator_stress` | no - W0 | pending |

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/stress_router_test.exs` - DS-01 compile/route/auth gate tests.
- [ ] `test/threadline/operator_surface/stress_fixtures_test.exs` - DS-04 matrix completeness and assign-shape drift tests.
- [ ] `test/threadline/operator_surface/stress_ledger_test.exs` - DS-02 inventory freshness and DS-03 ledger ratchet tests.
- [ ] `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` - DS-01 semantic route/auth/theme/viewport checks and DS-03 bounded screenshot allowlist.
- [ ] `mix.exs` alias `verify.operator_stress` - focused wrapper for `operator-stress.spec.ts`, created by Plan 171-04 before browser assertions are treated as per-task feedback.

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
