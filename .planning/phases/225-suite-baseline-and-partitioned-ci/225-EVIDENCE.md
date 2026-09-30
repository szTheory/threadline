# Phase 225: Suite Baseline and Partitioned CI - Evidence

## SUITE-03

Scope (D-15): `test/threadline/operator_surface/auth_test.exs`,
`export_auth_plug_test.exs`, and `theme_auth_plug_test.exs` now run `async: true`,
isolated by the emitting process through the new
`Threadline.TelemetryHelpers.attach_telemetry!/1` helper
(`test/support/telemetry_helpers.ex`), proven by
`test/threadline/telemetry_helpers_test.exs`.

### D-17: isolation mutation control (red/green)

`Threadline.TelemetryHelpers.handle_event/4`'s process-identity filter
(`self() == test_pid or test_pid in Process.get(:"$callers", [])`) was
temporarily replaced with an unconditional forward, and restored by hand
afterward (confirmed identical to the pre-mutation file with `diff`, since
the file was not yet committed at mutation time).

**Red** (filter removed, `mix test test/threadline/telemetry_helpers_test.exs`):

```
Running ExUnit with seed: 771065, max_cases: 36
Excluding tags: [pgbouncer_topology: true, live_dialyzer: true]

...

  1) test an event executed by a bare spawn process (no $callers) is NOT received (Threadline.TelemetryHelpersTest)
     test/threadline/telemetry_helpers_test.exs:25
     Unexpectedly received message {[:threadline, :test, :telemetry_helpers], #Reference<0.3752843321.1311244301.88883>, %{count: 1}, %{source: :spawn}} (which matched {@event, ^ref, _measurements, _metadata})
     code: refute_received {@event, ^ref, _measurements, _metadata}
     stacktrace:
       test/threadline/telemetry_helpers_test.exs:38: (test)


Finished in 0.01 seconds (0.01s async, 0.00s sync)
4 tests, 1 failure
```

**Green** (filter restored, same command):

```
Running ExUnit with seed: 470507, max_cases: 36
Excluding tags: [pgbouncer_topology: true, live_dialyzer: true]

....
Finished in 0.01 seconds (0.01s async, 0.00s sync)
4 tests, 0 failures
```

### D-18: 200-repeat proof, no new flake

```
mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/telemetry_helpers_test.exs --repeat-until-failure 200
```

Exit 0. 201 iterations total (the initial run plus 200 repeats), each reporting
`50 tests, 0 failures` with a fresh seed — no failure at any iteration.

### D-20: SUITE-03 local delta

Three plain `mix test` runs, timed with `/usr/bin/time -p`, taken after
`MIX_ENV=test mix compile --warnings-as-errors`, with nothing else on the
local Postgres (`pg_stat_activity` showed 0 non-idle connections before the
run). This is local, noisy timing — not the CI comparator (`225-BASELINE.md`
D-13).

| Run | Finished in | Async | Sync | Counts | real (s) |
|-----|-------------|-------|------|--------|----------|
| 1 | 128.4s | 13.4s | 115.0s | 2587 tests, 0 failures, 3 excluded | 129.03 |
| 2 | 133.0s | 13.3s | 119.7s | 2587 tests, 0 failures, 3 excluded | 133.77 |
| 3 | 164.6s | 15.5s | 149.1s | 2587 tests, 0 failures, 3 excluded | 165.25 |

Median by `Finished in` total (128.4 < 133.0 < 164.6): **run 2, 133.0s
(13.3s async, 119.7s sync), real 133.77s.**

`225-BASELINE.md`'s pre-change local median (run 3 there): **137.0s (16.9s
async, 120.1s sync), real 137.76s.**

Delta: `133.0 - 137.0 = -4.0s` (about -2.9%) on `Finished in`; `133.77 - 137.76
= -3.99s` on real. The SUITE-03 change (three files converted to
`async: true`) shows a small local improvement, well inside the ±55s local
swing 224-EVIDENCE.md and 225-BASELINE.md both record for this repo's shared,
noisy local Postgres — this delta is not a precise measurement of the
async conversion alone, only a directional check that nothing regressed.
Run 3's outlier (164.6s vs 128.4s/133.0s) reflects that same local noise
(other local processes / OS scheduling), not a suite change; the three async
files contribute well under a second each to the suite total either way.

The CI partitioning delta (SUITE-02) is a separate figure, produced by a
later plan in this phase.

## SUITE-02 local

### N lock and reason

N = 3, per `225-BASELINE.md` D-03: median local run T = 137.0s, slowest
module M = 28.8s (`Threadline.PlaywrightFailFastContractTest`), T / 3 =
45.7s >= M, so N = 3 is confirmed by measurement, not just the default.
`bin/ci-test-partitions`'s header cites `225-BASELINE.md` D-03 for the
same default.

### D-05: peak connections vs max_connections

`SHOW max_connections;` -> **100**. Sampled `SELECT count(*) FROM
pg_stat_activity WHERE datname LIKE 'threadline_test%'` once per second
across a full `mix verify.test_partitioned` run: **peak 7** connections
across all three partition databases. No `pool_size` change (stays 2,
`config/test.exs`).

### D-06: `_build` write check

```
touch /tmp/marker_partitions && mix verify.test_partitioned
find _build/test -newer /tmp/marker_partitions -type f
```

One file: `_build/test/lib/threadline/.mix/.mix_test_failures`. Confirmed
this is `mix test`'s own failure-tracking manifest (Elixir's
`Mix.Tasks.Test.manifest_opts/1`, `@manifest_file_name
".mix_test_failures"`), not written by a lone no-op `mix compile` (verified:
`touch marker && MIX_ENV=test mix compile` -> `find` on the same marker
prints nothing). Mix exposes no CLI flag to redirect
`:failures_manifest_path`, and making the file read-only before the
partitioned run crashes the suite (`ExUnit.RunnerStats.handle_cast/2`
raises `File.Error` when it cannot write it, taking the whole run down) --
strictly worse than the race it would prevent. This repo's aliases never
pass `--failed`, so the manifest's content is never read back; the race is
three processes independently overwriting the same small file with their
own "no failures" (or failure) summary, a last-write-wins race with no
partial-write risk (each write is a single `File.write!` of a few hundred
bytes) and no consumer. Accepted as a documented, understood exception to
the "prints nothing" check rather than disabling ExUnit's failure tracking
or forcing a crash.

### Shared-resource audit

| Resource | Files | Verdict |
|---|---|---|
| `CREATE ROLE` | `test/threadline/health/trigger_findings_non_owner_test.exs` (only hit) | Cluster-wide; role name now folds `MIX_TEST_PARTITION` alongside the existing `System.unique_integer/1` (this commit) |
| `CREATE DATABASE` / `DROP DATABASE` / `ALTER SYSTEM` / `pg_terminate_backend` / `CREATE TABLESPACE` / `LISTEN` / `NOTIFY` | none found (`grep -rnE` over `test/`) | No other cluster-wide DDL/signal in the suite |
| nested `System.cmd("mix"...)` | `test/threadline/capture/notice_guard_canary_test.exs` | Inherits the parent env (`System.get_env()` merged into `cmd_env/1`), so the nested `mix test` runs against its own partition's `MIX_TEST_PARTITION`-suffixed database; confirmed passing under the partitioned run |
| fixed `server: true` / literal 4-digit `port:` | none found (`grep -rnE` over `test/` and `config/test.exs`) | No fixed network port shared across concurrent partitions |
| `database:` literal | only a doc comment in `trigger_rerun_test.exs`, no config hit besides `config/test.exs` itself | Single config site, already partition-aware (D-04) |
| `File.write!/mkdir_p!/rm_rf!/cp_r!` outside `tmp_dir` | reviewed every hit (`grep -rnE` over `test/`) | Every write targets a per-test `System.tmp_dir!()`-based path with a `System.unique_integer/1` or `mktemp`-style suffix, or a path under `@tag :tmp_dir` (ExUnit's own per-test scoping); none is a fixed shared path. This is the same counter class as the `CREATE ROLE` fix, but filesystem paths are not cluster-wide like Postgres roles -- a same-integer coincidence across two concurrent partitions would only collide if both partitions also picked the exact same tmp_dir/path AND ran concurrently, which is the pre-existing `async: true` collision class this suite already accepts, not a new partition-specific hazard |

### Self-test output (all-pass)

```
$ bin/ci-test-partitions --self-test
ci-test-partitions self-test: ok (all pass, partition 2 fails, partitions 1+3 fail, partition-1-empty+2-fails, partition-1-empty+rest-pass, killed partition, summary order, invalid N)
```

Exit 0.

### D-10 runtime mutation: bare-wait red, restored green

The per-PID wait loop (`for i in $(seq 1 "$n"); do wait "${pids[i]}" ||
fail=1; done`) was temporarily replaced with a bare `wait; fail=0`, and
`bin/ci-test-partitions --self-test` was re-run:

```
$ bin/ci-test-partitions --self-test
ci-test-partitions: self-test: partition-2-fails case must exit non-zero
```

Exit 2 (red, as expected -- the bare-wait bug class returns 0 regardless of
a failing partition). The mutation was then reverted byte-for-byte (`cp` from
a pre-mutation copy) and `bash -n bin/ci-test-partitions` plus `--self-test`
both confirmed green again:

```
$ bash -n bin/ci-test-partitions && bin/ci-test-partitions --self-test
ci-test-partitions self-test: ok (all pass, partition 2 fails, partitions 1+3 fail, partition-1-empty+2-fails, partition-1-empty+rest-pass, killed partition, summary order, invalid N)
```

Exit 0.

### Local partitioned run (local, not the CI comparator)

```
$ mix verify.test_partitioned
ci-test-partitions: compiling once, serially
ci-test-partitions: partition report (N=3)

| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 31 | 1045 tests, 0 failures |
| 2 | 0 | 88 | 766 tests, 0 failures |
| 3 | 0 | 55 | 777 tests, 0 failures |
| total | - | 89 | - |
```

Total wall clock 89s vs the `225-BASELINE.md` unpartitioned local median
137.0s -- a local, noisy directional check only (not the CI comparator,
which is a later plan's job).

### D-07: partition-1-migrated positive run, unmigrated-partition negative run

```
$ MIX_ENV=test MIX_TEST_PARTITION=1 mix verify.threadline
...
TABLE                          STATUS
-------------------------------------
threadline_ci_coverage_canary  covered
summary: 1/1 expected tables covered (0 violated)
...
findings: 0 gated error(s), 0 not-gated error(s), 1 warning(s)
```

Exit 0.

```
$ MIX_ENV=test MIX_TEST_PARTITION=7 mix verify.threadline
...
** (DBConnection.ConnectionError) [Elixir.Threadline.Test.Repo] connection not available and request was dropped from queue after 5994ms.
```

Exit 1 (`threadline_test7` was never created or migrated by any partition
run, so the step fails closed rather than reporting a vacuous zero-coverage
pass).

### Flake Detection re-derivation (D-11)

Source run: `gh run list --workflow flake-detection.yml --limit 10` ->
run **36364688861** (2026-09-28, `success`, 2583 tests), the newest
completed run whose repeat step ran every iteration to the end (the next
newer run, 36391367194, `failed` before completing its repeats).

`gh run view 36364688861 --log` `Finished in` lines (13 suite runs = 1 cold
+ 12 repeats, matching the committed repeat count):

```
Finished in 255.9 seconds (33.3s async, 222.5s sync)   <- cold first run
Finished in 201.2 seconds (21.3s async, 179.8s sync)
Finished in 201.2 seconds (20.8s async, 180.3s sync)
Finished in 199.4 seconds (20.6s async, 178.7s sync)
Finished in 198.9 seconds (20.7s async, 178.2s sync)
Finished in 199.4 seconds (20.7s async, 178.6s sync)
Finished in 201.1 seconds (20.9s async, 180.2s sync)
Finished in 200.3 seconds (20.9s async, 179.4s sync)
Finished in 198.3 seconds (20.9s async, 177.4s sync)
Finished in 198.6 seconds (20.7s async, 177.9s sync)
Finished in 198.2 seconds (20.6s async, 177.5s sync)
Finished in 197.4 seconds (20.6s async, 176.8s sync)
Finished in 198.5 seconds (20.8s async, 177.7s sync)
```

Raw figures: cold 255.9s, repeats 197.4-201.2s (slowest 201.2s). Added test
cost: 224-EVIDENCE.md's "Property test cost" measured the one property test
added since that run's head commit at up to 5.1s
(`trigger_rerun_property_test.exs`, three runs 5.1s/3.8s/4.1s, slowest
cited); SUITE-03's telemetry async conversion (this phase) is credited 0s
(it can only shorten an iteration, never lengthen one). Each raw figure plus
5.1s, rounded up to the next whole second:

- cold: 255.9 + 5.1 = 261.0 -> **261s** (`@cold_first_run_ceiling_s`)
- repeat: 201.2 + 5.1 = 206.3 -> **207s** (`@repeat_ceiling_s`)

Sizing arithmetic at the committed 12 repeats: needed = 261 + 12 x 207 =
2,745s (about 46 min); usable = 3300 x (100 - 10) / 100 = 2,970s. 2,745 <=
2,970, so **12 repeats still fits with headroom to spare** (about 17% of
the 55-minute budget free) -- the repeat count is unchanged; only the
cited run, raw figures and ceilings moved. `.github/workflows/flake-detection.yml`'s
budget comment and `test/threadline/flake_classifier_contract_test.exs`
Test 6 (`@cold_first_run_ceiling_s`, `@repeat_ceiling_s`, and the
doc-consistency `run 36364688861` assertion) were updated to match, in the
D-12 gate commit.

### Three phase-head plain `mix test` runs and median

Timed with `/usr/bin/time -p`, after `MIX_ENV=test mix compile`, with
nothing else on the local Postgres:

| Run | Finished in | Async | Sync | Counts | real (s) |
|-----|-------------|-------|------|--------|----------|
| 1 | 136.5s | 14.4s | 122.1s | 10 properties, 2588 tests, 0 failures, 3 excluded | 137.30 |
| 2 | 137.1s | 16.3s | 120.8s | 10 properties, 2588 tests, 0 failures, 3 excluded | 137.80 |
| 3 | 133.3s | 14.8s | 118.4s | 10 properties, 2588 tests, 0 failures, 3 excluded | 134.01 |

Median by `Finished in` total (133.3 < 136.5 < 137.1): **run 1, 136.5s
(14.4s async, 122.1s sync), real 137.30s.** Local, noisy timing on a
shared machine -- not the CI comparator.

### `mix ci.all` and `mix verify.test_partitioned` exit status

`mix ci.all` exit 0. `verify.test`'s summary line inside that run: `10
properties, 2588 tests, 0 failures, 3 excluded`. Browser lane: `317
passed (1 flaky, retried and passed), 26 skipped, 0 failed`.
`mix verify.test_partitioned` exit 0 (own section above).
`bin/ci-test-partitions --self-test` exit 0 (own section above).

### Gate commit

`2dd7a963eeacd56efcc8cbe2ccbd792ad6309393` -- `ci: run the test suite in
partitions, one database each` -- the ten D-12 files: `bin/ci-test-partitions`
(mode 100755), `.github/workflows/ci.yml`, `mix.exs`, `config/test.exs`,
`test/threadline/ci_topology_contract_test.exs`,
`test/threadline/ci_workflow_parity_contract_test.exs`,
`.github/workflows/flake-detection.yml`,
`test/threadline/flake_classifier_contract_test.exs`,
`test/threadline/health/trigger_findings_non_owner_test.exs`,
`CONTRIBUTING.md`. No `bin/classify-flake-run` change (the repeat count did
not change).
