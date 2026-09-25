---
phase: 203-real-gates
plan: 04
subsystem: code quality / credo gate
status: complete
tags: [gate-01, gate-02, credo, alias-usage, mechanical-sweep]
requires: [203-03]
provides:
  - "0 Design.AliasUsage findings in every file outside test/threadline/operator_surface/ under Credo full defaults"
affects: [203-05, 203-07]
tech-stack:
  added: []
  patterns:
    - "One refactor commit per test directory for mechanical Credo sweeps (blame-ignorable)"
    - "Nested modules in a test file alias the module in their own body, not through the outer module's lexical scope"
    - "`as:` is used only when the short name would shadow a module the file really uses (Oban)"
key-files:
  created: []
  modified:
    - test/mix/tasks/threadline.evidence_show_test.exs
    - test/mix/tasks/threadline.incident_test.exs
    - test/mix/tasks/threadline/export_test.exs
    - test/support/stress_router_prod_compile.exs
    - test/threadline/audit_transaction_test.exs
    - test/threadline/continuity_brownfield_test.exs
    - test/threadline/health_test.exs
    - test/threadline/verify_coverage_task_test.exs
    - test/threadline/capture/trigger_context_test.exs
    - test/threadline/capture/trigger_test.exs
    - test/threadline/export/cleanup_test.exs
    - test/threadline/export/orchestrator_test.exs
    - test/threadline/export_queue/oban_test.exs
    - test/threadline/storage/s3_test.exs
decisions:
  - "Threadline.ExportQueue.Oban is aliased `as: ObanAdapter` in oban_test.exs because the bare `Oban` there is the real Oban module passed as `oban_name:`; a plain alias would have changed test behavior"
  - "stress_router_prod_compile.exs: StressRouter is a required macro module, not a route target, so `alias` + `require StressRouter` leaves scope resolution unchanged; the MIX_ENV=prod compile test proves it"
metrics:
  duration: 3min
  completed: 2026-09-22
  tasks: 2
  files: 14
commits: 7
plan_head_before: b6f1839078768bdd69996079ee45a13644b229a6
actuals:
  tokens: 3400
  tasks: 2
  commits: 7
---

# Phase 203 Plan 04: AliasUsage sweep in non-contract tests outside operator_surface Summary

All 116 `Design.AliasUsage` findings in the 14 non-contract test files outside `test/threadline/operator_surface/` are fixed. The work is in 7 directory-batched `refactor(203-04)` commits. There was no config change and no `credo:disable` comment.

Plan base SHA: `b6f1839078768bdd69996079ee45a13644b229a6` (also stored in the git dir as `gsd-203-04-base`).

## Counts (measured live with `mix credo --strict --config-file deps/credo/.credo.exs --format json`)

| Measure | Before | After |
|---------|--------|-------|
| AliasUsage, all | 303 | 187 |
| AliasUsage, outside test/threadline/operator_surface/ | 116 | 0 |
| AliasOrder, all | 9 | 9 (all in pre-existing files) |
| Total findings | 429 | 313 |

The remaining 187 AliasUsage findings are all in `test/threadline/operator_surface/`. Plan 05 owns them.

## Tasks

| Task | Name | Commits | Files |
|------|------|---------|-------|
| 1 | Alias sweep in test/mix/tasks, test/support, top-level test/threadline | 0da44bf9, e7ad0968, adc4ea78 | 8 |
| 2 | Alias sweep in test/threadline/{capture,export,export_queue,storage} | 9ece3a2b, b58be3bb, 8fd13a06, 7a62e7b4 | 6 |

Commits:
- 0da44bf9 refactor(203-04): alias repeated module references in test/mix/tasks/
- e7ad0968 refactor(203-04): alias repeated module references in test/support/
- adc4ea78 refactor(203-04): alias repeated module references in test/threadline/
- 9ece3a2b refactor(203-04): alias repeated module references in test/threadline/capture/
- b58be3bb refactor(203-04): alias repeated module references in test/threadline/export/
- 8fd13a06 refactor(203-04): alias repeated module references in test/threadline/export_queue/
- 7a62e7b4 refactor(203-04): alias repeated module references in test/threadline/storage/

## Aliases added

Only one `as:` name was chosen: `alias Threadline.ExportQueue.Oban, as: ObanAdapter` in `test/threadline/export_queue/oban_test.exs`. All other aliases use the default short name:
- `Mix.Tasks.Threadline.Evidence.Show`, `Mix.Tasks.Threadline.Incident`, `Mix.Tasks.Threadline.Export`
- `Threadline.OperatorSurface.StressRouter` (alias + `require StressRouter`)
- `Threadline.Capture.TriggerSQL` (audit_transaction, continuity_brownfield, health, trigger_context, trigger tests)
- `Ecto.Adapters.SQL`, `Threadline.Health.CoverageSchemas` (health_test)
- `Ecto.Adapters.SQL`, `Mix.Tasks.Threadline.Health.Coverage`, `Mix.Tasks.Threadline.VerifyCoverage`, `Threadline.Verify.CoveragePolicy` (verify_coverage_task_test)
- `Threadline.Storage.Local`: in the outer module of cleanup_test, and inside each nested storage module that uses it (2 in cleanup_test, 3 in orchestrator_test; orchestrator_test's outer module already had it)
- `Threadline.Storage.S3` (s3_test)

## Verification

- `mix compile --warnings-as-errors`: clean after each batch
- `mix test` on the three test/mix/tasks files: 12 tests, 0 failures
- `mix test test/threadline/operator_surface/stress_router_test.exs`: 20 tests, 0 failures. This includes the `MIX_ENV=prod mix run` compile of `stress_router_prod_compile.exs`, which asserts the fail-closed macro message.
- `mix test` on the four top-level test/threadline files: 36 tests, 0 failures
- `mix test test/threadline/capture test/threadline/export test/threadline/export_queue test/threadline/storage`: 55 tests, 0 failures
- The Task 2 jq gate printed `true`: AliasUsage is 0 outside operator_surface, and every AliasOrder finding is in a pre-existing file.
- `mix verify.format`: exit 0
- Refactor commit count since the base: 7
- `grep -rnE "credo:(disable|enable)" lib test`: no matches

## Deviations from Plan

None. The plan executed as written. The plan text expected `Threadline.Test.Repo` and `Ecto.Adapters.SQL` findings in cleanup_test/orchestrator_test, but the measured flagged lines there were all `Threadline.Storage.Local`, so only that module was aliased.

## Known Stubs

None.

## Self-Check: PASSED

- All 14 modified files exist, and all 7 commit hashes are present in `git log`.
