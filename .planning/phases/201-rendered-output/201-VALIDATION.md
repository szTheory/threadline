---
phase: "201"
slug: "rendered-output"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
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

- **After every task commit:** Run the task's named ExUnit target(s); after markup changes also run the rendered-output contract, and after integrity work run `mix verify.mechanical`.
- **After Wave 1:** Run the new contract, fixture contract, mechanical gate, and renamed shell browser spec. **After Wave 2:** run all five affected LiveView tests and the four selector-coupled Playwright specs. **After Wave 3:** run the final contract/integrity/browser commands.
- **Before `$gsd-verify-work`:** Run root `mix ci.all`, `env -C examples/threadline_phoenix ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix precommit`, corpus/structure equality, and the deterministic browser checks.
- **Max feedback latency:** 180 seconds for the targeted task loop; the phase gate may run longer.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 201-01-01 | 201-01 | 1 | RENDER-01, RENDER-02, RENDER-03 | T-201-01-01, T-201-01-02 | Internal planning vocabulary, attributes, and CSS provenance are absent from owned output without scanning host data. | source + render contract | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix test test/threadline/operator_surface/rendered_output_contract_test.exs` | ❌ planned new file | ⬜ pending execution |
| 201-01-02 | 201-01 | 1 | RENDER-04, RENDER-05, RENDER-06 | T-201-01-04 | Reference artifacts remain immutable while normalized owned structure is demonstrably equal. | integrity + structural receipt | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix verify.mechanical` | ❌ planned new evidence | ⬜ pending execution |
| 201-01-03 | 201-01 | 1 | RENDER-01, RENDER-06 | T-201-01-03 | Shell/Home behavior keeps durable semantic selectors and the stress route remains fail-closed. | browser integration | `npm --prefix examples/threadline_phoenix/e2e exec playwright test -- tests/operator-shell-home.spec.ts` | ✅ after planned rename | ⬜ pending execution |
| 201-02-01..03 | 201-02 | 2 | RENDER-01, RENDER-02, RENDER-06 | T-201-02-01, T-201-02-04 | Five source/ExUnit cohorts and three browser specs migrate atomically to semantic selectors while 21 attributes are removed. | LiveView + browser integration | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/row_history_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/rendered_output_contract_test.exs` | ✅ plus planned contract | ⬜ pending execution |
| 201-03-01 | 201-03 | 3 | RENDER-01 | T-201-03-02 | Critic iteration runbook contract retains behavior under a durable history-preserved name and exact Mix discovery path. | ExUnit contract | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix verify.doc_contract` | ✅ after planned rename | ⬜ pending execution |
| 201-03-02 | 201-03 | 3 | RENDER-01 | T-201-03-02 | CI workflow contract retains behavior under a durable history-preserved name and convention discovery. | ExUnit contract | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/threadline/ci_workflow_parity_contract_test.exs` | ✅ after planned rename | ⬜ pending execution |
| 201-03-03 | 201-03 | 3 | RENDER-01, RENDER-02, RENDER-03, RENDER-04, RENDER-05, RENDER-06 | T-201-03-01, T-201-03-03, T-201-03-04, T-201-03-05 | Static, structural, integrity, behavior, accessibility, and security-preservation contracts pass together. | full phase gate | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix ci.all` | ✅ | ⬜ pending execution |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Threat references are planning labels for the planner to define in each plan's `threat_model`; the plan checker must reconcile them before execution.

---

## Wave 0 Requirements

- [x] Planned in Task 201-01-01: `test/threadline/operator_surface/rendered_output_contract_test.exs` with source-derived zero-allowlist vocabulary/attribute/CSS guard, representative renders, non-vacuity sentinels, and positive controls. The file remains pending execution.
- [x] Planned in Tasks 201-01-01 and 201-01-02: a private structural canonicalizer and pre-edit receipt covering all seven affected rendered nodes. Both remain pending execution.
- [x] Planned in Task 201-01-02 and finalized by 201-03-03: `.planning/audits/201-rendered-output-evidence.md` with landed-commit attribution, normalized hashes/counts, exact manifest path/byte equality, zero exceptions, and no-recapture/no-critic confirmation. The file remains pending execution.
- [x] Planned in Tasks 201-01-03, 201-03-01, and 201-03-02: history-preserved renames and every exact discovery consumer. The renames remain pending execution.

No framework installation is required.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Human review may inspect the evidence artifact, but it is not the sole gate for any requirement.

---

## Validation Sign-Off

- [x] All nine planned tasks have `<automated>` verification with immediate failure directions
- [x] Sampling continuity: every task has automated verification
- [x] Wave 0 requirements are assigned to Tasks 201-01-01/02 and finalization Task 201-03-03; `wave_0_complete` remains false until execution creates the assets
- [x] No watch-mode flags
- [x] Targeted feedback latency is less than 180 seconds; aggregate gates may run longer
- [x] `nyquist_compliant: true` set after plan/task/command reconciliation

**Approval:** planning validation approved 2026-09-13; execution evidence pending
