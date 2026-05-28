---
phase: 123
slug: first-hour-config
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
updated: 2026-05-28T19:00:00Z
---

# Phase 123 — Validation Strategy

> Finalized Nyquist validation for first-hour config (Phase 126-02).
> Superseding closure authority: `123-VERIFICATION.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.14+) |
| **Config file** | `mix.exs` aliases `verify.doc_contract`, `verify.test` |
| **Quick run command** | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` or `mix test test/threadline/production_checklist_doc_contract_test.exs` |
| **Full suite command** | `mix verify.doc_contract` then `mix ci.all` |
| **Estimated runtime** | ~15–45 seconds (doc contracts only) |

---

## Sampling Rate

- **After every task commit:** Run the plan's targeted test file(s)
- **After every plan wave:** Run `mix verify.doc_contract`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 123-01-01 | 01 | 1 | CFG-01 | T-123-01 / — | Getting-started contains literal before §3 | doc contract | `mix test ...getting_started_saas...` | ✅ | ✅ green |
| 123-01-02 | 01 | 1 | CFG-02 | T-123-02 / — | Ordering + rationale fragments locked | doc contract | same | ✅ | ✅ green |
| 123-02-01 | 02 | 1 | CFG-03 | T-123-03 / — | Checklist section + backlink | doc contract | `mix test ...production_checklist...` | ✅ | ✅ green |
| 123-02-02 | 02 | 1 | CFG-03 | — | `verify.doc_contract` includes new test | integration | `mix verify.doc_contract` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new framework install.

- [x] ExUnit doc-contract pattern in `getting_started_saas_doc_contract_test.exs`
- [x] `production_checklist_doc_contract_test.exs` — present on current tree
- [x] `mix.exs` `verify.doc_contract` alias extended — includes production checklist test

*Wave 0 complete; both doc-contract files present.*

---

## Commands Actually Used

Phase 126-02 rerun bundle (2026-05-28T19:00:00Z):

1. `mix test test/threadline/getting_started_saas_doc_contract_test.exs`  
   Result: PASS (7 tests, 0 failures), exit 0
2. `mix test test/threadline/production_checklist_doc_contract_test.exs`  
   Result: PASS (1 test, 0 failures), exit 0
3. `mix verify.doc_contract`  
   Result: PASS (97 tests, 0 failures), exit 0

---

## Nyquist Notes

**Retroactive backfill:** Phase 126-02 finalized this artifact on the current tree. `123-VERIFICATION.md` remains the **superseding authority** for CFG-01/02/03 closure (getting-started §2 Configure band, production-checklist prerequisite, doc-contract tests). This VALIDATION file records the Nyquist rerun bundle and honest per-task map; it does not replace VERIFICATION traceability.

- `nyquist_compliant: true` applies only with the named commands above green on the same tree.
- ExDoc anchor row closed via **doc-contract proxy** (D-11): locked heading `### Configure Threadline` plus cross-link `getting-started-saas.md#configure-threadline` in `production_checklist_doc_contract_test.exs`. Evidence tier: **proven**.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ~~ExDoc anchor renders~~ | CFG-01 | ~~Markdown anchor slug not asserted in CI~~ | **Closed — proven via doc-contract proxy** (`### Configure Threadline` + `getting-started-saas.md#configure-threadline`). No `mix docs` HTML grep in PR CI (D-11). |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** finalized on 2026-05-28 after Phase 126-02 rerun bundle.
