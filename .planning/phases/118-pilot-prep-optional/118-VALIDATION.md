---
phase: 118
slug: pilot-prep-optional
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 118 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` aliases `verify.doc_contract`, `ci.all` |
| **Quick run command** | `mix test test/threadline/adoption_pilot_doc_contract_test.exs test/threadline/evaluating_threadline_doc_contract_test.exs` |
| **Full suite command** | `mix verify.doc_contract` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run per-file `mix test` for touched contract module
- **After every plan wave:** Run `mix verify.doc_contract`
- **Before `/gsd-verify-work`:** `mix verify.doc_contract` must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 118-01-01 | 01 | 1 | PILOT-01 | T-118-01 | No stale test counts in adopter docs | unit | `rg '136 tests' guides/adoption-pilot-backlog.md; echo exit:$?` | ✅ | ⬜ pending |
| 118-01-02 | 01 | 1 | PILOT-01 | T-118-02 | Entrypoints match mix.exs | unit | `mix test test/threadline/adoption_pilot_doc_contract_test.exs` | ✅ | ⬜ pending |
| 118-02-01 | 02 | 1 | PILOT-02 | T-118-03 | Evaluating guide exists with locked literals | unit | `test -f guides/evaluating-threadline.md` | ❌ W0 | ⬜ pending |
| 118-02-02 | 02 | 1 | PILOT-02 | T-118-04 | No false STG attestation claims | unit | `mix test test/threadline/evaluating_threadline_doc_contract_test.exs` | ❌ W0 | ⬜ pending |
| 118-02-03 | 02 | 1 | PILOT-02 | T-118-05 | README maps to evaluating guide | unit | `mix test test/threadline/readme_doc_contract_test.exs --only line:XXX` | ✅ | ⬜ pending |
| 118-02-04 | 02 | 1 | PILOT-02 | T-118-06 | mix.exs alias includes new contract | unit | `mix verify.doc_contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing doc-contract infrastructure covers phase requirements
- [ ] `guides/evaluating-threadline.md` — created in plan 118-02 Task 1
- [ ] `test/threadline/evaluating_threadline_doc_contract_test.exs` — created in plan 118-02 Task 3

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Evaluating guide readability (~80–120 lines) | PILOT-02 | Line count is guidance not gate | `wc -l guides/evaluating-threadline.md` — target 80–120 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
