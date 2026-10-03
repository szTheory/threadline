---
phase: 226-pure-property-tests-and-run-budget
plan: 04
subsystem: testing
tags: [stream_data, property-testing, export, csv, rfc4180, mutation-testing]

requires:
  - phase: 226-pure-property-tests-and-run-budget
    provides: "Threadline.Test.PropertyRuns (pure/1 run-budget knob), the reusable .planning/.../tools/mutation-control.sh runner, and Threadline.Test.ChangeFactGenerators (fact_gen/0, to_audit_change/1) (226-01, 226-03)"
provides:
  - "Threadline.Test.StrictRFC4180 (test/support/strict_rfc4180.ex): decode!/1 — a hand-written, dependency-free RFC 4180 decoder with its own example tests"
  - "Threadline.Export.CSV (lib/threadline/export/csv.ex): D-17 fix — quotes a bare CR, byte-identical otherwise"
  - "Threadline.Test.ExportHostileValueGenerators (test/support/export_hostile_value_generators.ex): hostile_string_gen/0, hostile_non_empty_string_gen/0, json_value_gen/0, export_row_gen/0"
  - "PROP-05 property: test/threadline/export_property_test.exs (CSV/json_wrapped/ndjson round-trip, D-19 defaults pinned, cross-format agreement with ChangeDiff)"
  - "PROP-05 mutation controls recorded in evidence/ (5/5 kill each)"
affects: [226-05, 226-06]

actuals:
  tokens: 8434
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Independent-decoder round-trip oracle: PROP-05's ground truth is not a fact-derived expectation (unlike PROP-02) but the generated row itself, decoded by a library that shares no code with the encoder (a hand-written RFC 4180 decoder for CSV, Jason for JSON) and compared after one named normalisation function"
    - "Hostile-value injection on top of a fact-first generator: ExportHostileValueGenerators draws a ChangeFactGenerators fact, then overrides data_after/changed_from leaf values (keeping keys, so D-19's none/sparse shape survives) with full JSON-domain values, and overrides table_schema/table_name/op with hostile strings at a fixed weight so a raw CR reaches a raw-string column, not just a JSON-encoded one"
    - "A custom NimbleCSV.define/2 module (Threadline.Export.CSV) with an extended :reserved list is the minimal fix for a dumper that under-quotes relative to what downstream readers (Excel, Python csv) actually treat as a line break"

key-files:
  created:
    - test/support/strict_rfc4180.ex
    - test/threadline/strict_rfc4180_test.exs
    - lib/threadline/export/csv.ex
    - test/support/export_hostile_value_generators.ex
    - test/threadline/export_property_test.exs
    - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/export.patch
    - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/export_csv_join.patch
    - .planning/phases/226-pure-property-tests-and-run-budget/evidence/PROP-05-mutation-export.md
    - .planning/phases/226-pure-property-tests-and-run-budget/evidence/PROP-05-mutation-csv-join.md
  modified:
    - lib/threadline/export.ex
    - test/threadline/export_test.exs
    - CHANGELOG.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
    - .planning/ROADMAP.md

key-decisions:
  - "The oracle for PROP-05 is structurally different from PROP-02's fact-derived expectation: because the whole point is proving the *encoder* round-trips without loss through an *independent decoder*, the ground truth is the generated row map itself (decoded by StrictRFC4180/Jason, compared via one named normalize/1 and a named export_defaults/1 D-19 step), not a parallel fact-based reconstruction"
  - "export_row_gen/0 preserves data_after/changed_from's nil-vs-map-vs-partial-map shape from the underlying ChangeFactGenerators fact (so D-19's none/sparse_empty/sparse_partial modes still occur) while redrawing every leaf value from json_value_gen/0 — this keeps the hostile-value injection orthogonal to the before_values mode it rides on"
  - "JSON's \"action\" object forwards a nil aa_correlation_id as JSON null (Export.change_map/1 never defaults it); only CSV's always-present include_action_metadata columns default a nil correlation/action id to \"\". The property caught this distinction — the first draft asserted the CSV default applied to JSON too and failed correctly; the test was fixed to assert the real per-format behavior, not the library's code changed (D-19 pins JSON's null, it does not add a default)"

requirements-completed: [PROP-05]

coverage:
  - id: D1
    description: "Threadline.Test.StrictRFC4180.decode!/1 is a hand-written, dependency-free RFC 4180 decoder (no NimbleCSV, no Regex split) that accepts quoted fields with doubled quotes and embedded CR/LF, tabs and non-ASCII, and rejects a bare CR/LF or stray quote in an unquoted field, data after a closing quote, an unterminated quoted field, and a final record without a trailing CRLF"
    requirement: "PROP-05"
    verification:
      - kind: unit
        ref: "mix test test/threadline/strict_rfc4180_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-17: CSV export now quotes a field containing a bare CR (Threadline.Export.CSV, a custom NimbleCSV.define/2 with \"\\r\" added to :reserved); values without a bare CR are byte-identical to plain NimbleCSV.RFC4180 output; CHANGELOG Fixed entry added"
    requirement: "PROP-05"
    verification:
      - kind: unit
        ref: "mix test test/threadline/export_test.exs (describe \"D-17 bare CR\") test/mix/tasks/threadline/export_test.exs test/threadline/public_surface_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "PROP-05 proves CSV, :json_wrapped and :ndjson all round-trip generated rows (including hostile values in raw-string and JSON columns) through an independent decoder after one named normalisation; D-19's nil-default substitutions are pinned explicitly; a cross-format property checks json_wrapped's base fields agree with ChangeDiff.from_audit_change/2's :export_compat output; a leading =/+/-/@ value round-trips unchanged (no formula escaping added)"
    requirement: "PROP-05"
    verification:
      - kind: unit
        ref: "mix test test/threadline/export_property_test.exs"
        status: pass
      - kind: unit
        ref: "THREADLINE_PROPERTY_SCALE=5 mix test test/threadline/export_property_test.exs --seed 1 (and seeds 2, 3, 42, 1000)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Both PROP-05 mutation controls (datetime_iso truncated to :second; the RFC4180 dump replaced with a naive Enum.join) are killed 5/5 across seeds, reproduce on seed 1, and lib/ is restored clean and green afterward"
    requirement: "PROP-05"
    verification:
      - kind: other
        ref: "bash .planning/.../tools/mutation-control.sh --max-runs 150 .planning/.../tools/mutations/{export,export_csv_join}.patch test/threadline/export_property_test.exs 5"
        status: pass
    human_judgment: false

duration: ~1h15min
completed: 2026-10-01
status: complete
---

# Phase 226 Plan 4: Pure Property Tests and Run Budget — PROP-05 Export Round-Trip Summary

**PROP-05 proves CSV/JSON export round-trips generated change rows — including hostile values in both raw-string and JSON-encoded columns — through an independent decoder, fixes a real bare-CR CSV defect the property exposed, and pins the documented nil-default asymmetries between formats.**

## Performance

- **Duration:** ~1h15min
- **Completed:** 2026-10-01
- **Tasks:** 3
- **Files modified:** 10 (7 created, 3 modified in lib/test; plus REQUIREMENTS.md/STATE.md/ROADMAP.md)

## Accomplishments

- `Threadline.Test.StrictRFC4180` — a ~75-line, dependency-free RFC 4180 decoder (no NimbleCSV, no Regex) with 14 of its own example tests covering the full accept/reject matrix from the RFC: quoted fields with `""` and embedded CR/LF, tabs, astral Unicode; rejects a bare CR/LF or stray quote in an unquoted field, data after a closing quote, an unterminated quoted field, and a final record missing its trailing CRLF.
- **D-17 fixed**: `Threadline.Export.CSV` (`lib/threadline/export/csv.ex`) is a custom `NimbleCSV.define/2` identical to `NimbleCSV.RFC4180` except its `:reserved` list adds `"\r"`, so a bare carriage return in a raw-string export column (`table_name`, `table_schema`, `op`, a correlation id) is now quoted instead of silently splitting a CSV row when read by Excel or Python's `csv` module. Values without a bare CR are byte-identical to before. Pinned by three new regression tests in `export_test.exs`'s "D-17 bare CR" describe block, plus a CHANGELOG Fixed entry.
- `Threadline.Test.ExportHostileValueGenerators` builds on `ChangeFactGenerators` to deliver CSV/JSON-hostile values (comma, `"`, CRLF, lone CR/LF, leading `=`/`+`/`-`/`@`, astral/combining Unicode, `""`, `"[REDACTED]"`, plus bignums and special floats `1.0e300`/`5.0e-324`/`2.0`/`-0.0`) into both raw-string export columns and JSON-encoded columns, while preserving the underlying fact's `changed_from` none/sparse_empty/sparse_partial shape. It also attaches an optional transaction actor (`ActorRef` built from generated type/id facts, or nil) and optional action metadata.
- `export_property_test.exs` (5 properties, 6 example tests) proves: CSV round-trips through `StrictRFC4180.decode!/1` (header asserted once against a hand-typed column list); `:json_wrapped` and `:ndjson` round-trip through `Jason.decode!/1`; a leading `=`/`+`/`-`/`@` value round-trips unchanged (D-17's deferred formula-injection sibling stays out of scope, proven by example); D-19's nil-default substitutions (`changed_from` → `{}` both formats, CSV-only `data_after` → `"{}"`, CSV-only `""` correlation/action id default) are pinned with explicit example tests; and `:json_wrapped`'s base fields agree with `ChangeDiff.from_audit_change/2`'s `:export_compat` output for the same fact.
- Both PROP-05 mutation controls (`datetime_iso/1` truncated to `:second`; the RFC4180 dump replaced with a naive `Enum.join(",") <> "\r\n"`) recorded in `evidence/`, each 5/5 kill, reproduced on seed 1, `lib/` restored clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: Strict RFC 4180 decoder with its own example tests** - `2625c08a` (test)
2. **Task 2: D-17 — quote any CSV field containing a bare CR** - `f4313da7` (fix)
3. **Task 3: Hostile-value generator, PROP-05 properties and both export mutation controls** - `e45ae569` (test)

## Files Created/Modified

- `test/support/strict_rfc4180.ex` - `Threadline.Test.StrictRFC4180.decode!/1`
- `test/threadline/strict_rfc4180_test.exs` - its RFC 4180 example tests
- `lib/threadline/export/csv.ex` - `Threadline.Export.CSV`, D-17 fix
- `lib/threadline/export.ex` - points `dump_csv_to_iodata/1` at `Threadline.Export.CSV`
- `test/threadline/export_test.exs` - "D-17 bare CR" regression tests
- `CHANGELOG.md` - Unreleased Fixed entry for the bare-CR quoting fix
- `test/support/export_hostile_value_generators.ex` - `Threadline.Test.ExportHostileValueGenerators`
- `test/threadline/export_property_test.exs` - PROP-05 properties, `export_defaults/1`, `normalize/1`
- `.planning/.../tools/mutations/export.patch`, `export_csv_join.patch` - mutation patches
- `.planning/.../evidence/PROP-05-mutation-export.md`, `PROP-05-mutation-csv-join.md` - evidence, 5/5 each
- `.planning/REQUIREMENTS.md` - PROP-05 checked off (checkbox + traceability table)
- `.planning/STATE.md`, `.planning/ROADMAP.md` - plan progress updated

## Decisions Made

- PROP-05's oracle is deliberately different in shape from PROP-02's: since the thing under test is "does the encoder lose information round-tripping through an independent decoder", the ground truth is the generated row itself (not a parallel fact-derived reconstruction), compared via one named `normalize/1` (atom keys/values → strings) and one named `export_defaults/1` (D-19's documented nil substitutions) step.
- `export_row_gen/0` redraws every `data_after`/`changed_from` leaf value from `json_value_gen/0` but keeps the original fact's key set and nil/`%{}`/partial-map shape, so hostile-value injection doesn't interfere with exercising D-19's three `before_values` modes.
- The property caught a real distinction between formats that the plan's D-19 wording glossed over: CSV's `include_action_metadata` columns always exist and so default a nil correlation id to `""`, but JSON's `"action"` object only exists when `aa_id` is present and then forwards `aa_correlation_id` unchanged (including `null`). Fixed the test's expectation to match Export's actual (and correct) per-format behavior rather than assuming one shared default.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test assumed a JSON correlation-id default that Export does not apply**
- **Found during:** Task 3, first `mix test` run of the new property file
- **Issue:** The JSON round-trip oracle asserted `defaults.correlation_id` (the CSV `""` default) for the `"action"` object's `correlation_id`, but `Export.change_map/1` forwards `aa_correlation_id` unchanged in JSON (including `nil`/`null`); only CSV's always-present metadata columns apply the `""` default.
- **Fix:** Asserted `row.aa_correlation_id` (the raw value) for JSON's `"action.correlation_id"`, with a comment explaining the CSV-only default.
- **Files modified:** `test/threadline/export_property_test.exs`
- **Verification:** `mix test test/threadline/export_property_test.exs` green afterward (0 failures).
- **Committed in:** `e45ae569` (caught and fixed before committing)

**2. [Rule 3 - Blocking] Credo nested-module-alias and over-quoted-string-literal nits**
- **Found during:** Task 2, `mix verify.credo`
- **Issue:** `test/threadline/export_test.exs` referenced `Threadline.Test.StrictRFC4180` without an alias, and `test/threadline/strict_rfc4180_test.exs` had a string literal with more than 3 embedded quotes — both credo `--strict` findings.
- **Fix:** Added `alias Threadline.Test.StrictRFC4180` and switched the literal to a `~s(...)` sigil.
- **Files modified:** `test/threadline/export_test.exs`, `test/threadline/strict_rfc4180_test.exs`
- **Verification:** `mix verify.credo` exits 0 (no issues) afterward.
- **Committed in:** `f4313da7`

---

**Total deviations:** 2 auto-fixed (Rule 1 — test logic bug caught before commit; Rule 3 — blocking credo nits fixed inline).
**Impact on plan:** None on scope; both fixes tightened test correctness/style without changing `lib/` behavior beyond the planned D-17 fix.

## Issues Encountered

The shared local Postgres/dev machine runs other agents' `mix test` processes concurrently (unrelated repositories); the first full-suite run took ~5 minutes under that contention but completed green (2618 then 2624 tests, 0 failures) — environmental, not a defect in this plan's work.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `Threadline.Test.StrictRFC4180` and `Threadline.Test.ExportHostileValueGenerators` are new, reusable test-support modules; no other plan in this phase currently needs them, but 227 (DB-backed properties) or a future export-contract phase could.
- PROP-05 and D-17 are fully proven; D-19 is pinned (not changed) per the phase's scope boundary. `lib/` is clean; full `mix test` is 2624 tests/0 failures; `mix verify.credo` and `mix format --check-formatted` are clean repo-wide.
- No blockers for 226-05 (PROP-08 wiring) onward.

---
*Phase: 226-pure-property-tests-and-run-budget*
*Completed: 2026-10-01*

## Self-Check: PASSED

All 9 created files confirmed present on disk; all 3 task commits (`2625c08a`, `f4313da7`, `e45ae569`) confirmed in `git log --oneline --all`.
