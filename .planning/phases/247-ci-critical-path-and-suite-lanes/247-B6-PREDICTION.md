# Phase 247 B6 tail-queue prediction (Plan 32, D-29/D-31)

This record holds the D-29 pre-registration for the B6 tail-queue cohort and its gate verdict. It was committed before anything was pushed. Plan 33 reads it.

**Gate: FAIL.** Component (a), the replay, is false: the worst 8 s/claim replay is above 1.08 on the min lane (1.101) and on the latest lane (1.107). Component (b), the CI-02 margin, is true, with a predicted median of 491.8 s against the 510 s ceiling. Under P7 there is no push, no PR and no cohort. `247-B6-ESCALATION.md` (stage `prediction`, 0 hosted runs) records the escalation, and Plan 33 halts at its precondition.

## Pre-registration

- `pre_registration_commit` is 6a1e8a16b3ba550d225e4c42036448ea2631dab0. That is the last commit that touched `247-32-PLAN.md` before Task 1 began, and it holds the TQ-PREREG block (P1–P10). `pre_registered_rule` below is that block verbatim, and it still equals the block in the current plan.
- No other K, overhead, run subset, model term, weight or colocation was tried. Before the full run there was exactly one replay number: the Task 1 tracer (current lane, run 40692111621, 8 s), which the plan requires. After that, `replay` ran once at 8000 ms and once at 4000 ms over every lane and run, and `predict` computed the verdict from those two outputs.
- Tool: `tools/tail_queue_replay.py` (`tool_sha256` below; committed in b25c3c29). Runner: `bin/ci-test-partitions` (`runner_sha256` below, the same bytes as the 247-B6-LOCAL.md head). K = 12 (`TAIL_QUEUE_K`) and `ASYNC_FACTOR_PERMILLE` = 292 are both read from the runner.

## Inputs

- 14 main runs. B3 has 5, B4 has 4 and B5 has 5, giving 42 run/lane artifacts and 168 TSVs. None is unavailable: every artifact is unexpired until 2026-11-10/11.
- All 42 artifact zips match their API `digest`. 84 TSVs (B3 runs 1–3 and B4 runs 1–4, all lanes) match `247-FROZEN-REPLAY.json`, which itself matches `FROZEN_REPLAY_SHA256`. All 168 match `PINNED_TSV_SHA256` in the tool, and their hashes are in `tsv_sha256` below.
- The replayed assignment is the runner's own, from a temporary copy with `MIX_BIN=false`. Every lane queues exactly 12 files, out of 269 on current and 206 on min and latest (toolchain scope). The three queues differ in their tail, but all of them include `public_surface_contract_test`, both `stress_router` files and `partition_monitor_test`. No inventory file was unobserved in any run.

## Replay per lane and run

Ratios are max/min partition time. Boot is included in every partition time (P3, R3-IN-05). "Static" is the calibration replay with `CI_TEST_PARTITIONS_TAIL_K=0`. "Measured" is the job-log `| max/min |` value from the committed cohort record.

| Lane | Run | Cohort | Queue 8 s | Queue 4 s | Static | Measured |
|---|---|---|---|---|---|---|
| current | 40433193088 | B3 | 1.052107 | 1.029482 | 1.028547 | 1.13 |
| current | 40434036118 | B3 | 1.051658 | 1.033665 | 1.209923 | 1.24 |
| current | 40434884357 | B3 | 1.059218 | 1.049015 | 1.139862 | 1.15 |
| current | 40436597341 | B3 | 1.036414 | 1.036172 | 1.152365 | 1.19 |
| current | 40437416932 | B3 | 1.061635 | 1.044002 | 1.160857 | 1.19 |
| current | 40449332597 | B4 | 1.046831 | 1.025541 | 1.152526 | 1.12 |
| current | 40450141708 | B4 | 1.063714 | 1.031485 | 1.109564 | 1.11 |
| current | 40450801580 | B4 | 1.054291 | 1.029320 | 1.089055 | 1.12 |
| current | 40451533079 | B4 | 1.063412 | 1.047469 | 1.179294 | 1.12 |
| current | 40692111621 | B5 | 1.050945 | 1.036461 | 1.038946 | 1.17 |
| current | 40693451272 | B5 | 1.059550 | 1.037620 | 1.132943 | 1.17 |
| current | 40694602284 | B5 | 1.025533 | 1.036008 | 1.128476 | 1.09 |
| current | 40695763585 | B5 | 1.052747 | 1.035158 | 1.117058 | 1.17 |
| current | 40696978392 | B5 | 1.046298 | 1.028135 | 1.071175 | 1.16 |
| min | 40433193088 | B3 | 1.074716 | 1.049936 | 1.196155 | 1.36 |
| min | 40434036118 | B3 | 1.074680 | 1.024045 | 1.206129 | 1.35 |
| min | 40434884357 | B3 | 1.071317 | 1.049254 | 1.277516 | 1.28 |
| min | 40436597341 | B3 | 1.078586 | 1.054005 | 1.172254 | 1.37 |
| min | 40437416932 | B3 | 1.071038 | 1.043420 | 1.190516 | 1.33 |
| min | 40449332597 | B4 | 1.041739 | 1.029809 | 1.052698 | 1.24 |
| min | 40450141708 | B4 | 1.023058 | 1.049799 | 1.030934 | 1.28 |
| min | 40450801580 | B4 | 1.101163 | 1.068672 | 1.156632 | 1.27 |
| min | 40451533079 | B4 | 1.038325 | 1.041733 | 1.267682 | 1.25 |
| min | 40692111621 | B5 | 1.052433 | 1.045510 | 1.109191 | 1.07 |
| min | 40693451272 | B5 | 1.075704 | 1.041801 | 1.089157 | 1.06 |
| min | 40694602284 | B5 | 1.077597 | 1.061939 | 1.088752 | 1.11 |
| min | 40695763585 | B5 | 1.078432 | 1.042286 | 1.091866 | 1.03 |
| min | 40696978392 | B5 | 1.060010 | 1.063275 | 1.087860 | 1.11 |
| latest | 40433193088 | B3 | 1.068143 | 1.020470 | 1.321384 | 1.36 |
| latest | 40434036118 | B3 | 1.032544 | 1.048885 | 1.101435 | 1.30 |
| latest | 40434884357 | B3 | 1.053250 | 1.044022 | 1.042824 | 1.30 |
| latest | 40436597341 | B3 | 1.106776 | 1.094006 | 1.104405 | 1.26 |
| latest | 40437416932 | B3 | 1.068243 | 1.059585 | 1.247915 | 1.38 |
| latest | 40449332597 | B4 | 1.106514 | 1.085832 | 1.183431 | 1.10 |
| latest | 40450141708 | B4 | 1.074021 | 1.073667 | 1.148872 | 1.04 |
| latest | 40450801580 | B4 | 1.055634 | 1.062181 | 1.295507 | 1.12 |
| latest | 40451533079 | B4 | 1.044859 | 1.030090 | 1.146027 | 1.06 |
| latest | 40692111621 | B5 | 1.099813 | 1.034336 | 1.158329 | 1.08 |
| latest | 40693451272 | B5 | 1.076557 | 1.026526 | 1.201388 | 1.09 |
| latest | 40694602284 | B5 | 1.058769 | 1.065929 | 1.062462 | 1.06 |
| latest | 40695763585 | B5 | 1.086137 | 1.097786 | 1.093220 | 1.09 |
| latest | 40696978392 | B5 | 1.067757 | 1.066358 | 1.172342 | 1.09 |

| Lane | Worst at 8 s (gate) | Worst at 4 s (information) | Runs above 1.08 at 8 s |
|---|---|---|---|
| current | 1.063714 | 1.049015 | none |
| min | 1.101163 | 1.068672 | 40450801580 (B4) 1.101163 |
| latest | 1.106776 | 1.097786 | 40436597341 (B3) 1.106776; 40449332597 (B4) 1.106514; 40692111621 (B5) 1.099813; 40695763585 (B5) 1.086137 |

The queue does what D-27 designed it for on the current lane: every current replay is ≤ 1.064 at 8 s per claim, against measured B5 ratios of 1.09–1.17. On min and latest, though, the 8 s/claim overhead itself becomes the imbalance. Their partitions are shorter. The median slowest static partition is about 141 s on min and 143 s on latest, against 195 s on current. So 12 claims at 8 s each are a larger share of each partition, and the granularity of the last claims matters more. That is why the 4 s replays are lower there. The research reported latest-lane replays up to 1.092 across 4–8 s, and the disclosure said this gate could fail. It did.

## The model's own error

The static replay against the measured ratio shows how far to trust the model:

- **B5** ran with today's weight files, so its static replay is the closest like-for-like comparison. The test tree has changed slightly since B5 (Plans 29–31), so the assignment is close to B5's, not proven identical.
  - On the current lane the static replay minus measured is −0.131, −0.037, +0.038, −0.053 and −0.089. The model is optimistic there, which matches the +15.5 s unexplained residual on the `stress_router` partition reported in 247-B6-REMEDY-RESEARCH.md.
  - On min it is +0.039, +0.029, −0.021, +0.062 and −0.022.
  - On latest it is +0.078, +0.111, +0.002, +0.003 and +0.082. The model is pessimistic there.
- **B3 and B4** measured ratios come from earlier weight files and test trees, so they belong to different assignments. For those runs the static and measured columns compare different assignments, not model error alone.
- **Error band.** The model's error on one run is about ±0.05–0.13, as large as the gap between the gate (1.08) and the CI-03 limit (1.15). So the replay is an expectation, not an acceptance measurement (D-21/D-24). Only a cohort decides CI-03, and the pre-registered gate decides whether a cohort may run. It may not.

## CI-02 prediction (P10)

- `slowest_partition_delta_s` = +19.837 s. This is the median over the five B5 current-lane runs of the queue replay's slowest partition minus the static replay's slowest partition, at 8 s per claim. The per-run deltas are +22.98, +17.45, +17.05, +19.84 and +21.54 s.
- `self_test_delta_s` = 15 s. This is the larger of head_env − baseline_env (46 − 31) and head_bin_bash − baseline_bin_bash (46 − 33), from 247-B6-LOCAL.md.
- `predicted_ci02_median_s` = 457 + 19.837 + 15 = 491.8 s. That is ≤ 510, so gate component (b) holds, and it is ≤ 540, so `ci02_expectation` is EXPECTED_PASS (advisory). CI-02 itself stays decided by B5's measured 457 s median. No B6 cohort will run.

## Other facts on record

- **Local overheads are informational only, and they decide nothing.** From 247-B6-LOCAL.md, the mean per-claim overhead was 2526.3 ms on the current lane (three runs: 3726, 1447 and 2406 ms), 1955 ms on min and 1120 ms on latest. The gate assumes 8000 ms. That figure comes from the research and was fixed before any of these numbers existed.
- **Protocol facts from the research.** The current-lane ratio SD is about 0.035 per run (B5). At a measured mean of 1.10, all of three runs pass ≤ 1.15 about 86% of the time.
- **Preflight criteria (P8) and stop rule (P9)** are recorded for completeness. Neither is reached on a gate FAIL. `tail_queue_replay.py preflight --run <id>` is the committed GO/NO_GO evaluator: attempt 1 must succeed, every lane's `| max/min |` must be ≤ 1.10, each lane's claim lines must equal `queued`, and the pooled mean claim overhead must be ≤ 8000 ms.

## Record

<!-- B6-PREDICTION-JSON-BEGIN -->
{
  "assignment_sha256": {
    "current": "542fbb543594050e2c4f0ca84774f7cc1dbae3d91e9f19deb601af3282fc45f0",
    "latest": "14bd1d4a0fa197a01275663baeb6c36fd670ba4fe40ad8d54fc7d5497ad9a6ee",
    "min": "a2410d3b047a16f00b3021d609bd53e058f7ec5899e8b10f0c775de0556aeaf3"
  },
  "ci02_prediction": {
    "b5_median_s": 457,
    "ci02_expectation": "EXPECTED_PASS",
    "predicted_ci02_median_s": 491.8,
    "self_test_delta_s": 15,
    "slowest_partition_delta_s": 19.837
  },
  "ci03_expectation": "EXPECTED_MISS",
  "cohorts": {
    "B3": [
      40433193088,
      40434036118,
      40434884357,
      40436597341,
      40437416932
    ],
    "B4": [
      40449332597,
      40450141708,
      40450801580,
      40451533079
    ],
    "B5": [
      40692111621,
      40693451272,
      40694602284,
      40695763585,
      40696978392
    ]
  },
  "factor_permille": 292,
  "gate": "FAIL",
  "gate_components": {
    "ci02_predicted_le_510": true,
    "replay_worst_le_1_08": false
  },
  "k": 12,
  "local_overhead_ms": {
    "current": 2526.3,
    "latest": 1120.0,
    "min": 1955.0
  },
  "overhead_gate_ms": 8000,
  "overhead_info_ms": 4000,
  "pre_registered_rule": "P1 Runner and K. The replayed assignment is the one that `bin/ci-test-partitions` at Plan 32's HEAD produces (its sha256 is recorded as runner_sha256). It is run in a temporary copy with MIX_BIN=false, N=4, THREADLINE_CI_LANE=<lane>, and THREADLINE_TEST_SCOPE=toolchain for min and latest. K is that runner's TAIL_QUEUE_K (12). The replay reads the runner's static sets (partition-<i>.files) and tail-queue.tsv in claim order; it never reimplements assignment or lifting. A second assignment with CI_TEST_PARTITIONS_TAIL_K=0 gives a static replay used for calibration only.\nP2 Inputs. Lanes: current, min, latest. Runs: B3 40433193088 40434036118 40434884357 40436597341 40437416932; B4 40449332597 40450141708 40450801580 40451533079; B5 40692111621 40693451272 40694602284 40695763585 40696978392. For each run and lane, the input is the four TSVs of artifact partition-timings-<lane>-<run>. TSVs pinned in 247-FROZEN-REPLAY.json must match it. Every artifact zip whose API listing carries a digest must match that digest. All TSV sha256 values are pinned in the tool (PINNED_TSV_SHA256) and in the prediction. A run and lane that is expired, missing or fails validation is listed as unavailable and never substituted.\nP3 Static time. For run r and partition p: T_p = boot_r + S + max(D, L) over p's static files. S, A and L use r's observed per-file wall_ms; a file that r did not observe uses its raw lane weight and is counted as unobserved. D = floor(A * ASYNC_FACTOR_PERMILLE / 1000), at least 1 when A > 0, with the factor read from the runner. boot_r is the lower middle of r's four sorted header boot_ms values.\nP4 Queue. Claims are taken in tail-queue order. Each claim goes to the partition with the smallest current T (ties go to the lowest partition number) and adds the file's observed wall_ms (or its raw lane weight if unobserved) plus overhead_ms.\nP5 Ratio. ratio_r = max_p T_p / min_p T_p over all four partitions. A partition with no static file and no claim makes the replay fail; it never drops out.\nP6 Gate. overhead_ms = 8000. The gate has two components and is PASS if and only if both hold. (a) Replay: for every lane, every available run's ratio is <= 1.08, and every lane has at least one available run in B4 and at least one in B5. (b) CI-02 margin: predicted_ci02_median_s from P10 is <= 510. overhead_ms = 4000 is reported alongside, for information only. ci03_expectation = EXPECTED_PASS if and only if component (a) holds; otherwise EXPECTED_MISS.\nP7 Consequence. On gate FAIL (either component): no push, no PR and no cohort; 247-B6-ESCALATION.md (stage prediction) records it (D-30). On gate PASS: Plan 33 proceeds to the landing PR.\nP8 Preflight. `tail_queue_replay.py preflight --run <id>` evaluates attempt 1 of the landing PR's ci.yml run. It is GO if and only if all of these hold: the run concluded success; each of Build and test (current), (min) and (latest) logs a `| max/min |` value <= 1.10; each lane's claim-line count equals the queued count on its `tail queue K=12 queued=<q>` line; and the pooled mean of overhead_ms over every claim line of the three lanes is <= 8000. Otherwise it is NO_GO. On NO_GO: no merge, no cohort, and an escalation (stage preflight). The PR run is never a gate sample.\nP9 Cohort and stop rule (D-29/D-30). B5 rules apply: at most 6 main runs at the B6 squash (the merge push plus guarded serial workflow_dispatch runs), stopping at 5 attempt-1 successes. The first three successes decide CI-03 on all three lanes at <= 1.15. The median of five decides CI-02 at <= 540 s. Failed runs count against the cap, are excluded and root-caused, and are never re-run. Main stays frozen. B6 is final: a CI-03 miss is recorded and escalated, with no B7 and no re-sampling.\nP10 CI-02 prediction (its 510 s ceiling is gate component (b) of P6). slowest_partition_delta_s is the median, over the five B5 runs on the current lane, of (max_p T_p of the queue replay at overhead_ms = 8000 minus max_p T_p of the static replay) / 1000. self_test_delta_s is the larger of (head_env - baseline_env) and (head_bin_bash - baseline_bin_bash) from the self_test_seconds in 247-B6-LOCAL.md. predicted_ci02_median_s = 457 (the B5 measured median) + slowest_partition_delta_s + self_test_delta_s, rounded to 0.1 s. ci02_expectation = EXPECTED_PASS if and only if predicted_ci02_median_s <= 540; otherwise EXPECTED_MISS. Gate component (b) requires predicted_ci02_median_s <= 510. CI-02 itself is decided only by the B6 cohort median at 540 s.\nDisclosure. K=12 and the 4 s and 8 s overhead points come from 247-B6-REMEDY-RESEARCH.md, whose scratch replays already used B3\u2013B5 data. The research reported latest-lane replays up to 1.092 across 4\u20138 s, so this gate can fail. The 510 s CI-02 component and the median-of-3 self-test measurement were added at plan-check iteration 2, before any replay or self-test number existed. No other K, overhead, run subset, model term, weight or colocation is tried after this block.",
  "pre_registration_commit": "6a1e8a16b3ba550d225e4c42036448ea2631dab0",
  "preflight_criteria": {
    "evaluator": "tail_queue_replay.py preflight",
    "max_lane_ratio": 1.1,
    "max_pooled_mean_overhead_ms": 8000
  },
  "replay": {
    "current": {
      "40433193088": {
        "cohort": "B3",
        "measured_ratio": 1.13,
        "queue_ratio_4000": 1.029482,
        "queue_ratio_8000": 1.052107,
        "static_ratio": 1.028547
      },
      "40434036118": {
        "cohort": "B3",
        "measured_ratio": 1.24,
        "queue_ratio_4000": 1.033665,
        "queue_ratio_8000": 1.051658,
        "static_ratio": 1.209923
      },
      "40434884357": {
        "cohort": "B3",
        "measured_ratio": 1.15,
        "queue_ratio_4000": 1.049015,
        "queue_ratio_8000": 1.059218,
        "static_ratio": 1.139862
      },
      "40436597341": {
        "cohort": "B3",
        "measured_ratio": 1.19,
        "queue_ratio_4000": 1.036172,
        "queue_ratio_8000": 1.036414,
        "static_ratio": 1.152365
      },
      "40437416932": {
        "cohort": "B3",
        "measured_ratio": 1.19,
        "queue_ratio_4000": 1.044002,
        "queue_ratio_8000": 1.061635,
        "static_ratio": 1.160857
      },
      "40449332597": {
        "cohort": "B4",
        "measured_ratio": 1.12,
        "queue_ratio_4000": 1.025541,
        "queue_ratio_8000": 1.046831,
        "static_ratio": 1.152526
      },
      "40450141708": {
        "cohort": "B4",
        "measured_ratio": 1.11,
        "queue_ratio_4000": 1.031485,
        "queue_ratio_8000": 1.063714,
        "static_ratio": 1.109564
      },
      "40450801580": {
        "cohort": "B4",
        "measured_ratio": 1.12,
        "queue_ratio_4000": 1.02932,
        "queue_ratio_8000": 1.054291,
        "static_ratio": 1.089055
      },
      "40451533079": {
        "cohort": "B4",
        "measured_ratio": 1.12,
        "queue_ratio_4000": 1.047469,
        "queue_ratio_8000": 1.063412,
        "static_ratio": 1.179294
      },
      "40692111621": {
        "cohort": "B5",
        "measured_ratio": 1.17,
        "queue_ratio_4000": 1.036461,
        "queue_ratio_8000": 1.050945,
        "static_ratio": 1.038946
      },
      "40693451272": {
        "cohort": "B5",
        "measured_ratio": 1.17,
        "queue_ratio_4000": 1.03762,
        "queue_ratio_8000": 1.05955,
        "static_ratio": 1.132943
      },
      "40694602284": {
        "cohort": "B5",
        "measured_ratio": 1.09,
        "queue_ratio_4000": 1.036008,
        "queue_ratio_8000": 1.025533,
        "static_ratio": 1.128476
      },
      "40695763585": {
        "cohort": "B5",
        "measured_ratio": 1.17,
        "queue_ratio_4000": 1.035158,
        "queue_ratio_8000": 1.052747,
        "static_ratio": 1.117058
      },
      "40696978392": {
        "cohort": "B5",
        "measured_ratio": 1.16,
        "queue_ratio_4000": 1.028135,
        "queue_ratio_8000": 1.046298,
        "static_ratio": 1.071175
      }
    },
    "latest": {
      "40433193088": {
        "cohort": "B3",
        "measured_ratio": 1.36,
        "queue_ratio_4000": 1.02047,
        "queue_ratio_8000": 1.068143,
        "static_ratio": 1.321384
      },
      "40434036118": {
        "cohort": "B3",
        "measured_ratio": 1.3,
        "queue_ratio_4000": 1.048885,
        "queue_ratio_8000": 1.032544,
        "static_ratio": 1.101435
      },
      "40434884357": {
        "cohort": "B3",
        "measured_ratio": 1.3,
        "queue_ratio_4000": 1.044022,
        "queue_ratio_8000": 1.05325,
        "static_ratio": 1.042824
      },
      "40436597341": {
        "cohort": "B3",
        "measured_ratio": 1.26,
        "queue_ratio_4000": 1.094006,
        "queue_ratio_8000": 1.106776,
        "static_ratio": 1.104405
      },
      "40437416932": {
        "cohort": "B3",
        "measured_ratio": 1.38,
        "queue_ratio_4000": 1.059585,
        "queue_ratio_8000": 1.068243,
        "static_ratio": 1.247915
      },
      "40449332597": {
        "cohort": "B4",
        "measured_ratio": 1.1,
        "queue_ratio_4000": 1.085832,
        "queue_ratio_8000": 1.106514,
        "static_ratio": 1.183431
      },
      "40450141708": {
        "cohort": "B4",
        "measured_ratio": 1.04,
        "queue_ratio_4000": 1.073667,
        "queue_ratio_8000": 1.074021,
        "static_ratio": 1.148872
      },
      "40450801580": {
        "cohort": "B4",
        "measured_ratio": 1.12,
        "queue_ratio_4000": 1.062181,
        "queue_ratio_8000": 1.055634,
        "static_ratio": 1.295507
      },
      "40451533079": {
        "cohort": "B4",
        "measured_ratio": 1.06,
        "queue_ratio_4000": 1.03009,
        "queue_ratio_8000": 1.044859,
        "static_ratio": 1.146027
      },
      "40692111621": {
        "cohort": "B5",
        "measured_ratio": 1.08,
        "queue_ratio_4000": 1.034336,
        "queue_ratio_8000": 1.099813,
        "static_ratio": 1.158329
      },
      "40693451272": {
        "cohort": "B5",
        "measured_ratio": 1.09,
        "queue_ratio_4000": 1.026526,
        "queue_ratio_8000": 1.076557,
        "static_ratio": 1.201388
      },
      "40694602284": {
        "cohort": "B5",
        "measured_ratio": 1.06,
        "queue_ratio_4000": 1.065929,
        "queue_ratio_8000": 1.058769,
        "static_ratio": 1.062462
      },
      "40695763585": {
        "cohort": "B5",
        "measured_ratio": 1.09,
        "queue_ratio_4000": 1.097786,
        "queue_ratio_8000": 1.086137,
        "static_ratio": 1.09322
      },
      "40696978392": {
        "cohort": "B5",
        "measured_ratio": 1.09,
        "queue_ratio_4000": 1.066358,
        "queue_ratio_8000": 1.067757,
        "static_ratio": 1.172342
      }
    },
    "min": {
      "40433193088": {
        "cohort": "B3",
        "measured_ratio": 1.36,
        "queue_ratio_4000": 1.049936,
        "queue_ratio_8000": 1.074716,
        "static_ratio": 1.196155
      },
      "40434036118": {
        "cohort": "B3",
        "measured_ratio": 1.35,
        "queue_ratio_4000": 1.024045,
        "queue_ratio_8000": 1.07468,
        "static_ratio": 1.206129
      },
      "40434884357": {
        "cohort": "B3",
        "measured_ratio": 1.28,
        "queue_ratio_4000": 1.049254,
        "queue_ratio_8000": 1.071317,
        "static_ratio": 1.277516
      },
      "40436597341": {
        "cohort": "B3",
        "measured_ratio": 1.37,
        "queue_ratio_4000": 1.054005,
        "queue_ratio_8000": 1.078586,
        "static_ratio": 1.172254
      },
      "40437416932": {
        "cohort": "B3",
        "measured_ratio": 1.33,
        "queue_ratio_4000": 1.04342,
        "queue_ratio_8000": 1.071038,
        "static_ratio": 1.190516
      },
      "40449332597": {
        "cohort": "B4",
        "measured_ratio": 1.24,
        "queue_ratio_4000": 1.029809,
        "queue_ratio_8000": 1.041739,
        "static_ratio": 1.052698
      },
      "40450141708": {
        "cohort": "B4",
        "measured_ratio": 1.28,
        "queue_ratio_4000": 1.049799,
        "queue_ratio_8000": 1.023058,
        "static_ratio": 1.030934
      },
      "40450801580": {
        "cohort": "B4",
        "measured_ratio": 1.27,
        "queue_ratio_4000": 1.068672,
        "queue_ratio_8000": 1.101163,
        "static_ratio": 1.156632
      },
      "40451533079": {
        "cohort": "B4",
        "measured_ratio": 1.25,
        "queue_ratio_4000": 1.041733,
        "queue_ratio_8000": 1.038325,
        "static_ratio": 1.267682
      },
      "40692111621": {
        "cohort": "B5",
        "measured_ratio": 1.07,
        "queue_ratio_4000": 1.04551,
        "queue_ratio_8000": 1.052433,
        "static_ratio": 1.109191
      },
      "40693451272": {
        "cohort": "B5",
        "measured_ratio": 1.06,
        "queue_ratio_4000": 1.041801,
        "queue_ratio_8000": 1.075704,
        "static_ratio": 1.089157
      },
      "40694602284": {
        "cohort": "B5",
        "measured_ratio": 1.11,
        "queue_ratio_4000": 1.061939,
        "queue_ratio_8000": 1.077597,
        "static_ratio": 1.088752
      },
      "40695763585": {
        "cohort": "B5",
        "measured_ratio": 1.03,
        "queue_ratio_4000": 1.042286,
        "queue_ratio_8000": 1.078432,
        "static_ratio": 1.091866
      },
      "40696978392": {
        "cohort": "B5",
        "measured_ratio": 1.11,
        "queue_ratio_4000": 1.063275,
        "queue_ratio_8000": 1.06001,
        "static_ratio": 1.08786
      }
    }
  },
  "runner_sha256": "cec42f3a4703c7902a5a6ba78d4fd5f4f2c38568c58fda93d1a8ac00573f1f9e",
  "schema": "threadline.phase247-b6-prediction/1",
  "stop_rule": "P9 Cohort and stop rule (D-29/D-30). B5 rules apply: at most 6 main runs at the B6 squash (the merge push plus guarded serial workflow_dispatch runs), stopping at 5 attempt-1 successes. The first three successes decide CI-03 on all three lanes at <= 1.15. The median of five decides CI-02 at <= 540 s. Failed runs count against the cap, are excluded and root-caused, and are never re-run. Main stays frozen. B6 is final: a CI-03 miss is recorded and escalated, with no B7 and no re-sampling.",
  "tool_sha256": "91f91b13510f5027b6e7d3a4726b8092b1f44732d99881277a7c89ee76301dcb",
  "tsv_sha256": {
    "40433193088": {
      "current": {
        "1": "a4d227dd5000e1321164ee706b3ea0a252cea38ba37c31338df53b049c41dca8",
        "2": "a5362f4817dfc713df8278a42285ef59f069b69019c789063753c765dde18f8e",
        "3": "f86671d04dbea7b71b2fce0c1c6f5314316b9f6fca3439b9f779bd1d4efc445d",
        "4": "1619671cd633bec3b6990acd678c02d9d5f72cad73ed021dfe3771d24d29ad50"
      },
      "latest": {
        "1": "dc4a00a6da6c145f13b77d9036c1334304ee792b3f1d8525ff6b8f5e37875bf4",
        "2": "e1d4a836726513c9bb17fe88c1b30858148e2b1208efd38e5c8cb1efd855b8e8",
        "3": "3fdfb5d55e4c06293a9ca76adb09b477491b147e34dc400178bc408f087615e3",
        "4": "58264691d53d2c5f963ff65949a840e9980a408a6d9e8e4343e4745a86b6d279"
      },
      "min": {
        "1": "a76887eb5e37e485ec2d181e59d19a15afc141fd590056bce01f31726b0ff8c5",
        "2": "d4597c8140e6caf968092efd1224942fa87d90df4812fede51dc6e795280f99b",
        "3": "04709a65daf859c20380bb160f21cd11eff8af36c6ec88e3524ab846aa90d603",
        "4": "aded70900a801df58b8a53913d6251a17108a92a5942176f5641e9aef58d8be3"
      }
    },
    "40434036118": {
      "current": {
        "1": "eb8f60b89d33d57efa105acc0da064622ccfd7abcc1d00a94b076ef8611ccffe",
        "2": "9c984219c942c5741f580418de2d82135199bd8afe9cf540205a278af2006538",
        "3": "c0374ab1b9b45a2d6bdb533c1a00d1325322662a2d4bf0998911d96ed27bca60",
        "4": "bb51e8778c27af649c95aeb040a75023e3bf3b8aaefb48b285317b1b3ef9c8cb"
      },
      "latest": {
        "1": "661856454fec5f20f41e0f6a458ea0e602c94115b1957d1e931e185ce7e1f5db",
        "2": "762f1e7c5764db28f4a7f01932931ae0ce07d488913ca139f322495fa1a01815",
        "3": "927c360c100f60d290d661afed88cd044ff22327e1f9bef87cfc7a61775476d9",
        "4": "7047ff3419842c0bb2c59cdbd5f8a709eec43e84cd882c6adb48a48e2320ee06"
      },
      "min": {
        "1": "51886731a37ee2021bd215dbb0dd46a4e6985e455b0bea7e3a595c166a0d9c3b",
        "2": "8fa2e7934d74522c8b66677cacd7e1f8525467501471659bfbb8ebf829a8e503",
        "3": "4b16ed4b2e59b71325950dd65ca8bb2398e1f1cf391608b21e2cb46025e289b5",
        "4": "fe6cd48470a0b486ebe1a78bc3c6487caa3778d43b4cd646e23ac6616e2bbc91"
      }
    },
    "40434884357": {
      "current": {
        "1": "49eb0a638e479e0c9e16a0693dabc266614f7310751efc4f1b0c9555cf484fe2",
        "2": "f79eb9ba7d269dbad09655e0944d5a9cba44252de5418d9785cfbc4f2d725255",
        "3": "dcba0d970e0c18bc27802d8f157945f6fd7b743a0250cb423cbbb1b6ca26810b",
        "4": "07d5dffd83766328ece33c78932eeb151fba95032596921f7222e2c10ce2ec7a"
      },
      "latest": {
        "1": "9166115eb16c8e3292271b4ff8a0d4f8f7cec15779ac040d7d17d2a5dc8fba6d",
        "2": "4c979ec8ff2fb9b4fe71154367d8d317c92ac277bb41d3291249d28a3f1e6640",
        "3": "8c3ca6abc7b4bf6531fc2bc75b61ae02a60c0e220a6f862eea480fee2209a569",
        "4": "2edf2c80efa7f8f7198d75607634b381c3f456cd087a9b370217ee15088e5094"
      },
      "min": {
        "1": "86922db2a650584738ffdfa62748d12e66beed7a7ecc1e608cb93c07ca1150a1",
        "2": "3244a31bb22d6befd7e24252b5d82906bb8d4a46af2d13cefe1b65008776f058",
        "3": "08090d8d431f8fc146ad04c903930b0feec6078c735360ffaf7a2d5b0b2613cf",
        "4": "1b6a172255aaf3f6dad6a39305754e4fb1e22c6a969775c9bcc646af71bb2e37"
      }
    },
    "40436597341": {
      "current": {
        "1": "551055ed65ffb00ed859c08c9df332bd704373c75d48996afbe2104f2b5e2d0c",
        "2": "3fddf83b56c35c6c0ee04d094231edc66c82c81b230e541143bdf2dcc915e749",
        "3": "54aab5d1303bc55489533504fef5e7ca5eeb9b45f162c507dc730379f1cc1ce4",
        "4": "644092424ba58452ec86fd9aaf61b5042e70fff7e46285467fd510292c8891fc"
      },
      "latest": {
        "1": "822e14262c00315297e958d2924cb4229595cc3724993c37e4e51589d61e4a8e",
        "2": "f244b541cf53d7595d5f5e64c24075794ea9d08c5dd31123720f31ed00baa26d",
        "3": "348955975abaebd36f7c08a78605ea5d8cb4fedf730d00fbd773eae5daffba53",
        "4": "8f95d9d5cf52c243372b5c048b1aff6eb1c270b9cd2f8dc1ae7e10dc93adff9c"
      },
      "min": {
        "1": "fc0a93560f8f247f5c25b3abdd956965952b17e724b9306724fcd54cd1d58d5f",
        "2": "c654563fb2891ee3a853e092e11347a98100b0bd9f17deef229f1fd4465957cb",
        "3": "d13daf5cdd1a0da888b44d0e2dfa5ac3a426bd674192ecb97ee8654e867ab876",
        "4": "2bea64c6996fa23ae8077d145d217639b154a58e38f489d4d01c1efdb8f25d84"
      }
    },
    "40437416932": {
      "current": {
        "1": "731a91e6afa400a1370e91664727167349ca2b5f1b0ef205a787e5a6f2f0c45f",
        "2": "10953f6d8df9613bb8a157f871213fc4958b3c0d5200c43c175f07a191aa2839",
        "3": "bd7377b598441223a9a41b46ccf08639ecf09d47aef12d2cfca50f6b73d995b3",
        "4": "7fdc2fd9c736377750325453b6101eaa2a927d28cc90239a7b36df7a8d8d871c"
      },
      "latest": {
        "1": "325104edf27bf7166201a3c18de3bde76abb5937c6488f9d08d41b69dee44f36",
        "2": "1af468c8ff1de21f23b6f07c8c5bfaba004ac6434b1e412a3ebc464117e90a61",
        "3": "8cc212be1901cacb19727677fed4ff3645572b5d09473b4ffb218562d77aec56",
        "4": "b01ec262841e22a65ad40e74b1e4ac1b1f41126529bd95a0440b4d532d00e87a"
      },
      "min": {
        "1": "2d4f45a93bf9eb776127cadc6441919b649b9a47542bce290dea526949772546",
        "2": "9f5b651b9b608ea4d369e277a29f706fb1c9b27ec5bf6d2b602c28941d15e3c3",
        "3": "7bc967b0b59d53deedc3737c88368a1e547a5dd341489c459566d8d75d6c59aa",
        "4": "7fc0d73df39d2ac927762e1f3a64b63820fceed41d9b9cd17ebec16d79f28b40"
      }
    },
    "40449332597": {
      "current": {
        "1": "90d43c4786aa6d2535e446c27fd850939ff0d8d33cc62b24a352b92876ba71c2",
        "2": "700cbb5dde3552a948ab657625ddafecc93d1631e24fe2305018afb87ba96a76",
        "3": "5f03e0f72435cb0661572f7d511b8f8e6aa39269c2603dcaa031b718b0185a1b",
        "4": "a3e2d643c71f824030277af9ae84fc55c7d76e4b0f804f6a0fee67240d99c990"
      },
      "latest": {
        "1": "1f7f2595baca96534a518a1a8fc546e44a5ff54d23c1c29a0eae953aa06032a7",
        "2": "f88b0fccc6104d7b4045424ac19cec2cc28b562af3ba531bb3cdb7df3c047909",
        "3": "5fe3e5ea66ea8fb2bf4d059de8fc8988e377d5b03fd4ba0b1ab6d8a9da921640",
        "4": "07e6c5486b6011dea22065d05dc5501c46f8693e326b6076a7b4fc6299abc6ae"
      },
      "min": {
        "1": "8f68d7e146ff567b86d67eb69051f8455ce8d070f0bd13ae498ecb2f6001054f",
        "2": "ec634bf85a9f4f47222985fb3803a0231b41a590d6f470f448b1f9a1b90c7466",
        "3": "2f85de00f0d218893531f3d290ee35f1262e4b8e473a464b7f046bc53b042724",
        "4": "f38a93d7ca1c2c6674edc8a52bf4b3199efd3a1ab5c2411149e89e57c4a42961"
      }
    },
    "40450141708": {
      "current": {
        "1": "d2300948d7b0ae2a2c9df2db261a4d80225dbaed34aea572eb468b9147c8ff54",
        "2": "8bc4451ab6ff046ec9a8ba5abb014e185b9a8de717a809f4c77c741f98554830",
        "3": "6c0afa23b12efa80637ca587fe64858111a60455e7ed30abe64c1818824da795",
        "4": "5b88d3bb5b2b04368989ccf6d1974f7c0af7b736534ff72ea0be85346342494f"
      },
      "latest": {
        "1": "f063168142b362585509588de5eb7618e5419f0fe2b37b20e8aa8e5d6fb423d7",
        "2": "e8eceeb94c1eedee25b94c4ffcef150464fc1ef63681fc782f291ccca3ca4eb3",
        "3": "1ad7831b4b166f33dcbc0c292bd2953792353b58faf5be6a8b440c857735401d",
        "4": "03a0443a4835c5f982b7c8a9c5094f2e82fa05674c2ea48ea009bdbacf54523f"
      },
      "min": {
        "1": "c35e333ad88d34993d272b9696e7b52a393d52ab4809ee4946e241d60f744246",
        "2": "63246d80ec06ef6316aa570d85745712dd99f6ad731a87f8475cbf3a962128f1",
        "3": "49daeb55cb2d7cbcf79f3bf6ff4abc56beae9b57cbb8429600ec6e32eae2e556",
        "4": "311fbd2349cbae4d631d199bd40150f42262b61b19c9d9449b8eed5bbb61c07c"
      }
    },
    "40450801580": {
      "current": {
        "1": "cd7e6be6a94106e374efb0fb0889684679bf39c8c51f79b40ced0c61b61a960a",
        "2": "422e62f523281c8b52649a0b0f0d3d8ba26939c52bb0ce362d544d7e92bd4df7",
        "3": "552f3f4f8a7b48ac5e3c8b1e02d416e44bf5a352ce0df4ef4f0ec48950ea2881",
        "4": "0490e13224658315ef7cd0ad7f810b63b82394d6af20b108383ace2ae7894b0c"
      },
      "latest": {
        "1": "ad412b029fb29c1da379f43ee979827c44d21a8dbbcc110754b4c7c5196433cf",
        "2": "20f550cd1a8a981b5f1ab1beba46310a9e54d6c6557c8208b7f5b26f5281a618",
        "3": "708291eb84f01852cfaaaa1b87935660c03883a56563bfa7066bc91e50e59e75",
        "4": "3082718abc74b3452fbe5ee36a2222d88efe31531568e2e746b956ec3fa1d34f"
      },
      "min": {
        "1": "024eb134c78fc0ef3cc43a27c753297889b5840d1c1978f924829a71f0ad987e",
        "2": "b372d03aeac068cc69aac0be2a4a394f1e91317b5f1c28575c7551bfb88246d9",
        "3": "06e983c548acd22e4632f2f1fd426235eb5451fcc5ac8a4980598f77a62a5ff1",
        "4": "6a2b1bdc21465ae3bbc1ac3e9ae01a59463c27a0daaa46da50756220cc4489ad"
      }
    },
    "40451533079": {
      "current": {
        "1": "8cd0ab32c9c5e1802916fdbb22435feb26b52bcc1e043e9e5b8a06f4faae2b13",
        "2": "1ca1078535f5b86fc6222e5808fe065d386c416bc6d1cd309e67565a4b279802",
        "3": "09263aa23cd0d43fb7319b60413edc1ef43beecf15b849b236cf54babe3c2b41",
        "4": "37dd942d322d61e275b48d839be8b638bc390723c37346c676b0c63b426a4de6"
      },
      "latest": {
        "1": "5e6237d22cafbf69473c1c913158abf1200a4ca4b6c1417df267f783d0c87f21",
        "2": "de9a215eb07dda696f2a6752bd44c0b6224672094aa410ae566299b8a17ca6e9",
        "3": "214cc070bfbe5b595b3361aad576cdae0827017400b3289ac4b83886f71c0891",
        "4": "3a6e787355f5d782111ce069eebe359b656907885b0f3a1b5b5fdb1e39413352"
      },
      "min": {
        "1": "e4a3bb798e0f8f625cfe2693b146b07ae4b1cbdb7d0c754a2a83e8a6ee764fc5",
        "2": "4bbb0b9a2c84e3e1ec184272d873f08e19ac940f2f71bee8113f2ed5be3ff9f1",
        "3": "783c3f620e8b39a3f991e63c415e21110b37227c0d619901f08a04da8fae61a5",
        "4": "8d17634440826f8c3d15d92b8251f34a1b3b09f5ffde2a68426430d707c40465"
      }
    },
    "40692111621": {
      "current": {
        "1": "3fcf13ab7ad1d05563049a00ce0e77d5049fb715ac2afe2a5416f6ae81a2a223",
        "2": "82a84f126b76764f99ccde6f15fd74f61dddef26f550bfbbbd4b5e82bf221fa3",
        "3": "91046b412ffdb44e6a82ff4f7c4eb7b13b0d1c5f144b79cbdbf1f4375c22a2fc",
        "4": "fb52fe75ea5ed44db3e6d550a3bc7ee0b1d5f37243be2aba41b0e3975e35b8e8"
      },
      "latest": {
        "1": "059b00c063c5b90a8c1b1d816d087f68b2b2a90ad450e3496bea28380637b41c",
        "2": "5d1b24e80a04873f95fcc30504fcded118b4fc96f43486812e0510466c7917cc",
        "3": "78da9556c2cb17bfe2e54631b1ba9716c2adc479898dc6cd71b0d1e2e6030681",
        "4": "a4426b9285ee86cac269453ffb57505d307daa0f51c7c9f0b63934b98582b96a"
      },
      "min": {
        "1": "1ee8885ddeb3a83e56e8a9e08ffc410291e05e8d8d8a55ffde5082314bb569e6",
        "2": "7f4712ca40d09982f6d319291fa6fdcced8aaf2684f993eb3d680059842a6298",
        "3": "f2ff0ebb8038c362e0328ab6f5e27ae80df6eeab2340a5ab1f14d7103a0e6903",
        "4": "7254042c163871021789b36cd47ed5a24a1b8b1fde5469df4c745c9c2dccbb57"
      }
    },
    "40693451272": {
      "current": {
        "1": "7dc441a7c1539862f4f14cb6a565d1811532bbf07473798aa7068c232b246620",
        "2": "801465c84845ff959f9242309735a33f5f6a62bb9e7e37faacc12fa63ec41fa2",
        "3": "5c0e0cda2c32cd7de9956b7c3de127bccb7a4bf5d95150d7151d66cb90729e43",
        "4": "f55549a2a40e38d15d3253a2273f82a1e75a4cdfdd353014e6b5850acc304a65"
      },
      "latest": {
        "1": "68701ca29e49132c9a28e9f0eaf595c9080779e4297906847667a37d1dedd1cf",
        "2": "17696e607efb712460b3e54ea11237854d4ca46d6f2fa77cd5d10c6e111faa3d",
        "3": "34d62efb4bf200a45810b670436708574c67d694883595ab1a09b5bfe9150988",
        "4": "fe5f5b091e42f6aa886778ea757097d9883c65366ec2d38b01c7594ec2275a66"
      },
      "min": {
        "1": "3cb610929fc5e34446802ba7f4b3f7b0277137ea4b0da5039c08ecd20946d7dc",
        "2": "8f2715cb6fa0659ce3a97ae69ee08e26774c77d27ec0b87a110f1de5a142bd13",
        "3": "01b6f0c6e7f4091a39b5266875a6397a156de7f493f0ad54a684374990dfe07d",
        "4": "c0dda62acea1a1870f61623fec9d983b62a602ef2658b243f9d25f8b3f47409e"
      }
    },
    "40694602284": {
      "current": {
        "1": "049d2b96f1eeb3a3179689c550147f2c8d18a0fb400a96eb2e3456063877718c",
        "2": "0952c1701a02d2a26e2384af1415ed15d8055dc98f77e1c68431b7283e8018a4",
        "3": "073a6b0353d1906610afbd832a49df184dad3744285c910d0ab8ded62e795bf7",
        "4": "bb1f2c7af1f5982fe6256e0849ce11b0c27fd2010e581833d840be70f267bea1"
      },
      "latest": {
        "1": "5c7de2024df1ae775871acc7bf4d3a617763cfb240fb6d25669bbc64fe3d89e1",
        "2": "5ac6a5b8716f027e9aa9f70b8739b8f399693741fd4aade253792a720d9a80ac",
        "3": "bb87b5317256d9e939bcb162b0c173300a9dc9e208263b7e051e591da348cde2",
        "4": "13e4b4c70979198a28ad9dd96f8cf48e1d8e47ebe180049013cf7e2a563a7e1f"
      },
      "min": {
        "1": "db0c2ffee7a060380745e7959ce0fd7de6f794c05e63ea9715008a10eb401af6",
        "2": "3a0d9df6a78ebc0556646fb4751e646be80d5e1fa17489f8bf208f97050d8a91",
        "3": "eef5b1cf2b6d934fb907251de508890538e1c255054128b519aa6272e84fb54c",
        "4": "ee88cf22e416aee6e497a30eb1c10c138fddff71e3190fa44fee244ebfe95b56"
      }
    },
    "40695763585": {
      "current": {
        "1": "01a3e79c1877468be636e4eef7cc8391f2613b8c07cb3d559d4029d213bd1ca2",
        "2": "9805b347d333e3de05e6527691281ba78fc1a825ed1c30c834cc3844544b45de",
        "3": "76eeecc61ee7088c3bfbb04cf33148a014629beb52d623053260e6401806b070",
        "4": "4c5686033fb40ce16d1e460a8c05724f0d70d1f39b7474caaed0ce489b698dc5"
      },
      "latest": {
        "1": "fc6b38b610e879a1c9842777179a7e164cb2bf43e86e6abad9bf9ee36b8500a7",
        "2": "70c5eb1d5f11e03df0732649d921d6e33b56c3b73076842da3c463a85298c75f",
        "3": "22491d0970d2347c8e4c8dbf32e253191fc62444801edf09790ceeeed92e91d0",
        "4": "7da5aeac208df64cb8ef561efe447d849385b29b9c59c8c6f11ff0b1d3c4694d"
      },
      "min": {
        "1": "81305bb1522bde47209d096c9af238b0b1b9908e1d1e6bae063719ab583b1d45",
        "2": "fabe6e8bbc621ddbd8009963e681f7edc5c786db9a258f4fd3b7feaa1b7fd8fe",
        "3": "470a60afd36cc034dfd3b4e850e4ad5a6be4169b602702b94d1220c754020f15",
        "4": "2fd2d6cbca446bca2885580087856610b6278d08e4ee14cd07f641fc2236a1c9"
      }
    },
    "40696978392": {
      "current": {
        "1": "2197b1082138f3a2bbd445660cea8965887b8ca3b8b78d581b488fc31d90d9a3",
        "2": "a07a2b1243b65da66a094a2e6a70fc170cd54fdc62da00441fcf13b201de250f",
        "3": "4de51f55735ac845f9e83c6e53d9e04f1d8e8ee0c14eb586bd750ca3d00d354d",
        "4": "690dc7e3f7278ab8b2712e21b5f0815225de76f300287f74c0e44d3e77dcc956"
      },
      "latest": {
        "1": "cfb5ce33035ae6f6542ab63eb7b77ba8bf542fdd28967933221ccea2d777bdb5",
        "2": "e7e34b1374fae583b209afb82061e8f2573bfd795df90c0f0f02919e0a0b4bdc",
        "3": "5d673f789de51b11db6e234d6af01bbec2dc0f3c6c33076a8cda59b9f3f8918d",
        "4": "62f97d2cd219d5416c0abee325acfa088cbb5187cdeb43b19f5149a21b0e5a39"
      },
      "min": {
        "1": "3ff0fa532846bf7094efdc6a5bd00f65694c7ab26ce0ac4516d180936f5c8a6c",
        "2": "4e18c5f096fa23d0afc1faaf35f534bf926567c2d71bc8b8c63435fec0a0ae3a",
        "3": "c3b1770d0177c53f17c15616bf816601d851509c6cdae5357f2835070259845a",
        "4": "51898a95575ddf73e2d711417fae5f37f2076417fbb6019ed552483add1c26fd"
      }
    }
  },
  "unavailable": [],
  "worst_8000": {
    "current": 1.063714,
    "latest": 1.106776,
    "min": 1.101163
  }
}
<!-- B6-PREDICTION-JSON-END -->
