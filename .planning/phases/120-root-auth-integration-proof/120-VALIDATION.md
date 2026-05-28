---
phase: 120
slug: root-auth-integration-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 120 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` aliases `verify.test`, `verify.doc_contract` |
| **Quick run command** | `mix test test/threadline/integrations/phx_gen_auth_integration_test.exs` |
| **Full suite command** | `mix verify.test` and `mix verify.doc_contract` |
| **Estimated runtime** | ~30–90 seconds (integration file only); full verify ~minutes |

---

## Sampling Rate

- **After every task commit:** Run quick integration test command
- **After plan 120-01 wave:** Run quick command + `mix test test/threadline/upgrade_path_doc_contract_test.exs` if doc-contract task started
- **After plan 120-02:** Run `mix verify.test` and `mix verify.doc_contract`
- **Before `/gsd-verify-work`:** Both verify aliases green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 120-01-01 | 01 | 1 | AUTH-PROOF-01 | T-120-01 | actor_fn returns nil for logged-out scope | unit | `mix test test/threadline/integrations/phx_gen_auth_integration_test.exs` | ⬜ W0 | ⬜ pending |
| 120-01-02 | 01 | 1 | AUTH-PROOF-01 | T-120-01 | scope user.id → :user ActorRef | unit | same | ⬜ W0 | ⬜ pending |
| 120-01-03 | 01 | 1 | AUTH-PROOF-02 | T-120-02 | 1-arity authorize allow/deny via ExportAuthPlug | unit | same | ⬜ W0 | ⬜ pending |
| 120-01-04 | 01 | 1 | AUTH-PROOF-01 | T-120-03 | Threadline.Plug smoke assigns audit_context | unit | same | ⬜ W0 | ⬜ pending |
| 120-02-01 | 02 | 2 | AUTH-PROOF-03 | T-120-04 | matrix row + no forthcoming wording | doc contract | `mix verify.doc_contract` | ✅ | ⬜ pending |
| 120-02-02 | 02 | 2 | AUTH-PROOF-03 | T-120-02 | guide authorize_fn 1-arity | doc contract | `grep` + verify.doc_contract | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:
- `test/threadline/integrations/sigra_test.exs` — structural template
- `test/threadline/upgrade_path_doc_contract_test.exs` — extend for fourth lane
- `mix verify.test` / `mix verify.doc_contract` — canonical gates

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | All behaviors automated |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands
- [x] Sampling continuity: quick test between tasks
- [x] Wave 0: existing ExUnit + verify aliases
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` in frontmatter

**Approval:** pending execution
