# Phase 247 B6 local proof (Plan 31, D-27 / D-12 / CI-04)

This record holds the local evidence for the runtime tail queue from Plan 30:

- one whole `mix test` run;
- five partitioned lane runs (current ×3, min and latest once each, at toolchain scope);
- a queued-hang proof with a real BEAM;
- the self-test time cap, re-checked at this HEAD.

Plan 32 cites it. Plan 33 relies on it through tree equality.

## Where and how

- **Tree.** Every run used HEAD `eae71898` on `milestone/v1.47`. That is the non-planning tree Plan 33 will land, because the only commit after it adds planning files. The runner's sha256 is pinned below.
- **Database.** An ephemeral `postgres:16` (16.14) container labelled `dev.threadline.plan=247-31`, on a loopback ephemeral port. Every mix command got `DB_HOST=127.0.0.1 DB_PORT=<port>`. The shared 5432 cluster was never used. The container was removed afterwards.
- **Toolchain.** Elixir 1.17.3-otp-27 on OTP 27.3.4.15, from `.tool-versions`. The min and latest lanes ran on this local toolchain with their own lane weights and `THREADLINE_TEST_SCOPE=toolchain`. They prove the queue on those lanes' weights and scope, not those lanes' Elixir/OTP versions.
- **Host.** A shared, loaded development host (load average about 19–30 during the timings).
- **Numbers.** Every value below comes from the runner's own output (the report table, the `| max/min |` row, the `tail queue K=…` line, the `claim ` lines), never from ExUnit lines.

## Whole suite

`mix test`, unpartitioned, at the same HEAD: `32 properties, 3387 tests, 0 failures, 3 excluded`, exit 0.

**This is the second series.** The first whole-suite run, at `f2dbe251`, went red with one failure. The failing test was `test/threadline/query/row_key_read_test.exs:204`: `as_of/4` at `DateTime.utc_now()` returned the insert snapshot instead of the update. Plan 247-13 recorded the same line as a one-off. Triage followed the plan's halt clause:

- **Mechanism.** The trigger stamps `captured_at` with the database's `clock_timestamp()`, but the test passed the BEAM's wall clock. Both observed symptoms need a stamp later than the BEAM's `now`: 247-13's `:before_audit_horizon`, and this `"a"` instead of `"b"`. A 240 s bracketed probe under full-suite load (34,733 samples) never caught the database ahead and saw no backward step. The cross-clock comparison is the defect. The exact trigger (a VM clock step) was not reproduced.
- **Test-only fix.** `29636579` reads the instant from `clock_timestamp()` at all three `as_of/4` sites in that file. `eae71898` corrects the comment.
- **Red-capable control.** Using an instant 1 µs before the update's stamp reproduces the exact failure at both affected tests (9 tests, 2 failures, right `{:ok, %{"id" => 1, "name" => "a"}}`). Restored, the file is 9/0.
- **Restart.** The whole series then restarted from the beginning at `eae71898`. No re-run of only the failed invocation is counted.

## Lane runs

| Run | Lane | Scope | Exit | Tests (Σ partitions) | Failures | max/min | K | Queued | Claimed | Claim lines | overhead_mean_ms |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | current | (all) | 0 | 3387 | 0 | 1.09 | 12 | 12 | 12 | 12 | 3726 |
| 2 | current | (all) | 0 | 3387 | 0 | 1.22 | 12 | 12 | 12 | 12 | 1447 |
| 3 | current | (all) | 0 | 3387 | 0 | 1.26 | 12 | 12 | 12 | 12 | 2406 |
| 4 | min | toolchain | 0 | 2567 | 0 | 1.04 | 12 | 12 | 12 | 12 | 1955 |
| 5 | latest | toolchain | 0 | 2567 | 0 | 1.03 | 12 | 12 | 12 | 12 | 1120 |

- **Coverage.** Each current-lane total equals the whole-suite total (3387), so nothing was dropped or duplicated. The toolchain-scope lanes left out the 63 `:repo_contract` files, as designed (D-10).
- **Claims.** Every queued file was claimed, and every claim exited 0.
- **Ratios and overheads.** These are host-local and informational only. `overhead_mean_ms` is wall time per claim minus the file's own ExUnit wall time, on this host. It does not stand in for the hosted preflight or the CI runner. Plan 32 may cite it only as a local observation.

## Queued-hang proof (CI-04 under D-27)

**Setup.** A scratch copy came from `git archive HEAD`, with `deps/` and `_build/test` copied in, not linked. All but three light sync files were deleted:

- `test/threadline/application_test.exs`
- `test/threadline/mix/migrations_path_test.exs`
- `test/threadline/storage_schema_test.exs`

A sync `test/zz_queued_hang_test.exs` was added. Its line-4 test body is `Process.sleep(:infinity)`. The scratch colocate file was empty, and the scratch weights gave the hang file 999999 ms. All four files were sync and ungrouped, so all four were queued, and the hang file was seq 1.

**Run.** `CI_TEST_PARTITIONS_BUDGET_S=90 bin/ci-test-partitions 4`, with real mix and a 200 s outer alarm.

**Results:**

- The run exited 1 after 64 s.
- Partition 1 had no static files. It claimed seq 1 as invocation `p1-1`, a claim invocation.
- Its log carries `----- HANG: in-flight: (deadline 60000 ms, VM wall 60003 ms) -----`, then `test/zz_queued_hang_test.exs:4 test hangs in the body of a queued file`, then a stack with the frame `(elixir 1.17.3) lib/process.ex:303: Process.sleep/1`, then `----- HANG: end -----`.
- Stdout has `claim partition=1 seq=1 file=test/zz_queued_hang_test.exs … exit=1`.
- The other three claims exited 0.
- The deadline came from the remaining budget: 90 s − 30 s = 60 000 ms.
- `pgrep -f <scratch path>` was empty afterwards, and the copy was removed.
- The fixture never existed under the repository's `test/`.

## Self-test time cap (W5)

- **Method.** `bin/ci-test-partitions --self-test` was timed with `date +%s`. The baseline was a `git archive` of origin/main `824c2851`, and the HEAD was a `git archive` of `eae71898`. There were three interleaved rounds of base-env, head-env, base-/bin/bash and head-/bin/bash. Env bash is 5.2.37; `/bin/bash` is 3.2.57. Every run printed `self-test: ok`.
- **Medians.** env 31 → 46 (+15 s). /bin/bash 33 → 46 (+13 s). Both are within the +20 s cap.
- **Noise.** One head-env sample (63 s) landed during a load spike. The median absorbs it.

<!-- B6-LOCAL-JSON-BEGIN -->
{
  "schema": "threadline.phase247-b6-local/1",
  "head": "eae7189865e5e8fddf170684a99595f8bf97fd7d",
  "runner_sha256": "cec42f3a4703c7902a5a6ba78d4fd5f4f2c38568c58fda93d1a8ac00573f1f9e",
  "whole_suite": {"tests": 3387, "failures": 0, "properties": 32, "excluded": 3, "exit": 0},
  "lane_runs": [
    {"lane": "current", "scope": "", "exit": 0, "tests": 3387, "failures": 0, "printed_ratio": "1.09", "k": 12, "queued": 12, "claimed": 12, "claim_lines": 12, "overhead_mean_ms": 3726},
    {"lane": "current", "scope": "", "exit": 0, "tests": 3387, "failures": 0, "printed_ratio": "1.22", "k": 12, "queued": 12, "claimed": 12, "claim_lines": 12, "overhead_mean_ms": 1447},
    {"lane": "current", "scope": "", "exit": 0, "tests": 3387, "failures": 0, "printed_ratio": "1.26", "k": 12, "queued": 12, "claimed": 12, "claim_lines": 12, "overhead_mean_ms": 2406},
    {"lane": "min", "scope": "toolchain", "exit": 0, "tests": 2567, "failures": 0, "printed_ratio": "1.04", "k": 12, "queued": 12, "claimed": 12, "claim_lines": 12, "overhead_mean_ms": 1955},
    {"lane": "latest", "scope": "toolchain", "exit": 0, "tests": 2567, "failures": 0, "printed_ratio": "1.03", "k": 12, "queued": 12, "claimed": 12, "claim_lines": 12, "overhead_mean_ms": 1120}
  ],
  "queued_hang_proof": {"budget_s": 90, "elapsed_s": 64, "exit": 1, "named": "test/zz_queued_hang_test.exs:4", "hang_marker": true, "claim_exit": 1, "claim_invocation": "p1-1", "monitor_deadline_ms": 60000, "leftover_beam": false},
  "postgres": "16",
  "toolchain": {"elixir": "1.17.3-otp-27", "erlang": "27.3.4.15"},
  "self_test_seconds": {
    "baseline_ref": "824c2851",
    "baseline_env": 31,
    "baseline_bin_bash": 33,
    "head_env": 46,
    "head_bin_bash": 46,
    "samples": {
      "baseline_env": [31, 38, 31],
      "baseline_bin_bash": [31, 38, 33],
      "head_env": [43, 63, 46],
      "head_bin_bash": [45, 48, 46]
    }
  },
  "first_series_red": {"head": "f2dbe251", "failure": "test/threadline/query/row_key_read_test.exs:204", "fix_commits": ["29636579", "eae71898"], "restarted_from_beginning": true}
}
<!-- B6-LOCAL-JSON-END -->
