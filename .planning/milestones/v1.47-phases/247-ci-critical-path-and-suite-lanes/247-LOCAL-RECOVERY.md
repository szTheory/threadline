# Local recovery after the B4 cap

The maintainer authorized the recommended local diagnosis and evidence-backed
fixture fixes after Plan 19 halted. No new CI run, retry, push, merge or measurement
cohort was started. B4 remains four successes, two failures, CI-02 INCOMPLETE and
CI-03 MISS. This follow-up does not complete halted Plan 19.

## Committed fixes

- `136bb932`: co-locate the four shared local-export filesystem users and make
  LocalTest synchronous. The production runner regression detects overlapping
  OS processes when the group is removed. See
  `../../debug/247-export-fixture-isolation.md`.
- `714b4dbb`: give ExUnit ownership of pruner fixture workers. The exact leaking
  test returned with one worker alive. A controlled surviving worker removed a
  fresh parent and reproduced `audit_changes_transaction_id_fkey`. The regression
  fails when worker ownership is reverted. See `../../debug/247-row-history-fk.md`.

Independent review found no confirmed defects in either fix. Application code,
public APIs, weights, inventories, thresholds, retry policies and workflow remain
unchanged. The source changes are test-only and have not landed on main.

## Verification

| Check | Result |
|---|---|
| Production current/full runner, four processes | 269 files; 3,383 tests; 32 properties; zero failures; 89 s |
| Production min-scope runner with temporary trace enabled, local current toolchain | 206 files; 2,563 tests; zero failures; 61 s |
| Seven affected files on Elixir 1.15.8 / OTP 26.2.5.21 | 100 tests; zero failures; native ARM64, PostgreSQL 16 |
| Export overlap negative control | Removing the group triggers overlapping-process failures |
| Pruner ownership negative control | Reverting to Task.start fails the ownership assertion |
| Pruner plus row-history after final timer hardening | 19 tests, zero failures at seeds 675682, 1, 2 and 3 |
| Named format and strict Credo checks | Pass; no Credo issues |
| Independent source and temporary diagnostic review | Zero confirmed defects |

Local partition ratios were 1.58 (full) and 1.44 (min scope). They are diagnostic
results on a different runner, not replacements for the fixed main ratios or a
CI-03 acceptance claim. The exact minimum-toolchain check used ARM64/PG16 rather
than CI's AMD64/PG15. No browser or production UI source changed.

## Startup diagnosis and rejected optimization

On native ARM64 with the exact min Elixir/OTP pair, the captured 31-file P3 list
reached its first module at 3.749 s. The helper's database/application work took
112 ms; file require took 2.554 s. Moving timeline fixtures into precompiled
support saved only 0.400 s from require and added 1.531 s to project compile,
worsening the combined cold path by 1.131 s. That scratch change was rejected.

The repeated 17–22 s AMD64 CI interval remains unexplained. No model, weight,
async-flag or threshold tuning is justified. Full evidence and limits are in
`../../debug/247-min-startup.md`.

## Concrete next action: one diagnostic CI run

`tools/min-startup-trace.patch` is a temporary, locally checked diagnostic patch.
It is saved with zero context; apply with:

```sh
git apply --check --unidiff-zero .planning/phases/247-ci-critical-path-and-suite-lanes/tools/min-startup-trace.patch
git apply --unidiff-zero .planning/phases/247-ci-critical-path-and-suite-lanes/tools/min-startup-trace.patch
```

It enables low-sensitivity helper phase timestamps only on the min lane, runs
the unchanged full partitioned tests, then profiles the frozen B4 P3 file list
without executing it again. Its extra steps have a two-minute profile timeout
and upload the phase trace, actual assignments and profile log. All three matrix
lanes and the required aggregate remain intact. The diagnostic must run off main
and its instrumentation must be removed before a landing candidate is merged.

Local checks: trace-enabled 206-file run above; workflow YAML parsed; actionlint
and shell syntax pass; the known Elixir 1.15 profiler exit-1/path diagnostic is
accepted only with a completed compilation marker and no compilation error; an
injected CompileError is rejected. The normal test step remains independently
blocking. Patch application check passes against the committed fixture fixes.

Recommendation: authorize exactly one `ci.yml` workflow dispatch on a diagnostic
branch. This is one complete workflow run with min-only instrumentation, not a
min-only workflow and not a new main measurement cohort. No retries or extra
dispatches. Read the trace, propose a causal fix if supported, and stop for scope
if it is inconclusive. A fresh main measurement budget is a later decision.

The explicit six-run cap in `247-19-PLAN.md` requires a new budget decision before
this run. Both old failures and all fixed B4 ratios remain immutable evidence.
