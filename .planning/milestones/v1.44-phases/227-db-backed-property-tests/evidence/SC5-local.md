# SC-5 local wall clock (D-27)

## Local acceptance (D-27, SC4)

Each command below was run once and recorded verbatim; none was red, so none
was re-run.

`mix test --repeat-until-failure 20 test/threadline/capture/redaction_leak_property_test.exs test/threadline/query/as_of_property_test.exs test/threadline/retention/cutoff_property_test.exs`:

```text
20 repeats, 20/20 green. Every repeat: "3 properties, 0 failures".
```

`bash -c 'THREADLINE_PROPERTY_SCALE=5 mix test test/threadline/capture/redaction_leak_property_test.exs test/threadline/query/as_of_property_test.exs test/threadline/retention/cutoff_property_test.exs'`:

```text
THREADLINE_PROPERTY_SCALE=5: pure max_runs x5, DB x3
Finished in 1.2 seconds (0.00s async, 1.2s sync)
3 properties, 0 failures
```

`mix test` (full suite, suite-order effects):

```text
Finished in 151.0 seconds (15.0s async, 136.0s sync)
31 properties, 2672 tests, 0 failures, 3 excluded
```

`mix verify.test_partitioned` (local partitioned-CI proxy, 4 partitions):

```text
| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 54 | 572 tests, 0 failures |
| 2 | 0 | 65 | 693 tests, 0 failures |
| 3 | 0 | 58 | 621 tests, 0 failures |
| 4 | 0 | 50 | 786 tests, 0 failures |
```

`mix verify.format`: exit 0. `mix verify.credo`: "4826 mods/funs, found no issues", exit 0.
`bash -c 'MIX_ENV=test mix compile --warnings-as-errors'`: exit 0, no warnings.

## D-27.1: the three files' own cost

The three DB properties added by this phase, plus `db_property_harness_test.exs`
(the shared harness exercised directly), via:

`mix test test/threadline/capture/redaction_leak_property_test.exs test/threadline/query/as_of_property_test.exs test/threadline/retention/cutoff_property_test.exs test/threadline/db_property_harness_test.exs --slowest-modules 10`

and, at the scaled run, the same file list under:

`bash -c 'THREADLINE_PROPERTY_SCALE=5 mix test test/threadline/capture/redaction_leak_property_test.exs test/threadline/query/as_of_property_test.exs test/threadline/retention/cutoff_property_test.exs test/threadline/db_property_harness_test.exs --slowest-modules 10'`

A warm-up run (discarded) was run first (not separately tabulated below,
per phase 226's evidence-doc convention), then five runs at scale one and
five runs at the scaled env var (see the next subsection).

### Scale 1 — 5 runs

```text
run  Finished-in(s)  real-total(s)
1    0.6             1.131
2    0.5             1.096
3    0.5             1.112
4    0.4             0.976
5    0.5             1.015

median Finished-in: 0.5s
median real-total:  1.096s
```

### Scale 1 — per-module median (ms, across the 5 runs above)

```text
Threadline.Query.AsOfPropertyTest                 222.9
Threadline.Retention.CutoffPropertyTest           116.7
Threadline.Capture.RedactionLeakPropertyTest       72.7
Threadline.DbPropertyHarnessTest                   33.6
```

### Scale 5 (`THREADLINE_PROPERTY_SCALE=5`) — 5 runs

```text
run  Finished-in(s)  real-total(s)
1    1.2             1.892
2    1.0             1.614
3    1.3             1.922
4    1.5             2.123
5    1.1             1.638

median Finished-in: 1.2s
median real-total:  1.892s
```

### Scale 5 — per-module median (ms, across the 5 runs above)

```text
Threadline.Query.AsOfPropertyTest                 621.4
Threadline.Capture.RedactionLeakPropertyTest      226.2
Threadline.Retention.CutoffPropertyTest           238.5
Threadline.DbPropertyHarnessTest                   41.6
```

### D-27: partition weights

At the unscaled run every one of the three new property files' own median
module cost (the scale-one per-module table above — `AsOfPropertyTest` is
the slowest) stays well under the two-second-per-file threshold for a solo
append, so `test/partition_weights.txt` is left untouched — no line is
appended, and `bin/ci-test-partitions --write-weights` was never run.

## D-27.2: whole-suite local before/after (local, noisy)

Base commit: the parent of the first commit whose subject starts with
`feat(227-01)` (the first `227-01` commit in this phase), found with:

`git log --reverse --format=%H %s` filtered for a `feat(227-01)` or
`test(227-01)` subject, then `^` on the oldest match.

Worktree built with `git worktree add --detach "${TMPDIR:-/tmp}/tl-227-base" 582602c5`,
deps reused via `bash -c 'MIX_DEPS_PATH=<repo>/deps mix deps.get'`, one
`bash -c 'MIX_DEPS_PATH=<repo>/deps mix compile'` warm-up, then three timed
`bash -c 'MIX_DEPS_PATH=<repo>/deps mix test'` runs. Removed afterward with
`git worktree remove` (`git worktree list` back to one entry).

### Base — three `bash -c 'MIX_DEPS_PATH=<repo>/deps mix test'` runs

```text
run  Finished-in(s)  real-total(s)  counts
1    153.1           170.29         2650 tests, 1 failure, 28 properties
2    133.1           133.84         2650 tests, 1 failure, 28 properties
3    132.9           133.56         2650 tests, 1 failure, 28 properties

median Finished-in: 133.1s
median real-total:  133.84s
```

The one failure on every base run is `Threadline.DepFloorGuardTest`
("no locked dep floors above Elixir 1.15" — "deps/ is empty — run `mix
deps.get` before this guard"). It is an artifact of running under
`MIX_DEPS_PATH`, not a regression introduced by this phase: that test globs
the worktree's own relative `deps/*/mix.exs` path, which is empty in the
worktree because the actual dependency tree lives at the real repo's `deps/`
path per the plan's reuse instruction (D-27). The same test passes cleanly
on the phase head's plain `mix test` runs below, where no `MIX_DEPS_PATH`
override is in play. This is the same characteristic the phase 226 evidence
doc documented for its own base worktree.

### Head — three plain `mix test` runs

```text
run  Finished-in(s)  real-total(s)  counts
1    140.7           141.45         2672 tests, 0 failures, 31 properties
2    128.9           129.46         2672 tests, 0 failures, 31 properties
3    127.0           127.58         2672 tests, 0 failures, 31 properties

median Finished-in: 128.9s
median real-total:  129.46s
```

### Local, noisy — restating the documented noise floor

```text
median Finished-in, base: 133.1s
median Finished-in, head: 128.9s
delta (head - base):      -4.2s

base run1 -> run3 swing:  153.1s -> 132.9s (-20.2s), a monotonic cooldown
  across the three timed runs, not a trend tied to any one commit

test-count delta (base -> head): 2650 -> 2672 tests (`mix test`)
property-count delta (base -> head): 28 -> 31 properties (`mix test`)
```

local, noisy: this machine's own documented load-noise floor is on an order
of magnitude larger than the head-vs-base gap recorded above, so this local
whole-suite figure is read as within the documented noise floor, not as a
per-test regression or improvement in either direction. CI's dedicated,
single-tenant runners are the reliable before/after signal and are reported
separately in this phase's EVIDENCE.md, in its CI subsection.

```text
phase 224's evidence doc recorded head-vs-base swings of about 52 seconds
and 56 seconds in opposite directions from unrelated concurrent processes on
the same machine (224-EVIDENCE.md, D-18 local-noise note), against this
phase's -4.2s head-vs-base gap. Structural delta this phase added: 22 more
tests, 3 more properties.
```
