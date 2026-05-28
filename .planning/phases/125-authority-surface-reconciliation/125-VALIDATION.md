---
phase: 125
slug: authority-surface-reconciliation
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
---

# Phase 125 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` aliases `verify.doc_contract`, `ci.all` |
| **Quick run command** | `mix test test/threadline/v1_23_charter_doc_contract_test.exs` |
| **Full suite command** | `mix verify.doc_contract` then `mix ci.all` |
| **Estimated runtime** | ~30s doc contract; ~minutes for `ci.all` |

---

## Sampling Rate

- **After every task commit:** Run quick run command when charter test touched; else `rg` acceptance greps from plan
- **After every plan wave:** Run `mix verify.doc_contract`
- **Before phase verify-work:** `mix ci.all` must be green
- **Max feedback latency:** 120 seconds (doc contract)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 125-01-01 | 01 | 1 | ROADMAP SC #1 | — | Charter literals match PROJECT shipped heading | unit | `mix test test/threadline/v1_23_charter_doc_contract_test.exs` | ✅ | ⬜ pending |
| 125-01-02 | 01 | 1 | ROADMAP SC #1 | — | Full doc contract alias green | integration | `mix verify.doc_contract` | ✅ | ⬜ pending |
| 125-02-01 | 02 | 2 | ROADMAP SC #2–3 | — | STATE/MILESTONE-ARC/ROADMAP grep invariants | unit | plan `rg` bundle | ✅ | ⬜ pending |
| 125-02-02 | 02 | 2 | ROADMAP SC #4 | — | CI entrypoints green on reconciled tree | integration | `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files beyond charter assertion updates.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for doc contract path
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
