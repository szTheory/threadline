---
phase: 13
slug: retention-batched-purge
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/retention/` |
| **Full suite command** | `mix ci.all` (or `mix verify.test` per CI docs) |
| **Estimated runtime** | ~30–120s depending on Docker Postgres |

---

## Sampling Rate

- **After every task commit:** `MIX_ENV=test mix compile --warnings-as-errors` and targeted `mix test` for touched paths
- **After every plan wave:** `MIX_ENV=test mix test` for retention + any regression slice listed in plan verification
- **Before `/gsd-verify-work`:** `mix ci.all` green
- **Max feedback latency:** ~180s for full `mix ci.all` when DB up

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | RETN-01 | T-13-01-01 / — | Invalid window rejected at config boundary | unit | `MIX_ENV=test mix test test/threadline/retention/policy_test.exs` | ❌ W0 | ⬜ pending |
| 13-01-02 | 01 | 1 | RETN-01 | — | Docs match code semantics | manual grep | `grep -q retention guides/domain-reference.md` | ❌ W0 | ⬜ pending |
| 13-02-01 | 02 | 2 | RETN-02 | T-13-02-01 | Unguarded prod purge blocked | unit + integration | `MIX_ENV=test mix test test/threadline/retention/purge_test.exs` | ❌ W0 | ⬜ pending |
| 13-02-02 | 02 | 2 | RETN-02 | T-13-02-02 | SQL parameterized; no string-built cutoff in raw | integration | same file | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/retention/` — test module stubs or first failing tests for RETN-01 / RETN-02 before implementation (if TDD requested)
- [ ] **Existing infrastructure** — `Threadline.Test.Repo`, audit migrations already cover DB integration

*Wave 0: add test files when first plan executes if not present.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cron playbook in prod | RETN-02 | Host-specific | Follow README “Retention” section: set config, run Mix with `--dry-run`, then gated execute |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual row
- [ ] Sampling continuity: compile + targeted test between tasks
- [ ] No watch-mode flags in verify commands
- [ ] `nyquist_compliant: true` set in frontmatter when execution complete

**Approval:** pending
