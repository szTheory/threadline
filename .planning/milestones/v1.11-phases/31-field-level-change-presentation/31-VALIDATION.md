---
phase: 31
slug: field-level-change-presentation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-24
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.x / Mix) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/change_diff_test.exs` |
| **Full suite command** | `mix compile --warnings-as-errors && mix test` |
| **Estimated runtime** | ~30–120 seconds (project-dependent) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/change_diff_test.exs`
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | XPLO-01 | T-31-01 | No cleartext inference beyond persisted maps | unit | `mix test test/threadline/change_diff_test.exs` | ✅ | ⬜ pending |
| 31-01-02 | 01 | 1 | XPLO-01 | T-31-02 | Stable JSON key order / no struct leakage | unit | `mix test test/threadline/change_diff_test.exs` | ✅ | ⬜ pending |
| 31-02-01 | 02 | 2 | XPLO-01 | — | N/A (tests + docs) | unit | `mix test test/threadline/change_diff_test.exs` | ✅ | ⬜ pending |
| 31-02-02 | 02 | 2 | XPLO-01 | — | Public API discoverability only | unit + compile | `mix compile --warnings-as-errors && mix test` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — no new test framework install.

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution green
