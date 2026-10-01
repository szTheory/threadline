---
phase: 226-pure-property-tests-and-run-budget
plan: 05
subsystem: testing
tags: [stream_data, property-testing, run-budget, ci, yaml_elixir, mutation-testing]

requires:
  - phase: 226-pure-property-tests-and-run-budget
    provides: "Threadline.Test.PropertyRuns (scale/0, parse_scale/1, pure/1, db/1) (226-01); CursorGenerators, ChangeFactGenerators, RedactionPolicyGenerators, ExportHostileValueGenerators (226-01..226-04)"
provides:
  - "test/test_helper.exs: fail-fast THREADLINE_PROPERTY_SCALE check right after ExUnit.start(), one-line banner on a non-1 scale"
  - "flake-detection.yml `id: repeat` step: THREADLINE_PROPERTY_SCALE: \"5\" (ci.yml untouched)"
  - "CONTRIBUTING.md \"Property tests\" paragraph documenting the knob"
  - "naming_property_test.exs, trigger_migration_property_test.exs, trigger_rerun_property_test.exs routed through PropertyRuns.pure/1 / .db/1"
  - "Threadline.PropertyScaleContractTest (test/threadline/property_scale_contract_test.exs): parsed-YAML + AST pin on the whole PROP-08 wiring, 7 mutation controls"
  - "Threadline.PropertyGeneratorCoverageTest (test/threadline/property_generator_coverage_test.exs): D-22 generator-coverage floors for all four phase generators"
affects: [226-06]

actuals:
  tokens: 9063
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Deterministic independent-seed sampling for coverage floors: StreamData.seeded/2 hard-codes its own seed into the returned generator and ignores the per-element seed a caller pipes in, so draining many elements from one seeded generator yields n copies of one value, not n independent draws. sample/2 instead calls StreamData.seeded/2 once per index with a different integer seed (each wrapped in its own single-element Enum.at(0) pull), with a rem(i, 100) + 1 size ramp — deterministic, reproducible under any --seed, and genuinely varied."
    - "Parsed-YAML + AST pin instead of regex: property_scale_contract_test.exs parses both workflow YAMLs with YamlElixir and AST-scans every *_property_test.exs with Code.string_to_quoted! rather than grepping — a regex cannot tell which step owns an env key or distinguish a literal max_runs from a PropertyRuns.pure(n) call."
    - "async: true contract test with zero env mutation: all scale-arithmetic assertions (1 -> unchanged, 5 -> x5/x3-capped) go through pure helper functions parameterized by an explicit scale integer, never System.put_env, so the contract test is safe to run in parallel with every other async suite."

key-files:
  created:
    - test/threadline/property_scale_contract_test.exs
    - test/threadline/property_generator_coverage_test.exs
  modified:
    - test/test_helper.exs
    - .github/workflows/flake-detection.yml
    - CONTRIBUTING.md
    - test/threadline/capture/naming_property_test.exs
    - test/threadline/mix/trigger_migration_property_test.exs
    - test/threadline/capture/trigger_rerun_property_test.exs

key-decisions:
  - "CONTRIBUTING.md's property-tests paragraph originally named Threadline.Test.PropertyRuns.parse_scale/1 as a fully qualified module reference; public_surface_contract_test.exs treats any \\bThreadline\\.… token in a public doc as a claim that the module is part of the packaged lib/ surface, and Threadline.Test.PropertyRuns lives under test/support/, not lib/. Fixed by pointing at the file and function name instead of the qualified module path, which keeps the doc accurate without implying the test-support module is public API."
  - "property_generator_coverage_test.exs samples 1000 independent draws per generator via a different StreamData.seeded(gen, i) call per index (never piping one seeded generator into Enum.take), documented inline with the reasoning, since seeded/2 ignoring the incoming seed was probed and confirmed during planning (D-22 prohibition)."

requirements-completed: [PROP-01, PROP-02, PROP-03, PROP-05]

coverage:
  - id: D1
    description: "test/test_helper.exs reads PropertyRuns.scale() once directly after ExUnit.start(); an invalid THREADLINE_PROPERTY_SCALE raises before any test runs, and a non-1 scale prints exactly one banner line naming the pure/DB multipliers"
    requirement: "PROP-08"
    verification:
      - kind: unit
        ref: "mix test test/threadline/flake_classifier_contract_test.exs"
        status: pass
      - kind: other
        ref: "bash -c 'THREADLINE_PROPERTY_SCALE=11 mix test test/threadline/capture/naming_property_test.exs; test $? -ne 0'"
        status: pass
    human_judgment: false
  - id: D2
    description: "flake-detection.yml's `id: repeat` step sets THREADLINE_PROPERTY_SCALE: \"5\" with a comment pointing at the contract test; ci.yml never sets it; CONTRIBUTING.md documents the knob"
    requirement: "PROP-08"
    verification:
      - kind: unit
        ref: "mix test test/threadline/property_scale_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "naming_property_test.exs, trigger_migration_property_test.exs, and trigger_rerun_property_test.exs route every check all max_runs through PropertyRuns.pure/1 or .db/1 (no hard-coded max_runs literals remain)"
    requirement: "PROP-08"
    verification:
      - kind: unit
        ref: "mix test test/threadline/capture/naming_property_test.exs test/threadline/mix/trigger_migration_property_test.exs test/threadline/capture/trigger_rerun_property_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "property_scale_contract_test.exs (async: true, zero env mutation) pins parse_scale/pure/db arithmetic at scales 1 and 5, parses both workflow YAMLs with YamlElixir, AST-scans every *_property_test.exs for in-range PropertyRuns calls, and all 7 mutation controls (misspelled key, env moved to the wrong step, value \"1\", key deleted, key added to ci.yml, a 300-literal fixture, a no-max_runs fixture) each produce a violation while differing from the original input"
    requirement: "PROP-08"
    verification:
      - kind: unit
        ref: "mix test test/threadline/property_scale_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "property_generator_coverage_test.exs (D-22) samples CursorGenerators.paging_gen/0, ChangeFactGenerators.fact_gen/0, RedactionPolicyGenerators.policy_gen/0, and ExportHostileValueGenerators.export_row_gen/0 1000 times each via deterministic per-index seeding and asserts the floors the plan specifies (tie-timestamp rates, op x before_values cells, defect-tag coverage + valid-rate, and CSV/JSON-hostile value coverage), each assert carrying a message naming the bias it protects"
    requirement: null
    verification:
      - kind: unit
        ref: "mix test test/threadline/property_generator_coverage_test.exs"
        status: pass
      - kind: unit
        ref: "mix test test/threadline/property_generator_coverage_test.exs --seed 1"
        status: pass
    human_judgment: false
  - id: D6
    description: "Full repo gates clean after this plan: mix compile --warnings-as-errors, mix format --check-formatted, mix verify.credo, and the full mix test suite (28 properties, 2649 tests, 0 failures, 3 excluded)"
    requirement: null
    verification:
      - kind: unit
        ref: "mix test (full suite)"
        status: pass
      - kind: unit
        ref: "mix verify.credo"
        status: pass
    human_judgment: false

duration: ~1h10min
completed: 2026-10-01
status: complete
---

# Phase 226 Plan 5: Pure Property Tests and Run Budget — PROP-08 Run Budget Summary

**Wires and pins PROP-08 end to end: a fail-fast THREADLINE_PROPERTY_SCALE check in test_helper.exs, scale 5 on the weekly Flake Detection repeat step only, all three pre-existing property files routed through `PropertyRuns`, a parsed-YAML + AST contract test with seven mutation controls, and D-22 generator-coverage floors proving every generator's stated bias is actually reached.**

## Performance

- **Duration:** ~1h10min (continuation session; a prior executor completed Tasks 1-2 and left Task 3's file written but uncommitted and ungated)
- **Completed:** 2026-10-01
- **Tasks:** 3
- **Files modified:** 8 (2 created, 6 modified)

## Accomplishments

- **D-08** `test/test_helper.exs` binds `scale = Threadline.Test.PropertyRuns.scale()` immediately after `ExUnit.start()`, so an out-of-range `THREADLINE_PROPERTY_SCALE` aborts the run before any test executes; a non-1 scale prints one banner line (`THREADLINE_PROPERTY_SCALE=5: pure max_runs x5, DB x3`) that does not interfere with `bin/classify-flake-run`'s header-counting (verified against both a passing and a flaky fixture log, plus the full `flake_classifier_contract_test.exs` suite).
- **D-09** `flake-detection.yml`'s `id: repeat` step sets `THREADLINE_PROPERTY_SCALE: "5"` with a one-line comment pointing at the contract test; `ci.yml` is untouched. **D-13** CONTRIBUTING.md's "Deterministic tests" section gained a "Property tests" paragraph covering the knob's range, the pure/DB multiplier rule, `mix test --only property`, and `--seed` replay.
- **D-10** `naming_property_test.exs` (7 `check all` calls), `trigger_migration_property_test.exs` (two `max_runs: 300` literals), and `trigger_rerun_property_test.exs` (`@max_runs 20`) now route through `PropertyRuns.pure(200)` / `PropertyRuns.db(20)` instead of implicit defaults or hard-coded literals.
- **D-11** `Threadline.PropertyScaleContractTest` (async: true, zero `System.put_env` calls) pins the whole wiring: pure-function arithmetic checks at scales 1 and 5; `YamlElixir`-parsed assertions that exactly one step across both workflows (`flake-detection.yml`'s `repeat` step) sets the env key and `ci.yml` never does; an `Code.string_to_quoted!`-based AST scan of every `test/**/*_property_test.exs` requiring in-range `PropertyRuns.pure/db` calls (directly or via `@max_runs`); and 7 mutation controls (key misspelled, env on the wrong step, value `"1"`, key deleted, key added to `ci.yml`, a `max_runs: 300` fixture, a fixture `check all` with no `max_runs`) that each assert the mutated input differs from the original and each produces a violation.
- **D-22** `Threadline.PropertyGeneratorCoverageTest` samples each of this phase's four generators 1000 times via a deterministic `sample/2` helper (a fresh `StreamData.seeded(gen, i)` draw per index, size-ramped with `StreamData.resize(rem(i, 100) + 1)` — never one seeded generator piped into `Enum.take`, which would yield n copies of a single value) and asserts named floors: `CursorGenerators.paging_gen/0` (≥25% duplicate-timestamp lists, a 3+-way tie, an adjacent-1µs-gap pair, both `k == n` and `k > n` page sizes); `ChangeFactGenerators.fact_gen/0` (every `op_cells/0` cell reached, `{:present, nil}` priors present); `RedactionPolicyGenerators.policy_gen/0` (every `defect_tags/0` tag reached, ≥30% valid); `ExportHostileValueGenerators.export_row_gen/0` (a bare `"`, `,`, lone CR, lone LF, non-ASCII grapheme, and `nil` all present across raw-string and JSON-encoded columns). Passes under two different ExUnit seeds, proving the sampling is seed-independent.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fail-fast scale check, workflow env and CONTRIBUTING docs** - `0c6fd8d3` (feat)
2. **Task 2: Move existing properties onto PropertyRuns and pin the wiring** - `a5d4e194` (test)
3. **Task 3: Generator coverage floors (D-22)** - `5daaf1c7` (test), plus a necessary pre-commit fix `2af789be` (fix)

**Plan metadata:** pending (this commit)

## Files Created/Modified

- `test/test_helper.exs` - fail-fast `PropertyRuns.scale()` check + banner, right after `ExUnit.start()`
- `.github/workflows/flake-detection.yml` - `THREADLINE_PROPERTY_SCALE: "5"` on the `repeat` step only
- `CONTRIBUTING.md` - "Property tests" paragraph in "Deterministic tests"
- `test/threadline/capture/naming_property_test.exs` - all 7 `check all` calls use `PropertyRuns.pure(200)`
- `test/threadline/mix/trigger_migration_property_test.exs` - both `max_runs: 300` literals replaced
- `test/threadline/capture/trigger_rerun_property_test.exs` - `@max_runs PropertyRuns.db(20)`, moduledoc updated
- `test/threadline/property_scale_contract_test.exs` - `Threadline.PropertyScaleContractTest`, 7 mutation controls
- `test/threadline/property_generator_coverage_test.exs` - `Threadline.PropertyGeneratorCoverageTest`, D-22 floors

## Decisions Made

- CONTRIBUTING.md's property-tests paragraph names the knob's implementation by file/function (`test/support/property_runs.ex`, `parse_scale/1`) rather than a fully qualified `Threadline.Test.PropertyRuns` module reference, because `public_surface_contract_test.exs` requires every `Threadline.…`-shaped token in a public doc to resolve to a module actually packaged under `lib/`, and this is a test-support module.
- `property_generator_coverage_test.exs`'s `sample/2` deliberately avoids `StreamData.seeded(gen, s) |> Enum.take(n)` (confirmed during planning to return n copies of one value, since `seeded/2` ignores the per-element seed its caller pipes in) in favor of one independent `StreamData.seeded/2` call per sample index, each wrapped in its own `Enum.at(0)` pull.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CONTRIBUTING.md's fully qualified `Threadline.Test.PropertyRuns` reference broke `public_surface_contract_test.exs`**
- **Found during:** Task 3, first full `mix test` run after re-running all gates
- **Issue:** Task 1's CONTRIBUTING.md addition named `Threadline.Test.PropertyRuns.parse_scale/1` as a backticked, fully qualified module reference. `public_surface_contract_test.exs`'s reference inventory only contains modules whose compiled source lives under `lib/`; `Threadline.Test.PropertyRuns` is a `test/support/` module, so both `public_doc_refs_contribute owns a nonempty public-document reference slice` and `all local, external, and module-doc subjects have one exact owner` failed with `unknown public references: %{modules: [Threadline.Test.PropertyRuns], ...}`.
- **Fix:** Reworded the sentence to point at the file and function name (`test/support/property_runs.ex`, `parse_scale/1`) instead of the qualified module path — same information, no claim that the module is public API.
- **Files modified:** `CONTRIBUTING.md`
- **Verification:** `mix test test/threadline/public_surface_contract_test.exs` (38 tests, 0 failures); full `mix test` re-run afterward: 28 properties, 2649 tests, 0 failures, 3 excluded.
- **Committed in:** `2af789be` (separate fix commit, since the offending line was already committed in `0c6fd8d3` from the prior session)

---

**Total deviations:** 1 auto-fixed (Rule 1 — a doc-reference bug that broke an existing contract test, caught by the plan's own full-suite gate before this plan's completion).
**Impact on plan:** None on scope; the fix only reworded one CONTRIBUTING.md sentence, no behavior or test logic changed.

## Issues Encountered

A prior executor session completed Tasks 1-2 (committed) and wrote Task 3's test file to disk, but stopped before running the plan's gates. This session verified Task 3's file already met every acceptance criterion (`StreamData.resize` present, zero `Enum.take(`, every floor `assert` carries a message, passes under two different seeds), then ran the full gate sequence (`mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix verify.credo`, full `mix test`), which surfaced the CONTRIBUTING.md regression above. No rework of the already-completed tasks was needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PROP-08 is fully wired: a bad scale aborts before any test runs, the weekly Flake Detection lane runs properties at 5x/3x-capped, every existing property file is routed through `PropertyRuns`, and the wiring is pinned by a parsed-YAML + AST contract test with 7 mutation controls.
- D-22's generator-coverage floors are in place for all four of this phase's generator modules (`CursorGenerators`, `ChangeFactGenerators`, `RedactionPolicyGenerators`, `ExportHostileValueGenerators`), reusable by 226-06 or 227 without further generator-coverage work.
- Full `mix test` (2649 tests, 0 failures), `mix verify.credo`, `mix compile --warnings-as-errors`, and `mix format --check-formatted` are all clean repo-wide.
- Per CLAUDE.md, `.planning/REQUIREMENTS.md` PROP-08 stays unchecked here — 226-06 closes it (budget-sizing plan not yet run).
- No blockers for 226-06.

---
*Phase: 226-pure-property-tests-and-run-budget*
*Completed: 2026-10-01*

## Self-Check: PASSED
