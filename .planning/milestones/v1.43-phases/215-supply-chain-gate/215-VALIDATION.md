---
phase: "215"
slug: "supply-chain-gate"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-26"
---

# Phase 215 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3) |
| **Config file** | `test/test_helper.exs` (exclusion-tag pattern, e.g. `pgbouncer_topology: true`) |
| **Quick run command** | `mix test test/threadline/deps_audit_contract_test.exs test/threadline/ignore_advisories_contract_test.exs test/threadline/deps_health_doc_contract_test.exs` |
| **Full suite command** | `mix test` + `mix verify.deps_audit` |
| **Estimated runtime** | ~60 seconds (contract tests); `verify.deps_audit` network-bound |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Run `mix test` and `mix verify.deps_audit`
- **Before `/gsd-verify-work`:** Full suite must be green, plus a live `mix hex.audit` over all three lockfiles
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

To be filled by the planner / executor per task. Requirement → test map from RESEARCH.md:

| Task | Req | Behavior | Test Type | Automated Command | File Exists | Status |
|------|-----|----------|-----------|-------------------|-------------|--------|
| 215-01 T1 | SUP-01 | Root lock mint/lazy_html bump, root audit clean, deps block unchanged, NIF 2.16 present, fix(deps) commit + CHANGELOG | integration | `mix hex.audit` + lock-diff/deps-block/NIF/commit checks (215-01 T1 verify) + `mix test` + ci.all-form browser lane | ✅ (commands) | ⬜ pending |
| 215-01 T2 | SUP-01 | Bench package-group refresh; all three lockfiles audit clean; 214 baseline check green | integration | three `mix hex.audit` + `git diff --quiet 36ab6e71 -- bench/mix.exs examples/threadline_phoenix/mix.exs` + `check-project-baseline.sh` | ✅ (commands) | ⬜ pending |
| 215-02 T1 | SUP-02 | Gate behavior matrix (Hex floor boundary, aggregate, order, env refusal, empty/duplicate dirs) + live gate + negative self-test | unit (fake mix) + integration | `mix test test/threadline/deps_audit_gate_test.exs && mix verify.deps_audit && bin/verify-deps-audit --self-test` | ❌ W0 (created in task) | ⬜ pending |
| 215-02 T2 | SUP-02 | Job + header + ci-required needs + roster + table + ci.all in one commit | contract | `mix test test/threadline/deps_audit_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs` | ❌ W0 (created in task) | ⬜ pending |
| 215-03 T1-T2 | SUP-03 | Live resolved-config check over 3 projects + synthetic rule tests (today = expired, duplicates, stale, retirements, sorted output) | contract | `mix test test/threadline/ignore_advisories_contract_test.exs` | ❌ W0 (created in task) | ⬜ pending |
| 215-04 T1 | SUP-04 | deps-health-report classification + workflow shape | unit (fake mix) + contract | `mix test test/threadline/deps_health_report_test.exs` | ❌ W0 (created in task) | ⬜ pending |
| 215-04 T2-T3 | SUP-04, SUP-03 | CONTRIBUTING freshness policy ↔ workflow/gate facts; no dependabot.yml; least privilege; label distinct | doc-contract | `mix test test/threadline/deps_health_doc_contract_test.exs` | ❌ W0 (created in task) | ⬜ pending |

Negative-fixture design note: the network-backed "red on a known-vulnerable lock" proof is
`bin/verify-deps-audit --self-test`, which runs as a step of the `verify-deps-audit` CI job and is
contract-asserted. It is not a tagged ExUnit test, because test_helper.exs boots Postgres on every
`mix test` run. No test is excluded from default `mix test`.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/deps_audit_contract_test.exs` — SUP-02
- [ ] negative fixture project `test/fixtures/deps_audit/vulnerable_lock/` + `bin/verify-deps-audit --self-test` — SUP-02
- [ ] `test/threadline/deps_audit_gate_test.exs` (offline gate behavior) — SUP-02
- [ ] `test/threadline/deps_health_report_test.exs` — SUP-04
- [ ] `test/threadline/ignore_advisories_contract_test.exs` — SUP-03
- [ ] `test/threadline/deps_health_doc_contract_test.exs` — SUP-04

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
