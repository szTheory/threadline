---
phase: 11
slug: backfill-continuity
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit 1.x (Elixir 1.18+) |
| **Config file** | `config/test.exs` (existing `:threadline` test repo) |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/continuity_brownfield_test.exs` |
| **Full suite command** | `MIX_ENV=test mix ci.all` |
| **Estimated runtime** | ~30–120 seconds (depends on PostgreSQL availability) |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix compile --warnings-as-errors`
- **After every plan wave:** Run `MIX_ENV=test mix test` on all new/changed test paths for Phase 11
- **Before `/gsd-verify-work`:** `MIX_ENV=test mix ci.all` must be green in CI or local with PostgreSQL
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | TOOL-02 | T-11-01-01 | No app-side `AuditChange.insert` in default path | integration | `MIX_ENV=test mix test …continuity…` | ⬜ W0 | ⬜ pending |
| 11-01-02 | 01 | 1 | TOOL-02 | T-11-01-02 | Table names validated as identifiers | unit | `mix test` policy/module tests if split | ⬜ W0 | ⬜ pending |
| 11-02-01 | 02 | 1 | TOOL-02 | — | Docs only | manual grep | `grep -F brownfield-continuity README.md` | ⬜ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Brownfield integration test module under `test/threadline/` — stubs REQ TOOL-02 empty-baseline path
- [ ] **Existing infrastructure** covers PostgreSQL `DataCase`, audit schema migrations — no new framework install

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Operator reads guide and understands T₀ | TOOL-02 | Subjective comprehension | Read `guides/brownfield-continuity.md` § semantics; confirm SC1–SC3 statements present |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual step
- [ ] Sampling continuity: integration test lands in Plan 11-01 wave 1
- [ ] No watch-mode flags in commands
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
