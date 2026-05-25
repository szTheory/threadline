---
phase: 86
slug: scoped-read-path-closure
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T13:34:15Z
---

# Phase 86 — Validation Strategy

> Current-tree Nyquist closure for the Phase 86 scoped read-path claim after the
> Phase 91 backfill.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Phoenix LiveViewTest, doc-contract tests, planning artifact review |
| **Config file** | `config/test.exs`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs --max-failures 1` |
| **Docs contract command** | `MIX_ENV=test mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` |
| **Estimated runtime** | ~5-15 seconds warm for the targeted proof and contract subset |

## Per-Task Verification Map

| Task ID | Requirement | Secure Behavior | Automated Command | Status |
|---------|-------------|-----------------|-------------------|--------|
| 86-V-01 | SCOPE-01, SCOPE-02 | `history/3` and `as_of/4` apply support scope and block out-of-scope historical reads. | `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs --max-failures 1` | ✅ green |
| 86-V-02 | SCOPE-01, SCOPE-02 | `row_history/4` and `row_history_page/4` match the same scoped helper behavior. | `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs --max-failures 1` | ✅ green |
| 86-V-03 | SCOPE-01, SCOPE-02 | The mounted `/audit` transaction-history route renders only in-scope row history and snapshot state. | `MIX_ENV=test mix test test/threadline/operator_surface/transaction_live_test.exs --seed 154054` | ✅ green |
| 86-V-04 | SCOPE-01, SCOPE-02 | Planning and public truth surfaces match the proven current-tree claim. | `MIX_ENV=test mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ green |

## Commands Actually Used

1. `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs --max-failures 1`
   Result: PASS
2. `MIX_ENV=test mix test test/threadline/operator_surface/transaction_live_test.exs --seed 154054`
   Result: PASS
3. `MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs --max-failures 1`
   Result: PASS
4. `MIX_ENV=test mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`
   Result: PASS

## Requirement Closure

- `SCOPE-01`: complete in Phase 91
- `SCOPE-02`: complete in Phase 91

## Validation Sign-Off

- [x] `history/3`, `as_of/4`, `row_history/4`, and `row_history_page/4` are covered explicitly.
- [x] Mounted `/audit` proof exists through the real transaction-history route.
- [x] `nyquist_compliant: true` is set only after the current-tree proof commands passed.
- [x] Closure is tied to exact commands actually used, not the older implementation intent.
