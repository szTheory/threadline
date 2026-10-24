# Phase 225: Suite Baseline and Partitioned CI - Evidence

## SUITE-03

Scope (D-15): `test/threadline/operator_surface/auth_test.exs`,
`export_auth_plug_test.exs`, and `theme_auth_plug_test.exs` now run `async: true`,
isolated by the emitting process through the new
`Threadline.TelemetryHelpers.attach_telemetry!/1` helper (`mix test test/threadline/telemetry_helpers_test.exs`)
(`test/support/telemetry_helpers.ex`), proven by
`test/threadline/telemetry_helpers_test.exs`.

### D-17: isolation mutation control (red/green)

`Threadline.TelemetryHelpers.handle_event/4`'s process-identity filter (`mix test test/threadline/telemetry_helpers_test.exs`)
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

Exit 0. 201 iterations total (the initial run plus 200 repeats), each reporting (`mix test --repeat-until-failure 200`)
`50 tests, 0 failures` with a fresh seed — no failure at any iteration. (`mix test --repeat-until-failure 200`)

### D-20: SUITE-03 local delta

Three plain `mix test` runs, timed with `/usr/bin/time -p`, taken after
`MIX_ENV=test mix compile --warnings-as-errors`, with nothing else on the
local Postgres (`pg_stat_activity` showed 0 non-idle connections before the (`mix test`)
run). This is local, noisy timing — not the CI comparator (`225-BASELINE.md` (`mix test`)
D-13).

| Run | Finished in | Async | Sync | Counts | real (s) |
|-----|-------------|-------|------|--------|----------|
| 1 | 128.4s | 13.4s | 115.0s | 2587 tests, 0 failures, 3 excluded | 129.03 `mix test` |
| 2 | 133.0s | 13.3s | 119.7s | 2587 tests, 0 failures, 3 excluded | 133.77 `mix test` |
| 3 | 164.6s | 15.5s | 149.1s | 2587 tests, 0 failures, 3 excluded | 165.25 `mix test` |

Median by `Finished in` total (128.4 < 133.0 < 164.6): **run 2, 133.0s (`mix test`)
(13.3s async, 119.7s sync), real 133.77s.** (`mix test`)

`225-BASELINE.md`'s pre-change local median (run 3 there): **137.0s (16.9s (`mix test`)
async, 120.1s sync), real 137.76s.** (`mix test`)

Delta: `133.0 - 137.0 = -4.0s` (about -2.9%) on `Finished in`; `133.77 - 137.76 (`mix test`)
= -3.99s` on real. The SUITE-03 change (three files converted to (`mix test`)
`async: true`) shows a small local improvement, well inside the ±55s local (`mix test`)
swing 224-EVIDENCE.md and 225-BASELINE.md both record for this repo's shared, (`mix test`)
noisy local Postgres — this delta is not a precise measurement of the
async conversion alone, only a directional check that nothing regressed.
Run 3's outlier (164.6s vs 128.4s/133.0s) reflects that same local noise (`mix test`)
(other local processes / OS scheduling), not a suite change; the three async
files contribute well under a second each to the suite total either way.

The CI partitioning delta (SUITE-02) is a separate figure, produced by a
later plan in this phase.

## SUITE-02 local

### N lock and reason

N = 3, per `225-BASELINE.md` D-03: median local run T = 137.0s, slowest (`mix test --slowest 50 --slowest-modules 10`)
module M = 28.8s (`Threadline.PlaywrightFailFastContractTest`), T / 3 = (`mix test --slowest 50 --slowest-modules 10`)
45.7s >= M, so N = 3 is confirmed by measurement, not just the default. (`mix test --slowest 50 --slowest-modules 10`)
`bin/ci-test-partitions`'s header cites `225-BASELINE.md` D-03 for the (`mix verify.test_partitioned`)
same default.

### D-05: peak connections vs max_connections

`SHOW max_connections;` -> **100**. Sampled `SELECT count(*) FROM (`psql -c "SHOW max_connections;"`)
pg_stat_activity WHERE datname LIKE 'threadline_test%'` once per second
across a full `mix verify.test_partitioned` run: **peak 7** connections
across all three partition databases. No `pool_size` change (stays 2, (`psql -c "SELECT count(*) FROM pg_stat_activity WHERE datname LIKE 'threadline_test%'"`)
`config/test.exs`).

### D-06: `_build` write check

```
touch /tmp/marker_partitions && mix verify.test_partitioned
find _build/test -newer /tmp/marker_partitions -type f
```

One file: `_build/test/lib/threadline/.mix/.mix_test_failures`. Confirmed
this is `mix test`'s own failure-tracking manifest (Elixir's
`Mix.Tasks.Test.manifest_opts/1`, `@manifest_file_name (`mix verify.test_partitioned`)
".mix_test_failures"`), not written by a lone no-op `mix compile` (verified:
`touch marker && MIX_ENV=test mix compile` -> `find` on the same marker
prints nothing). Mix exposes no CLI flag to redirect
`:failures_manifest_path`, and making the file read-only before the
partitioned run crashes the suite (`ExUnit.RunnerStats.handle_cast/2` (`mix verify.test_partitioned`)
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
| `CREATE ROLE` | `test/threadline/health/trigger_findings_non_owner_test.exs` (only hit) | Cluster-wide; role name now folds `MIX_TEST_PARTITION` alongside the existing `System.unique_integer/1` (this commit) `mix verify.test_partitioned` |
| `CREATE DATABASE` / `DROP DATABASE` / `ALTER SYSTEM` / `pg_terminate_backend` / `CREATE TABLESPACE` / `LISTEN` / `NOTIFY` | none found (`grep -rnE` over `test/`) | No other cluster-wide DDL/signal in the suite |
| nested `System.cmd("mix"...)` | `test/threadline/capture/notice_guard_canary_test.exs` | Inherits the parent env (`System.get_env()` merged into `cmd_env/1`), so the nested `mix test` runs against its own partition's `MIX_TEST_PARTITION`-suffixed database; confirmed passing under the partitioned run |
| fixed `server: true` / literal 4-digit `port:` | none found (`grep -rnE` over `test/` and `config/test.exs`) | No fixed network port shared across concurrent partitions `mix verify.test_partitioned` |
| `database:` literal | only a doc comment in `trigger_rerun_test.exs`, no config hit besides `config/test.exs` itself | Single config site, already partition-aware (D-04) |
| `File.write!/mkdir_p!/rm_rf!/cp_r!` outside `tmp_dir` | reviewed every hit (`grep -rnE` over `test/`) | Every write targets a per-test `System.tmp_dir!()`-based path with a `System.unique_integer/1` or `mktemp`-style suffix, or a path under `@tag :tmp_dir` (ExUnit's own per-test scoping); none is a fixed shared path. This is the same counter class as the `CREATE ROLE` fix, but filesystem paths are not cluster-wide like Postgres roles -- a same-integer coincidence across two concurrent partitions would only collide if both partitions also picked the exact same tmp_dir/path AND ran concurrently, which is the pre-existing `async: true` collision class this suite already accepts, not a new partition-specific hazard `mix verify.test_partitioned` |

### Self-test output (all-pass)

```
$ bin/ci-test-partitions --self-test
ci-test-partitions self-test: ok (all pass, partition 2 fails, partitions 1+3 fail, partition-1-empty+2-fails, partition-1-empty+rest-pass, killed partition, summary order, invalid N)
```

Exit 0. (`bash bin/ci-test-partitions --self-test`)

### D-10 runtime mutation: bare-wait red, restored green

The per-PID wait loop (`for i in $(seq 1 "$n"); do wait "${pids[i]}" || (`bash bin/ci-test-partitions --self-test`)
fail=1; done`) was temporarily replaced with a bare `wait; fail=0`, and (`bash bin/ci-test-partitions --self-test`)
`bin/ci-test-partitions --self-test` was re-run:

```
$ bin/ci-test-partitions --self-test
ci-test-partitions: self-test: partition-2-fails case must exit non-zero
```

Exit 2 (red, as expected -- the bare-wait bug class returns 0 regardless of (`bash bin/ci-test-partitions --self-test`)
a failing partition). The mutation was then reverted byte-for-byte (`cp` from
a pre-mutation copy) and `bash -n bin/ci-test-partitions` plus `--self-test`
both confirmed green again:

```
$ bash -n bin/ci-test-partitions && bin/ci-test-partitions --self-test
ci-test-partitions self-test: ok (all pass, partition 2 fails, partitions 1+3 fail, partition-1-empty+2-fails, partition-1-empty+rest-pass, killed partition, summary order, invalid N)
```

Exit 0. (`bash bin/ci-test-partitions --self-test`)

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

Total wall clock 89s vs the `225-BASELINE.md` unpartitioned local median (`mix verify.test_partitioned`)
137.0s -- a local, noisy directional check only (not the CI comparator, (`mix verify.test_partitioned`)
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

Exit 0. (`MIX_ENV=test MIX_TEST_PARTITION=1 mix verify.threadline`)

```
$ MIX_ENV=test MIX_TEST_PARTITION=7 mix verify.threadline
...
** (DBConnection.ConnectionError) [Elixir.Threadline.Test.Repo] connection not available and request was dropped from queue after 5994ms.
```

Exit 1 (`threadline_test7` was never created or migrated by any partition (`MIX_ENV=test MIX_TEST_PARTITION=7 mix verify.threadline`)
run, so the step fails closed rather than reporting a vacuous zero-coverage
pass).

### Flake Detection re-derivation (D-11)

Source run: `gh run list --workflow flake-detection.yml --limit 10` ->
run 36364688861 (2026-09-28, `success`, 2583 tests), the newest
completed run whose repeat step ran every iteration to the end (the next
newer run 36391367194, `failed` before completing its repeats).

`gh run view 36364688861 --log` `Finished in` lines (13 suite runs = 1 cold
+ 12 repeats, matching the committed repeat count): (`gh run view 36364688861 --log`)

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

Raw figures: cold 255.9s, repeats 197.4-201.2s (slowest 201.2s). Added test (`gh run view 36364688861 --log`)
cost: 224-EVIDENCE.md's "Property test cost" measured the one property test (`gh run view 36364688861 --log`)
added since that run's head commit at up to 5.1s (`gh run view 36364688861 --log`)
(`trigger_rerun_property_test.exs`, three runs 5.1s/3.8s/4.1s, slowest (`gh run view 36364688861 --log`)
cited); SUITE-03's telemetry async conversion (this phase) is credited 0s (`gh run view 36364688861 --log`)
(it can only shorten an iteration, never lengthen one). Each raw figure plus
5.1s, rounded up to the next whole second: (`gh run view 36364688861 --log`)

- cold: 255.9 + 5.1 = 261.0 -> **261s** (`@cold_first_run_ceiling_s`) (`gh run view 36364688861 --log`)
- repeat: 201.2 + 5.1 = 206.3 -> **207s** (`@repeat_ceiling_s`) (`gh run view 36364688861 --log`)

Sizing arithmetic at the committed 12 repeats: needed = 261 + 12 x 207 = (`gh run view 36364688861 --log`)
2,745s (about 46 min); usable = 3300 x (100 - 10) / 100 = 2,970s. 2,745 <= (`gh run view 36364688861 --log`)
2,970, so **12 repeats still fits with headroom to spare** (about 17% of (`gh run view 36364688861 --log`)
the 55-minute budget free) -- the repeat count is unchanged; only the (`gh run view 36364688861 --log`)
cited run, raw figures and ceilings moved. `.github/workflows/flake-detection.yml`'s
budget comment and `test/threadline/flake_classifier_contract_test.exs`
Test 6 (`@cold_first_run_ceiling_s`, `@repeat_ceiling_s`, and the (`mix test test/threadline/flake_classifier_contract_test.exs`)
doc-consistency `run 36364688861` assertion) were updated to match, in the
D-12 gate commit.

### Three phase-head plain `mix test` runs and median

Timed with `/usr/bin/time -p`, after `MIX_ENV=test mix compile`, with
nothing else on the local Postgres:

| Run | Finished in | Async | Sync | Counts | real (s) |
|-----|-------------|-------|------|--------|----------|
| 1 | 136.5s | 14.4s | 122.1s | 10 properties, 2588 tests, 0 failures, 3 excluded | 137.30 `mix test` |
| 2 | 137.1s | 16.3s | 120.8s | 10 properties, 2588 tests, 0 failures, 3 excluded | 137.80 `mix test` |
| 3 | 133.3s | 14.8s | 118.4s | 10 properties, 2588 tests, 0 failures, 3 excluded | 134.01 `mix test` |

Median by `Finished in` total (133.3 < 136.5 < 137.1): **run 1, 136.5s (`mix test`)
(14.4s async, 122.1s sync), real 137.30s.** Local, noisy timing on a (`mix test`)
shared machine -- not the CI comparator.

### `mix ci.all` and `mix verify.test_partitioned` exit status

`mix ci.all` exit 0. `verify.test`'s summary line inside that run: `10
properties, 2588 tests, 0 failures, 3 excluded`. Browser lane: `317 (`mix ci.all`)
passed (1 flaky, retried and passed), 26 skipped, 0 failed`. (`mix ci.all`)
`mix verify.test_partitioned` exit 0 (own section above).
`bash bin/ci-test-partitions --self-test` exit 0 (own section above).

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

## SUITE-02 rebalance

### Why

CI run 36792875477 (PR #71) measured `Run tests` at 225/218/224s (min/current/latest)
against the run 36730596489 baseline of 288/291/267s, a drop of only about 22-25%. Its
current-lane partition report showed 67/217/119s per partition (run 36792875477): Mix's
`--partitions` assigns files round-robin over the sorted file list, so the heaviest sync
modules landed together in one partition (run 36792875477). `bin/ci-test-partitions` now
assigns files itself, greedy longest-first by measured weight (the amendment under D-03 in the phase context),
with the partition count unchanged (`bash bin/ci-test-partitions -h`).

### Weights source

`test/partition_weights.txt` was generated by `bin/ci-test-partitions --write-weights`, which
runs `mix test --slowest-modules 1000` on the unpartitioned local database and sums the
per-module milliseconds per file. That run (`mix test --slowest-modules 1000`): 2588 tests,
0 failures, 3 excluded (`mix test --slowest-modules 1000`), finished in 170.4s (47.8s async,
122.5s sync) (`mix test --slowest-modules 1000`); 223 of 224 test files received a weight (`mix test --slowest-modules 1000` reports no module time for the other,
which takes the median).

### Local before and after (local, noisy, not the CI comparator)

"Before" is the pre-change script, recovered and run unchanged with
`git show HEAD:bin/ci-test-partitions > tmp/ci-test-partitions-roundrobin` followed by
`bash tmp/ci-test-partitions-roundrobin` (HEAD = a0d8cfb9). "After" is
`mix verify.test_partitioned` on the new script. The two were run interleaved (round-robin,
weighted, round-robin, weighted) on a loaded shared machine (load average 13-17 per `bash -c uptime`),
so the pair-wise comparison is the meaningful figure, not the absolute seconds.

Round-robin pair 1 (`bash tmp/ci-test-partitions-roundrobin`):

```
| 1 | 0 | 36 | 1045 tests, 0 failures |
| 2 | 0 | 103 | 766 tests, 0 failures |
| 3 | 0 | 63 | 777 tests, 0 failures |
| total | - | 104 | - |
```

Weighted pair 1 (`mix verify.test_partitioned`):

```
ci-test-partitions: 224 test files assigned to 3 partitions by measured weight (test/partition_weights.txt)
| 1 | 0 | 65 | 1170 tests, 0 failures |
| 2 | 0 | 74 | 696 tests, 0 failures |
| 3 | 0 | 77 | 722 tests, 0 failures |
| total | - | 78 | - |
```

Round-robin pair 2 (`bash tmp/ci-test-partitions-roundrobin`):

```
| 1 | 0 | 35 | 1045 tests, 0 failures |
| 2 | 0 | 95 | 766 tests, 0 failures |
| 3 | 0 | 61 | 777 tests, 0 failures |
| total | - | 96 | - |
```

Weighted pair 2 (`mix verify.test_partitioned`):

```
| 1 | 0 | 65 | 1170 tests, 0 failures |
| 2 | 0 | 71 | 696 tests, 0 failures |
| 3 | 0 | 73 | 722 tests, 0 failures |
| total | - | 73 | - |
```

Slowest partition: 103s -> 77s and 95s -> 73s, about 24-25% less (`mix verify.test_partitioned`
vs `bash tmp/ci-test-partitions-roundrobin`). The weighted partitions finish within 12s of each
other (`mix verify.test_partitioned`) where round-robin spread them over 60-67s
(`bash tmp/ci-test-partitions-roundrobin`). Every run reported 2588 tests in total, 0 failures
(`mix verify.test_partitioned`, `bash tmp/ci-test-partitions-roundrobin`).

The local slowest partition stays well above the simulation's roughly 53s (`python3 225-partition-sim.py`
over a `mix test --slowest-modules 400` run) because the
three partitions now run concurrently for the whole step: summed partition seconds rose from
202-191s to 216-209s (`mix verify.test_partitioned` vs `bash tmp/ci-test-partitions-roundrobin`)
as they contend for the same CPU and Postgres. The CI "after" figure, on a runner with a
dedicated Postgres container, is the comparator for the SUITE-02 bar (`gh run view` on a later
push), not these local seconds.

### Self-test

```
$ bin/ci-test-partitions --self-test
ci-test-partitions self-test: ok (all pass, partition 2 fails, partitions 1+3 fail, partition-1-empty+2-fails, partition-1-empty+rest-pass, killed partition, summary order, invalid N, every file exactly once, unweighted file runs, stale weight ignored, deterministic assignment, heaviest files spread, zero-file partition, exactly-once check rejects bad assignments, write-weights)
```

Exit 0 (`bash bin/ci-test-partitions --self-test`). The self-test runs a copy of the script
inside a throwaway project with seven test files, three heavy, one async, one unweighted and a
stale weight entry (`bash bin/ci-test-partitions --self-test`).

## CI after

### Maintainer grant (D-14c)

The maintainer's grant, in their own words: "yes go for it u can push a PR and make it green
then squash merge that'sno big deal plz auto do it" and later "Okay automatically follow your
recommendations sounds good I read your plan and it sounds good go for it" / "i authoruize u".

### Deviation from the plan's dispatch shape

Task 1's `<action>` named three sequential `gh workflow run ci.yml --ref milestone/v1.44`
dispatches plus one Flake Detection dispatch. Under the grant above, the orchestrator instead
pushed `milestone/v1.44` and opened PR #71 (`gh pr view 71 --json headRefOid,state,url`)
(`gh pr view 71 --json headRefOid,state,url`), so `pull_request` events on that PR supplied most
of the post-change `ci.yml` runs (each fix a separate commit on the branch), plus one explicit
`gh workflow run ci.yml --ref milestone/v1.44` dispatch and one
`gh workflow run flake-detection.yml --ref milestone/v1.44` dispatch. This plan cites the runs
that actually happened rather than re-deriving a count of exactly three dispatches; every run of
the step is still cited, none is dropped, and no run was re-run or cancelled to get a better
figure (the executor safety rules).

Pushed sha: `git ls-remote origin milestone/v1.44` -> `6c4da13f801ec001849905fa7ac711388da12567`
(the branch tip after the Flake Detection resize commit). The two runs cited for the SUITE-02
verdict below share an earlier head, `9614535ccfd5f3c0761b493cd0099e0ca78a7d50` (the commit
right before that resize), because that is the newest head with two independent green runs
(one `pull_request`, one `workflow_dispatch`) at the time this plan executed; a further
`pull_request` run on `6c4da13f` was still `in_progress` (run 36815423208) and is not waited on
or cited, per the plan's instruction not to wait on it.

### Full PR #71 CI history on milestone/v1.44 (`gh run list --workflow ci.yml --branch milestone/v1.44 --limit 20`)

| Run | Head sha | Event | Conclusion | Note |
|---|---|---|---|---|
| run 36792875477 | e39b2c9b | pull_request | failure | Mix round-robin partitions unbalanced 67/217/119s |
| run 36798631372 | 171fd00a | pull_request | failure | fresh partition DB startup race |
| run 36799589565 | dcd15175 | pull_request | failure | stress router cold prod compile >60s |
| run 36800563728 | 13a95408 | pull_request | failure | checkout-sharing tests overlapped |
| 36801744615 | 822a8c37 | pull_request | failure | `mix hex.build --unpack` tmp dir in checkout |
| run 36802594485 | 9207c093 | pull_request | success | green but marginal |
| run 36803573797 | cdfea518 | pull_request | success | green, worse (doubled group weight) |
| run 36804809428 | 67d8191a | pull_request | success | green, cold-weights fix, N becomes 4 |
| run 36805584891 | b0beea8d | pull_request | failure | repo-hygiene self-test `printf\|grep -q` pipefail race |
| **run 36808706517** | **9614535c** | **pull_request** | **success** | **cited run 1 below** |
| **run 36810081717** | **9614535c** | **workflow_dispatch** | **success** | **cited run 2 below** |
| run 36815423208 | 6c4da13f | pull_request | in_progress | not cited, not waited on |

(`gh run list --workflow ci.yml --branch milestone/v1.44 --limit 20 --json databaseId,headSha,conclusion,event,createdAt,status`)

### Run 1: 36808706517 (`pull_request`, head `9614535c`)

```
python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36808706517 --cache-state
```

```
## run 36808706517

| Lane | Job seconds | Proxy (min) | Run tests seconds | Build cache |
|---|---|---|---|---|
| min | 239 | 4 | 180 | hit |
| current | 317 | 6 | 148 | hit |
| latest | 211 | 4 | 155 | hit |
| **total** | | **14** | |
```

#### `Prove the gate goes red (failing partition)` — all three lanes (`gh run view 36808706517 --log`)

```
Build and test (min)	Prove the gate goes red (failing partition)	2026-10-01T03:04:06.0054024Z ci-test-partitions self-test: ok (all pass, partition 2 fails, partitions 1+3 fail, partition-1-empty+2-fails, partition-1-empty+rest-pass, killed partition, summary order, invalid N, every file exactly once, unweighted file runs, stale weight ignored, deterministic assignment, heaviest files spread, zero-file partition, exactly-once check rejects bad assignments, write-weights, colocation group)
Build and test (latest)	Prove the gate goes red (failing partition)	2026-10-01T03:04:04.1466320Z ci-test-partitions self-test: ok (... same case list ...)
Build and test (current)	Prove the gate goes red (failing partition)	2026-10-01T03:04:01.3128642Z ci-test-partitions self-test: ok (... same case list ...)
```

Each ran as a distinct CI step (shown here with its own `##[group]Run bin/ci-test-partitions --self-test`
header in the full log) and each job completed successfully, so the step exited 0 on all three (`gh run view 36808706517 --log`)
lanes — the mutation control that catches the `wait` exit-code bug class (D-10) passed on every
lane of this run.

#### `Run tests` partition tables, ascending order, three lanes (`gh run view 36808706517 --log`)

```
Build and test (min) — ci-test-partitions: partition report (N=4)
| Partition | Exit | Seconds | Counts |
| 1 | 0 | 111 | 665 tests, 0 failures |
| 2 | 0 | 125 | 602 tests, 0 failures |
| 3 | 0 | 168 | 544 tests, 0 failures |
| 4 | 0 | 179 | 777 tests, 0 failures |
| total | - | 180 | - |

Build and test (current) — ci-test-partitions: partition report (N=4)
| Partition | Exit | Seconds | Counts |
| 1 | 0 | 102 | 665 tests, 0 failures |
| 2 | 0 | 101 | 602 tests, 0 failures |
| 3 | 0 | 141 | 544 tests, 0 failures |
| 4 | 0 | 147 | 777 tests, 0 failures |
| total | - | 148 | - |

Build and test (latest) — ci-test-partitions: partition report (N=4)
| Partition | Exit | Seconds | Counts |
| 1 | 0 | 99 | 665 tests, 0 failures |
| 2 | 0 | 119 | 600 tests, 0 failures |
| 3 | 0 | 142 | 543 tests, 0 failures |
| 4 | 0 | 154 | 777 tests, 0 failures |
| total | - | 155 | - |
```

Each lane's total matches the `Run tests seconds` column from `ci-job-timing.py` above
(180/148/155), confirming the script reads the same step the partition report itself times. (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36808706517`)

#### D-07: `Verify Threadline trigger coverage` on the current lane, against partition 1's database (`gh run view 36808706517 --log`)

```
Build and test (current)	Verify Threadline trigger coverage	2026-10-01T03:06:30.6262019Z threadline_ci_coverage_canary  covered
Build and test (current)	Verify Threadline trigger coverage	2026-10-01T03:06:30.6262847Z summary: 1/1 expected tables covered (0 violated)
```

The step runs `MIX_ENV=test MIX_TEST_PARTITION=1 mix verify.threadline` against the now
per-partition `threadline_test1` database (D-07's fix) and reports the canary table covered, not (`gh run view 36808706517 --log`)
an empty report — the step that depends on the base DB keeps working once tests run only on
suffixed partition DBs.

### Run 2: 36810081717 (`workflow_dispatch`, same head `9614535c`)

```
python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36810081717 --cache-state
```

```
## run 36810081717

| Lane | Job seconds | Proxy (min) | Run tests seconds | Build cache |
|---|---|---|---|---|
| min | 169 | 3 | 100 | miss |
| current | 380 | 7 | 162 | miss |
| latest | 170 | 3 | 104 | miss |
| **total** | | **13** | |
```

This run was a cold-cache run (build cache miss on all three lanes — a fresh `workflow_dispatch`
on the same head as run 1, which was a cache hit), labelled rather than silently dropped or (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36810081717 --cache-state`)
compared against a cache-hit baseline, per the plan's must-have.

#### `Prove the gate goes red (failing partition)` and partition tables (`gh run view 36810081717 --log`)

All three lanes' self-test step printed `ci-test-partitions self-test: ok (... same 17 cases as (`gh run view 36810081717 --log`)
run 1 ...)` and the job completed successfully (min at 03:21:55, current at 03:22:20, latest at (`gh run view 36810081717 --log`)
03:21:53), so the mutation control passed on every lane of this run too. (`gh run view 36810081717 --log`)

```
Build and test (min) — ci-test-partitions: partition report (N=4)
| 1 | 0 | 78 | 665 tests, 0 failures |
| 2 | 0 | 77 | 602 tests, 0 failures |
| 3 | 0 | 91 | 544 tests, 0 failures |
| 4 | 0 | 99 | 777 tests, 0 failures |
| total | - | 100 | - |

Build and test (current) — ci-test-partitions: partition report (N=4)
| 1 | 0 | 99 | 665 tests, 0 failures |
| 2 | 0 | 113 | 602 tests, 0 failures |
| 3 | 0 | 151 | 544 tests, 0 failures |
| 4 | 0 | 161 | 777 tests, 0 failures |
| total | - | 162 | - |

Build and test (latest) — ci-test-partitions: partition report (N=4)
| 1 | 0 | 79 | 665 tests, 0 failures |
| 2 | 0 | 82 | 600 tests, 0 failures |
| 3 | 0 | 94 | 543 tests, 0 failures |
| 4 | 0 | 103 | 777 tests, 0 failures |
| total | - | 104 | - |
```

D-07 coverage on the current lane (`gh run view 36810081717 --log`):

```
Build and test (current)	2026-10-01T03:25:03.1189979Z threadline_ci_coverage_canary  covered
Build and test (current)	2026-10-01T03:25:03.1190850Z summary: 1/1 expected tables covered (0 violated)
```

## SUITE-02 verdict

```
python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717
```

```
lane=min run=36808706517 step_drop=37.5% (need>=30.0%) proxy_rise=-33.3% (need<=10.0%) PASS
lane=current run=36808706517 step_drop=49.1% (need>=30.0%) proxy_rise=-25.0% (need<=10.0%) PASS
lane=latest run=36808706517 step_drop=41.9% (need>=30.0%) proxy_rise=-33.3% (need<=10.0%) PASS

lane=min run=36810081717 step_drop=65.3% (need>=30.0%) proxy_rise=-50.0% (need<=10.0%) PASS
lane=current run=36810081717 step_drop=44.3% (need>=30.0%) proxy_rise=-12.5% (need<=10.0%) PASS
lane=latest run=36810081717 step_drop=61.0% (need>=30.0%) proxy_rise=-50.0% (need<=10.0%) PASS

OVERALL: PASS
```

(`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`,
exit 0) (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`)

Two cited after runs, every lane of every run at or beyond the 30% step-drop floor and under the (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`)
10% proxy-rise ceiling (every lane actually shows a proxy *drop*, not a rise, on both runs), (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`)
overall verdict PASS over at least two cited after runs, satisfying the plan's must-have. No run
was re-run or dropped to improve the figure; the nine earlier failing/marginal PR runs listed in
the history table above are the record of what did not pass before the rebalance and the N=4 (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`)
amendment landed.

## Flake Detection (D-18, D-11)

`gh workflow run flake-detection.yml --ref milestone/v1.44` dispatched run **36810083586** on
head `9614535ccfd5f3c0761b493cd0099e0ca78a7d50` (`gh run list --workflow flake-detection.yml --branch milestone/v1.44 --limit 10 --json databaseId,headSha,conclusion,event,createdAt,status`).

### Gate, repeat step, classifier (`gh run view 36810083586 --log`)

```
Suite repeat-until-failure (broken vs flaky)	Classify broken vs flaky	env: GATE_DECISION: run
Suite repeat-until-failure (broken vs flaky)	Classify broken vs flaky	env: EXIT_CODE: 0
Suite repeat-until-failure (broken vs flaky)	Classify broken vs flaky	env: ELAPSED_S: 2994
Suite repeat-until-failure (broken vs flaky)	Classify broken vs flaky	env: BUDGET_S: 3300
Suite repeat-until-failure (broken vs flaky)	Classify broken vs flaky	##[notice]Flake Detection classification: pass (completed iterations: 13, exit: 0)
```

The gate ran (`GATE_DECISION: run`), the repeat step exited 0 at 2994 of a 3300 s budget, and the (`gh run view 36810083586 --log`)
classifier reports **pass** with 13 completed iterations (1 cold first run + 12 repeats, the (`gh run view 36810083586 --log`)
repeat count committed at the time of this dispatch — before the resize below), 0 flaky or broken (`gh run view 36810083586 --log`)
tests.

### Cold first run and slowest repeat (`gh run view 36810083586 --log`)

```
Finished in 286.3 seconds (42.9s async, 243.3s sync)   <- cold first run
Finished in 224.6 seconds (29.2s async, 195.3s sync)
Finished in 225.5 seconds (28.6s async, 196.8s sync)
Finished in 225.5 seconds (28.8s async, 196.7s sync)
Finished in 226.8 seconds (28.9s async, 197.8s sync)
Finished in 227.2 seconds (29.2s async, 198.0s sync)   <- slowest repeat
Finished in 225.1 seconds (28.5s async, 196.5s sync)
Finished in 223.8 seconds (28.6s async, 195.1s sync)
Finished in 225.7 seconds (28.7s async, 197.0s sync)
Finished in 224.7 seconds (29.0s async, 195.7s sync)
Finished in 226.3 seconds (28.9s async, 197.3s sync)
Finished in 225.3 seconds (28.9s async, 196.3s sync)
Finished in 225.9 seconds (29.1s async, 196.7s sync)
```

Raw figures: cold 286.3s, repeats 223.8-227.2s (slowest 227.2s), 13 "Finished in" lines total (`gh run view 36810083586 --log`)
(1 cold + 12 repeats), matching the iteration count the classifier reported. (`gh run view 36810083586 --log`)

### Exceeded the Plan-03 ceiling; maintainer-authorized resize (deviation)

This run's raw figures (cold 286.3s, slowest repeat 227.2s) are **over** the ceilings Plan 03 (`mix test test/threadline/flake_classifier_contract_test.exs`)
committed (cold 261s, repeat 207s, from this file's D-11 section above, derived from the earlier (`mix test test/threadline/flake_classifier_contract_test.exs`)
run 36364688861). Per the plan's `<action>`, exceeding a committed ceiling is a stop-and-report
condition; per the plan's `<executor_safety>`, changing the sizing and pushing again needs a new
grant. The orchestrator (not this plan's executor) already acted on the standing broad grant
("automatically follow your recommendations... go for it", the same grant quoted under `## CI
after`) and committed the re-derivation as `6c4da13f` ("ci: resize Flake Detection to 11 repeats (`git show 6c4da13f --stat`)
from a measured run"), re-deriving new ceilings from this same run:
`@cold_first_run_ceiling_s 287`, `@repeat_ceiling_s 228` (`mix test test/threadline/flake_classifier_contract_test.exs`)
(`mix test test/threadline/flake_classifier_contract_test.exs`), with the repeat count dropped
from 12 to 11 because 12 repeats at the new ceilings need 3,023s against the 2,970s usable budget (`mix test test/threadline/flake_classifier_contract_test.exs`)
(287 + 12 x 228 = 3,023 > 2,970), while 11 repeats need 2,795s (287 + 11 x 228 = 2,795 <= 2,970), (`mix test test/threadline/flake_classifier_contract_test.exs`)
about 15% headroom. (`mix test test/threadline/flake_classifier_contract_test.exs`)

This run's own raw figures fit inside those re-derived ceilings (286.3 <= 287, 227.2 <= 228), so (`mix test test/threadline/flake_classifier_contract_test.exs`)
the committed sizing — as it stands after `6c4da13f` — is proven by the same run that forced its
re-derivation. This is recorded here rather than silently treated as a plain pass against the
original Plan-03 numbers, consistent with the must-have that a cherry-picked comparator never (`mix test test/threadline/flake_classifier_contract_test.exs`)
fakes a claim.

## SUITE-06 before and after

### Local (labelled local, noisy; median of three plain `mix test` runs)

| Stage | Finished in | Async | Sync | real (s) | Source |
|---|---|---|---|---|---|
| Before (SUITE-01 baseline, `225-BASELINE.md`) | 137.0s | 16.9s | 120.1s | 137.76 | `mix test` |
| After SUITE-03 (telemetry async, `225-02-SUMMARY.md`/this file's D-20) | 133.0s | 13.3s | 119.7s | 133.77 | `mix test` |
| At the phase head (post SUITE-02 gate, `225-03`/this file's "Three phase-head plain `mix test` runs" section) | 136.5s | 14.4s | 122.1s | 137.30 | `mix test` |

SUITE-03 delta (its own line, per D-20): `133.0 - 137.0 = -4.0s` (about -2.9%) on `Finished in` (`mix test`)
(`mix test`) — a small, noisy local improvement well inside this repo's measured local swing.
Plain `mix test` is unpartitioned, so the local figures carry no partitioning delta; `mix
verify.test_partitioned` is the opt-in local path (D-08) and is reported separately above, not
as a SUITE-06 comparator.

### CI (partitioned `Run tests` step per lane, and the billed-minutes proxy, before and after)

| Lane | Before (`run 36730596489`) | After run 1 (`run 36808706517`) | After run 2 (`run 36810081717`) | Step drop (run 1 / run 2) |
|---|---|---|---|---|
| min | 288s | 180s | 100s | 37.5% / 65.3% (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`) |
| current | 291s | 148s | 162s | 49.1% / 44.3% (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`) |
| latest | 267s | 155s | 104s | 41.9% / 61.0% (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`) |
| proxy (min, total) | 20 | 14 | 13 | -30.0% / -35.0% (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`) |

(`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`)

The CI delta above is the combined effect of SUITE-02's partitioning (D-01..D-12, D-03a, D-03b) (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 36808706517 36810081717`)
plus SUITE-03's small async conversion; SUITE-03's own share is reported separately in the local
table above (-2.9%, well under the noise floor this repo already documents), so the great majority (`mix test`)
of the CI-side drop is attributable to partitioning, not to SUITE-03.
