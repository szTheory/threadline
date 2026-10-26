---
phase: 229-adopter-api-and-health-additions
plan: 02
subsystem: api
tags: [postgres, health, catalog, jsonb]

# Dependency graph
requires:
  - phase: 229-01
    provides: "phase 229's before suite wall clock (D-28 half)"
provides:
  - "Threadline.Health.legacy_key_findings/1 public function (HLTH-03)"
  - "Threadline.Health.LegacyKeyFindings private module (codes/0, run/1)"
  - "Finding.code() :unresolved_legacy_keys, details keys unresolved_count/capped/key_columns"
  - "HLTH-04 fail-fast documentation + doc-contract pin"
affects: [229-03, 229-04, 230-rebalance-net-suite-check-and-0-12-0]

# Actuals (#2632)
actuals:
  tokens: 9300
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Per-table capped probe driven by TriggerCatalog.threadline_triggers/1, never a global GROUP BY over audit_changes (mirrors export.ex's 10,000+ cap convention)"
    - "repo.transaction/1 wrapping a transaction-local SET statement_timeout via set_config, letting a cancelled probe raise Postgrex.Error unchanged rather than returning a sentinel"
    - "Bind every identifier/value as a SQL parameter ($1..$4, including a text[] array), qualifying audit_changes only through StorageSchema.table/2"

key-files:
  created:
    - lib/threadline/health/legacy_key_findings.ex
    - test/threadline/health/legacy_key_findings_test.exs
  modified:
    - lib/threadline/health.ex
    - lib/threadline/health/finding.ex
    - test/threadline/upgrade_backfill_test.exs
    - test/threadline/health_findings_doc_contract_test.exs
    - test/partition_colocate.txt
    - guides/domain-reference.md
    - guides/configuration-and-commands.md
    - CHANGELOG.md

key-decisions:
  - "D-20 discretion: a cancelled probe raises Postgrex.Error (code :query_canceled) unchanged out of repo.transaction/1, rather than returning a sentinel — keeps the return type [Finding.t()] and adds no new public exception module, documented in the @doc"
  - "One trigger per {schema, table} picked by Enum.min_by(group, & &1.trigger) — the trigger whose name sorts first, per D-19's dedup rule"
  - "Test fixtures bind the Elixir map term directly for table_pk rewrites (never a pre-JSON-encoded string) — Postgrex's jsonb extension already encodes the term it receives; binding an already-encoded string double-encodes it into a jsonb scalar string instead of an object, the same pitfall 229-01's independent oracle hit"

requirements-completed: [HLTH-03, HLTH-04]

coverage:
  - id: D1
    description: "Threadline.Health.legacy_key_findings/1 is public, same :repo/:schema options as trigger_findings/1, returns [Finding.t()] sorted by {schema, table, code}, emits no telemetry, and is proven end-to-end on the frozen 0.10.2 fixture (present after regeneration, cleared by the guide's own backfill SQL)"
    requirement: "HLTH-03"
    verification:
      - kind: unit
        ref: "test/threadline/upgrade_backfill_test.exs#Task 1 (tracer): a non-id-keyed table through the whole documented path"
        status: pass
      - kind: unit
        ref: "test/threadline/health/legacy_key_findings_test.exs#no telemetry legacy_key_findings/1 emits no [:threadline, :health, :findings_checked] event"
        status: pass
    human_judgment: false
  - id: D2
    description: "The probe is per-table, capped at 10,000(+1), statement-timeout bounded, counts only recoverable INSERT/UPDATE rows (excluding DELETE and redacted/missing key columns), is prefix-correct under a non-default storage schema, and never leaks row values"
    requirement: "HLTH-03"
    verification:
      - kind: unit
        ref: "test/threadline/health/legacy_key_findings_test.exs#the count cap caps the reported count and sets capped true when exceeded"
        status: pass
      - kind: unit
        ref: "test/threadline/health/legacy_key_findings_test.exs#redacted/missing key columns and DELETE rows a redacted key column is not counted, and a table with only such rows yields no finding"
        status: pass
      - kind: unit
        ref: "test/threadline/health/legacy_key_findings_test.exs#redacted/missing key columns and DELETE rows DELETE rows are never counted"
        status: pass
      - kind: unit
        ref: "test/threadline/health/legacy_key_findings_test.exs#storage schema prefix correctness probes the configured storage schema, not the default"
        status: pass
      - kind: unit
        ref: "test/threadline/health/legacy_key_findings_test.exs#statement timeout a cancelled probe raises Postgrex.Error with code :query_canceled"
        status: pass
      - kind: unit
        ref: "test/threadline/health/legacy_key_findings_test.exs#no leaked values no seeded data value appears in the finding's message or details"
        status: pass
    human_judgment: false
  - id: D3
    description: "Docs state malformed :trigger_capture config raises ArgumentError rather than producing a finding, pinned in both the Finding moduledoc and guides/configuration-and-commands.md's trigger_capture row"
    requirement: "HLTH-04"
    verification:
      - kind: unit
        ref: "test/threadline/health_findings_doc_contract_test.exs#the Finding moduledoc documents the catch-all and fail-fast rules"
        status: pass
      - kind: unit
        ref: "test/threadline/health_findings_doc_contract_test.exs#configuration-and-commands.md states the HLTH-04 fail-fast sentence"
        status: pass
    human_judgment: false

duration: ~25min
completed: 2026-10-02
status: complete
---

# Phase 229 Plan 02: Threadline.Health.legacy_key_findings/1 and HLTH-04 Docs Summary

**New public `Threadline.Health.legacy_key_findings/1` reports a per-table `:unresolved_legacy_keys` warning for pre-0.11 audit rows a backfill can still fix — capped, statement-timeout-bounded, zero-telemetry, prefix-correct under any storage schema — plus the documented fail-fast rule for malformed `:trigger_capture` config.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-10-02T16:52:00Z
- **Completed:** 2026-10-02T17:05:00Z
- **Tasks:** 3 completed
- **Files modified:** 10 (2 created, 8 modified)

## Accomplishments
- `Threadline.Health.LegacyKeyFindings` (`lib/threadline/health/legacy_key_findings.ex`): per-table, capped (`LIMIT cap+1`), transaction-local `statement_timeout`-bounded probe over `StorageSchema.table("audit_changes", opts)`, counting only INSERT/UPDATE rows whose `table_pk` is still `{"id": null}` or `{}` and whose key columns are present and non-null in `data_after` — never a global `GROUP BY`
- `Threadline.Health.legacy_key_findings/1` delegates to it; `Finding.code()` gains `:unresolved_legacy_keys`; `details` uses string keys `"unresolved_count"`, `"capped"`, `"key_columns"` per D-23
- Proven end-to-end on the frozen 0.10.2 fixture in `upgrade_backfill_test.exs`: the finding is present (count 5, `key_columns: ["doc_key"]`) after trigger regeneration and before backfill, and absent after the guide's own marker-extracted backfill SQL runs, while the DELETE row stays unresolved
- 14 focused direct-fixture tests on real PostgreSQL: the `{}`/`{"id": null}` equivalence, cap boundary and overflow, non-default storage-schema prefix correctness (inside `with_storage_schema("audit", ...)`), `:schema` filtering + validation, a no-key-args trigger excluded entirely from probing, redacted/missing key columns excluded, DELETE rows excluded, a held `ACCESS EXCLUSIVE` lock driving a `statement_timeout` → `Postgrex.Error{postgres: %{code: :query_canceled}}` raise, option validation, zero telemetry emission, and zero leaked row values
- Docs: `Finding` and `Health` moduledocs extended (both findings functions named up front, codes/details/timeout/cap documented, catch-all-clause guidance, the `#what-cannot-be-recovered` link); `guides/domain-reference.md` gains the finding-codes row; `guides/configuration-and-commands.md`'s `trigger_capture` row states the HLTH-04 fail-fast sentence; `health_findings_doc_contract_test.exs` now iterates `TriggerFindings.codes() ++ LegacyKeyFindings.codes()` and pins both sentences; CHANGELOG `### Added` bullet

## Task Commits

1. **Task 1: Tracer — legacy_key_findings/1 end-to-end on the frozen 0.10.2 fixture** - `61eacb1c` (feat)
2. **Task 2: Focused fixtures — {} variant, cap, storage schema, :schema filter, no-args trigger, redacted keys, timeout** - `12afbe74` (test)
3. **Task 3: Finding/Health docs, domain reference row, the HLTH-04 sentence, doc contracts and CHANGELOG** - `ba73d0b1` (docs)

_No TDD tasks in this plan; each task is a single atomic commit._

## Files Created/Modified
- `lib/threadline/health/legacy_key_findings.ex` — new `@moduledoc false` module: `codes/0`, `run/1`, the per-table capped/timeout-bounded probe
- `lib/threadline/health.ex` — public `legacy_key_findings/1` delegate with full `@doc`; Telemetry section notes it emits no event
- `lib/threadline/health/finding.ex` — `code()` union gains `:unresolved_legacy_keys`; moduledoc documents it, the catch-all rule, and the HLTH-04 echo
- `test/threadline/upgrade_backfill_test.exs` — Task 1 tracer assertions (pre/post-backfill finding presence)
- `test/threadline/health/legacy_key_findings_test.exs` — new file, 14 focused tests
- `test/partition_colocate.txt` — new file registered alongside `upgrade_backfill_test.exs`
- `test/threadline/health_findings_doc_contract_test.exs` — extended to both findings modules, two new doc-sentence pins
- `guides/domain-reference.md` — `:unresolved_legacy_keys` finding row + distinguishing sentence
- `guides/configuration-and-commands.md` — `trigger_capture` row's fail-fast sentence
- `CHANGELOG.md` — `### Added` bullet

## Decisions Made
- D-20 discretion: the cancelled-probe timeout raises `Postgrex.Error` unchanged out of `repo.transaction/1` rather than returning a sentinel — documented in the `@doc`, no new public exception module.
- One trigger per `{schema, table}` picked via `Enum.min_by(group, & &1.trigger)` (first by name), per D-19.
- Test fixtures bind the raw Elixir map term for `table_pk` rewrites rather than a pre-encoded JSON string — binding an already-encoded string double-encodes it into a jsonb scalar (the same pitfall 229-01's SUMMARY documented for its independent oracle); discovered and fixed while writing Task 2's fixtures (not a plan deviation — a test-authoring correctness fix, same logic 229-01 already applied to its own oracle).

## Deviations from Plan

None — plan executed exactly as written. One internal comment in `legacy_key_findings.ex` was rewritten mid-Task-3 to remove a `D-19` planning-vocabulary citation flagged by `release_artifact_contract_test.exs` (a pre-existing repo-wide guard this plan's `executor_safety` block already named as a hard constraint); the rationale itself (per-table probe, never a global `GROUP BY`) is preserved in durable domain language. No behavior change, no scope creep.

## Issues Encountered
None beyond the jsonb double-encoding fixture bug described above, caught immediately by the test run and fixed before any commit.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 03 (`--strict`/`--all-schemas`) can wire `legacy_key_findings/1` into `mix threadline.health.coverage`'s findings concatenation; `trigger_findings/1` and `pgbouncer_topology_test.exs` are untouched (confirmed via `git diff`), preserving the zero-grant catalog-only invariant. Full local suite green: 32 properties, 2725 tests, 0 failures, 3 excluded. `mix verify.credo`, `mix format --check-formatted`, and `mix docs` all clean on top of this plan's commits.

---
*Phase: 229-adopter-api-and-health-additions*
*Completed: 2026-10-02*

## Self-Check: PASSED

- `lib/threadline/health/legacy_key_findings.ex` exists
- `test/threadline/health/legacy_key_findings_test.exs` exists
- Commits `61eacb1c`, `12afbe74`, `ba73d0b1` all found in `git log --oneline --all`
