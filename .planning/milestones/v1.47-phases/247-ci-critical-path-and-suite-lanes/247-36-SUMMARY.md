---
phase: 247-ci-critical-path-and-suite-lanes
plan: 36
subsystem: ci-partitioning
status: complete
tags: [ci, tail-queue, landing, preflight, cohort, B6, D-29, D-32, D-33, CI-01, CI-02, CI-03, CI-04]
requires:
  - phase: 247-35
    provides: "247-B6-PREDICTION-2.md gate PASS (runner_sha256, tool_sha256), tools/tail_queue_replay.py preflight (D-33)"
  - phase: 247-34
    provides: "bin/ci-test-partitions lane_tail_k() (current 12, min 0, latest 0), 247-B6-LOCAL-2.md"
provides:
  - "main 11234b01 (PR #99, non-releasable ci: squash): runtime tail queue on the current lane, R3-WR-01..04 fixes, row_key_read clock fix"
  - "247-B6-PREFLIGHT.json: committed P8 preflight GO on PR run 40774253622"
  - "247-B6-MEASUREMENT.json: five attempt-1 successes at the squash, median 461 s"
  - "B6-GATE-JSON (threadline.phase247-b6-gate/1) in 247-MEASUREMENT.md and 247-VALIDATION.md: CI-02 PASS, CI-03 PASS, continuity all true"
affects: ["247-37 (Path S closure: ESCALATION outcome, REVIEW-DISPOSITION, VALIDATION and SECURITY sections, ROADMAP, REQUIREMENTS, STATE)"]
terminal_path: S
hosted_runs_spent: 6
actuals:
  tokens: 8950
  tasks: 3
  commits: 3
plan_head_before: 3d6abd2d37c8391503e806e80079ed1b3f021a8b
plan_head_after: 265253a8339d9450c143183d04446c5a203cd703
tech-stack:
  added: []
  patterns:
    - "Guarded single-dispatch script: main equals the squash, no active ci.yml main run, fewer than 6 runs and fewer than 5 successes, then one dispatch and a bounded watch"
    - "Continuity read from GitHub attempt-1 jobs, artifacts and job logs (ANSI and timestamps stripped), then projected into the gate block by one derivation script"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-PREFLIGHT.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-MEASUREMENT.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-36-SUMMARY.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md
    - .planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
decisions:
  - "B6 is Path S. CI-02 PASS: median 461 s over five attempt-1 successes at main 11234b01. CI-03 PASS: first three are current 1.06/1.02/1.02, min 1.06/1.07/1.06 and latest 1.09/1.05/1.09, all <= 1.15. No 247-B6-ESCALATION-2.md and no SEED-009."
  - "P8 preflight GO on PR #99 attempt-1 run 40774253622: current 1.06 with 12/12 claims and a pooled mean overhead of 1775 ms; min 1.08; latest 1.08; K 12/0/0."
  - "The round-2 prediction was conservative. Predicted CI-02 was 493.8 s against a measured 461 s (-32.8 s). Current worst_8000 was 1.063714 against a measured max of 1.06. The min/latest static replays (1.28/1.32) stayed pessimistic against measured maxima of 1.07/1.09."
  - "SEED-006 reopen_when now uses the 247 B6 measured median 461 s (runs 40775441502..40779961784, slowest job Build and test (current) in three of five runs, up to 469 s). Its status stays closed."
metrics:
  duration: "~79 min (21:20Z-22:39Z), of which ~15 min local ci.all, ~8 min PR run, ~8 min push run and ~33 min serial dispatches"
  started: 2026-10-28T21:20:21Z
  completed: 2026-10-28T22:40:00Z
---

# Phase 247 Plan 36: B6 landing, P8 preflight and final cohort Summary

**The current-lane runtime tail queue reached main as `ci:` squash 11234b01 through PR #99. Its PR attempt-1 run passed the committed P8 preflight (GO). The one capped B6 cohort then closed both open requirements on fresh same-head evidence: CI-02 at a median of 461 s (≤ 540), and CI-03 with all nine first-three ratios between 1.02 and 1.09 (≤ 1.15). This is terminal Path S, so no D-32 fallback was taken.**

## Outcome

| Item | Result |
|---|---|
| Precondition | Met before any push. The prediction-2 block has `gate` PASS, `gate_components` {current ≤ 1.08: true, CI-02 ≤ 510: true} and `k_by_lane` 12/0/0. `runner_sha256` and `tool_sha256` equal HEAD. Round 1's sha256 is still 33fbbc3f…cefe09. LOCAL-2 exists and ESCALATION-2 does not. The remote land branch was absent, and gh auth was ok. |
| Land branch | 14 clean `cherry-pick -x` picks onto main 824c2851, plus the planning sync d7bff1ef. Both tree proofs exit 0. The land diff is exactly the six allowed paths, and the frozen paths are unchanged. |
| Exact-head local gate | Every gate exits 0: `ci_all`, `self_test_env`, `self_test_bin_bash`, `static_identity`, `current_partitioned`, `repo_hygiene` and `branch_protection`. The root suite ran 3388 tests with 0 failures, and the browsers 418 passed with 0 failures. The current lane showed `12 queued, 12 claimed, mean overhead 1267 ms`. |
| PR | #99, head d7bff1ef. One head ran ci.yml, with zero force-pushes. Run 40774253622 attempt 1 succeeded with 17/17 jobs green. |
| Preflight (P8, D-33) | **GO**, with no reasons. Current: ratio 1.06, K 12, 12 claim lines, 12 queued and 12 claimed, 1775 ms. Min: 1.08, K 0. Latest: 1.08, K 0. |
| Merge | `gh pr merge 99 --squash --match-head-commit d7bff1ef…` produced squash 11234b01, which equals `origin/main`. The non-planning tree equals the tested head. The remote branch was deleted. Push run 40775441502 succeeded with 17/17 jobs, and the post-merge branch-protection readback was ok. |
| Cohort | Used 5/6: the push plus 4 guarded serial dispatches, all attempt-1 successes, with 0 exclusions and 0 re-runs. `247-B6-MEASUREMENT.json` has `state` measured and `found` 5. |
| CI-02 | **PASS**. The walls were 455/461/478/479/443 s, for a median of 461 s. |
| CI-03 | **PASS**. First three: current 1.06/1.02/1.02, min 1.06/1.07/1.06, latest 1.09/1.05/1.09. |
| Continuity | CI-01 browser timings, partition timings, the CI-04 self-test tokens (`hang,`, `hang_ignore_term`, `hang_quit`, `tq-hang`, `tq-lane-k`) on all 15 lane logs, the unchanged monitor, the LOCAL-2 hang proof and lane K 12/0/0 on every run: all true. |
| Terminal path | **S**. There is no `247-B6-ESCALATION-2.md` and no SEED-009. SEED-006 moved to the B6 bound. |

## Commits

| Task | Commit | Message |
|---|---|---|
| 1 | f536ed51 | docs(247-36): record B6 landing and preflight |
| 2 | ced1bad8 | docs(247-36): record B6 main cohort |
| 3 | 265253a8 | docs(247-36): record B6 gate verdicts and the D-32 branch |

The land-branch commits (14 picks plus d7bff1ef) landed on main as the single squash 11234b01. They are not on milestone/v1.47, because their sources already are.

## Hosted spend

Six hosted ci.yml runs were spent:
- one PR run (40774253622);
- five main runs at the squash: 40775441502 (push), plus the dispatches 40776626061, 40777747292, 40778862839 and 40779961784.

This is within the cap of two PR heads and six main runs.

## Deviations from Plan

1. **[Process note] Postgres container recreated once.** The first labelled container was started with `-c max_connections=300`. ci.yml's postgres:16 service uses the defaults, so I removed it before any gate ran and started a default container. No gate ran against the first container.
2. **[Process note] `git worktree remove --force`.** The land worktree held copied `deps`/`_build`/`node_modules` caches. Tracked status was clean, so I removed it with `--force`, then deleted the local branch `land/v1.47-ci03-tail-queue` (it was already deleted on the remote).
3. **[Process note] Dependency audit count.** The audit reported 12 non-blocking example-only `bandit` advisories, against B5's 11. The example lockfile is unchanged since 824c2851, so the extra finding comes from the advisory database. This is recorded in Land B6.
4. **[Orchestrator instruction] STATE.md and ROADMAP.md.** The plan's Executor constraints leave ROADMAP/STATE to 247-37. The orchestrator asked for a narrow hand-edit: STATE `completed_plans` 58 → 59 plus the session fields, and a tick on the 247-36 ROADMAP line. That is all I did. REQUIREMENTS.md and the closure sections were not touched.

**Impact:** none on the evidence.

## Verification

- Task 1 `<automated>` (run under bash): `B6 landing: PASS`. The labelled container is gone.
- Task 2 `<automated>`: `B6 cohort serial, runs: 5`.
- Task 3 `<automated>`: `B6 reconciliation: PASS PASS PASS`. The persisted cohort equals a fresh reader run. MEASUREMENT.md and VALIDATION.md have 0 deleted lines since a6bd555c (162 added each).
- `bin/verify-repo-hygiene` was green before every planning commit.

## Requirements

CI-01..04 are not marked complete here. 247-37 closes the round's bookkeeping, and the verifier decides the requirements.

## Known Stubs

None.

## Threat Flags

None. No new surface beyond T-247-97..101: exact-head gates, the `--match-head-commit` squash, the six-run cap with serial guards and no re-runs, and canonical unedited JSON.

## Next

247-37 on Path S. It closes the round's shared records: the ESCALATION outcome, REVIEW-DISPOSITION, VALIDATION and SECURITY sections, the ROADMAP ticks, the REQUIREMENTS line and STATE `stopped_at`.

## Self-Check: PASSED

- FOUND: .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-PREFLIGHT.json
- FOUND: .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-MEASUREMENT.json
- FOUND: f536ed51, ced1bad8, 265253a8 (ancestors of HEAD)
- FOUND: 11234b01 on origin/main
- ABSENT, as required on Path S: 247-B6-ESCALATION-2.md, SEED-009, 247-B6-INCOMPLETE.json
