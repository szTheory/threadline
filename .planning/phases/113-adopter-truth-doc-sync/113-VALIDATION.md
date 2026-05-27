---
phase: 113
slug: adopter-truth-doc-sync
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 113 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (root `Threadline.Test.Repo`; example `ThreadlinePhoenix.Repo`) |
| **Config file** | `test/test_helper.exs`, `examples/threadline_phoenix/config/test.exs` |
| **Quick run command** | Wave-specific — see Per-Task Verification Map |
| **Full suite command** | `mix verify.example && mix verify.doc_contract` |
| **Estimated runtime** | Quick ~10–30s per plan; full verify ~2–3 min |

---

## Sampling Rate

- **After every task commit:** Run wave-specific command from Per-Task Verification Map
- **After every plan wave:** Run that wave's automated command
- **Before `/gsd-verify-work`:** `mix verify.example && mix verify.doc_contract` must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 113-01-01 | 01 | 1 | TRUTH-01 | T-113-01 | evidence admin-only; support denied | integration | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs` | ✅ | ⬜ pending |
| 113-01-02 | 01 | 1 | TRUTH-01 | T-113-01 | mount snippet locks evidence_authorize_fn | doc-contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` | ✅ | ⬜ pending |
| 113-02-01 | 02 | 1 | TRUTH-04 | — | WALK-03-02 literals + leaving-agent count == 12 | integration | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/walkthrough_doc_contract_test.exs` | ✅ | ⬜ pending |
| 113-03-01 | 03 | 1 | TRUTH-02 | — | adoption-pilot 0.5.x literals | doc-contract | `mix test test/threadline/adoption_pilot_doc_contract_test.exs` | ❌ W1 | ⬜ pending |
| 113-04-01 | 04 | 2 | TRUTH-03 | — | canonical evidence CLI locked | doc-contract | `mix test test/threadline/evidence_cli_doc_contract_test.exs` | ❌ W2 | ⬜ pending |
| 113-04-02 | 04 | 2 | TRUTH-05 | — | full doc + example verify green | integration | `mix verify.doc_contract && mix verify.example` | ✅ | ⬜ pending |
| 113-closeout | — | — | TRUTH-05 | — | phase acceptance | integration | `mix verify.example && mix verify.doc_contract && mix verify.test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No lib changes expected.

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
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
