# Phase 247 — Gate measurement on main after Land B3

Measured 2026-10-27T02:25:12.455760+00:00 using the committed read-only reader. PR #96 landed exact tested head `9fa28fad` as main squash `89add23ede29b7840e6cfa29cd70eb3c8ea59ae2`. All five selected runs are successful **attempt 1**, on that same squash head. The first five qualifying successes are retained in chronological order; failed attempts are explicitly excluded below. No workflow attempt or failed job was rerun.

B3 squash SHA: 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2
B3 CI-02 verdict: PASS
B3 CI-02 requirement: met
B3 CI-03 verdict: MISS
B3 CI-03 requirement: unmet

## Verdicts

| Gate | Threshold | Measured | Verdict |
|---|---|---|---|
| CI-02, median wall over five successes | ≤ 540 s | 444 s | **PASS** |
| CI-03, every first-three ratio on each lane | ≤ 1.15 | current 1.13 / 1.24 / 1.15; min 1.36 / 1.35 / 1.28; latest 1.36 / 1.30 / 1.30 | **MISS** |

CI-03 remains unmet. This completes the prescribed measurement, not phase 247. Thresholds are unchanged; later favorable ratios cannot replace any first-three value.

## Five-run CI-02 wall evidence

Wall is attempt-1 `run_started_at` → `updated_at`; durations below are attempt-1 job durations. Source JSON: `247-B3-MEASUREMENT.json` (`threadline.main-ci-measurement/1`, state measured, found 5).

| Run | Event | Head | Wall s | Desktop s | Mobile s | Receipt s | Slowest job (s) |
|---|---|---|---:|---:|---:|---:|---|
| 40433193088 | push | 89add23e | 423 | 395 | 368 | 18 | Build and test (current) (411) |
| 40434036118 | workflow_dispatch | 89add23e | 471 | 414 | 426 | 19 | Build and test (current) (438) |
| 40434884357 | workflow_dispatch | 89add23e | 451 | 424 | 404 | 16 | Example app browser E2E (desktop-chromium) (424) |
| 40436597341 | workflow_dispatch | 89add23e | 442 | 414 | 292 | 15 | Example app browser E2E (desktop-chromium) (414) |
| 40437416932 | workflow_dispatch | 89add23e | 444 | 361 | 412 | 19 | Example app browser E2E (mobile-chromium) (412) |

Sorted walls: 423 / 442 / 444 / 451 / 471 seconds. Median **444 seconds**. This is the observed gate value, without attributing runner/queue variation to the code change.

## Fixed first-three CI-03 sample

Ratios come from the runner's `| max/min |` report row, never an ExUnit footer. All three Build and test jobs succeeded on all three sampled runs; their four partition rows each have Exit 0.

| Lane | 40433193088 | 40434036118 | 40434884357 | Verdict |
|---|---:|---:|---:|---|
| current | 1.13 | 1.24 | 1.15 | MISS |
| min | 1.36 | 1.35 | 1.28 | MISS |
| latest | 1.36 | 1.30 | 1.30 | MISS |

| Run | current p1/p2/p3/p4 s | min p1/p2/p3/p4 s | latest p1/p2/p3/p4 s |
|---|---|---|---|
| 40433193088 | 178 / 198 / 202 / 188 | 137 / 128 / 136 / 174 | 89 / 84 / 90 / 114 |
| 40434036118 | 170 / 207 / 211 / 203 | 141 / 136 / 140 / 183 | 139 / 137 / 140 / 178 |
| 40434884357 | 142 / 160 / 163 / 159 | 132 / 130 / 134 / 166 | 140 / 135 / 138 / 176 |

Selected files, confirmed from each job's own assignment line: current `test/partition_weights.txt`; min `test/partition_weights_min.txt`; latest `test/partition_weights_latest.txt`. N=4, colocation, scope filtering, monitor and warning-only ratio reporting remain unchanged. These three successful runs are the D-12 order/shared-state coupling sample.

## Excluded attempt-1 runs

- `40435657557` (workflow_dispatch, head `89add23e`): `failure`.

Run 40435657557 failed mobile job 121963594493 in unchanged `operator-motion.spec.ts:275`: modal/toast focus restoration raced keyboard Enter, leaving the toast visible. The case is byte-identical to B2, and the known sibling synchronization fix is recorded in `deferred-items.md`. It is retained as an excluded failure, not called green. Subsequent runs are distinct workflow_dispatch runs, not reruns. Dispatches were serial, after the preceding run reached its terminal result, and stopped after five qualifying successes.

## Receipt, timing and required gate continuity

PR run 40432374330 had all 17 checks green at the exact tested head and validated 31 named journeys across both browser legs. Both browser-timings artifacts, all three partition-timings families and the receipt artifact exist. The five selected main runs retain the browser legs, receipt, timing uploads and CI required; their job durations are recorded in the source JSON. Branch protection after merge remains exactly `CI required@15368`, with no stacked classic rule; main's non-planning tree equals the tested candidate.

## Miss

**CI-03 is MISS; CI-02 is PASS.** Lane-specific weights improved the balance observed after B2, but they did not meet the fixed ratio gate. Min/latest partition 4 is consistently slowest in the first-three sample despite nearly equal predicted loads. For min, p4 is 174 / 183 / 166 s versus fastest 128 / 136 / 130 s; latest p4 is 114 / 178 / 176 s versus 84 / 137 / 135 s. The stable relative residual is evidence of a remaining assignment-model mismatch, not solely runner noise. Absolute latest durations vary substantially between runners, so runner variation is present too. Current ranges 1.13–1.24, meeting the limit twice and missing once.

Do not infer a new weighting formula or relax 1.15 from these observations. CI-03 stays unmet for a research-backed follow-up gap plan. No additional source reweighting occurred during this window. Automated test coverage and threat mitigation are assessed separately from numeric acceptance; no human UAT replaces the measurements.

## Reproduction

```sh
bin/measure-main-ci --since 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2 --count 5 --ratios --format json
```

---

## Historical B2 evidence (superseded for the current live gate)

Measured 2026-10-26 on main only (D-01). Land B2 is the squash
`29abf5653a0e1c31b70d73d71a3f6c552d9b9712` (PR #95, parent `3463fa74`). After the merge,
`git diff --quiet origin/main milestone/v1.47 -- . ':!.planning'` exits 0.

Command, read-only, no `GH_BIN` shim (gh 2.101, the flag is feature-detected since `d1261dfd`):

```
bin/measure-main-ci --since 29abf5653a0e1c31b70d73d71a3f6c552d9b9712 --count 5 --ratios --format json
```

Output schema `threadline.main-ci-measurement/1`, `state: measured`, `found: 5`,
`excluded: []`. The script selected exactly the five runs the orchestrator dispatched, in order,
all on head `29abf565`, attempt 1, conclusion success.

### Verdicts

| Gate | Requirement | Threshold | Measured | Verdict |
|------|-------------|-----------|----------|---------|
| D-08 median ci.yml wall, 5 runs | CI-02 | ≤ 540 s | 468 s | **PASS** |
| D-12 partition max/min, 3 runs per lane | CI-03 | ≤ 1.15 on every run of every lane | current 1.20–1.42, latest 1.43–1.58, min 1.57–1.61 | **MISS** |

### CI-02 median

Wall is attempt-1 `run_started_at` → `updated_at`, as the script reads it. Job seconds are the
attempt-1 job durations.

| Run | Event | Wall s | Desktop leg s | Mobile leg s | Receipt s | Slowest job (s) |
|-----|-------|-------:|--------------:|-------------:|----------:|-----------------|
| 40413601357 | push | 595 | 397 | 413 | 13 | Build and test (current) (444) |
| 40414924903 | workflow_dispatch | 671 | 404 | 324 | 17 | Build and test (current) (438) |
| 40416330436 | workflow_dispatch | 468 | 337 | 443 | 13 | Example app browser E2E (mobile-chromium) (443) |
| 40417290637 | workflow_dispatch | 438 | 358 | 356 | 17 | Build and test (current) (426) |
| 40418204130 | workflow_dispatch | 414 | 367 | 367 | 14 | Build and test (current) (404) |

- Sorted walls: 414 / 438 / 468 / 595 / 671. **Median 468 s (7.8 min). PASS (≤ 540 s).**
- Excluded runs: none. No cancelled, failed or re-attempted run sits in the window.
- Baseline: median 724 s (12.07 min, CONTEXT `<baseline>`, pre-247 main). The median is
  256 s lower, a 35 % cut.
- Leg medians: desktop 367 s, mobile 367 s. Receipt fan-in median 14 s. `CI required` 2–5 s.
  The pre-split single browser job had a median of 706 s.
- **New critical path:** `Build and test (current)` is the slowest job in 4 of 5 runs (median
  438 s). The browser legs are now close behind it. `Example app browser E2E (mobile-chromium)`
  was the slowest job in the median run. The browser job was the bound before the split.
- Wall exceeds the slowest job by 10–233 s. The tail is the receipt and `CI required` running
  after the legs, plus runner queueing. Runs 1 and 2 have the largest gaps.

### CI-03 partition ratios

The ratio is the `| max/min |` row of the `bin/ci-test-partitions` report table, read from each
`Build and test (<lane>)` job log by `bin/measure-main-ci --ratios` (D-12: never parsed from
ExUnit summary lines). The first 3 consecutive runs are 40413601357, 40414924903 and
40416330436.

| Lane | 40413601357 | 40414924903 | 40416330436 | Verdict |
|------|------------:|------------:|------------:|---------|
| current | 1.20 | 1.26 | 1.42 | MISS |
| latest | 1.48 | 1.58 | 1.43 | MISS |
| min | 1.57 | 1.61 | 1.59 | MISS |

Runs 4 and 5 agree: current 1.19 / 1.23, latest 1.47 / 1.40, min 1.58 / 1.69. No lane has
even one run at or under 1.15.

Partition seconds (p1 / p2 / p3 / p4) from the same report tables:

| Run | current | latest | min |
|-----|---------|--------|-----|
| 40413601357 | 195 / 220 / 208 / 234 | 98 / 116 / 138 / 145 | 89 / 122 / 137 / 140 |
| 40414924903 | 173 / 212 / 192 / 218 | 66 / 80 / 104 / 103 | 104 / 137 / 167 / 161 |
| 40416330436 | 121 / 157 / 150 / 172 | 116 / 126 / 166 / 164 | 80 / 109 / 127 / 126 |

Test counts per partition: current 789 / 813 / 915 / 861. latest 453 / 620 / 800 / 682. min
453 / 623 / 800 / 682.

**Order-coupling check (D-12):** all 15 lane jobs in the 5 runs passed with 0 failures on the
new partition mix. No order or shared-state coupling surfaced.

Compared with before the refresh (247-OBSERVATION `## Partition ratios`, 1.44–1.68 on every
lane): the current lane improved to 1.19–1.42, so the current-lane weights work. The min and
latest lanes did not improve. They run a subset of the files (repo-file contract tests are
current-only, D-09/D-10), but they are partitioned with the current-lane weights. So p1 is
consistently the light partition on both subset lanes (453 tests against 620–800).

### Receipt across merged results

PR run `40412545694` on the land head `e85195da`: all 17 checks green, including
`Example app browser E2E (desktop-chromium)`, `Example app browser E2E (mobile-chromium)`,
`Browser journey receipt` and `CI required`. The receipt job downloaded the four leg artifacts
(`operator-ci-executed-{desktop,mobile}-chromium-40412545694` and
`operator-ci-discovered-{desktop,mobile}-chromium-40412545694`) with the existing permissions,
with no 403 (RESEARCH A1 did not trigger). Its log reads
`Validated 31 named journeys across desktop-chromium, mobile-chromium.` The receipt artifact
`operator-ci-evidence-40412545694` exists. Each of the 5 main runs above also ran
`Browser journey receipt` green.

### Branch protection

`bin/verify-branch-protection` (read-only), after the merge:

```
OK: required contexts are exactly [CI required@15368]
Branch protection OK for szTheory/threadline@main: required contexts are exactly [CI required@15368], that name has been emitted 5 time(s) on head 29abf5653a0e1c31b70d73d71a3f6c552d9b9712, and no classic protection is stacking.
```

`CI required` is still the single required context.

### Miss

**CI-03 misses. CI-02 passes**, so the D-08 shard fallback is not needed. The two browser legs
are balanced (median 367 s each; 247-OBSERVATION per-project share 50.95 % mobile / 49.05 %
desktop), and the median has 72 s of headroom.

CI-03 numbers: see `## CI-03 partition ratios`. Every lane misses on every run. The worst is
min (1.57–1.69). The current lane is closest (1.19–1.42), and runner noise is large: the same
head's current-lane partition walls vary up to 1.6× between runs (p1 195 s against 121 s).

Fallback for gap closure (D-11 per-lane weights):

1. The input already exists. Every lane uploads `partition-timings-<lane>-<run>` TSVs. The
   three runs above have them for `min`, `current` and `latest`. `bin/ci-test-partitions
   --ingest-weights <dir> --lane min|latest` (247-04) ingests one lane's TSVs, and the
   per-file median over 3 runs is the D-11 rule.
2. The gap-closure plan adds only a per-lane weights file for `min` and `latest` (same
   `<ms> <file>` format; the weights-inventory contract must accept a lane-subset file) and its selection
   in the runner by lane. `test/partition_weights.txt` stays the current-lane file.
3. Current-lane residual (1.19–1.42): re-ingest from the 5 post-B2 current-lane TSVs, and
   check whether one file exceeds the even share (D-11 split rule). If the residual after that
   is runner noise rather than assignment, that is a scope decision, not a reason to change
   the threshold.
4. Re-measure 3 consecutive main runs per lane with `bin/measure-main-ci --ratios` after the
   per-lane weights land.

Threshold not relaxed. Next: /gsd-plan-phase 247 --gaps; a miss remaining after the fallback is a maintainer scope decision.


## B4 bounded outcome — INCOMPLETE

B4 measurement: INCOMPLETE

The exact PR #97 candidate `4ff7af655315a927eb5a62e14cb2abc7e72d4ab8` landed as main `02d115a32e4479f353d284c04fc838ba58938d16`. The authorized six-run window is exhausted: four successful attempt-1 runs and two failed exclusions, using the merge push and five serial dispatches. Source and acceptance limits stayed fixed; no attempt/job was retried and no seventh run was dispatched.

CI-02 on B4 is **INCOMPLETE**: five qualifying successes were required and only four exist. The canonical reader reports `median_wall_s: null`; no five-run PASS is inferred. Historical B3 CI-02 PASS at 444 s remains historical; SEED-006 retains that last complete bound.

CI-03 is **MISS** on the fixed first-three successful runs: all six current/latest ratios pass, while all three min ratios exceed 1.15. Startup remains part of the accepted full-wall measurement.

| Qualifying run | Event | Wall s |
|---|---|---:|
| 40449332597 | push | 454 |
| 40450141708 | workflow_dispatch | 423 |
| 40450801580 | workflow_dispatch | 468 |
| 40451533079 | workflow_dispatch | 404 |

| Lane | First / second / third printed ratios |
|---|---|
| current | 1.12 / 1.11 / 1.12 |
| min | 1.24 / 1.28 / 1.27 |
| latest | 1.10 / 1.04 / 1.12 |

### Failed exclusions and follow-up

- 40452150109, min job 122017125177, partition 3, seed 675682: `Threadline.OperatorSurface.RowHistoryLiveScopedTest` at `row_history_live_test.exs:361`, `audit_changes_transaction_id_fkey` during child insertion after parent insertion. Source triage confirms parent/child use the same Repo options and each partition has its own database; it does not establish why the parent row was absent. Do not label a root cause or patch colocation from that evidence.
- 40452833440, min job 122019295198, partition 1, seed 856063: `Threadline.Export.OrchestratorTest` at `export/orchestrator_test.exs:239`, setup line 177, `File.rm_rf!("priv/threadline_exports")` failed with “file already exists.” The fixture uses a checkout-shared directory. A read-only replay maps orchestrator to min partition 1, export controller to partition 4, and cleanup/local-storage tests to partition 2. This demonstrates cross-process shared-path exposure; further diagnosis must capture the competing writer/cleanup before claiming the failure cause or a fix.

Both newly observed failures remain failed, excluded and unresolved. Failed initial PR run 40446515239 and historical B3 failed run 40435657557 remain separately recorded and were not retried. CI-01 timing artifacts, both browser projects, full 31-journey receipts and CI-04 guards were verified on the exact green PR and four qualifying main successes; they do not erase the two failed attempts.

### Residual diagnosis and scope recommendation

All three min misses have partition 3 slowest. Its pre-first-module boot intervals are 20.469 / 18.940 / 17.227 s; min active-only ratios are 1.140 / 1.165 / 1.127. The first p3 active wall is 145.075 s versus a 145.070 s observed sync-module sum. These intervals recur; the artifacts do not establish their cause. Current and latest pass all six full-wall ratios. Both independent researchers recommend no further optimizer, weight, N=4, inventory, or threshold change from this evidence.

Stop paid sampling at this cap. Recommended next scope is a bounded local diagnosis of fixture isolation (shared export directory and the separate row-history FK failure), then a concrete reviewed candidate and a new sampling budget decision. Do not spend more runs trying to obtain a favorable sample or waive the fixed 1.15 / 540 s limits silently.

The unchanged canonical count-5 reader payload is `247-B4-INCOMPLETE.json`. No complete `247-B4-MEASUREMENT.json` or B4-GATE-JSON block is produced. Plan 19 Task 2's complete-five reconciliation and its mutation controls cannot run because their sample precondition is unmet. The incomplete payload, both projections, six-run chronology and two exclusions are reconciled separately; this is not a substitute PASS.

<!-- B4-INCOMPLETE-JSON-BEGIN -->
{
  "schema": "threadline.phase247-b4-incomplete/1",
  "squash_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
  "state": "INCOMPLETE",
  "required_successes": 5,
  "found_successes": 4,
  "total_runs": 6,
  "run_cap": 6,
  "extra_dispatches": 5,
  "runs": [
    {
      "id": 40449332597,
      "event": "push",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "wall_s": 454
    },
    {
      "id": 40450141708,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "wall_s": 423
    },
    {
      "id": 40450801580,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "wall_s": 468
    },
    {
      "id": 40451533079,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "wall_s": 404
    }
  ],
  "first_three_ratios": {
    "current": [
      1.12,
      1.11,
      1.12
    ],
    "min": [
      1.24,
      1.28,
      1.27
    ],
    "latest": [
      1.1,
      1.04,
      1.12
    ]
  },
  "excluded": [
    {
      "id": 40452150109,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "reason": "failure"
    },
    {
      "id": 40452833440,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "reason": "failure"
    }
  ],
  "ci02_verdict": "INCOMPLETE",
  "ci03_verdict": "MISS"
}
<!-- B4-INCOMPLETE-JSON-END -->


## B5 bounded outcome — CI-02 PASS, CI-03 MISS

B5 measurement: measured (five attempt-1 successes)

PR #98's exact tested head `14f9562115153c58a792a349f7ef6479496d2d44` landed as main `824c28517820c1cd6595f2e0e60b34ec3ce64d14`. The bounded cohort used 5/6 runs: the merge push plus four serial dispatches. All five are attempt-1 successes at the squash, so sampling stopped with one slot unused. Nothing was retried or re-run, and the 540 s and 1.15 limits are unchanged. The unedited canonical reader payload is `247-B5-MEASUREMENT.json`.

| Selected run | Event | Wall s | Slowest job |
|---|---|---:|---|
| 40692111621 | push | 449 | Build and test (current) (441 s) |
| 40693451272 | workflow_dispatch | 457 | Example app browser E2E (mobile-chromium) (432 s) |
| 40694602284 | workflow_dispatch | 450 | Build and test (current) (438 s) |
| 40695763585 | workflow_dispatch | 461 | Build and test (current) (430 s) |
| 40696978392 | workflow_dispatch | 589 | Example app browser E2E (desktop-chromium) (444 s) |

CI-02 is **PASS**: the median wall over the five qualifying runs is **457 s**, at or under 540 s. The last run's 589 s includes runner pickup delay (its Build and test jobs started 40–116 s after creation) and is counted in full.

CI-03 is **MISS** on the fixed first three successful runs:

| Lane | First / second / third printed ratios | Result |
|---|---|---|
| current | 1.17 / 1.17 / 1.09 | two values above 1.15 |
| min | 1.07 / 1.06 / 1.11 | all at or under 1.15 |
| latest | 1.08 / 1.09 / 1.06 | all at or under 1.15 |

Min partition seconds (P1/P2/P3/P4) on the first three runs: 134/140/137/143, 150/153/159/154 and 96/104/107/104. For the failing lane, current partition seconds were 202/204/187/219, 188/198/181/212 and 204/209/199/217. Partition 4 was slowest in all three, and partition 3 fastest in two.

Exclusions: none. No cohort run failed, so neither B4 failure (`row_history_live_test.exs:361` FK, `orchestrator_test.exs:239` rm_rf) recurred, and there is nothing to triage.

### Prediction versus measurement (min lane)

| Source | Min ratio |
|---|---|
| B5-WEIGHTS predicted (production runner) | 1.00011 |
| Candidate B training replays (40449332597 / 40450141708 / 40450801580) | 1.054 / 1.032 / 1.161 |
| Candidate B holdout replays (40451533079 / 40504321590) | 1.273 / 1.044 |
| Measured B5 first three | 1.07 / 1.06 / 1.11 |
| Measured B5 runs 4–5 (outside the gate) | 1.03 / 1.11 |

Plan 27's advisory `ci03_expectation` was **EXPECTED_MISS**. The measured CI-03 verdict is MISS, so the expectation is confirmed at the verdict level. That is not a plan failure. The mechanism differs from the prediction, though. The expected min-lane miss did not occur: all three min ratios pass after the fixture isolation and candidate B weights. The miss is on the current lane instead, which passed on B4 (1.12 / 1.11 / 1.12). The current weights, runner, async factor and N are unchanged since B4. The current-lane inputs did change: 136bb932 put a new colocation group of the four export-root files into one partition and flipped `storage/local_test.exs` to `async: false`. A read-only local runner assignment (`MIX_BIN=false`, lane current) puts that colocation group in partition 3 and `deps_audit_gate_test.exs` in partition 2, while partition 4 is the measured slow side. The artifacts do not establish the cause of the current-lane spread.

CI-01 and CI-04 continuity: every selected run has unexpired `browser-timings-desktop-chromium-<run>`, `browser-timings-mobile-chromium-<run>` and `partition-timings-{current,min,latest}-<run>` artifacts (10 artifacts per run). `git diff --quiet 02d115a32e4479f353d284c04fc838ba58938d16 824c28517820c1cd6595f2e0e60b34ec3ce64d14 -- test/support/partition_monitor.ex bin/ci-test-partitions .github/workflows/ci.yml` exits 0, so the monitor, runner and workflow are byte-identical to the B4 squash where CI-04 was verified.

### Remaining gap (maintainer scope question)

CI-02 now passes on fresh same-head main evidence, at 457 s. CI-03 remains unmet. Two of the nine first-three ratios exceed 1.15, both on the current lane (1.17, 1.17), while min and latest pass. Plan 27 named the D-11 split of `test/threadline/deps_audit_gate_test.exs` into two module files as the next candidate, and it stays named here without being implemented. That split was aimed at the min-lane async floor, which this cohort no longer shows. So the maintainer's scope question is which candidate addresses the current-lane spread: that split, a current-lane weight refresh from B5 timings that accounts for the 136bb932 colocation group, or both. Any choice needs its own sampling budget. Per D-25, nothing is re-sampled, no threshold changes and no further cohort is planned here.

<!-- B5-GATE-JSON-BEGIN -->
{
  "schema": "threadline.phase247-b5-gate/1",
  "squash_sha": "824c28517820c1cd6595f2e0e60b34ec3ce64d14",
  "state": "measured",
  "runs": [
    {
      "id": 40692111621,
      "event": "push",
      "head_sha": "824c28517820c1cd6595f2e0e60b34ec3ce64d14",
      "wall_s": 449
    },
    {
      "id": 40693451272,
      "event": "workflow_dispatch",
      "head_sha": "824c28517820c1cd6595f2e0e60b34ec3ce64d14",
      "wall_s": 457
    },
    {
      "id": 40694602284,
      "event": "workflow_dispatch",
      "head_sha": "824c28517820c1cd6595f2e0e60b34ec3ce64d14",
      "wall_s": 450
    },
    {
      "id": 40695763585,
      "event": "workflow_dispatch",
      "head_sha": "824c28517820c1cd6595f2e0e60b34ec3ce64d14",
      "wall_s": 461
    },
    {
      "id": 40696978392,
      "event": "workflow_dispatch",
      "head_sha": "824c28517820c1cd6595f2e0e60b34ec3ce64d14",
      "wall_s": 589
    }
  ],
  "median_wall_s": 457,
  "first_three_ratios": {
    "current": [
      1.17,
      1.17,
      1.09
    ],
    "min": [
      1.07,
      1.06,
      1.11
    ],
    "latest": [
      1.08,
      1.09,
      1.06
    ]
  },
  "excluded": [],
  "ci02_verdict": "PASS",
  "ci03_verdict": "MISS",
  "continuity": {
    "ci01_browser_timings_all_runs": true,
    "ci04_monitor_runner_workflow_unchanged_since_b4": true,
    "partition_timings_all_runs": true
  },
  "ci03_expectation": "EXPECTED_MISS",
  "follow_up": "The named next candidate is the D-11 split of test/threadline/deps_audit_gate_test.exs into two module files (not implemented here); because the measured CI-03 miss is on the current lane, where that file is predicted in partition 2 while partition 4 is slowest, the maintainer scope question should also weigh a current-lane weight refresh after the 136bb932 colocation change."
}
<!-- B5-GATE-JSON-END -->
