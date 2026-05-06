---
phase: 54
plan: "54-02"
title: Linked investigation result shapes
date: 2026-05-05
files_changed:
  - lib/threadline.ex
  - lib/threadline/investigation.ex
  - lib/threadline/investigation/linked_change.ex
  - lib/threadline/query.ex
  - test/threadline/investigation_test.exs
  - test/threadline/query_test.exs
verification:
  - command: mix test test/threadline/investigation_test.exs --max-failures 1
    result: passed - 8 tests, 0 failures
  - command: mix test test/threadline/investigation_test.exs test/threadline/query_test.exs --max-failures 1
    result: passed - 57 tests, 0 failures
  - command: rg "def(transaction_| transaction_)|defstruct .*LinkedChange|audit_changes_for_transaction" lib/threadline.ex lib/threadline/investigation.ex lib/threadline/investigation/linked_change.ex
    result: passed - transaction_context and audit_changes_for_transaction linkage present; LinkedChange exists in the linked result module
  - command: rg -L "change_diff" lib/threadline/investigation.ex lib/threadline/investigation/linked_change.ex
    result: no output; direct match check `rg -n "change_diff" ...` also returned no matches, confirming Phase 55 diff rendering is still absent
  - command: rg "LinkedChange|transaction_(slice|context)|change_diff|backward-compatible|timeline_page" test/threadline/investigation_test.exs test/threadline/query_test.exs
    result: passed - helper/result-shape and backward-compatibility assertions are present in the focused test files
commits:
  - 882d660
  - 15d9b92
---

# Phase 54 Plan 54-02 Summary

Implemented linked investigation result shapes so the Phase 54 helper layer now returns explicit transaction/action context instead of bare `%AuditChange{}` rows, while keeping the older query primitives unchanged and leaving Phase 55 incident-bundle behavior out of scope.

## What Changed

- Added `%Threadline.Investigation.LinkedChange{}` and `%Threadline.Investigation.LinkedTransaction{}` as the helper-layer contracts for linked investigation reads.
- Updated row, actor, and correlation helpers in `Threadline.Investigation` to preload `transaction: :action` and return linked wrapper results while preserving existing ordering and filter semantics.
- Added `Threadline.transaction_context/2` as the public transaction-oriented drill-down helper built on `audit_changes_for_transaction/2`.
- Added focused investigation tests proving the richer helper shapes expose linked change, transaction, and optional action context without `change_diff` or incident-bundle payload fields.
- Added focused compatibility coverage proving `history/3`, `actor_history/2`, `timeline/2`, `timeline_page/2`, and `audit_changes_for_transaction/2` still return plain Ecto structs unchanged.

## Deviations

None in behavior. The only verification quirk was `rg -L "change_diff" ...` returning no output, so I confirmed the intended boundary with a direct `rg -n "change_diff" ...` check, which found no matches.
