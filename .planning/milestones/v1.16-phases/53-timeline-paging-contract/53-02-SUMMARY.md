---
phase: 53
plan: "53-02"
title: Public timeline paging entrypoint and docs
date: 2026-05-05
files_changed:
  - lib/threadline.ex
  - README.md
  - guides/domain-reference.md
  - guides/getting-started-saas.md
  - test/support/readme_quickstart_fixtures.ex
  - test/threadline/query_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/exploration_routing_doc_contract_test.exs
  - test/threadline/getting_started_saas_doc_contract_test.exs
verification:
  - command: mix test test/threadline/query_test.exs
    result: passed - 48 tests, 0 failures
  - command: mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/getting_started_fixtures_test.exs
    result: passed - 23 tests, 0 failures
  - command: mix verify.test
    result: passed - 257 tests, 0 failures, 1 excluded
---

# Phase 53 Plan 53-02 Summary

Exposed the shipped timeline paging contract as a documented top-level `Threadline` investigation path and aligned README plus guide surfaces around one canonical eager-vs-paged story.

## What Changed

- Clarified `Threadline.timeline/2` docs as the eager compatibility path and documented `Threadline.timeline_page/2` as the stable keyset path for large investigation windows.
- Updated `README.md` to list `Threadline.timeline_page/2` in the public API inventory and quick-start audit trail examples.
- Updated `guides/domain-reference.md` exploration routing guidance to point adopters at `Threadline.timeline_page/2` for large windows while keeping `Threadline.timeline/2` as the simple eager path.
- Updated `guides/getting-started-saas.md` with a minimal paged investigation example and guidance to continue with `next_cursor` instead of offsets.
- Added a compile-checked README fixture for the public paged call shape and strengthened doc-contract tests to lock the new public surface and routing story.
- Extended `test/threadline/query_test.exs` with a top-level delegator proof showing `Threadline.timeline_page/2` matches the query-layer result while `Threadline.timeline/2` remains eager and list-based.

## Verification

- `mix test test/threadline/query_test.exs`
  - Passed: `48 tests, 0 failures`
- `mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/getting_started_fixtures_test.exs`
  - Passed: `23 tests, 0 failures`
- `mix verify.test`
  - Passed: `257 tests, 0 failures (1 excluded)`

## Deviations

None. The plan executed as written.
