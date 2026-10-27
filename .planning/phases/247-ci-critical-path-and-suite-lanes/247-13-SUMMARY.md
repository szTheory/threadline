---
phase: 247-ci-critical-path-and-suite-lanes
plan: 13
subsystem: ci
status: complete
tags: [ci, landing, measurement, d-08, d-12, ci-02, ci-03, seed-006]
requires:
  - phase: 247-11
    provides: "browser split assertions (fan-in rules pinned)"
  - phase: 247-12
    provides: "CI-derived current-lane partition weights and fitted async factor"
provides:
  - "Land B2 on main: squash 29abf565 (PR #95), main equals milestone/v1.47 outside .planning"
  - "247-MEASUREMENT.md: CI-02 median 468 s over 5 attempt-1 main runs (PASS), CI-03 ratios over 3 runs per lane (MISS), D-11 per-lane fallback spec"
  - "SEED-006 reopen_when cites the 247 measured median and critical path"
  - "bin/measure-main-ci feature-detects gh --allow-escape-sequences (gh 2.101+)"
affects: [247-gaps, 247-verification, SEED-006]
tech-stack:
  added: []
  patterns:
    - "Gate measurement on main only, attempt 1, via the committed read-only bin/measure-main-ci"
    - "gh capability probe from `gh api --help`, run only when the flag is needed"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md
  modified:
    - bin/measure-main-ci
    - test/threadline/measure_main_ci_contract_test.exs
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md
    - .planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md
decisions:
  - "CI-02 PASS: median ci.yml wall 468 s (runs 40413601357, 40414924903, 40416330436, 40417290637, 40418204130), baseline 724 s; critical path is now Build and test (current)"
  - "CI-03 MISS: max/min current 1.20/1.26/1.42, latest 1.48/1.58/1.43, min 1.57/1.61/1.59; threshold 1.15 not relaxed; D-11 per-lane weights for min/latest is the gap-closure fallback"
  - "The D-08 shard fallback is not needed: CI-02 passed and the two browser legs are balanced (median 367 s each)"
  - "Local ci.all run 1 red on two time-sensitive as_of cases outside the B2 diff; the orchestrator took run 2 (green, same tree) as the local gate and PR CI as the deciding gate"
  - "SEED-006 status stays closed; only the second reopen_when clause changed"
metrics:
  duration: "Task 3 ~10 min (continuation); Tasks 1-2 in prior sessions"
  completed: 2026-10-26
  tasks: 3
  files: 6
actuals:
  tokens: 5000
  tasks: 3
  commits: 4
plan_head_before: d1e66aff256b9c991c8548237a4cf2c2f87b5538
plan_head_after: 0615f19641ffefd3e3cc615c0fbf5d42e80fb884
requirements: [CI-02, CI-03]
requirements-completed: [CI-02]
---

# Phase 247 Plan 13: Land B2 and measure the phase gates on main Summary

The browser split and the CI-derived partition weights are on main (PR #95, squash `29abf565`).
Across five attempt-1 main runs, the median ci.yml wall is 468 s, down from 724 s, so CI-02
passes (≤ 540 s). CI-03 misses: no lane's partition ratio reached 1.15. The current lane
improved to 1.20–1.42. The min and latest lanes did not improve (1.43–1.61), because they run
a file subset on the current-lane weights. SEED-006's reopen bound now cites the measured
median.

## Tasks

| Task | Name | Commit | Notes |
|------|------|--------|-------|
| pre-req | measure-main-ci gh 2.101 escape-flag fix | `d1261dfd` | feature-detected flag, fake-gh covers both gh generations |
| 1 | Final gate, build and prove land/v1.47-b2 | `34459626`, `ae27692c` | ci.all run 1 red (2 `as_of` wall-clock flakes outside B2), run 2 green; land head `e85195da`, tree equal to milestone |
| 2 | Maintainer lands B2, 5 main samples | (orchestrator) | PR #95 run 40412545694, 17/17 green, no 403; squash `29abf565`; 5 sequential samples, all success |
| 3 | Measure, write 247-MEASUREMENT.md, SEED-006 | `0615f196` | CI-02 PASS 468 s; CI-03 MISS; SEED-006 rewritten; `## Miss` with the D-11 fallback |

## Gate results (main)

| Gate | Measured | Verdict |
|------|----------|---------|
| CI-02 median, 5 runs, ≤ 540 s | 468 s (414 / 438 / 468 / 595 / 671) | PASS |
| CI-03 max/min, 3 runs per lane, ≤ 1.15 | current 1.20 / 1.26 / 1.42; latest 1.48 / 1.58 / 1.43; min 1.57 / 1.61 / 1.59 | MISS |
| Receipt reconciles both legs | PR run 40412545694: `Validated 31 named journeys across desktop-chromium, mobile-chromium.`; artifact `operator-ci-evidence-40412545694` | PASS |
| Branch protection | `bin/verify-branch-protection`: `CI required` is the single required context | PASS |
| D-12 order coupling | 15 lane jobs across the 5 runs, all 0 failures | PASS |

`bin/measure-main-ci` selected exactly the five dispatched runs, with no exclusions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] bin/measure-main-ci failed on gh 2.101 job-log reads**
- **Found during:** Task 1 pre-requisite (deferred from 247-08)
- **Issue:** gh 2.101 refuses ANSI job logs without `--allow-escape-sequences`, and older gh rejects that flag.
- **Fix:** the script probes `gh api --help` once, only under `--ratios`. Two fake-gh contract cases pin the choice.
- **Files modified:** bin/measure-main-ci, test/threadline/measure_main_ci_contract_test.exs
- **Commit:** `d1261dfd`

### Process notes

- The local ci.all gate was red on run 1 because of two time-sensitive `as_of` cases outside
  the B2 diff. Both passed in isolation with the same seed and with 4 more seeds. The
  orchestrator decided to take run 2 (green, unchanged tree) as the local gate, with PR CI as
  the deciding gate. This is recorded in 247-LANDING `### Landed`, and the flake is in
  deferred-items.md.
- CI-03 is a recorded miss, not a deviation. The thresholds were not relaxed and no run was
  dropped. CI-03 stays unmet in REQUIREMENTS.

## Known Stubs

None.

## Next

CI-03 gap closure: `/gsd-plan-phase 247 --gaps`. Add per-lane weights for min and latest from
the existing `partition-timings-<lane>-<run>` TSVs via `bin/ci-test-partitions
--ingest-weights <dir> --lane min|latest`, re-ingest the current lane from the post-B2 TSVs,
then re-measure 3 main runs per lane. A miss that remains after that is a maintainer scope
decision.

## Self-Check: PASSED

- FOUND: 247-MEASUREMENT.md, 247-LANDING.md `### Landed`, SEED-006 `247 measured median`
- FOUND commits: d1261dfd, 34459626, ae27692c, 0615f196 (ancestors of HEAD)
- FOUND: origin/main 29abf565 equals milestone/v1.47 outside .planning
- Temp land worktree removed; local branch `land/v1.47-b2` kept
