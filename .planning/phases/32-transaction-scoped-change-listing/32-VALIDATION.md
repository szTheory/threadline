---
phase: 32
slug: transaction-scoped-change-listing
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/query_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30–120 seconds (environment-dependent) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/query_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | XPLO-02 | T-32-01 | Read-only; no tuple leaks for “not found” | unit + compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 32-01-02 | 01 | 1 | XPLO-02 | T-32-02 | Delegator matches Query | integration | `mix test test/threadline/query_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing infrastructure covers all phase requirements — `Threadline.DataCase` + `query_test.exs` helpers.

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| *None* | — | — | — |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
