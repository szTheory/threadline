---
phase: 173
slug: primitive-components-extract-audit-each-in-isolation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2024-06-15
---

# Phase 173 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` / `test/test_helper.exs` |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test`
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 173-01-01 | 01 | 1 | COMP-01 | — | N/A | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ W0 | ⬜ pending |
| 173-01-02 | 01 | 1 | COMP-01 | — | N/A | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ W0 | ⬜ pending |
| 173-02-01 | 02 | 2 | COMP-01 | — | N/A | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ W0 | ⬜ pending |
| 173-02-02 | 02 | 2 | COMP-01 | — | N/A | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ W0 | ⬜ pending |
| 173-03-01 | 03 | 3 | COMP-02 | — | N/A | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ W0 | ⬜ pending |
| 173-03-02 | 03 | 3 | COMP-02 | — | N/A | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ W0 | ⬜ pending |
| 173-04-01 | 04 | 4 | COMP-03 | — | N/A | unit | `mix test test/threadline/operator_surface/ui_stress_test.exs` | ✅ W0 | ⬜ pending |
| 173-04-02 | 04 | 4 | COMP-03 | T-173-04 | Retain dev-only gating | integration | `mix test` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*If none: "Existing infrastructure covers all phase requirements."*
Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stress route visibility | COMP-03 | Visual audit | Visit `/audit/__stress` locally to verify components in different themes |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling rate is sufficient for Nyquist
- [x] Test scope covers all Phase 173 goals

**Approval:** pending
