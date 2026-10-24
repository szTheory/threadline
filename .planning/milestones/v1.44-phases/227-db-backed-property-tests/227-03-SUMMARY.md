---
phase: 227-db-backed-property-tests
plan: 03
subsystem: testing
tags: [streamdata, ex_unit_properties, postgres, triggers, as_of]

requires:
  - phase: 227-db-backed-property-tests
    provides: "Threadline.Test.DbProperty (227-01): iteration_key/0, with_iteration/2, delete_iteration!/2, ordered_id/2, the D-06 scale-contract rule, and the hardened mutation-control.sh"
provides:
  - "Threadline.Test.RowHistoryGenerators: history_gen/0, full_row_gen/0, subset_gen/0"
  - "as_of_property_test.exs — PROP-06 property, DB-backed, model-replay oracle over real INSERT/UPDATE/DELETE SQL"
  - "D-17 tie-pinning example in query_test.exs's describe \"as_of/4 — ASOF-01/02/05\""
  - "property_generator_coverage_test.exs: RowHistoryGenerators D-26 floors (delete bias, re-insert after delete)"
  - "five PROP-06 mutation controls (as_of_le, as_of_order, as_of_delete, capture_clock killed 5/5; as_of_tiebreak recorded as an expected survivor, killed instead by the D-17 example)"
affects: [227-04, 227-05, 228]

actuals:
  tokens: 21113
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "model-replay oracle: the property folds the generated steps into its own string-keyed model of the live row as it applies them as real parameterised SQL, never reading data_after/history_query/as_of_query to compute expected values (rejects the Pitfall 3 tautology)"
    - "every UPDATE statement sets all five columns every time (changed columns from the step's generated full_row, unchanged columns from the current model), so an empty subset is a genuine no-op UPDATE that still fires the trigger"
    - "jsonb parameter binding: Postgrex encodes an Elixir term bound to a jsonb column directly via Jason — pre-encoding the value with Jason.encode!/1 before binding double-encodes it into a jsonb string scalar instead of the intended nested object"
    - "--inverted mutation-control run proves an expected survivor honestly: the property (GREEN_FILE) must stay green under the as_of_tiebreak mutant on every seed while the D-17 example (RED_FILE) goes red 5/5, instead of just asserting the property passes"

key-files:
  created:
    - test/support/row_history_generators.ex
    - test/threadline/query/as_of_property_test.exs
    - .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_le.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_order.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_delete.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/capture_clock.patch
    - .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_tiebreak.patch
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-as-of-le.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-as-of-order.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-as-of-delete.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-capture-clock.md
    - .planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-as-of-tiebreak.md
  modified:
    - test/threadline/query_test.exs
    - test/threadline/property_generator_coverage_test.exs

key-decisions:
  - "Used Threadline.StorageSchema.table(\"audit_changes\") (string arg) rather than the PLAN.md acceptance grep's literal StorageSchema.table(:audit_changes) (atom) — the function only accepts a string table name (227-01's established decision, confirmed by every PROP property in this phase); the atom form would raise FunctionClauseError"
  - "RowHistoryGenerators.history_gen/0 generates the full D-15 shape directly (batches of frequency-picked write/delete steps from bounded pools, capped at 8 steps) rather than splitting a minimal tracer generator from a later full one — the tracer task's own files already needed the complete column-value pools to exercise a real INSERT+UPDATE round trip meaningfully"
  - "as_of_tiebreak.patch is the one PROP-06 mutant proven, not just asserted, to survive the property: an --inverted mutation-control run shows the property (GREEN_FILE) stays green at every seed under the mutant while the D-17 example (RED_FILE) goes red 5/5, matching D-16/D-17's \"real capture never ties\" claim with a reproducible check rather than a comment"

patterns-established:
  - "DB-property model-replay oracle for a row's full history: apply generated steps as real parameterised SQL inside one Repo.transaction per batch, read back the newly captured audit_changes row after every statement (readback count/op/data_after side checks), and probe the function under test only at exact, one-microsecond-before, and far-future timestamps — never by sampling random times"

requirements-completed: [PROP-06]

coverage:
  - id: D1
    description: "PROP-06 property: as_of at every point in a generated row history (batches of INSERT/UPDATE/DELETE steps on a real trigger-captured table, up to 8 steps) equals the test's own in-order replay model, both untyped and with cast: true, at the exact bound, one microsecond before it, and one hour after the last step"
    requirement: "PROP-06"
    verification:
      - kind: unit
        ref: "test/threadline/query/as_of_property_test.exs#as_of at every point in a row's history equals an in-order replay of the real mutations that produced it"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-17 example: query_test.exs pins the deterministic-not-causal timestamp tie (higher DbProperty.ordered_id/2 id wins, repeatably) for as_of/4"
    requirement: "PROP-06"
    verification:
      - kind: unit
        ref: "test/threadline/query_test.exs#as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-26 generator coverage floors: a delete step in >=20% of 1000 sampled histories, and at least one history with a write immediately following a delete (re-insert)"
    requirement: "PROP-06"
    verification:
      - kind: unit
        ref: "test/threadline/property_generator_coverage_test.exs#RowHistoryGenerators.history_gen/0 (delete and re-insert bias)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Five D-16 mutation controls: as_of_le, as_of_order, as_of_delete, and capture_clock each killed 5/5 with a reproduced shrunk counterexample, lib/ clean after every revert; as_of_tiebreak recorded honestly as an expected survivor (property stays green on every seed) and killed instead by the D-17 example via an --inverted run"
    requirement: "PROP-06"
    verification:
      - kind: other
        ref: "bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh --max-runs 20 .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_le.patch test/threadline/query/as_of_property_test.exs 5"
        status: pass
    human_judgment: false

duration: ~1h20m
completed: 2026-10-01
status: complete
---

# Phase 227 Plan 03: PROP-06 As-Of Replay Property Summary

**A DB-backed StreamData property proves `as_of` reconstructs a row's state exactly at every point in its real history — including the inclusive bound, deletes, and re-inserts — with four mutation-killed guards and one honestly-recorded expected survivor pinned by a deterministic example**

## Performance

- **Duration:** ~1h20m
- **Started:** 2026-10-01T20:15:00Z (approx.)
- **Completed:** 2026-10-01T21:35:00Z
- **Tasks:** 3
- **Files modified:** 12 (10 created, 2 modified)

## Accomplishments

- `Threadline.Test.RowHistoryGenerators` (`test/support/row_history_generators.ex`): `history_gen/0` yields 1-4 batches of 1-3 steps each (capped at 8 steps overall), each step a `frequency`-picked `{:write, full_row, subset}` or `:delete`. Column values are exact with no normaliser — `name`/`note` cover plain text, a literal single quote, a double quote, CRLF, and multibyte/emoji text; `n` covers zero, negative, a bigint above 2^53, and the signed 64-bit extremes; `flag` covers true/false/nil; `doc` covers nil and a small nested map of strings/ints/bools/nil via `fixed_map` (never a recursive, size-dependent generator). `numeric` and `timestamptz` columns are never generated, per D-14.
- `test/threadline/query/as_of_property_test.exs`: a dedicated `asof_prop_rows` fixture table with the global capture function reinstalled from `lib/` in `setup_all` (so a mutant takes effect every run). The property folds generated steps into its own string-keyed model as it applies them as real parameterised SQL inside one `Repo.transaction` per batch — an INSERT when the row is absent, a full-column UPDATE (changed columns from the step, unchanged from the current model) when present, or a DELETE. After every statement, a storage-qualified raw readback finds exactly one new `audit_changes` row matching the op, checks its `data_after` against the model (a capture-fidelity side check, distinct from an `as_of` failure), and records its `captured_at`. `captured_at` is asserted strictly increasing across all observed steps. `as_of/4` is then probed at every step's exact bound, one microsecond before it (predecessor's expected value, or `:before_audit_horizon` for step 1), and one hour after the last step — both untyped and, at every `{:ok, _}` probe, with `cast: true` against the atomized model. Measured at ~0.4s unscaled and ~0.9s at `THREADLINE_PROPERTY_SCALE=5`, well under the `PropertyRuns.db(20)` budget.
- `test/threadline/query_test.exs` gains the D-17 tie-pinning example: two synthetic `AuditChange` rows with an identical `captured_at` and ids from `DbProperty.ordered_id/2` prove `as_of/4` resolves the tie deterministically (the higher id wins), repeatably.
- `test/threadline/property_generator_coverage_test.exs` gains a `RowHistoryGenerators.history_gen/0` describe block proving the D-26 floors: a delete step reaches >=20% of 1000 sampled histories, and at least one sampled history contains a write immediately following a delete.
- Five D-16 mutation controls against `lib/threadline/query.ex`'s `as_of/4`/`as_of_query/4` and `lib/threadline/capture/trigger_sql.ex`'s global capture function: `as_of_le.patch` (`<=` -> `<`), `as_of_order.patch` (`desc: ac.captured_at` -> `asc:`), `as_of_delete.patch` (drop the `op: "delete"` arm), and `capture_clock.patch` (`clock_timestamp()` -> `now()`, exactly one line) are each killed 5/5 by the property with a reproduced shrunk counterexample, `lib/` clean after every revert. `as_of_tiebreak.patch` (`desc: ac.id` -> `asc:`) is the one mutant the property is expected to survive — proven, not just asserted, via an `--inverted` run showing the property stays green on every seed under the mutant while the new D-17 example goes red 5/5, matching D-17's "real capture never ties" evidence (0 duplicate `captured_at` in 9,001 same-row captures, 38-46us minimum gap).

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — PROP-06 as_of replay property** - `cda62ee7` (feat)
2. **Task 2: D-17 tie example and D-26 coverage floors** - `1bc0e758` (test)
3. **Task 3: D-16 mutation controls and D-17 expected survivor** - `26826c83` (test)

**Plan metadata:** pending (this commit)

## Files Created/Modified

- `test/support/row_history_generators.ex` - the row-history generator (D-04/D-15)
- `test/threadline/query/as_of_property_test.exs` - the PROP-06 property
- `test/threadline/query_test.exs` - D-17 tie-pinning example
- `test/threadline/property_generator_coverage_test.exs` - `RowHistoryGenerators` D-26 floors
- `.planning/phases/227-db-backed-property-tests/tools/mutations/as_of_le.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/as_of_order.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/as_of_delete.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/capture_clock.patch`
- `.planning/phases/227-db-backed-property-tests/tools/mutations/as_of_tiebreak.patch`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-as-of-le.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-as-of-order.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-as-of-delete.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-capture-clock.md`
- `.planning/phases/227-db-backed-property-tests/evidence/PROP-06-mutation-as-of-tiebreak.md`

## Decisions Made

See `key-decisions` in frontmatter. The two load-bearing ones for later plans:

1. `StorageSchema.table/2` takes a string table name, confirmed again here — PLAN.md's acceptance-criteria grep for the atom form was stale from before 227-01 established this.
2. Postgrex encodes an Elixir term bound to a jsonb parameter directly via Jason; pre-encoding a map with `Jason.encode!/1` before binding it double-encodes it into a jsonb string scalar. Any future raw-SQL jsonb write in this phase (227-04's retention fixture inserts via `insert_all`, which goes through Ecto's own type encoding, is unaffected) should bind the raw term, not a pre-encoded string.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PLAN.md's acceptance grep cites an atom-arg `StorageSchema.table/2` call that does not exist**
- **Found during:** Task 1, writing the property per PLAN.md's acceptance criteria
- **Issue:** PLAN.md's Task 1 acceptance criteria greps for `StorageSchema.table(:audit_changes)` (atom), but `Threadline.StorageSchema.table/2`'s guard clause only matches string literals (227-01's established decision, confirmed by 227-02's `LeakOracle` and `db_property.ex`). Using the atom form would raise `FunctionClauseError`.
- **Fix:** Used the string form `StorageSchema.table("audit_changes")` throughout, consistent with every other PROP property in this phase.
- **Files modified:** test/threadline/query/as_of_property_test.exs
- **Verification:** `mix test test/threadline/query/as_of_property_test.exs` green
- **Committed in:** `cda62ee7` (Task 1 commit)

**2. [Rule 1 - Bug] jsonb parameter double-encoding on first INSERT**
- **Found during:** Task 1, first test run
- **Issue:** Binding `Jason.encode!(doc)` as a `$N::jsonb` parameter stored the column as a jsonb **string scalar** containing the escaped JSON text (confirmed via `jsonb_typeof` returning `"string"`), not the intended nested object — because Postgrex already Jason-encodes an Elixir term bound to a jsonb parameter, so pre-encoding double-encodes it.
- **Fix:** Bind the raw Elixir term (map or `nil`) directly; removed the `Jason.encode!/1` call.
- **Files modified:** test/threadline/query/as_of_property_test.exs
- **Verification:** `mix test test/threadline/query/as_of_property_test.exs --repeat-until-failure 20` green
- **Committed in:** `cda62ee7` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs surfaced by the first real test run, not scope creep).
**Impact on plan:** Neither changed the plan's design; both are implementation-detail fixes needed for the property to actually work against real Postgres/Postgrex.

## Issues Encountered

None beyond the two auto-fixed items above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PROP-06 is fully proven: the property, its generator, its D-17 example, its D-26 coverage floors, and all five mutation controls (four killed, one honestly recorded as an expected survivor) are in place and green.
- `Threadline.Test.RowHistoryGenerators` is new, phase-227-scoped test-support; 227-04 (PROP-07 retention) builds its own `RetentionCutoffGenerators` per 227-CONTEXT.md and does not depend on this module.
- Full `mix test` is green (2665 tests, 0 failures) with these changes in place; `mix verify.format` and `mix verify.credo` are clean.
- No blockers.

---
*Phase: 227-db-backed-property-tests*
*Completed: 2026-10-01*

## Self-Check: PASSED

All created/modified files confirmed on disk; all 3 task commit hashes (`cda62ee7`, `1bc0e758`, `26826c83`) confirmed in `git log`.
