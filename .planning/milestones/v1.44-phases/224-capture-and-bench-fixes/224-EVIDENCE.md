# Phase 224 evidence

## SUITE-05 mutation control

Date: 2026-09-30
Base commit: `cfe1ce59`

Local mutation control for the bench bare-compile wiring (D-16). The `def cli` line
was removed from `bench/mix.exs`, both bench build dirs were wiped, and
`mix verify.bench_compile` was run from a clean bench state with `MIX_ENV` unset.

Commands:

```
rm -rf bench/_build bench/deps
env -u MIX_ENV mix verify.bench_compile
```

### Red (mutated: `def cli` removed from `bench/mix.exs`)

```
==> threadline
Compiling 156 files (.ex)
    error: module ExUnitProperties is not loaded and could not be found
    │
  8 │   use ExUnitProperties
    │   ^^^^^^^^^^^^^^^^^^^^
    │
    └─ test/support/naming_generators.ex:8: Threadline.Test.NamingGenerators (module)


== Compilation error in file test/support/naming_generators.ex ==
** (CompileError) test/support/naming_generators.ex: cannot compile module Threadline.Test.NamingGenerators (errors have been logged)
    (elixir 1.17.3) expanding macro: Kernel.use/1
    test/support/naming_generators.ex:8: Threadline.Test.NamingGenerators (module)
could not compile dependency :threadline, "mix compile" failed. Errors may have been logged above. You can recompile this dependency with "mix deps.compile threadline --force", update it with "mix deps.update threadline" or clean it with "mix deps.clean threadline"
** (Mix) verify.bench_compile failed (1)
```

Restored with `git checkout -- bench/mix.exs`; confirmed `git diff --quiet -- bench/` exited 0
(no residual mutation).

### Green (restored, bench build dirs wiped again)

```
==> threadline
Compiling 156 files (.ex)
Generated threadline app
==> bench
Generated bench app
```

`mix verify.bench_compile` exited 0.

## CAPT-02 mutation controls

Date: 2026-09-30
Base commit (fix restored): `02c5c92d`

Local mutation control for the down-path function drop (D-11). The
`needs_per_table` filter was re-inserted into `function_downs` in
`down_body/2` (`lib/mix/tasks/threadline.gen.triggers.ex`) — the only change
made:

```diff
     function_downs =
-      Enum.map_join(first_run_specs, "\n\n", fn {t, _} ->
+      first_run_specs
+      |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)
+      |> Enum.map_join("\n\n", fn {t, _} ->
         first_run_drop_comment(t) <>
           "\n" <>
           execute_line(TriggerSQL.drop_function_if_unused(Naming.function_name(t)))
       end)
```

### Red — deterministic regression (`mix test test/threadline/capture/trigger_rerun_test.exs`)

```
  1) test rolling back a rerun chain full-chain rollback leaves no orphaned capture function (Threadline.Capture.TriggerRerunTest)
     test/threadline/capture/trigger_rerun_test.exs:217
     Assertion with == failed
     code:  assert Harness.orphan_capture_functions() -- baseline == []
     left:  ["threadline_capture_changes_test_trigger_rerun_chain"]
     right: []
     stacktrace:
       test/threadline/capture/trigger_rerun_test.exs:238: (test)

13 tests, 1 failure
```

### Red — property (`mix test test/threadline/capture/trigger_rerun_property_test.exs`)

```
Running ExUnit with seed: 554469, max_cases: 36

  1) property a random chain of 1-4 runs rolls back to zero new orphaned capture functions (Threadline.Capture.TriggerRerunPropertyTest)
     test/threadline/capture/trigger_rerun_property_test.exs:23
     Failed with generated values (after 0 successful runs):

         * Clause:    runs <- run_sequence()
           Generated: [:default, {:per_table, :store_changed_from}]

     Assertion with == failed
     code:  assert Harness.orphan_capture_functions() -- baseline == []
     left:  ["threadline_capture_changes_trp_5"]
     right: []

1 property, 1 failure
```

Reproduce command: `mix test --seed 554469 test/threadline/capture/trigger_rerun_property_test.exs`

Reran the cited command once (still mutated): identical failure, same shrunk
counterexample `[:default, {:per_table, :store_changed_from}]`, same
orphaned function name `threadline_capture_changes_trp_5` (seed
reproducibility confirmed for the flagged CAPT-02 probe-item assumption).

### Restore

```
git checkout -- lib/mix/tasks/threadline.gen.triggers.ex
git diff --quiet -- lib/
```
exited 0 (no residual mutation).

### Green (restored)

```
mix test test/threadline/capture/trigger_rerun_test.exs test/threadline/capture/trigger_rerun_property_test.exs
...............
Finished in 4.1 seconds (0.00s async, 4.1s sync)
1 property, 13 tests, 0 failures
```

## Property test cost

Date: 2026-09-30
Commit (restored tree): `02c5c92d`

Three consecutive runs of `mix test test/threadline/capture/trigger_rerun_property_test.exs`
alone, reported separately from the suite wall clock (D-18) as DB-backed
correctness debt landing before Phase 225's partitioning:

| Run | Finished in | Result |
|-----|-------------|--------|
| 1 | 5.1 seconds (0.00s async, 5.1s sync) | 1 property, 0 failures |
| 2 | 3.8 seconds (0.00s async, 3.8s sync) | 1 property, 0 failures |
| 3 | 4.1 seconds (0.00s async, 4.1s sync) | 1 property, 0 failures |

## Suite wall clock (SUITE-06)

Date: 2026-09-30
Head commit (phase head, before the plan-metadata commit): `4db4d3db`
Base commit (milestone base, per ROADMAP SC5/SUITE-01): `dd780e68`

Local `mix test` wall clock, head vs. base, each run with a prior `MIX_ENV=test
mix compile` (excluded from the timed window). Base was measured in a
`git worktree add --detach` checkout of `dd780e68` with its own
`mix deps.get` (root and `examples/threadline_phoenix`) and compile; the
worktree was removed with `git worktree remove --force` afterward
(`git worktree list` back to one entry).

| Run | Commit | Finished in | Counts | real (s) |
|-----|--------|-------------|--------|----------|
| head, run 1 | 4db4d3db | 282.5 s (59.0s async, 223.4s sync) | 10 properties, 2583 tests, 0 failures, 3 excluded | 284.68 |
| base, run 1 | dd780e68 | 231.0 s (44.7s async, 186.3s sync) | 9 properties, 2578 tests, 0 failures, 3 excluded | 232.63 |
| head, run 2 | 4db4d3db | 187.7 s (30.8s async, 156.9s sync) | 10 properties, 2583 tests, 0 failures, 3 excluded | 188.63 |
| base, run 2 | dd780e68 | 243.2 s (34.4s async, 208.8s sync) | 9 properties, 2578 tests, 0 failures, 3 excluded | 244.28 |

Run 1's head-vs-base gap (52.05 s real, 37.1 s of "Finished in" sync time)
exceeded the plan's 10%-plus-property-cost threshold (10% of base's 186.3 s
sync time is 18.6 s; the property's own solo cost is ~4-5 s per the table
above; threshold ~22.7 s), so both runs were repeated once per the plan's
step 3. Run 2 shows the opposite sign (head faster than base by 55.65 s
real) and an even larger swing. This machine runs other unrelated local
processes concurrently (observed via `ps aux` mid-run: other project test/
build processes competing for CPU), so the local wall clock is dominated by
machine-load noise rather than by the +5 tests / +1 property this phase
added. The `2578 -> 2583` test-count delta and `9 -> 10` property-count delta
are the only structural difference between head and base; per the isolated
measurement above, the added property test itself costs ~4-5 s solo. CI's
dedicated, single-tenant runners (below) are the reliable before/after
signal; the local figures are recorded for completeness per D-18 but should
not be read as a regression or an improvement on their own.

**CI, before** — run 36730596489 (CI, push, base commit `dd780e68`, the
v1.43 landing referenced by ROADMAP SC5):

| Job | Started | Completed | Duration | Conclusion |
|-----|---------|-----------|----------|------------|
| Build and test (min) | 14:38:10Z | 14:43:50Z | 340 s | success |
| Build and test (current) | 14:38:11Z | 14:46:07Z | 476 s | success |
| Build and test (latest) | 14:38:10Z | 14:43:31Z | 321 s | success |
| CI required | 14:46:10Z | 14:46:13Z | 3 s | success |

Whole-run span (earliest job start to `CI required` completion): 14:38:10Z
to 14:46:13Z = 483 s.

**CI, after** — pending a maintainer push grant (this plan's
`<executor_safety>` forbids pushing or dispatching CI). Once
`milestone/v1.44` (or its landing branch) is pushed and a `ci.yml` run
completes, cite it with:

```
gh run list --workflow ci.yml --branch milestone/v1.44 --limit 1
gh run view <run-id> --json jobs --jq '.jobs[] | [.name, .startedAt, .completedAt, .conclusion] | @tsv'
```

As of this measurement, `gh run list --workflow ci.yml --branch
milestone/v1.44 --limit 3` returns no runs (the branch has never been
pushed).

## Roadmap check (D-01)

`.planning/ROADMAP.md`'s Phase 224 `**Research**:` line already reads
`Resolved in discuss-phase (224-CONTEXT D-01)` (from commit `02c0dfbd`,
confirmed still present at the phase head). No edit needed.

## Phase gate

Date: 2026-09-30
Commit: `4db4d3db` (before this plan's docs/evidence commits)

`mix ci.all` — full chain (`verify.format`, `verify.credo`, `verify.deps_audit`,
`verify.repo_hygiene`, `compile --warnings-as-errors`, `verify.xref_cycles`,
`verify.compile_no_optional`, `verify.bench_compile`, `verify.test`,
`verify.threadline`, `verify.example`, dev-toolchain Dialyzer, the live
Dialyzer slice, and the browser lane
`verify.example_browser --project=desktop-chromium --project=mobile-chromium`
under `CI=true`) exited **0**.

`verify.test` summary line: `10 properties, 2583 tests, 0 failures, 3
excluded`. No `** (Mix)` or failure line anywhere in the full `ci.all`
output.

Browser lane (`verify.example_browser`) summary: `315 passed (10.7m)`, `3
flaky` (each passed on Playwright's automatic retry — the pre-existing
flakes already catalogued for this browser lane), `26 skipped` — matching
the project's documented CI=true baseline of ~318 passed (315 + 3
flaky-but-passed) / 0 failed / 26 skipped.

`bin/verify-repo-hygiene` (run separately after `ci.all`): `4268 tracked
text file(s) clean; 8 allowlist entries used, 0 inert`, exit 0.

`git worktree list` after cleanup: one entry (the main checkout).
