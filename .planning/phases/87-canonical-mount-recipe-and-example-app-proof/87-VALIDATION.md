---
phase: 87
slug: canonical-mount-recipe-and-example-app-proof
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T15:25:00Z
---

# Phase 87 — Validation Strategy

> Finalized validation artifact for the canonical `/audit` mount and example-app
> proof backfill recorded in Phase 92.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Mix alias verification, CI-surface grep, and artifact review |
| **Config file** | `mix.exs`, `config/test.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `mix verify.doc_contract` |
| **Full proof commands** | `mix verify.doc_contract` and `mix verify.example` |
| **Estimated runtime** | `mix verify.doc_contract` stays sub-minute warm; `mix verify.example` is the slower named host-proof band |

---

## Sampling Rate

- After public contract wording changes: run `mix verify.doc_contract`.
- After example-host router or proof changes: run `mix verify.example`.
- Before closing `ADOPT-01` and `ADOPT-02`: require both named rerun surfaces
  green on the same tree.
- Max feedback latency: one warm doc-contract pass plus one example-host pass.

---

## Per-Task Verification Map

| Task ID | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|-------------|------------|-----------------|-----------|-------------------|--------|
| 87-V-01 | ADOPT-01 | T-92-01 | Public contract surfaces keep one canonical shared `/audit` recipe with host-owned auth, scope, and export seams. | doc-contract | `mix verify.doc_contract` | ✅ green |
| 87-V-02 | ADOPT-02 | T-92-02 | The example Phoenix app proves shared-tree support scope narrowing and admin-only export denial in the nested host context. | nested integration | `mix verify.example` | ✅ green |
| 87-V-03 | ADOPT-01, ADOPT-02 | T-92-03 | Phase 87 artifacts cite only the named rerun surfaces and current-tree claim boundary. | artifact review | `rg -n "ADOPT-01|ADOPT-02|mix verify\\.doc_contract|mix verify\\.example" .planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VERIFICATION.md .planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VALIDATION.md` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Requirement-to-Command Map

| Requirement | Evidence Band | Command | Why This Command Counts |
|-------------|---------------|---------|-------------------------|
| ADOPT-01 | Public contract proof | `mix verify.doc_contract` | Locks the canonical `/audit` mount language, host-owned callback naming, and guide/README agreement. |
| ADOPT-02 | Runnable example-host proof | `mix verify.example` | Compiles and tests the nested Phoenix example in its own truthful host context. |
| ADOPT-01, ADOPT-02 | Rerun-surface discoverability | `rg -n 'verify\.example|verify\.doc_contract|ci\.all' mix.exs` plus CI grep | Confirms maintainers and adopters can find the same proof paths later. |

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
6. `rg -n 'verify\.example|verify\.doc_contract|ci\.all' mix.exs && rg -n 'run: mix verify\.example|run: mix verify\.doc_contract|verify-test|verify-docs' .github/workflows/ci.yml`  
   Result: PASS

---

## CI Discoverability

- `mix.exs` exposes `verify.doc_contract` in `preferred_envs`.
- `mix.exs` exposes the `verify.example` alias and includes it in `ci.all`.
- `.github/workflows/ci.yml` runs both `mix verify.example` and
  `mix verify.doc_contract` in the main verification job.

That keeps the Phase 87 proof reproducible through named repo entrypoints.

---

## Nyquist Notes

- `mix verify.doc_contract` is the fast feedback loop for public contract drift.
- `mix verify.example` remains the mandatory slower band because the nested
  example app cannot be honestly substituted by root-running its test module.
- The final artifact pair only closes after both named proof commands are green
  and the artifact grep confirms the recorded claim matches those commands.

---

## Validation Sign-Off

- [x] All proof-bearing tasks map to named rerun surfaces or explicit artifact checks.
- [x] `ADOPT-01` is backed by the public contract proof chain.
- [x] `ADOPT-02` is backed by the nested example-host proof chain.
- [x] Commands actually used are recorded exactly.
- [x] No ad-hoc shell-only closure path was required.
- [x] `nyquist_compliant: true` is set only after the proof commands passed.

**Approval:** finalized on 2026-05-25 after current-tree re-verification through `mix verify.doc_contract` and `mix verify.example`.
