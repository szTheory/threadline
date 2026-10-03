---
phase: "231"
slug: "facade-topology-and-the-capture-semantics-edge"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-03"
---

# Phase 231 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/public_surface_contract_test.exs test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~60 seconds (quick), several minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run targeted `mix test` on the touched files
- **After every plan wave:** Run `mix compile --warnings-as-errors && mix test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (filled by planner / validate-phase) | | | API-04, API-07 | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/facade_only_references_contract_test.exs` — SC2 / API-04 (D-12)
- [ ] Association-absence test (location chosen by planner) — SC3 / API-07

Existing `test/support/` helpers cover all fixtures.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
