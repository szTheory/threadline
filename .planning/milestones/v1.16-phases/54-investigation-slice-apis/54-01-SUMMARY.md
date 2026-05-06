---
phase: 54
plan: "54-01"
title: Public investigation helper entrypoints
date: 2026-05-05
files_changed:
  - lib/threadline.ex
  - lib/threadline/investigation.ex
  - lib/threadline/query.ex
  - test/threadline/investigation_test.exs
verification:
  - command: mix test test/threadline/investigation_test.exs --max-failures 1
    result: passed - 6 tests, 0 failures
  - command: rg "def (row_history|row_history_page|actor_window|actor_window_page|correlation_bundle|correlation_bundle_page)\(" lib/threadline.ex lib/threadline/investigation.ex
    result: passed - all six eager/paged helper pairs present in both public and helper modules
  - command: mix test test/threadline/query_test.exs test/threadline/investigation_test.exs --max-failures 1
    result: passed - 54 tests, 0 failures
---

# Phase 54 Plan 54-01 Summary

Added the first public investigation helper layer so adopters can ask the canonical row-history, actor-window, and correlation-bundle questions from `Threadline` without rebuilding filter composition by hand.

## What Changed

- Added `Threadline.row_history/4`, `row_history_page/4`, `actor_window/3`, `actor_window_page/3`, `correlation_bundle/3`, and `correlation_bundle_page/3` as the public discovery surface.
- Added `Threadline.Investigation` to hold the higher-level helper contracts and keep reserved helper predicates explicit instead of widening the low-level timeline filter vocabulary.
- Added `Threadline.Query.row_history/4`, `row_history_page/4`, and `row_history_query/3` so row history reuses the existing timeline ordering and keyset cursor behavior while still constraining one schema row by table plus primary-key JSON.
- Added focused investigation tests that prove row scoping, actor-wide multi-table reads, strict correlation inner-join semantics, and paged/eager parity across all three helper families.

## Verification

- `mix test test/threadline/investigation_test.exs --max-failures 1`
  - Passed: `6 tests, 0 failures`
- `rg "def (row_history|row_history_page|actor_window|actor_window_page|correlation_bundle|correlation_bundle_page)\(" lib/threadline.ex lib/threadline/investigation.ex`
  - Passed: all expected public/helper function definitions found
- `mix test test/threadline/query_test.exs test/threadline/investigation_test.exs --max-failures 1`
  - Passed: `54 tests, 0 failures`

## Deviations

None. The plan executed as written.
