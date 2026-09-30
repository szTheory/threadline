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
