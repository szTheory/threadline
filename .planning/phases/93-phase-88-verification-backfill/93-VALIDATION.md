---
phase: 93
slug: phase-88-verification-backfill
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T15:40:00Z
---

# Phase 93 — Validation Strategy

> Finalized validation contract for the Phase 88 verification backfill.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix alias verification + planning-artifact review |
| **Config file** | `mix.exs`, `config/test.exs`, `.github/workflows/ci.yml`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` |
| **Quick run command** | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` |
| **Full proof commands** | `mix verify.doc_contract` and `mix verify.example` |
| **Estimated runtime** | ~10-25 seconds warm, plus the example-host verification band |

---

## Sampling Rate

- After any runtime denial/fallback drift fix in Wave 1: rerun the targeted operator-surface slice immediately.
- After any guide or example wording drift fix in Wave 1: rerun `mix verify.doc_contract`.
- After Wave 1 settles: require `mix verify.example` before writing authority-surface closure artifacts.
- Before final sign-off: grep the Phase 88 artifacts and active planning surfaces for `AUTH-01`, `UX-01`, and `UX-02`.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 93-01-01 | 01 | 1 | AUTH-01, UX-01 | T-93-01 | The current tree still proves hidden export affordances, direct HTTP `403 forbidden`, explicit `Action Denied`, and explicit `Unsupported View` fallback states. | targeted runtime proof | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 93-01-02 | 01 | 1 | UX-02 | T-93-02 | Public contract surfaces still teach the same host-owned denial/fallback story and truthful fallback transports. | doc-contract | `mix verify.doc_contract` | ✅ | ✅ green |
| 93-01-03 | 01 | 1 | AUTH-01, UX-02 | T-93-03 | The example Phoenix host and named rerun surfaces still prove the shared `/audit` posture and discoverable verification path. | nested integration + grep | `mix verify.example` plus rerun-surface grep | ✅ | ✅ green |
| 93-02-01 | 02 | 2 | AUTH-01, UX-01, UX-02 | T-93-04 | `88-VERIFICATION.md` and `88-VALIDATION.md` record only the current-tree denial/fallback claim boundary and named proof commands. | artifact review | `rg -n 'AUTH-01|UX-01|UX-02|mix verify\\.doc_contract|mix verify\\.example|403 forbidden|Action Denied|Unsupported View' .planning/phases/88-denial-fallback-ux-closure/88-VERIFICATION.md .planning/phases/88-denial-fallback-ux-closure/88-VALIDATION.md` | ✅ | ✅ green |
| 93-02-02 | 02 | 2 | AUTH-01, UX-01, UX-02 | T-93-04 | Active planning surfaces mark only the Phase 93 requirement closures complete and keep later Phase 94 authority work pending. | planning artifact | `rg -n 'AUTH-01 \\| Phase 93 \\| Complete|UX-01 \\| Phase 93 \\| Complete|UX-02 \\| Phase 93 \\| Complete' .planning/REQUIREMENTS.md && rg -n '\\[x\\] 93-01: Re-verify export denial, fallback UX, and support-lane guidance on the current tree|\\[x\\] 93-02: Add Phase 88 verification artifact and requirement closure evidence' .planning/ROADMAP.md && rg -n 'AUTH-01 / AUTH-02|UX-01 / UX-02 / DOC-01 / DOC-02|Phase 94' .planning/PROJECT.md .planning/STATE.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

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
10. `rg -n 'AUTH-01|UX-01|UX-02|mix verify\.doc_contract|mix verify\.example|403 forbidden|Action Denied|Unsupported View' .planning/phases/88-denial-fallback-ux-closure/88-VERIFICATION.md .planning/phases/88-denial-fallback-ux-closure/88-VALIDATION.md`  
    Result: PASS

---

## Validation Sign-Off

- [x] All execution tasks point back to named rerun surfaces or explicit artifact checks.
- [x] Sampling continuity stayed below the three-task Nyquist gap.
- [x] The missing Phase 88 artifact chain is now present and tied to current-tree proof.
- [x] Active requirement and roadmap surfaces now agree with the verified Phase 88 verdict.
- [x] No ad-hoc shell-only closure path was required.
- [x] `nyquist_compliant: true` is set only after execution evidence passed.

**Approval:** finalized on 2026-05-25 after current-tree verification and artifact closure.
