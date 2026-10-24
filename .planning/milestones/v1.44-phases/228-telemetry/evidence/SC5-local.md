# SC-5 local wall clock (D-19)

## Local acceptance (D-19)

Each command below was run once and recorded verbatim; none was red, so none
was re-run.

`mix test` (full suite):

```text
Finished in 137.4 seconds (15.0s async, 122.3s sync)
31 properties, 2702 tests, 0 failures, 3 excluded
```

`mix verify.test_partitioned` (local partitioned-CI proxy, 4 partitions):

```text
| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 47 | 677 tests, 0 failures |
| 2 | 0 | 57 | 620 tests, 0 failures |
| 3 | 0 | 51 | 640 tests, 0 failures |
| 4 | 0 | 40 | 765 tests, 0 failures |
```

`mix verify.format`: exit 0 (no output).

`mix verify.credo`: exit 0.

```text
"4895 mods/funs, found no issues" over 415 source files.
```

`bash -c 'MIX_ENV=test mix compile --warnings-as-errors'`: exit 0, no
warnings.

`mix docs`: exit 0, no warning (`doc/index.html`, `doc/llms.txt`,
`doc/Threadline.epub` generated).

`bash -c 'bin/verify-repo-hygiene'`: exit 0.

```text
"4435 tracked text file(s) clean; 8 allowlist entries used, 0 inert".
```

`bash -c 'THREADLINE_PROPERTY_SCALE=5 mix test test/threadline/capture/redaction_leak_property_test.exs'`:

```text
THREADLINE_PROPERTY_SCALE=5: pure max_runs x5, DB x3
Finished in 0.3 seconds (0.00s async, 0.3s sync)
1 property, 0 failures
```

## D-19: the new and extended telemetry files' own cost

The nine files named by the plan — four brand-new to this phase
(`telemetry_registry_contract_test.exs`, `telemetry_raising_handler_test.exs`,
`telemetry_doc_contract_test.exs`, `telemetry_repo_query_recipe_test.exs`),
one new controller test (`export_controller_telemetry_test.exs`), and four
pre-existing files this phase extended (`redaction_leak_property_test.exs`,
`retention_test.exs`, `export_test.exs`, `export/orchestrator_test.exs`) —
via:

`mix test --slowest-modules 20 test/threadline/telemetry_registry_contract_test.exs test/threadline/telemetry_raising_handler_test.exs test/threadline/telemetry_doc_contract_test.exs test/threadline/telemetry_repo_query_recipe_test.exs test/threadline/operator_surface/export_controller_telemetry_test.exs test/threadline/capture/redaction_leak_property_test.exs test/threadline/retention_test.exs test/threadline/export_test.exs test/threadline/export/orchestrator_test.exs`

A warm-up run (discarded) was run first, then three timed runs at the phase
head.

### Head — 3 runs

```text
run  Finished-in(s)
1    4.6
2    4.6
3    4.7

median Finished-in: 4.6s
```

### Head — per-module median (ms, across the 3 runs above)

```text
Threadline.Export.OrchestratorTest                1108.7
Threadline.OperatorSurface.ExportControllerTelemetryTest 1075.3
Threadline.TelemetryRepoQueryRecipeTest            1074.0
Threadline.ExportTest                               563.4
Threadline.RetentionTest                            370.4
Threadline.Capture.RedactionLeakPropertyTest         88.5
Threadline.TelemetryRaisingHandlerTest               74.7
Threadline.TelemetryRegistryContractTest             66.7
Threadline.TelemetryDocContractTest                  13.8

head total (sum of medians): 4435.5ms
```

### Base — the four pre-existing extended files only, 3 runs

```text
The four brand-new files and the new controller test do not exist at the
base commit, so their base cost is 0 by construction.
```

Only the four pre-existing files this phase extended were measured at the
base commit (the worktree built in the whole-suite section below), via:

`bash -c 'MIX_DEPS_PATH=<repo>/deps mix test --slowest-modules 10 test/threadline/capture/redaction_leak_property_test.exs test/threadline/retention_test.exs test/threadline/export_test.exs test/threadline/export/orchestrator_test.exs'`

```text
run  Finished-in(s)
1    1.1
2    1.2
3    1.2

median Finished-in: 1.2s
```

### Base — per-module median (ms, across the 3 runs above)

```text
Threadline.RetentionTest                            388.2
Threadline.ExportTest                               346.7
Threadline.Export.OrchestratorTest                  219.8
Threadline.Capture.RedactionLeakPropertyTest         122.3

base total (sum of medians): 1077.0ms
```

### D-19: added own cost and the Flake Detection threshold

```text
head total:   4435.5ms (9 files: 4 new + 1 new controller test + 4 extended)
base total:   1077.0ms (the 4 pre-existing extended files only)
added cost:   3358.5ms (~3.4s)
```

```text
3.4s is well under the plan's 15s Flake Detection threshold (the 227 Test 6
headroom is 200s over 9 runs), so Flake Detection is not requested by this
measurement. See 228-EVIDENCE.md's Flake Detection subsection for the
recorded reason.
```

### D-19: partition weights

```text
None of the nine files' own median module cost (head table above) exceeds
the two-second-per-file threshold for a solo append (the slowest,
Export.OrchestratorTest, is 1108.7ms).
```

`test/partition_weights.txt` is left untouched — no line is appended, and
`bin/ci-test-partitions --write-weights` was never run.

## D-19: whole-suite local before/after (local, noisy)

Base commit: the parent of the first commit whose subject contains
`(228-01)`, found with:

`git log --reverse --format=%H --grep='(228-01)' | head -1`, then `^` on
that match.

Worktree built with `git worktree add --detach "${TMPDIR:-/tmp}/tl-228-base" 3159f27a`,
deps reused via `bash -c 'MIX_DEPS_PATH=<repo>/deps mix compile'` for both
the dev and test environments (one warm-up compile each), then three timed
`bash -c 'MIX_DEPS_PATH=<repo>/deps mix test'` runs. Removed afterward with
`git worktree remove --force` (`git worktree list` back to one entry).

### Base — three `bash -c 'MIX_DEPS_PATH=<repo>/deps mix test'` runs

```text
run  Finished-in(s)  real-total(s)
1    232.0            232.79
2    212.4             213.43
3    213.7             214.86

median Finished-in: 213.7s
median real-total:  214.86s
```

A fourth, untimed run of the same unmodified base commit
(`bash -c 'MIX_DEPS_PATH=<repo>/deps mix test'`, output redirected to a
temp file) was made solely to capture the test/failure counts the three
timed runs above did not record to stdout under the `grep`-filtered
capture; it is not used in the timing median above, and its own
Finished-in is reported for transparency, not substituted for any of the
three timed figures:

```text
Finished in 256.5 seconds (33.7s async, 222.8s sync)
31 properties, 2673 tests, 1 failure, 3 excluded
```

The one failure is `Threadline.DepFloorGuardTest` ("no locked dep floors
above Elixir 1.15" — "deps/ is empty — run `mix deps.get` before this
guard"), the same `MIX_DEPS_PATH` worktree artifact phase 227's evidence
already documented: that test globs the worktree's own relative
`deps/*/mix.exs` path, which is empty because the real dependency tree
lives at the main repo's `deps/` path per the plan's reuse instruction. It
is not a regression introduced by this phase; the same test passes cleanly
on the phase head's plain `mix test` runs below.

### Head — three plain `mix test` runs

```text
run  Finished-in(s)  real-total(s)
1    137.4            n/a (ExUnit "Finished in" only; no `/usr/bin/time` wrapper on this run)
2    254.4            255.69
3    219.0            220.20

median Finished-in: 219.0s
```

All three head runs:

```text
31 properties, 2702 tests, 0 failures, 3 excluded.
```

### Local, noisy — restating the documented noise floor

```text
median Finished-in, base: 213.7s
median Finished-in, head: 219.0s
delta (head - base):      +5.3s

test-count delta (base -> head):     2673 -> 2702 tests (+29)
property-count delta (base -> head): 31 -> 31 (unchanged)
```

local, noisy: this machine's own documented load-noise floor (phase 224's
evidence doc restated by phase 227's evidence at about 52-56 seconds of
swing from unrelated concurrent processes on the same machine) is an order
of magnitude larger than the head-vs-base gap recorded above (see the
figures above), so this local whole-suite figure is read as within the
documented noise floor, not as a per-test regression or improvement in
either direction.

```text
Two other long-lived beam.smp processes (unrelated `mix ci` and
`mix test.fast` invocations, started well before any of the timed runs
above) were observed still running on this machine throughout both the
base and head measurement windows via `ps aux`, which is the concrete
source of this run's noise.
```

CI's dedicated, single-tenant runners are the reliable before/after signal
and are reported separately in this phase's EVIDENCE.md, in its CI
subsection.

```text
Structural delta this phase added: 29 more tests, 0 more properties (no new
property file; the existing redaction property gained a telemetry observer
and a structural guard, not a new property).
```
