---
phase: "201"
slug: "rendered-output"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-13"
---

# Phase 201 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.17.3 and Playwright 1.60.0 |
| **Config file** | `mix.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/threadline/operator_surface/rendered_output_contract_test.exs` |
| **Full suite command** | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix ci.all` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the new rendered-output contract plus the directly affected LiveView test file; run `mix verify.mechanical` after markup or CSS changes.
- **After every plan wave:** Run all seven affected render scenarios and the four selector-coupled Playwright specs in both desktop and mobile Chromium.
- **Before `$gsd-verify-work`:** `mix ci.all`, the example application's `mix precommit`, corpus integrity, normalized structure, and the deterministic browser checks must be green.
- **Max feedback latency:** 180 seconds for the targeted task loop; the phase gate may run longer.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 201-W0-01 | TBD | 0 | RENDER-01, RENDER-02, RENDER-03 | T-201-01 | Internal planning vocabulary, attributes, and CSS provenance are absent from owned output without scanning host data. | source + render contract | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/threadline/operator_surface/rendered_output_contract_test.exs` | ❌ W0 | ⬜ pending |
| 201-W0-02 | TBD | 0 | RENDER-05, RENDER-06 | T-201-02 | Reference artifacts remain immutable while normalized owned structure is demonstrably equal. | integrity + structural receipt | `test -f .planning/audits/201-rendered-output-evidence.md` | ❌ W0 | ⬜ pending |
| 201-SEL-01 | TBD | TBD | RENDER-02, RENDER-06 | T-201-03 | Selector migration preserves behavior, route restrictions, authentication hooks, responsive layout, and accessibility. | LiveView + browser integration | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/threadline/operator_surface/live/{start_live_test,export_status_live_test,evidence_live_test,row_history_live_test,timeline_live_test}.exs test/threadline/operator_surface/stress_router_test.exs` | ✅ | ⬜ pending |
| 201-MECH-01 | TBD | TBD | RENDER-04, RENDER-05 | T-201-02 | Fixture bytes and deterministic mechanical floors remain unchanged; no recapture path runs. | integrity + deterministic gate | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs && ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix verify.mechanical` | ✅ | ⬜ pending |
| 201-E2E-01 | TBD | TBD | RENDER-02, RENDER-06 | T-201-03 | Operator workflows remain usable at desktop and mobile widths without overflow or accessibility regression. | Playwright end to end | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-earned-flows.spec.ts operator-home-nav-mobile.spec.ts operator-shell-home.spec.ts operator-responsive-mobile-first.spec.ts` | ✅ after planned rename | ⬜ pending |
| 201-GATE-01 | TBD | TBD | RENDER-01, RENDER-02, RENDER-03, RENDER-04, RENDER-05, RENDER-06 | T-201-01, T-201-02, T-201-03 | All static, structural, integrity, behavior, accessibility, and security-preservation contracts pass together. | full phase gate | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Threat references are planning labels for the planner to define in each plan's `threat_model`; the plan checker must reconcile them before execution.

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/rendered_output_contract_test.exs` — source-derived zero-allowlist vocabulary/attribute/CSS guard, representative renders, non-vacuity sentinels, and synthetic positive controls for RENDER-01, RENDER-02, and RENDER-03.
- [ ] A narrow private structural canonicalizer and a pre-edit receipt covering all seven affected rendered nodes for RENDER-06.
- [ ] `.planning/audits/201-rendered-output-evidence.md` — landed-commit attribution, pre/post normalized hashes and counts, fixture manifest hash, exact commands and results, exception count, and explicit confirmation that no recapture or paid-critic path ran for RENDER-04, RENDER-05, and RENDER-06.
- [ ] Update exact test-discovery references after renaming the two residual roadmap-named test files.

No framework installation is required.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Human review may inspect the evidence artifact, but it is not the sole gate for any requirement.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Targeted feedback latency is less than 180 seconds
- [ ] `nyquist_compliant: true` set in frontmatter after plan-task reconciliation

**Approval:** pending
