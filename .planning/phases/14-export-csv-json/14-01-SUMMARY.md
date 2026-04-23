---
phase: 14-export-csv-json
plan: "01"
subsystem: database
tags: [ecto, csv, json, nimble_csv, export]

requires:
  - phase: 13
    provides: Retention patterns for result maps; no code dependency.
provides:
  - Shared timeline query with strict filter validation
  - Threadline.Export CSV/JSON/count/stream APIs
affects: [operators, hex-docs]

tech-stack:
  added: [nimble_csv]
  patterns: ["Single join to AuditTransaction for timeline + export", "Keyset stream with UUID cast"]

key-files:
  created: [lib/threadline/export.ex, test/threadline/export_test.exs]
  modified: [lib/threadline/query.ex, mix.exs, mix.lock, test/threadline/query_test.exs]

key-decisions:
  - "Strict timeline filter keys raise ArgumentError (shared with export)."
  - "CSV uses fixed columns plus transaction_json hybrid column."

patterns-established:
  - "export_changes_query/1 extends timeline_query/1 with select map."

requirements-completed: [EXPO-01, EXPO-02]

duration: 45min
completed: 2026-04-23
---

# Phase 14 — Plan 14-01 Summary

**Delivered bounded CSV/JSON export and a keyset stream on the same query spine as `timeline/2`, with strict filter validation and integration tests.**

## Accomplishments

- `validate_timeline_filters!/1`, `timeline_query/1`, `export_changes_query/1` in `Threadline.Query`.
- `Threadline.Export` with `to_csv_iodata/2`, `to_json_document/2`, `count_matching/2`, `stream_changes/2`.
- PostgreSQL-backed tests for parity, truncation, NDJSON, CSV edge encoding, and stream pagination.

## Self-Check: PASSED

- `DB_PORT=5433 MIX_ENV=test mix compile --warnings-as-errors`
- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/query_test.exs test/threadline/export_test.exs`
