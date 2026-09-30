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
