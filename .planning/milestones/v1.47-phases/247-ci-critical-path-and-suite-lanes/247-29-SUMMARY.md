---
phase: 247-ci-critical-path-and-suite-lanes
plan: 29
subsystem: ci-partitioning
status: complete
tags: [ci, partition-weights, ingest-weights, lane-rule, review-fixes, gap-closure, D-28, CI-03]
requires:
  - phase: 247-27
    provides: "candidate B min weights (per-file max rule, sha256 cb833068…b187) and tools/min_balance.py"
  - phase: 247-28
    provides: "B5 on main 824c2851 (CI-02 PASS, CI-03 current-lane MISS) and the R3 review round"
provides:
  - "bin/ci-test-partitions lane_rule(): current/'' median, min max, latest median"
  - "--ingest-weights --rule median|max (default lane_rule); strict --output with a mismatched rule exits 2 before reading any TSV; prints 'ingest-weights: rule <rule>'"
  - "Self-test block (z2) with marker 'lane-rule: ok' and 'lane rule' in the final ok line"
  - "Contract test 'lane weight rules: current and latest take the median, min the maximum, and a strict mismatch exits 2' with a min->median mutant"
  - "CONTRIBUTING sentence naming lane_rule, the median/max split and the strict --rule exit 2"
  - "RetentionRun on_exit cleanup in retention_history_live_test.exs and retention/pruner_test.exs (R3-WR-01)"
  - "min_balance.py: fail-closed ratio_of, temp-copy predict/replay (placed() removed), strict_ingest_copy(rule), derive byte-parity against the runner's --rule max"
  - "247-REVIEW-DISPOSITION.md: every R3 finding dispositioned, open: 2"
affects: ["247-30", "247-31", "247-32", "247-33", "247 verification"]
actuals:
  tokens: 12200
  tasks: 3
  commits: 4
plan_head_before: e4cb0591ed7dcc1011e769b74af59f77b70518f5
plan_head_after: 17376b84a115cee46428add7a213cdec4be2b4cf
tech-stack:
  added: []
  patterns:
    - "A per-lane policy lives as a pure case function beside lane_weights(); contract tests read only the production function body, so self-test literals cannot satisfy them"
    - "Phase-local tools never write the live tree: they stage a temporary copy of the runner and the test tree and read every hash from the copy"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-29-SUMMARY.md
  modified:
    - bin/ci-test-partitions
    - test/threadline/ci_topology_contract_test.exs
    - CONTRIBUTING.md
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/retention/pruner_test.exs
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW-DISPOSITION.md
key-decisions:
  - "Without --rule, lanes current/min/latest and the unset lane use lane_rule; any other non-strict --lane keeps the median, so the legacy self-test (r) path is unchanged"
  - "Max is a second branch of the existing per-file awk (last value of the ascending group, floor 1); the median expression is byte-for-byte the old one"
  - "Strict min ingest of the three hash-verified B4 training runs with the default rule is byte-identical to the committed test/partition_weights_min.txt (sha256 cb833068…b187); no weight file changed"
  - "min_balance.py predict, replay and derive all run in one shared stage_copy(); derive now requires the runner's strict --rule max output to equal max_rule byte for byte"
  - "R3-IN-05 is planned for 247-32, not fixed; R3-IN-01/02/04/06/07 are deferred with one-line reasons"
requirements-completed: []
coverage:
  - id: D1
    description: "lane_rule() and --ingest-weights --rule in the runner, with self-test (z2)"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test and /bin/bash bin/ci-test-partitions --self-test (lane-rule: ok)"
        status: pass
  - id: D2
    description: "Byte parity of a strict min ingest of the B4 training runs with the committed min weights; --rule median exits 2 without writing"
    requirement: CI-03
    verification:
      - kind: integration
        ref: "Task 1 <automated> verify (fetch, git archive HEAD scratch copy, cmp)"
        status: pass
  - id: D3
    description: "Contract test with a min->median mutant, and the CONTRIBUTING sentence"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs#lane weight rules: current and latest take the median, min the maximum, and a strict mismatch exits 2"
        status: pass
  - id: D4
    description: "RetentionRun on_exit cleanup in both retention modules"
    verification:
      - kind: integration
        ref: "mix test test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/retention/pruner_test.exs (run twice, 39 tests, 0 failures each)"
        status: pass
  - id: D5
    description: "min_balance.py fail-closed ratio_of, temp-copy predict, derive parity"
    verification:
      - kind: unit
        ref: "python3 -I tools/min_balance.py --self-test; Task 3 <automated> verify"
        status: pass
---

# Phase 247 Plan 29: R3 review fixes and the per-lane ingest rule Summary

**The min lane's per-file maximum rule now lives in `bin/ci-test-partitions` as `lane_rule()` plus `--ingest-weights --rule`. It reproduces the committed min weights byte for byte, and a strict refresh with the wrong rule exits 2. The R3 test-teardown and min_balance.py warnings are fixed, and every R3 finding has a disposition.**

## Performance

- Duration: about 16 min (first task commit 16:12 UTC, last 16:20 UTC)
- Completed: 2026-10-28
- Tasks: 3 of 3
- Commits: 4 task commits (e9bb16ca, f27d11b9, 5b3e5ab8, 17376b84)

## Accomplishments

### Task 1: lane_rule and --rule (R3-WR-04), commit e9bb16ca
- `lane_rule()` sits directly after `lane_weights()`, in the same `printf '%s\n'` arm style: `''|current` median, `min` max, `latest` median, anything else `die` (exit 2).
- `ingest_weights` accepts `--rule median|max`. Any other value exits 2. In strict `--output` mode, an explicit rule that differs from `lane_rule "$lane"` dies right after the lane and output checks. That is before any TSV is read or any temp file is created. A new line `ingest-weights: rule <rule>` follows the unchanged summary line. `weights_header()` is untouched.
- The header comment and `usage()` name `--rule median|max` and the per-lane defaults.
- Self-test (z2) builds 100/300/200 ms runs for one file and checks:
  - (a) strict min without a rule gives the maximum;
  - (b) `--rule max` gives identical bytes;
  - (c) `--rule median` exits 2 and leaves the target unchanged;
  - (d) strict current gives the median;
  - (e) `--rule p90` exits 2;
  - (f) the header block equals `weights_header`.
  It also checks the four `lane_rule` mappings and prints `lane-rule: ok`. Both `bin/ci-test-partitions --self-test` and macOS `/bin/bash` 3.2 pass. A min->median mutant copy of the runner fails the self-test (`strict min ingest must report rule max`).
- Parity proof: `min_balance.py fetch` verified all 20 TSVs against their pinned hashes. Then a strict min ingest of the three training runs (40449332597, 40450141708, 40450801580), run in a `git archive HEAD` scratch copy, printed `ingest-weights: 206 files from 12 TSVs (0 skipped by --lane)` / `ingest-weights: rule max`. The result is byte-identical to `test/partition_weights_min.txt` (sha256 cb833068…b187). `--rule median` exited 2 with `strict --output for lane min requires --rule max, got median`, and the target stayed byte-unchanged.

### Task 2: contract mutant and CONTRIBUTING, commit f27d11b9
- New `@tag :tmp_dir` test in `ci_topology_contract_test.exs`. It builds a sandbox with the runner, two plain test files, R1-headed weights and three runs × four partitions per lane. Under `/bin/bash` it checks:
  - strict min writes `300 test/a_test.exs`;
  - strict current writes `200 test/a_test.exs`;
  - strict min with `--rule median` exits 2 and leaves the file unchanged.
- The test then applies a min->median mutant: `refute mutant == script`, `lane_rule_errors(mutant) == ["wrong rule for lane min"]`, and the mutant's strict min output no longer contains `300 test/a_test.exs`. The production `lane_rule()` body is read with `~r/^lane_rule\(\) \{\n(.*?)^\}/ms`.
- CONTRIBUTING.md gains one sentence (4 added lines, no rewrapped lines) at the end of the `--ingest-weights` paragraph.
- `mix verify.format`, `mix verify.credo` (no issues) and the four contract files (108 tests, 0 failures) all pass against an ephemeral postgres:16.

### Task 3: R3-WR-01..03, R3-IN-03 and the dispositions, commits 5b3e5ab8 and 17376b84
- R3-WR-01: both retention modules register `on_exit(fn -> Repo.delete_all(RetentionRun, repo_opts()) end)` in `setup`, with a comment saying why. Both files passed twice (39 tests, 0 failures each run).
- R3-WR-02: `ratio_of` now fails on no partitions, on any partition with `files <= 0` (and names those partitions), and on a non-positive minimum cost. Max/min is computed over all partitions.
- R3-WR-03: `placed()`, its signal handlers and the `signal`/`contextmanager` imports are gone. A shared `stage_copy()` copies the runner and the whole `test/` tree (which holds the colocation file) into a `tempfile.mkdtemp` directory and writes any candidate to the copy's lane path. `run_assignment(lane, root, candidate)` runs the copied runner and reads every input from the copy: raw weights, async map, factor and sha256s. `cmd_predict` and `cmd_replay` pass `--weights` through. The docstring is updated.
- `strict_ingest_copy(train, lane, rule)` passes `--rule`, and its dead `inventory` return is dropped. `load_run`'s unused `partition_wall_ms` is also dropped (R3-IN-03). `cmd_derive` uses rule max and requires `max_rule(...)` to equal the runner's output byte for byte. A live `derive --rule max` over the fetched training runs reproduced cb833068…b187.
- New self-test cases:
  - `ratio_of` rejects an empty partition, a zero cost and no partitions;
  - with a fake root and fake runner, the live lane file's bytes and mtime are unchanged and no copy artifacts are left in the live tree;
  - raw weights come from the copy;
  - an identical candidate predicts the same, while a distinct candidate changes raw weights, costs and the reported weights sha256.
- Real `predict` output is identical before and after the refactor for all three lanes: min 1.00011, current 1.000017, latest 1.000046, with the same costs. `predict --weights` left `test/partition_weights_min.txt` byte- and mtime-unchanged, and `git status --porcelain test/` was empty.
- Disposition changes:
  - R3-WR-01..04 and R3-IN-03 are `fixed`, with SHAs.
  - R3-IN-05 is `planned (247-32)`.
  - R3-IN-01/02/04/06/07 are `deferred`, each with a reason.
  - Frontmatter `open: 2` (WR-04 open, R3-IN-05 planned).
  - The R3 rows that sat after the closing paragraph are moved back into the table.
  - The closing paragraph now states CI-02 PASS, CI-03 current-lane MISS and 3/4.

## R3-WR-01 observation (not a gate)

After the retention files finished on the ephemeral DB (`threadline_test`), `threadline_retention_runs` existed in the `threadline` and `audit` schemas. `SELECT status, count(*) … GROUP BY status` returned no rows in either schema, so no `queued` or `running` row was left behind.

## Deviations from Plan

### Minor adjustments

**1. [Rule 3 - Blocking] Separate TSV roots per lane in the contract test and self-test**
- **Found during:** Task 2 (and Task 1 step 4)
- **Issue:** The plan describes `<tmp>/ing/<run>/min/` and `<tmp>/ing/<run>/current/` under one root. But strict `validate_lane_timings` reads every TSV under the given directory and dies on a wrong-lane header, so one shared root would make every strict ingest fail.
- **Fix:** Each lane gets its own root (`ing-min/<run>/min/`, `ing-current/<run>/current/` in the contract test, and `lane-rule/<lane>/<run>/<lane>/` in the self-test). The assertions are unchanged.
- **Commits:** e9bb16ca, f27d11b9

**2. [Rule 1 - Credo] Nested case extracted**
- **Found during:** Task 2
- **Issue:** `mix verify.credo` flagged nesting depth 3 in the new sandbox builder.
- **Fix:** The per-partition rows moved into `lane_rule_rows/2` clauses.
- **Commit:** f27d11b9

No other deviations. No weight file, lane inventory, threshold or `*_test.exs` set changed. Verified with `git diff --quiet origin/main HEAD -- test/partition_weights*.txt` and with no A/D `*_test.exs` entries.

## Auth gates

None. `gh run download` reached the B4 artifacts, so the Task 1 precondition held.

## Known Stubs

None.

## Next

247-30 (wave 25).

## Self-Check: PASSED

- FOUND: bin/ci-test-partitions (`lane_rule() {` once), test/threadline/ci_topology_contract_test.exs, CONTRIBUTING.md, both retention test modules, tools/min_balance.py (no `def placed`), 247-REVIEW-DISPOSITION.md
- FOUND commits: e9bb16ca, f27d11b9, 5b3e5ab8, 17376b84 (ancestors of HEAD)
- Ephemeral postgres:16 `tl-247-29` stopped (started with --rm); no background shells left
