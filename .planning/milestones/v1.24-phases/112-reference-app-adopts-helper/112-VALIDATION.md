---
phase: 112
slug: reference-app-adopts-helper
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 112 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + PostgreSQL (root `Threadline.Test.Repo`; example `ThreadlinePhoenix.Repo`) |
| **Config file** | `test/test_helper.exs`, `examples/threadline_phoenix/config/test.exs` |
| **Quick run command** | `mix test test/threadline/audit_transaction_test.exs` |
| **Full suite command** | `mix verify.example && mix verify.doc_contract && mix verify.test` |
| **Estimated runtime** | Quick ~15–45s; full verify ~2–4 min |

---

## Sampling Rate

- **After every task commit:** Run wave-specific command from Per-Task Verification Map
- **After every plan wave:** Run example targeted audit/correlation tests for that wave
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 240 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 112-01-01 | 01 | 0 | D-112-01c | — | capture-only meta stored on audit_transaction | integration | `mix test test/threadline/audit_transaction_test.exs` | ✅ | ⬜ pending |
| 112-02-01 | 02 | 1 | ADOPT-HELPER-01 | — | create_post uses helper; marker interior updated | integration | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs` | ✅ | ⬜ pending |
| 112-02-02 | 02 | 1 | ADOPT-HELPER-03 | — | guide §6 matches blog marker; no legacy block | doc-contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` | ✅ | ⬜ pending |
| 112-03-01 | 03 | 2 | ADOPT-HELPER-01 | — | HelpDesk HTTP path uses helper | integration | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/help_desk_audit_http_test.exs` | ✅ | ⬜ pending |
| 112-03-02 | 03 | 2 | ADOPT-HELPER-02 | — | delete_reply capture-only + org meta | integration | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/help_desk_audit_test.exs` | ✅ | ⬜ pending |
| 112-04-01 | 04 | 3 | ADOPT-HELPER-01 | — | touch_post_for_job links action_id | integration | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/workers/post_touch_worker_test.exs` | ✅ | ⬜ pending |
| 112-04-02 | 04 | 3 | ADOPT-HELPER-03 | — | README cross-links helper | doc-contract | `mix verify.doc_contract` | ✅ | ⬜ pending |
| 112-closeout | — | — | ADOPT-HELPER-02 | — | full example + doc contracts green | integration | `mix verify.example && mix verify.doc_contract && mix verify.test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/audit_transaction_test.exs` — new test `"transaction_meta stored on capture-only audit_transaction"`
- [ ] `lib/threadline/audit.ex` — capture-only `:transaction_meta` apply path

*Prerequisite for Plan 03 delete_reply migration.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 240s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
