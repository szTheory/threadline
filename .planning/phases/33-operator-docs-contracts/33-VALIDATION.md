---
phase: 33
slug: operator-docs-contracts
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 33 — Validation Strategy

> Doc + contract-test phase; no new runtime code required beyond optional `mix format`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.x) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/threadline/exploration_routing_doc_contract_test.exs` |
| **Full suite command** | `mix test test/threadline/` |
| **Estimated runtime** | \< 10 seconds |

---

## Sampling Rate

- **After every task commit:** `mix test test/threadline/exploration_routing_doc_contract_test.exs`
- **After every plan wave:** `mix test test/threadline/` (doc contract group)
- **Before `/gsd-verify-work`:** `mix ci.all` or project canonical verify alias
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | XPLO-03 | T-33-01 / — | N/A (public docs) | doc contract | `mix test test/threadline/exploration_routing_doc_contract_test.exs` | ✅ | ✅ verified |
| 33-01-02 | 01 | 1 | XPLO-03 | — | N/A | doc contract | same | ✅ | ✅ verified |
| 33-01-03 | 01 | 1 | XPLO-03 | — | N/A | doc contract | same | ✅ | ✅ verified |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new Mix aliases or W0 stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub rendered anchor | XPLO-03 cross-link | Hosting may differ slightly from local slug | Open `guides/domain-reference.md` on GitHub preview; confirm fragment from checklist resolves |

---

## Validation Sign-Off

- [ ] All tasks have automated verify via doc contract module
- [ ] Sampling continuity maintained
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
