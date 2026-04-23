---
phase: 10
slug: verify-coverage-doc-contracts
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-23
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.15+) |
| **Config file** | `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix compile --warnings-as-errors` |
| **Full suite command** | `MIX_ENV=test mix ci.all` (Postgres on `DB_HOST`, default `localhost`) |
| **Estimated runtime** | ~2–5 minutes full gate |

---

## Sampling Rate

- **After every task commit:** `MIX_ENV=test mix compile --warnings-as-errors`
- **After every plan wave:** `MIX_ENV=test mix test` (full suite before `/gsd-verify-work`)
- **Before `/gsd-verify-work`:** `mix ci.all` must be green with Postgres
- **Max feedback latency:** ~300 seconds (CI-class)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | TOOL-01 | T-10-01-01 / — | Read-only catalog queries; no user SQL | unit | `mix test test/threadline/verify_coverage_policy_test.exs` | ⬜ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | TOOL-01 | — | N/A | integration | `mix test test/threadline/verify_coverage_task_test.exs` | ⬜ W0 | ⬜ pending |
| 10-02-01 | 02 | 2 | TOOL-03 | — | Doc tests compile-only; no secrets | unit | `mix test test/threadline/readme_doc_contract_test.exs` | ⬜ W0 | ⬜ pending |
| 10-02-02 | 02 | 2 | TOOL-01, TOOL-03 | — | CI runs same commands as local | integration | `MIX_ENV=test mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — PostgreSQL `DataCase`, `Threadline.Test.Repo`, GitHub Actions `verify-test` job.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Actions green on fork | TOOL-01, TOOL-03 | Requires `push` to remote | Open PR; confirm `verify-test` completes |

*Primary automation is local `mix ci.all` parity (CI-02).*

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable
- [ ] `nyquist_compliant: true` set in frontmatter when phase verifies

**Approval:** pending
