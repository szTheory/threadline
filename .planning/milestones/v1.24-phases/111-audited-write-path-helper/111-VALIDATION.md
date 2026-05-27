---
phase: 111
slug: audited-write-path-helper
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 111 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit 1.x + Ecto.Adapters.SQL (PostgreSQL) |
| **Config file** | `test/test_helper.exs`, `test/support/data_case.ex` |
| **Quick run command** | `mix test test/threadline/audit_transaction_test.exs test/threadline/audit_doc_contract_test.exs` |
| **Full suite command** | `mix verify.test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command for touched test files
- **After every plan wave:** Run `mix verify.test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 111-01-01 | 01 | 1 | AUDIT-TXN-01 | T-111-01 | Actor required before txn unless explicit opt-in | unit | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 111-01-02 | 01 | 1 | AUDIT-TXN-02 | T-111-02 | audit_context sugar extracts actor + correlation | unit | `grep -q 'audit_context' lib/threadline/audit.ex` | ❌ W0 | ⬜ pending |
| 111-02-01 | 02 | 2 | AUDIT-TXN-03 | T-111-03 | correlation_id timeline matches linked action | integration | `mix test test/threadline/audit_transaction_test.exs` | ❌ W0 | ⬜ pending |
| 111-02-02 | 02 | 2 | AUDIT-TXN-03 | T-111-01 | missing_actor fails predictably | integration | `mix test test/threadline/audit_transaction_test.exs --only missing_actor` | ❌ W0 | ⬜ pending |
| 111-03-01 | 03 | 2 | AUDIT-TXN-04 | — | guide section present | doc-contract | `mix test test/threadline/audit_doc_contract_test.exs` | ❌ W0 | ⬜ pending |
| 111-03-02 | 03 | 2 | AUDIT-TXN-04 | — | integration-contracts section locked | doc-contract | `mix test test/threadline/integration_contracts_doc_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `test/support/data_case.ex` — PostgreSQL sandbox
- [x] `test/threadline/capture/trigger_context_test.exs` — trigger table pattern
- [x] `test/support/getting_started_fixtures.ex` — doc anchor extraction
- [x] `Threadline.Test.Repo` migrations via `test_helper.exs`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Moduledoc readability | AUDIT-TXN-04 | Subjective prose quality | Spot-check `@moduledoc` capture-only vs correlation-ready table |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
