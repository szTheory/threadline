---
phase: 73
slug: authorization-contract-repair-and-scoped-access-enforcement
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
updated: 2026-05-08T15:35:00Z
---

# Phase 73 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit focused LiveView/controller/auth/doc-contract tests plus full repo verification |
| **Config file** | `mix.exs`; `test/test_helper.exs`; Phoenix test endpoints embedded in focused test modules |
| **Quick run command** | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~20-45 seconds quick, ~90-150 seconds full on warm cache |

---

## Sampling Rate

- **After every task commit:** Run the task-scoped focused command listed below.
- **After every plan wave:** Run the full Phase 73 focused suite plus `mix verify.compile_no_optional`.
- **Before `$gsd-verify-work`:** Run `mix ci.all`.
- **Max feedback latency:** 45 seconds for focused feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 73-01-01 | 01 | 1 | INTEG-03, ADOPT-08 | T-73-01 / T-73-02 | Shared scope callback is threaded through mount/export and narrows timeline/export rows without Threadline-owned role semantics. | unit + integration | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1` | ✅ | ✅ green |
| 73-01-02 | 01 | 1 | INTEG-03, ADOPT-08 | T-73-03 | Actor and transaction flows reject or hide out-of-scope records using the same host callback seam. | LiveView integration | `mix test test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 73-02-01 | 02 | 2 | COMPAT-03, ADOPT-09 | T-73-04 | Example router and guides teach one policy-equivalent shared `authorize_fn` plus host-owned `scope_query_fn`. | doc-contract + source-read | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 73-02-02 | 02 | 2 | COMPAT-02, COMPAT-03 | T-73-05 | Example router source no longer grants any `%Phoenix.LiveView.Socket{}` as an implicit allow path. | doc-contract + grepable source check | `mix test test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 73-03-01 | 03 | 3 | COMPAT-02, INTEG-03, ADOPT-08 | T-73-06 | Phase 71 verification artifact records the final post-fix tree and exact commands proving the repaired contract. | artifact verification | `test -f .planning/phases/71-mount-recipes-and-access-tiers/71-VERIFICATION.md` | ✅ | ✅ green |
| 73-03-02 | 03 | 3 | COMPAT-02 | T-73-07 | Phase 71 validation artifact is finalized from draft state and reflects the scoped-proof surface. | artifact verification | `rg -n '^status: passed|^status: complete' .planning/phases/71-mount-recipes-and-access-tiers/71-VALIDATION.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/73-authorization-contract-repair-and-scoped-access-enforcement/73-RESEARCH.md`
- [x] `.planning/phases/73-authorization-contract-repair-and-scoped-access-enforcement/73-PATTERNS.md`
- [x] `.planning/phases/73-authorization-contract-repair-and-scoped-access-enforcement/73-VALIDATION.md`
- [x] Existing focused auth, controller, LiveView, and doc-contract test suites identified for extension.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review that the support-read-only recipe still feels host-owned rather than Threadline-owned | ADOPT-08, INTEG-03 | The difference between “host-owned scoping seam” and “Threadline role DSL” is partly architectural prose, not just literals | Confirm the final docs describe `scope_query_fn` as a host callback, keep `scope` opaque, and do not define built-in roles or organization semantics. |

---

## Validation Sign-Off

- [x] All planned tasks have explicit automated verification coverage or artifact checks.
- [x] Sampling continuity: no wave ends without a focused automated suite.
- [x] Wave 0 covers the required planning artifacts.
- [x] No watch-mode commands are required.
- [x] Feedback latency target stays under 45 seconds for focused runs.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-08 after the repaired proof surface, compile-no-optional gate, and full repo gate all passed.

**Final Notes:**

- `73-VERIFICATION.md` now records the phase-level truth table and requirement coverage.
- The Phase 71 missing-artifact audit findings are now materially closed on the repaired tree.
