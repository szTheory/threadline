---
phase: 247-ci-critical-path-and-suite-lanes
round: R4
scope: incremental review of gap plans 29-37 (diff vs 2f0148e03ffbb80d3dc12ce025ad71520183a7e0)
reviewed: 2026-10-28T23:07:28Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - bin/ci-test-partitions
  - CONTRIBUTING.md
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/query/row_key_read_test.exs
  - test/threadline/retention/pruner_test.exs
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/tail_queue_replay.py
findings:
  critical: 0
  warning: 3
  info: 8
  total: 11
status: issues_found
---

# Phase 247: Code Review Report, Round R4 (incremental, Plans 29–37)

**Reviewed:** 2026-10-28T23:07:28Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

Earlier rounds are in git history; round R3 (Plans 26–28) was the previous content of this
file. Finding ids here use the `R4-` prefix so they do not collide with earlier rounds.

## Summary

The eight files changed in `git diff 2f0148e0 HEAD` were reviewed. Most of the effort went
into the runtime tail queue in `bin/ci-test-partitions` (D-27/D-32): `select_tail_queue`,
`verify_tail_queue`, `claim_next`/`release_tail_lock`, `partition_invoke`,
`merge_partition_timings`, `verify_claims`, the per-partition claim loop, and how all of
these interact with the watchdog and `kill_all`. Lock behaviour was not judged from the code
alone. The production `claim_next`/`release_tail_lock` bodies were extracted into a
scratch harness (outside the repo) and run with 4–8 concurrent claimers against a
pre-seeded stale lock.

What holds up:

- **Exactly-once is fail-closed end to end.** `verify_tail_queue` checks static ∪ queue
  against the enumerated set before anything runs. `verify_claims` checks claimed ==
  queued with no duplicates afterwards and sets `fail=1`. Every lock anomaly found below ends
  in a red run (duplicate claim, lock timeout, or unclaimed rest), never a green run that
  skips a file. No fail-open path was found in the claim loop, in exit-status aggregation
  (first non-zero `INV_STATUS` wins; lock timeout and merge failure each force 1), or in
  the watchdog hand-off (`.budget` is written first and the subshell exits 124 without
  writing a status).
- **One deadline across invocations is correct.** The monitor's deadline is VM-relative
  (`:erlang.statistics(:wall_clock)`), so `deadline_ms - 1000 × elapsed` makes every claim
  VM end at the same wall instant as the static deadline. A disarmed deadline (≤ 0) is
  passed through unchanged, as `tq-deadline` proves.
- **bash 3.2.** Checked on macOS `/bin/bash` 3.2.57. `${#list[@]}` on an empty `local`
  array under `set -u` is safe. The `files=("$CLAIM_FILE")` / `${monitor_args[@]+…}`
  forms, here-strings and `+=` are all 3.2-safe. Prefix assignments before `run_case`
  (`case_tail_k= …`) are scoped to the call, so the legacy cases really run at K=0.
  `now_ms` falls back correctly on BSD `date`, which prints `%3N` literally.
- **R3 fixes verified.** R3-WR-01: both retention modules register `on_exit` cleanup in
  `setup`. R3-WR-02: `ratio_of` fails closed. R3-WR-03: `placed()` is gone and the runner
  always runs in `stage_copy`. R3-WR-04: `lane_rule`, `--rule`, the strict mismatch exiting
  2, the contract mutant and the CONTRIBUTING sentence are all present and correct.
- **`row_key_read_test` clock fix is sound.** `clock_timestamp()` is the stamping clock in
  the capture trigger, and `as_of_query` compares `captured_at <= ^timestamp`.
- **Contract tests have working mutants:** TAIL_QUEUE_K=4/13, a min lane that queues again,
  lane_rule min→median, a missing ok-token, a second invocation site, and seams in ci.yml.
  The `nil` env entries really unset the seam.

No blockers. The three warnings are races and signal-ordering defects in the claim path.
Each fails closed, but each can turn a run red for the wrong reason or misreport why it went
red. That undercuts D-14's "a hung partition fails fast and names itself".

## Warnings

### R4-WR-01: The stale-lock break can steal a live lock, and an ownerless lock can never be broken

**File:** `bin/ci-test-partitions:663-692` (`claim_next`), `698-703` (`release_tail_lock`)
**Issue:** Two independent defects in the `mkdir` lock protocol.

1. **ABA between the owner read and the rename.** A poller reads `owner=X` (666), sees
   `partition-X.status` (667), then `mv`s whatever is at `$lock` at that moment (669). If
   another poller B broke the same stale lock and took a fresh one in between, A renames
   and `rm -rf`s **B's live lock**, then takes its own. A and B now both believe they hold
   the lock. B's later `rm -f "$lock/owner"; rmdir "$lock"` (691-692) then deletes A's lock
   too, and the problem cascades. Both read the same `tail-queue.next` and claim the same
   seq. Measured with the production function bodies in a scratch harness (4 claimers, a
   seeded stale lock owned by a partition with a status file, and 0–40 ms of scheduler
   delay inserted only between the owner read and the status test): 60 trials, **2 trials
   claimed one seq twice**. The successful breaks removed 89 live locks owned by partitions
   1–4 and 14 live locks that had no owner file yet, against only 60 genuine stale ones.
   Without the inserted delay, 100 trials on an idle machine showed no live-lock break, so
   the window is narrow but real. The outcome is a file run twice on two partitions and
   `verify_claims` failing the run with "do not cover the queue exactly once".
2. **Ownerless windows.** The lock exists without an `owner` file between `mkdir` (663)
   and `printf … >"$lock/owner"` (681), and again between `rm -f "$lock/owner"` (691) and
   `rmdir` (692). A holder that is KILLed in either window leaves a lock that neither
   `release_tail_lock` (owner `""` ≠ i) nor the stale rule (`[ -n "$owner" ]`) will ever
   remove. Every other partition then spins for `CI_TEST_PARTITIONS_LOCK_WAIT_S` (30 s) and
   fails with "tail-queue lock timeout", and the rest of the queue never runs. This is
   reachable when `CI_TEST_PARTITIONS_KILL_GRACE_S=0` (as in the self-test) or whenever a
   group KILL lands mid-claim. One stuck partition is then reported as N partitions with lock
   timeouts.

In production the stale path is nearly dead code. Every way an owner dies (`stop_over_budget`,
`kill_all`) already calls `release_tail_lock` from a single process. The in-claimer
breaker adds the multi-breaker race without covering a case the watchdog does not already
cover.
**Fix:** Make acquisition and ownership one atomic step, and keep the breaker to one process:

```bash
# acquire: a symlink is created atomically with its target, so there is no ownerless window
while ! ln -s "$i" "$lock" 2>/dev/null; do
  # no in-claimer stale breaking; the watchdog/kill_all release a dead owner's lock
  if [ "$polls" -ge $((wait_s * 10)) ]; then ...; return 1; fi
  sleep 0.1; polls=$((polls + 1))
done
...
rm -f "$lock"            # release

release_tail_lock() {    # single breaker: watchdog / kill_all only
  [ "$(readlink "$2/tail-queue.lock" 2>/dev/null || true)" = "$1" ] || return 0
  rm -f "$2/tail-queue.lock"
}
```

If in-claimer breaking has to stay, re-read the renamed directory's `owner` after a
successful `mv`. If it is not the stale owner you read, you have broken a live lock: fail the
partition loudly instead of continuing, and add a contention case to `tq-lock-stale`
(see R4-IN-05).

### R4-WR-02: A partition with its deadline spent keeps claiming, and each claim dies at once with a false `HANG` report

**File:** `bin/ci-test-partitions:1152-1156` (`partition_invoke`), `1365-1386` (claim loop)
**Issue:** If the static set (or earlier claims) finishes with less than about a BEAM boot left
of `deadline_ms`, `inv_deadline` is clamped to 1 ms and the claim still starts. The monitor
halts at its first check (`now >= deadline`) with `print_report(…, "deadline 1 ms")` and
`System.halt(1)`. Then the loop claims the next file and does the same thing, until the
queue is empty or the watchdog fires at the budget. For example: budget 480 s,
`deadline_ms` 450000. Partition 2's static set finishes at 449 s, so claim 1 gets 1000 ms and
every later claim gets 1 ms. Each claim burns a full `mix` boot, prints a `HANG: in-flight:`
block, and is recorded with `exit=1`. Nothing hung; the budget ran out. The step summary
and logs blame several innocent queued files. Before the tail queue, the same partition
would simply have exited at 449 s. The run is red either way, but it is red with the wrong
diagnosis, and in-VM hang attribution is exactly what D-14 is meant to provide.
**Fix:** Stop claiming once the remaining in-VM budget cannot cover a claim. Leave the
unclaimed rest to `verify_claims`, which already names it:

```bash
# in the claim loop, before claim_next
if [ "$deadline_ms" -gt 0 ]; then
  left=$((deadline_ms - 1000 * ($(date +%s) - p_start)))
  if [ "$left" -lt "${CI_TEST_PARTITIONS_MIN_CLAIM_MS:-15000}" ]; then
    printf 'ci-test-partitions: partition %s: %s ms of in-VM budget left; claiming no more\n' \
      "$i" "$left" | tee -a "$log_dir/partition-$i.log"
    break
  fi
fi
```

(Use a constant rather than a new seam if ci.yml must stay seam-free.) Then drop the
`inv_deadline=1` clamp: a claim should never start with a non-positive remainder.

### R4-WR-03: A TERM that arrives during `claim_next` still claims and starts a new BEAM after the stop

**File:** `bin/ci-test-partitions:1365-1375`
**Issue:** The `trap 'stop_claims=1' TERM` handler only runs between commands, and
`stop_claims` is tested only at the top of the loop (1365). The group TERM from
`stop_over_budget` (1018) or `kill_all` (1310) can land while the subshell is inside
`claim_next`, for example during its `sleep 0.1` poll or its `cat`/`awk` forks. In that
case `claim_next` finishes: it takes the row, advances `tail-queue.next` and appends a
`claim` row. Then the loop body runs `partition_invoke` and forks a **new** `mix test`
BEAM. That BEAM was born after the group TERM, so it never receives one. The consequences:

- The watchdog's grace loop (1020-1023) sees the group alive for the whole
  `KILL_GRACE_S` (10 s). It then prints "partition i ignored SIGTERM for 10s", which is false,
  since nothing received a TERM and ignored it, before sending the KILL.
- The file has a `claim` row but never ran, so `verify_claims`, which counts only `claim`
  rows, treats it as covered. The run is red anyway, because of the watchdog or
  `kill_all`'s exit 1, but the claim map in the step summary lists a run that never
  happened.
- On `kill_all` (a cancelled job), cleanup is delayed by the full grace.

**Fix:** Recheck the stop conditions after `claim_next` returns. Better, check them inside
`claim_next` while it holds the lock, before it advances `next`, so a stopping partition
never consumes a row:

```bash
claim_next "$i" "$log_dir" "$lock_wait_s" || { ...; break; }
[ -n "$CLAIM_FILE" ] || break
if [ "$stop_claims" -ne 0 ] || [ -f "$log_dir/partition-$i.budget" ]; then
  printf 'unrun\t%s\t%s\n' "$CLAIM_SEQ" "$CLAIM_FILE" >>"$log_dir/partition-$i.claims"
  [ "$p_status" -ne 0 ] || p_status=1
  break
fi
```

Then have `verify_claims` require a `done` row for every `claim` row.

## Info

### R4-IN-01: A non-strict `--ingest-weights --lane min` writes the current lane's file using the min lane's rule

**File:** `bin/ci-test-partitions:1573-1578` (rule default), `311` (`WEIGHTS_REL`)
**Issue:** Without `--output`, `output` stays `test/partition_weights.txt` (the current
lane's file). But the default rule is `lane_rule "$lane"`, which is keyed on the `--lane` TSV
filter. So `--ingest-weights <dir> --lane min` silently writes per-file **maxima** into the
current lane's weights. Only strict mode ties the rule to the output file.
**Fix:** Key the default rule on the output path's lane (median for `WEIGHTS_REL`), or
refuse `--lane min|latest` without `--output`.

### R4-IN-02: The async test is duplicated as a literal, though the comment says it is shared

**File:** `bin/ci-test-partitions:330, 442, 581`; `tools/tail_queue_replay.py:297`
**Issue:** `ASYNC_USE_RE` says "assign_files greps the same pattern", but `assign_files`
(442) hard-codes its own copy of the regex. If either copy is edited alone, the
assignment's async discount and the queue's eligibility disagree. A file could then be
weighted as async but queued as sync, or the reverse. The replay tool has a third copy.
**Fix:** Use `"$ASYNC_USE_RE"` at 442, and have a contract or self-test assert there is one
definition.

### R4-IN-03: The counts table silently undercounts when one invocation's summary does not parse

**File:** `bin/ci-test-partitions:744-763, 784-785`
**Issue:** `partition_counts` skips any invocation log that parses as `no tests` and sums the
rest. The "show the log tail" hint (785) fires only when *every* invocation is
unparseable. So if the static invocation's summary is unrecognised (for example a new
ExUnit format) but the claims parse, the table shows only the claims' counts and nothing
says so. Exit status is unaffected.
**Fix:** Count unparseable invocation logs that ran files, and print the same stdout hint
for each.

### R4-IN-04: Under the lock, `tail-queue.next` falls back to 1 on empty or garbled content

**File:** `bin/ci-test-partitions:682-683, 687`
**Issue:** `printf … >"$log_dir/tail-queue.next"` truncates the file before it writes. A
holder killed between the two leaves an empty file, and the next holder silently restarts
the queue at seq 1, running every earlier claim again. `verify_claims` catches the
duplicates (fail-closed). The lockless pre-check's fallback to 1 is harmless, but the
in-lock one should not guess.
**Fix:** Write `next` through a temp file and `mv`. Inside the lock, treat unreadable
content as an error and return 1.

### R4-IN-05: The self-test does not exercise the lock paths that R4-WR-01 and R4-WR-03 break

**File:** `bin/ci-test-partitions` self-test `tq-lock-stale`, `tq-contention`
**Issue:** `tq-lock-stale` breaks a stale lock with a single claimer. `tq-contention` never
seeds a stale lock. No case KILLs a holder between `mkdir` and the `owner` write, or sends
TERM to a partition inside `claim_next`. Those are the three cases above, and all three pass
the current suite.
**Fix:** Add a contention case on a seeded stale lock (assert no seq is claimed twice), a
case with a seeded ownerless lock (assert the failure is attributed and is not N lock
timeouts), and a TERM-during-claim case (assert no claim row without a `done` row).

### R4-IN-06: `min_balance.py predict --lane current` still models the greedy sets, and it inherits the caller's environment

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py:240-279`
**Issue:** `run_assignment` reads `assignment.tsv`, which is the greedy assignment from before
the lift. On the current lane the runner now lifts 12 files into the queue, so the reported
`ratio` is not the current lane's runtime spread. Only `tail_queue_replay.py` models that.
Unlike the replay tool, which drops `CI_TEST_PARTITIONS_*`/`THREADLINE_*`, it passes
`os.environ` straight through, so a stray seam in the shell (for example
`CI_TEST_PARTITIONS_BUDGET_S=abc`) aborts or alters the run.
**Fix:** Refuse `--lane current` or document it as greedy-only, and filter the environment
the same way `tail_queue_replay.run_assignment` does.

### R4-IN-07: `preflight` leaves claim exits and per-seq uniqueness to the run conclusion

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/tail_queue_replay.py:1055-1093`
**Issue:** `evaluate_preflight` parses each claim's `exit`, but never checks it. It does not
check that seqs are distinct, or that the queue line's `claimed` equals `queued`. Today
`conclusion == "success"` implies all three, because a non-zero claim or a failed
`verify_claims` fails the job. So this is defense in depth only. A future change that let a
lane go green with a failed claim would still pass preflight.
**Fix:** Add `all(c["exit"] == 0)`, distinct `seq`, and `q["claimed"] == q["queued"]` to
the K>0 lane checks.

### R4-IN-08: Sibling cross-clock `as_of/4` call sites remain (known, deferred)

**File:** `test/threadline/query/row_key_composite_test.exs:133, 202`
**Issue:** These have the same write-then-`as_of(DateTime.utc_now())` shape that
`row_key_read_test.exs` fixed with `db_now/0`. 247-31 logged them in `deferred-items.md`.
`as_of_property_test.exs:295` is benign: it probes with no writes and expects
`:before_audit_horizon`. They are listed here only so the R4 record is complete.
**Fix:** Move `db_now/0` into `Threadline.DataCase` and use it at both composite sites.

---

_Reviewed: 2026-10-28T23:07:28Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
