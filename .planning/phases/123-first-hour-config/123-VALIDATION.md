---
phase: 123
slug: first-hour-config
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
---

# Phase 123 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.14+) |
| **Config file** | `mix.exs` aliases `verify.doc_contract`, `verify.test` |
| **Quick run command** | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` or `mix test test/threadline/production_checklist_doc_contract_test.exs` |
| **Full suite command** | `mix verify.doc_contract` then `mix ci.all` |
| **Estimated runtime** | ~15–45 seconds (doc contracts only) |

---

## Sampling Rate

- **After every task commit:** Run the plan's targeted test file(s)
- **After every plan wave:** Run `mix verify.doc_contract`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 123-01-01 | 01 | 1 | CFG-01 | T-123-01 / — | Getting-started contains literal before §3 | doc contract | `mix test ...getting_started_saas...` | ✅ | ⬜ pending |
| 123-01-02 | 01 | 1 | CFG-02 | T-123-02 / — | Ordering + rationale fragments locked | doc contract | same | ✅ | ⬜ pending |
| 123-02-01 | 02 | 1 | CFG-03 | T-123-03 / — | Checklist section + backlink | doc contract | `mix test ...production_checklist...` | ❌ W0 | ⬜ pending |
| 123-02-02 | 02 | 1 | CFG-03 | — | `verify.doc_contract` includes new test | integration | `mix verify.doc_contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new framework install.

- [x] ExUnit doc-contract pattern in `getting_started_saas_doc_contract_test.exs`
- [ ] `production_checklist_doc_contract_test.exs` — created in plan 02 task 1
- [ ] `mix.exs` `verify.doc_contract` alias extended — plan 02 task 2

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc anchor renders | CFG-01 | Markdown anchor slug not asserted in CI | Open `mix docs` or preview link `getting-started-saas.md#configure-threadline` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
