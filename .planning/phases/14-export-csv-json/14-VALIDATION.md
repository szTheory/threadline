---
phase: 14
slug: export-csv-json
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18+) |
| **Config file** | `test/test_helper.exs`, `mix.exs` aliases |
| **Quick run command** | `mix test test/threadline/export/` (after plans add paths) |
| **Full suite command** | `mix verify.test` or `mix ci.all` |
| **Estimated runtime** | ~30–120s depending on Postgres integration count |

---

## Sampling Rate

- **After every task commit:** Run targeted `mix test path/to/new_test.exs`
- **After every plan wave:** Run `mix test test/threadline/` (or full `mix verify.test` if touched shared code)
- **Before `/gsd-verify-work`:** Full suite green per project CI entrypoints
- **Max feedback latency:** 120s (integration-heavy tasks)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | EXPO-01, EXPO-02 | — | Read-only queries; no audit mutation | integration | `mix test test/threadline/export/` | Wave 0 | ⬜ pending |

*Populate rows when PLAN.md task IDs are known. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/export/` — integration tests for CSV/JSON happy paths (created in Wave 1 per plan)
- [ ] Existing infrastructure: `Threadline.DataCase`, Docker/CI Postgres — **Existing infrastructure covers database cases** once export tests are added

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Large export memory on real dataset | D-11 / D-14 | Synthetic CI DB is small | In staging, run `mix threadline.export` with `--limit` at cap; confirm truncation metadata and operator logs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable for integration tests
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
