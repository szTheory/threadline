---
phase: 26
slug: support-playbooks-doc-contracts
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.x / Mix) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/threadline/support_playbook_doc_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~1–3 minutes incremental; full suite per project norms |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/support_playbook_doc_contract_test.exs` when guides or that test file changed.
- **After every plan wave:** Run `mix test` (or `mix ci.all` if touching cross-cutting docs).
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** Bounded by `mix test` wall clock on dev machine.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | LOOP-02 | T-26-02 | SQL examples use placeholders only; no live secrets | doc | `mix test test/threadline/support_playbook_doc_contract_test.exs` (post wave 2) | ✅ | ⬜ pending |
| 26-01-02 | 01 | 1 | LOOP-02 | — | N/A (markdown) | doc | same | ✅ | ⬜ pending |
| 26-02-01 | 02 | 2 | LOOP-04 | — | N/A | unit | `mix test test/threadline/support_playbook_doc_contract_test.exs` | ⬜ W0 | ⬜ pending |
| 26-02-02 | 02 | 2 | LOOP-04 | — | N/A | unit | `mix test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc render | LOOP-02 | HTML preview not in CI | Optional: `mix docs` and spot-check anchors open. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify via ExUnit
- [ ] Sampling continuity: guide edits paired with contract test updates in wave 2
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when phase execution completes

**Approval:** pending
