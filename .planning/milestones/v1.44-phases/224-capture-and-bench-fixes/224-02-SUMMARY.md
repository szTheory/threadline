---
phase: 224-capture-and-bench-fixes
plan: 02
subsystem: capture
tags: [stream_data, ecto, postgres, triggers, property-test]

requires:
  - phase: 224-01
    provides: "orphan_capture_functions/0, the unconditional first-run down function drop, and the real Ecto.Migrator apply/rollback helpers on MigrationHarness"
provides:
  - "Threadline.Test.TriggerRunGenerators.run_sequence/0 — 1-4 ordered :default / {:per_table, option} runs, size-independent"
  - "Threadline.Capture.TriggerRerunPropertyTest — DB-backed property (max_runs 20) proving any 1-4-run rerun chain rolls back to zero orphaned capture functions"
  - "CAPT-02 mutation controls (deterministic + property, reproducible seed) and the property's own three-run cost, recorded in 224-EVIDENCE.md"
affects: [225-suite-baseline, 226-pure-property-tests]

actuals:
  tokens: 2657
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Size-independent StreamData generator (frequency over constant lengths + a fixed-length recursive gen all) for a DB-backed property, so a capped max_runs samples every sequence length from the first iteration"
    - "try/after cleanup inside check all (not on_exit) for a DataCase async:false property that performs real DDL per iteration"

key-files:
  created:
    - test/support/trigger_run_generators.ex
    - test/threadline/capture/trigger_rerun_property_test.exs
  modified:
    - .planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md

key-decisions:
  - "run_sequence/0 shares one System.unique_integer([:positive, :monotonic]) call between the table name and its tmp dir, matching the plan's literal instruction and the acceptance criterion counting exactly one occurrence of that call"
  - "Rollback loop uses Enum.reduce over the reversed file list with a `remaining` counter to distinguish 'every file except the first' (remaining > 1) from the first file's own rollback (remaining == 1), rather than a separate index computation"

patterns-established:
  - "A DB-backed property's expectations are derived only from the generated run list and the structural pg_proc/pg_trigger check (Harness.trigger_function/2, Harness.orphan_capture_functions/0), never from Naming — Naming appears exactly once, in cleanup"

requirements-completed: [CAPT-02, SUITE-06]

coverage:
  - id: D1
    description: "DB-backed property (DataCase async:false, max_runs 20) applies 1-4 real generated runs through Ecto.Migrator, rolls every down back in reverse, and proves zero new orphaned capture functions after full rollback"
    requirement: CAPT-02
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_rerun_property_test.exs#a random chain of 1-4 runs rolls back to zero new orphaned capture functions"
        status: pass
    human_judgment: false
  - id: D2
    description: "Property expectations are derived from the run list and the structural pg_trigger/pg_proc query, never from Naming (no-tautology invariant)"
    requirement: CAPT-02
    verification:
      - kind: unit
        ref: "grep -v '^\\s*#' test/threadline/capture/trigger_rerun_property_test.exs | grep -c 'Naming\\.' == 1 (cleanup DROP only)"
        status: pass
    human_judgment: false
  - id: D3
    description: "CAPT-02 mutation control: reverting only the needs_per_table filter turns both the deterministic regression and the property red, with a reproducible seed; restoring the fix turns both green"
    requirement: CAPT-02
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md#CAPT-02 mutation controls"
        status: pass
    human_judgment: false
  - id: D4
    description: "The property test's own cost (three Finished in runs on the restored tree) is recorded separately from the suite wall clock, as DB-backed correctness debt landing before Phase 225's partitioning"
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md#Property test cost"
        status: pass
    human_judgment: false

duration: ~30min
completed: 2026-09-30
status: complete
---

# Phase 224 Plan 02: Capture Rerun Property Test Summary

**A new size-independent StreamData generator and a DB-backed `max_runs 20` property prove that any 1-4-run chain of real `mix threadline.gen.triggers` runs — any mix of default and per-table modes — rolls back to zero orphaned capture functions, with both CAPT-02 mutation controls recorded against a reproducible seed.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-09-30 (session start)
- **Completed:** 2026-09-30
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- `Threadline.Test.TriggerRunGenerators.run_sequence/0`: a new generator module producing 1-4 ordered runs (`:default` or `{:per_table, option}` for `store_changed_from`/`exclude`/`mask`), built entirely from size-independent pieces (`frequency` over `constant` lengths, `member_of`, a fixed-length recursive `gen all`) so a capped `max_runs` samples every sequence length starting from the first iteration. Never reuses `pair_gen()`'s collision-biased long names.
- `Threadline.Capture.TriggerRerunPropertyTest`, a new `DataCase async: false` property with `@max_runs 20`: each iteration creates a uniquely-named table, applies every generated run for real through `Harness.generate!/2` + `Harness.migrate_up/1`, asserts the trigger's function identity matches what the run list predicts (default vs a `threadline_capture_changes_`-prefixed per-table name — never derived from `Naming`), rolls every migration back in reverse through `Harness.migrate_down/1`, and asserts `Harness.orphan_capture_functions() -- baseline == []` throughout. Isolation and cleanup (migrations forgotten, table dropped, capture env and shell restored, tmp removed, stray `mix_shell` messages drained) live in a `try/after` inside `check all`, since `on_exit` never fires between property iterations.
- Both CAPT-02 mutation controls recorded in `224-EVIDENCE.md`: re-adding only the `needs_per_table` filter to `down_body/2`'s `function_downs` turned the existing deterministic regression red (orphaned `threadline_capture_changes_test_trigger_rerun_chain`) and the new property red (seed `554469`, shrunk counterexample `[:default, {:per_table, :store_changed_from}]`, orphaned `threadline_capture_changes_trp_5`). `mix test --seed 554469 ...` reproduced the identical failure once more, confirming the flagged CAPT-02 seed-reproducibility assumption. Restoring the fix (`git checkout --`) turned both green again, confirmed by `git diff --quiet -- lib/`.
- The property test's own cost recorded separately: three consecutive solo runs at 5.1s / 3.8s / 4.1s (`Finished in`), reported as DB-backed correctness debt landing before Phase 225's partitioning (D-18).

## Task Commits

1. **Task 1: Tracer — property over 1-4 real runs rolls back to zero new orphans** - `02c5c92d` (test)
2. **Task 2: Record the CAPT-02 mutation controls and the property's own cost** - `063de72e` (docs)

## Files Created/Modified
- `test/support/trigger_run_generators.ex` - new `Threadline.Test.TriggerRunGenerators.run_sequence/0` generator
- `test/threadline/capture/trigger_rerun_property_test.exs` - new DB-backed property test module
- `.planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md` - new `## CAPT-02 mutation controls` and `## Property test cost` sections (appended after 224-03's `## SUITE-05 mutation control`)

## Decisions Made
- Followed 224-CONTEXT.md D-10 and D-11 exactly as specified; no deviation from the plan's implementation shape.
- Reused one `System.unique_integer([:positive, :monotonic])` call for both the table name and its tmp-dir suffix, per the plan's literal instruction ("tmp under `System.tmp_dir!()` with the same integer") and the acceptance criterion requiring exactly one grep match for that call.
- Wrote the rollback loop as `Enum.reduce` over the reversed file list with a `remaining` counter (starts at `length(files)`, decrements each iteration) rather than a separate zip-with-index, to cleanly distinguish "every file except the first" (`remaining > 1`) from the first file's own rollback (`remaining == 1`) per the plan's phrasing.

## Deviations from Plan

None — plan executed exactly as written. One self-correction caught by the plan's own acceptance-criteria grep before committing: the moduledoc's first draft named `THREADLINE_PROPERTY_SCALE` literally (to explain the `@max_runs` swap point), which tripped the `grep -c "THREADLINE_PROPERTY_SCALE"` == 0 criterion; reworded to describe the same guarantee without the literal token, fixed before the Task 1 commit, no functional change.

## Issues Encountered
None. The property test passed on its first run (no red state encountered from the new code itself — only from the deliberate mutation control in Task 2).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CAPT-02 (property half) complete, alongside CAPT-01/CAPT-02 (deterministic half, 224-01) and SUITE-05 (224-03). Only 224-04 (docs + SUITE-06 measurement + phase gate) remains in this phase.
- `mix test test/threadline/capture test/mix/tasks/threadline/gen_triggers_test.exs` (8 properties, 225 tests, 0 failures), `mix verify.credo` and `mix format --check-formatted` all green.
- `bin/verify-repo-hygiene` clean (4267 tracked files, 0 inert).
- Ready for `224-04` (wave 3, docs + SUITE-06 measurement + `mix ci.all` phase gate).

## Self-Check: PASSED

- `[ -f test/support/trigger_run_generators.ex ]` FOUND
- `[ -f test/threadline/capture/trigger_rerun_property_test.exs ]` FOUND
- `[ -f .planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md ]` FOUND
- `git log --oneline -5` shows `063de72e` and `02c5c92d` present in history
- Re-ran all task `<verify>` commands: `mix test test/threadline/capture/trigger_rerun_property_test.exs` (1/0), the Task 2 automated bash check (`git diff --quiet -- lib/` + both evidence greps, exit 0), `bin/verify-repo-hygiene` (clean) — all pass
- `plan_head_before: 048fe857`, `plan_head_after: 063de72e88ec378ebfc01ab48af96be24066d2ba`, commits measured via `git rev-list --count 048fe857..HEAD` = 2

---
*Phase: 224-capture-and-bench-fixes*
*Completed: 2026-09-30*
