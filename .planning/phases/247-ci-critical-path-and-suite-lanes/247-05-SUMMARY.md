---
phase: 247-ci-critical-path-and-suite-lanes
plan: 05
subsystem: ci
tags: [bash, watchdog, process-groups, partitioned-tests, hang-diagnosis, github-actions, artifacts]
status: complete

requires:
  - "247-03 (wave 1)"
  - "247-04 (PartitionMonitor, CI_TEST_PARTITIONS_BUDGET_S, timings TSVs, --ingest-weights)"
provides:
  - "D-14: bin/ci-test-partitions runs each partition in its own process group; watch_partitions stops an over-budget partition (QUIT the BEAM, backstop, group TERM, group KILL after the grace) and records status=124 reason=budget"
  - "D-14: a capped `Hung partitions` table in the step summary (in-flight names only)"
  - "D-12: `| max/min | - | <r> | - |` report row and a stdout-only `::warning::partition ratio <r> exceeds 1.15`"
  - "D-15: ci.yml Run tests `timeout-minutes: 12` (480 s < 12 min < job 20) and `THREADLINE_CI_LANE: ${{ matrix.lane }}`"
  - "D-11/D-15: partition-timings-<lane>-<run> (always) and partition-logs-<lane>-<run> (failure) artifacts, 14-day retention"
  - "ci_topology rules run-tests-step-timeout, watchdog, monitor-args, timings-upload, logs-upload, each with a rule-specific mutation control"
affects: [247-06, 247-12, "Land B"]

actuals:
  tokens: 10873
  tasks: 3
  commits: 3
plan_head_before: cd93e7362493f4eff34ea3168b189e0a14cb316b
plan_head_after: 57f396c3a961fc9f1c633b03eac611c7da67dc0b

tech-stack:
  added: []
  patterns:
    - "`set -m` around the fork loop only: each `( ... ) </dev/null &` partition leads its own process group, signalled as `kill -SIG -- -PGID`"
    - "Pre-kill descendant snapshot of `<pid> <lstart>`; a later KILL only hits a PID whose start time still matches"
    - "Test-only seams (DIAG_WAIT_S, KILL_GRACE_S, PSQL, REPORT_ONLY) shrink the hang self-tests to seconds and keep them offline"

key-files:
  created: []
  modified:
    - bin/ci-test-partitions
    - .github/workflows/ci.yml
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
    - CONTRIBUTING.md

key-decisions:
  - "247-05: the watchdog writes the `.budget` marker before any signal. The partition's own status writer then exits 124 without writing, and WATCHDOG_KILLED forces fail=1 after the byte-pinned wait loop. A partition that exits 0 during diagnosis still fails."
  - "247-05: if the log already holds `HANG: in-flight:`, QUIT is skipped. The backstop (log tail, process tree, pg_stat_activity) prints only when neither `HANG: in-flight:` nor `Aborting test suite` arrived."
  - "247-05: the Hung partitions table takes the monitor's HANG block names. It uses ExUnit's `* test [file:line]` abort list only when that block is absent, so a real QUIT (which yields both) lists each test once."
  - "247-05: the max/min ratio is n/a when no partition with files has a known time, or when the fastest took 0 s."
  - "247-05: the watchdog polls at 0.1 s, then 0.3 s, then once a second, so fast runs stay fast. That is within D-14's 'up to 5 s'."

patterns-established:
  - "A fake process that must answer QUIT is perl, not bash: a background command starts with QUIT ignored, and bash cannot trap a signal ignored on entry. The BEAM installs its own handler (probed)."

requirements-completed: []

coverage:
  - id: D1
    description: "Hung partition stopped at budget: backstop, group TERM, Exit 124, siblings pass, no leftover process; TERM-ignoring partition escalated to SIGKILL; QUIT-answering partition skips the backstop and is named"
    requirement: CI-04
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test cases (s) hang, (t) hang_ignore_term, (u) hang_quit; bash 5, /bin/bash 3.2, and bash 3.2 throughout (PATH-pinned)"
        status: pass
  - id: D2
    description: "Real BEAM hang end to end: Process.sleep(:infinity) test, 8 s budget, QUIT -> ExUnit abort + monitor sigquit block, Exit 124, test named in the summary, no leftover BEAM"
    requirement: CI-04
    verification:
      - kind: integration
        ref: "throwaway mix project with the committed script + partition_monitor.ex (scratchpad, removed)"
        status: pass
  - id: D3
    description: "max/min row 1.30 + warning / 1.10 no warning / zero-file partition excluded / n/a; warning stays out of the step summary; exit 0"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test case (v) via CI_TEST_PARTITIONS_REPORT_ONLY"
        status: pass
  - id: D4
    description: "Timeout layering, watchdog call, monitor args, timings and logs uploads contract-pinned with rule-specific mutation controls; Dialyzer timeout control scoped to its job"
    requirement: CI-04
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs"
        status: pass
  - id: D5
    description: "Full suite and the real partitioned runner on ephemeral postgres:16"
    requirement: CI-03
    verification:
      - kind: integration
        ref: "mix verify.test (3346 tests, 32 properties, 0 failures) and mix verify.test_partitioned (4 partitions green, max/min 1.67 warning printed, exit 0)"
        status: pass
  - id: D6
    description: "The new ci.yml keys and artifacts behave on GitHub Actions (step timeout, matrix.lane in TSV headers, artifact uploads)"
    requirement: CI-04
    verification:
      - kind: other
        ref: "backstop: first CI run of Land B"
        status: unknown

duration: 50min
completed: 2026-10-26
---

# Phase 247 Plan 05: Partition budget watchdog, timeout layering and the max/min ratio Summary

**`bin/ci-test-partitions` now gives each partition its own process group. A non-blocking watchdog asks a hung partition's BEAM for ExUnit's abort list, prints a backstop when the VM cannot answer, then sends TERM and, if needed, KILL to the group. The partition is recorded as Exit 124 and its stuck tests are named in the step summary. ci.yml sets the step timeout between the 480 s budget and the 20-minute job timeout and uploads the timings and failure logs.**

## Performance

- **Duration:** about 50 min
- **Completed:** 2026-10-26
- **Tasks:** 3, each with its own commit
- **Files modified:** 5

## Accomplishments

- `set -m` is on for the fork loop only. Each partition subshell (`trap ':' TERM`, stdin `/dev/null`) runs mix in the background, records the BEAM PID in `partition-<i>.beam.pid` and waits on it. All four byte anchors are unchanged: the mix line substring, the `local fail=0` per-PID wait loop, `verify_assignment` and `WEIGHTS_REL`.
- `watch_partitions "$n" "$log_dir"` sits directly above `  local fail=0`. It only polls with `kill -0` and the age since fork, and never blocks on `wait`. On budget it calls `stop_over_budget`, which does the following:
  - It writes the `.budget` marker and prints `ci-test-partitions: partition <i> exceeded budget <s>s`.
  - Unless the log already has the HANG block, it sends QUIT to the BEAM and waits up to 30 s for either marker.
  - If neither marker arrives, it prints the backstop: last 40 log lines, the `ps -A -o pid,ppid,etime,args` rows for the group and its descendants, and `pg_stat_activity` for `threadline_test<i>`, with `PGCONNECT_TIMEOUT` and `statement_timeout`.
  - It sends TERM to the group, waits up to 10 s, then sends KILL to the group and to any snapshot descendant whose start time still matches.
  - It writes `status=124 reason=budget`.
- `kill_all` (INT/TERM) now sends TERM to each process group, waits for the grace, then sends KILL to the group.
- `report()` adds `| max/min | - | <r> | - |` after `| total |` and a `Hung partitions` table (at most 10 names of 100 characters, with `|` replaced). The `::warning::` line goes to stdout only.
- ci.yml `Run tests` keeps `      - name: Run tests\n        run: mix verify.test_partitioned\n` byte for byte. After it come `timeout-minutes: 12`, then `env: THREADLINE_CI_LANE: ${{ matrix.lane }}`, plus the layering comment. Two upload steps follow, using the existing `upload-artifact@cf430e03… # v7.0.2` pin.
- CONTRIBUTING has a new paragraph right after the partitions paragraph. It covers the budget, the HANG dump, Exit 124, both artifacts, `--ingest-weights` (`--write-weights` as the offline fallback) and the max/min warning. Every existing sentence is unchanged.

## Task Commits

1. **Task 1 (tracer): process-group watchdog, Exit 124, hang self-tests.** `8595702a` (feat). Tracer gate: the automated verify was re-run on bash 5 and `/bin/bash` 3.2, `pgrep -f 247hangsentinel` found nothing, and the topology and parity contracts passed. Expansion continued.
2. **Task 2: max/min ratio row + ci.yml timeout, lane env and artifacts.** `4df9752f` (feat)
3. **Task 3: topology contract rules and controls, CONTRIBUTING, gates.** `57f396c3` (test)

## Verification evidence

| Check | Result |
|---|---|
| `bin/ci-test-partitions --self-test` (bash 5.2) | ok, about 24 s (was 2 s), ends `... hang, hang_ignore_term, hang_quit, max/min ratio)` |
| `/bin/bash bin/ci-test-partitions --self-test` | ok |
| bash 3.2 throughout (`bash` on PATH pinned to `/bin/bash`, so the sandbox copy and fake mix run 3.2 too) | ok |
| `pgrep -f 247hangsentinel` after each run | nothing |
| Real BEAM hang (throwaway project, 8 s budget) | exit 1 after 9 s, row `\| 1 \| 124 \|`, summary names `test/hang_test.exs:3 test waits forever on purpose`, no leftover BEAM |
| Quick contract list (6 files) | 132 tests, 0 failures |
| `mix verify.test` on ephemeral postgres:16 | 32 properties, 3346 tests, 0 failures, 3 excluded |
| `mix verify.test_partitioned` on ephemeral postgres:16 | 4 partitions exit 0, `\| max/min \| - \| 1.67 \| - \|`, warning printed, exit 0 |
| `mix verify.format`, `mix verify.credo` | clean |
| Non-portable tools (`timeout`, `gtimeout`, `setsid`, `wait -n`, `ps --ppid`) outside comments | 0 |

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Parity contract's flow-mapped-step control produced invalid YAML**
- **Found during:** Task 2
- **Issue:** `ci_workflow_parity_contract_test.exs` "flow-mapped step with continue-on-error" added a flow step right after the Run tests `run:` line. With `timeout-minutes`/`env:` now after that line, the mutated workflow no longer parsed (`rule=yaml-parse`).
- **Fix:** The control now inserts the same flow step just before `- name: Run tests`. The step is unchanged, it stays in verify-test, and it must still report `rule=continue-on-error`. No assertion was weakened.
- **Files modified:** test/threadline/ci_workflow_parity_contract_test.exs
- **Commit:** 4df9752f

**2. [Rule 1 - Bug] The real QUIT listed each hung test twice**
- **Found during:** Task 3 (real BEAM end-to-end check)
- **Issue:** After QUIT, the log has both ExUnit's `* test … [file:line]` list and the monitor's `HANG: in-flight:` block, so the Hung partitions table showed each test twice in two formats.
- **Fix:** `hung_rows` uses the HANG block when present and falls back to the abort list otherwise.
- **Files modified:** bin/ci-test-partitions
- **Commit:** 57f396c3

**3. [Rule 2 - Correctness] Extra cases and checks beyond the plan's minimum**
- **Self-test (u) `hang_quit`:** proves that the QUIT, abort-list, skip-backstop and named-in-summary path works offline.
- **Topology rules:** a `logs-upload` rule and control, plus two layering controls (step timeout raised to the job's 20, budget default raised to 900). Without these, the `<` comparisons in the layering check would go untested.
- **Seam checks:** `CI_TEST_PARTITIONS_DIAG_WAIT_S` and `CI_TEST_PARTITIONS_KILL_GRACE_S` must be integers (exit 2 otherwise), and the self-test checks this.
- **Commits:** 8595702a, 57f396c3

**4. [Rule 3 - Blocking] Credo complexity**
- **Issue:** Adding the five checks inline pushed `partition_topology_errors` over credo's cyclomatic limit.
- **Fix:** The checks moved into `partition_hang_wiring_checks/3`, which uses small predicate helpers (`timeout_layered?`, `watchdog_wired?`, `monitor_args_wired?`, `partition_upload?`).
- **Commit:** 57f396c3

## Known Stubs

None.

## Threat Flags

None. T-247-10 (kill scope) is mitigated in three ways. Signals go only to `-PGID` of groups this script created. Snapshot descendants are KILLed only on a PID plus start-time match. There is no `pkill` and no PGID 0. T-247-11 is mitigated because the summary carries only the table and at most 10 capped names, and the self-test asserts that no `FAKE_MIX`, `last 40`, sentinel or `::warning` text reaches it. T-247-12 is mitigated because the artifact names include the lane and run_id.

## Next Phase Readiness

- 247-06 adds `THREADLINE_TEST_SCOPE` to the same Run tests `env:` block. It sits after `THREADLINE_CI_LANE`, and the anchor and `timeout-minutes: 12` stay first.
- 247-12 can download `partition-timings-<lane>-<run>` and run `bin/ci-test-partitions --ingest-weights <dir> --lane current`.
- The first real CI run (Land B) is the backstop for the GitHub-side behaviour (D6).

## Self-Check: PASSED

- FOUND: bin/ci-test-partitions (watch_partitions ×3, status=124, `kill -KILL -- -`)
- FOUND: .github/workflows/ci.yml (`timeout-minutes: 12` after the Run tests anchor; both artifact names)
- FOUND: test/threadline/ci_topology_contract_test.exs (rule=watchdog, rule=monitor-args, rule=timings-upload, run-tests-step-timeout)
- FOUND commits: 8595702a, 4df9752f, 57f396c3 (ancestors of HEAD)
