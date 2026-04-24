# Phase 25 — Pattern map (LOOP-01)

| Intended change | Role | Closest analog | Notes |
|-----------------|------|----------------|-------|
| New allowed filter + validation loop | Query API | `lib/threadline/query.ex` `@allowed_timeline_filter_keys`, `validate_timeline_filters!/1`, private `filter_by_*` | Copy unknown-key error string style. |
| Conditional predicate on joined semantics | Ecto composition | Same file `timeline_query/1` + `filter_by_actor/2` (JSONB `@>` fragment) | New join is plain FK + string equality — simpler than actor JSONB. |
| Filter parity test | Integration | `test/threadline/export_test.exs` → `describe "filter parity with timeline/2"` | Reuse `insert_transaction/1`, `insert_change/2`, `table_name/1`; add `AuditAction` insert + `action_id` on txn. |
| DX-03 validation tests | Unit | `test/threadline/query_test.exs` → `describe "DX-03: timeline_repo!/2 and validate_timeline_filters!/1"` | Extend with `:correlation_id` happy path and bad values. |
| JSON row shape | Export | `lib/threadline/export.ex` `change_map/1`, `csv_row/1` | Extend select in `export_changes_query` path — see `Query.export_changes_query/1` select map for column names. |
| CHANGELOG filter vocabulary | Docs | `CHANGELOG.md` recent entries for Query/Export | Follow Keep a Changelog subsection style used in repo. |

## Code excerpts (signatures)

- `Query.timeline_query(filters)` — starts `AuditChange |> join(:inner, [ac], at in AuditTransaction, ...)`.
- `Query.export_changes_query/1` — `validate` → `timeline_query` → `select([ac, at], %{...})`.
- `Export.change_map/1` — builds `"transaction"` map; add `"action"` map when action data present.
