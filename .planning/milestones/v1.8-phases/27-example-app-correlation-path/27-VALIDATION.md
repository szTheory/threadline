---
phase: 27
slug: example-app-correlation-path
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `examples/threadline_phoenix/config/test.exs` |
| **Quick run command** | `mix verify.example` (from repository root) |
| **Full suite command** | `mix ci.all` (from repository root) |
| **Estimated runtime** | ~2–6 minutes (full CI chain) |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.example` for tasks under `examples/threadline_phoenix/`; `mix compile --warnings-as-errors` for library-only edits.
- **After every plan wave:** Run `mix ci.all` before claiming phase complete.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** Bounded by CI (acceptable for this repo).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | LOOP-03 | T-27-01 | No user-controlled SQL; opts from `AuditContext` only | integration | `mix verify.example` | ✅ | ⬜ pending |
| 27-01-02 | 01 | 1 | LOOP-03 | T-27-01 | Synthetic correlation IDs in test | integration | `mix verify.example` | ✅ | ⬜ pending |
| 27-01-03 | 01 | 1 | LOOP-03 | — | N/A (docs) | doc contract + manual read | `mix verify.doc_contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] ExUnit + Postgres test DB for example app — already present (`posts_audit_path_test.exs`).

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Optional curl smoke | LOOP-03 | Optional DX check | From README, `curl` POST with `x-correlation-id` against local `mix phx.server` |

*Primary proof is automated (`mix verify.example`).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable for repo CI
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
