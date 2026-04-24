---
phase: 29
slug: audit-table-indexing-cookbook
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.x / Mix) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/threadline/audit_indexing_doc_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5–60 seconds (project-dependent) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/audit_indexing_doc_contract_test.exs` when that file exists; otherwise `mix compile --warnings-as-errors`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | IDX-01 | T-29-01 / — | N/A (docs accuracy) | manual+grep | `grep -qF 'IDX-02-AUDIT-INDEXING' guides/audit-indexing.md` | ⬜ W0 | ⬜ pending |
| 29-01-02 | 01 | 1 | IDX-01 | T-29-02 | N/A | compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 29-01-03 | 01 | 1 | IDX-01 | T-29-03 | N/A | grep links | `grep -q 'audit-indexing.md' guides/domain-reference.md` | ⬜ W0 | ⬜ pending |
| 29-02-01 | 02 | 2 | IDX-02 | — | N/A | unit | `mix test test/threadline/audit_indexing_doc_contract_test.exs` | ⬜ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `guides/audit-indexing.md` — created by plan 29-01 (not pre-existing)
- [ ] `test/threadline/audit_indexing_doc_contract_test.exs` — created by plan 29-02

**Existing infrastructure:** `mix format`, Credo (if enabled), CI aliases cover global quality.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cookbook readability | IDX-01 | Tone and pedagogy | Skim `guides/audit-indexing.md` after merge |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented grep gates
- [ ] Sampling continuity: compile or targeted test after each plan
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when phase execution completes

**Approval:** pending
