---
phase: 172
slug: foundations-audit-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-15
---

# Phase 172 — Validation Strategy

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
| 172-01-01 | 01 | 1 | DS-06 | — | N/A | manual | `mix test` | ✅ W0 | ⬜ pending |
| 172-01-02 | 01 | 1 | DS-06 | — | N/A | manual | `mix test` | ✅ W0 | ⬜ pending |
| 172-01-03 | 01 | 1 | DS-06 | — | N/A | unit | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ W0 | ⬜ pending |
| 172-02-01 | 02 | 2 | DS-05 | — | N/A | unit | `mix test` | ✅ W0 | ⬜ pending |
| 172-02-02 | 02 | 2 | DS-05 | — | N/A | unit | `mix test` | ✅ W0 | ⬜ pending |
| 172-02-03 | 02 | 2 | DS-05 | — | N/A | unit | `mix test` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*If none: "Existing infrastructure covers all phase requirements."*
Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Decision documentation | DS-06 | Documentation update | Verify DESIGN-SYSTEM.md is updated |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling rate is sufficient for Nyquist
- [x] Test scope covers all Phase 172 goals

**Approval:** pending