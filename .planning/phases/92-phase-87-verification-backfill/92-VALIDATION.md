---
phase: 92
slug: phase-87-verification-backfill
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T15:25:00Z
---

# Phase 92 — Validation Strategy

> Per-phase validation contract for the verification-backfill proof chain.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix alias verification + nested example-app tests |
| **Config file** | `mix.exs`, `config/test.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix verify.doc_contract` and `mix verify.example` |
| **Estimated runtime** | ~10-30 seconds warm for the quick doc-contract subset; `mix verify.example` is the slower wave-gate proof band |

---

## Sampling Rate

- **After every task commit:** Run the targeted doc-contract subset when guide, README, router-proof, or planning-authority wording changes.
- **After every plan wave:** Run `mix verify.doc_contract` and `mix verify.example`.
- **Before `$gsd-verify-work`:** Both named verification aliases must be green.
- **Max feedback latency:** 30 seconds warm for the per-commit smoke path; `mix verify.example` is an explicit wave-gate exception because the nested example app has no cheaper truthful proof command on the current tree.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 92-01-01 | 01 | 1 | ADOPT-01 | T-92-01 | Public contract surfaces keep one canonical shared `/audit` recipe with host-owned auth, scope, and export seams. | doc-contract | `mix verify.doc_contract` | ✅ | ✅ green |
| 92-01-02 | 01 | 1 | ADOPT-02 | T-92-02 | Example Phoenix app proves shared-tree support scope narrowing and admin-only export denial in the nested host context. | nested integration | `mix verify.example` | ✅ | ✅ green |
| 92-02-01 | 02 | 2 | ADOPT-01, ADOPT-02 | T-92-03 | `87-VERIFICATION.md` and `87-VALIDATION.md` record only claims proven by the named rerun surfaces and current-tree evidence. | artifact review | `rg -n \"ADOPT-01|ADOPT-02|mix verify\\.doc_contract|mix verify\\.example\" .planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VERIFICATION.md .planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VALIDATION.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers the automated proof surfaces for `ADOPT-01` and `ADOPT-02`.
- Missing execution artifacts are the actual Wave 0 target: `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VERIFICATION.md` and `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VALIDATION.md`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Truth narrowing on planning authority surfaces if the verified claim boundary changes | ADOPT-01, ADOPT-02 | This only applies if execution discovers public-claim drift that requires maintainer bookkeeping changes. | Compare the final `87-VERIFICATION.md` claim boundary against `.planning/ROADMAP.md`, `.planning/STATE.md`, and `.planning/REQUIREMENTS.md`; update only if the proven scope is narrower than the current authority text. |

---

## Nyquist Notes

- `MIX_ENV=test mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs --max-failures 1` is the fast smoke loop and stays within the 30-second feedback target on a warm tree.
- `mix verify.example` is intentionally treated as a wave-gate proof band rather than a per-commit smoke loop. The research established that root-running the nested example test file is not a truthful or stable substitute because the example app's `ConnCase` only exists inside `examples/threadline_phoenix`.
- No smaller repo-level command currently proves `ADOPT-02` honestly while preserving the named rerun surface required by D-04, so the slower example-host verification remains mandatory at wave boundaries and final sign-off.

---

## Commands Actually Used

1. `mix verify.doc_contract`
   Result: PASS
2. `mix verify.example`
   Result: PASS
3. `rg -n 'scope "/audit"|authorize_fn|scope_query_fn|export_authorize_fn' guides/getting-started-saas.md guides/operator-surface.md guides/upgrade-path.md examples/threadline_phoenix/README.md`
   Result: PASS
4. `rg -n 'mix verify\.example|sigra-reference' guides/upgrade-path.md examples/threadline_phoenix/README.md test/threadline/upgrade_path_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs`
   Result: PASS
5. `rg -n 'scope "/audit"|threadline_operator_surface\("/"|authorize_fn:|export_authorize_fn:|scope_query_fn:' examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
   Result: PASS
6. `rg -n "ADOPT-01|ADOPT-02|mix verify\.doc_contract|mix verify\.example" .planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VERIFICATION.md .planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VALIDATION.md`
   Result: PASS

---

## Validation Sign-Off

- [x] All execution tasks point back to named rerun surfaces or explicit artifact checks.
- [x] Sampling continuity: no proof-bearing task closes without either `mix verify.doc_contract`, `mix verify.example`, or an artifact grep tied to those commands.
- [x] Wave 0 covers the only missing references: the Phase 87 verification artifacts.
- [x] No watch-mode or ad-hoc shell-only proof paths are required.
- [x] Feedback latency remained under the expected warm-run budget for this phase.
- [x] `nyquist_compliant: true` is set only after execution evidence passed.

**Approval:** finalized on 2026-05-25 after current-tree verification and artifact closure.
