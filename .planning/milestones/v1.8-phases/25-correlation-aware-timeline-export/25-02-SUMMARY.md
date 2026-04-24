---
phase: 25-correlation-aware-timeline-export
plan: "02"
subsystem: api
tags: [export, json, csv, tests]

key-files:
  created: []
  modified:
    - lib/threadline/export.ex
    - lib/threadline/query.ex
    - lib/threadline.ex
    - test/threadline/export_test.exs
    - test/threadline/query_test.exs
    - CHANGELOG.md

requirements-completed: [LOOP-01]

completed: 2026-04-24
---

# Plan 25-02 summary

**Export & docs:** `change_map/1` adds nested **`"action"`** with **`id`** and **`correlation_id`** when `aa_id` is present. **`to_csv_iodata/2`** supports **`include_action_metadata: true`** appending **`correlation_id`** and **`action_id`**. **`Threadline.timeline/2`** `@doc` lists **`:correlation_id`**. Integration tests: validation edge cases, strict join, JSON id parity with correlation filter, extended CSV columns. **CHANGELOG** `[Unreleased]` documents the filter, validation, SQL semantics, JSON, and CSV.

## Self-Check: PASSED

- `DB_PORT=5433 mix test`
