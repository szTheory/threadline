# Phase 247 — Gate measurement on main after Land B2

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

## Verdicts

| Gate | Requirement | Threshold | Measured | Verdict |
|------|-------------|-----------|----------|---------|
| D-08 median ci.yml wall, 5 runs | CI-02 | ≤ 540 s | 468 s | **PASS** |
| D-12 partition max/min, 3 runs per lane | CI-03 | ≤ 1.15 on every run of every lane | current 1.20–1.42, latest 1.43–1.58, min 1.57–1.61 | **MISS** |

## CI-02 median

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

## CI-03 partition ratios

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

## Receipt across merged results

PR run `40412545694` on the land head `e85195da`: all 17 checks green, including
`Example app browser E2E (desktop-chromium)`, `Example app browser E2E (mobile-chromium)`,
`Browser journey receipt` and `CI required`. The receipt job downloaded the four leg artifacts
(`operator-ci-executed-{desktop,mobile}-chromium-40412545694` and
`operator-ci-discovered-{desktop,mobile}-chromium-40412545694`) with the existing permissions,
with no 403 (RESEARCH A1 did not trigger). Its log reads
`Validated 31 named journeys across desktop-chromium, mobile-chromium.` The receipt artifact
`operator-ci-evidence-40412545694` exists. Each of the 5 main runs above also ran
`Browser journey receipt` green.

## Branch protection

`bin/verify-branch-protection` (read-only), after the merge:

```
OK: required contexts are exactly [CI required@15368]
Branch protection OK for szTheory/threadline@main: required contexts are exactly [CI required@15368], that name has been emitted 5 time(s) on head 29abf5653a0e1c31b70d73d71a3f6c552d9b9712, and no classic protection is stacking.
```

`CI required` is still the single required context.

## Miss

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
