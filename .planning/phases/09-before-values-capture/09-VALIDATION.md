---
phase: 09
slug: before-values-capture
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-23
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.x) |
| **Config file** | `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/capture/trigger_test.exs test/threadline/capture/trigger_changed_from_test.exs test/threadline/query_test.exs` |
| **Full suite command** | `MIX_ENV=test mix ci.all` |
| **Estimated runtime** | ~30–120 seconds (Postgres-dependent) |

---

## Sampling Rate

- **After every task commit:** Run the **quick run command** (or the narrowest test file touched).
- **After every plan wave:** Run `MIX_ENV=test mix ci.all`.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | BVAL-01 | T-09-01-01 | No new `SET LOCAL` / host `set_config` in capture path | unit+grep | `MIX_ENV=test mix test test/threadline/capture/trigger_changed_from_test.exs` | ✅ | ⬜ pending |
| 09-01-02 | 01 | 1 | BVAL-01 | T-09-01-02 | Generator only interpolates validated table/column identifiers | integration | `grep -r \"store_changed_from\" lib/mix/tasks/threadline.gen.triggers.ex` + mix test | ✅ | ⬜ pending |
| 09-02-01 | 02 | 2 | BVAL-02 | — | N/A (data shape) | unit | `MIX_ENV=test mix test test/threadline/query_test.exs` | ✅ | ⬜ pending |
| 09-02-02 | 02 | 2 | BVAL-01 | — | Audit row classification duplicates base table policy | integration | `MIX_ENV=test mix test test/threadline/capture/trigger_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit + `Threadline.DataCase` + PostgreSQL repo cover Phase 9 — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Code review: no session coupling beyond GUC read | ROADMAP SC #4 | Human judgment on SQL diff | Review `TriggerSQL` emitted bodies in PR |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
