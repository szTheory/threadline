---
phase: 228-telemetry
plan: 04
subsystem: telemetry
tags: [telemetry, property-test, mutation-control, redaction]

requires:
  - phase: 228-telemetry (plan 01)
    provides: "Threadline.Telemetry @events registry, __events__/0, test/threadline/telemetry_registry_contract_test.exs"
  - phase: 228-telemetry (plan 02)
    provides: "emit_export_completed/4, emit_export_failed/5, [:threadline, :export, :completed|:failed]"
  - phase: 228-telemetry (plan 03)
    provides: "purge_span/2, emit_batch_purged/3, [:threadline, :retention, :purge, :start|:stop|:exception], [:threadline, :retention, :batch_purged]; the registry's generic metadata value-type guard"
provides:
  - "PROP-04 telemetry observer in test/threadline/capture/redaction_leak_property_test.exs: every __events__/0 name attached in setup, a telemetry:<event> surface per observed event, refuted against both canaries and plain markers, plus a structural guard (>=1 export event, exactly 3 [:threadline, :export, :completed] events with csv/json/ndjson formats and matching row_count)"
  - "test/threadline/telemetry_raising_handler_test.exs: a raising handler attached to all four D-13 events is caught, detached from every one of them, and [:telemetry, :handler, :failure] fires, while export and purge results/side effects are unaffected"
  - "Two recorded mutation controls (.planning/phases/228-telemetry/tools/mutations/telemetry_export_leak.patch, telemetry_unlisted_key.patch) with evidence fragments proving the telemetry observer and the registry allowlist both bite on a real mutant"
affects: [228-05, 228-06]

actuals:
  tokens: 10200
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Discard-then-drain around the unit of work: build_surfaces/5 calls discard_telemetry/1 immediately before the three export calls it already makes, then drain_telemetry/1 immediately after, so the telemetry surfaces this iteration reports are exactly (and only) the events those three export calls caused"
    - "Structural guard against a vacuous observer: assert_export_telemetry_structure!/2 requires at least one [:threadline, :export, ...] event and exactly three [:threadline, :export, :completed] events (csv/json/ndjson, each row_count == the expected change count) before trusting the refute_canaries!/assert_markers! calls on telemetry surfaces — a detached or no-op handler fails this guard long before it could pass the leak checks vacuously"
    - "Telemetry surfaces get a stricter check than data surfaces: ordinary export/diff/stream surfaces legitimately carry the plain marker (real row data); telemetry surfaces must carry neither canaries nor markers, since telemetry should never carry row data at all"

key-files:
  modified:
    - test/threadline/capture/redaction_leak_property_test.exs
  created:
    - test/threadline/telemetry_raising_handler_test.exs
    - .planning/phases/228-telemetry/tools/mutations/telemetry_export_leak.patch
    - .planning/phases/228-telemetry/tools/mutations/telemetry_unlisted_key.patch
    - .planning/phases/228-telemetry/evidence/TELE-03-mutation-telemetry-export-leak.md
    - .planning/phases/228-telemetry/evidence/TELE-03-mutation-unlisted-key.md

key-decisions:
  - "One attach_many across all four D-13 events (export completed/failed, batch_purged, purge :stop) for the export-side raising-handler case, matching :telemetry 1.4.2's documented behavior that a handler failure detaches the id from every event in its attach_many, not only the one that fired; a second, separately-attached raising handler covers only batch_purged/purge :stop for the retention case, per the plan's two-case split"
  - "The leak mutant's shrunk counterexample surfaces a plain marker (the bio value), not a redaction canary — confirmed and documented in the evidence fragment: CSV output is already masked/excluded by the time the mutant forwards it into telemetry metadata, so the only thing left to leak is the unredacted bio column, which is exactly what the telemetry-surfaces refute call (canaries(plan) ++ markers(plan)) exists to catch"

requirements-completed: [TELE-03]

coverage:
  - id: D1
    description: "The PROP-04 property attaches a uniquely-id'd non-raising handler to every Threadline.Telemetry.__events__/0 name in setup, detached on_exit; each iteration drains the mailbox before build_surfaces and again after it, appending one telemetry:<event> surface per received event"
    requirement: TELE-03
    verification:
      - kind: unit
        ref: "test/threadline/capture/redaction_leak_property_test.exs#no canary survives a redacted trigger/storage/diff/CSV/JSON/NDJSON round trip"
        status: pass
    human_judgment: false
  - id: D2
    description: "Telemetry surfaces are checked with LeakOracle.refute_canaries!/3 against canaries(plan) ++ markers(plan) and excluded from assert_markers!/3; a structural assertion requires >=1 export event and exactly 3 [:threadline, :export, :completed] events with csv/json/ndjson formats and matching row_count"
    requirement: TELE-03
    verification:
      - kind: unit
        ref: "test/threadline/capture/redaction_leak_property_test.exs (assert_export_telemetry_structure!/2)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A raising handler attached to the export events, batch_purged and purge :stop does not change export's result, detaches from all four events on its first failure, and [:telemetry, :handler, :failure] fires naming the handler id; a second raising handler on only batch_purged/purge :stop does not change a real purge's result or deleted rows"
    requirement: TELE-03
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_raising_handler_test.exs (2 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Two recorded mutation controls: a lib patch forwarding export CSV bytes into export telemetry turns the property red on 5/5 seeds; a patch adding an unlisted metadata key turns the allowlist contract test red on 5/5; both green after restore, lib/ clean"
    requirement: TELE-03
    verification:
      - kind: unit
        ref: ".planning/phases/228-telemetry/evidence/TELE-03-mutation-telemetry-export-leak.md, TELE-03-mutation-unlisted-key.md"
        status: pass
    human_judgment: false

duration: ~1h45m
completed: 2026-10-02
status: complete
---

# Phase 228 Plan 04: Telemetry Redaction Observer and Raising-Handler Proof Summary

**The PROP-04 redaction property now observes every real `Threadline.Telemetry` event behind a structural guard that cannot pass vacuously, a new raising-handler test pins `:telemetry` 1.4.2's documented failure-isolation contract for export and purge, and two recorded mutation controls prove both the telemetry leak observer and the registry allowlist actually bite.**

## Performance

- **Duration:** ~1h45m
- **Completed:** 2026-10-02
- **Tasks:** 3/3 completed
- **Files modified:** 7 (6 created, 1 modified)

## Accomplishments

- `test/threadline/capture/redaction_leak_property_test.exs` gained a `setup` that attaches a fresh, uniquely-ref'd non-raising handler to every `Threadline.Telemetry.__events__/0` name (detached `on_exit`), bound into the property body via the context-binding form of `property/3`. `build_surfaces/5` now discards any stray pre-existing telemetry message immediately before the CSV/JSON/NDJSON export calls it already makes, then drains the mailbox immediately after, turning each `{event, measurements, metadata}` into a `"telemetry:<event>"` surface built only from `inspect(measurements, limit: :infinity, printable_limit: :infinity) <> inspect(metadata, ...)` — the widened `inspect` opts matter because the default truncates past 4096 bytes and the generator pads values with 1-4 KB.
- Telemetry surfaces get a stricter check than the pre-existing data surfaces: ordinary export/diff/stream surfaces legitimately carry the plain marker (real row data passes through unredacted columns), so they stay in `assert_markers!/3`; telemetry surfaces are filtered out of that call and instead refuted against `canaries(plan) ++ markers(plan)` together, since telemetry should carry no row data at all, not even the positive-control marker.
- `assert_export_telemetry_structure!/2` is the vacuity guard: it requires at least one `[:threadline, :export, ...]` event, exactly three `[:threadline, :export, :completed]` events, their formats sorted to exactly `[:csv, :json, :ndjson]`, and every one's `row_count` equal to the iteration's actual change count. A detached or silently-no-op handler fails this assertion long before the leak checks could pass it vacuously.
- New `test/threadline/telemetry_raising_handler_test.exs` (2 tests, `async: false`) pins `:telemetry` 1.4.2's documented failure contract (`deps/telemetry/src/telemetry.erl`): Case 1 attaches one raising handler across all four D-13 events (export `:completed`/`:failed`, `batch_purged`, purge `:stop`) and runs `Export.to_csv_iodata/2`; the export still returns `{:ok, %{returned_count: 1}}`, `:telemetry.list_handlers/1` shows the handler gone from all four events (not only the one that fired), and `[:telemetry, :handler, :failure]` fires naming the handler id. Case 2 attaches a second, independent raising handler to only `batch_purged`/purge `:stop` and runs `Retention.purge/1`; the normal result map returns, the expired rows are actually gone, and the handler is detached from both events afterward. Both cases use `ExUnit.CaptureLog.with_log/1` to assert the handler's crash was logged without leaking `Logger` output outside the capture.
- Two mutation controls, run via `mutation-control.sh` at `K=5`, both green after restore with `lib/` left clean:
  - `telemetry_export_leak.patch` makes `emit_export_completed/4` accept and forward a 5th `data` argument into metadata, and `to_csv_iodata/2` pass `IO.iodata_to_binary(iodata)` into it. Killed the redaction property on all 5 seeds; the shrunk counterexample's failure names the `telemetry:threadline.export.completed` surface and the leaked plain marker (the generated `bio` value — CSV output is already masked/excluded by the time the mutant forwards it, so `bio` is the only thing left to leak).
  - `telemetry_unlisted_key.patch` adds `extra: 1` to `emit_actor_ref_mismatch/0`'s metadata. Killed `telemetry_registry_contract_test.exs` on all 5 seeds on the existing key-equality assertion.
  - `mutation-control.sh`'s own internal reproduce check (its second run of seed one) intermittently failed on the pre-existing map-key print-order flake CLAUDE.md already documents against a different file — unrelated to either mutant; documented in the leak evidence fragment, with every seed independently confirmed killed and a byte-identical full report captured from a clean end-to-end run.
- Full `mix test`: 31 properties, 2695 tests, 0 failures, 3 excluded. `mix verify.credo`, `mix compile --warnings-as-errors`, and `mix format --check-formatted` all clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — PROP-04 telemetry observer end to end (attach, drain, surface, refute, structural guard)** - `30a33f76` (feat)
2. **Task 2: Raising-handler test for export and purge** - `bf8f9584` (test)
3. **Task 3: Two mutation controls with recorded evidence** - `87f697d7` (docs)

## Files Created/Modified

- `test/threadline/capture/redaction_leak_property_test.exs` - telemetry `setup`, `drain_telemetry/1`/`discard_telemetry/1`, `assert_export_telemetry_structure!/2`, telemetry surfaces threaded through `build_surfaces/5`, telemetry-specific refute call, moduledoc surface list updated
- `test/threadline/telemetry_raising_handler_test.exs` - new: `raise_handler/4`, `attach_raising!/2`, `refute_handler_attached!/2`, two tests (export-side four-event attach_many; retention-side batch_purged/purge-stop attach_many)
- `.planning/phases/228-telemetry/tools/mutations/telemetry_export_leak.patch` - lib-only diff: `emit_export_completed/4` grows a `data` arg; `to_csv_iodata/2` forwards `IO.iodata_to_binary(iodata)`
- `.planning/phases/228-telemetry/tools/mutations/telemetry_unlisted_key.patch` - lib-only diff: `emit_actor_ref_mismatch/0` metadata gains `extra: 1`
- `.planning/phases/228-telemetry/evidence/TELE-03-mutation-telemetry-export-leak.md`, `TELE-03-mutation-unlisted-key.md` - mutation-control evidence fragments, both passing `check-citations.py`

## Decisions Made

- Case 1 of the raising-handler test uses a single `attach_many` across all four D-13 events (not four separate `attach` calls), matching `:telemetry` 1.4.2's documented semantics that a handler failure detaches its id from every event in that `attach_many` call — this is the exact behavior the plan's `:telemetry.list_handlers/1` assertion across all four events is meant to pin.
- The leak mutant's observed leak is the plain marker, not a canary, and this is documented explicitly in the evidence fragment rather than left as an unexplained detail: `secret_excluded`/`secret_masked`/`profile_masked` are already redacted in the stored row by the time `to_csv_iodata/2` reads it, so forwarding the CSV bytes into telemetry can only leak the columns that were never redacted in the first place (`bio`).

## Deviations from Plan

- **[Rule 1/2 — none required.]** No deviations. The plan's acceptance-criteria grep for `@max_runs PropertyRuns.db(20)` expects a count of 1 in `redaction_leak_property_test.exs`; the file has always had 2 matches (one in the moduledoc prose explaining the budget, one in the actual `@max_runs` attribute) — pre-existing from phase 227/228-01 and unrelated to any change in this plan (confirmed via `git show HEAD~3:...| grep -c` before this plan's first commit). `@max_runs PropertyRuns.db(20)` itself was left untouched as the plan required.
- **[Observation, not a deviation.]** `mutation-control.sh`'s internal byte-for-byte reproduce check for the leak control intermittently failed across repeated invocations on the pre-existing map-key `inspect` print-order flake CLAUDE.md documents (against a different file, `change_diff_property_test.exs`). This is a property of the script's string-comparison reproduce step, not of the mutant or the property under test — every seed independently killed the mutant on every invocation, and two full script runs completed end to end with byte-identical reports. Documented in the leak evidence fragment rather than hidden.

## Issues Encountered

None blocking. See the flake note above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

TELE-03's two runtime proofs (D-13, D-14) are closed with both tests green and both mutation controls recorded. Plan 05 (docs: moduledoc table, `guides/telemetry.md`, doc-parity test, mix.exs/guide-graph registration) and plan 06 (EVIDENCE.md assembly + maintainer push/dispatch checkpoint) can cite this plan's two evidence fragments directly; no further telemetry registry or test-harness changes are needed from this plan.

---
*Phase: 228-telemetry*
*Completed: 2026-10-02*

## Self-Check: PASSED

All 6 created/modified files confirmed present on disk; all 3 task commit
hashes (`30a33f76`, `bf8f9584`, `87f697d7`) confirmed in `git log`.
