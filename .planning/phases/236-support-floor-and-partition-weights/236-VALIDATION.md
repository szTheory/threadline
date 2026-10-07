---
phase: "236"
slug: "support-floor-and-partition-weights"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 236 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Mix/Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` |
| **Full suite command** | `mix ci.all` against PostgreSQL 15 |
| **Estimated runtime** | ~15 minutes (planning estimate; confirm during execution) |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs`
- **After every plan wave:** Run `mix ci.all` against PostgreSQL 15 when the wave changes the support floor or shared test behavior; otherwise run the focused command above
- **Before `$gsd-verify-work`:** Full suite must be green against PostgreSQL 15
- **Max feedback latency:** 60 seconds for focused contract tests

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 236-01-01 | 01 | 0 | FLOOR-01 | T-236-01 | Min-lane PostgreSQL value cannot drift from 15 | contract | `mix verify.test test/threadline/ci_topology_contract_test.exs` | ✅ existing; extend | ⬜ pending |
| 236-01-02 | 01 | 0 | FLOOR-02 | T-236-02 | Published floor and tested-on lane claims match Mix and CI sources | doc contract | `mix verify.test test/threadline/guides/upgrade_path_contract_test.exs` | ❌ Wave 0 | ⬜ pending |
| 236-01-03 | 01 | 0 | CI-01 | T-236-03 | Removing one measured test path makes the completeness contract fail | contract + mutation control | `mix verify.test test/threadline/ci_topology_contract_test.exs` | ✅ existing; extend | ⬜ pending |
| 236-01-04 | 01 | 1 | FLOOR-01, FLOOR-02, CI-01 | T-236-01, T-236-02, T-236-03 | Measured weights cover the final test inventory and the complete verification chain passes on PostgreSQL 15 | integration | `bin/ci-test-partitions --write-weights` then `mix ci.all` | ✅ existing tooling | ⬜ pending |

*The task map is a research-based draft; reconcile task IDs and waves with the finalized PLAN.md.*

---

## Wave 0 Requirements

- [ ] `test/threadline/guides/upgrade_path_contract_test.exs` — add support-table contract coverage for FLOOR-02
- [ ] `test/threadline/ci_topology_contract_test.exs` — extend topology and weight-completeness contracts with red mutation controls
- [ ] Existing ExUnit and PostgreSQL fixtures cover all phase requirements; no framework installation is required

---

## Manual-Only Verifications

All phase behaviors have automated verification. The PostgreSQL 15 full-suite run is an integration gate, not a manual-only check.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for focused contract tests
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
