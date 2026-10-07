---
phase: "233"
slug: "lookup-return-shapes"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-03"
---

# Phase 233 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.15+) |
| **Config file** | `test/test_helper.exs`; partition weights `test/partition_weights.txt` |
| **Quick run command** | `mix test test/threadline/investigation_test.exs test/threadline/query_test.exs test/threadline/query/action_hydration_test.exs test/threadline/deprecation_parity_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~60 seconds quick; full `ci.all` several minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick run command plus `mix compile --warnings-as-errors`
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds (quick run)

Local gate gotchas: a red Dialyzer step in `ci.all` may be a PLT cache miss — rebuild with `mix dialyzer --plt` before trusting it. Never run playwright directly.

---

## Per-Task Verification Map

Filled by the planner per task; requirement → test mapping from RESEARCH.md:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| API-06 / SC1 | plain lookups return `{:ok,_}` / `{:error,:not_found}` | unit | `mix test test/threadline/investigation_test.exs` | ✅ extend | ⬜ pending |
| API-06 / SC2 | bang siblings return value / raise `NotFoundError` | unit | `mix test test/threadline/investigation_test.exs test/threadline/not_found_error_test.exs` | ❌ W0 | ⬜ pending |
| API-06 / SC3 | callers migrated, CHANGELOG, ci green | contract | `mix compile --warnings-as-errors && mix ci.all` | ✅ | ⬜ pending |
| D-05 | lookup doc-contract with `as_of/4` exemption | contract | `mix test test/threadline/lookup_return_shapes_contract_test.exs` | ❌ W0 | ⬜ pending |
| D-06 | deprecated `Query.audit_transaction/2` parity + `__info__(:deprecated)` | contract | `mix test test/threadline/deprecation_parity_test.exs` | ✅ extend | ⬜ pending |
| D-09..D-14, D-18 | zero-change txn, scope surfaces, query count ≤ 3, unknown keys, `.action` hydration, malformed ids | integration | `mix test test/threadline/investigation_test.exs test/threadline/query/action_hydration_test.exs` | ✅ extend | ⬜ pending |
| D-17 | `NotFoundError` 404, message has id only | unit | `mix test test/threadline/not_found_error_test.exs` | ❌ W0 | ⬜ pending |
| D-20 | `Scope.apply` fails closed on every scoped read | integration | `mix test test/threadline/query/scope_fail_closed_test.exs` | ❌ W0 | ⬜ pending |
| D-22 | `TransactionLive` `/transactions/not-a-uuid` renders not-found | LiveView | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/not_found_error_test.exs` — `NotFoundError` message, `Plug.Exception` status/actions
- [ ] `test/threadline/lookup_return_shapes_contract_test.exs` — D-05 doc-contract
- [ ] `test/threadline/query/scope_fail_closed_test.exs` — D-20 fail-closed matrix
- [ ] `bin/ci-test-partitions --write-weights` after new test files; commit `test/partition_weights.txt`

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
