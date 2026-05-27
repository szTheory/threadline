---
phase: 116
slug: example-first-hour-fixes
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 116 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (root + example app) |
| **Config file** | `examples/threadline_phoenix/test/test_helper.exs`, root `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/readme_doc_contract_test.exs` |
| **Full suite command** | `mix verify.doc_contract && mix verify.example` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run targeted contract test for touched surface
- **After every plan wave:** Run `mix verify.example` (Plan 01) or full closeout (Plan 02)
- **Before `/gsd-verify-work`:** `mix verify.doc_contract` + `mix verify.example` green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 116-01-01 | 01 | 1 | EXAMPLE-01 | T-116-01 | Session plugs before Threadline.Plug on :api | unit | `grep fetch_current_scope examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | ✅ | ⬜ pending |
| 116-01-02 | 01 | 1 | EXAMPLE-01 | T-116-02 | sigra_conn/2 compatible with session plugs | integration | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/posts_audit_path_test.exs` | ✅ | ⬜ pending |
| 116-01-03 | 01 | 1 | EXAMPLE-01 | T-116-06 | Docs state host-owned auth, no bearer tokens | doc contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs` | ✅ | ⬜ pending |
| 116-01-04 | 01 | 1 | EXAMPLE-01 | T-116-03 | getting-started §6 mirrors auth staging | doc contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` | ✅ | ⬜ pending |
| 116-02-01 | 02 | 2 | EXAMPLE-02 | T-116-05 | Track A/B chooser + neutral vs fiction terminology | doc contract | `mix test test/threadline/readme_doc_contract_test.exs` | ✅ | ⬜ pending |
| 116-02-02 | 02 | 2 | EXAMPLE-03 | T-116-02 | Mix task ownership table + skip generators on clone | doc contract | `mix test test/threadline/readme_doc_contract_test.exs` | ✅ | ⬜ pending |
| 116-02-03 | 02 | 2 | EXAMPLE-04 | — | Full verify aliases green | integration | `mix verify.doc_contract && mix verify.example` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 stubs needed.

- [x] Doc contract tests exist for example README and root README
- [x] Example app HTTP audit path tests exist
- [x] `mix verify.doc_contract` and `mix verify.example` aliases configured

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser login → cookie curl → 201 | EXAMPLE-01 | DevTools cookie copy | Track A golden path in 116-RESEARCH.md §6 |
| Bare curl without cookie → 500 missing actor | EXAMPLE-01 | Negative HTTP proof | Same path without `-b` flag |
| Track A without demo.seed | EXAMPLE-02 | Human runbook check | Migrate + login + curl only |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
