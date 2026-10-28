---
phase: 247-ci-critical-path-and-suite-lanes
plan: 28
subsystem: ci-measurement
status: complete
tags: [ci, landing, main-cohort, CI-02, CI-03, gap-closure, D-25]
requires:
  - phase: 247-26
    provides: "min-lane fixture isolation (136bb932, 714b4dbb, RetentionHistoryLiveTest worker ownership)"
  - phase: 247-27
    provides: "candidate B min weights (sha256 cb833068…b187) and advisory ci03_expectation EXPECTED_MISS"
provides:
  - "Main 824c28517820c1cd6595f2e0e60b34ec3ce64d14: PR #98 squash of tested land head 14f95621 (non-releasable ci:)"
  - "247-B5-MEASUREMENT.json: unedited bin/measure-main-ci output, measured, five attempt-1 successes, median 457 s"
  - "B5-GATE-JSON (threadline.phase247-b5-gate/1) in 247-MEASUREMENT.md and 247-VALIDATION.md: CI-02 PASS, CI-03 MISS"
  - "SEED-006 reopen bound moved to the 247 B5 measured median 457 s"
affects: ["247 verification", "CI-03 follow-up scope"]
actuals:
  tokens: 8400
  tasks: 3
  commits: 3
plan_head_before: be93b37a8f8ff977262ee9b28b981451e4a8bee7
plan_head_after: ff87e5d16bcd41ae0f990e0c1ea4b185b3a06899
tech-stack:
  added: []
  patterns:
    - "Guarded serial dispatch: main == squash, no active ci.yml main run, and the total below the cap, checked before every dispatch"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B5-MEASUREMENT.json
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md
    - .planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md
key-decisions:
  - "B5 landed as PR #98, squash 824c2851, at the exact tested head 14f95621. That head passed the full local CI=true ci.all and a 17/17 attempt-1 PR run. There was one PR head and no force-push"
  - "Cohort stopped at five attempt-1 successes in 5/6 runs, with no exclusions and no re-runs"
  - "CI-02 PASS at median 457 s, under the 540 s limit"
  - "CI-03 MISS on the current lane (1.17/1.17/1.09). Min (1.07/1.06/1.11) and latest (1.08/1.09/1.06) pass. EXPECTED_MISS is confirmed at the verdict level, but on a different lane than predicted"
  - "Follow-up is a maintainer scope question: the named D-11 split of deps_audit_gate_test.exs and/or a current-lane weight refresh after the 136bb932 colocation change. Neither is implemented, and no further cohort is planned"
requirements-completed: []
coverage:
  - id: D1
    description: "B5 candidate landed on protected main at the exact locally and hosted tested head"
    requirement: CI-03
    verification:
      - kind: other
        ref: "247-28-PLAN.md Task 1 <automated> verify (PR state, force-push timeline, attempt-1 PR run, heads<=2, squash tree, push run)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Single capped serial main cohort, persisted unedited"
    requirement: CI-02
    verification:
      - kind: other
        ref: "247-28-PLAN.md Task 2 <automated> verify (cohort serial, runs: 5)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Derived CI-02/CI-03 verdicts and CI-01/CI-04 continuity, identical in both reports"
    requirement: CI-03
    verification:
      - kind: other
        ref: "247-28-PLAN.md Task 3 <automated> verify (B5 reconciliation: PASS PASS MISS)"
        status: pass
    human_judgment: false
duration: 85min
completed: 2026-10-28
---

# Phase 247 Plan 28: Land B5 and the capped main cohort Summary

**PR #98 landed the min-lane fixture isolation and candidate B weights as main 824c2851. Five serial attempt-1 main successes then gave CI-02 PASS (median 457 s) and CI-03 MISS. The min lane is now balanced (1.07/1.06/1.11), but the current lane missed at 1.17/1.17/1.09.**

## Performance

- **Duration:** about 85 min (local gate about 20 min; PR run 7.4 min; push run plus four dispatches about 42 min)
- **Started:** about 2026-10-28T12:20Z
- **Completed:** 2026-10-28T13:46Z
- **Tasks:** 3 of 3
- **Files modified:** 5 planning files (one created). The land set itself changed six test files on main.

## Accomplishments

- **Task 1 (tracer).** The precondition held: the B5-WEIGHTS record, the hash and EXPECTED_MISS were all present.
  - Land branch `land/v1.47-ci03-min-b5` was cut from main 02d115a3. It holds seven clean `-x` picks (136bb932, 714b4dbb, 14badb2c, d4688d58, eed59aa2, 3b510219, 8ef4b801) plus the planning sync 14f95621.
  - Both tree proofs and the scope proof hold: six test/ files differ, and lib/bin/.github/mix/CHANGELOG are unchanged.
  - Exact-head `CI=true mix ci.all` on postgres:16 exited 0: 3384 tests / 0 failures, example 132/0, Dialyzer 0, browsers 418 passed / 56 skips. The self-test (Bash 5.2 and 3.2), hygiene and branch protection also exited 0.
  - PR #98 run 40690983585 passed 17/17 on attempt 1. The SHA-guarded squash produced 824c2851, and the tree equality check holds. The remote branch was deleted.
  - Push run 40692111621 passed 17/17 on attempt 1. The branch-protection readback exited 0.
  - The tracer verify was re-run end to end and passed before expansion.
- **Task 2.** The guarded serial cohort ran 40692111621 (push, 449 s), then dispatches 40693451272 (457 s), 40694602284 (450 s), 40695763585 (461 s) and 40696978392 (589 s). The 589 s includes runner pickup delay.
  - All five passed on attempt 1. That used 5/6 runs, with no exclusions and no re-runs. Neither B4 failure recurred.
  - `247-B5-MEASUREMENT.json` is the reader's unedited output and equals a fresh read.
- **Task 3.** Identical B5-GATE-JSON blocks went into MEASUREMENT.md and VALIDATION.md.
  - CI-02 PASS (457 s ≤ 540). CI-03 MISS: current 1.17/1.17/1.09, min 1.07/1.06/1.11, latest 1.08/1.09/1.06.
  - Continuity holds on all five runs: CI-01 browser-timings ×2 and partition-timings ×3 are present and unexpired. CI-04's monitor, runner and workflow are byte-identical to B4.
  - SEED-006's reopen bound now uses the B5 median 457 s.

## Task Commits

1. **Task 1: build, gate and merge the B5 land head.** `5438c9f5` (docs). Land-branch commits 5e494ebe…8973fd3b and 14f95621 live on main through squash 824c2851.
2. **Task 2: capped serial main cohort.** `2256c0a2` (docs)
3. **Task 3: gate verdicts and continuity.** `ff87e5d1` (docs)

## Measured verdicts (fixed limits 540 s / 1.15)

| Requirement | Verdict | Evidence |
|---|---|---|
| CI-01 continuity | holds | both browser-timings artifacts on all five runs |
| CI-02 | **PASS** | median 457 s over 40692111621, 40693451272, 40694602284, 40695763585, 40696978392 |
| CI-03 | **MISS** | current 1.17 / 1.17 / 1.09 (two values above 1.15); min and latest pass |
| CI-04 continuity | holds | monitor/runner/workflow unchanged since 02d115a3; partition timings on every run |

Plan 27's `ci03_expectation` EXPECTED_MISS is confirmed at the verdict level, which is not a plan failure. The mechanism differs from the prediction, though. The predicted min-lane miss did not happen: min now passes. The current lane missed instead, after passing on B4 (1.12/1.11/1.12). Its weights and runner are unchanged. Its inputs changed through the 136bb932 colocation group and the `local_test.exs` async flip. A read-only local assignment puts that group in current partition 3 and `deps_audit_gate_test.exs` in partition 2, while partition 4 is the measured slow side. The cause is not established.

## Decisions Made

See `key-decisions`. CI-02 and CI-03 are not marked complete in REQUIREMENTS.md, and the phase is not marked complete. Those calls belong to the verifier.

## Deviations from Plan

**1. [Process note] `git add .planning` inside the scratch land worktree.** `git checkout milestone/v1.47 -- .planning` had already staged the sync, so the extra `git add` was redundant. It ran in a fresh land worktree with no untracked planning files. The tree proof `git diff --quiet milestone/v1.47 HEAD -- .planning` exits 0, so nothing beyond the tracked snapshot was committed. The source root never used a wholesale add.

**2. [Rule 1 - Bug] Fixed a garbled cell in my own chronology table before committing.** The first row's created-at cell read "13:04:46Z → created 12:57:17Z". It was corrected to 12:57:17Z, the run's real created_at, before the Task 2 commit.

**Total deviations:** 1 self-corrected bug and 1 process note. **Impact:** none on the evidence.

## Issues Encountered

- The CI-03 miss moved from the min lane to the current lane. It is recorded as a maintainer scope question, with no re-sampling and no threshold change (D-25).
- The last cohort run's 589 s wall is inflated by GitHub runner pickup delay; jobs started 40–116 s after creation. It is counted in full, as the canonical reader requires.

## Next Phase Readiness

CI-02 now has fresh same-head main evidence. CI-03 remains a gap on the current lane. The scope question for the maintainer: does the named D-11 split of `test/threadline/deps_audit_gate_test.exs`, a current-lane weight refresh from B5 timings, or both address the current-lane spread? Any choice needs a new sampling budget. Phase 247 verification is next.

## Known Stubs

None.

## Threat Flags

None. No new surface was added. The PR, merge and dispatches stayed within the T-247-60/61 mitigations: exact-head guards, the six-run cap and serial guards.

## Self-Check: PASSED

- FOUND: 247-B5-MEASUREMENT.json, Land B5 section (exactly one `B5 tested land HEAD` line), B5-GATE-JSON in both reports, SEED-006 B5 bound
- FOUND commits: 5438c9f5, 2256c0a2, ff87e5d1 (ancestors of HEAD), and main squash 824c2851
- Task 1, 2 and 3 automated verifies all passed. No container labelled `dev.threadline.plan=247-28` remains, and the land worktree is removed
