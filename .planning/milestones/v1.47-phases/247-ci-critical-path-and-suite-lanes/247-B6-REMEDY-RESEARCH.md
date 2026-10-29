# Phase 247 — B6 remedy research (CI-03 current lane)

Date: 2026-10-28. Three parallel researchers each covered one decision cluster: the remedy, the R3 review findings, and the re-measurement protocol. The orchestrator independently re-ran the remedy replays (tail-queue simulation and leave-one-cohort-out replays) and got the reported numbers. Scratch scripts were not committed, because they import scratch-local helpers and downloaded artifacts. Plan 29 rebuilds the replay as a phase-local tool, so the B6 pre-registration can be reproduced.

## Inputs

- B5 current-lane `partition-timings-current-<run>` TSVs for main runs 40692111621, 40693451272 and 40694602284 (the gate runs), plus 40695763585 and 40696978392 (held out). B3 and B4 cohorts are as recorded in `247-MEASUREMENT.md`.
- Current-lane partition 4 is the slowest in 5 of 5 B5 runs, by +16 s. It holds both `async: false` stress-router files. Measured 75–91 s and 63–69 s; the committed B3-era weights are 71 342 ms and 53 672 ms.
- Partition boot (before the first module) ranges from 2.1 to 4.4 s per VM across the 20 B5 current TSVs.

## Remedy cluster — finding

Only the mean offset is stable. With the assignment fixed, run-to-run noise would give ratios of 1.02–1.055 if the partition means were balanced. A static weight refresh can't remove the offset reliably. Every refresh moves 52–68% of async work to a different partition. Async per-file walls depend on what runs concurrently (`formatter_topology` ranges from 7 to 49 s). So weights learned under one assignment don't carry over to the next. The cross-cohort replay error is ±0.05–0.07. For example, B4 data predicts the B3 assignment at 1.23, but B3 measured 1.15.

| Candidate | B5 gate runs 1–3 | B5 holdout runs 4–5 | Leave-one-cohort-out (B3/B4/B5) |
|---|---|---|---|
| Status quo, measured | 1.169 / 1.172 / 1.093 | 1.164 / 1.164 | — |
| Median refresh, trained on runs 1–3 | 1.058 / 1.176 / 1.168 | 1.167 / 1.163 | median 1.152, worst 1.30 |
| Mean refresh | — | — | 1.09–1.36 |
| Max-rule refresh | 1.120 / 1.214 / 1.199 | 1.160 / 1.115 | 1.07–1.42 (worst rule) |
| D-11 `deps_audit_gate` split | median 1.138, max 1.162 | — | min-lane replay 1.09 → 1.19–1.25 |
| Refresh + D-11 | 1.09–1.13, worst 1.24–1.42 | — | — |
| **Tail queue K=12, 4 s per claim** | **1.019 / 1.021 / 1.028** | **1.032 / 1.037** | B3 ≤ 1.041, B4 ≤ 1.043 |
| **Tail queue K=12, 8 s per claim** | 1.046 / 1.052 / 1.049 | 1.044 / 1.053 | B3, B4 ≤ 1.058 |

Tail-queue replays on the other lanes at K=12: min 1.026–1.078 and latest 1.018–1.092, both under 4–8 s per claim. K=4 replays at 1.31, so K is a pinned constant. The slowest partition moves by −7 to +27 s, which keeps the predicted CI-02 median at about 485 s or less (limit 540 s).

Rejected:
- Weight refresh under any rule: it is ≈ a coin flip against 1.15, which matches the history of one pass in three assignments.
- The D-11 split: it targets partition 2, not partition 4, and it disturbs min and latest, which already pass.
- A sync-only refresh: 1.03–1.11 on B5, but 1.15–1.48 on B4.
- An async-floor fix to the cost model: it moves min from 1.09 to 1.16.
- Splitting `public_surface` or `stress_router`: 1.14–1.19.
- Hand pinning or a colocation trick: none of the 67 candidate groupings works, and pins go stale.

Prior art: Knapsack Pro Queue Mode and pytest-xdist `--dist load`/`worksteal` both move from static timing splits to runtime balancing once the timing noise floor is reached.

Unexplained residual: the partition holding `stress_router_test` runs +15.5 s over the model in 12 of 12 runs, against +1.2 s for the other partitions. Locally, an isolated run of partition 4 shows a gap of only 0.7 s, and file load takes 0.38 s. So the residual is attributed to CPU contention on CI. The tail queue absorbs it.

## Review cluster — dispositions

- **R3-WR-01 — fix.** Add `on_exit` cleanup of `RetentionRun` rows in `retention_history_live_test.exs` and `retention/pruner_test.exs`.
- **R3-WR-02 — fix.** `ratio_of` fails on an empty partition instead of dropping it.
- **R3-WR-03 — fix.** `predict` runs the runner in a temporary copy, the same way `strict_ingest_copy` does. Delete `placed()` and its signal handling.
- **R3-WR-04 — fix in `bin/`.**
  - Add `lane_rule()` next to `lane_weights()`: current median, min max, latest median.
  - Add `--ingest-weights --rule median|max`. It defaults to the lane rule. In strict `--output` mode, a mismatched rule exits 2.
  - Pin it with self-test cases and a `ci_topology_contract_test` mutant, and add one CONTRIBUTING sentence.
  - Parity check: a strict min ingest over the B4 training runs must byte-match the committed `test/partition_weights_min.txt`.
  - The R1 header stays verbatim.

## Protocol cluster — finding

- Current-lane ratio SD is about 0.035 per run (B5).
- If the measured mean is 1.10, all three of three runs pass ≤ 1.15 about 86% of the time. At 1.12 the rate is about 60%, and at 1.15 about 12%.
- Model optimism observed so far: measured ≈ predicted + 0.07 (B5 min lane).
- B6 therefore needs a pre-registered margin gate, and it needs to be the last hosted CI-03 cohort. Sampling an unchanged head again until it passes would be p-hacking. Each cohort from B3 to B6 tests a new change.
