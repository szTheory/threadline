---
phase: 55
plan: "55-01"
title: Incident bundle library surface
date: 2026-05-05
files_changed:
  - lib/threadline.ex
  - lib/threadline/investigation.ex
  - lib/threadline/investigation/incident_bundle.ex
  - lib/threadline/query.ex
  - test/threadline/investigation_test.exs
  - test/threadline/query_test.exs
commits:
  - 4e28c55 feat(55-01): add incident bundle surface
  - 4e0d5bc test(55-01): lock raw helper compatibility
verification:
  - command: mix test test/threadline/investigation_test.exs --max-failures 1
    result: passed - 11 tests, 0 failures
  - command: mix test test/threadline/investigation_test.exs test/threadline/query_test.exs --max-failures 1
    result: passed - 60 tests, 0 failures
  - command: rg "def incident_bundle\\(|defmodule Threadline\\.Investigation\\.Incident(Bundle|Change)|\\{:error, :not_found\\}" lib/threadline.ex lib/threadline/investigation.ex lib/threadline/investigation/incident_bundle.ex
    result: passed - public delegator, typed bundle modules, and not-found path present
---

# Phase 55 Plan 55-01 Summary

Shipped the first-class incident bundle contract at the library surface so one transaction drill-down now returns linked transaction/action context, ordered bundled changes, and packaged JSON-ready diffs without changing the older raw helper APIs.

## What Changed

- Added `Threadline.incident_bundle/2` as the public singular lookup for incident drill-down.
- Added explicit `%Threadline.Investigation.IncidentBundle{}` and `%Threadline.Investigation.IncidentChange{}` structs so the contract stays typed and Elixir-native while preserving access to raw linked structs.
- Added an existence-aware `Threadline.Query.audit_transaction/2` helper so `incident_bundle/2` can distinguish a missing parent transaction from an existing transaction whose child change list is empty.
- Kept `transaction_context/2` and `audit_changes_for_transaction/2` unchanged while extending focused tests to prove ordering, diff packaging, empty-change semantics, and backward compatibility.

## Verification

- `mix test test/threadline/investigation_test.exs --max-failures 1`
  - Passed: `11 tests, 0 failures`
- `mix test test/threadline/investigation_test.exs test/threadline/query_test.exs --max-failures 1`
  - Passed: `60 tests, 0 failures`
- `rg "def incident_bundle\\(|defmodule Threadline\\.Investigation\\.Incident(Bundle|Change)|\\{:error, :not_found\\}" lib/threadline.ex lib/threadline/investigation.ex lib/threadline/investigation/incident_bundle.ex`
  - Passed: expected public/helper definitions and not-found handling found

## Deviations

None. The plan executed as written.
