---
phase: 228-telemetry
plan: 02
subsystem: telemetry
tags: [telemetry, export, orchestrator, operator-surface, plug]

requires:
  - phase: 228-telemetry (plan 01)
    provides: "Threadline.Telemetry @events registry, __events__/0, helper-only emission rule, runtime allowlist + static scan in test/threadline/telemetry_registry_contract_test.exs"
provides:
  - "Threadline.Telemetry.emit_export_completed/4 and emit_export_failed/5 (@doc false), registry entries for [:threadline, :export, :completed|:failed]"
  - "to_csv_iodata/2 and to_json_document/2 emit exactly one outcome event per call, raise contract unchanged (reraise with original stacktrace)"
  - "Export.Orchestrator.run/2 emits on every mark_failed branch and once on completion, via a :counters row-sent ref threaded through ctx"
  - "ExportController's chunked download (send_chunked_stream/5) emits exactly one outcome event after its reduce_while, including on a client disconnect (error_kind :client_closed)"
  - "test/threadline/operator_surface/export_controller_telemetry_test.exs: a ClosedChunkAdapter Plug.Conn.Adapter proving the client-disconnect path without a real HTTP client"
affects: [228-05]

actuals:
  tokens: 10534
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Clock-before-validation try/rescue: eager export functions bind started_at before Query.validate_timeline_filters!/1, so a bad-filter raise still emits a :failed event with duration and row_count: 0"
    - ":counters row-sent ref for rescue visibility: a reduce_while/try-rescue accumulator is invisible inside its own rescue clause, so row counts the rescue branch needs (orchestrator write_temp_csv, controller send_chunked_stream) are tracked in a :counters.new(1, []) ref instead"

key-files:
  created:
    - test/threadline/operator_surface/export_controller_telemetry_test.exs
  modified:
    - lib/threadline/telemetry.ex
    - lib/threadline/export.ex
    - lib/threadline/export/orchestrator.ex
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - test/threadline/export_test.exs
    - test/threadline/export/orchestrator_test.exs
    - test/threadline/telemetry_registry_contract_test.exs

key-decisions:
  - "error_kind mapping (Claude's discretion per 228-CONTEXT.md): :exception for any raise; :transaction_failed for a non-exception transaction/completion failure; :storage_error for a temp-file read or storage adapter failure; :client_closed only for the chunked download's Plug.Conn.chunk/2 error — all four atoms are reachable and exercised by tests"
  - "Orchestrator ctx threading: persist_export/finalize_stored_export/compensate_failed_finalization now take a single ctx map (adding started_at and a :counters rows ref) instead of six positional args each, keeping every function under the 120-line/800-line executor_safety limits"

requirements-completed: [TELE-01]

coverage:
  - id: D1
    description: "[:threadline, :export, :completed] and [:threadline, :export, :failed] are registered in Threadline.Telemetry with the D-05/D-06 shapes (duration/row_count measurements; format/truncated or format/error_kind/exception metadata)"
    requirement: TELE-01
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_registry_contract_test.exs#every registry event fires with exactly its registered keys"
        status: pass
    human_judgment: false
  - id: D2
    description: "to_csv_iodata/2 and to_json_document/2 emit exactly one outcome event per call on both branches, with the raise-on-bad-filter contract unchanged"
    requirement: TELE-01
    verification:
      - kind: unit
        ref: "test/threadline/export_test.exs#to_csv_iodata/2 telemetry (TELE-01)"
        status: pass
      - kind: unit
        ref: "test/threadline/export_test.exs#to_json_document/2 telemetry (TELE-01)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Export.Orchestrator.run/2 emits on every outcome branch (success, transaction failure, temp-file read failure, storage put failure, completion_fn error or raise, compensation) with {:ok,_}/{:error,_} and export_jobs.error_message unchanged; a lost atomic claim emits nothing"
    requirement: TELE-01
    verification:
      - kind: unit
        ref: "test/threadline/export/orchestrator_test.exs (telemetry assertions added to success, transaction-failure, completion-failure, invalid-params, claim-race tests; new storage-put-failure and completion_fn-raises cases)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The chunked operator-surface download emits exactly one outcome event after its reduce_while, including :failed/:client_closed on a chunk-write error; the iodata path (<=5,000 rows) is untouched"
    requirement: TELE-01
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/export_controller_telemetry_test.exs (4 tests: clean >5,000-row stream, >10,000-row truncation, client-closed chunk write, <=5,000-row single-event path)"
        status: pass
    human_judgment: false

duration: ~1h45m
completed: 2026-10-02
status: complete
---

# Phase 228 Plan 02: Export Telemetry Summary

**`[:threadline, :export, :completed]` / `[:threadline, :export, :failed]` now fire exactly once per logical export across all three units of work — the eager CSV/JSON functions, the async orchestrator job, and the chunked operator-surface download — closing `error_kind` over `:exception | :client_closed | :storage_error | :transaction_failed` with no reason string and no failure-contract change.**

## Performance

- **Duration:** ~1h45m
- **Completed:** 2026-10-02
- **Tasks:** 3/3 completed
- **Files modified:** 7 (1 created, 6 modified)

## Accomplishments

- `Threadline.Telemetry.emit_export_completed/4` and `emit_export_failed/5` (`@doc false`) plus their `@events` registry entries carry the D-05/D-06 shapes exactly: `completed` measurements `%{duration, row_count}` / metadata `%{format, truncated}`; `failed` the same measurements plus `%{format, error_kind, exception}` — never a reason string, never a table or filter value.
- `to_csv_iodata/2` and `to_json_document/2` start the clock before `Query.validate_timeline_filters!/1`, emit `:completed` once just before returning, and on any raise emit `:failed` with `row_count: 0` then `reraise e, __STACKTRACE__` — the raise-on-bad-filter contract is byte-for-byte unchanged. `to_json_document/2` resolves its emit format (`:json` for `:wrapped`, `:ndjson` for `:ndjson`) before the `try`, so the rescue branch labels a bad-filter raise with the right format even though the raise happens before `json_format` would otherwise be read.
- `Export.Orchestrator.run/2` threads `started_at` and a `:counters.new(1, [])` row-sent ref through its `ctx` map (bound once a job is claimed, so a lost atomic claim emits nothing). Every `mark_failed` branch now emits beside it — outer rescue → `:exception`; temp-file read failure and storage-put failure → `:storage_error`; a transaction-function error or unexpected result → `:transaction_failed`; `compensate_failed_finalization` → `:exception` when the completion failure was a raised struct, `:transaction_failed` otherwise. `:completed` fires once, only when `completion_fn` returns `{:ok, _job}`.
- The chunked operator-surface download (`send_chunked_stream/5`, now receiving the matched `count`) emits exactly one event after its `reduce_while`: `:completed` (`truncated: count > @max_rows`) on a clean stream, or `:failed`/`:client_closed` the moment `Plug.Conn.chunk/2` returns an error. A `:counters` ref mirrors the row count for the wrapping `rescue` clause (an `:exception` outcome, reraised), since the `reduce_while` accumulator itself is invisible there. The `Stream.take(@max_rows)` / `Enum.reduce_while` / `Plug.Conn.chunk` literals the doc-contract test pins are all still present verbatim.
- New `test/threadline/operator_surface/export_controller_telemetry_test.exs` calls the controller directly (no router/endpoint) with a hand-built `Plug.Test` conn, swapping in a `ClosedChunkAdapter` whose `chunk/2` always returns `{:error, :closed}` to prove the client-disconnect path without a real HTTP client — 4 tests covering the clean->5,000-row stream, the >10,000-row truncation, the client-closed chunk write, and the <=5,000-row single-event (eager-path) case.
- Full `mix test`: 2690 tests, 0 failures. `mix verify.format` and `mix verify.credo` clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — helpers + registry entries + to_csv_iodata/2 on both branches** - `e03e2bad` (feat)
2. **Task 2: to_json_document/2 and the async Orchestrator on every outcome branch** - `65f4e4bd` (feat)
3. **Task 3: Chunked operator-surface download — thread the outcome through reduce_while and emit once** - `911b30ee` (feat)

## Files Created/Modified

- `lib/threadline/telemetry.ex` - `emit_export_completed/4`, `emit_export_failed/5`, two registry entries
- `lib/threadline/export.ex` - `to_csv_iodata/2` and `to_json_document/2` wrapped in `try/rescue` with telemetry on both branches
- `lib/threadline/export/orchestrator.ex` - `started_at`/`rows` threaded through `ctx`; `persist_export`, `finalize_stored_export`, `compensate_failed_finalization` take `ctx` instead of six positional args; emits on every failure branch and once on completion
- `lib/threadline/operator_surface/controllers/export_controller.ex` - `send_chunked_stream/5` (now takes `count`); `reduce_while` accumulator carries `sent_rows`/`outcome`; one emit after the loop, a `:counters` ref for the wrapping rescue
- `test/threadline/export_test.exs` - telemetry describe blocks for both eager functions (success, truncation, bad-filter raise)
- `test/threadline/export/orchestrator_test.exs` - telemetry assertions on existing tests + new storage-put-failure and completion_fn-raises cases; `PutFailStorage` test module
- `test/threadline/telemetry_registry_contract_test.exs` - `drive_export_completed!`/`drive_export_failed!` added to `drive_all!/0`
- `test/threadline/operator_surface/export_controller_telemetry_test.exs` - new file: `ClosedChunkAdapter` + 4 tests

## Decisions Made

- `error_kind` mapping (left to Claude's discretion by 228-CONTEXT.md): `:exception` for any raise, `:transaction_failed` for a non-exception transaction/completion failure, `:storage_error` for a temp-file read or storage adapter failure, `:client_closed` only for the chunked download's `Plug.Conn.chunk/2` error. All four atoms are reachable and each has a passing test.
- Refactored the orchestrator's `persist_export/7` → `persist_export/4`, `finalize_stored_export/6` → `finalize_stored_export/3`, `compensate_failed_finalization/6` → `compensate_failed_finalization/4` to take the shared `ctx` map instead of threading `repo`, `storage`, `storage_opts`, `completion_fn` individually — needed once `started_at`/`rows` had to reach every one of those functions, and it kept each function well under the 120-line executor-safety limit.

## Deviations from Plan

None — plan executed as written, with one scheduling note: Task 1's edit pass touched both `to_csv_iodata/2` (Task 1's scope) and `to_json_document/2` (Task 2's scope) in `lib/threadline/export.ex` and `test/threadline/export_test.exs` before the first commit, since both functions share the same `try/rescue` shape and were edited together for consistency. The Task 1 commit (`e03e2bad`) therefore includes `to_json_document/2`'s telemetry wiring and tests ahead of schedule; Task 2's commit (`65f4e4bd`) carries only the Orchestrator work. All acceptance criteria for both tasks are independently verified and green; no functionality is missing or duplicated.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

TELE-01 is Complete (marked in REQUIREMENTS.md). The `@events` registry and runtime-allowlist/static-scan contract from plan 01 now cover ten events total (eight pre-existing + two export events), extensible for plan 03's retention span and batch event. Plan 05 (docs) can derive its event tables from `__events__/0` for export alongside the rest.

---
*Phase: 228-telemetry*
*Completed: 2026-10-02*

## Self-Check: PASSED
