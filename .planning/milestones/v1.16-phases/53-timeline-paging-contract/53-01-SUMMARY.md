---
phase: 53
plan: "53-01"
title: Timeline paging contract
date: 2026-05-05
files_changed:
  - lib/threadline/query.ex
  - lib/threadline.ex
  - lib/threadline/export.ex
  - test/threadline/query_test.exs
  - test/threadline/export_test.exs
verification:
  - command: mix test test/threadline/query_test.exs test/threadline/export_test.exs
    result: passed
  - command: mix verify.test
    result: passed
---

# Phase 53 Plan 53-01 Summary

Implemented an explicit keyset paging contract for timeline-style reads, anchored on descending `(captured_at, id)` order, without changing `Threadline.timeline/2`.

## What Changed

- Added `Threadline.Query.timeline_page/2` and `Threadline.Query.TimelinePage` with explicit `:page_size` and `:cursor` opts.
- Centralized keyset cursor advancement in `Threadline.Query.maybe_after_timeline_cursor/2`.
- Added `Threadline.timeline_page/2` as the public wrapper for the query-layer contract.
- Refactored `Threadline.Export.stream_changes/2` to reuse `Threadline.Query.timeline_page/2` instead of keeping a private cursor predicate.
- Added focused tests for invalid paging input, page concatenation parity, and timestamp-tie traversal.
- Strengthened export streaming parity coverage with a tie-heavy fixture.

## Verification

- `mix test test/threadline/query_test.exs test/threadline/export_test.exs`
  - Passed: `62 tests, 0 failures`
- `mix verify.test`
  - Passed: `256 tests, 0 failures (1 excluded)`

## Deviations

- The first attempt to run the two verification commands in parallel caused invalid shared-state interference in the build/test environment. Re-ran them sequentially, which is the correct execution mode for this repo.
- While aligning export with the shared paging primitive, fixed a restart bug in `Export.stream_changes/2` where a final partial page could restart from the beginning because `nil` was being used for both "start" and "done" cursor state.

