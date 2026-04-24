---
phase: 24
slug: job-path-actions-adoption-pointers
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `examples/threadline_phoenix/config/test.exs` |
| **Quick run command** | `cd examples/threadline_phoenix && mix test test/path/to/phase24_test.exs` |
| **Full suite command** | `MIX_ENV=test mix verify.example` (from repo root) |
| **Estimated runtime** | ~30–90 seconds (example app + DB) |

---

## Sampling Rate

- **After every task commit:** Quick command on touched test file(s)
- **After every plan wave:** `MIX_ENV=test mix verify.example` from repo root
- **Before `/gsd-verify-work`:** Full suite green
- **Max feedback latency:** ~120s for full example gate

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-01 | 01 | 1 | REF-04 | T-24-01 | GUC only inside txn | compile | `mix compile --warnings-as-errors` in example | ⬜ W0 | ⬜ pending |
| 24-01-02 | 01 | 1 | REF-04 | T-24-01 | Same as above + cast attrs | integration | `mix test …/workers/post_touch_worker_test.exs` | ⬜ W0 | ⬜ pending |
| 24-01-03 | 01 | 1 | REF-05 | T-24-02 | No new HTTP; args validated | integration | same test file | ⬜ W0 | ⬜ pending |
| 24-02-01 | 02 | 2 | REF-05, REF-06 | — | Doc accuracy | unit | `mix verify.doc_contract` / README grep | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure** covers Phase 24 — example app, Postgres, `verify.example`, `DataCase`, Phase 23 `Blog` + `posts` triggers. No new Wave-0 stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| *None* | — | — | — |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented grep criteria
- [ ] Sampling continuity: worker test runs after Oban wiring tasks
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
