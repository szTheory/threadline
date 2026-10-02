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

(filled by plan 04)
