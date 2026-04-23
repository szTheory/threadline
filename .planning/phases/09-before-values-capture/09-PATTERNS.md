# Phase 9 — Pattern map (analog code)

## Trigger + audit persistence

| Planned touch | Role | Closest analog | Excerpt / pattern |
|---------------|------|----------------|-------------------|
| `TriggerSQL` body / builders | PL/pgSQL source of truth | `lib/threadline/capture/trigger_sql.ex` `install_function/0` | UPDATE `jsonb_each` join + `IS DISTINCT FROM`; INSERT list for `audit_changes` |
| Per-table migration emission | Mix codegen | `lib/mix/tasks/threadline.gen.triggers.ex` | `migration_content/1` + `OptionParser.parse/2` strict flags |
| Additive audit DDL | Install migration string | `lib/threadline/capture/migration.ex` | `CREATE TABLE IF NOT EXISTS audit_changes` column list + `execute(inspect(TriggerSQL.install_function()))` |
| Integration harness | Temp audited table + Repo | `test/threadline/capture/trigger_test.exs` | `setup_all` `CREATE TABLE`, `create_trigger`, `Repo.all(AuditChange)` |

## Query / public API

| Planned touch | Role | Closest analog | Notes |
|---------------|------|----------------|-------|
| `Threadline.history/3` | Delegates to Query | `lib/threadline.ex` → `Threadline.Query.history/3` | No `select` merge today — keep default load of all schema fields |
| `AuditChange` struct | Ecto schema | `lib/threadline/capture/audit_change.ex` | Add `field(:changed_from, :map)` beside `data_after` |

## Data flow (target)

```
UPDATE on audited table
  → trigger function (global or per-table variant from gen)
  → INSERT audit_changes (..., changed_fields, changed_from?, ...)
  → Threadline.Query.history/3
  → %AuditChange{changed_from: map | nil}
```
