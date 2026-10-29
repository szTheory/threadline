# Phase 247 B6 local proof, round 2 (Plan 34, D-32 / D-31 / D-34 / D-12 / CI-04)

This record holds the local evidence for the per-lane tail queue from Plan 34, where `lane_tail_k()` gives current 12, min 0 and latest 0:

- one whole `mix test` run;
- one partitioned run each of current, min and latest (min and latest at toolchain scope);
- a queued-hang proof with a real BEAM;
- the static identity of min and latest against origin/main 824c2851;
- the D-31 self-test time cap, measured by the D-34 method.

247-B6-LOCAL.md (round 1, the all-lane K=12 runner) is unchanged. Plan 35's P10 reads `self_test_seconds` below. Plan 36 relies on this record through tree equality.

## Where and how

- **Tree.** Every run below used HEAD `4f872f5e` on `milestone/v1.47`. That is the non-planning tree Plan 36 will land, because every later commit touches only `.planning/`. The runner's sha256 is pinned below. It is byte-identical to the runner at `462a6063`, the commit the D-34 timing series measured; `4f872f5e` adds only a contract assertion in `test/threadline/ci_topology_contract_test.exs`.
- **Database.** An ephemeral `postgres:16` (16.14) container labelled `dev.threadline.plan=247-34`, on a loopback ephemeral port. Every mix command got `DB_HOST=127.0.0.1 DB_PORT=<port>`. The shared 5432 cluster was never used. The container was removed afterwards.
- **Toolchain.** Elixir 1.17.3-otp-27 on OTP 27.3.4.15, from `.tool-versions`. The min and latest lanes ran on this local toolchain with their own lane weights and `THREADLINE_TEST_SCOPE=toolchain`. They prove the per-lane K on those lanes' weights and scope, not those lanes' Elixir/OTP versions.
- **Host.** A shared, loaded development host, with load averages of about 8–23 during this plan.
- **Numbers.** Every lane value comes from the runner's own output (the report table, the `| max/min |` row, the `tail queue K=…` line, the `claim ` lines), never from ExUnit lines.
- **Informational only.** The local ratios and overheads are host-local. They do not stand in for the hosted preflight or the CI runner.

## Whole suite

`mix test`, unpartitioned, at `4f872f5e`: `32 properties, 3388 tests, 0 failures, 3 excluded`, exit 0. The total is one more than round 1's 3387 because of the new `lane_tail_k` contract test.

## Lane runs

| Lane | Scope | Exit | Tests (Σ partitions) | Failures | max/min | K | Queued | Claimed | Claim lines | overhead_mean_ms |
|---|---|---|---|---|---|---|---|---|---|---|
| current | (all) | 0 | 3388 | 0 | 1.23 | 12 | 12 | 12 | 12 | 2867 |
| min | toolchain | 0 | 2568 | 0 | 1.32 | 0 | 0 | 0 | 0 | n/a |
| latest | toolchain | 0 | 2568 | 0 | 1.26 | 0 | 0 | 0 | 0 | n/a |

- **Coverage.** The current total equals the whole suite (3388), so nothing was dropped or duplicated. The min and latest totals are equal. The toolchain-scope lanes left out the 63 `:repo_contract` files, as designed (D-10).
- **Per-lane K.** Current queued 12, claimed 12, and every claim exited 0. Min and latest printed `ci-test-partitions: tail queue: 0 files lifted (K=0), weight 0 ms`, then `tail queue K=0 queued=0 claimed=0 overhead_mean_ms=n/a`. Their reports have no `Tail queue (K=…)` table.
- **Earlier runs.** One run of each lane was also made at `99f0a595`, before the trim commit. They gave current 3388 / 1.17 / K=12 12/12/12 / 1225 ms, min 2568 / 1.35 / K=0, and latest 2568 / 1.28 / K=0, all exit 0. They are superseded by the runs above at the recorded runner and are listed only for completeness.

## Static identity against origin/main 824c2851

This is Plan 34 Task 1's verify, run under env bash and `/bin/bash` at `8caf2295` and again at `462a6063`, which has the same runner as `4f872f5e`. It uses `git archive` copies run with `MIX_BIN=false`, the seam unset, and toolchain scope for min and latest.

- The min and latest `partition-1..4.files` are byte-identical to 824c2851's.
- Min and latest queue nothing and print the K=0 lift line.
- Current's greedy `assignment.tsv` is byte-identical to 824c2851's, and its queue holds 12 files.

## Queued-hang proof (CI-04 under D-32)

**Setup.** A scratch copy came from `git archive HEAD` at `4f872f5e`, with `deps/` and `_build/` copied in, not linked. All but three light sync files were deleted:

- `test/threadline/application_test.exs`
- `test/threadline/mix/migrations_path_test.exs`
- `test/threadline/storage_schema_test.exs`

A sync `test/zz_queued_hang_test.exs` was added. Its line-4 test body is `Process.sleep(:infinity)`. The scratch colocate file was empty, and the scratch weights gave the hang file 999999 ms. `THREADLINE_CI_LANE` was unset, so lane '' is current and K=12. All four files were queued, and the hang file was seq 1.

**Run.** `CI_TEST_PARTITIONS_BUDGET_S=90 bin/ci-test-partitions 4`, with real mix and a 200 s outer alarm.

**Results:**

- The run exited 1 after 65 s.
- Partition 1 claimed seq 1 as invocation `p1-1`.
- Its log carries `----- HANG: in-flight: (deadline 60000 ms, VM wall 60001 ms) -----`, then `test/zz_queued_hang_test.exs:4 test hangs in the body of a queued file`, then a stack with the frame `(elixir 1.17.3) lib/process.ex:303: Process.sleep/1`, then `----- HANG: end -----`.
- Stdout has `claim partition=1 seq=1 file=test/zz_queued_hang_test.exs … exit=1`.
- The other three claims exited 0.
- `pgrep -f <scratch path>` was empty afterwards, and the copy was removed.
- The fixture never existed under the repository's `test/`.

## Self-test time cap (D-31, measured by D-34)

**Rule (D-31, unchanged).** Under each bash, the HEAD median of 3 `--self-test` runs must be at most the baseline median of 3 + 20 s. The baseline is a `git archive` of origin/main `824c2851`. The HEAD is a `git archive` of `462a6063`, whose runner is byte-identical to `4f872f5e`'s. Timing is `date +%s` around each run. Env bash is 5.2.37 and `/bin/bash` is 3.2.57. Every run printed `self-test: ok`.

**Method (D-34).** Under each bash, the runs alternate base, HEAD, base, HEAD, base, HEAD, so that host-load drift falls on both sides equally. That gives 3 samples per side, and the schema stays the same. The recorded `self_test_seconds` come from this series.

| Variant | Load (start → end) | Base samples | Base median | HEAD samples | HEAD median | Cap | Verdict |
|---|---|---|---|---|---|---|---|
| env | 10.65 → 9.03 | 29, 31, 30 | 30 | 45, 52, 44 | 45 | 50 | pass (+15) |
| /bin/bash | 8.25 → 12.98 | 32, 28, 30 | 30 | 47, 52, 45 | 47 | 50 | pass (+17) |

**Halted series, disclosed verbatim (D-34: nothing is discarded silently).** Before D-34, Plan 34 measured two non-interleaved series. Each round ran base-env, head-env, base-/bin/bash and head-/bin/bash, three rounds in a row. The load average was about 12–23. Both series failed the cap, and the plan halted (247-34-SUMMARY.md, "Escalation: self-test time cap").

| Series | Variant | Base samples | Base median | HEAD samples | HEAD median | Cap | Verdict |
|---|---|---|---|---|---|---|---|
| 1, HEAD 8caf2295 (before the trim) | env | 31, 29, 37 | 31 | 46, 54, 59 | 54 | 51 | FAIL (+23) |
| 1, HEAD 8caf2295 (before the trim) | /bin/bash | 30, 38, 33 | 33 | 47, 60, 45 | 47 | 53 | pass (+14) |
| 2, HEAD 462a6063 (after the I5 trim) | env | 34, 36, 38 | 36 | 59, 53, 52 | 53 | 56 | pass (+17) |
| 2, HEAD 462a6063 (after the I5 trim) | /bin/bash | 40, 33, 28 | 33 | 60, 50, 59 | 59 | 53 | FAIL (+26) |

A per-case timing run at `462a6063` (`/bin/bash`, load about 20) put `tq-lane-k` itself at about 0.8 s after the trim. The rest of the HEAD-over-base delta comes from cases that Plans 29–30 added and Plans 30–31 already measured at +13 to +15 s.

<!-- B6-LOCAL-2-JSON-BEGIN -->
{
  "schema": "threadline.phase247-b6-local/2",
  "head": "4f872f5e701f500d9f5ca9be416cc22c64c569d4",
  "runner_sha256": "2d420a97fa5b2218e84cd8b5217e0d6664873fd7900023c55590c166c201449b",
  "lane_k": {"current": 12, "min": 0, "latest": 0},
  "whole_suite": {"tests": 3388, "failures": 0, "properties": 32, "excluded": 3, "exit": 0},
  "lane_runs": [
    {"lane": "current", "scope": "", "exit": 0, "tests": 3388, "failures": 0, "printed_ratio": "1.23", "k": 12, "queued": 12, "claimed": 12, "claim_lines": 12, "overhead_mean_ms": 2867},
    {"lane": "min", "scope": "toolchain", "exit": 0, "tests": 2568, "failures": 0, "printed_ratio": "1.32", "k": 0, "queued": 0, "claimed": 0, "claim_lines": 0, "overhead_mean_ms": null},
    {"lane": "latest", "scope": "toolchain", "exit": 0, "tests": 2568, "failures": 0, "printed_ratio": "1.26", "k": 0, "queued": 0, "claimed": 0, "claim_lines": 0, "overhead_mean_ms": null}
  ],
  "queued_hang_proof": {"budget_s": 90, "elapsed_s": 65, "exit": 1, "named": "test/zz_queued_hang_test.exs:4", "hang_marker": true, "claim_exit": 1, "claim_invocation": "p1-1", "monitor_deadline_ms": 60000, "leftover_beam": false},
  "static_identity_main": {"ref": "824c28517820c1cd6595f2e0e60b34ec3ce64d14", "lanes": ["min", "latest"], "bashes": ["env", "/bin/bash"], "partition_files_identical": true, "current_assignment_identical": true},
  "postgres": "16",
  "toolchain": {"elixir": "1.17.3-otp-27", "erlang": "27.3.4.15"},
  "self_test_seconds": {
    "method": "D-34 interleaved (base, head, base, head, base, head per bash)",
    "baseline_ref": "824c28517820c1cd6595f2e0e60b34ec3ce64d14",
    "head_ref": "462a6063a15767479a9a499bd0f4f31385f575ae",
    "baseline_env": 30,
    "baseline_bin_bash": 30,
    "head_env": 45,
    "head_bin_bash": 47,
    "samples": {
      "baseline_env": [29, 31, 30],
      "baseline_bin_bash": [32, 28, 30],
      "head_env": [45, 52, 44],
      "head_bin_bash": [47, 52, 45]
    },
    "load_averages": {
      "env": {"start": [10.65, 14.58, 17.19], "end": [9.03, 11.98, 15.42]},
      "bin_bash": {"start": [8.25, 11.72, 15.29], "end": [12.98, 12.15, 14.57]}
    },
    "halted_series": [
      {"series": 1, "head": "8caf2295", "method": "non-interleaved rounds", "env": {"baseline": [31, 29, 37], "head": [46, 54, 59], "verdict": "FAIL"}, "bin_bash": {"baseline": [30, 38, 33], "head": [47, 60, 45], "verdict": "pass"}},
      {"series": 2, "head": "462a6063", "method": "non-interleaved rounds, after the I5 trim", "env": {"baseline": [34, 36, 38], "head": [59, 53, 52], "verdict": "pass"}, "bin_bash": {"baseline": [40, 33, 28], "head": [60, 50, 59], "verdict": "FAIL"}}
    ]
  }
}
<!-- B6-LOCAL-2-JSON-END -->
