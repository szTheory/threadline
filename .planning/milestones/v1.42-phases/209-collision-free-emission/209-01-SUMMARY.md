---
phase: 209-collision-free-emission
plan: 01
subsystem: test-infrastructure
status: complete
tags: [testing, postgres, telemetry, identifier-truncation, capture]
requires: []
provides:
  - Threadline.Test.NoticeGuard (attach!/0, handle/4, take/0,1, attached?/0, verify!/1)
  - canary contract proving a non-zero mix test exit on an undrained 42622 notice
  - client_min_messages = notice boot assertion
affects:
  - every later plan in this phase runs under the guard; byte-faithful long-name fixtures must drain with NoticeGuard.take/0
tech-stack:
  added: []
  patterns:
    - telemetry handler on [:threadline, :test, :repo, :query], matched on SQLSTATE code only
    - hits keyed by root of $callers (Task.async children attributed to the test)
    - after_suite + System.at_exit(exit({:shutdown, 1})) for a non-zero VM exit
    - canary .exs under test/support run only by explicit path (no exclude tag)
key-files:
  created:
    - test/support/notice_guard.ex
    - test/support/notice_guard_canary.exs
    - test/threadline/capture/notice_guard_test.exs
    - test/threadline/capture/notice_guard_canary_test.exs
  modified:
    - test/test_helper.exs
    - test/threadline/capture/trigger_rerun_test.exs
decisions:
  - "NoticeGuard keys hits by List.last($callers) || self(); a Task.async child's hit is drained by the parent test (assumption A1 now proven by test)"
  - "System.at_exit + exit({:shutdown, 1}) from after_suite gives mix test exit 1 (assumption A5 proven by the canary contract)"
  - "Canary negative case unsets the flag (env value nil) rather than setting it to 0"
metrics:
  duration: 570s
  completed: 2026-09-25
actuals:
  tokens: 2700
  tasks: 2
  commits: 2
plan_head_before: 27e54607200ed6da8e98d3fe6084c57e3ad76e6a
---

# Phase 209 Plan 01: Identifier-Truncation Guard Summary

Any PostgreSQL identifier-truncation NOTICE (SQLSTATE 42622) returned through `Threadline.Test.Repo` now fails `mix test`. A telemetry handler, attached before migrations, records these notices. An `after_suite` check reports them and sets a non-zero VM exit. A positive control, a negative control and a nested-`mix test` canary contract prove the guard works.

## Tasks

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | NoticeGuard end to end + fix the deliberate 67-byte fixture | 9db9077c | test/support/notice_guard.ex, test/test_helper.exs, test/threadline/capture/notice_guard_test.exs, test/threadline/capture/trigger_rerun_test.exs |
| 2 | Canary contract + client_min_messages boot assertion | 0e5ef028 | test/support/notice_guard_canary.exs, test/threadline/capture/notice_guard_canary_test.exs, test/test_helper.exs |

## TDD evidence

- Task 1 RED: `notice_guard_test.exs` failed 5/5 with `UndefinedFunctionError ... Threadline.Test.NoticeGuard.take/0`. GREEN: 14 tests, 0 failures (with trigger_rerun_test).
- Task 2 RED: the canary contract failed 2/2 (`Paths given to "mix test" did not match any directory/file: test/support/notice_guard_canary.exs`). GREEN: 2 tests, 0 failures. Run directly, the flagged canary exited 1 and printed `identifier truncation (SQLSTATE 42622)` with the 64-byte identifier.
- Boot assertion: I set `ALTER DATABASE threadline_test SET client_min_messages = warning` and the boot raised `client_min_messages is "warning", expected "notice"` (exit 1). I then reset the setting, and `SHOW client_min_messages` returned `notice` again.

## Verification

- `mix verify.test`, run after Task 1: `7 properties, 1929 tests, 0 failures, 1 excluded`, exit 0, no truncation report.
- `mix verify.test`, run after Task 2: `7 properties, 1931 tests, 0 failures, 1 excluded`, exit 0, no truncation report.
- The plan's Task 2 verify command (canary, controls, zero_skips_contract, test_structure_contract): 16 tests, 0 failures.
- `mix format --check-formatted` and `mix credo --strict` report no issues in the new or changed files.
- The ExUnit exclude list is unchanged (`[pgbouncer_topology: true]`). The canary has no `@tag` and no `@moduletag`.

## Deviations from Plan

None. The plan was executed as written. One small choice: the canary contract's "without the flag" case unsets `THREADLINE_TRUNCATION_GUARD_CANARY` (env value `nil`). It does not set it to `"0"`, so the case matches the plan's wording exactly.

## Notes for later plans

- Byte-faithful 0.9 fixtures that use uncut long names will produce a 42622 hit on purpose. Such a test must call `NoticeGuard.take/0` and assert the exact hit it expects. Hits from `Ecto.Migrator` (which runs in a `Task.async`) are attributed to the test process through `$callers`.
- Inside `mix ci.all`, a guard failure is printed right away. The non-zero exit only happens when the VM ends, after the remaining aliases have run.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: test/support/notice_guard.ex, test/support/notice_guard_canary.exs, test/threadline/capture/notice_guard_test.exs, test/threadline/capture/notice_guard_canary_test.exs
- FOUND: commits 9db9077c, 0e5ef028
