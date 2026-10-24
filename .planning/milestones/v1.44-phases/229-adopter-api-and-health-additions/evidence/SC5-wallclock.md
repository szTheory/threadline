# Phase 229 SC-5 wall clock (D-28)

Commit measured: `c99742d8` (`git rev-parse --short HEAD`), with `git status --porcelain -- lib test` printing nothing before any lib/ or test/ file in this phase was touched.

## Before (base, local, noisy)

Three sequential `mix test` runs, no other change to `lib` or `test` since `c99742d8`:

```text
run  Finished-in(s)                                   Counts
1    151.4 (16.6s async, 134.8s sync)                 31 properties, 2703 tests, 0 failures, 3 excluded
2    186.2 (20.8s async, 165.4s sync)                 31 properties, 2703 tests, 0 failures, 3 excluded
3    227.2 (23.8s async, 203.4s sync)                 31 properties, 2703 tests, 0 failures, 3 excluded

median Finished-in: 186.2s
```

All three runs were green (0 failures); none was re-run.

One `mix verify.test_partitioned` run (local partitioned-CI proxy, 4 partitions):

```text
| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 57 | 677 tests, 0 failures |
| 2 | 0 | 73 | 621 tests, 0 failures |
| 3 | 0 | 68 | 640 tests, 0 failures |
| 4 | 0 | 55 | 765 tests, 0 failures |
| total | - | 74 | - |
```

### Phase-225 partitioned baseline (comparator)

Phase 225's baseline (`.planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md`,
measured at the milestone base `dd780e68`, CI run 36730596489 — the "Run tests" step
per lane, the only comparator formula later 225 plans graded against):

```text
| Lane    | Job seconds | Proxy (min) | Run tests seconds | Build cache |
|---------|-------------|-------------|--------------------|-------------|
| min     | 340         | 6           | 288                | hit         |
| current | 476         | 8           | 291                | hit         |
| latest  | 321         | 6           | 267                | hit         |
| total   |             | 20          |                    |             |
```

225-BASELINE.md's local (not-CI-comparator) whole-suite `mix test` figures at the same
`dd780e68` base, for additional local context: three runs of 135.1s / 151.8s / 137.0s,
median 137.0s (10 properties, 2583 tests, 0 failures, 3 excluded) — fewer properties and
tests than this phase's head because 226-228 added property files and tests since
`dd780e68`.

This phase's local `mix test` median of 186.2s above is not a clean apples-to-apples
comparison against either the phase-225 CI proxy (CI step time on dedicated runners,
not local wall clock) or the phase-225 local figure (measured at an earlier milestone
base with fewer tests); it is recorded here per D-28 as the phase's own before/after
local pair, with the phase-225 figures cited for comparison per the plan's instruction.

## After

Commit measured: `493fa333` (`git rev-parse --short HEAD`), with
`git status --porcelain -- lib test` printing nothing before this
measurement — all four of this phase's plans (`:limit`,
`legacy_key_findings/1`, `--strict`, `--all-schemas`), plus two small
fixes discovered while closing the phase gate (an environment-dependent
test precondition, and a Dialyzer `:unmatched_returns` finding in plan
02's code — see Deviations in the SUMMARY), are committed.

Local machine load note (honest, not cherry-picked): this is a local,
noisy measurement on a shared development machine; other unrelated
processes may have been running concurrently across these three runs, the
same caveat the before section and phase 228's evidence file both record.

Three sequential `mix test` runs, no other change to `lib` or `test` since
`493fa333`:

```text
run  Finished-in(s)                                   Counts
1    308.3 (48.6s async, 259.6s sync)                 32 properties, 2767 tests, 0 failures, 3 excluded
2    171.9 (35.0s async, 136.9s sync)                 32 properties, 2767 tests, 0 failures, 3 excluded
3    157.1 (15.2s async, 141.9s sync)                 32 properties, 2767 tests, 0 failures, 3 excluded

median Finished-in: 171.9s
```

All three runs were green (0 failures); none was re-run. The wide spread
(157s-308s) on an otherwise-unchanged tree across three consecutive runs
on the same machine illustrates the load note above more than it reflects
anything about this phase's code.

One `mix verify.test_partitioned` run (local partitioned-CI proxy, 4
partitions):

```text
| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 56 | 596 tests, 0 failures |
| 2 | 0 | 89 | 824 tests, 0 failures |
| 3 | 0 | 74 | 601 tests, 0 failures |
| 4 | 0 | 63 | 746 tests, 0 failures |
| total | - | 90 | - |
```

### This plan's own test cost

`mix test --slowest-modules 40` over the new and extended test files
(`test/threadline/operator_surface/coverage_mix_test.exs`,
`test/threadline/operator_surface/coverage_doc_contract_test.exs`,
`test/threadline/health_test.exs` — all extended, none newly created this
phase):

```text
Threadline.OperatorSurface.CoverageMixTest        1617.2ms
Threadline.HealthTest                              205.9ms
Threadline.OperatorSurface.CoverageDocContractTest  13.8ms

109 tests, 0 failures, finished in 1.8s total
```

### Comparison

- **Before median (`c99742d8`, plan 01 start) → after median (`493fa333`,
  plan 04 end):** 186.2s → 171.9s whole-suite `mix test` — effectively flat
  (-7.7%) despite 65 more tests (2703 → 2767 tests, 31 → 32 properties)
  from this phase's own new fixtures (a 33-extra-schema `--all-schemas`
  determinism fixture, a per-table `legacy_key_findings/1` probe, and the
  `--strict` 12-cell matrix). Given the 157s-308s single-machine spread
  recorded above, this comparison is dominated by machine-load noise, not
  a real per-run cost signal in either direction; the per-file
  `--slowest-modules` figure above is the more reliable per-test cost
  measure (109 tests across the three files finish in 1.8s).
- **`mix verify.test_partitioned` total:** 74s (before) → 90s (after). The
  before run's per-partition counts were lower (677/621/640/765 = 2703
  tests) than after (596/824/601/746 = 2767 tests); the increase tracks
  the added test count, with partition balance staying close (56-89s
  across 4 partitions, vs 55-73s before), consistent with phase 225's
  weighted-partition design still holding.
- **Phase-225 partitioned CI baseline** (`225-BASELINE.md`, CI run
  36730596489, "Run tests" step): min 288s / current 291s / latest 267s
  per lane — a CI-runner "Run tests" step time, not comparable one-to-one
  with either this phase's local `mix test` or local
  `verify.test_partitioned` figures (different host, different
  parallelism, dedicated runner vs a shared local machine); cited here
  per the plan's instruction as the standing cross-phase reference point,
  same caveat the before section already recorded.

`mix ci.all` final status: green at `493fa333` (see the SUMMARY for the
full run log; Dialyzer's one `:unmatched_returns` finding was fixed in
the same commit, confirmed not a PLT-cache-miss false positive by
rebuilding the PLT first and re-running before making any code change).
