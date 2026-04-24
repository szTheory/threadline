---
phase: 32-transaction-scoped-change-listing
plan: 32-01
subsystem: api
tags: [ecto, postgresql, audit, query, uuid, xplo-02]

requires:
  - phase: 31-field-level-change-presentation
    provides: Threadline.Query listing patterns, ChangeDiff boundary
provides:
  - Threadline.Query.audit_changes_for_transaction/2
  - Threadline.audit_changes_for_transaction/2 delegator
  - Integration tests for ordering, empty set, invalid UUID, preload
affects:
  - phase-33
  - exploration-docs

tech-stack:
  added: []
  patterns:
    - "Explicit :repo + optional :preload; list return shape matches history/timeline"
    - "UUID validated with Ecto.UUID.cast before query (clear ArgumentError)"

key-files:
  created: []
  modified:
    - lib/threadline/query.ex
    - lib/threadline.ex
    - test/threadline/query_test.exs

key-decisions:
  - "Strict :preload shape (nil, [], or list) to catch integrator typos early"

patterns-established:
  - "Transaction-scoped change listing reuses timeline_order/1 for ordering parity with timeline/2"

requirements-completed: [XPLO-02]

duration: 20min
completed: 2026-04-24
---

# Phase 32: Transaction-scoped change listing — Plan 32-01 Summary

**Public `audit_changes_for_transaction/2` on `Threadline.Query` and `Threadline` lists all capture changes for one `audit_transactions.id`, with the same `(captured_at, id)` descending order as `timeline/2`, UUID validation, and opt-in `:preload`.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Query API with `Ecto.UUID.cast/1` guard, `[]` for missing rows, `timeline_order/1` reuse
- Root delegator mirroring `history/3` style
- Repo tests covering ordering, parity, empty UUID, malformed id, `preload: [:transaction]`

## Task Commits

1. **Task 32-01-01 — `Threadline.Query.audit_changes_for_transaction/2`** — `2fc8eb1` (feat)
2. **Task 32-01-02 — delegator + `QueryTest`** — `b50851d` (feat)

## Files Created/Modified

- `lib/threadline/query.ex` — new function, moduledoc See also
- `lib/threadline.ex` — delegator and `@doc`
- `test/threadline/query_test.exs` — `describe "audit_changes_for_transaction/2 — XPLO-02"`

## Decisions Made

None beyond plan — followed **32-CONTEXT** D-1–D-5.

## Deviations from Plan

None — plan executed as written. Added explicit `ArgumentError` for non-list `:preload` (stricter than silent ignore).

## Issues Encountered

Local `mix test` without `DB_PORT=5433` failed (default Postgres role); **`DB_PORT=5433 mix test`** matches project parity gate from STATE.

## Next Phase Readiness

Phase 33 can document “which API when” including transaction drill-down vs `timeline/2`.

---
*Phase: 32-transaction-scoped-change-listing*
*Completed: 2026-04-24*
