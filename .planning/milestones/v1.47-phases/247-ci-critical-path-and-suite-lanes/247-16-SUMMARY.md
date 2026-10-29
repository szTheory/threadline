---
phase: 247-ci-critical-path-and-suite-lanes
plan: 16
subsystem: ci
status: complete
tags: [partitions, async-duration-floor, measured-weights, gap-closure]
requires:
  - phase: 247-15
    provides: Fixed B3 main timing evidence and numeric miss
provides:
  - Duration-floor-aware deterministic group assignment
  - Three lane weight files regenerated from fixed B3 artifacts
  - Behavioral long-async fixture and production mutation control
affects: [247-18, 247-19, 247-verification]
tech-stack:
  added: []
  patterns: [non-additive-bin-cost, raw-async-duration-floor]
key-files:
  created: []
  modified: [bin/ci-test-partitions, test/threadline/ci_topology_contract_test.exs, test/partition_weights.txt, test/partition_weights_min.txt, test/partition_weights_latest.txt]
requirements-completed: []
requirements-implemented: [CI-03]
coverage:
  - id: duration-floor
    description: Raw async wall bounds group and bin cost without changing output format or inventory
    requirement: CI-03
    verification:
      - {kind: integration, ref: 'bin/ci-test-partitions --self-test (Bash 5.2 and Bash 3.2)', status: pass}
      - {kind: unit, ref: 'mix test test/threadline/ci_topology_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs', status: pass}
    human_judgment: false
  - id: measured-lane-weights
    description: Strict B3 ingestion and exact full/scoped execution
    requirement: CI-03
    verification:
      - {kind: integration, ref: 'mix verify.test_partitioned; THREADLINE_CI_LANE=min THREADLINE_TEST_SCOPE=toolchain mix verify.test_partitioned', status: pass}
    human_judgment: false
actuals: {tokens: 9600, tasks: 2, commits: 3}
duration: 18min
completed: 2026-10-27
---

# Phase 247 Plan 16 Summary

**Bin cost now respects the longest asynchronous file's elapsed duration while preserving measured lane scope, output and hang safeguards.**

## Implementation and provenance

Assignment carries raw wall and async flag internally; group standalone cost determines descending rank, then placement minimizes resulting bin cost, previous cost and partition number. Cost is sync raw sum plus max(floored 292/1000 async raw sum, longest async raw wall). Final output remains partition/path/discounted file weight. The 80,000 ms synthetic async file still prints 23,360 but occupies its own 80,000 ms bin while the short async and sync files share the other bin. Removing the floor changes this real production assignment and fails the mutation control.

GitHub metadata rechecked for fixed B3 runs 40433193088 (push), 40434036118 and 40434884357 (workflow_dispatch): main, successful attempt 1, exact head 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2. Downloaded all nine named partition-timings artifacts, 36 TSVs total, to scratch. Strict lane ingestion used separate roots, each with three distinct runs, four partitions/run and one observation per file/run. Current has 269 sorted positive rows; min/latest each have 206. Zero medians retain the existing 1 ms floor. No run substitution or committed raw artifacts.

## Fixed B3 model check

Evaluated original partition wall minus boot against original per-file assignments with the production async classifier. Longest async file in each lane is `test/threadline/deps_audit_gate_test.exs`.

| Lane | Old RMS s | Floor RMS s | Longest async ms | New predicted bin loads s | Predicted ratio |
|---|---:|---:|---:|---|---:|
| min | 35.693 | 6.963 | 108774 | 133.631 / 133.630 / 133.632 / 133.630 | 1.000015 |
| current | 17.589 | 14.528 | 103863 | 177.083 / 177.083 / 177.081 / 177.080 | 1.000017 |
| latest | 29.264 | 7.108 | 110073 | 130.254 / 130.260 / 130.254 / 130.254 | 1.000046 |

Predictions use the actual production assignment with committed colocation and regenerated medians. Both scoped lanes improve model fit and all predicted ratios remain <=1.15. These are local candidate predictions; the B3 historical MISS is unchanged and CI-03 is still unmet.

## Verification

- RED self-test failed with `long async raw-duration floor must spread work` before implementation.
- Bash 3.2 and explicit `/opt/homebrew/bin/bash` 5.2 self-tests passed, including exact inventory, four-invocation lane routing, atomic interrupted-ingest control and CI-04 hang/TERM/KILL cases.
- Focused topology/scope contracts: 45 tests, 0 failures.
- Full `mix verify.test_partitioned`: 269 files exactly once, 3382 tests, 0 failures; partition seconds 79/97/83/62 (local warning-only ratio 1.56).
- Min/toolchain entrypoint: 206 files exactly once, 2562 tests, 0 failures; seconds 53/66/59/51 (local warning-only ratio 1.29). Full local suite remains whole; these Mac timings are not main acceptance.
- `mix verify.format`, `mix verify.credo` (5692 mods/funs, no issues), and `git diff --check` passed.
- Independent read-only gsd-code-reviewer: no findings; checked formula, ties, mutation, safeguards and all 36 TSVs against regenerated weights.
- Ephemeral loopback postgres:16 container labelled dev.threadline.plan=247-16 removed after all checks.

## Task commits

1. Task 1 RED: a0b678c9; GREEN min tracer: e989ae15.
2. Task 2 current/latest weights and all-lane validation: 94a34440.

## Deviations and issues

The managed sandbox blocks the self-test's process-tree inspection, a full-suite temporary Git worktree fixture and the default npm cache. Repeated those checks with filesystem/process access and `npm_config_cache` in scratch, without changing source. The first full run also detected a HEAD change because the tracer was committed while a checkout-stability test was running; the successful full rerun held HEAD and tracked files fixed throughout. Downloads include two workflow_dispatch events, as the recorded fixed B3 set specifies. Strict ingestion requires lane-specific roots, so scratch copies retain the required run/lane hierarchy. No API, scope, threshold, CI job or process safeguard changed.

## Self-Check: PASSED

All five modified source paths exist, three plan-scoped commits are reachable, both shell self-tests and both real suite scopes passed after the last source change, and model-fit gates passed. This closes plan execution, not CI-03's live numeric gap.
