---
phase: 227-db-backed-property-tests
plan: 02
subsystem: testing
tags: [streamdata, ex_unit_properties, postgres, triggers, redaction]

requires:
  - phase: 227-db-backed-property-tests
    provides: "Threadline.Test.DbProperty (227-01): iteration_key/0, with_iteration/2, delete_iteration!/2, ordered_id/2, the D-06 scale-contract rule, and the hardened mutation-control.sh"
provides:
  - "Threadline.Test.LeakOracle: stored_surfaces/2, stored_changes/3, refute_canaries!/3, assert_markers!/3, assert_structure!/3"
  - "Threadline.Test.RedactionLeakGenerators: op_plan_gen/0, canary/2, plain_marker/1, canaries/1, markers/1, value/1"
  - "redaction_leak_property_test.exs — PROP-04 property, DB-backed, checks every D-10 surface"
  - "D-13 example gap closed in trigger_redaction_test.exs"
  - "property_generator_coverage_test.exs: sample_db/2 (1..20 size ramp) and D-26 floors for RedactionLeakGenerators"
  - "three D-12 mutation controls (redaction_changed_from_mask, redaction_exclude_change_detect, redaction_update_path), each killed 5/5 with evidence fragments"
affects: [227-03, 227-04, 227-05, 228]

actuals:
  tokens: 12101
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "op-plan generator threading: StreamData generates per-slot/per-step {written_value, canary_or_nil} pairs; the property body threads the row's current full-column state across 1-4 UPDATE steps (untouched columns resent unchanged, since a real UPDATE statement must set every column)"
    - "paired-transaction index: a generated 0-based step index runs that step and the next one inside one Repo.transaction, exercising the same-txid upsert without a second harness"
    - "LeakOracle surfaces list ({name, bytes} pairs) is open-ended by design (D-11): phase 228 appends telemetry:<event> surfaces additively, no change needed here"
    - "mutation-control.sh --inverted proves a coverage gap before fixing it: the exclude_change_detect mutant survives the pre-D-13 example suite, then D-13's two refute assertions make the same mutant killable by a fast deterministic example"

key-files:
  created:
    - test/support/leak_oracle.ex
    - test/support/redaction_leak_generators.ex
    - test/threadline/capture/redaction_leak_property_test.exs
    - .planning/phases/227-db-backed-property-tests/tools/mutations/redaction_changed_from_mask.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/redaction_exclude_change_detect.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/redaction_update_path.patch
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-04-mutation-changed-from-mask.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-04-mutation-exclude-change-detect.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-04-mutation-update-path.md
  modified:
    - test/threadline/capture/trigger_redaction_test.exs
    - test/threadline/property_generator_coverage_test.exs

key-decisions:
  - "Property-body state threading instead of a stateful generator: op_plan_gen/0 generates independent per-step action descriptors (touch_redacted with a slot subset, touch_plain_only, noop_update); the property body folds them into the row's actual current column values before each UPDATE, which keeps the generator StreamData-idiomatic (no hand-rolled recursive bind for full-row state) while still sending syntactically complete UPDATE statements"
  - "canaries/1 and markers/1 read precomputed {value, token} pairs rather than re-deriving canary(slot, step) from plan shape — simpler and avoids a second source of truth for which slot/step combinations actually wrote a bare token (nil/empty/exact-placeholder slots intentionally carry no token)"
  - "marker positive-control check excludes the stored:audit_transactions surface — audit_transactions rows carry no host-row columns, so the plain marker (which lives in bio) is never expected there; checking it there would be a vacuous requirement, not a stronger one"
  - "measured well under the D-05 run budget (~0.05-0.2s including scale 5), so max_runs stays at PropertyRuns.db(20) — no need to drop to db(15)/db(10)"

patterns-established:
  - "D-10 surface list for an audited-row property: raw storage-qualified row_to_json reads + every ChangeDiff format variant + every Export entrypoint (iodata and streaming), scanned by one shared LeakOracle rather than bespoke per-surface assertions"

requirements-completed: [PROP-04]

coverage:
  - id: D1
    description: "PROP-04 property: no redacted-column canary reaches stored audit_changes/audit_transactions, any ChangeDiff variant, or CSV/JSON/NDJSON export (iodata or streamed), across generated insert/update/delete plans on a real per-table redacted trigger"
    requirement: "PROP-04"
    verification:
      - kind: unit
        ref: "test/threadline/capture/redaction_leak_property_test.exs#no canary survives a redacted trigger/storage/diff/CSV/JSON/NDJSON round trip"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-13 example gap: trigger_redaction_test.exs's UPDATE example now refutes the excluded column in changed_fields and changed_from"
    requirement: "PROP-04"
    verification:
      - kind: unit
        ref: "test/threadline/capture/trigger_redaction_test.exs#UPDATE masks changed_from for masked column and omits exclude from data_after"
        status: pass
    human_judgment: false
  - id: D3
    description: "Three D-12 mutation controls each killed 5/5 with a reproduced shrunk counterexample, lib/ clean after every revert; the exclude_change_detect gap is documented before/after the D-13 fix"
    requirement: "PROP-04"
    verification:
      - kind: other
        ref: "bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh --max-runs 20 .planning/phases/227-db-backed-property-tests/tools/mutations/redaction_changed_from_mask.patch test/threadline/capture/redaction_leak_property_test.exs 5"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-26 generator coverage floors: dual-slot touch_redacted bias (>=40% of plans) and the full redacted-value rung ladder (nil, empty, exact placeholder, placeholder-as-substring, multibyte, >1KB) all reached within 1000 sampled plans"
    requirement: "PROP-04"
    verification:
      - kind: unit
        ref: "test/threadline/property_generator_coverage_test.exs#RedactionLeakGenerators.op_plan_gen/0 (canary and hostile-shape bias)"
        status: pass
    human_judgment: false

duration: ~1h45m
completed: 2026-10-01
status: complete
---

# Phase 227 Plan 02: PROP-04 Redaction Leak Property Summary

**A DB-backed StreamData property proves no redacted column's plaintext reaches stored audit_changes, any ChangeDiff variant, or CSV/JSON/NDJSON export — across generated insert/update/delete plans with hostile-wrapped canaries — with three mutation-killed guards and a closed example-test gap**

## Performance

- **Duration:** ~1h45m
- **Started:** 2026-10-01T18:27:00Z (approx.)
- **Completed:** 2026-10-01T20:12:21Z
- **Tasks:** 3
- **Files modified:** 11 (9 created, 2 modified)

## Accomplishments

- `Threadline.Test.LeakOracle` (`test/support/leak_oracle.ex`): raw storage-qualified reads of `audit_changes`/`audit_transactions` via `row_to_json` (bypassing the Ecto schema, so a future column is covered automatically); `refute_canaries!/3` (negative check, with an 80-byte window and the op plan in every failure message); `assert_markers!/3` (positive control, so a missing trigger can't pass vacuously); `assert_structure!/3` (D-10.3 structural rules: excluded key absent from `data_after`/`changed_from`/`changed_fields`; masked keys equal the placeholder exactly, even when the plaintext was `nil` or `""`; `table_pk == %{"id" => id}`).
- `Threadline.Test.RedactionLeakGenerators` (`test/support/redaction_leak_generators.ex`): `op_plan_gen/0` generates an INSERT plus 1-4 `frequency`-picked steps (`touch_redacted` with a slot subset biased toward both `secret_excluded`+`secret_masked`, `touch_plain_only`, `noop_update`), a paired-transaction step index, a ~1/3 trailing DELETE, and a generated `include_action_metadata` boolean. Redacted values are ~70% hostile-wrapped canaries (prefix/suffix pool including the placeholder itself, CRLF, multibyte, an occasional 1-4KB pad) and ~10% each `nil`/`""`/exact placeholder (structural-checks-only rungs, per D-08).
- `test/threadline/capture/redaction_leak_property_test.exs`: a dedicated `prop_redaction_leak` fixture table (D-07) with a real per-table redacted trigger installed from `lib/` in `setup_all`, so a `lib/` mutant takes effect. The property threads the row's actual current state across steps (resending unchanged columns, since every UPDATE must set every column), then checks every D-10 surface: raw stored rows, `ChangeDiff` default/`expand_insert_fields: true`/`format: :export_compat`, `to_csv_iodata/2` (generated `include_action_metadata`), `to_json_document/2` (`:wrapped`/`:ndjson`), and `stream_export_rows/2` piped through `format_changes_iodata/3` for `:csv`/`:json_wrapped`/`:ndjson` — with `returned_count` positive controls on every export call. Measured at ~0.05-0.2s (including `THREADLINE_PROPERTY_SCALE=5`), so `@max_runs PropertyRuns.db(20)` stays unchanged.
- `property_generator_coverage_test.exs` gains `sample_db/2` (a 1..20 size ramp matching `PropertyRuns.db/1`'s ceiling, vs `sample/2`'s 1..100 ramp for pure properties) and a describe block proving the dual-slot `touch_redacted` bias (>=40% of plans) and all six redacted-value rungs (nil, "", exact placeholder, placeholder-as-substring, multibyte, >1KB) are reached within 1000 samples.
- Three D-12 mutation controls, each killed 5/5 with a reproduced shrunk counterexample and `lib/` clean after revert: `redaction_changed_from_mask.patch` (masked old values would leak into `changed_from`), `redaction_exclude_change_detect.patch` (excluded column's name/value would enter `changed_fields`/`changed_from`), `redaction_update_path.patch` (redaction would run on INSERT only). For the exclude-change-detect mutant, an `--inverted` run first proves the pre-D-13 example suite stays green under it (a real coverage gap); D-13 then adds `refute "password" in change.changed_fields` and `refute Map.has_key?(change.changed_from, "password")` to `trigger_redaction_test.exs`'s UPDATE example, and a follow-up run proves that one fast deterministic example now kills the same mutant 5/5.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — one canary through a real redacted trigger/storage/diff/CSV round trip** - `a325b443` (feat)
2. **Task 2: Full generator, every surface, structural rules, positive controls, coverage floors** - `4ca78990` (feat)
3. **Task 3: D-12 mutation controls, pre-D-13 survival record, D-13 example gap** - `554c13a2` (test)

**Plan metadata:** pending (this commit)

## Files Created/Modified

- `test/support/leak_oracle.ex` - the shared negative/positive/structural oracle (D-10)
- `test/support/redaction_leak_generators.ex` - the op-plan generator (D-08/D-09)
- `test/threadline/capture/redaction_leak_property_test.exs` - the PROP-04 property
- `test/threadline/capture/trigger_redaction_test.exs` - D-13 assertions closing the exclude-change-detect example gap
- `test/threadline/property_generator_coverage_test.exs` - `sample_db/2` and the RedactionLeakGenerators D-26 floors
- `.planning/phases/227-db-backed-property-tests/tools/mutations/redaction_changed_from_mask.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/redaction_exclude_change_detect.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/redaction_update_path.patch`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-04-mutation-changed-from-mask.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-04-mutation-exclude-change-detect.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-04-mutation-update-path.md`

## Decisions Made

See `key-decisions` in frontmatter. The two load-bearing ones for later plans:

1. The op-plan generator produces independent per-step action descriptors rather than a stateful fold; the property body (not the generator) threads the row's actual current column state across steps. This pattern generalizes to any DB property whose fixture table needs full-row UPDATEs across a variable-length step sequence.
2. `LeakOracle`'s `surfaces` list contract (`[{name, bytes}]`) is deliberately open — D-11 (phase 228) appends `"telemetry:<event>"` surfaces without any change to this module.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `assert_markers!/3` initially checked the plain marker on the `stored:audit_transactions` surface, which never carries host-row columns**
- **Found during:** Task 1, first test run
- **Issue:** `audit_transactions` rows have no `bio` column; checking for the marker there is a vacuous requirement that would always need special-casing, and the first run failed on it.
- **Fix:** The property filters `stored:audit_transactions` out of the surfaces list passed to `assert_markers!/3` (it stays in the list passed to `refute_canaries!/3`, since a leak there would still matter).
- **Files modified:** test/threadline/capture/redaction_leak_property_test.exs
- **Verification:** `mix test test/threadline/capture/redaction_leak_property_test.exs` green
- **Committed in:** `a325b443` (Task 1 commit)

**2. [Rule 1 - Bug] The static call-site contract test flagged literal moduledoc prose as an unprefixed `AuditChange` read**
- **Found during:** Task 2, full-suite run (`mix test`)
- **Issue:** `test/threadline/storage_schema_call_site_contract_test.exs`'s AST/text sweep matched the literal string `Repo.all(AuditChange)` inside this file's moduledoc prose (explaining why `format_changes_iodata/3` needs `stream_export_rows/2` instead), not an actual call site.
- **Fix:** Reworded the moduledoc to describe the same point without the literal pattern the scanner matches.
- **Files modified:** test/threadline/capture/redaction_leak_property_test.exs
- **Verification:** `mix test test/threadline/storage_schema_call_site_contract_test.exs test/threadline/capture/redaction_leak_property_test.exs` green; full `mix test` 0 failures
- **Committed in:** `4ca78990` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs surfaced by real test runs, not scope creep).
**Impact on plan:** Neither changed the plan's design; both are implementation-detail fixes needed for the property and the full suite to actually pass.

## Issues Encountered

None beyond the two auto-fixed items above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PROP-04 is fully proven: the property, its generator, its oracle, and all three mutation controls are in place and green, with the D-13 example gap closed.
- `Threadline.Test.LeakOracle` and `Threadline.Test.RedactionLeakGenerators` are new, phase-227-scoped test-support modules; no later plan in this phase depends on them directly (227-03/04/05 build their own PROP-06/PROP-07 generators and oracles per 227-CONTEXT.md D-14 through D-22), but phase 228's telemetry work can extend `LeakOracle`'s surfaces list additively per D-11.
- No blockers.

---
*Phase: 227-db-backed-property-tests*
*Completed: 2026-10-01*

## Self-Check: PASSED

All created/modified files confirmed on disk; all 3 task commit hashes (`a325b443`, `4ca78990`, `554c13a2`) confirmed in `git log`.
