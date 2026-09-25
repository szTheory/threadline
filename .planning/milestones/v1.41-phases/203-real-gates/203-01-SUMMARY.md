---
phase: 203-real-gates
plan: 01
subsystem: query / layer boundaries
status: complete
tags: [gate-03, layering, rename, contract-test]
requires: []
provides:
  - Threadline.Query.Scope (renamed from Threadline.OperatorSurface.Scope, @moduledoc false)
  - Threadline.Query.FilterParams (renamed from Threadline.OperatorSurface.Exports.FilterParams, @moduledoc false)
  - Threadline.LayerBoundaryContractTest (GATE-03 source-scan contract)
affects: [203-03, 203-06]
tech-stack:
  added: []
  patterns:
    - "Whole-module git mv + line-1 rename with every pin retargeted in the same commit"
    - "Source-scan contract with non-empty scan-set guard and existence-checked allowlist"
    - "Explicit @renamed_modules register for released CHANGELOG history"
key-files:
  created:
    - test/threadline/layer_boundary_contract_test.exs
  modified:
    - lib/threadline/query/scope.ex (moved)
    - lib/threadline/query/filter_params.ex (moved)
    - test/threadline/query/filter_params_test.exs (moved)
    - lib/threadline/query.ex
    - lib/threadline/export/orchestrator.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/start_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/operator_surface/exports_doc_contract_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - test/threadline/code_walkthrough_doc_contract_test.exs
    - test/threadline/how_threadline_works_doc_contract_test.exs
decisions:
  - "Query.Scope and Query.FilterParams moved from :module_visibility_operator_helpers to :module_visibility_domain_tail in public_surface_contract_test (no longer operator helpers; both tag lists stay non-empty)"
  - "Released CHANGELOG 0.10.0 entry is not rewritten; public_surface_contract gains an explicit @renamed_modules register (old => new) accepted in CHANGELOG.md only, plus a test asserting each old name is gone, its successor compiled, and the changelog still names it"
  - "layer_boundary_contract_test folds the planning-independence self-guard into the non-empty-scan test so the contract stays at exactly 3 tests"
metrics:
  duration: "~6 min wall (plus test runs)"
  completed: 2026-09-22
actuals:
  tokens: 4350
  tasks: 2
  commits: 3
plan_head_before: 1ffd1ad03cf963ac3652ef280580c9abef3e5450
---

# Phase 203 Plan 01: Move query concepts out of OperatorSurface + GATE-03 contract Summary

`Threadline.OperatorSurface.Scope` and `Threadline.OperatorSurface.Exports.FilterParams` are now `Threadline.Query.Scope` and `Threadline.Query.FilterParams`. Both were moved with `git mv`, and only line 1 of each changed. A new source-scan contract test enforces GATE-03: no `lib/**/*.ex` outside the operator surface may reference `OperatorSurface`, and `lib/mix/tasks/critic.synth.ex` is the only allowlisted exception. The tracer proved the test RED on a real inversion before the second move turned it green.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | `634e7d35` | refactor(203-01): move OperatorSurface.Scope to Threadline.Query.Scope |
| 2 | `7c81654f` | refactor(203-01): move Exports.FilterParams to Threadline.Query.FilterParams |
| 2 | `d968f853` | refactor(203-01): add layer-boundary contract test (GATE-03) |

## Tracer RED output (after Scope move, before FilterParams move)

```
  1) test no lib module outside the operator surface references it (Threadline.LayerBoundaryContractTest)
     test/threadline/layer_boundary_contract_test.exs:59
     these lib files outside the operator surface reference OperatorSurface, which inverts the layering: ["lib/threadline/export/orchestrator.ex"]. ...
3 tests, 1 failure
```

`lib/threadline/query.ex` was absent from the output, which confirms the Scope move was complete. After `7c81654f` the result was 3 tests, 0 failures.

## Verification

- Task 1 pin tests (code_walkthrough, how_threadline_works, public_surface, query): 105 tests, 0 failures
- `mix compile --force --warnings-as-errors`: clean (106 files)
- Task 2 set (filter_params, exports_doc_contract, export_controller, public_surface, export/orchestrator, timeline_live, transaction_live, start_live, query, layer_boundary): 275 tests, 0 failures
- Full suite `DB_PORT=5433 mix test`: 1697 tests, 0 failures, 1 excluded (the pgbouncer_topology gate)
- `mix verify.format`: exit 0
- Credo gate (`deps/credo/.credo.exs --strict`): total 484, AliasOrder 11. The AliasOrder lines shifted as predicted: timeline_live 16, start_live 17, export_status_live 15. The new contract file has no Credo issues.
- Rename-in-place acceptance: every changed line in the five callers is a FilterParams alias line (exit 0)
- `lib/mix/tasks/critic.synth.ex` untouched; `String.to_atom` count in exports_doc_contract unchanged (4)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] public_surface_contract rejects the old module names still in the released CHANGELOG**
- **Found during:** Task 1
- **Issue:** `public_doc_refs_changelog` and the aggregate owner test check every module named in `CHANGELOG.md` against the compiled app. The released 0.10.0 entry (CHANGELOG.md:105, :113, tagged `v0.10.0`) names both old modules. RESEARCH said "Do not edit (history)", and it missed that this contract reads the changelog. The rename therefore failed 2 tests.
- **Fix:** CHANGELOG.md is not edited. An explicit `@renamed_modules` register (old => new) was added to `public_surface_contract_test.exs`, and it applies to the `CHANGELOG.md` subject only. A new test asserts that the register is non-empty, that each old name is gone from the compiled app, that each successor is compiled, and that the changelog still names each old name. The check on every other document is unchanged, so no pin was weakened, and the register is itself pinned. Scope was added in `634e7d35` and FilterParams in `7c81654f`.
- **Consequence for acceptance:** the check `grep -rn "Exports.FilterParams\|operator_surface/exports/filter_params" lib test` prints one intentional line: `test/threadline/public_surface_contract_test.exs:21` (the register key). There is no stale pin.

**2. [Minor] Self-guard placement**
- The planning-independence self-guard copied from `dialyzer_ignore_contract_test.exs` is folded into the "scan set is non-empty" test, so the contract has exactly the 3 tests the plan specifies.

## Notes

- Broken-windows ledger not appended: `.planning/WINDOWS.md` is a protected path for this run, and there are no stubs, skipped tests, or unrun verifies to record.
- Flagged assumption A-GATE-03 (the substring detector misses runtime-assembled module names) is carried unverified, as the plan states.

## Self-Check: PASSED

- FOUND: lib/threadline/query/scope.ex, lib/threadline/query/filter_params.ex, test/threadline/query/filter_params_test.exs, test/threadline/layer_boundary_contract_test.exs
- FOUND commits: 634e7d35, 7c81654f, d968f853
