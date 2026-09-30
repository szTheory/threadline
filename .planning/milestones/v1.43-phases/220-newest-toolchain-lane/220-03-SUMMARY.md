---
phase: 220-newest-toolchain-lane
plan: 03
subsystem: infra
tags: [ci, elixir-1.20, otp-29, postgres-18, spike, workflow-dispatch]

requires:
  - phase: 220-01
    provides: "refactor commit 17a7faa5 (six D-08 dead-code removals) and the local pre-spike prediction"
  - phase: 220-02
    provides: "commit A 77ff2392 (voting latest row plus fail-closed lane contracts)"
provides:
  - "spike/220-latest (tip 4a32cbf6) = land/v1.43-217-218 + the two code commits, pushed to origin"
  - "SC1 evidence: run 36484105399, where min, current and latest all passed on Elixir 1.20.4 / OTP 29.1.1 / PG 18.6"
  - "220-SPIKE.md with Outcome GREEN, which plan 04 reads"
affects: [220-04]

actuals:
  tokens: 4200
  tasks: 3
  commits: 1
plan_head_before: 8b73e956
plan_head_after: e208c736dcc2e39884132e89d0c6264cd4ad26d3

tech-stack:
  added: []
  patterns:
    - "Spike vehicle: cherry-pick the code commits onto the landing branch in a throwaway worktree, prove tree equality, then dispatch ci.yml against the non-default ref"

key-files:
  created:
    - .planning/phases/220-newest-toolchain-lane/220-SPIKE.md
  modified: []

key-decisions:
  - "Spike outcome GREEN on the first dispatch (run 36484105399). The fix cycle and the flake re-dispatch were not spent: 1 of 2 pushes and 1 of 3 dispatches used"
  - "The latest lane's measured cost is 7 billed minutes on a cold miss, and the whole run billed 58 against a cold-set p50 of 51. The warm per-run delta is still unmeasured"

requirements-completed: [LANE-01]

duration: 15min
completed: 2026-09-28
status: complete
---

# Phase 220 Plan 03: Newest-toolchain dispatch spike Summary

**One `workflow_dispatch` of ci.yml on `spike/220-latest` (run 36484105399, head 4a32cbf6) passed all 16 jobs. That covers `Run test suite (latest)` on Elixir 1.20.4 / OTP 29.1.1 / PostgreSQL 18.6 (compile `--warnings-as-errors`, xref cycles, and 2513 tests passed), and min and current in the same run. The D-11 outcome is GREEN.**

## Performance

- **Duration:** about 15 min, of which the CI run took about 9.5 min
- **Started:** 2026-09-28T21:04Z
- **Completed:** 2026-09-28T21:20Z
- **Tasks:** 3 (Task 2 was resolved by the maintainer's grant)
- **Files created:** 1 (220-SPIKE.md)

## Task 1 (tracer): build and prove spike/220-latest

- `land/v1.43-217-218` local = origin = `fcb22e00c4dc80f9a05a242ccb11b2136dfaaaa2`.
- The worktree `/tmp/threadline-spike-220` holds branch `spike/220-latest`. Two commits were cherry-picked in order:
  - `17a7faa5` became `56015527`;
  - `77ff2392` became `4a32cbf6`.
- There were no conflicts; `mix.exs` auto-merged. Commit B (`5a037db2`) and all `.planning/` commits were excluded.
- **Spike tip:** `4a32cbf6ccf026ffd727d2c183d9aa356431f788`.
- **Tree gate:**
  - `git diff --quiet milestone/v1.43 spike/220-latest -- P` exits 0, where P is the 11 paths the two commits touch.
  - The land..spike name-only diff equals P and has no `.planning/` path.
  - The plan's tracer `<automated>` verify returned 0.
- **Pin re-check** (2026-09-28 21:08 UTC): Elixir `v1.20.4-otp-29`, OTP `OTP-29.1.1`, `postgres:18.6` present, `18.7` and `18.8` absent. There was no drift, so no re-pin was needed.
- **Tracer gate:** the verify was re-run before expansion and passed. The spike was verified end to end, so the plan continued.

## Task 2: grant (resolved before dispatch)

The maintainer resolved this in their own message: "yes i grant both of those go for it no problemo". It replied to an orchestrator message that listed two grants:

- **Grant 1 (used in this plan):** push `spike/220-latest` up to 2 times, and `gh workflow run ci.yml --ref spike/220-latest` up to 3 times.
- **Grant 2 (for plan 04, not used here):** push `land/v1.43-217-218` once, and delete the remote `spike/220-latest`. This plan did not use it.

## Task 3: push, dispatch, classify, record

- **Push:** 1 push (new branch). **Dispatch:** 1, run 36484105399. Its `headSha` equals the spike tip.
- **Verify-test jobs:**
  - min: success (job 109136659655)
  - current: success (job 109136659639)
  - latest: success (job 109136659729)
- **All other jobs:** success, including Browser E2E and `CI required`.
- **Latest evidence:**
  - the cache key names `otp-OTP-29.1.1-elixir-v1.20.4-otp-29`;
  - `docker pull postgres:18.6`;
  - `Compile (warnings as errors)` succeeded (`Compiling 156 files (.ex)`, `Generated threadline app`);
  - `No cycles found`;
  - `Result: 2513 passed (9 properties, 2504 tests), 3 excluded`;
  - 20 test-file warnings, non-fatal. This matches the pre-spike.
- **Classification:** no failures. The fix cycle and the flake re-dispatch were not spent.
- **Cost:**
  - the latest job billed 7 min (378 s);
  - the run billed 58 in total (49.3 unrounded) on a cold miss;
  - 220-SPIKE.md sets these beside the `[inference]` estimate of +6 per run, from a warm 49 to about 55.
- **Record commit:** `e208c736` `docs(220): record the newest-toolchain spike run`. It contains only `220-SPIKE.md`.

## Task Commits

1. **Task 1 (tracer):** commits on the spike branch only, not on milestone/v1.43. They are `56015527` (refactor, cherry-pick of 17a7faa5) and `4a32cbf6` (ci, cherry-pick of 77ff2392).
2. **Task 2:** checkpoint resolved by the grant. No commit.
3. **Task 3:** `e208c736` (docs). Adds 220-SPIKE.md.

## Deviations from Plan

None. The plan was executed as written.

- The pre-spike's +4 test-count difference is expected (commit A's contract tests) and is explained in 220-SPIKE.md.
- The username grep was run on the untracked file directly before staging, because `git grep` does not see untracked files. It printed nothing.

## Next Phase Readiness

- Plan 04 reads `## Outcome` = GREEN. It cherry-picks `56015527` and `4a32cbf6` (or the originals) onto `land/v1.43-217-218` under grant 2, then deletes the remote `spike/220-latest`.
- The worktree `/tmp/threadline-spike-220` and the local `spike/220-latest` are left in place for plan 04.
- The warm per-run cost of the latest lane is still unmeasured, and first warm runs on main will show it.

## Self-Check: PASSED

- FOUND: .planning/phases/220-newest-toolchain-lane/220-SPIKE.md
- FOUND: e208c736 (only 220-SPIKE.md), 4a32cbf6 and 56015527 on spike/220-latest (local and origin)
- Run 36484105399: head 4a32cbf6; min, current and latest all success
