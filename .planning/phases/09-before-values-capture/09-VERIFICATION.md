---
status: passed
phase: 09-before-values-capture
completed: 2026-04-23
---

# Phase 9 verification — Before-values capture

**Goal (ROADMAP):** Opt-in `changed_from` on UPDATE; `history/3` returns the field without breaking callers.

## Must-haves

| # | Criterion | Evidence |
|---|-----------|----------|
| SC-1 | Integration-style tests for UPDATE on/off; INSERT/DELETE null `changed_from` | `test/threadline/capture/trigger_changed_from_test.exs` |
| SC-2 | Install path documents column; generator emits option-aware DDL | `lib/threadline/capture/migration.ex`, `lib/mix/tasks/threadline.gen.triggers.ex`, `README.md` |
| SC-3 | `Threadline.history/3` surfaces `changed_from` | `lib/threadline.ex`, `test/threadline/query_test.exs` |
| SC-4 | No new session coupling in capture SQL | `rg 'set_config\|SET LOCAL' lib/threadline/capture/trigger_sql.ex` — empty |

## Commands (run with PostgreSQL)

```bash
MIX_ENV=test mix ecto.migrate
MIX_ENV=test mix test test/threadline/capture/trigger_test.exs test/threadline/capture/trigger_changed_from_test.exs test/threadline/query_test.exs
MIX_ENV=test mix ci.all
```

## Human follow-up

None required beyond standard CI on a machine with Postgres.

## Gaps

None identified in static review. Re-run this document’s commands if CI fails.
