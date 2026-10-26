---
phase: 247-ci-critical-path-and-suite-lanes
plan: 04
subsystem: ci
tags: [exunit-formatter, partitioned-tests, hang-diagnosis, ci-timings, bash]
status: complete

requires:
  - "247-03 (wave 1)"
provides:
  - "D-13: Threadline.Test.PartitionMonitor, a CI-only ExUnit formatter with an unlinked VM-wall-clock deadline watcher (HANG: in-flight: block, stacks, System.halt(1)) and a :sigquit report"
  - "D-11 recording half: threadline.partition-timings/1 TSV per partition (THREADLINE_PARTITION_TIMINGS_FILE)"
  - "bin/ci-test-partitions attaches the monitor, sets THREADLINE_TEST_DEADLINE_MS from CI_TEST_PARTITIONS_BUDGET_S (default 480), and has --ingest-weights <dir> [--lane <name>]"
  - "D-16(b): test/threadline/partition_monitor_test.exs runtime-sandbox proof"
affects: [247-05, 247-12, "Land B"]

actuals:
  tokens: 10250
  tasks: 3
  commits: 2
plan_head_before: 98fba89f8ff727250f1fee21d1a060055483c07a
plan_head_after: 4a888cafbcdb0a13e66eb410e4cdb8e290749ff5

tech-stack:
  added: []
  patterns:
    - "Formatter GenServer + plain-spawn (unlinked) watcher, so the deadline outlives ExUnit's EM.stop"
    - "Runtime sandbox mix project in tmp_dir, run through a Port with a kill-on-timeout, for subprocess hang proofs"
    - "TSVs selected by their header lane= field, never by path or artifact name"

key-files:
  created:
    - test/support/partition_monitor.ex
    - test/threadline/partition_monitor_test.exs
  modified:
    - bin/ci-test-partitions
    - test/partition_weights.txt

key-decisions:
  - "247-04: in-flight process selection = any process whose current_stacktrace has a frame from an in-flight test module or from ExUnit.Runner (test bodies, setup_all and module processes), then non-idle processes, capped at 200; process dictionaries are never read"
  - "247-04: a CI_TEST_PARTITIONS_BUDGET_S of 30 s or less gives a non-positive deadline, which disarms the in-VM watcher (the 247-05 bash watchdog still applies); leading zeros are rejected"
  - "247-04: --ingest-weights takes the lower-middle value for an even count, dies (exit 2) on a TSV without the threadline.partition-timings/1 header, and ignores rows that are not test/...*_test.exs with integer wall_ms"
  - "247-04: the hang report also lists modules that have run tests but have none running as `(module open, no test running)`, and `nothing in flight` when no module is running"

patterns-established:
  - "Subprocess mix runs in tests go through Port.open with :os_pid and a pkill/kill on timeout, so a failed halt cannot leak a BEAM"

requirements-completed: []

coverage:
  - id: D1
    description: "Monitor attached by bin/ci-test-partitions with deadline + timings env; fake mix consumes --formatter pairs"
    requirement: CI-04
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test (bash 5 and /bin/bash 3.2), case (i, cont.) and budget validation"
        status: pass
  - id: D2
    description: "--ingest-weights median, keep-absent, header, path sort, >2x moves both directions, malformed rows ignored, --lane selection and rejection"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test case (r); mutation probes (median, lane parse, monitor args) each turned it red"
        status: pass
  - id: D3
    description: "Test-body and setup_all hangs named with file:line / module plus a Process.sleep stack frame, VM halts non-zero; no-deadline run exits 0"
    requirement: CI-04
    verification:
      - kind: unit
        ref: "test/threadline/partition_monitor_test.exs (3 tests)"
        status: pass
  - id: D4
    description: "Full partitioned suite with the monitor attached: 4 TSVs, every enumerated file timed exactly once, CLI output intact"
    requirement: CI-03
    verification:
      - kind: integration
        ref: "mix verify.test_partitioned on ephemeral postgres:16"
        status: pass
  - id: D5
    description: "Monitor behaviour on the Elixir 1.15.8 min lane"
    requirement: CI-04
    verification:
      - kind: other
        ref: "backstop: the untagged partition_monitor_test runs on the min lane after Land B"
        status: unknown

duration: 15min
completed: 2026-10-26
---

# Phase 247 Plan 04: PartitionMonitor, ingest-weights and the D-16(b) sandbox proof Summary

**A CI-only ExUnit formatter writes per-file timing TSVs for each partition. Its unlinked watcher, armed on VM wall-clock time, names a hung test body or setup_all with file:line and stacks, then halts the VM. `bin/ci-test-partitions` attaches it and can turn its TSVs back into `test/partition_weights.txt` with `--ingest-weights [--lane]`.**

## Performance

- **Duration:** about 15 min
- **Completed:** 2026-10-26
- **Tasks:** 3 (2 with code commits; Task 3 was verification only and found nothing to fix)
- **Files modified:** 4

## Accomplishments

- `Threadline.Test.PartitionMonitor` handles `:module_started`, `:test_started`, `:test_finished`, `:module_finished`, `:suite_finished` and `:sigquit`, and ignores every other event. It uses only fields that exist on 1.15. There is no `spawn_link`, `JSON`, `Duration` or `Process.set_label`.
- The watcher is a plain `spawn` that gets a snapshot after every event and polls about every 250 ms against `:erlang.statistics(:wall_clock)`. When it fires it prints `----- HANG: in-flight: ... -----`, the in-flight lines, a `----- HANG: processes -----` section and `----- HANG: end -----`, then calls `System.halt(1)`.
- `bin/ci-test-partitions` keeps all four byte-pinned anchors. The monitor args are appended after `"${files[@]}"` as `${monitor_args[@]+"${monitor_args[@]}"}`. The deadline is budget × 1000 − 30000 (450000 at the default budget), and each partition gets its own `partition-timings-<i>.tsv`.
- `--ingest-weights <dir> [--lane <name>]` takes the per-file median, keeps weights for files absent from the TSVs, writes the shared `weights_header` block through mktemp + mv in the weights directory, and prints `ingest-weights: N files from M TSVs (K skipped by --lane)` and the `moved >2x:` lines sorted by file.

## Task Commits

1. **Task 1 (tracer): record timings, attach the monitor, ingest mode.** `b7f214d5` (feat). Tracer gate: the automated verify was re-run end to end (both self-tests and the real `mix test --formatter ... PartitionMonitor` TSV check) and passed. Expansion continued.
2. **Task 2: in-VM hang naming and the D-16(b) sandbox test.** `4a888caf` (feat)
3. **Task 3: prove it on the real partitioned runner.** Verification only, no commit. The locally ingested weights were restored with `git checkout -- test/partition_weights.txt`, and `git diff --quiet` passed.

## Task 3 measurements (local, ephemeral postgres:16, Elixir 1.17.3)

| Partition | Exit | Seconds | Counts | TSV rows | boot_ms | wall_ms |
|---|---|---|---|---|---|---|
| 1 | 0 | 54 | 828 tests, 0 failures | 67 | 943 | 54212 |
| 2 | 0 | 58 | 899 tests, 0 failures | 69 | 969 | 57811 |
| 3 | 0 | 70 | 931 tests, 0 failures | 68 | 929 | 70236 |
| 4 | 0 | 49 | 688 tests, 0 failures | 64 | 1034 | 48883 |
| total | - | 71 | - | 268 | - | - |

- The union of TSV rows equals `enumerated.txt` exactly (268 files, each once; checked by `diff`). Each partition log still has its CLIFormatter summary line, and no partition log contains `HANG:`.
- Real-data round trip: `--ingest-weights tmp/ci-test-partitions` wrote 268 rows from 4 TSVs and reported 162 `moved >2x` lines. That is expected for local wall times against traced `--slowest-modules` weights. The committed refresh from CI data belongs to 247-12. `--lane current` on the same local TSVs (all `lane=local`) exited 2, as designed.
- Sandbox boot (VM start to first `module_started`) measured 194–200 ms locally, so the 2000 ms deadline has about a 10x margin. It was not raised.

## Decisions Made

See `key-decisions` in the frontmatter. The process-selection rule replaces the plan's "pids carried in the events" idea. ExUnit 1.15 carries no pids, and on 1.17 the hung test frame stays on the stack even for a tail-position `Process.sleep(:infinity)` (observed). The `ExUnit.Runner` frame match is the fallback for stacks where it does not.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Kill-on-timeout for the sandbox subprocess**
- **Found during:** Task 2
- **Issue:** `System.cmd` blocks until the child exits. A monitor regression that stopped halting would leave a BEAM running after ExUnit's test timeout, which breaks the plan's rule against leftover processes.
- **Fix:** The sandbox runs go through `Port.open` with `:os_pid`. After 60 s the process tree is killed with `pkill -KILL -P` plus `kill -KILL`, and the test fails with the captured output.
- **Files modified:** test/threadline/partition_monitor_test.exs
- **Commit:** 4a888caf

**2. [Rule 2 - Correctness] Ingest self-test also covers a >2x drop and malformed rows**
- **Found during:** Task 1, by mutation probe
- **Issue:** Removing the `old > 2 × new` branch left the self-test green.
- **Fix:** Added a shrinking file (5000 → 1000), plus rows with a non-test path and non-numeric ms that must be ignored (T-247-09).
- **Commit:** b7f214d5

**3. [Rule 3 - Preventive] Sandbox `mix.exs` lists `extra_applications: [:ex_unit]`**
- **Found during:** Task 2
- **Issue:** The separate `mix compile` step keeps compile time out of the 2000 ms VM deadline, and it compiles a module that matches on `ExUnit.*` structs. Mix 1.15+ prunes code paths for applications a project does not declare.
- **Fix:** Declared `:ex_unit` in the sandbox application from the start. This was not shown to be necessary: no run without it was tried.
- **Commit:** 4a888caf

The fake mix uses a "next argument is the formatter value" flag instead of the plan's literal `shift 2`, because its argument loop is a `for` loop. The behaviour is the same, and a trailing `--formatter` with no value is rejected.

## Known Stubs

None.

## Threat Flags

None. The stack dump matches T-247-08 (stack, registered name, status, queue length only, printed to the partition log/stdout). Ingest matches T-247-09 (numeric ms and test-path rows only, atomic write).

## Next Phase Readiness

- 247-05 can rely on `CI_TEST_PARTITIONS_BUDGET_S` and the `HANG:` marker for the bash watchdog. It should set `THREADLINE_CI_LANE` in ci.yml so TSV headers carry the real lane.
- 247-12 ingests the CI artifacts with `--ingest-weights <dir> [--lane current]`.

## Self-Check: PASSED

- FOUND: test/support/partition_monitor.ex, test/threadline/partition_monitor_test.exs
- FOUND: b7f214d5, 4a888caf (both ancestors of HEAD)
