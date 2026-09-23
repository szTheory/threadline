---
phase: 203-real-gates
plan: 05
subsystem: code quality / credo gate
status: complete
tags: [gate-01, gate-02, credo, alias-usage, mechanical-sweep]
requires: [203-04]
provides:
  - "0 Design.AliasUsage findings tree-wide (lib/ and test/) under Credo full defaults; all 356 fixed across Plans 03-05"
affects: [203-06, 203-07, 203-09, 203-10]
tech-stack:
  added: []
  patterns:
    - "An alias used inside a `quote do ... defmodule ... end` block has to live in the enclosing (quoting) module. Quote hygiene tags aliases inside the quoted body `alias: false`, so an alias declared inside the quoted defmodule does not resolve."
    - "Modules that `use Threadline.DataCase` already get `Repo`, `AuditChange`, and `AuditTransaction` aliases from the macro. Only the call sites are shortened; no redundant alias line is added."
key-files:
  created: []
  modified:
    - test/threadline/operator_surface/live/actor_live_test.exs
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/live/row_history_live_test.exs
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/breadcrumb_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - test/threadline/operator_surface/coverage_mix_test.exs
    - test/threadline/operator_surface/critic_trust_test.exs
    - test/threadline/operator_surface/exports_mix_parity_test.exs
    - test/threadline/operator_surface/policy_show_mix_test.exs
    - test/threadline/operator_surface/row_history_component_test.exs
    - test/threadline/operator_surface/skip_link_test.exs
    - test/threadline/operator_surface/stress_router_test.exs
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/ui_test.exs
decisions:
  - "No `as:` alias was needed anywhere in Plan 05. The test-local `*Test.Auth` modules (start_live_test and six others) are aliased plainly as `Auth` in their Router modules. No module in those scopes references the library `Threadline.OperatorSurface.Auth`, so there is no lexical collision, and this matches the existing house precedent in copy_contract_test.exs:42"
  - "stress_router_test.exs: the three Code.compile_quoted routers get their `StressRouter` alias from the enclosing StressRouterTest module, not from inside the quoted defmodule, because quote hygiene prevents the inner alias from resolving. Their `require Threadline.OperatorSurface.StressRouter` lines stay fully qualified"
metrics:
  duration: 7min
  completed: 2026-09-22
  tasks: 2
  files: 20
commits: 3
plan_head_before: 140a53cee72655ad7402fda9056c7521b5e153a8
actuals:
  tokens: 17800
  tasks: 2
  commits: 3
---

# Phase 203 Plan 05: AliasUsage sweep in operator_surface tests (sweep complete) Summary

The last 187 `Design.AliasUsage` findings are fixed. They were all in the 20 non-contract test files under `test/threadline/operator_surface/`. AliasUsage is now 0 across `lib/` and `test/` under Credo's full defaults. The change is 3 directory-batched `refactor(203-05)` commits with no config change, no path scoping, and no `credo:disable` comment.

Plan base SHA: `140a53cee72655ad7402fda9056c7521b5e153a8` (also stored in the git dir as `gsd-203-05-base`).

## Counts (measured live with `mix credo --strict --config-file deps/credo/.credo.exs --format json`)

| Measure | Before (this plan) | After |
|---------|--------------------|-------|
| AliasUsage, all | 187 | 0 |
| AliasOrder, all | 9 | 9 (all in pre-existing files) |
| Total findings | 313 | 126 |

Phase-level: 484 findings before Plan 03, and 126 now. That is within the plan's "at most 128" bound.

Whole-tree per-check histogram after this plan: AliasOrder 9, MaxLineLength 1, ParenthesesOnZeroArityDefs 1, PreferImplicitTry 7, StringSigils 4, WithSingleClause 1, CondStatements 3, CyclomaticComplexity 16, FilterFilter 2, MapJoin 18, NegatedConditionsWithElse 5, Nesting 30, RedundantWithClauseResult 11, RejectReject 2, UnlessWithElse 1, ExpensiveEmptyEnumCheck 6, MissedMetadataKeyInLoggerConfig 1, SpecWithStruct 8. The before histogram is identical except that it also has AliasUsage 187.

## Tasks

| Task | Name | Commits | Files |
|------|------|---------|-------|
| 1 | Alias sweep in test/threadline/operator_surface/live/ | d11c1c85 | 9 |
| 2 | Alias sweep in the remaining operator_surface tests, then prove the sweep complete | b6c72979, 1b31fcbc | 11 |

Commits (the `.git-blame-ignore-revs` candidate set, not committed here):
- d11c1c85 refactor(203-05): alias repeated module references in test/threadline/operator_surface/live/
- b6c72979 refactor(203-05): alias repeated module references in test/threadline/operator_surface/controllers/
- 1b31fcbc refactor(203-05): alias repeated module references in test/threadline/operator_surface/

## `as:` names chosen

None. Plan (b) asked for `as:` (for example `StartAuth`) only where `Auth` would collide with `Threadline.OperatorSurface.Auth`. A grep showed that no module which uses a test-local `*Test.Auth` references the library Auth module, either bare or qualified. The only such text is inside string literals in stress_router_test.exs:309/316, which are not code. So plain `alias ...StartLiveTest.Auth` is used in each of the three start_live routers. This follows the shared rule ("`as:` only when the short name already exists in that lexical scope") and the copy_contract_test.exs precedent.

## Remaining AliasOrder sites (pre-existing, not caused by this sweep)

- Plan 06 (lib): `lib/threadline.ex:9`, `lib/threadline/operator_surface/live/coverage_live.ex:12`, `export_status_live.ex:15`, `retention_history_live.ex:20`, `start_live.ex:17`
- Plan 07 (test): `test/support/data_case.ex:17`, `test/support/storage_schema_case.ex:9`, `test/threadline/export_queue/task_adapter_test.exs:4`, `test/threadline/storage_schema_integration_test.exs:5`
- `copy_contract_test.exs` no longer reports AliasOrder. An earlier plan absorbed it.

## Verification

- `mix compile --force --warnings-as-errors`: clean
- `mix test --warnings-as-errors test/threadline/operator_surface/live`: 190 tests, 0 failures
- `mix test --warnings-as-errors` on the 11 Task 2 files: 195 tests, 0 failures (after the deviation fix below)
- Tree-wide jq gate (AliasUsage == 0 and AliasOrder only in the pre-existing set): `true`
- `DB_PORT=5433 mix test` (full suite): 1699 tests, 0 failures, 1 excluded
- `mix verify.format`: exit 0
- `grep -rnE "credo:(disable|enable)" lib test`: no output
- Commit-count acceptance: `3`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] An alias inside quoted router modules did not resolve**
- **Found during:** Task 2 (stress_router_test.exs)
- **Issue:** The first pass put `alias Threadline.OperatorSurface.StressRouter` inside the three `Code.compile_quoted(quote do defmodule ... end)` routers (ThrowawayRouter, ProdHookRouter, TestHookRouter). Quote hygiene marks the quoted `StressRouter` reference `alias: false`, so it stayed the bare atom `StressRouter`, and 2 tests failed with `module StressRouter is not available`.
- **Fix:** Removed the inner aliases and added `alias Threadline.OperatorSurface.StressRouter` to the enclosing `StressRouterTest` module, so the quoted reference expands to the full name when the quote is built. The compiled code is identical to before, and the file's 20 tests pass.
- **Files modified:** test/threadline/operator_surface/stress_router_test.exs
- **Commit:** 1b31fcbc (fixed before commit; no broken commit exists)

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: d11c1c85, b6c72979, 1b31fcbc (git log)
- FOUND: all 20 modified files exist
