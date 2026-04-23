---
phase: 2
slug: semantics-layer
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.15+) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/semantics/` (after tree exists) or `mix test path/to/file_test.exs` |
| **Full suite command** | `mix verify.test` |
| **Estimated runtime** | ~30–120 seconds (depends on Postgres) |

---

## Sampling Rate

- **After every task commit:** `mix compile --warnings-as-errors` and targeted `mix test` for touched modules.
- **After every plan wave:** `mix verify.test`
- **Before `/gsd-verify-work`:** `mix ci.all` (format + credo + test) green
- **Max feedback latency:** bounded by full suite (~2 min target)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | — | T-02-01-01 / — | N/A (hygiene) | unit | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | ACTR-* | T-02-01-02 / — | Typed actor JSONB | unit | `mix test test/threadline/semantics/actor_ref_test.exs` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 1 | CTX-03, CTX-04 | T-02-01-03 / T-02-01-04 | No `SET` in trigger; GUC read only | integration | `mix test test/threadline/capture/trigger_context_test.exs` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 1 | PKG-04 | — | Idempotent DDL | integration | `mix test` (migration tests if present) | ✅ | ⬜ pending |
| 02-02-01 | 02 | 2 | SEM-* | T-02-02-01 | No bypass of `record_action` for invalid actors | unit | `mix test test/threadline/semantics/audit_action_test.exs` | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 2 | SEM-01, SEM-05 | — | Tagged errors, no raise | unit | `mix test test/threadline/record_action_test.exs` | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 3 | CTX-01, CTX-02 | — | Conn-scoped context only | unit | `mix test test/threadline/plug_test.exs` | ❌ W0 | ⬜ pending |
| 02-03-02 | 03 | 3 | CTX-05 | — | Pure helpers, no global state | unit | `mix test test/threadline/job_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements: `Threadline.Test.Repo`, `Threadline.DataCase`, PostgreSQL in `config/test.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PgBouncer transaction pool | CTX-03 | Needs real pooler topology | In staging with PgBouncer transaction mode, run audited write + `set_config` path; confirm `audit_transactions.actor_ref` matches and no session leakage across transactions. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: compile + targeted tests between commits
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency under CI budget
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution green
