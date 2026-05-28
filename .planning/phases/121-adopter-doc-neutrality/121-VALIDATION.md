---
phase: 121
slug: adopter-doc-neutrality
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 121 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` (`verify.doc_contract`, `verify.test`) |
| **Quick run command** | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` |
| **Full suite command** | `mix verify.doc_contract` |
| **Estimated runtime** | ~45–90 seconds (doc contracts) |

---

## Sampling Rate

- **After every task commit:** Run task `<verify>` command or quick run above
- **After every plan wave:** Run `mix verify.doc_contract`
- **Before `/gsd-verify-work`:** `mix verify.doc_contract` green; spot `mix ci.all` if Postgres available
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 121-01-01 | 01 | 1 | ADOPT-AUTH-01 | T-121-01 | §5 generic plug first; Sigra optional | doc contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` | ✅ | ⬜ pending |
| 121-01-02 | 01 | 1 | ADOPT-AUTH-01 | T-121-02 | §6 curl scoped to sigra-reference | doc contract | same | ✅ | ⬜ pending |
| 121-02-01 | 02 | 2 | ADOPT-AUTH-02 | T-121-03 | Four-lane README discovery | doc contract | `mix test test/threadline/readme_doc_contract_test.exs` | ✅ | ⬜ pending |
| 121-02-02 | 02 | 2 | ADOPT-AUTH-02 | — | Evaluator neutrality + phx link | doc contract | `mix test test/threadline/evaluating_threadline_doc_contract_test.exs` | ✅ | ⬜ pending |
| 121-02-03 | 02 | 2 | ADOPT-AUTH-03 | T-121-04 | phx guide markers locked | doc contract | `mix test test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` | ❌ W0 | ⬜ pending |
| 121-02-04 | 02 | 2 | ADOPT-AUTH-03 | — | verify.doc_contract includes phx test | alias | `mix verify.doc_contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing doc-contract infrastructure covers phase (no new framework)
- [ ] `test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` — created in 121-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hex/docs `<details>` rendering | ADOPT-AUTH-01 | HTML rendering varies | Open getting-started on hexdocs after publish; confirm curl block collapses |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
