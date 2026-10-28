---
phase: 247-ci-critical-path-and-suite-lanes
plan: 31
subsystem: ci-partitioning
status: complete
tags: [ci, partition-runner, tail-queue, D-27, D-12, CI-03, CI-04, contracts, docs]
requires:
  - phase: 247-30
    provides: "TAIL_QUEUE_K=12 runtime tail queue, its seams and stdout/summary formats in bin/ci-test-partitions"
provides:
  - "ci_topology_contract_test: behavioral `tail queue lifts exactly TAIL_QUEUE_K=12 ungrouped sync files and a smaller K is caught` (K=4 mutant), rule=tail-queue-seams, rule=single-invocation-site, rule=tail-queue-doc (`CONTRIBUTING documents the tail queue with the runner's K`)"
  - "run_export_storage_partitions!/3 extra_env; split negative control at CI_TEST_PARTITIONS_TAIL_K=0, grouped case at the real K"
  - "CONTRIBUTING tail-queue sentences (the 12 heaviest, same-DB single-file claims, exactly once, claim table; budget covers queued files)"
  - "247-B6-LOCAL.md B6-LOCAL-JSON (threadline.phase247-b6-local/1): whole suite, five lane runs, queued-hang proof, self-test medians"
affects: ["247-32", "247-33", "247 verification"]
actuals:
  tokens: 21000
  tasks: 3
  commits: 5
plan_head_before: 145c1fee5611d07ddf68c7007c2b231b0379aec1
plan_head_after: 5996646364faea53285775a37d9f952640c05d26
tech-stack:
  added: []
  patterns:
    - "Behavioral contract over the copied runner: a MIX_BIN=false sandbox stops at the serial compile after the lift, so tail-queue.tsv is readable without a BEAM"
    - "As-of instants read from the stamping clock (clock_timestamp()) instead of the BEAM wall clock"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-LOCAL.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-31-SUMMARY.md
  modified:
    - test/threadline/ci_topology_contract_test.exs
    - CONTRIBUTING.md
    - test/threadline/query/row_key_read_test.exs
    - .planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md
key-decisions:
  - "The seam-absence and single-invocation-site rules live inside partition_topology_errors (so the SUITE-02 test asserts them), each with its own rule= name and mutation control (three seams, one duplicated call site)"
  - "The grouped export case passes CI_TEST_PARTITIONS_TAIL_K=nil explicitly so an inherited shell value cannot change K"
  - "The doc-parity rule compares whitespace-normalized paragraph text, so CONTRIBUTING can be rewrapped without breaking it; in-test K and doc mutants prove both directions"
  - "A whole-suite red at row_key_read_test.exs:204 was fixed test-only (db_now/0) with a mutation control and the whole series restarted from the beginning"
requirements-completed: []
coverage:
  - id: D1
    description: "Tail queue contract-pinned: K test with mutant, seam absence in ci.yml, single invocation site, export control honest"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "Task 1 verify: ci_topology, ci_workflow_parity, repo_contract_scope, partition_monitor (105 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CONTRIBUTING describes the tail queue; doc-parity rule ties the documented K to TAIL_QUEUE_K"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "Task 2 verify: ci_topology, repo_contract_scope, ci_coverage_doc, ci_workflow_parity (110 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Local lanes green with no coverage lost; real-BEAM queued-hang naming; self-test cap"
    requirement: CI-04
    verification:
      - kind: integration
        ref: "Task 3 verify (B6 local: PASS): 247-B6-LOCAL.md JSON block"
        status: pass
    human_judgment: false
duration: 150min
completed: 2026-10-28
---

# Phase 247 Plan 31: Tail-queue contracts, docs and local proof Summary

**The Plan 30 tail queue is now pinned by contracts:**

- a behavioral K=12 sandbox test, which a K=4 mutant fails;
- a ci.yml seam ban;
- a single-invocation-site rule;
- a CONTRIBUTING doc-parity rule.

**The export-overlap negative control has its teeth back, at a static split.** On ephemeral postgres:16:

- the whole suite and five partitioned lane runs went green with every queued file claimed;
- the current-lane totals equal the whole suite's 3387 tests;
- a real PartitionMonitor named `test/zz_queued_hang_test.exs:4` from inside a claim invocation, and the run failed in 64 s.

## Performance

- **Duration:** about 150 min. Most of it was the suite runs on a loaded shared host, including one restarted series.
- **Completed:** 2026-10-28
- **Tasks:** 3 of 3
- **Files modified:** 4 tracked files plus 2 planning records

## Accomplishments

### Task 1: contracts

- **K test.**
  - The sandbox holds 14 sync files, a heavier async file and a heavier colocated pair. It asserts that the queue is exactly the 12 heaviest ungrouped sync files, heaviest first.
  - `TAIL_QUEUE_K=12` is matched on exactly one line with `Regex.scan`.
  - The K=4 mutant yields 4 rows and is caught.
- **New rules.** `rule=tail-queue-seams` bans the three test-only seams from ci.yml. `rule=single-invocation-site` requires `String.split/2` on the canonical invocation to give 2 parts. Each rule has mutation controls that trip it by name.
- **Export-overlap control.**
  - The split control runs at `CI_TEST_PARTITIONS_TAIL_K=0`, with the reason in a comment, and still asserts `export fixture overlap`.
  - The grouped case runs at the real K.
  - `partition_monitor_test.exs` and `partition_monitor.ex` are unchanged against origin/main.

### Task 2: docs

- The CONTRIBUTING partition paragraph now says:
  - the 12 heaviest sync, non-colocated files (`TAIL_QUEUE_K`) are held in a tail queue;
  - each partition claims the next-largest queued file and runs it as its own `mix test <file>` on the same database;
  - every file still runs exactly once;
  - the step summary lists each claim.
- The hang paragraph says the 480 s budget covers queued files too.
- `rule=tail-queue-doc` has K and doc mutants.

### Task 3: local proof

All runs are at `eae71898`. Details are in `247-B6-LOCAL.md`.

- **Whole suite:** 3387 tests, 0 failures.
- **current ×3:** 3387/0 each. max/min 1.09, 1.22 and 1.26. overhead_mean_ms 3726, 1447 and 2406.
- **min and latest, toolchain scope:** 2567/0 each. max/min 1.04 and 1.03.
- **Every run:** K=12, queued = claimed = claim lines = 12.
- **Queued-hang proof:** a 90 s budget, exit 1 after 64 s, a `HANG: in-flight:` block naming `test/zz_queued_hang_test.exs:4` with a `Process.sleep/1` frame, from claim invocation `p1-1` (claim `exit=1`). No BEAM was left.
- **Self-test medians:** env 31 → 46 (+15 s) and /bin/bash 33 → 46 (+13 s), within the +20 s cap.

## Task Commits

1. **Task 1:** `0de4c4e5` `test(247-31): contract-pin the partition tail queue`. This was a tracer task. Its full automated verify was re-run green before expansion.
2. **Task 2:** `f2dbe251` `docs(247-31): document the partition tail queue`
3. **Task 3 triage (test-only fix):**
   - `29636579` `test(247-31): read the as_of instant from the database clock in row_key_read`
   - `eae71898` `test(247-31): state only the observed clock mechanism in row_key_read`
4. **Task 3 record:** `59966463` `docs(247-31): record B6 local lane runs and queued-hang proof`

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, halt-clause triage] Cross-clock `as_of/4` flake in `row_key_read_test.exs`**
- **Found during:** Task 3 step 1. The first whole-suite run, at `f2dbe251`, had 1 failure.
- **Issue:** `as_of(…, DateTime.utc_now())` returned the insert snapshot (`"a"`) where `"b"` was expected. The trigger stamps `captured_at` with the database's `clock_timestamp()`, so the test was comparing two clocks. 247-13 recorded the same line once, as `:before_audit_horizon`.
  - A 240 s probe under full-suite load never caught the database ahead of the BEAM: max −288 µs, and no backward step.
  - So the exact trigger was not reproduced. The cross-clock comparison is the defect class.
- **Fix:** `db_now/0` reads `clock_timestamp()`, used at all three `as_of/4` sites in the file. This is test-only, and the assertions are unchanged.
- **Mutation control:** an instant 1 µs before the update's stamp gives 9 tests, 2 failures, with exactly the observed right-hand side. Restored, the file is 9/0.
- **Restart:** the whole series restarted from the beginning at `eae71898`. The first red run is not counted.
- **Files modified:** `test/threadline/query/row_key_read_test.exs`. It is outside the plan's files list, which the halt clause allows.
- **Commits:** 29636579, eae71898

**2. [Plan detail] Scratch copy took `_build/test`, not all of `_build/`**
- The hang proof runs `MIX_ENV=test` only, so the other build directories were not needed.

**3. [Plan detail] Extra JSON keys**
- `247-B6-LOCAL.md` adds informational keys the verify ignores: `first_series_red`, `claim_invocation`, `monitor_deadline_ms`, `leftover_beam`, and whole-suite `properties`/`excluded`.

## Deferred Issues

- Sibling write-then-`as_of(DateTime.utc_now())` sites remain:
  - `row_key_composite_test.exs:133` and `:202`
  - `as_of_property_test.exs:295`
- These are logged in `deferred-items.md`. None failed in this plan's runs.

## Known Stubs

None.

## Threat Flags

None. The changes are tests, docs and evidence only.

## Next Phase Readiness

- **Plan 32:** may cite the B6-LOCAL overheads and the self-test delta (+15/+13 s) as local, informational inputs.
- **Plan 33:** lands this non-planning tree. The last code commit is `eae71898`, and the commits after it are planning-only.

## Self-Check: PASSED

- FOUND: test/threadline/ci_topology_contract_test.exs, CONTRIBUTING.md, 247-B6-LOCAL.md
- FOUND commits: 0de4c4e5, f2dbe251, 29636579, eae71898, 59966463
- No labelled container remains. `git status --porcelain test/` is empty. Repo hygiene is green.
