---
phase: 228-telemetry
plan: 03
subsystem: telemetry
tags: [telemetry, retention, span, contract-test]

requires:
  - phase: 228-telemetry (plan 01)
    provides: "Threadline.Telemetry @events registry, __events__/0, helper-only emission rule, runtime allowlist + static scan in test/threadline/telemetry_registry_contract_test.exs"
  - phase: 228-telemetry (plan 02)
    provides: "drive_export_completed!/drive_export_failed! pattern in drive_all!/0 for extending the registry contract test"
provides:
  - "Threadline.Telemetry.purge_span/2 and emit_batch_purged/3 (@doc false); registry entries for [:threadline, :retention, :purge, :start|:stop|:exception] (with exempt_metadata) and [:threadline, :retention, :batch_purged]"
  - "Threadline.Retention.purge/1's dry-run/real-run branch wrapped in purge_span/2, opened only after input checks pass; purge_loop/7 emits batch_purged once per step"
  - "A generic metadata value-type guard in the registry contract test (atom/boolean/integer/nil/reference/atom-list, with the authorize :path string as the sole exception), proven to bite on an injected free-text value"
affects: [228-05]

actuals:
  tokens: 5720
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Span opens only after input checks: purge_span/2 wraps only the dry-run/real-run branch inside purge/1's enabled-policy path, so a disabled or misconfigured call emits nothing (matches the export-events precedent of emitting only once the unit of work is known to run)"
    - "Per-step measurement without a wrapping transaction: purge_loop/7 captures System.monotonic_time/0 at the top of each reduce_while step and emits batch_purged right after that step's delete_all and orphan drain both return, since retention purge statements autocommit"

key-files:
  modified:
    - lib/threadline/telemetry.ex
    - lib/threadline/retention.ex
    - test/threadline/retention_test.exs
    - test/threadline/telemetry_registry_contract_test.exs

key-decisions:
  - "Credo nesting-depth fix: extracted purge/1's dry-run/real-run if/else into a private run_purge/8, since the span-wrapped block plus the existing enabled-check if/else would otherwise nest to depth 3 (credo's max is 2)"
  - "Exception type for the missing-schema path (Claude's discretion per 228-CONTEXT.md): assert_raise Postgrex.Error — confirmed empirically on the first run against a nonexistent storage schema, not assumed"

requirements-completed: [TELE-02]

coverage:
  - id: D1
    description: "purge_span/2 wraps only purge/1's dry-run/real-run branch, opened after the :repo fetch, Policy.resolve!/1, the {:error, :disabled} return and resolve_cutoff/2; a disabled or misconfigured call emits nothing (D-08)"
    requirement: TELE-02
    verification:
      - kind: unit
        ref: "test/threadline/retention_test.exs#purge/1 without repo raises KeyError; purge/1 returns disabled when retention.enabled is false; cutoff newer than the policy cutoff raises ArgumentError naming retention"
        status: pass
    human_judgment: false
  - id: D2
    description: "start/stop metadata are %{dry_run: boolean} plus telemetry_span_context; stop measurements are deleted_changes/deleted_transactions/batches_run next to the automatic duration/monotonic_time; cutoff/policy/repo/prefix absent (D-09)"
    requirement: TELE-02
    verification:
      - kind: unit
        ref: "test/threadline/retention_test.exs#purge/1 multi-batch, idempotent, and removes empty audit_transactions; dry-run counts only the selected storage schema"
        status: pass
      - kind: unit
        ref: "test/threadline/telemetry_registry_contract_test.exs#every registry event fires with exactly its registered keys"
        status: pass
    human_judgment: false
  - id: D3
    description: "One batch_purged fires per purge_loop step after that step's delete_all and orphan drain both return; event count equals batches_run including the terminating empty step; dry runs emit zero batch events (D-10)"
    requirement: TELE-02
    verification:
      - kind: unit
        ref: "test/threadline/retention_test.exs#purge/1 emits one batch_purged per purge_loop step, counts matching the returned totals (D-10); dry run emits zero batch_purged events"
        status: pass
    human_judgment: false
  - id: D4
    description: "A purge against a missing storage schema emits :start then :exception (kind: :error), no :stop or batch_purged, and still raises, on the real database with no mocks (D-11)"
    requirement: TELE-02
    verification:
      - kind: unit
        ref: "test/threadline/retention_test.exs#purge against a missing storage schema emits :start then :exception, no :stop or batch_purged, and re-raises (D-11)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The allowlist test drives all four retention events and asserts every observed metadata value outside exempt_metadata is an atom, boolean, integer, nil, reference or list of atoms, except the authorize path string; measurements are integers or atoms"
    requirement: TELE-03
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_registry_contract_test.exs#every registry event fires with exactly its registered keys (drive_retention_purge!, assert_metadata_value_types!/2, assert_measurement_value_types!/2)"
        status: pass
    human_judgment: false

duration: ~40m
completed: 2026-10-02
status: complete
---

# Phase 228 Plan 03: Retention Telemetry Summary

**`[:threadline, :retention, :purge, :start|:stop|:exception]` now spans every real purge/dry-run preview (opened only once input checks pass), one `batch_purged` event fires per purge-loop step including the terminating empty one, and a forced exception against a missing storage schema proves the `:exception` path on the real database — closing the registry at fourteen events with a generic metadata value-type guard behind it.**

## Performance

- **Duration:** ~40m
- **Completed:** 2026-10-02
- **Tasks:** 2/2 completed
- **Files modified:** 4

## Accomplishments

- `Threadline.Telemetry.purge_span/2` (`@doc false`) wraps `Threadline.Retention.purge/1`'s dry-run/real-run branch in a `[:threadline, :retention, :purge]` `:telemetry.span/3`, called only after the `:repo` fetch, `Policy.resolve!/1`, the `{:error, :disabled}` return and `resolve_cutoff/2` — a disabled or misconfigured call emits nothing, proven by `refute_received` on `KeyError`, `{:error, :disabled}` and the cutoff-newer-than-policy `ArgumentError` paths. Start and stop metadata are both `%{dry_run: boolean}` (passed again at stop since `:telemetry` doesn't merge start metadata forward); the span function lifts `deleted_changes`, `deleted_transactions` and `batches_run` into stop measurements next to the automatic `duration`/`monotonic_time`. `purge/1`'s return contract is byte-for-byte unchanged.
- `Threadline.Telemetry.emit_batch_purged/3` (`@doc false`) fires `[:threadline, :retention, :batch_purged]` once per `purge_loop/7` reduce step, right after that step's change `delete_all` and full orphan drain have both returned (no wrapping transaction, so the statements have already committed) — measurements `%{deleted_changes, deleted_transactions, duration}`, no metadata. The event count equals `batches_run`, including the terminating empty step; a dry run never reaches `purge_loop/7`, so it emits zero batch events.
- The forced exception path (`purge(repo: Repo, storage_schema: "<unique missing schema>")` with retention enabled) raises `Postgrex.Error` from `run_with_tracking/7`'s `RetentionRun` insert against the nonexistent schema, confirmed empirically rather than assumed. It emits `:start` then `:exception` (`kind: :error`, with `reason`/`stacktrace` present as the documented `exempt_metadata`), no `:stop`, no `batch_purged`, and still re-raises — proven against the real database with no mocks or sandbox, safe under `async: false`.
- The registry now lists fourteen events total (ten carried in from plans 01/02, four added here). The runtime allowlist test's `drive_all!/0` gained `drive_retention_purge!/0` (a normal cutoff-bounded purge for start/stop/batch_purged, then a missing-schema purge inside `assert_raise` for the exception path, config and the created `RetentionRun` row both cleaned up). The per-entry check was extended with `assert_measurement_value_types!/2` (every measurement value is an integer or atom) and `assert_metadata_value_types!/2` (every metadata value outside an entry's `exempt_metadata` and the automatic `telemetry_span_context` must be an atom, boolean, integer, nil, reference, or list of atoms — the sole exception is `:path` on `[:threadline, :operator_surface, :authorize]`, a request-path string). The guard was proven to bite twice locally: first by temporarily adding an unlisted `note: "x"` key to `emit_batch_purged/3`'s metadata (red on the existing key-equality assertion), then by registering `:note` in the entry too and re-running (red specifically on the new value-type assertion: `"[:threadline, :retention, :batch_purged] metadata :note => \"x\" is not an allowed value type (atom, boolean, integer, nil, reference, or list of atoms)"`), both reverted after confirming red.
- `purge/1`'s dry-run/real-run `if/else` was extracted into a private `run_purge/8` to keep the span-wrapped block within credo's nesting-depth limit of 2 (`mix verify.credo` was red at depth 3 before the extraction, clean after).
- Full `mix test`: 2693 tests, 0 failures, 138.4s wall clock. `mix verify.format`, `mix verify.credo`, and `mix compile --warnings-as-errors` all clean. `Threadline.Telemetry.__events__() |> length()` is 14.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — purge_span/2 around both branches, observed start + stop with counts** - `06ce2f50` (feat)
2. **Task 2: batch_purged per step, forced exception path, retention drivers and value-type guard** - `b66fa5f5` (feat)

## Files Created/Modified

- `lib/threadline/telemetry.ex` - `purge_span/2`, `emit_batch_purged/3` (`@doc false`); four registry entries for `[:threadline, :retention, :purge, :start|:stop|:exception]` (with `exempt_metadata`) and `[:threadline, :retention, :batch_purged]`
- `lib/threadline/retention.ex` - `purge/1`'s enabled branch wraps `run_purge/8` in `Threadline.Telemetry.purge_span/2`; `purge_loop/7` calls `Threadline.Telemetry.emit_batch_purged/3` per step
- `test/threadline/retention_test.exs` - span start/stop assertions on existing tests; new tests for batch-event counting, dry-run zero batch events, and the forced exception path
- `test/threadline/telemetry_registry_contract_test.exs` - `drive_retention_purge!/0` added to `drive_all!/0`; `assert_measurement_value_types!/2` and `assert_metadata_value_types!/2` added to the per-entry loop

## Decisions Made

- Credo nesting-depth fix: extracted `purge/1`'s dry-run/real-run branch into a private `run_purge/8` function rather than inlining the `if/else` inside the span closure, since the combination nested to depth 3 against credo's max of 2.
- Exception type for the D-11 forced-failure test and the contract-test driver (left to Claude's discretion by 228-CONTEXT.md): `Postgrex.Error`, confirmed by running the test red-first against a real nonexistent schema rather than guessed.

## Deviations from Plan

- **[Scheduling only] `emit_batch_purged/3` and its registry entry landed in the Task 1 commit (`06ce2f50`) instead of Task 2.** Both new `Threadline.Telemetry` helpers were written in a single edit pass before the first commit, since they share the same module and moduledoc-table edit region. Task 1's commit message and scope describe only `purge_span/2`'s wiring; Task 2's commit (`b66fa5f5`) carries the `purge_loop/7` call site, all new tests, and the contract-test extensions as planned. Both tasks' acceptance criteria are independently green; no functionality is missing, duplicated, or under-tested as a result.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

TELE-02 is complete (to be marked in REQUIREMENTS.md). The registry now holds fourteen events with a generic metadata value-type guard behind the key-equality check, extensible for plan 04 (PROP-04 observer, raising-handler test) and plan 05 (moduledoc table, `guides/telemetry.md`, doc-parity test) to build on without re-deriving the allowed-value-type rule.

---
*Phase: 228-telemetry*
*Completed: 2026-10-02*

## Self-Check: PASSED
