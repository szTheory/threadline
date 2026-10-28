# One approved off-main startup diagnostic

The maintainer answered **yes** to exactly one off-main diagnostic CI run after
reviewing `247-LOCAL-RECOVERY.md` and `tools/min-startup-trace.patch`. This grants
one complete `ci.yml` workflow dispatch, no retry and no main measurement cohort.

## Identity and budget

- Main baseline: `02d115a32e4479f353d284c04fc838ba58938d16` (freshly fetched).
- Reviewed local source: `99efb50e` (fixture fixes `136bb932` and `714b4dbb`).
- Diagnostic branch: `diag/v1.47-min-startup`.
- Diagnostic head: `8177d00d74b03527c2b14bbb0ef17f6c5895b464`.
- Run: [40504321590](https://github.com/szTheory/threadline/actions/runs/40504321590).
- Event: `workflow_dispatch`; created `2026-10-27T12:30:40Z`; attempt 1.
- Budget: **1/1 dispatch used**. No other run existed on this branch before the
  request. A local exclusive-create request ledger prevents accidental repeat.
- No PR or merge was created. The diagnostic instrumentation is off main and is
  absent from the quality-baseline source. The diagnostic head stays immutable.

The diagnostic branch was created from current main. It contains only the four
reviewed fixture-fix files and the three trace-patch files. All four fixture files
byte-match the source authority. Branch push is outside every workflow's main-only
push filters; the one explicit dispatch is the CI trigger.

## Fresh preflight

- `mix verify.format`: pass.
- Seven targeted files, seed 675682: **100 tests, zero failures**.
- `actionlint .github/workflows/ci.yml`: pass.
- `git diff --check`: pass.
- Remote branch head equals the committed diagnostic head.
- Frozen profile list contains the 31 captured B4 min P3 files.

## Interpretation boundary

This is a diagnostic run on a different source head, not a fifth B4 success or a
new main acceptance sample. B4 remains four successful runs and two failed
exclusions; CI-02 is incomplete and CI-03 misses its fixed ratios. Do not retry
this diagnostic if it fails. Capture the trace, identify a causal fix only when
supported, and stop for scope if the evidence is inconclusive. Remove temporary
instrumentation before any landing candidate is merged. A further CI/main budget
requires a separate decision.

## Result

**Success: 17/17 jobs, attempt 1, 11 retained artifacts.** Run wall was 450 s,
from 12:30:40Z to 12:38:10Z. All three build/test lanes, both browser projects,
the journey receipt, Dialyzer, release rehearsal and `CI required` passed.

Machine-checked evidence is preserved in `247-DIAGNOSTIC-EVIDENCE.json`, including
run/head/event identity, all job conclusions, artifact IDs/digests, printed
ratios, inventories, raw min timing TSVs, raw helper trace, frozen file profile
and actual min assignments. All four fixture files matched the reviewed source.
The source authority's workflow and helper remain free of instrumentation.

| Lane | Files | Printed partition seconds P1/P2/P3/P4 | Printed ratio |
|---|---:|---|---:|
| Current | 269 | 139 / 162 / 159 / 163 | 1.17 |
| Min | 206 | 88 / 91 / 102 / 78 | 1.31 |
| Latest | 206 | 147 / 144 / 159 / 155 | 1.10 |

These are one off-main observation per lane. Current and min miss 1.15 in this
run; latest passes once. The 450 s wall is not a five-run median. No phase gate
is closed from this diagnostic and no historical B4 result is replaced.

### Startup findings

| Min partition | Helper entry | Helper work | First module (VM-relative) | Helper end to first module |
|---|---:|---:|---:|---:|
| 1 | 954 ms | 570 ms | 1,886 ms | 362 ms |
| 2 | 979 ms | 680 ms | 2,239 ms | 580 ms |
| 3 | 863 ms | 514 ms | 1,598 ms | 221 ms |
| 4 | 1,090 ms | 499 ms | 2,063 ms | 474 ms |

The old 17–22 s P3 interval did not recur. Database/application setup was fast
in this run. The frozen 31-file B4 P3 list compiled 118 modules in 3,327 ms when
profiled separately after the normal run; timeline fixtures accounted for
3,288 ms. Elixir 1.15's compilation-only mode skipped execution and returned its
expected exit-1/path diagnostic. All frozen files existed and compiled; this is
not a missing-file or test-failure finding.

Actual P3 changed from 31 all-sync files in B4 to 36 files with eight async
files after the export colocation fix. `boot_ms` measures time to the first
module event, so this changed scheduling boundary prevents a controlled
before/after startup comparison. The isolated profile also lacks concurrent
partition load. Neither observation proves why the old delay occurred or that
the fixture fixes cured it.

### Body-cost findings

Min's observed partition walls remain imbalanced despite short startup. The
existing formula applied to this run's observed file durations gives modeled
costs of approximately 78.6 / 78.1 / 86.9 / 72.1 s. Wall minus first-module minus
that explanatory cost leaves residuals of 7.3 / 10.0 / 12.9 / 2.9 s. Committed B3
weights predict approximately 133.6 s per partition instead. Several large
files ran much faster than their committed weights; the changes are not a
uniform scale factor. These offline calculations explain the diagnostic and
are not authoritative acceptance ratios.

A single different-head run cannot establish refreshed weights, an async
factor, a new optimizer or a startup fix. Two independent read-only researchers
agreed that startup causality remains unproven and further hosted sampling or
source tuning is not justified by this observation alone.

## Disposition and next scope

**The one-run task is complete; budget 1/1 used.** No retry, additional dispatch,
main run, PR or merge followed. B4 and Phase 247's 2/4 status remain unchanged.
The diagnostic branch is retained as immutable evidence; it is not a merge
candidate.

Recommendation: one bounded local investigation before another CI proposal.
Use the exact min toolchain and a disposable harness to isolate the effect of
async scheduling on first-module timestamps while holding the test workload,
cache and host fixed. Compare helper completion, file-load completion, first
module and total wall time; use repeated pairs to expose noise. Then replay the
existing B3/B4/diagnostic durations against the unchanged cost components to
separate weight drift from residual execution overhead. Do not change weights,
async flags, the model or thresholds unless a specific causal improvement is
reproduced. This narrows hypotheses; local timing cannot satisfy CI-03.

The requested AMD64 trace did not establish a causal fix, so the approved
protocol stops for scope here. No further CI budget is assumed.
