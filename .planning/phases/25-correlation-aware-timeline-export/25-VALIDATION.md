---
phase: 25
slug: correlation-aware-timeline-export
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for LOOP-01 (correlation-aware timeline & export).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.15+) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/query_test.exs test/threadline/export_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~2–5 minutes (project-dependent) |

---

## Sampling Rate

- **After every task commit:** `mix test test/threadline/query_test.exs test/threadline/export_test.exs`
- **After every plan wave:** `mix test` (or `mix verify.test` from repo root if configured)
- **Before `/gsd-verify-work`:** Full suite green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | LOOP-01 | T-25-01 / — | Parameterized SQL only; correlation length cap | unit + integration | `mix test test/threadline/query_test.exs` | ✅ | ⬜ pending |
| 25-02-01 | 02 | 2 | LOOP-01 | T-25-02 / — | No new secrets in export; stable CSV default | integration | `mix test test/threadline/export_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — `Threadline.DataCase`, `Threadline.Test.Repo`, patterns in `test/threadline/export_test.exs` / `query_test.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | All behaviors covered by automated tests per CONTEXT D-4. |

---

## Validation Sign-Off

- [ ] All tasks have grep- or test-verifiable acceptance criteria
- [ ] Sampling continuity: query + export tests after each wave
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
