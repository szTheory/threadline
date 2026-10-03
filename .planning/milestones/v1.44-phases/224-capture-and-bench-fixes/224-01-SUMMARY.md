---
phase: 224-capture-and-bench-fixes
plan: 01
subsystem: capture
tags: [ecto, postgres, migrations, triggers, capture, rollback]

requires: []
provides:
  - "First-run trigger migration down unconditionally drops the table's per-table capture function"
  - "Threadline.Test.MigrationHarness.orphan_capture_functions/0 structural orphan check"
  - "Real Ecto.Migrator partial/full-chain rollback regression tests for the rerun chain"
  - "Regenerated example shape fixture matching the new down shape"
affects: [225-suite-baseline, capture-layer, adopter-facing-migrations]

actuals:
  tokens: 5931
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Unconditional usage-checked drop from the first-run migration, keyed on the deterministic per-table function name, instead of a needs_per_table filter"
    - "Structural pg_proc/pg_trigger orphan check independent of the naming module under test"

key-files:
  created: []
  modified:
    - lib/mix/tasks/threadline.gen.triggers.ex
    - test/support/migration_harness.ex
    - test/threadline/capture/trigger_rerun_test.exs
    - test/mix/tasks/threadline/gen_triggers_test.exs
    - examples/threadline_phoenix/priv/shape_fixtures/migrations/20260930173006_threadline_triggers_shape_code_keyed_shape_composi_f2f800f9eb80.exs

key-decisions:
  - "D-01: emit the per-table function drop from the first-run migration only, unconditionally (no needs_per_table filter); the rerun migration's down stays untouched"
  - "D-02: reuse TriggerSQL.drop_function_if_unused/2 completely unchanged — no quiet option, no new parameter"
  - "D-09: the orphan check is structural (pg_proc/pg_trigger joined on tgparentid = 0), bound to the storage schema as a parameter, and never relies on search_path or Naming"

patterns-established:
  - "Naming.function_name/1 is deterministic per table, so a first-run migration can safely target a per-table function a later rerun might create, with no forward scan"

requirements-completed: [CAPT-01, CAPT-02]

coverage:
  - id: D1
    description: "First-run down unconditionally drops the table's per-table capture function through the unchanged usage-checked drop_function_if_unused/2"
    requirement: CAPT-01
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#rolling back a rerun chain partial rollback keeps capture on the per-table function"
        status: pass
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#rolling back a rerun chain full-chain rollback leaves no orphaned capture function"
        status: pass
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#rolling back a rerun chain a single default run rolls back with no warning and no orphan"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs (down body + rerun detection + trigger names describes)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Deterministic regression proving no orphan, no false WARNING, and no CASCADE across partial and full-chain real Ecto.Migrator rollback"
    requirement: CAPT-02
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_test.exs#describe rolling back a rerun chain (3 tests)"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs#no statement cascades and every quoted identifier fits in 63 bytes"
        status: pass
    human_judgment: false
  - id: D3
    description: "Example shape fixture trigger migration regenerated (never hand-edited), matching the new down shape"
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_migration_contract_test.exs"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-09-30
status: complete
---

# Phase 224 Plan 01: Capture Rollback Fix Summary

**A default-then-rerun `gen.triggers` chain now rolls back to zero orphaned `pg_proc` functions: the first-run migration's `down` unconditionally drops its table's per-table capture function through the unchanged usage-checked `drop_function_if_unused/2`.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-09-30T16:57:23Z (STATE.md last_updated)
- **Completed:** 2026-09-30
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- `down_body/2` in `Mix.Tasks.Threadline.Gen.Triggers` drops every first-run table's per-table capture function unconditionally (no `needs_per_table` filter), with a plain-language `#` comment naming the table and pinning the shared phrase `if this migration or a later rerun created one`. The rerun migration's `down` is untouched: still no trigger drop, no function drop.
- Updated the moduledoc's "Rerunning" section with the same pinned phrase, tying the generated comment to the docs.
- Added `Threadline.Test.MigrationHarness.orphan_capture_functions/0`: a structural `pg_proc`/`pg_trigger` orphan check bound to the storage schema as a parameter, independent of `Threadline.Capture.Naming`.
- Added a new `describe "rolling back a rerun chain"` block in `trigger_rerun_test.exs` with a real `Ecto.Migrator`-backed `apply_down!/1` helper and three tests: partial rollback (keeps capture on the rerun's per-table function, no orphan, no false WARNING), full-chain rollback via `Ecto.Migrator.run(Repo, path, :down, all: true)` (zero orphans), and a single default-mode run (no warning, no orphan).
- Re-pinned every affected expected-output `down` assertion in `gen_triggers_test.exs` (trigger names, rerun detection by table, down body) to include the new unconditional function drop, added `@first_run_down_phrase`, and pinned it in both the moduledoc and a generated first-run `down`.
- Regenerated the committed example shape fixture trigger migration (deleted then regenerated, never hand-edited); its `def down` now contains the function-drop comment/statement pair for all 6 tables.

## Task Commits

1. **Task 1: Tracer — first-run down drops the per-table function; prove it end-to-end through Ecto.Migrator and pg_proc** - `0bc83e3a` (fix)
2. **Task 2: Re-pin every expected-output down assertion, pin the shared phrase, regenerate the example shape fixture** - `0e644dc3` (test)

_Both tasks land as the plan's single fix/test pair; no separate `docs`/`build` commit was needed for this plan._

## Files Created/Modified
- `lib/mix/tasks/threadline.gen.triggers.ex` - `down_body/2` no longer filters function drops by `needs_per_table`; new `first_run_drop_comment/1`; moduledoc "Rerunning" section extended
- `test/support/migration_harness.ex` - new `orphan_capture_functions/0` structural orphan check
- `test/threadline/capture/trigger_rerun_test.exs` - new `describe "rolling back a rerun chain"` (3 tests) + `apply_down!/1` helper
- `test/mix/tasks/threadline/gen_triggers_test.exs` - re-pinned down assertions across 3 describe blocks, `@first_run_down_phrase`, one new moduledoc-pin test
- `examples/threadline_phoenix/priv/shape_fixtures/migrations/20260930173006_threadline_triggers_shape_code_keyed_shape_composi_f2f800f9eb80.exs` - regenerated (renamed from the 20260926100001 version prefix)

## Decisions Made
- Followed 224-CONTEXT.md D-01..D-05, D-08, D-09, D-12 exactly as specified; no deviation from the plan's implementation shape.
- Wrote the `first_run_drop_comment/1` wording as three short lines, keeping the pinned phrase `if this migration or a later rerun created one` on a single line so both the generator output and the test suite's `grep`/`String.contains?` checks match it without needing whitespace normalization for the per-line variant (the moduledoc test does whitespace-normalize, but the direct `File.read!(file) =~ @first_run_down_phrase` assertions in `gen_triggers_test.exs` do not).
- Mixed table sets test ("rerun down never names a first-run table's own comment as if it were the rerun's"): rather than a blanket `refute down_text =~ ~r/#.../`, stripped the three known first-run-comment lines before asserting the rerun comment never names `comments`, since D-01 now makes `comments`'s own first-run comment legitimately mention it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `first_run_drop_comment/1`'s pinned phrase initially wrapped across two lines**
- **Found during:** Task 2 acceptance-criteria verification (`grep -n "if this migration or a later rerun created one"` returned only 1 line instead of the required 2)
- **Issue:** The first draft of the comment wrapped `if this migration or a later` / `rerun created one` across two source lines in the `[...]` list passed to `Enum.map_join`, so the literal phrase never appeared contiguous in the generated migration text.
- **Fix:** Rewrote the three-line comment so the full phrase sits on one line.
- **Files modified:** `lib/mix/tasks/threadline.gen.triggers.ex`
- **Verification:** `grep -n "if this migration or a later rerun created one" lib/mix/tasks/threadline.gen.triggers.ex` now returns 2 lines (moduledoc + comment helper); `mix test` green.
- **Committed in:** `0bc83e3a` (Task 1 commit, fixed before commit)

**2. [Rule 1 - Bug] `orphan_capture_functions/0`'s doc comment literally said "Naming"**
- **Found during:** Task 1 acceptance-criteria verification (`grep -c "Naming" test/support/migration_harness.ex` printed 1 instead of the required 0)
- **Issue:** The `@doc` prose for `orphan_capture_functions/0` named `Threadline.Capture.Naming` to explain independence from it, which itself tripped the acceptance criterion checking for zero literal uses of that word (the check exists to prove the orphan query genuinely doesn't depend on the naming module, and a stray doc mention doesn't violate that, but the acceptance criterion as written is a plain grep).
- **Fix:** Reworded the doc comment to describe the same guarantee without the literal word "Naming".
- **Files modified:** `test/support/migration_harness.ex`
- **Verification:** `grep -c "Naming" test/support/migration_harness.ex` now prints 0; the function itself never referenced `Naming` in code.
- **Committed in:** `0bc83e3a` (Task 1 commit, fixed before commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 — both caught by the plan's own acceptance-criteria greps before committing, no functional change to behavior)
**Impact on plan:** Both fixes are wording-only corrections to satisfy pinned acceptance criteria; no scope creep, no change to the drop logic or SQL.

## Mutation Control (D-11, deterministic half)

Reverted only `lib/mix/tasks/threadline.gen.triggers.ex`'s `down_body/2` change (via `git stash`) with the new tests in place, and ran `mix test test/threadline/capture/trigger_rerun_test.exs --seed 1`:

```
1) test rolling back a rerun chain full-chain rollback leaves no orphaned capture function (Threadline.Capture.TriggerRerunTest)
   test/threadline/capture/trigger_rerun_test.exs:217
   Assertion with == failed
   code:  assert Harness.orphan_capture_functions() -- baseline == []
   left:  ["threadline_capture_changes_test_trigger_rerun_chain"]
   right: []

13 tests, 1 failure
```

Restored the fix (`git stash pop`) and re-ran: `13 tests, 0 failures`. This is the exact mutation control the plan's Task 1 asked for ("Write (b) first and run it BEFORE the generator edit to watch it fail on the orphan assertion, then apply the generator edit and watch it pass") — done post-hoc against the already-written test, with the same red/green proof.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CAPT-01 and CAPT-02 (deterministic half) requirements complete; SUITE-05 (bench compile) and the property-test half of CAPT-02 (D-10) belong to later plans in this phase per the ROADMAP wave split.
- `mix test test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/capture` (232 examples), the example shape-fixture contract/round-trip tests, `mix verify.credo`, and `mix format --check-formatted` all green.
- `bin/verify-repo-hygiene` clean (4262 tracked files, 0 inert).
- Ready for `224-02` (or whichever plan in wave 2/3 covers the property test and bench fix per the roadmap's wave assignment).

## Self-Check: PASSED

- `[ -f lib/mix/tasks/threadline.gen.triggers.ex ]` FOUND
- `[ -f test/support/migration_harness.ex ]` FOUND
- `[ -f test/threadline/capture/trigger_rerun_test.exs ]` FOUND
- `[ -f test/mix/tasks/threadline/gen_triggers_test.exs ]` FOUND
- `[ -f examples/threadline_phoenix/priv/shape_fixtures/migrations/20260930173006_threadline_triggers_shape_code_keyed_shape_composi_f2f800f9eb80.exs ]` FOUND
- `git log --oneline --all --grep="224-01"` — no commits use that grep pattern (commits use adopter-facing subjects per plan instruction to avoid planning vocabulary); verified instead via `git log --oneline -5` showing `0e644dc3` and `0bc83e3a` present in history
- Re-ran all task `<verify>` commands: `mix test test/threadline/capture/trigger_rerun_test.exs` (13/0), `mix test test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/capture` (7 properties, 225 tests, 0 failures), example shape fixture tests (13/0), `mix verify.credo` (clean), `mix format --check-formatted` (clean) — all pass
- `plan_head_before: 916dde2c`, `plan_head_after: 0e644dc3`, commits measured via `git rev-list --count 916dde2c..HEAD` = 2

---
*Phase: 224-capture-and-bench-fixes*
*Completed: 2026-09-30*
