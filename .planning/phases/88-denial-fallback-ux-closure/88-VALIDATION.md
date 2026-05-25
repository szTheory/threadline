---
phase: 88
slug: denial-fallback-ux-closure
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T15:40:00Z
---

# Phase 88 — Validation Strategy

> Finalized validation artifact for the denial/fallback UX backfill recorded in
> Phase 93.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix alias verification + CI-surface grep + artifact review |
| **Config file** | `mix.exs`, `config/test.exs`, `.github/workflows/ci.yml`, `.planning/REQUIREMENTS.md` |
| **Quick run command** | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` |
| **Full proof commands** | `mix verify.doc_contract` and `mix verify.example` after the targeted denial/fallback slice |
| **Estimated runtime** | ~10-25 seconds warm for the targeted slice; `mix verify.example` is the slower wave-gate proof band |

---

## Sampling Rate

- After any denial/fallback runtime or test change: run the targeted operator-surface slice.
- After any guide or example wording change affecting fallback posture: run `mix verify.doc_contract`.
- Before closing `AUTH-01`, `UX-01`, and `UX-02`: require the targeted slice, `mix verify.doc_contract`, and `mix verify.example` green on the same tree.
- Max feedback latency: one targeted slice plus the two named rerun commands.

---

## Per-Task Verification Map

| Task ID | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|-------------|------------|-----------------|-----------|-------------------|--------|
| 88-V-01 | AUTH-01, UX-01 | T-93-01 | Support-scoped sessions hide unavailable export affordances while direct export requests still fail with plain-text `403 forbidden`. | mounted integration + controller | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1` | ✅ green |
| 88-V-02 | UX-01 | T-93-01 | Coverage, policy, and retention support-lane gaps render explicit `Unsupported View` fallback messaging instead of silent redirects or blanks. | mounted integration | `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` | ✅ green |
| 88-V-03 | UX-02 | T-93-02 | Public contract surfaces teach the same host-owned denial/fallback story and fallback transports as the runtime proof. | doc-contract | `mix verify.doc_contract` | ✅ green |
| 88-V-04 | AUTH-01, UX-02 | T-93-03 | The nested example host and named rerun surfaces keep export posture and fallback proof discoverable through stable entrypoints. | nested integration + grep | `mix verify.example` plus rerun-surface grep | ✅ green |
| 88-V-05 | AUTH-01, UX-01, UX-02 | T-93-04 | Durable Phase 88 verification artifacts record only the current-tree claim boundary and named proof commands. | artifact review | `rg -n 'AUTH-01|UX-01|UX-02|mix verify\\.doc_contract|mix verify\\.example|403 forbidden|Action Denied|Unsupported View' .planning/phases/88-denial-fallback-ux-closure/88-VERIFICATION.md .planning/phases/88-denial-fallback-ux-closure/88-VALIDATION.md` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Requirement-to-Command Map

| Requirement | Evidence Band | Command | Why This Command Counts |
|-------------|---------------|---------|-------------------------|
| AUTH-01 | Root behavior + example posture | Targeted operator-surface slice plus `mix verify.example` | Proves export is separately privileged in both the root app and the runnable example host. |
| UX-01 | Root behavior | Targeted operator-surface slice | Proves hidden affordances, explicit `Action Denied`, and explicit `Unsupported View` states on the current tree. |
| UX-02 | Public contract + example guidance | `mix verify.doc_contract` and `mix verify.example` | Proves docs, example guidance, and named rerun surfaces tell the same fallback story. |

---

## Commands Actually Used

1. `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1`  
   Result: PASS
2. `mix verify.doc_contract`  
   Result: PASS
3. `mix verify.example`  
   Result: PASS
4. `rg -n 'Request Background Export|forbidden|Action Denied|Unsupported View' test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs`  
   Result: PASS
5. `rg -n 'authorize_fn|scope_query_fn|export_authorize_fn|plain-text \`403\`|Unsupported View|mix threadline.export --dry-run|mix threadline.health.coverage|mix threadline.policy.show' guides/operator-surface.md guides/getting-started-saas.md guides/integration-contracts.md`  
   Result: PASS
6. `rg -n '/support tree|policy DSL|tenancy DSL' guides/operator-surface.md guides/getting-started-saas.md guides/integration-contracts.md`  
   Result: PASS for the guardrail
7. `rg -n 'scope "/audit"|authorize_fn|scope_query_fn|export_authorize_fn' examples/threadline_phoenix/README.md examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`  
   Result: PASS
8. `rg -n 'verify\.example|verify\.doc_contract|ci\.all' mix.exs`  
   Result: PASS
9. `rg -n 'run: mix verify\.example|run: mix verify\.doc_contract|verify-test|verify-docs' .github/workflows/ci.yml`  
   Result: PASS

---

## CI Discoverability

- `mix.exs` exposes `verify.doc_contract` in `preferred_envs`.
- `mix.exs` exposes the `verify.example` alias and keeps it in `ci.all`.
- `.github/workflows/ci.yml` runs both `mix verify.example` and `mix verify.doc_contract` in the verification workflow.

That keeps the Phase 88 proof reproducible through named repo entrypoints
instead of through artifact-only closure language.

---

## Nyquist Notes

- The targeted operator-surface test slice is the fast proof loop for denial and
  fallback behavior.
- `mix verify.doc_contract` is the fast contract drift detector for the public
  fallback story.
- `mix verify.example` remains mandatory at wave boundaries because the nested
  example app is the truthful proof surface for the runnable host posture.
- The final artifact pair closes only after all three proof bands are green and
  the artifact grep confirms the recorded claim matches those commands.

---

## Validation Sign-Off

- [x] All proof-bearing tasks map to named rerun surfaces or explicit artifact checks.
- [x] `AUTH-01` is backed by both root behavior and example-host export posture proof.
- [x] `UX-01` is backed by explicit denial and unsupported-view runtime proof.
- [x] `UX-02` is backed by doc-contract and example guidance proof.
- [x] Commands actually used are recorded exactly.
- [x] No ad-hoc shell-only closure path was required.
- [x] `nyquist_compliant: true` is set only after the proof commands passed.

**Approval:** finalized on 2026-05-25 after current-tree re-verification through the targeted denial/fallback slice, `mix verify.doc_contract`, and `mix verify.example`.
