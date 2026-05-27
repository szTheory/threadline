---
phase: 107-realistic-seed-data-demo-mix-tasks
plan: 02
subsystem: demo-ops
tags: [elixir, phoenix, demo-reset, delete-reply, truncate, mix-task]

requires:
  - phase: 107-realistic-seed-data-demo-mix-tasks
    plan: 01
    provides: Demo.Manifest literals and dev config keys
provides:
  - HelpDesk.delete_reply/3 for SEED-05 hard-delete path
  - ThreadlinePhoenix.Demo.Tables.truncate_sql/0 shared with audit tests
  - mix demo.reset with prod guard and Demo.Seed.run/0 stub
affects:
  - 107-03 seed runner
  - 107-04 contract tests
  - 108 walkthrough scripting

tech-stack:
  added: []
  patterns:
    - "Demo.Tables as SSOT for TRUNCATE list (D-107-03b)"
    - "Prod guard before app.start on destructive mix tasks (T-107-03)"
    - "delete_reply without record_action (D-107-05d)"

key-files:
  created:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/tables.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
    - examples/threadline_phoenix/lib/mix/tasks/demo.reset.ex
    - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex
    - examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_test.exs

key-decisions:
  - "Prod guard runs in Mix task before app.start so DATABASE_URL is not required to fail closed"
  - "Table name user_tokens (not plan typo users_tokens) per Sigra migration"
  - "Demo.Seed.run/0 logs stub warning until Plan 107-03 replaces it"

patterns-established:
  - "Pattern: audit tests and demo.reset import Demo.Tables.truncate_sql/0"

requirements-completed: [SEED-04]

duration: 25min
completed: 2026-05-27
---

# Phase 107 Plan 02: Reset, Delete, and Demo Tables Summary

**Reusable hard-delete API, shared demo truncate SQL, and `mix demo.reset` with production guard — walkthrough recovery without `ecto.drop`.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-27T17:10:00Z
- **Completed:** 2026-05-27T17:15:00Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- `HelpDesk.delete_reply/3` sets actor GUC, hard-deletes a reply, and scopes org `meta` on the capture transaction (no `:ticket_reply_deleted` action).
- `ThreadlinePhoenix.Demo.Tables` centralizes FK-safe `TRUNCATE … CASCADE` for demo fiction and audit tests.
- `mix demo.reset` truncates demo tables and calls `Demo.Seed.run/0` (stub until 107-03); blocked in `:prod` unless `DEMO_ALLOW_RESET=1`.

## Task Commits

Each task was committed atomically:

1. **Task 1: HelpDesk.delete_reply/3** - `5df28f3` (feat)
2. **Task 2: Demo.Tables shared truncate list** - `91b19d2` (feat)
3. **Task 3: mix demo.reset** - `52d9491` (feat)

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` - `delete_reply/3` public API
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/tables.ex` - `@tables` + `truncate_sql/0`
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex` - truncate + seed delegate + prod guard
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex` - stub `run/0` for Plan 107-03
- `examples/threadline_phoenix/lib/mix/tasks/demo.reset.ex` - Mix entrypoint
- `examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_test.exs` - uses `Tables.truncate_sql/0` and `delete_reply/3`
- `examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs` - truncate + prod guard tests

## Decisions Made

- Mix task calls `assert_dev_or_allowed!/0` before `app.start` so production fails fast without database config.
- Used `user_tokens` table name from Sigra schema (plan listed `users_tokens`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prod mix test hit DATABASE_URL before guard**
- **Found during:** Task 3 verification
- **Issue:** `mix demo.reset` called `app.start` before prod guard, so subprocess failed on missing `DATABASE_URL` instead of `DEMO_ALLOW_RESET`.
- **Fix:** Run `Demo.Reset.assert_dev_or_allowed!/0` before `app.start`; expose guard for unit tests with optional `env` argument.
- **Files modified:** `demo/reset.ex`, `mix/tasks/demo.reset.ex`, `demo_reset_test.exs`
- **Verification:** `mix test test/threadline_phoenix/demo_reset_test.exs` — 3 tests, 0 failures
- **Commit hash:** `52d9491` (same task commit)

**2. [Rule 3 - Naming] `users_tokens` → `user_tokens`**
- **Found during:** Task 2 implementation
- **Issue:** Plan table list typo does not match migration (`user_tokens`).
- **Fix:** Used actual table name in `@tables`.
- **Commit hash:** `91b19d2`

**Total deviations:** 2 auto-fixed (1 bug, 1 naming). **Impact:** Low — behavior matches CONTEXT D-107-03b; prod guard is stricter than originally wired.

## Issues Encountered

None

## User Setup Required

None

## Next Phase Readiness

- Ready for **107-03** (`Demo.Seed.run/0` implementation, hero upserts, anchor writes).
- `delete_reply/3` and `mix demo.reset` are callable from seed pipeline.
- **SEED-05** on-disk incident (#4518) still requires seed planting in 107-03; API is ready.

## Self-Check: PASSED

- `cd examples/threadline_phoenix && mix test test/threadline_phoenix/help_desk_audit_test.exs` — 2 tests, 0 failures
- `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_reset_test.exs` — 3 tests, 0 failures
- `help_desk.ex` contains `def delete_reply(`
- Delete test asserts `ac.op == "delete"` on `ticket_replies`
- `demo/tables.ex` defines `truncate_sql/0`
- `lib/mix/tasks/demo.reset.ex` exists

---
*Phase: 107-realistic-seed-data-demo-mix-tasks*
*Completed: 2026-05-27*
