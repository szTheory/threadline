---
phase: "233"
slug: "lookup-return-shapes"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| **Quick run command** | `mix test test/threadline/not_found_error_test.exs test/threadline/lookup_return_shapes_contract_test.exs test/threadline/query/scope_fail_closed_test.exs test/threadline/transaction_lookup_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/deprecation_parity_test.exs` |
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
| API-06 / SC1 | all three plain lookups return `{:ok, _}` for present rows and `{:error, :not_found}` for missing rows | integration | `mix test test/threadline/transaction_lookup_test.exs test/threadline/investigation_test.exs` | ✅ | ✅ green |
| API-06 / SC2 | all three bang siblings return the bare value or raise `NotFoundError`; malformed binary and invalid non-binary ids are distinguished | integration | `mix test test/threadline/transaction_lookup_test.exs test/threadline/not_found_error_test.exs` | ✅ | ✅ green |
| API-06 / SC3 | migrated callers compile warning-free; full repository CI gate | contract | `mix compile --warnings-as-errors && mix ci.all` | ✅ | ⚠️ Phase checks pass; full gate has 3 sandbox-related failures (see notes) |
| D-05 | lookup doc-contract, reverse drift checks, and `as_of/4` exemption | contract | `mix test test/threadline/lookup_return_shapes_contract_test.exs` | ✅ W0 | ✅ green |
| D-06 | deprecated `Query.audit_transaction/2` parity + `__info__(:deprecated)` | contract | `mix test test/threadline/deprecation_parity_test.exs` | ✅ | ✅ green |
| D-09..D-14, D-18 | zero-change transactions, scope surfaces, query count, unknown keys, `.action` hydration, malformed ids | integration | `mix test test/threadline/transaction_lookup_test.exs test/threadline/investigation_test.exs` | ✅ | ✅ green |
| D-17 | `NotFoundError` message, Plug 404/actions, and raised exception | unit | `mix test test/threadline/not_found_error_test.exs` | ✅ W0 | ✅ green |
| D-20 | `Scope.apply` fails closed across scoped reads | integration | `mix test test/threadline/query/scope_fail_closed_test.exs` | ✅ W0 | ✅ green |
| D-22 | `TransactionLive` `/transactions/not-a-uuid` renders not-found | LiveView | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/threadline/not_found_error_test.exs` — `NotFoundError` message, `Plug.Exception` status/actions
- [x] `test/threadline/lookup_return_shapes_contract_test.exs` — D-05 doc-contract
- [x] `test/threadline/query/scope_fail_closed_test.exs` — D-20 fail-closed matrix
- [x] Partition weights already contain all three Wave 0 test files; no new tests were needed.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s for the Phase 233 targeted run
- [x] `nyquist_compliant: true` set in frontmatter

## Audit Results (2026-10-07)

- Confirmed the three Wave 0 files exist and the partition-weight file has an entry for each. Their behaviors are covered: exception contract (3 tests), lookup-family docs (bidirectional export/spec/doc contract), and fail-closed behavior across every scoped read.
- Refreshed Phase 233 focused command: 138 tests, 0 failures. `mix compile --warnings-as-errors` also passed.
- Full `mix ci.all` reached the full suite and reported 32 properties, 3058 tests, 3 failures, 3 excluded. The failures are environment-bound clean-checkout tests: Git cannot create `.git/worktrees` in this sandbox, Hex cannot persist `/Users/jon/.hex/cache.ets`, and npm cannot write `/Users/jon/.npm/_cacache`. The example app suite passed (132 tests, 0 failures); Dialyzer passed. The remaining silent browser lane was interrupted after more than a minute without output. The repository-wide CI gate cannot be certified green in this environment.
- No Phase 233 test gaps remain. No test files or implementation files were changed during this audit.

**Approval:** automated validation refreshed; repository-wide CI remains environment-blocked
