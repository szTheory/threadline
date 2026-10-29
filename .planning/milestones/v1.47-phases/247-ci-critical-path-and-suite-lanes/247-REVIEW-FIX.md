---
phase: 247-ci-critical-path-and-suite-lanes
fixed_at: 2026-10-28T23:59:00Z
review_path: .planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW.md
review_round: R4
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 247: Code Review Fix Report (Round R4)

**Fixed at:** 2026-10-28T23:59:00Z
**Source review:** .planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW.md (round R4)
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (R4-WR-01, R4-WR-02, R4-WR-03; scope `critical_warning`)
- Fixed: 3
- Skipped: 0
- Out of scope: R4-IN-01..08. The only R4-IN-05 work done was the self-test cases
  added as regression proof for each warning, listed under each fix below.

All three findings are logic and race fixes in the claim path. Tier 1/2 checks only prove
syntax. Each fix therefore also adds a `--self-test` case, and that case was shown to fail
against a mutant that undoes the fix. Re-running the self-test is the automated proof that
the logic is correct, so no human verification is needed.

## Fixed Issues

### R4-WR-01: The stale-lock break can steal a live lock, and an ownerless lock can never be broken

**Files modified:** `bin/ci-test-partitions`
**Commit:** 4e91b3fb
**Status:** fixed (logic change; self-test regression case added)
**Applied fix:** The reviewer's recommended shape. `claim_next` acquires the lock with
`ln -sn <i> tail-queue.lock`. The symlink and its owner are created in one atomic step, so
the lock is never ownerless. `-n` keeps `ln` from descending into a directory named after
the target. The in-claimer stale breaker is removed: a claimer never removes a lock it does
not hold. `release_tail_lock` (`readlink`-keyed, called only from the watchdog's
`stop_over_budget` and from `kill_all`, both in the runner process) is the only breaker. A
lock timeout now names the holder: `tail-queue lock timeout (held by partition N)`. The
header comment is updated to match.
**Regression proof:** `tq-lock-stale` is replaced by:
- `tq-lock`: a lock held by a partition that has a status file is not broken. The claim
  times out naming the holder and takes nothing. Release is keyed on the index. After that
  the claim is taken and the lock is gone.
- `tq-lock-contention`: 4 concurrent claimers wait behind a seeded lock until the single
  breaker frees it. No claimer may break the lock. Every one of 6 seqs is claimed exactly
  once. The case runs 5 rounds.

The `tq-basic` and `tq-contention` "lock gone" checks now also test `-L`, because a
dangling symlink is not `-e`. A mutant that restores in-claimer breaking fails `tq-lock`.
**Residual:** If the watchdog's `readlink` lands within the same instant as a KILLed
holder's in-flight `unlink` syscall, the release could in theory remove a lock that a
sibling had just taken. That window is microseconds wide, much narrower than the
multi-breaker race fixed here. It still fails closed: `verify_claims` would catch a
duplicate claim.

### R4-WR-02: A partition with its deadline spent keeps claiming, and each claim dies at once with a false `HANG` report

**Files modified:** `bin/ci-test-partitions`
**Commit:** 8d4ff4b5
**Status:** fixed (logic change; self-test regression case added)
**Applied fix:** Adds the constant `TAIL_CLAIM_MIN_MS=15000`. It is a constant, not a
seam, so ci.yml stays seam-free and the `@tail_queue_seams` contract list is unchanged.
`claim_next` takes a 4th argument, the claim-by time in epoch ms (0 when the deadline is
disarmed). Under the lock, after any lock wait and before `next` advances, it consumes
nothing once that time has passed and sets `CLAIM_STOP=budget`. The claim loop sets
claim-by to `p_start*1000 + deadline_ms - TAIL_CLAIM_MIN_MS`. When claiming stops, it
prints `partition <i>: <n> ms of in-VM budget left; claiming no more` to stdout and the
partition log and breaks. The unclaimed rest fails `verify_claims`, which names it. The
1 ms `inv_deadline` clamp in `partition_invoke` is removed.

This differs from the review's sketch in one way: the check runs inside `claim_next`
under the lock, not before it. A long lock wait therefore cannot start a claim on a spent
deadline.
**Regression proof:** `tq-deadline-spent`: a 46 s budget arms a 16000 ms deadline, and the
static set takes 1.1 s. The run must claim nothing, start no claim BEAM (no `p1-1.log`),
print the stop line, report no `HANG`, and fail `verify_claims`. The old code claims and
fails this case. `tq-deadline` (the 480 s budget, where the claim runs) still passes as the
positive control.

### R4-WR-03: A TERM that arrives during `claim_next` still claims and starts a new BEAM after the stop

**Files modified:** `bin/ci-test-partitions`
**Commit:** 100fc074
**Status:** fixed (logic change; self-test regression case added)
**Applied fix:** This takes the review's "better" variant plus the fallback recheck:
- `claim_next` checks `stop_claims` (set by the subshell's TERM trap) and
  `partition-<i>.budget` under the lock, before `next` advances. A stopping partition
  consumes no row (`CLAIM_STOP=stopped`) and releases the lock.
- In the claim loop, a stop that lands after the row was taken writes an `unrun` row,
  fails the partition, and forks no BEAM.
- `verify_claims` now also requires a `done` row for every `claim` row. It prints
  `these tail queue claims never finished (no done row)` with the partition, seq and file.
  It still prints the existing coverage diff separately.
- The header comment is updated to match.

**Regression proof:** `tq-stop-claim`:
- It sends TERM to a claimer while that claimer waits on a held lock, then the single
  breaker releases the lock. Expected: `CLAIM_STOP=stopped`, no claim row, `tail-queue.next`
  not written, lock gone.
- It repeats the check with a budget record in place of the TERM.
- It proves that `verify_claims` fails a claim that has only an `unrun` row and names it,
  and passes once a `done` row is added.

A mutant without the under-lock check takes the row (`claim 1 test/a/heavy1_test.exs`).
`tq-hang` still passes. Its killed claims now also show up as unfinished, which is accurate.

## Contract impact

`test/threadline/ci_topology_contract_test.exs` needed no change:
- No new `CI_TEST_PARTITIONS_*` seam, so ci.yml stays seam-free.
- The single canonical `mix test` invocation site is unchanged.
- New ok-line tokens (`tq-deadline-spent`, `tq-lock`, `tq-lock-contention`,
  `tq-stop-claim`) are inserted before `, tq-lane-k)`, so the `tq-lane-k` ok-token
  mutant still changes the script.

The ok line drops `tq-lock-stale` in favour of `tq-lock`. No contract pins that token.

## Verification

All verification ran in the `quality-baseline` git worktree (branch `milestone/v1.47`),
which has its own `deps/` and `_build/`.
- `/bin/bash -n bin/ci-test-partitions` passed after each fix.
- `/bin/bash bin/ci-test-partitions --self-test` (macOS bash 3.2.57) exited 0 after each fix.
  The final ok line includes `tq-deadline-spent, tq-lock, tq-lock-contention, tq-stop-claim`.
- `mix test test/threadline/ci_topology_contract_test.exs`: 35 tests, 0 failures.
- Mutation checks: restoring in-claimer stale breaking fails `tq-lock`. Removing the
  under-lock stop check makes the TERM scenario take the row. The pre-fix code claims in
  the `tq-deadline-spent` scenario.
- The full suite and playwright were not run, as instructed.

Isolation note: `workflow.use_worktrees` is `true`, but no nested review-fix worktree was
created. The caller directed all work to happen in place in this worktree. The hand-rolled
cleanup tail would also have fast-forwarded the main checkout's branch, which is a
different branch. So the fixes were committed directly on `milestone/v1.47`. No recovery
sentinel was written, and no temp branch was created.

---

_Fixed: 2026-10-28T23:59:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
