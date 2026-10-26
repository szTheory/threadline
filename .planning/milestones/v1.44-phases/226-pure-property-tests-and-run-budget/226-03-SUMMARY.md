---
phase: 226-pure-property-tests-and-run-budget
plan: 03
subsystem: testing
tags: [stream_data, property-testing, change-diff, mutation-testing]

requires:
  - phase: 226-pure-property-tests-and-run-budget
    provides: "Threadline.Test.PropertyRuns (pure/1 run-budget knob) and the reusable .planning/.../tools/mutation-control.sh runner (226-01)"
provides:
  - "Threadline.Test.ChangeFactGenerators (test/support/change_fact_generators.ex): fact_gen/0, to_audit_change/1, op_cells/0 — fact-first generator reused by plan 04/05 for export rows and generator coverage"
  - "PROP-02 property: test/threadline/change_diff_property_test.exs (oracle, structural, metamorphic, expand_insert_fields)"
  - "PROP-02 mutation control recorded in evidence/ (5/5 kill)"
affects: [226-04, 226-05, 226-06, 227]

actuals:
  tokens: 6325
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Fact-first generation: the generator draws the ground truth (op, before_values mode, key shape, per-field after/prior facts) before building the real %AuditChange{} struct, so the test's oracle reads the facts directly and never calls ChangeDiff or inspects its built data_after/changed_from maps by key lookup"
    - "Size-independent field selection via a fixed-length boolean mask over a 12-name pool (list_of(boolean(), length: n)), rather than a size-dependent uniq_list_of, so every op x before_values matrix cell is reachable within a bounded max_runs regardless of how many fields a given draw selects"
    - "A single `keys` fact (:string | :atom) applied consistently to every map key in one fact, never mixed, since ChangeDiff's precedence for a map holding both forms of the same key is unspecified behaviour this generator deliberately does not pin"

key-files:
  created:
    - test/support/change_fact_generators.ex
    - test/threadline/change_diff_property_test.exs
    - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/change_diff.patch
    - .planning/phases/226-pure-property-tests-and-run-budget/evidence/PROP-02-mutation-change-diff.md
  modified:
    - .planning/phases/226-pure-property-tests-and-run-budget/deferred-items.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "The oracle (expected/3 in the test file) takes both `fact` and the built `ch` struct, but only reads `ch`'s pass-through identifier/metadata fields (id, transaction_id, table_schema, table_name, table_pk, captured_at, data_after) — field_changes construction reads only `fact.fields`/`fact.mode`/`fact.extra_after`, never a keyed lookup into ch.data_after or ch.changed_from, so the comparison against ChangeDiff.from_audit_change/2's real output is not tautological"
  - "data_after is legitimate pass-through in both ChangeDiff and the oracle (ChangeDiff literally forwards ch.data_after unchanged), so reusing ch.data_after as the oracle's 'data_after' key is correct, not a shortcut around the independence requirement — only field_changes construction is held to the no-lookup rule"
  - "The 'extra data_after columns' metamorphic property compares only the two maps' field_changes key, not the whole map, since data_after is expected to legitimately differ between the base and widened fixture; an initial whole-map comparison caught this as a real test bug before the fix (see Deviations)"

requirements-completed: [PROP-02]

coverage:
  - id: D1
    description: "ChangeFactGenerators generates facts first (op, mode, keys, per-field after/prior) and builds the %AuditChange{} only from those facts; fact_gen/0 is size-independent via a fixed-length boolean mask over a 12-name pool"
    requirement: "PROP-02"
    verification:
      - kind: unit
        ref: "mix test test/threadline/change_diff_property_test.exs (uses ChangeFactGenerators.fact_gen/0 and to_audit_change/1)"
        status: pass
    human_judgment: false
  - id: D2
    description: "PROP-02 oracle proves ChangeDiff.from_audit_change/2 matches a fact-derived expectation across the whole INSERT/UPDATE/DELETE x before_values matrix, plus structural (sorted names, none/sparse key presence, DELETE emptiness), metamorphic (atom vs string keys, changed_fields order, extra data_after columns) and expand_insert_fields properties"
    requirement: "PROP-02"
    verification:
      - kind: unit
        ref: "mix test test/threadline/change_diff_property_test.exs test/threadline/change_diff_test.exs"
        status: pass
      - kind: unit
        ref: "THREADLINE_PROPERTY_SCALE=5 mix test test/threadline/change_diff_property_test.exs --seed 1 and --seed 2"
        status: pass
    human_judgment: false
  - id: D3
    description: "The map_has_field? -> map_get != nil mutant in build_update_field/4 (turns a captured JSON null prior into prior_state: omitted instead of before: null) is killed 5/5 across seeds, reproduces on seed 1, and lib/ is restored clean and green afterwards"
    requirement: "PROP-02"
    verification:
      - kind: other
        ref: "bash .planning/.../tools/mutation-control.sh --max-runs 150 .planning/.../tools/mutations/change_diff.patch test/threadline/change_diff_property_test.exs 5"
        status: pass
    human_judgment: false

duration: ~45min
completed: 2026-10-01
status: complete
---

# Phase 226 Plan 3: Pure Property Tests and Run Budget — PROP-02 ChangeDiff Summary

**PROP-02 fact-first oracle for ChangeDiff's INSERT/UPDATE/DELETE x before_values matrix, plus structural and metamorphic properties, with the JSON-null-vs-omitted mutation control killed 5/5.**

## Performance

- **Duration:** ~45min
- **Completed:** 2026-10-01
- **Tasks:** 2
- **Files modified:** 6 (4 created, 2 modified)

## Accomplishments

- `Threadline.Test.ChangeFactGenerators` — draws the ground truth first: `op` (both cases), `mode` (`:none`/`:sparse_empty`/`:sparse_partial`), `keys` (`:string`/`:atom`), and a per-field `%{name, after, prior}` list, selected via a fixed-length boolean mask over a 12-name pool so the draw is size-independent. `{:present, nil}` priors land about a third of the time; `after` is absent about 30% of the time; `extra_after` columns (present in `data_after`, outside `changed_fields`) are drawn separately. `to_audit_change/1` renders these facts into a real `%Threadline.Capture.AuditChange{}` with no `ChangeDiff`-shaped logic. `op_cells/0` exposes the 9-cell op x mode matrix for plan 05's generator-coverage test.
- PROP-02 property (`change_diff_property_test.exs`): the oracle (`expected/3`) reads only the generated facts for `field_changes` construction — never a keyed lookup into the built struct's `data_after`/`changed_from` — and is compared against the real `ChangeDiff.from_audit_change/2` output with `===`. Covers the full op x before_values matrix plus `expand_insert_fields`.
- Structural properties: `field_changes` sorted by name; UPDATE names equal `changed_fields`; `"none"` omits `before`/`prior_state` on every field; `"sparse"` (both empty and partial) has exactly one of `before`/`prior_state` per field; DELETE always gives `[]` and `data_after: nil`.
- Metamorphic properties: atom-keyed vs string-keyed renderings of the same fact give identical `field_changes`; shuffling `changed_fields`' order changes nothing; widening `data_after` with columns outside `changed_fields` leaves UPDATE `field_changes` identical.
- The PROP-02 mutation control (`map_has_field?(cf, name)` -> `map_get(cf, name) != nil` in `build_update_field/4`) is killed 5/5 across seeds 1-5, reproduces the same counterexample on seed 1's second run, and `lib/` is restored clean and green afterward — recorded in `evidence/PROP-02-mutation-change-diff.md`.
- The 226-02 deferred `mix format` item is confirmed resolved (fixed by `b24ee66a`) and `REQUIREMENTS.md` now marks PROP-02 complete.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fact-first generator, independent oracle and the PROP-02 properties** - `3d574a19` (test)
2. **Task 2: ChangeDiff mutation control recorded** - `46bb13f1` (test)

Housekeeping commits (not plan tasks): `0d479ce7` (docs, resolved deferred item), `1f8e63af` (docs, REQUIREMENTS.md PROP-02 complete).

## Files Created/Modified

- `test/support/change_fact_generators.ex` - `Threadline.Test.ChangeFactGenerators`: `fact_gen/0`, `to_audit_change/1`, `op_cells/0`
- `test/threadline/change_diff_property_test.exs` - PROP-02 oracle, structural, metamorphic and expand_insert_fields properties
- `.planning/.../tools/mutations/change_diff.patch` - `map_has_field?` -> `map_get != nil` mutant on `build_update_field/4`
- `.planning/.../evidence/PROP-02-mutation-change-diff.md` - mutation-control evidence, 5/5 kill
- `.planning/phases/226-pure-property-tests-and-run-budget/deferred-items.md` - marked the 226-02 format item resolved
- `.planning/REQUIREMENTS.md` - PROP-02 checked off (checkbox + traceability table)

## Decisions Made

- The oracle is allowed to read `ch`'s pure pass-through fields (id, transaction_id, table_schema/name, table_pk, captured_at, data_after) because `ChangeDiff` itself does nothing but forward those columns unchanged — the independence requirement (D-14) is specifically that `field_changes` construction never derives from a keyed lookup into the built struct, and that boundary is what the test enforces and what the acceptance-criteria `awk`/`grep` scan over `defp expected` verifies.
- Field-name selection uses a fixed-length boolean mask (`list_of(boolean(), length: n)`) over the full pool rather than a size-dependent `uniq_list_of`, matching 226-01's discovery that `uniq_list_of/2` over a small fixed pool hits StreamData's "too many non-unique elements" guard at larger generation sizes.
- The pool is a plain module attribute of 12 lowercase field names (`name email status age active role note code level flag kind tag`), bounded so repeated `String.to_atom/1` calls in the `:atom`-keys path never risk atom-table growth across runs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Metamorphic "extra data_after columns" property compared the wrong scope**
- **Found during:** Task 1, first `mix test` run
- **Issue:** The property asserted the *entire* `ChangeDiff.from_audit_change/2` output was unchanged after widening `data_after` with an extra column. That's wrong — `data_after` itself legitimately differs (it now includes the extra column); only `field_changes` is expected to stay identical, since `update_field_changes/1` only iterates `changed_fields`.
- **Fix:** Narrowed the assertion to compare `["field_changes"]` only.
- **Files modified:** `test/threadline/change_diff_property_test.exs`
- **Verification:** `mix test test/threadline/change_diff_property_test.exs` — all 10 properties green afterward.
- **Committed in:** `3d574a19` (part of Task 1's commit; caught and fixed before committing)

---

**Total deviations:** 1 auto-fixed (Rule 1 — test logic bug caught before commit).
**Impact on plan:** None on `lib/` or scope; the fix only tightened the test's own assertion to match the documented contract (UPDATE iterates `changed_fields` only, not `Map.keys(data_after)`).

## Issues Encountered

None beyond the deviation above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `Threadline.Test.ChangeFactGenerators` is ready for reuse by plan 04 (export round-trip rows, per 226-CONTEXT D-16: "Row maps come from ChangeFactGenerators with the `tx_*` fields...") and plan 05's generator-coverage test (`op_cells/0`).
- PROP-02 is fully proven: the oracle, structural/metamorphic properties, and the mutation control are all green/red exactly as predicted; `lib/` is clean; full `mix test` is 2601 tests / 0 failures; `mix verify.credo` and `mix format --check-formatted` are clean repo-wide.
- No blockers for 226-04 onward.

---
*Phase: 226-pure-property-tests-and-run-budget*
*Completed: 2026-10-01*

## Self-Check: PASSED

All 4 created files confirmed present on disk; all 4 commits (`3d574a19`, `46bb13f1`, `0d479ce7`, `1f8e63af`) confirmed in `git log --oneline --all`.
