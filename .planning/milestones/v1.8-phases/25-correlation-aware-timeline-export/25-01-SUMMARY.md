---
phase: 25-correlation-aware-timeline-export
plan: "01"
subsystem: database
tags: [ecto, postgresql, audit, correlation]

key-files:
  created: []
  modified:
    - lib/threadline/query.ex
    - lib/threadline/export.ex

requirements-completed: [LOOP-01]

completed: 2026-04-24
---

# Plan 25-01 summary

**Query layer:** `:correlation_id` validation (trim, empty reject, 256-byte cap, nil rejected), `@allowed_timeline_filter_keys` and docs updated, `timeline_base_query/1` + `filter_by_correlation/2` + `timeline_order/1` pipeline, strict inner `AuditAction` join when the filter is set. **`timeline/2`** `select` arity matches two vs three bindings. **`export_changes_query/1`** diverges slightly from `timeline_query/1`: left join to `AuditAction` when the filter is absent so export rows can carry optional action ids without changing timeline semantics; inner join when the filter matches **25-CONTEXT** D-1. **`Export.count_matching`** / **`stream_changes`** binding lists fixed for `[ac, at]` / `[ac, at, aa]`.

## Self-Check: PASSED

- `DB_PORT=5433 mix test test/threadline/query_test.exs test/threadline/export_test.exs`
