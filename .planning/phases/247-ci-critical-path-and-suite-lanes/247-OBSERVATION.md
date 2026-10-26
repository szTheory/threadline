# Phase 247 — Main CI observation after Land B1

Read-only reading of the first three `ci.yml` runs on main at the B1 squash
`3463fa7416696578faa8a9933de0900e61dc9d48` (roadmap SC1, D-02 step 2), plus the D-16(c)
throwaway hang reproduction. Every number below comes from the GitHub API or from run
artifacts; nothing was dispatched, pushed or deleted while reading.

Sources:

- `bin/measure-main-ci --since 3463fa7416696578faa8a9933de0900e61dc9d48 --count 3 --ratios --format json`
  → `state: measured`, `found: 3`, `excluded: []`, `median_wall_s: 764`. With gh 2.101 the
  script's job-log read needed a read-only shim that adds `--allow-escape-sequences` to
  `gh api` (passed via the script's `GH_BIN` seam; see "Tooling note" at the end).
- Artifacts per run: `browser-timings-all-<run>`, `partition-timings-{min,current,latest}-<run>`.
- Browser job step timings: `gh api repos/{owner}/{repo}/actions/jobs/<job>` (`steps[]`).
- Repro logs: `gh api --allow-escape-sequences repos/{owner}/{repo}/actions/jobs/<job>/logs`, ANSI-stripped.

## Runs read

All three are attempt 1, conclusion `success`, head `3463fa74` (the B1 squash).

| Run | Event | Wall s | Browser job s | Playwright step s | Slowest job |
|-----|-------|-------:|--------------:|------------------:|-------------|
| 40394247390 | push | 777 | 767 | 700 | Example app browser E2E (2 projects), 767 s |
| 40396194471 | workflow_dispatch | 764 | 754 | 692 | Example app browser E2E (2 projects), 754 s |
| 40398138085 | workflow_dispatch | 756 | 747 | 690 | Example app browser E2E (2 projects), 747 s |

Median wall **764 s (12.7 min)**. The browser job is the critical path on every run. The next
slowest jobs are `Build and test (current)` (425 / 452 / 332 s) and `Build and test (min)`
(211 / 251 / 251 s). `Build and test (latest)` took 174 / 182 / 245 s. Everything else is
under 170 s, and `CI required` is 3 s.

Browser job ids: 121822941455, 121829780764, 121836562087. In all three, the job outside the
`Run example Playwright suite` step took 67 / 62 / 57 s: setup with every cache hit,
`Initialize containers` 21–25 s, and the post-steps.

## CI-01 slowest browser specs

Each run's `browser-timings-all-<run>` JSON has `top | length` = **20** (SC1: at least 20
slowest specs with durations), 47 per-project file rows, 418 executed tests (213 desktop,
205 mobile), and 0 retried rows in the top 20. Playwright runs with `workers: 1`, so the
per-test durations add up to the serial wall.

### Top 20, run 40398138085 (latest)

| # | Project | File | Test (truncated) | s |
|--:|---------|------|------------------|--:|
| 1 | desktop-chromium | operator-component-contracts.spec.ts | Phase 177 UAT #1 — group catalog holds together at every viewport › every registered group story… | 30.5 |
| 2 | mobile-chromium | operator-component-contracts.spec.ts | Phase 177 UAT #1 — group catalog holds together at every viewport › every registered group story… | 30.1 |
| 3 | mobile-chromium | operator-screenshots.spec.ts | operator surface screenshots › admin investigation and governance surfaces | 11.4 |
| 4 | desktop-chromium | operator-accessibility.spec.ts | operator accessibility baseline › preserves modal and drawer Escape focus through repeated… | 7.1 |
| 5 | mobile-chromium | operator-responsive-mobile-first.spec.ts | operator responsive matrix: phone › keeps every operator route usable without root horizontal… | 7.1 |
| 6 | mobile-chromium | operator-accessibility.spec.ts | operator accessibility baseline › keeps export and retention journeys readable across them… | 6.8 |
| 7 | desktop-chromium | operator-accessibility.spec.ts | operator accessibility baseline › closes the focused menu before its drawer and recovers focus… | 6.6 |
| 8 | desktop-chromium | operator-accessibility.spec.ts | operator accessibility baseline › keeps export and retention journeys readable across them… | 6.6 |
| 9 | mobile-chromium | operator-accessibility.spec.ts | operator accessibility baseline › preserves modal and drawer Escape focus through repeated… | 6.5 |
| 10 | mobile-chromium | operator-accessibility.spec.ts | operator accessibility baseline › closes the focused menu before its drawer and recovers focus… | 6.4 |
| 11 | mobile-chromium | operator-home-nav-mobile.spec.ts | operator Home orientation mobile UAT › header destinations stay reachable from representative… | 6.3 |
| 12 | desktop-chromium | operator-responsive-mobile-first.spec.ts | operator responsive matrix: phone › keeps every operator route usable without root horizontal… | 5.9 |
| 13 | mobile-chromium | operator-responsive-mobile-first.spec.ts | operator responsive matrix: desktop-1024 › keeps every operator route usable… | 5.6 |
| 14 | mobile-chromium | operator-responsive-mobile-first.spec.ts | operator responsive matrix: desktop › keeps every operator route usable… | 5.6 |
| 15 | mobile-chromium | operator-responsive-mobile-first.spec.ts | operator responsive matrix: tablet › keeps every operator route usable… | 5.6 |
| 16 | desktop-chromium | operator-home-nav-mobile.spec.ts | operator Home orientation mobile UAT › header destinations stay reachable from representative… | 5.5 |
| 17 | desktop-chromium | operator-screenshots.spec.ts | operator surface screenshots › admin investigation and governance surfaces | 5.3 |
| 18 | desktop-chromium | operator-responsive-mobile-first.spec.ts | operator responsive matrix: desktop › keeps every operator route usable… | 4.8 |
| 19 | desktop-chromium | operator-responsive-mobile-first.spec.ts | operator responsive matrix: desktop-1024 › keeps every operator route usable… | 4.8 |
| 20 | desktop-chromium | operator-responsive-mobile-first.spec.ts | operator responsive matrix: tablet › keeps every operator route usable… | 4.7 |

### Per-project totals

| Run | mobile-chromium s (tests) | desktop-chromium s (tests) | Attributed total s | Unattributed s | Playwright wall s (= total + unattributed) |
|-----|--------------------------:|---------------------------:|-------------------:|---------------:|-------------------------------------------:|
| 40394247390 | 334.6 (205) | 325.5 (213) | 660.1 | 15.9 | 676.0 |
| 40396194471 | 332.4 (205) | 320.7 (213) | 653.1 | 15.8 | 668.8 |
| 40398138085 | 333.8 (205) | 317.1 (213) | 650.9 | 16.8 | 667.6 |
| **mean** | **333.6** | **321.1** | **654.7** | **16.2** | **670.8** |

Desktop/mobile share of the attributed time: **mobile 50.95 %, desktop 49.05 %**. The test
counts (205 vs 213) point the other way from the time, which matches CONTEXT's warning that
counts understate imbalance. Here the imbalance is small, though.

"Unattributed" is the slow-specs definition: the reporter's `stats.duration` minus the summed
results. It is worker boot, global setup and inter-test gaps. The Playwright step itself is a
further 23.2 s longer on average (694.0 − 670.8). That is `run-e2e.sh` compiling the example
app and booting the server.

### Per-file top 15 (mean of 3 runs, per project)

| Project | File | Tests | Mean s |
|---------|------|------:|-------:|
| desktop-chromium | operator-accessibility.spec.ts | 18 | 56.6 |
| mobile-chromium | operator-accessibility.spec.ts | 18 | 55.9 |
| mobile-chromium | operator-component-contracts.spec.ts | 7 | 38.3 |
| desktop-chromium | operator-component-contracts.spec.ts | 7 | 37.3 |
| mobile-chromium | operator-responsive-mobile-first.spec.ts | 13 | 34.8 |
| desktop-chromium | operator-responsive-mobile-first.spec.ts | 13 | 29.5 |
| mobile-chromium | operator-timeline-investigation-flow.spec.ts | 15 | 28.1 |
| mobile-chromium | operator-phase-178-uat.spec.ts | 21 | 25.0 |
| desktop-chromium | operator-timeline-investigation-flow.spec.ts | 15 | 24.7 |
| desktop-chromium | operator-route-states.spec.ts | 21 | 19.2 |
| desktop-chromium | operator-phase-178-uat.spec.ts | 21 | 18.4 |
| mobile-chromium | operator-route-states.spec.ts | 20 | 17.3 |
| desktop-chromium | operator-motion.spec.ts | 12 | 16.3 |
| mobile-chromium | operator-screenshots.spec.ts | 2 | 15.0 |
| mobile-chromium | operator-motion.spec.ts | 12 | 14.6 |

Across both projects, the heaviest files are operator-accessibility (112.4 s),
operator-component-contracts (75.7 s), operator-responsive-mobile-first (64.3 s) and
operator-timeline-investigation-flow (52.8 s). No single file dominates a project: the
heaviest is about 17–18 % of its project's time.

## Partition ratios (before refresh)

Partition seconds are the `wall_ms` in each `partition-timings-<lane>-<run>` TSV header
(p1 / p2 / p3 / p4). The ratio is the script's own `| max/min |` row, read by
`bin/measure-main-ci --ratios` (D-12: never parsed from ExUnit summary lines).

| Run | Lane | p1 s | p2 s | p3 s | p4 s | max/min |
|-----|------|-----:|-----:|-----:|-----:|--------:|
| 40394247390 | min | 128.6 | 116.8 | 76.9 | 105.7 | 1.68 |
| 40394247390 | current | 172.0 | 148.7 | 221.5 | 182.7 | 1.49 |
| 40394247390 | latest | 105.2 | 87.6 | 69.0 | 76.0 | 1.52 |
| 40396194471 | min | 178.2 | 156.3 | 124.3 | 148.0 | 1.44 |
| 40396194471 | current | 185.5 | 160.5 | 233.7 | 198.3 | 1.45 |
| 40396194471 | latest | 104.6 | 86.4 | 69.8 | 77.7 | 1.50 |
| 40398138085 | min | 168.5 | 151.6 | 110.4 | 137.9 | 1.54 |
| 40398138085 | current | 113.7 | 103.0 | 153.9 | 137.8 | 1.50 |
| 40398138085 | latest | 172.3 | 142.8 | 109.9 | 125.1 | 1.56 |

Every lane misses the 1.15 target on every run (1.44–1.68), which is the expected
pre-refresh state. The weights still come from the old local `--slowest-modules` data
(CONTEXT `<baseline>`). The fastest partition differs by lane: p3 on min and latest, p2 on
current. Absolute partition times also vary about 1.5× between runs on the same head (the
current lane's file-wall sum is 1465 / 1386 / 971 s), so CI runner noise is large. The
weights refresh has to use medians (D-11), and the ratio claim needs three runs (D-12).

## Elixir 1.15 monitor proof

The D-13 formatter's event tuple shapes work on Elixir 1.15 (OTP 26), on the min lane:

| Run | Context | `Build and test (min)` job | Conclusion | `partition-timings-min-<run>` TSVs |
|-----|---------|----------------------------|------------|------------------------------------:|
| 40392212575 | B1 PR #94, head `525ea1d5` (the run that gated the merge) | 121815845365 | success | 4 (headers `lane=min`, wall 171.9 / 150.8 / 123.3 / 137.4 s) |
| 40387745942 | B1 PR #94, first head `a99dd653` | 121800408825 | success | — |
| 40394247390 | main | 121822941372 | success | 4 |
| 40396194471 | main | 121829781164 | success | 4 |
| 40398138085 | main | 121836561820 | success | 4 |

The repro below shows the other half on the same lane: the monitor names a hung `setup_all`
on Elixir 1.15.8.

## CI-02 split design inputs

Inputs are the 3-run means above. "Leg" means one `Example app browser E2E (<project>)`
matrix job (D-07).

**Fixed per-leg costs.** Each leg pays the full non-test overhead:

- job time outside the Playwright step: mean **62 s** (67 / 62 / 57), all cache hits;
- `run-e2e.sh` compile and server boot inside the step: mean **23.2 s** (694.0 s step − 670.8 s Playwright wall).

**Projected leg Playwright seconds** = project total + its share of the unattributed time
(16.2 s split 50.95 / 49.05):

- mobile-chromium: 333.6 + 0.5095 × 16.2 = **341.8 s**
- desktop-chromium: 321.1 + 0.4905 × 16.2 = **329.0 s**

If each leg pays the whole 16.2 s of worker boot instead (the conservative reading), the legs
are 349.8 s and 337.3 s.

**Projected leg step and job wall:**

- mobile step: 341.8 + 23.2 = **365.0 s**; leg job: 365.0 + 62 = **427.0 s (7.1 min)**. Conservative: 435.0 s.
- desktop step: 329.0 + 23.2 = 352.2 s; leg job: 352.2 + 62 = **414.2 s (6.9 min)**.

**Projected run wall** = max(leg) + fan-in (~20 s, D-07a receipt job) + `CI required` (3 s)
+ scheduling lag (~7 s: run wall minus browser job minus `CI required` is
777−767−3, 764−754−3, 756−747−3 = 7 / 7 / 6 s):
427.0 + 20 + 3 + 7 = **457 s ≈ 7.6 min**. Conservative: 435.0 + 30 = 465 s ≈ 7.8 min.
That clears the 9-minute target by ~75–85 s. The non-browser jobs set the next critical
path: `Build and test (current)` at 332–452 s, below every projected leg.

**Imbalance bands (CONTEXT `<specifics>`).** The observed split is **51 / 49**, so neither
risk band applies. For reference, on this data: 60 / 40 would make the heavy leg
0.60 × 670.8 + 23.2 + 62 = 487.7 s, run ≈ 517.7 s (8.6 min, passes barely); 65 / 35 would make
it 521.2 s, run ≈ 551 s (9.2 min, misses). The D-08 fallback (2-way shard of the dominant
project) is not indicated by this data.

The CONTEXT projection (~377 s Playwright per leg) is about 35 s high. The measured
whole-suite Playwright wall is now 670.8 s (418 executed tests), against the 12.1 min in the
CONTEXT baseline run.

**Provisional per-leg timeouts (D-07c, D-16 budget style: step < job, so the
failure-diagnostics upload survives a step timeout):**

| Bound | Value | Arithmetic |
|-------|------:|------------|
| Slowest projected leg step | 365.0 s | above (conservative 373.0 s) |
| Worst-case leg step | 389 s | worst browser job in the CONTEXT baseline, 802 s: (802 − 62 − 23.2) × 0.5095 + 23.2 |
| `Run example Playwright suite` step `timeout-minutes` | **9** (540 s) | 540 / 365.0 = 1.48×; 540 / 389 = 1.39× the worst case |
| Leg job `timeout-minutes` | **12** (720 s) | 540 s step + 62 s setup + ~60 s upload margin = 662 s < 720 s; 720 / 427.0 = 1.69× the projected leg |
| Fan-in job `timeout-minutes` | 5 | D-07a/D-07c, unchanged |

A strict "2× the slowest leg" rule would give a step of 2 × 365 s = 730 s, i.e. 12 min and a
15 min job. The data supports the 9 / 12 default instead. It keeps more headroom than today's
monolithic step (14 min against a 694 s mean = 1.21×), and a hung leg fails within 9 min
instead of 12. 247-10 should keep 9 / 12 and re-read the first post-split runs (D-08). If any
leg step goes above 450 s (83 % of the step budget), raise the step to 10 min and the job to
13 min, rather than letting the timeout become the flake.

## Weights refresh inputs

Artifacts for 247-12 (`bin/ci-test-partitions --ingest-weights`, current lane, per-file median
over 3 runs, D-11):

- `partition-timings-current-40394247390`
- `partition-timings-current-40396194471`
- `partition-timings-current-40398138085`

Each holds 4 TSVs (`partition-timings-1.tsv` … `-4.tsv`) with `lane=current` headers and
269 file rows in total. The `min` / `latest` artifacts with the same run ids also exist, but
they are only needed if those lanes still miss 1.15 after the refresh (D-11 "per-lane weights
only if").

**`stress_router_test.exs` against the even share (current lane):**

| Run | Sum of current-lane file walls s | Even share (sum / 4) s | `stress_router_test.exs` wall s | % of share |
|-----|---------------------------------:|-----------------------:|--------------------------------:|-----------:|
| 40394247390 | 1464.7 | 366.2 | 77.0 | 21 % |
| 40396194471 | 1386.3 | 346.6 | 74.5 | 21 % |
| 40398138085 | 971.3 | 242.8 | 47.6 | 20 % |
| **mean** | 1274.1 | 318.5 | **66.4** | **21 %** |

`stress_router_test.exs` does **not** exceed an even partition share, so the D-11 split-by-module
contingency is not triggered. Its committed weight is 47508 ms, against a 66.4 s CI mean. The
heaviest current-lane files on CI are `deps_audit_gate_test.exs` (114.8 / 139.4 / 84.3 s),
`browser_full_projects_contract_test.exs` (88.5 / 98.8 / 57.5 s),
`stress_router_prod_compile_test.exs` (65.6 / 85.8 / 56.2 s, committed weight 26460 ms, so it
is ~2.6× under-weighted) and `stress_router_test.exs`. All are below the even share, but a
greedy pack must not put two of them in one partition. The ingest's "> 2× moved" report should
flag `stress_router_prod_compile_test.exs`.

## D-16(c) PR #89 shape reproduction

| Field | Value |
|-------|-------|
| Branch | `throwaway/247-hang-repro`, commit `e1c2a3f0` (cut from the first B1 head `a99dd653`; never a PR, never merged; deleted from origin after the run) |
| Fixture | `test/threadline/zz_hang_repro_test.exs`: `Threadline.ZzHangReproTest`, `async: false`, `setup_all` → `Process.sleep(:infinity)`, one trivial test, no tag, weights row `1000` |
| Run | **40387548421** (`workflow_dispatch`, attempt 1, conclusion `failure`), started 19:31:48Z, updated 19:44:42Z |
| `Build and test (min)` job | **121799736736**, OTP 26 / Elixir 1.15.8, conclusion **`failure`** |
| Min-lane job duration | 19:31:52Z → 19:40:37Z = **525 s (8 min 45 s)**, well under the 20-minute job timeout and under the ~10 min expectation |
| `Run mix verify.test_partitioned` step | 19:33:00Z → 19:40:32Z (452 s): `** (Mix) verify.test_partitioned failed (1)`, `##[error]Process completed with exit code 1.` |
| Exit path that fired | **The in-VM D-13 monitor (the designed path).** The partition exit is `1`, not `124`. The monitor halted at its deadline `450000 ms` (budget 480 s − 30 s) of VM wall time, about 30 s before the D-14 bash watchdog would have fired. No `exceeded budget` / `status=124` line appears |

Partition report row (min lane, verbatim):

```
| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 59 | 591 tests, 0 failures |
| 2 | 1 | 450 | no tests |
| 3 | 0 | 58 | 601 tests, 0 failures |
| 4 | 0 | 96 | 744 tests, 0 failures |
| total | - | 452 | - |
| max/min | - | 7.76 | - |
```

`HANG:` block from the min-lane log, verbatim, with the timestamps cut (partition 2 output):

```
----- HANG: in-flight: (deadline 450000 ms, VM wall 450001 ms) -----
  test/threadline/zz_hang_repro_test.exs Threadline.ZzHangReproTest (setup_all)
----- HANG: processes -----
...
#PID<0.2497.0> status=waiting message_queue_len=0
    (elixir 1.15.8) lib/process.ex:303: Process.sleep/1
    test/threadline/zz_hang_repro_test.exs:1: Threadline.ZzHangReproTest.__ex_unit__/2
    (ex_unit 1.15.8) lib/ex_unit/runner.ex:313: anonymous fn/3 in ExUnit.Runner.run_setup_all/2
...
----- HANG: end -----
```

The block names the module with `(setup_all)` and is followed by the hung process's stack:
`Process.sleep/1`, the fixture frame and `ExUnit.Runner.run_setup_all/2`. The script's
"no test count found; last log lines" excerpt above the table repeats the stack frames, so the
step summary also carries the name.

The same fixture ran on the other lanes in the same run, with the same path:

- `Build and test (current)` job 121799736257: 526 s, failure, partition 2 exit `1` at 450 s, the same `HANG: in-flight:` line naming the module with `(setup_all)`.
- `Build and test (latest)` job 121799736024: 526 s, failure, partition 2 exit `1` at 450 s, the same line. Partition 3 there also had `1 failures`: `partition_monitor_test.exs:86`, the Elixir 1.19+ summary-format bug that `f839f116` / `525ea1d5` fixed after the repro branch was cut. It is unrelated to the repro.

**The original evidence is partly gone.** The PR #89 attempt-1 log (run 40137607358, job
121002346075) cannot be recovered (`BlobNotFound`), so this is a synthetic reproduction of the
hang's shape, not a replay of that log. What survives of PR #89, per CONTEXT `<baseline>`: the
hang was on the min lane (OTP 26.2.5 / Elixir 1.15.8). The step started at 22:14:24, and the
job hit its 20-minute timeout at 22:33:17 (annotation "The job has exceeded the maximum
execution time of 20m0s"), then completed at 22:38:17 after the 5-minute cancel grace. It
finished red after 24 minutes with no test named. The same shape now finishes red in 8 min 45 s
and names the module and its stack.

**For VERIFICATION (SC4):** Roadmap SC4's "reproduced against the PR #89 evidence" is met by a
synthetic reproduction of the PR #89 shape: an untagged, weighted `setup_all` that calls
`Process.sleep(:infinity)` on the min lane (run 40387548421, job 121799736736). It turned
`Build and test (min)` red with exit 1 in 525 s, and the log named
`Threadline.ZzHangReproTest (setup_all)` with its stack. That result was checked against the
PR #89 evidence that survives (the min lane, the 20-minute timeout annotation and the
22:14:24 → 22:33:17 step timings), because the attempt-1 log itself is unrecoverable.

## Tooling note

On gh 2.101, `gh api …/actions/jobs/<id>/logs` refuses to print a response that contains
terminal escape sequences unless `--allow-escape-sequences` is passed. CI job logs always
contain them. `bin/measure-main-ci --ratios` therefore exits 1 on this gh version. The reading
above used a read-only `GH_BIN` shim that adds the flag. Logged in `deferred-items.md` for the
plan that next runs the script (247-12 / 247-13).
