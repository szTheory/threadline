---
phase: 90
slug: phase-85-verification-backfill
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-25
---

# Phase 90 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 90 is a verification-backfill slice. The main risks are restating the
> old Phase 85 intent instead of the current-tree truth, proving only docs while
> skipping the shared callback contract, and marking milestone requirements
> complete without updating the active planning surface honestly.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit doc-contract tests, operator auth/export contract tests, focused root support-surface behavior tests, example-host proof via Mix alias, and planning-artifact grep verification |
| **Config file** | `mix.exs`, `config/test.exs`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs --max-failures 1` |
| **Full suite command** | `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1 && mix verify.example` |
| **Estimated runtime** | ~20-40 seconds warm, depending on example app compilation |

---

## Sampling Rate

- After any guide/example/test truth repair in `90-01`: run the quick suite.
- Before finalizing `85-VERIFICATION.md`: run the full suite including the
  example-host proof.
- After writing `85-VALIDATION.md` and milestone bookkeeping in `90-02`: grep
  the updated planning artifacts for the exact requirement and status strings.
- Max feedback latency: under 40 seconds for the targeted commands in this
  phase.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 90-01-01 | 01 | 1 | SCOPE-03, ADOPT-03 | T-90-01 / T-90-03 | Public claim surfaces only name the currently proven support-lane scope, keep support row-history / as-of explicitly unclaimed, and preserve the minimal additive-controls posture with no Threadline-owned DSL. | doc-contract | `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 90-01-02 | 01 | 1 | AUTH-02 | T-90-02 | The shared `%{assigns: assigns}` contract, export override posture, telemetry outcomes, and claimed read-surface behavior are verified on the current tree and recorded in `85-VERIFICATION.md`. | contract + behavior + example | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1 && mix verify.example && rg -n 'SCOPE-03|AUTH-02|ADOPT-03|shared `%\\{assigns: assigns\\}` callback|unclaimed|Not closed here|SCOPE-01|SCOPE-02|ADOPT-01|ADOPT-02|AUTH-01|UX-01|UX-02|DOC-01|DOC-02' .planning/phases/85-support-lane-surface-audit/85-VERIFICATION.md` | ✅ | ⬜ pending |
| 90-02-01 | 02 | 2 | SCOPE-03, AUTH-02, ADOPT-03 | T-90-04 | `85-VALIDATION.md` records the actual proof commands and Nyquist map for the closed Phase 85 requirements. | artifact review | `rg -n '^phase: 85|^nyquist_compliant: true|SCOPE-03|AUTH-02|ADOPT-03|mix verify\\.example|export_auth_plug_test\\.exs|timeline_live_test\\.exs|export_controller_test\\.exs' .planning/phases/85-support-lane-surface-audit/85-VALIDATION.md` | ❌ W0 | ⬜ pending |
| 90-02-02 | 02 | 2 | SCOPE-03, AUTH-02, ADOPT-03 | T-90-04 | Active milestone artifacts mark only the Phase 90 closures complete and leave later verification debt pending. | planning artifact | `rg -n 'SCOPE-03 \\| Phase 90 \\| Complete|AUTH-02 \\| Phase 90 \\| Complete|ADOPT-03 \\| Phase 90 \\| Complete' .planning/REQUIREMENTS.md && rg -n '\\[x\\] 90-01: Re-verify Phase 85 support-lane claim, callback contract, and minimal-controls boundary|\\[x\\] 90-02: Add Phase 85 verification artifact and requirement closure evidence' .planning/ROADMAP.md && ! rg -n 'Start Phase 85|Phase 89 \\(contract-lock-final-verification\\) — EXECUTING|Status: Executing Phase 89' .planning/STATE.md && rg -n 'Phase 91|completed_phases:|completed_plans:|percent:' .planning/STATE.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit doc-contract and operator-surface contract tests cover the
  required proof surfaces.
- [x] Existing example-host proof is available through `mix verify.example`,
  which is the correct repo-root entrypoint for the nested example app tests.
- [ ] `.planning/phases/85-support-lane-surface-audit/85-VERIFICATION.md` —
  to be created in `90-01`.
- [ ] `.planning/phases/85-support-lane-surface-audit/85-VALIDATION.md` —
  to be created in `90-02`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Distinguish Phase 85 closure from later-phase closure | SCOPE-03, AUTH-02, ADOPT-03 | The phase boundary is a milestone-truth judgment, not just a grep result. | After updating `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md`, confirm that only `SCOPE-03`, `AUTH-02`, and `ADOPT-03` move to complete and that later requirements remain pending until Phases 91-94 are verified. |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All planned tasks have explicit automated verification coverage.
- [x] Sampling continuity stays below the three-task Nyquist gap.
- [x] No watch-mode or non-deterministic verification commands are required.
- [ ] `nyquist_compliant: true` will be set after execution evidence is recorded.

**Approval:** pending
