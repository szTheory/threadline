---
phase: 107
slug: realistic-seed-data-demo-mix-tasks
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 107 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (example app) |
| **Config file** | `examples/threadline_phoenix/test/test_helper.exs` |
| **Quick run command** | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs` |
| **Full suite command** | `cd examples/threadline_phoenix && mix test` |
| **Estimated runtime** | ~15–45 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command above
- **After every plan wave:** Run full example app suite
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 107-01-01 | 01 | 1 | SEED-03 | T-107-01 | Manifest has no live secrets beyond demo password doc | unit | `mix test test/threadline_phoenix/demo_manifest_test.exs` | ❌ W0 | ⬜ pending |
| 107-02-01 | 02 | 2 | SEED-05 | T-107-02 | `delete_reply/3` sets actor GUC before delete | unit | `mix test test/threadline_phoenix/help_desk_audit_test.exs` | ✅ | ⬜ pending |
| 107-02-02 | 02 | 2 | SEED-04 | T-107-03 | `demo.reset` raises in prod without env | unit | `MIX_ENV=prod mix demo.reset` expect raise | ❌ W0 | ⬜ pending |
| 107-03-01 | 03 | 3 | SEED-01 | T-107-01 | `demo.seed` raises in prod without env | integration | `mix demo.seed` in test sandbox | ❌ W0 | ⬜ pending |
| 107-03-02 | 03 | 3 | SEED-02 | — | `:rand.seed` + hero stability | integration | demo_contract_test | ❌ W0 | ⬜ pending |
| 107-04-01 | 04 | 4 | SEED-03 | — | Heroes #4521, org Y, delete row | integration | demo_contract_test | ❌ W0 | ⬜ pending |
| 107-04-02 | 04 | 4 | SEED-04 | — | reset → same hero state | integration | reset contract in demo_contract_test | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_test.exs` — manifest module attribute smoke
- [ ] `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — post-seed hero + audit assertions (stubs OK in 107-01)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full 14-day timeline visual density | SEED-02 | Operator UI not asserted in CI | After seed, open `/audit` scoped to Acme, confirm ~50 tickets worth of activity |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
