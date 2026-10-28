---
phase: 247-ci-critical-path-and-suite-lanes
round: R3
scope: incremental review of gap plans 26-28 (diff vs 4f9f1e1c4737fda15be995eef813bfcafe744881)
reviewed: 2026-10-28T13:57:24Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/partition_weights_min.txt
findings:
  critical: 0
  warning: 4
  info: 7
  total: 11
status: issues_found
---

# Phase 247: Code Review Report, Round R3 (incremental, Plans 26–28)

**Reviewed:** 2026-10-28T13:57:24Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

Earlier rounds (Plans 23–25 and before) are in git history, last at `4f9f1e1c`. Finding ids
here use the `R3-` prefix so they do not collide with earlier rounds.

## Summary

The three files changed since `4f9f1e1c` were reviewed, and every numeric claim was
re-derived independently instead of trusting the plan summaries:

- **Weights file vs tool output: consistent.** The 12 cached training TSVs and 8 holdout
  TSVs all match the sha256 values pinned in `247-FROZEN-REPLAY.json`, whose own hash
  matches `FROZEN_REPLAY_SHA256`. `derive --rule max` on those TSVs reproduces
  `test/partition_weights_min.txt` byte for byte (sha256 `cb833068…b187`). A separate,
  independent per-file max (not using the tool) gives zero mismatches over 206 files, with
  every file present in all three runs. The only file floored to 1 is
  `pgbouncer_topology_test.exs`, observed at 0 ms.
- **R1–R5: faithfully applied.** Candidate A, built by the runner's strict ingest in a temp
  copy, hashes to `9280bf4d…23e5` as recorded. Replaying A and B over all five runs
  reproduces every recorded cost vector and spread exactly: A worst training spread 1.348177,
  B 1.161237, so R3 picks B. B's worst spread over all five runs is 1.273031, so R5 gives
  EXPECTED_MISS. `predict` for min, current and latest gives 1.00011, 1.000017 and 1.000046,
  matching the record. The Python median, effective-weight, async regex, cost and awk-split
  semantics were checked line by line against `bin/ci-test-partitions` `assign_files`. No
  off-by-one, rounding or hash defect was found that changes the selection.
- **Retention fix: genuine, not masking.** No sleeps, retries or loosened assertions were
  added. Workers now live under a `start_supervised!` Task.Supervisor that starts before the
  Pruner, so ExUnit stops the Pruner first and then the workers. `OnExitHandler.run` stops
  the test supervisor before any `on_exit` callback runs. The new regression test holds
  the Pruner's advisory lock on a separate session, which makes the ownership check
  deterministic. That test was red under the `Task.start` mutation, per the fixture audit.

No blockers. The warnings are latent hazards: one in the test teardown contract, and three in
the tool's robustness and in how the min-lane derivation stays reproducible.

## Warnings

### R3-WR-01: Workers stopped at teardown leave non-terminal RetentionRun rows that nobody cleans up

**File:** `test/threadline/operator_surface/live/retention_history_live_test.exs:91-117, 730-748` (also the type-to-confirm test at 695)
**Issue:** The fix makes the test supervisor kill accepted workers when a test ends, which is
the intended bound on their lifetime. The other side of that is that a killed worker never
moves its run to a terminal state:

- In the new test (730), the worker is still in `execute_when_lock_available`'s 100 ms retry
  sleep when `with_advisory_lock_held` returns. The test exits at once, so the worker is
  almost always killed before it takes the lock, and its run stays `status: "queued"`.
- In the type-to-confirm test (695), the worker can be killed partway through
  `Retention.purge`, which leaves a `"running"` row.

The module deletes `RetentionRun` only in `setup`, at the *start* of each test, and it has no
`on_exit`. `DataCase` does not truncate the table either. So whichever of these tests runs
last leaves a fresh queued or running row in that partition's database. `Pruner.init`'s
abandoned-run sweep only fails rows older than 24 h, and `accept_or_coalesce` returns
`{:active, run}` for any queued or running row. A later module in the same partition that
calls `Pruner.trigger/0` without deleting runs first would get `:ok` and never run anything.

Every current consumer (`pruner_test`, `retention_test`, `start_live_test`,
`copy_contract_test`, the telemetry tests) deletes runs in its own `setup`, so nothing fails
today. Still, the fix swaps one cross-test leak (an orphan worker that keeps running) for a
milder one (stale state left in the database), and the 247-26 sibling sweep does not record
this.
**Fix:** Clean up after the test supervisor has stopped the workers. `on_exit` callbacks run
after that, so this is ordered correctly:

```elixir
setup do
  stop_named_process!(Pruner)
  Repo.delete_all(RetentionRun, repo_opts())
  # Runs after ExUnit has stopped the Pruner and its test-owned workers, so a
  # killed worker's queued/running run cannot outlive the test either.
  on_exit(fn -> Repo.delete_all(RetentionRun, repo_opts()) end)
  ...
```

`test/threadline/retention/pruner_test.exs` (714b4dbb) has the same shape and should get
the same `on_exit`.

### R3-WR-02: `ratio_of` drops empty partitions, which hides the worst possible imbalance

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py:158-161`
**Issue:** `vals = [c["cost"] for c in costs.values() if c["files"] > 0]` leaves empty
partitions out of the max/min ratio. If an assignment leaves one of the 4 partitions empty,
the lane really runs on 3, but the tool reports the ratio over the 3 non-empty ones. That can
come out at or below 1.15, so a degenerate candidate could pass R2 (eligibility) and look
balanced in `replay`. `predict` and `replay` both use this function, and neither reports how
many partitions are non-empty. This does not happen with the current data (all four
partitions have files), but the R2 gate has no protection against it.
**Fix:** Treat an empty partition as a check failure (or as infinite spread) instead of
skipping it:

```python
def ratio_of(costs):
    require(all(c["files"] > 0 for c in costs.values()),
            f"empty partition(s): {[p for p, c in costs.items() if c['files'] == 0]}")
    vals = [c["cost"] for c in costs.values()]
    require(min(vals) > 0, "a partition has zero cost")
    return max(vals) / min(vals)
```

### R3-WR-03: `--weights` overwrites the committed lane file in the live worktree, with no protection against concurrent runs

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py:216-242, 296-300, 351-355`
**Issue:** `placed()` writes the candidate over `test/partition_weights_min.txt` in the
worktree that holds the script, and restores it from the bytes it read on entry.
Problems:

1. **Concurrent runs can leave a candidate in place.** Two invocations that overlap (for
   example, predicting A and B in parallel) interleave like this. Run 1 reads the committed
   bytes and writes A. Run 2 reads A as its "original" and writes B. Run 1 restores the
   committed bytes. Run 2 then "restores" A. Run 2's check `target.read_bytes() == original`
   passes because its original is A, so the tool exits 0 and leaves candidate A in the
   committed CI input with no warning.
2. Anything else that reads the file while a candidate is in place sees the candidate. That
   includes a local `mix verify.test_partitioned`, `ci_topology_contract_test`, and
   `git status`/`git diff`.
3. The restore in `finally` runs with the custom signal handlers still installed. A second
   SIGINT or SIGTERM during `write_bytes(original)` raises `KeyboardInterrupt` in the middle
   of the write, which can truncate the file. A SIGKILL leaves the candidate in place.

`derive` already does the safe thing: it copies the runner and test tree to a temp directory.
The plan's own verification also runs `predict` and `replay --weights` from a `git archive`
scratch copy. The tool's documented direct usage does not.
**Fix:** In `run_assignment`, run the runner in a temp copy (runner + `test/` + colocation,
as `strict_ingest_copy` does) and place the candidate there. The live file is then never
written. If in-place placement is kept, take an exclusive `fcntl.flock` on a sidecar lock
file and refuse to start if the target differs from `git show HEAD:<path>`. Also restore the
previous signal handlers *before* the restore write.

### R3-WR-04: The min-lane weights can no longer be reproduced from any documented regeneration path

**File:** `test/partition_weights_min.txt:1-6` (header line 4); `CONTRIBUTING.md:177-210`
**Issue:** The committed min weights now come from the per-file **maximum** (candidate B),
produced by a script inside `.planning/phases/247-…/tools/`. Neither the file nor the
contributor docs say so:

- The file's header (required verbatim by R1) says `Regenerate with: bin/ci-test-partitions --write-weights`.
  That command writes `test/partition_weights.txt` from one local run, not the min lane.
- CONTRIBUTING.md documents only `bin/ci-test-partitions --ingest-weights <dir>`, which
  produces the **median** (candidate A).
- `ci_topology_contract_test` checks only that the inventory is covered, not how the weights
  were derived.

So the next routine refresh, done the documented way, silently brings back candidate A.
Under R3, A's worst training spread was 1.348 against B's 1.161. Nothing in the repo would
flag the change, and the B5 selection would be lost without any record.
**Fix:** Add a short paragraph to CONTRIBUTING.md. It should say that the `min` lane weights
are derived with the per-file max rule
(`python3 -I .planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py derive --rule max --train <dir> --output test/partition_weights_min.txt`),
and that `--ingest-weights --lane min` produces the median, which is the wrong rule for that
lane. Alternatively, give the runner's `--ingest-weights` a `--rule max` mode, so the rule
lives in `bin/` and is covered by the runner's self-test rather than a phase-local script.
Either way, leave the R1 header alone; put the provenance in docs or the runner.

## Info

### R3-IN-01: `parse_tsv` accepts TSVs that the runner's strict ingest rejects

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py:166-181, 190`
**Issue:** `bits[1].isdigit()` / `bits[2].isdigit()` accept Unicode digits, and `int()`
converts some of them (for example U+0663, ARABIC-INDIC DIGIT THREE). `Path.read_text()` uses universal newlines, so
CRLF or lone-CR TSVs are normalised. `str.splitlines()` also splits on `\x0b`, `\x0c`,
`\x1c`–`\x1e` and `U+2028`. The runner's awk validation (`$2 !~ /^[0-9]+$/`, `\n`-only
records) rejects all of these. `fetch` and `derive` are protected (pinned hashes, and the
runner's strict ingest respectively), but `replay --root <arbitrary dir>` is not.
**Fix:** Use `re.fullmatch(r"[0-9]+", …)` and `f.read_bytes().decode("utf-8").split("\n")`,
dropping only one trailing empty element.

### R3-IN-02: `replay` does not check which runs it found

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py:203-211, 329-348`
**Issue:** `find_runs` silently skips a run whose TSVs are not laid out as `<digits>/min/`,
or whose `min` directory is empty. `replay` replays whatever it finds. If a holdout is laid
out wrongly, R5's "worst over five observations" quietly becomes worst over four. `derive`
pins `TRAIN_RUNS`; `replay` has no equivalent.
**Fix:** Add `--expect-runs` (or default to `TRAIN_RUNS + [B4_HOLDOUT, DIAG_RUN]` when
`--root` is a `fetch` output) and `require` an exact match.

### R3-IN-03: Dead return values

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py:433-435, 200, 454`
**Issue:** `strict_ingest_copy` computes and returns `inventory`, but its only caller
discards it (`median_text, _ = …`). That inventory is also not lane-scoped, since it
includes the repo-contract files, so it would be wrong if anything used it.
`load_run`'s `partition_wall_ms` is never read.
**Fix:** Remove both, or use `partition_wall_ms` (see R3-IN-05).

### R3-IN-04: Self-test misses the logic that most needs to match the runner

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py:472-541`
**Issue:** The docstring says the self-test covers "derivation … restore logic". It has no
cases for:

- `raw_weight_map` median: odd count, even count with floor, no weights giving 1000
- `read_weights` awk-split semantics: a leading blank giving an empty first field, duplicate
  entries summed
- `find_runs` / `load_run` rejections: duplicate run, extra TSV, file seen twice in one run
- signal-driven restore in `placed`

At runtime, `predict` cross-checks effective weights against the runner, which partly
covers the median path. But that check cannot see an async misclassification on a
weight-1 file, because 1 × 292 / 1000 is floored back to 1.
**Fix:** Add a small table-driven case for each item above.

### R3-IN-05: The replay "spread" leaves out partition boot time, so it is not the quantity CI-03 measures

**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py:140-155, 342-347`
**Issue:** Cost is S + max(D, L) over per-file walls only. `max_boot_ms` is reported but not
used. In every B4 run, the TSV headers show a 17–23 s boot on P3 against about 2 s elsewhere.
For example, 40449332597 has header walls 143.6/154.6/165.5/133.7 s, a measured ratio of
1.238. R5 is advisory and was pre-registered on this definition, so nothing needs
re-selecting. Still, the R5 expectation and the `risk` sentence compare a test-time-only
spread against a 1.15 threshold that CI applies to wall time including boot.
**Fix:** Also report a `wall_spread` per run from the header `wall_ms` values, so the R5
text can compare like with like.

### R3-IN-06: The new test's name claims more than it asserts

**File:** `test/threadline/operator_surface/live/retention_history_live_test.exs:730-748`
**Issue:** The name says the worker "cannot outlive" the test. The test only asserts that
the supervisor has a child while the lock is held. The lifetime bound comes from OTP
supervisor semantics and is never asserted, so a later change (for example starting the
supervisor with `Supervisor.start_link` instead of `start_supervised!`) would keep this test
green.
**Fix:** Capture the child pid, then assert in `on_exit` (which runs after the test
supervisor has stopped) that `Process.alive?(pid)` is false. Or rename the test to
"…is owned by the test supervisor".

### R3-IN-07: The test depends on Pruner internals (private lock key and state shape)

**File:** `test/threadline/operator_surface/live/retention_history_live_test.exs:45-46, 66-68`
**Issue:** `@pruner_lock_key :erlang.phash2("threadline_retention_pruner")` copies the
private `@lock_key` in `lib/threadline/retention/pruner.ex:12`. `:sys.replace_state` writes
the private `task_start` key directly. If the Pruner's state is renamed,
`%{state | task_start: …}` raises, which fails loudly. If the lock key changes, the
lock-held window stops blocking the worker. The worker then purges and exits at once, and
the `children != []` check becomes timing-dependent instead of failing clearly.
`pruner_test.exs` has the same coupling (714b4dbb).
**Fix:** Expose a `:task_supervisor` start option (test-only use is fine) and a
`Pruner.lock_key/0` (`@doc false`), and use them in both test modules.

---

_Reviewed: 2026-10-28T13:57:24Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
