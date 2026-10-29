---
phase: 247-ci-critical-path-and-suite-lanes
plan: 30
subsystem: ci-partitioning
status: complete
tags: [ci, partition-runner, tail-queue, D-27, CI-03, CI-04, CI-01, self-test, bash-3.2]
requires:
  - phase: 247-29
    provides: "lane_rule() and --ingest-weights --rule in bin/ci-test-partitions (its lane-rule self-test block counts against the same cap)"
provides:
  - "bin/ci-test-partitions TAIL_QUEUE_K=12 plus the test-only seams CI_TEST_PARTITIONS_TAIL_K, CI_TEST_PARTITIONS_LOCK_WAIT_S, CI_TEST_PARTITIONS_FAKE_FILE_PLAN"
  - "select_tail_queue / verify_tail_queue (before compile), claim_next under a mkdir lock with a partition-index owner, release_tail_lock, partition_invoke (the single mix test call site), merge_partition_timings, verify_claims (after the wait loop), partition_counts"
  - "Stdout: 'tail queue: <q> files lifted (K=<k>), weight <w> ms', 'partition <i>: static <n> files, weight <w> ms', 'claim partition=… overhead_ms=…', 'tail queue K=… queued=… claimed=… overhead_mean_ms=…'; step summary 'Tail queue (K=<k>)' table"
  - "Self-test cases tq-basic, tq-tsv, tq-claim-map, tq-k-pin, tq-order, tq-colocate, tq-async, tq-empty, tq-scope, tq-fail, tq-deadline, tq-lock-stale, tq-contention, tq-hang; legacy cases (a)-(x) at CI_TEST_PARTITIONS_TAIL_K=0"
affects: ["247-31", "247-32", "247-33", "247 verification"]
actuals:
  tokens: 13150
  tasks: 3
  commits: 3
plan_head_before: 387fca5278024d873082e3965db04444c5cc75d6
plan_head_after: f1bffd7680daf99c7ebf43a654890726aeed475d
tech-stack:
  added: []
  patterns:
    - "One invocation call site per partition: the static set (k=0) and each claim (k>=1) go through partition_invoke, so the canonical mix test line still occurs exactly once"
    - "Per-invocation evidence under invocations/ (p<i>-<k>.log/.tsv), named so they never match the partition-timings-*.tsv upload or ingest glob, then merged into the unchanged schema"
    - "Lock ownership by partition index (bash 3.2 has no BASHPID); stale = the owner already has a status file"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-30-SUMMARY.md
  modified:
    - bin/ci-test-partitions
key-decisions:
  - "The static invocation truncates partition-<i>.log, then the single call site appends (>>) for static and claims alike, so there is still exactly one invocation line"
  - "The static invocation gets the full deadline_ms (elapsed counted as 0); each claim gets deadline_ms - 1000 x (now - p_start), at least 1; a disarmed value (<= 0) passes unchanged"
  - "watch_partitions polls every 0.2 s for its first ~3 s (was 0.1 then 0.3 then 1 s); the budget stays whole seconds. This is the self-test trim that kept the cap comfortable; it also ends fast real runs sooner"
  - "claim_next skips the lock when the next pointer is past the queue (the pointer only grows), and a partition with an empty queue never enters the claim loop, so K=0 adds no lock traffic"
  - "requirements-completed stays empty: CI-01/03/04 are judged by the phase verifier after Plans 31-33 (the real CI-03 evidence is Plan 32/33's measurement)"
requirements-completed: []
coverage:
  - id: D1
    description: "Queue lift: K=12 heaviest ungrouped async:false files; greedy assignment and its printed lines unchanged; static lines and the queue line printed before the compile; verify_tail_queue"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test (tq-k-pin, tq-order, tq-colocate, tq-async, tq-empty, tq-scope) under env bash and /bin/bash"
        status: pass
      - kind: integration
        ref: "Task 1 automated verify: git archive HEAD scratch copy, MIX_BIN=false, 12 queue rows, 4 greedy + 4 static lines; an independent awk/grep recomputation of the 12 matched"
        status: pass
    human_judgment: false
  - id: D2
    description: "Claims under the mkdir lock through the single invocation site, exactly-once over static plus claimed, verify_claims"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test (tq-basic, tq-contention x2, tq-lock-stale)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Merged partition-timings-<i>.tsv in the unchanged schema, claim map lines, Tail queue table, counts summed over invocations"
    requirement: CI-01
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test (tq-tsv, tq-claim-map)"
        status: pass
    human_judgment: false
  - id: D4
    description: "One CI-04 budget across invocations, first non-zero exit wins, stop on TERM/budget, stale-lock break, lock timeout, lock release in stop_over_budget/kill_all"
    requirement: CI-04
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test (tq-fail, tq-deadline, tq-hang, tq-lock-stale; legacy hang, hang_ignore_term, hang_quit unchanged)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Self-test time cap: HEAD median of 3 <= origin/main median of 3 + 20 s under env bash and /bin/bash"
    verification:
      - kind: other
        ref: "Task 3 automated verify block, run as VARIANTS=env and VARIANTS=/bin/bash"
        status: pass
    human_judgment: false
self_test_seconds:
  baseline_ref: "origin/main 824c2851 (git archive)"
  baseline_env: [30, 30, 29]
  baseline_bin_bash: [33, 31, 29]
  head_env: [43, 44, 45]
  head_bin_bash: [46, 46, 43]
  median_baseline_env: 30
  median_baseline_bin_bash: 31
  median_head_env: 44
  median_head_bin_bash: 46
  delta_env: 14
  delta_bin_bash: 15
  cap: "+20 s per bash"
  pre_trim_env_run: {baseline: [32, 31, 31], head: [49, 50, 49], median_delta: 18}
tally_task1: {env: {baseline: 28, head: 33, delta: 5}, bin_bash: {baseline: 31, head: 44, delta: 13}}
tally_task2: {env: {baseline: 31, head: 38, delta: 7}, bin_bash: {baseline: 29, head: 37, delta: 8}}
duration: 60min
completed: 2026-10-28
---

# Phase 247 Plan 30: Runtime tail queue in the partition runner (D-27) Summary

**`bin/ci-test-partitions` now lifts the 12 heaviest ungrouped `async: false` files out of the unchanged greedy assignment. Each partition runs its static set first, then claims queued files largest-first under an atomic `mkdir` lock, and runs each as its own `mix test <file>` on its own DB. Each partition's per-invocation TSVs merge into the existing schema. A claim map goes to the log and the step summary. Exactly-once is checked before and after the run, and one CI-04 budget still spans every invocation. All 14 tq-* self-test cases pass under env bash and /bin/bash 3.2, at +14 s and +15 s median self-test cost (cap +20 s).**

## Performance

- **Duration:** about 60 min, mostly self-test measurement on a loaded host (load average 7–20 on 18 cores from unrelated projects)
- **Completed:** 2026-10-28
- **Tasks:** 3 of 3
- **Files modified:** 1 (`bin/ci-test-partitions`, +838/−48)

## Accomplishments

- **Lift (Task 1).**
  - `TAIL_QUEUE_K=12` sits beside `ASYNC_FACTOR_PERMILLE`, with the D-27 / B6 citation (K=4 replays at 1.31).
  - The `CI_TEST_PARTITIONS_TAIL_K` seam is validated by a new `count_env`.
  - `select_tail_queue` ranks by the assignment's effective weight descending, then path ascending (`LC_ALL=C`). It skips colocate-listed files and files that match the runner's async regex.
  - `assignment.tsv` and the `partition <i>: <n> files, weight <w> ms` lines still describe the full greedy assignment. The new `tail queue:` and `static` lines print before the serial compile, so `MIX_BIN=false` callers see them.
  - `verify_tail_queue` refuses a run whose static sets plus queue do not cover the enumerated set exactly once.
- **Claims (Task 1).**
  - `claim_next` takes `mkdir tail-queue.lock`, writes `owner`=partition index, advances `tail-queue.next`, and appends `claim\t<seq>\t<file>\t<start_ms>`.
  - `partition_invoke` is now the only place that holds the canonical `"$MIX_BIN" test --no-compile --no-deps-check --timeout="$PARTITION_TEST_TIMEOUT_MS" "${files[@]}" ${monitor_args…}` line. It is used for k=0 and for every claim.
  - `verify_claims` sets `fail=1` after the untouched `watch_partitions` → `local fail=0` → per-PID wait sequence.
- **Timings and claim map (Task 2).**
  - `merge_partition_timings` writes `partition-timings-<i>.tsv` atomically (temp in `$log_dir`, then `mv`). The header is `boot_ms` of the lowest k and `wall_ms` summed. Rows are concatenated, and a partition or lane mismatch, a bad header or a duplicate file fails the partition.
  - Each claim gets `done` rows and a stdout `claim partition=… seq=… file=… start_ms=… end_ms=… exit=… file_wall_ms=… overhead_ms=…` line.
  - `partition_counts` sums over `invocations/p<i>-*.log`, falling back to the single log for REPORT_ONLY.
  - The ratio now also counts partitions that only claimed.
  - The `Tail queue (K=<k>)` table carries only paths and integers. The stdout `tail queue K=… queued=… claimed=… overhead_mean_ms=…` line uses `n/a` when no claim finished.
- **Robustness (Task 3).**
  - `trap 'stop_claims=1' TERM` (still a handler, never `trap ''`). Claiming stops on `stop_claims` or a budget file, and a budget file still exits 124.
  - The first non-zero exit wins, and claiming continues after a failure.
  - A stale lock (its owner has a status file) is broken by an atomic rename. A wait longer than `CI_TEST_PARTITIONS_LOCK_WAIT_S` logs `partition <i>: tail-queue lock timeout` and fails the partition.
  - `release_tail_lock <i>` is called from `stop_over_budget` and `kill_all`, keyed on the partition index.
  - `beam.pid` is rewritten before each wait.
  - The header now has a "Tail queue (D-27)" paragraph, an updated opening sentence and monitor-env notes, the tq-* list, and the three new seams.
- **Coverage notes for `tq-hang`.**
  - It goes through the existing `CI_TEST_PARTITIONS_PSQL` seam, set to the self-test's `fake_psql`, so it stays offline.
  - A TERM-ignoring hang inside a claim has no case of its own. It shares `stop_over_budget`'s group TERM→KILL path with the static invocation, which the legacy `hang_ignore_term` case proves.

## Task Commits

1. **Task 1: tracer, lift, claim and exactly-once.** `cbcda76b` `ci(247-30): add the runtime tail queue to the partition runner (D-27)`. The tracer gate's automated `<verify>` was re-run end to end and passed before expansion.
2. **Task 2: TSV merge and claim map.** `c23401cd` `ci(247-30): merge tail-queue timings and print the claim map`
3. **Task 3: deadline, status, lock, hang cases and time cap.** `f1bffd76` `ci(247-30): keep one deadline, exit status and lock across tail-queue claims`

## Self-test time cap (W5)

| | Baseline origin/main 824c2851 (3 runs) | HEAD (3 runs) | Median Δ | Cap |
|---|---|---|---|---|
| env bash (5.2) | 30 30 29, median 30 | 43 44 45, median 44 | +14 s | ≤ +20 |
| /bin/bash 3.2 | 33 31 29, median 31 | 46 46 43, median 46 | +15 s | ≤ +20 |

- **Pre-trim env run:** the same verify passed at baseline median 31 and HEAD median 49 (+18 s).
- **Trim:** per-case seconds from an uncommitted, instrumented scratch copy showed the tq cases losing about 1 s each to poll overshoot: a fake run ending just after the 0.4 s poll waited until 1.4 s. Polling `watch_partitions` every 0.2 s for its first ~3 s cut about 5 s:
  - tq-hang: 4.2 → 2.8 s
  - each tq-contention round: 1.9 → 0.95 s
  - tq-basic: 1.15 → 0.85 s
- **No coverage was dropped:** no case was moved out of `--self-test`, and the cap was not relaxed.
- **Tallies:**
  - `tally_task1`: env 28→33 (+5), /bin/bash 31→44 (+13). An earlier attempt was invalid: zsh did not word-split the `/bin/bash <path>` command, so it was re-taken under bash.
  - `tally_task2`: env 31→38 (+7), /bin/bash 29→37 (+8).
- **Margin:** Plan 32 should fold about +15 s of self-test cost into the CI-02 prediction (B5 457 s; ceiling 510 s).

## Files Created/Modified

- `bin/ci-test-partitions`: the D-27 runtime tail queue, its report and claim map, the lock, and 14 tq-* self-test cases.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Legacy case (i) timings-file assertion re-pointed**
- **Found during:** Task 1
- **Issue:** The binding design gives every invocation `THREADLINE_PARTITION_TIMINGS_FILE=$log_dir/invocations/p<i>-<k>.tsv`. Case (i) asserted the old direct `partition-timings-<i>.tsv` path, so it would have gone red even though its meaning held: each partition gets its own timings file.
- **Fix:** It now asserts `invocations/p<i>-0.tsv`. The merged `partition-timings-<i>.tsv` is pinned by tq-tsv.
- **Commit:** cbcda76b

**2. [Rule 1 - Bug] Static invocation deadline counted from p_start itself**
- **Found during:** Task 1
- **Issue:** Computing `deadline_ms − 1000 × (now − p_start)` for k=0 would turn the legacy `FAKE_MIX_DEADLINE_MS=450000` assertion into a flake whenever a second boundary fell between the two `date` calls.
- **Fix:** The static invocation gets `deadline_ms` unchanged, and only claims subtract the elapsed time. tq-deadline proves the claim's value is positive and smaller.
- **Commit:** cbcda76b

**3. [Plan detail] `>` vs `>>`**
- **Found during:** Task 1
- **Issue:** Separate `>` (static) and `>>` (claim) call sites would mean two canonical invocation lines.
- **Fix:** The static invocation does `: >"$log"`, and the one call site always appends. The bytes are identical to `>`.
- **Commit:** cbcda76b

**4. [Plan detail] Fake boot_ms is `5 + k`**
- **Found during:** Task 2
- **Issue:** A flat 5 would make the "boot_ms from the lowest k" assertion unable to tell invocations apart.
- **Fix:** The fake reads k from the runner's `-<k>.tsv` path. k=0 still gives 5, as planned.
- **Commit:** c23401cd

**5. [Rule 3 - Blocking, time cap] watch_partitions early poll cadence**
- **Found during:** Task 3
- **Fix:** See "Self-test time cap". The watchdog semantics are unchanged: the budget is whole seconds and partitions are aged from the fork.
- **Commit:** f1bffd76

**6. [Rule 2 - Robustness] Lock contention and spin guards**
- **Found during:** Task 1 and Task 3
- **Fix:** An exhausted queue is detected without taking the lock (the pointer only grows), and an empty queue skips the claim loop. A failed stale-lock rename falls through to the normal 0.1 s poll instead of spinning.
- **Commits:** cbcda76b, f1bffd76

## Known interim breakage (owned by Plan 31)

`test/threadline/ci_topology_contract_test.exs` "shared local export fixtures never overlap across partition processes" will be red until Plan 31 Task 1 lands.

- **Grouped case:** passes at the real K.
- **Split negative control** (colocate `""`): makes the four sync export files eligible, so all of them are queued and every static set is empty. The contract's fake mix counts non-empty `partition-*.files` as its barrier, so it exits 42 instead of printing `export fixture overlap`.
- **Reproduced offline in bash** with the contract's own fake mix:

  | Run | Exit | `export fixture overlap` lines |
  |---|---|---|
  | grouped | 0 | 0 |
  | split | 1 | 0 |
  | split at `CI_TEST_PARTITIONS_TAIL_K=0` | 1 | 6 |

- **Fix:** 247-31-PLAN.md Task 1 step 4 already specifies it (`extra_env` with `CI_TEST_PARTITIONS_TAIL_K=0` for the split control). I left it there because `files_modified` for this plan is the runner alone.
- **Not run:** the Elixir contract suite, which needs a DB. No database was started.

## Issues Encountered

- **Host noise:** single self-test runs ranged 33–50 s on the same tree under heavy unrelated host load. Medians of 3, with baseline and HEAD interleaved, were used for the cap, as the plan specifies.
- **Measurement harness:** in zsh, `$cmd` holding `/bin/bash <path>` is not word-split. All measurements were re-run under bash, through a scratch copy of the plan's verify block.

## Known Stubs

None.

## Next Phase Readiness

- **Plan 31** owns:
  - contract pins (the K mutant, seam absence in ci.yml, the single invocation site, doc parity);
  - the export-overlap control adaptation above;
  - CONTRIBUTING;
  - local lane runs.
- **Plan 32** takes the measured +14/+15 s self-test delta into the CI-02 prediction.

## Self-Check: PASSED

- FOUND: bin/ci-test-partitions (TAIL_QUEUE_K=12 once; canonical invocation line once)
- FOUND: cbcda76b, c23401cd, f1bffd76 (ancestors of HEAD; `git rev-list --count 387fca52..HEAD` = 3)
- Weights, colocation file, monitor, `.github/` and `lib/` unchanged against origin/main
- No 247hangsentinel or runner process left behind; no container started
