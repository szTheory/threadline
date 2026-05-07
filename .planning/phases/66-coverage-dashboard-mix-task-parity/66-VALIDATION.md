---
phase: 66
slug: coverage-dashboard-mix-task-parity
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-07
---

# Phase 66 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test --exclude slow` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~{N} seconds (planner to fill from RESEARCH.md) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --exclude slow`
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd-verify-work`:** Full suite must be green (including `mix verify.compile_no_optional` to prove the optional-Phoenix-deps posture stays green)
- **Max feedback latency:** {N} seconds (planner to fill)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | {wave} | COV-{NN} | — | {expected secure behavior or "N/A"} | unit | `{command}` | ✅ / ❌ W0 | ⬜ pending |

*Planner: populate this table per task from PLAN.md frontmatter.*

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] {test files / fixtures from RESEARCH.md `## Validation Architecture`}
- [ ] Confirm assumptions A3 / A4 from RESEARCH.md (Application.put_env test seam, `:slow` tag visibility)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| {behavior} | COV-{NN} | {reason} | {steps} |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < {N}s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
