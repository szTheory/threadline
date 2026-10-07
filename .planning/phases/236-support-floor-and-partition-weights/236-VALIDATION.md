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
| 236-01-01 | 01 | 1 | FLOOR-01, FLOOR-02 | T-236-01, T-236-02 | Min-lane PostgreSQL is exactly 15 and the source-derived support table detects drift | topology + doc contracts | `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | ✅ topology existing; guide contract created in task | ⬜ pending |
| 236-01-02 | 01 | 1 | FLOOR-01 | T-236-02 | README and Unreleased breaking entry agree with the guide and state the adopter action | doc contract + mutation control | `mix verify.test test/threadline/guides/upgrade_path_contract_test.exs` | ✅ created by 236-01-01 | ⬜ pending |
| 236-02-01 | 02 | 2 | CI-01 | T-236-03 | Removing one measured test path makes the completeness contract fail; regenerated weights cover the final inventory | contract + mutation control | `mix verify.test test/threadline/ci_topology_contract_test.exs` | ✅ existing; extend | ⬜ pending |
| 236-02-02 | 02 | 2 | FLOOR-01, FLOOR-02, CI-01 | T-236-04 | The complete verification chain passes against a recorded PostgreSQL 15 server | integration | `DB_HOST=localhost DB_PORT=55432 mix ci.all` | ✅ existing tooling | ⬜ pending |

*Task IDs and waves match 236-01-PLAN.md and 236-02-PLAN.md. Each task's PLAN verification gives the precise failure signal.*

---

## Wave 0 Requirements

- [ ] `test/threadline/guides/upgrade_path_contract_test.exs` — created test-first by 236-01-01, before support-table edits
- [ ] `test/threadline/ci_topology_contract_test.exs` — topology control created by 236-01-01; weight-completeness control added by 236-02-01 before regeneration
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
