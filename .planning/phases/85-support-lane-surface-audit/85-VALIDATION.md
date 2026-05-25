---
phase: 85
slug: support-lane-surface-audit
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T07:21:09Z
---

# Phase 85 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> This final artifact records the actual current-tree proof commands used by Phase 90 to close the missing Phase 85 verification chain for `SCOPE-03`, `AUTH-02`, and `ADOPT-03`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit doc-contract tests, operator auth/export contract tests, focused mounted support-surface tests, example-host proof via Mix alias, and planning-artifact review |
| **Config file** | `mix.exs`, `config/test.exs`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` |
| **Contract + behavior proof** | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1` |
| **Example-host proof** | `mix verify.example` |
| **Estimated runtime** | ~10 seconds warm for the commands actually used |

---

## Sampling Rate

- After confirming the Phase 85 proof surfaces stayed truthful: run the doc-contract suite.
- Before writing the final verification verdict: run the focused callback and mounted-surface proof command.
- Before final bookkeeping closure: run `mix verify.example` so the example host remains part of the evidence chain.
- Max feedback latency: under 10 seconds for the targeted commands actually used in this closure pass.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 85-V-01 | 90-01 | 1 | `SCOPE-03`, `ADOPT-03` | T-90-01 / T-90-03 | Public claim surfaces keep one shared `/audit` mount, keep support-scoped row history / as-of explicitly `unclaimed`, and preserve the minimal additive host-owned control posture. | doc-contract | `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 85-V-02 | 90-01 | 1 | `AUTH-02` | T-90-02 | The shared `%{assigns: assigns}` callback, export mirror fallback, telemetry outcomes, and claimed mounted support behavior remain proven on the current tree. | contract + behavior | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 85-V-03 | 90-01 | 1 | `ADOPT-03` | T-90-03 | The example host still proves one shared `/audit` mount with host-owned scope and default export denial, without introducing a Threadline-owned DSL or separate support tree. | example-host | `mix verify.example` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Commands Actually Used

1. `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`
   Result: PASS
2. `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1`
   Result: PASS
3. `mix verify.example`
   Result: PASS

---

## Requirement Coverage

- `SCOPE-03`: Closed here through the explicit current-tree support-lane claim boundary and the `unclaimed` row-history / as-of wording.
- `AUTH-02`: Closed here through the shared callback contract and stable granted / denied / error telemetry outcomes.
- `ADOPT-03`: Closed here through the minimal additive controls posture and the verified example-host proof.

This artifact does **not** claim closure for `SCOPE-01`, `SCOPE-02`, `AUTH-01`, `ADOPT-01`, `ADOPT-02`, `UX-01`, `UX-02`, `DOC-01`, or `DOC-02`.

---

## Validation Sign-Off

- [x] All closed requirements have explicit automated verification evidence.
- [x] Commands actually used are recorded exactly, including `auth_test.exs`, `export_auth_plug_test.exs`, `timeline_live_test.exs`, `export_controller_test.exs`, and `mix verify.example`.
- [x] Sampling continuity stayed below the three-task Nyquist gap.
- [x] `nyquist_compliant: true` is set in frontmatter.
- [x] Closure remains narrow and does not overclaim later-phase support-lane work.

**Approval:** finalized on 2026-05-25 for the Phase 85 verification backfill executed in Phase 90.
