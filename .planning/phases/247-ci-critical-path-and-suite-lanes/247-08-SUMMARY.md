---
phase: 247-ci-critical-path-and-suite-lanes
plan: 08
subsystem: ci
tags: [landing, squash-merge, ci-observation, playwright-timings, partition-monitor, hang-repro]
status: complete

requires:
  - "247-02 Land A2 (removal squash 9f69a904 on origin/main)"
  - "247-03..07 (CI-01 slow-specs, D-13 PartitionMonitor, D-14/D-15 watchdog and timeouts, D-12 ratio row, D-09/D-10 lane scope, bin/measure-main-ci)"
provides:
  - "Land B1 on origin/main: squash 3463fa7416696578faa8a9933de0900e61dc9d48 `ci: publish browser spec timings, name hung tests, and scope repo contracts to the current lane (247)` (PR #94, green run 40392212575, non-releasable)"
  - "247-OBSERVATION.md: 3 main runs (40394247390, 40396194471, 40398138085; median wall 764 s), CI-01 top 20 and per-project/per-file totals, pre-refresh partition ratios per lane, CI-02 split inputs, weights-refresh artifact names, the D-16(c) repro evidence and the SC4 sentence for VERIFICATION"
  - "CI-04 live proof: repro run 40387548421, `Build and test (min)` job 121799736736 red with exit 1 in 525 s, naming `Threadline.ZzHangReproTest (setup_all)` with its stack (in-VM monitor path)"
  - "D-13 Elixir 1.15 proof: B1 PR min-lane job 121815845365 green with 4 partition-timings TSVs"
affects: [247-10, 247-12, 247-13, "CI-02 split design", "CI-03 weights refresh"]

actuals:
  tokens: 10000   # chars/4 over the 247-08 diff (39994 chars incl. the f839f116 test fix)
  tasks: 3
  commits: 4      # measured at SUMMARY write: git rev-list --count plan_head_before..HEAD; this SUMMARY's commit makes 5
plan_head_before: f47de58ad3b350c91299b6e615d1ca4b22719851
plan_head_after: 4f9925011e11e9d4d6ebb890972d26be28c96b77

tech-stack:
  added: []
  patterns:
    - "Read-only GH_BIN shim to get past gh 2.101's escape-sequence refusal without changing committed code"
    - "Projected per-leg wall = project total + share of unattributed + per-leg fixed costs (in-step compile/boot + job setup), measured from step timings"

key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-OBSERVATION.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-08-SUMMARY.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
    - test/threadline/partition_monitor_test.exs

key-decisions:
  - "247-08: the CI-02 split keeps the 9 min step / 12 min job per-leg timeouts. The projected heaviest leg is mobile-chromium at 365 s step / 427 s job, and the projected run wall is about 457 s (7.6 min). The observed share is 51/49, so neither the 60/40 nor the 65/35 band applies"
  - "247-08: stress_router_test.exs is about 21 % of an even current-lane share (66.4 s against 318.5 s), so the D-11 split-by-module contingency is not triggered. stress_router_prod_compile_test.exs is about 2.6× under-weighted and should show in the ingest's moved list"
  - "247-08: CI-04's repro fired on the in-VM monitor path (partition exit 1 at 450 s), not on the bash watchdog (124)"
  - "247-08: CI-03 is left Pending. The lane scope landed, but every lane's ratio is still 1.44–1.68 before the weights refresh (247-12)"

metrics:
  duration: "about 6.5h wall clock, most of it the PR CI runs, the test-fix round and the three sequential main runs"
  completed: 2026-10-26
---

# Phase 247 Plan 08: Land B1 Summary

**B1 is on origin/main as squash `3463fa74` (PR #94). It carries CI-01 slow-spec timings, the D-13 partition monitor, the D-14/D-15 watchdog and timeouts, the D-12 ratio row, the current-lane repo-contract scope and the measurement script. Three main runs were read: 764 s median wall; browser legs projected at about 7.6 min run wall after the split. A throwaway `setup_all` hang went red on the min lane in 525 s, naming `Threadline.ZzHangReproTest (setup_all)`.**

## Performance

- **Started:** 2026-10-26 (Task 1 commit 2c298c23 at 15:05 local)
- **Completed:** 2026-10-26
- **Tasks:** 3 (Task 2 was the push/PR/merge/dispatch checkpoint, which the orchestrator ran)
- **Files modified:** 3 planning files, 1 test file (+ this SUMMARY)

## Accomplishments

- Pinned `B1_END` = `be29f3c7`, built `land/v1.47-b1` (20 picks + planning sync), proved its tree equals `B1_END` outside `.planning`, and gated it with `CI=true mix ci.all` green on an ephemeral postgres:16 (3361 tests, 132 example tests, Dialyzer clean, 418 browser tests passed).
- B1 PR #94: the first run failed on `partition_monitor_test.exs` on current and latest. The fix went in as `f839f116` (milestone) / `525ea1d5` (land), and the second run `40392212575` was all green. Squash-merged, and the squash tree equals the land head.
- Read main runs 40394247390 / 40396194471 / 40398138085 (777 / 764 / 756 s): every browser-timings artifact has a 20-row top. Mean project time is mobile 333.6 s and desktop 321.1 s (51/49), with 16.2 s unattributed.
- Wrote the CI-02 split inputs: per-leg projections with the arithmetic, provisional 9/12 timeouts with the margins against the worst case, and the 60/40 and 65/35 reference points.
- Recorded the weights-refresh inputs: three `partition-timings-current-<run>` artifacts and the `stress_router_test.exs` share check.
- D-16(c): recorded the repro's partition row (`| 2 | 1 | 450 | no tests |`), the `HANG: in-flight:` block, the `Process.sleep/1` → fixture → `run_setup_all/2` stack, and the SC4 sentence. Also stated that the PR #89 attempt-1 log is unrecoverable.
- Cleaned up: the land and repro worktrees are removed (local branches kept), no containers are left, and the remote branches were deleted by the orchestrator.

## Task Commits

1. **Task 1: Tracer — gate, build land/v1.47-b1, tree proof, prepare the repro branch.** `2c298c23` (docs)
2. **Deviation fix: partition monitor test made load- and version-robust.** `f839f116` (test), land-branch pick `525ea1d5`, note `759ab625` (docs)
3. **Task 2: Push, PR, merge, main dispatches and repro dispatch.** Run by the orchestrator; no repo commit.
4. **Task 3: Observation and Land B1 merge record.** `4f992501` (docs)

## Files Created/Modified

- `.planning/phases/247-ci-critical-path-and-suite-lanes/247-OBSERVATION.md`: the CI-01 data, ratios, split and weights inputs, and the repro evidence.
- `.planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md`: `## Land B1`, covering the branch, gate, fix deviation and merge table.
- `.planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md`: the `measure-main-ci` gh escape-sequence issue.
- `test/threadline/partition_monitor_test.exs`: the retry-on-inconclusive deadline ladder, and acceptance of both ExUnit summary formats.

## Decisions Made

See `key-decisions` in the frontmatter. CI-01 and CI-04 are marked complete. CI-03 stays
Pending until the 247-12 weights refresh brings each lane to a ratio of 1.15 or less over
3 runs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] partition_monitor_test failed on the current and latest lanes in B1 PR run 40387745942**
- **Found during:** Task 2 (PR CI)
- **Issue:** The 2000 ms VM-wall sandbox deadline fired during code loading on a loaded runner (current lane). The pass assertion did not accept ExUnit 1.19+'s `Result: N passed` (latest lane).
- **Fix:** Each fixture writes a hang-entry marker. The test retries on a 2000 → 8000 → 30000 ms ladder until a run is conclusive and still asserts strictly. Both summary formats are accepted.
- **Files modified:** `test/threadline/partition_monitor_test.exs`
- **Commit:** `f839f116` (land pick `525ea1d5`)

**2. [Rule 3 - Blocking] `bin/measure-main-ci --ratios` exits 1 on gh 2.101**
- **Found during:** Task 3
- **Issue:** `gh api …/jobs/<id>/logs` refuses ANSI output unless `--allow-escape-sequences` is passed.
- **Fix:** No code change. A read-only `GH_BIN` shim in the session scratch dir adds the flag (the script already exposes the `GH_BIN` seam). The script fix is logged in `deferred-items.md` for 247-12 / 247-13, because this plan's files are planning-only.
- **Commit:** none (logged in `4f992501`)

## Issues Encountered

- One transient `gh: HTTP 503` on the first measurement attempt. The retry succeeded.
- Runner noise is large: the current lane's file-wall sum varied 971–1465 s on the same head.
  The weights refresh must take medians, and the ratio claim needs 3 runs.

## Next Phase Readiness

- 247-10 (CI-02 split) has the per-project totals, fixed per-leg costs and provisional
  9 / 12 timeouts.
- 247-12 (weights refresh) has three `partition-timings-current-<run>` artifacts. It needs the
  `measure-main-ci` gh fix, or the same shim, before it re-measures.
- 247-13 (Land B2) derives its range from `B1 end SHA: be29f3c7…` in 247-LANDING.md.

## Self-Check: PASSED

- FOUND: 247-OBSERVATION.md, 247-LANDING.md (`## Land B1` with the merge table), deferred-items.md
- FOUND commits on HEAD: 2c298c23, f839f116, 759ab625, 4f992501
- FOUND on origin/main: 3463fa74 (B1 squash)
- Plan Task 3 automated verify: exit 0
