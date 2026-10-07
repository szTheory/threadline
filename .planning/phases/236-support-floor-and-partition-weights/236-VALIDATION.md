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

- **After every task commit:** Run every automated command mapped to that task below; use the focused topology and guide contracts for additional quick feedback
- **After every plan wave:** Run `mix ci.all` against PostgreSQL 15 when the wave changes the support floor or shared test behavior; otherwise run the quick command in Test Infrastructure
- **Before `$gsd-verify-work`:** Full suite must be green against PostgreSQL 15
- **Max feedback latency:** 60 seconds for focused contract tests

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Pass / failure signal | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-----------------------|-------------|--------|
| 236-01-01 | 01 | 1 | FLOOR-01, FLOOR-02 | T-236-01, T-236-02 | Min-lane PostgreSQL is exactly 15 and the source-derived support table detects drift | topology + doc contracts | `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | Exit 0 passes; nonzero detects min-lane drift, ineffective mutation controls, or a guide/source mismatch | ✅ topology existing; guide contract created in task | ⬜ pending |
| 236-01-01 | 01 | 1 | FLOOR-01, FLOOR-02 | T-236-01, T-236-02 | Changed ExUnit contracts and mix.exs follow the formatter contract | format | `mix verify.format` | Exit 0 passes; nonzero reports unformatted changed files | ✅ existing alias | ⬜ pending |
| 236-01-02 | 01 | 1 | FLOOR-01 | T-236-02 | README and Unreleased breaking entry agree with the guide and state the adopter action | doc contract + mutation control | `mix verify.test test/threadline/guides/upgrade_path_contract_test.exs` | Exit 0 passes; nonzero detects an absent or stale floor, guide link, upgrade action, or ineffective mutation control | ✅ created by 236-01-01 | ⬜ pending |
| 236-02-01 | 02 | 2 | CI-01 | T-236-03 | Removing one measured test path makes the completeness contract fail; regenerated weights cover the final inventory | contract + mutation control | `DB_HOST=localhost DB_PORT=55432 mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | Exit 0 passes; nonzero detects missing, malformed, or duplicate weights, or an ineffective omission control | ✅ existing topology contract; extend | ⬜ pending |
| 236-02-01 | 02 | 2 | CI-01 | T-236-03, T-236-04 | Every discovered test runs exactly once through the partition runner on PostgreSQL 15 | partitioned integration | `DB_HOST=localhost DB_PORT=55432 mix verify.test_partitioned` | Exit 0 passes; nonzero detects a skipped or duplicate test, swallowed partition failure, or failing partitioned test | ✅ existing alias and runner | ⬜ pending |
| 236-02-02 | 02 | 2 | FLOOR-01, FLOOR-02, CI-01 | T-236-04 | The complete verification chain passes against a recorded PostgreSQL 15 server | integration | `DB_HOST=localhost DB_PORT=55432 mix ci.all` | Exit 0 passes after the server-version precheck; nonzero detects a failed root, example, compile, Dialyzer, or browser gate | ✅ existing tooling | ⬜ pending |

*Task IDs and waves match 236-01-PLAN.md and 236-02-PLAN.md. Each runnable PLAN `<automated>` check has its own row; the PostgreSQL 15 server-version precheck in 236-02-02 remains a required acceptance condition.*

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

- [ ] All four tasks and all six PLAN `<automated>` checks have task-map coverage or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for focused contract tests
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
