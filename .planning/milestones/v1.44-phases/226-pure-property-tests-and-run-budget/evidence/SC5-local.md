# SC-5 local wall clock (D-23)

## D-23.1: the new files' own cost

The seven files added by this phase per the D-23 wall-clock requirement:

```text
test/threadline/query/cursors_property_test.exs
test/threadline/change_diff_property_test.exs
test/threadline/capture/redaction_policy_property_test.exs
test/threadline/export_property_test.exs
test/threadline/strict_rfc4180_test.exs
test/threadline/property_scale_contract_test.exs
test/threadline/property_generator_coverage_test.exs
```

Warm-up (discarded), then median of five runs at scale one, then median of
five runs at the scaled env var, via:

`mix test test/threadline/query/cursors_property_test.exs test/threadline/change_diff_property_test.exs test/threadline/capture/redaction_policy_property_test.exs test/threadline/export_property_test.exs test/threadline/strict_rfc4180_test.exs test/threadline/property_scale_contract_test.exs test/threadline/property_generator_coverage_test.exs --slowest-modules 10`

and, at the scaled run, the same file list under:

`bash -c 'THREADLINE_PROPERTY_SCALE=5 mix test <same files> --slowest-modules 10'`

### Warm-up (discarded)

```text
Finished in 1.6 seconds (1.6s async, 0.00s sync)
18 properties, 55 tests, 0 failures
real 2.278s
```

### Scale 1 — 5 runs

```text
run  Finished-in(s)  real-total(s)
1    1.5             2.313
2    2.1             3.108
3    1.6             2.772
4    1.6             2.424
5    1.9             2.906

median Finished-in: 1.6s
median real-total:  2.772s
```

### Scale 1 — per-module median (ms, across the 5 runs above)

```text
Threadline.PropertyGeneratorCoverageTest          917.2
Threadline.ChangeDiffPropertyTest                 264.8
Threadline.ExportPropertyTest                     263.8
Threadline.Query.CursorsPropertyTest              156.9
Threadline.PropertyScaleContractTest               74.8
Threadline.Capture.RedactionPolicyPropertyTest      10.2
Threadline.Test.StrictRFC4180Test                    5.2
```

### Scale 5 (`THREADLINE_PROPERTY_SCALE=5`) — 5 runs

```text
run  Finished-in(s)  real-total(s)
1    96.6            97.35
2    104.9           106.68
3    97.2            98.57
4    84.3            85.62
5    81.7            82.80

median Finished-in: 96.6s
median real-total:  97.35s
```

### Scale 5 — per-module median (ms, across the 5 runs above)

```text
Threadline.ChangeDiffPropertyTest                 54119.7
Threadline.ExportPropertyTest                     36877.6
Threadline.PropertyGeneratorCoverageTest           1072.6
Threadline.Query.CursorsPropertyTest               1009.2
Threadline.PropertyScaleContractTest                115.2
Threadline.Capture.RedactionPolicyPropertyTest        67.0
Threadline.Test.StrictRFC4180Test                     11.4
```

### D-24: partition weights

At the unscaled run every new file's own median module cost (above) is well under
the D-24 two-second-per-file threshold for a solo append, so
`test/partition_weights.txt` is left untouched — no line is appended, and
`--write-weights` was never run.

## D-23.2: whole-suite local before/after (local, noisy)

Base commit: the parent of the first commit whose subject starts with
`test(226-01)`, found with:

`git log --reverse --format=%H --grep='^test(226-01)' | head -1`

then `^`.

Worktree built with `git worktree add --detach "${TMPDIR:-/tmp}/tl-226-base" <base>`,
deps reused via `bash -c 'MIX_DEPS_PATH=<repo>/deps mix deps.get'`, one
`bash -c 'MIX_DEPS_PATH=<repo>/deps mix compile'` warm-up, then three timed
`bash -c 'MIX_DEPS_PATH=<repo>/deps mix test'` runs. Removed afterward with
`git worktree remove`.

### Base — three `bash -c 'MIX_DEPS_PATH=<repo>/deps mix test'` runs

```text
run  Finished-in(s)  real-total(s)  counts
1    274.6           312.99         2588 tests, 1 failure, 10 properties
2    226.5           227.56         2588 tests, 1 failure, 10 properties
3    192.0           193.40         2588 tests, 1 failure, 10 properties

median Finished-in: 226.5s
median real-total:  227.56s
```

The one failure on every base run is `Threadline.DepFloorGuardTest`
("no locked dep floors above Elixir 1.15"). It is an artifact of running
under `MIX_DEPS_PATH`, not a regression introduced by this phase: that test
globs the worktree's own relative `deps/*/mix.exs` path, which is empty in
the worktree because the actual dependency tree lives at the real repo's
`deps/` path per the plan's reuse instruction (D-23). The same test
passes with 0 failures on the phase head's plain `mix test` runs below,
where no `MIX_DEPS_PATH` override is in play.

### Head — three plain `mix test` runs

```text
run  Finished-in(s)  real-total(s)  counts
1    147.7           148.66         2649 tests, 0 failures, 28 properties
2    144.9           145.57         2649 tests, 0 failures, 28 properties
3    139.4           140.13         2649 tests, 0 failures, 28 properties

median Finished-in: 144.9s
median real-total:  145.57s
```

### Local, noisy — restating the documented noise floor

```text
median Finished-in, base: 226.5s
median Finished-in, head: 144.9s
delta (head - base):      -81.6s

base run1 -> run3 swing:  274.6s -> 192.0s (-82.6s), a single monotonic
  cooldown across the three timed runs, not a trend tied to any one commit

test-count delta (base -> head): 2588 -> 2649 tests (`mix test`)
property-count delta (base -> head): 10 -> 28 properties (`mix test`)
```

The head-vs-base gap and the base's own run-to-run swing are both on the
order of magnitude already documented as this machine's local load noise.

```text
phase 224's evidence doc recorded head-vs-base swings of about 52 seconds
and 56 seconds in opposite directions from unrelated concurrent processes
on the same machine (224-EVIDENCE.md, D-18 local-noise note).
structural delta this phase added: 61 more tests, 18 more properties.
```

That structural delta is far smaller than either swing, so this local
figure is recorded for completeness per D-23 and is not read as a
per-test regression or improvement on its own. CI's dedicated,
single-tenant runners are the reliable before/after signal and are
reported separately in this phase's EVIDENCE.md, in its `### CI`
subsection (pending on the maintainer's grant unless already dispatched).
