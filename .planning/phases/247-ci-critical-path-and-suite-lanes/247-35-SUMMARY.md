---
phase: 247-ci-critical-path-and-suite-lanes
plan: 35
subsystem: ci-partitioning
status: complete
tags: [ci, tail-queue, pre-registration, TQ-PREREG-2, D-32, D-33, CI-02, CI-03]
requires:
  - phase: 247-34
    provides: "bin/ci-test-partitions lane_tail_k() (current 12, min 0, latest 0), runner_sha256 2d420a97..449b; 247-B6-LOCAL-2.md self_test_seconds (D-34 interleaved: env 30 -> 45, /bin/bash 30 -> 47)"
provides:
  - "tools/tail_queue_replay.py round 2 (b94edfe0, sha256 ca88478f..0a29): LANE_K read from the runner's lift line, current-lane assignment pinned to round 1, K=0 lanes replayed static, current-only gate (GATE_LANES), uniform 1.15 preflight (D-33) with claim and overhead checks only where K > 0, TQ-PREREG-2 and 247-B6-LOCAL-2.md inputs, schema threadline.phase247-b6-prediction/2"
  - "247-B6-PREDICTION-2.md (bdfd6ddf): the second pre-registration, gate PASS; pre_registration_commit 7d555e68"
affects: ["247-36 (precondition: gate PASS plus runner_sha256 and tool_sha256 equality with the land head; runs the P8 preflight with this tool)", "247-37"]
actuals:
  tokens: 17876
  tasks: 3
  commits: 2
plan_head_before: 2ee8e9590b19880138528e7f5a54dc53ab27fd61
plan_head_after: bdfd6ddf8990122fadbf69ae452f08543caf90b3
hosted_runs_spent: 0
tech-stack:
  added: []
  patterns:
    - "Read K from the runner's own output (the lift line), never from its source, so a seam or lane mapping change is caught at replay time"
    - "Input checks that halt as invalid, separate from gate verdicts: the current assignment must equal round 1's; K=0 lanes need seam-unset == TAIL_K=0"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-PREDICTION-2.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-35-SUMMARY.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/tail_queue_replay.py
    - .planning/STATE.md
    - .planning/ROADMAP.md
decisions:
  - "B6 prediction-2 gate PASS. Component (a): current worst 1.063714 <= 1.08 at 8 s/claim, B3/B4/B5 covered. Component (b): predicted CI-02 median 457 + 19.837 + 17 = 493.8 s <= 510. ci03_expectation EXPECTED_PASS. Plan 36 proceeds. Task 3 (D-32 fallback) was a no-op."
  - "The round-2 replay reproduces round 1 exactly where P1 requires it. The current-lane numbers equal round 1's to six decimals at assignment 542fbb54. The min and latest static replays equal round 1's static column (worst 1.277516 and 1.321384, information only)."
  - "Recorded honestly: on latest, three of five B5 static replays are above 1.15 (1.158/1.201/1.172), while the same five runs measured 1.06-1.09 at the byte-identical assignment. The model is pessimistic on latest and optimistic on current. CI-03 on min and latest rests on B5's measurement, and only the B6 cohort decides it."
metrics:
  duration: "~10 min of executor time (21:07-21:17Z)"
  started: 2026-10-28T21:07:14Z
  completed: 2026-10-28T21:17:00Z
---

# Phase 247 Plan 35: D-32 second pre-registration (TQ-PREREG-2) Summary

**The committed replay tool now handles the per-lane runner: K is read from the runner's own lift line and checked against LANE_K (current 12, min 0, latest 0), and only the current lane is gated. The one pre-registered round-2 replay gives gate PASS: current worst 1.063714 ≤ 1.08 and predicted CI-02 493.8 s ≤ 510 s. This was recorded in 247-B6-PREDICTION-2.md before anything was pushed, at zero hosted spend.**

## Outcome

| Item | Result |
|---|---|
| Precondition | Met. 42 of 42 `partition-timings-<lane>-<run>` artifacts were listed exactly once with `expired: false` (earliest expiry 2026-11-10). 247-34 is committed (`lane_tail_k() {`, 247-B6-LOCAL-2.md). The plan revision 7d555e68 holds the TQ-PREREG-2 block, unchanged in the current plan. |
| Task 1 (tracer): tool extension | Done, b94edfe0. The self-test passes with 68 checks, including all 14 named round-2 checks. The tracer verify passed, then passed again after the commit (the tracer gate). On run 40692111621, current replays at K=12, assignment 542fbb54, queue 1.050945, measured 1.17. Min replays at K=0 with an empty queue, queue == static, measured 1.07. |
| Task 2: prediction-2 | Done, bdfd6ddf. A fetch of 168 TSVs (42 digests, 84 frozen pins, 168 tool pins, 0 unavailable), one replay at 8000 ms and one at 4000 ms, one `predict`. The JSON block is the `predict` output, byte for byte. Gate **PASS**. |
| Task 3: D-32 fallback | No-op on PASS, as the plan specifies. Its verify asserts the PASS-path state: no 247-B6-ESCALATION-2.md, no SEED-009, no 247-36/37 SUMMARY. |
| Hosted spend | 0 runs. No push, PR, merge or dispatch. |

## Gate (P6, P10)

| Component | Value | Bound | Holds |
|---|---|---|---|
| (a) current-lane worst queue replay at 8 s/claim | 1.063714 (B4 40450141708); B4 and B5 covered | ≤ 1.08 | yes |
| (b) predicted CI-02 median | 457 + 19.837 + 17 = 493.8 s | ≤ 510 s | yes |

Information only (not gated):

- the current-lane worst at 4 s/claim is 1.049015;
- the min static worst is 1.277516 (B3 40434884357), and the B5 maximum is 1.109191;
- the latest static worst is 1.321384 (B3 40433193088), and the B5 maximum is 1.201388.

`ci02_expectation` is EXPECTED_PASS and `ci03_expectation` is EXPECTED_PASS. Both are advisory.

`self_test_delta_s` is 17. It is the larger of the env delta (45 − 30) and the /bin/bash delta (47 − 30). The other P10 term, `slowest_partition_delta_s`, is the median of +22.977, +17.451, +17.048, +19.837 and +21.543 s.

## Tool changes (constants diff against b25c3c29)

- **Changed constants:**
  - `EXPECTED_K = 12` became `LANE_K = {"current": 12, "min": 0, "latest": 0}`, and `GATE_LANES = ("current",)` was added;
  - `PLAN_REL` now points at 247-35-PLAN.md, with `PREREG_MARKER = "TQ-PREREG-2"`;
  - `PREDICTION_SCHEMA`, `LOCAL_REL`/`LOCAL_MARKER` and the `ROUND1_*` constants were added;
  - `PREFLIGHT_MAX_RATIO` moved from `Decimal("1.10")` to `Decimal("1.15")` (D-33), and there is no second ratio constant.
- **Unchanged constants, verified byte-equal against b25c3c29 by the Task 1 verify:** `PINNED_TSV_SHA256`, `COHORTS`, `FROZEN_REPLAY_SHA256`, `GATE_OVERHEAD_MS`, `INFO_OVERHEAD_MS`, `GATE_MAX_RATIO`, `CI02_GATE_S`, `CI02_LIMIT_S`, `B5_MEDIAN_S` and `PREFLIGHT_MAX_OVERHEAD_MS`.
- **`run_assignment`** reads K from exactly one `tail queue: <q> files lifted (K=<k>), weight <w> ms` stdout line, and `<q>` must equal the queue length (`parse_lift_line`).
- **`replay_lane`** requires the K to equal `LANE_K[lane]`, and the static calibration to print K=0. On K=0 lanes, the queue must be empty and the seam-unset sha must equal the TAIL_K=0 sha. On current, the assignment must equal `ROUND1_CURRENT_ASSIGNMENT_SHA256`, or the replay raises "current-lane assignment differs from round 1".
- **`cmd_replay`** emits `k_by_lane`.
- **`gate_of`** applies component (a) and its B4/B5 coverage to `GATE_LANES` only. It reports `worst_8000` for all three lanes, plus `worst_static` (min and latest) and `gated_lanes`.
- **`cmd_predict`** checks:
  - `k_by_lane == LANE_K`;
  - the current assignment equals round 1's;
  - the TQ-PREREG-2 block at the pre-registration commit equals the current plan's, and that commit is an ancestor of HEAD;
  - round 1's sha256, plus round 1's recorded current assignment;
  - the LOCAL-2 record has `lane_k == LANE_K`.

  It emits `disclosure`, `round1`, `static_identity_main`, `preflight_criteria.lane_k` and a null `local_overhead_ms` for K=0 lanes.
- **`evaluate_preflight`** applies, per lane:
  - every lane: K equals `LANE_K[lane]`, and the ratio is ≤ 1.15;
  - K > 0 lanes only: claim lines equal queued, at least one claim line exists, and the claims feed the pooled ≤ 8000 ms rule. The rule fails closed when no K > 0 lane has a claim line.

## Deviations from Plan

None. The plan was executed as written.

The tool gained a few fail-closed checks beyond the minimum listed:

- round 1's recorded `assignment_sha256.current` must equal `ROUND1_CURRENT_ASSIGNMENT_SHA256`;
- 247-B6-LOCAL-2.md's `lane_k` must equal `LANE_K`;
- the predicted record also carries `cohort_coverage`.

The self-test also has extra cases next to the 14 required names: K=12 with claims on latest, a current lane that queued nothing, a missing ratio row on a K=0 lane, current-only coverage, and round-1 marker rejection. None of these changes a pre-registered rule, a parameter or an input.

## Verification

- Task 1 `<automated>` (run under bash from a scratch script): passed twice, before and after the tool commit.
- Task 2 `<automated>`: passed. It ran a fresh fetch and a fresh replay at 8000 and 4000. The record reproduced within 0.0005 on every lane and run. It confirmed the 168 pinned TSVs, the P2 cohorts, that `pre_registration_commit` 7d555e68 is a strict ancestor of the prediction commit and not f68508ce, that the runner and tool hashes equal HEAD, and that the gate recomputes as PASS.
- Task 3 `<automated>`: passed on the PASS branch.
- `bin/verify-repo-hygiene`: green before each commit. `git status --porcelain test/ bin/` was empty.
- 247-B6-PREDICTION.md sha256 is still 33fbbc3f4737e72929269e447a086ca99ef2444161a41d11137f5be804cefe09.

## Requirements

CI-02 and CI-03 are not marked complete. The plan's gate is an expectation, and the B6 cohort in 247-36 decides both, so the verifier makes that call.

## Known Stubs

None.

## Next

247-36: land 247-29..31 + 247-34 as one `ci:` squash from `land/v1.47-ci03-tail-queue`. Its precondition re-checks this gate PASS and the runner and tool hashes at the land head. It then runs the P8 preflight (`tail_queue_replay.py preflight --run <id>`) and the B6 cohort under P9.

## Self-Check: PASSED

- FOUND: .planning/phases/247-ci-critical-path-and-suite-lanes/tools/tail_queue_replay.py (sha256 ca88478f..0a29, equal to `tool_sha256` in the record)
- FOUND: .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-PREDICTION-2.md
- FOUND: b94edfe0 (ancestor of HEAD)
- FOUND: bdfd6ddf (ancestor of HEAD)
- ABSENT, as required on PASS: 247-B6-ESCALATION-2.md, SEED-009, 247-36-SUMMARY.md, 247-37-SUMMARY.md
