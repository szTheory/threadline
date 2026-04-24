---
phase: 22
slug: example-app-layout-runbook
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) — root + nested example app |
| **Config file** | `config/test.exs` (root); `examples/threadline_phoenix/config/test.exs` (example) |
| **Quick run command** | `cd examples/threadline_phoenix && MIX_ENV=test mix test` |
| **Full suite command** | `MIX_ENV=test mix ci.all` (from repo root, after Plan 22-02) |
| **Estimated runtime** | ~2–5 min local (library + example); CI bounded by existing `verify-test` job |

---

## Sampling Rate

- **After every task commit:** `MIX_ENV=test mix compile --warnings-as-errors` in the touched tree (root or `examples/threadline_phoenix/`).
- **After every plan wave:** Full `MIX_ENV=test mix ci.all` when Postgres available; otherwise at least `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` after alias/workflow edits.
- **Before `/gsd-verify-work`:** `mix ci.all` green with Postgres.
- **Max feedback latency:** ~600s CI (existing job budget).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | REF-01 | T-22-01 / — | No secrets in seeds; path dep only | mix | `cd examples/threadline_phoenix && mix compile --warnings-as-errors` | W0 | ⬜ pending |
| 22-01-02 | 01 | 1 | REF-02 | — | N/A | mix | `cd examples/threadline_phoenix && mix test` | W0 | ⬜ pending |
| 22-02-01 | 02 | 2 | REF-01 | — | CI uses existing Postgres service | mix | `MIX_ENV=test mix ci.all` | ✅ | ⬜ pending |
| 22-02-02 | 02 | 2 | REF-01, REF-02 | — | Doc anchors stable | unit | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/threadline_phoenix/mix.exs` — Phoenix + path `{:threadline, path: "../.."}`.
- [ ] `examples/threadline_phoenix/test/test_helper.exs` — DB create/migrate pattern for `threadline_phoenix_test`.

*Wave 0 is satisfied when Plan 22-01 creates the example Mix project.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cold `docker compose up` then first `mix ecto.create` | REF-01 | Local topology varies | Follow example README appendix; confirm no race before migrate (D-13). |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable on CI

**Approval:** pending
