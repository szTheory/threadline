---
phase: 247-ci-critical-path-and-suite-lanes
plan: 27
subsystem: ci-partitioning
status: complete
tags: [ci, min-lane, partition-weights, pre-registration, gap-closure, CI-03]
requires: ["247-26"]
provides:
  - "test/partition_weights_min.txt: candidate B (per-file max over B4 main runs 40449332597, 40450141708, 40450801580), sha256 cb833068ef4eec9a8896edea1e4ae405b11bb1d7a5e1515724850fc5b663b187"
  - "tools/min_balance.py: hash-verified fetch, derive --rule max, predict (production assignment), replay (per-run observed walls), --self-test"
  - "247-B5-WEIGHTS.md (schema threadline.phase247-b5-weights/1): pre-registration reference, both candidates, R3 selection, five replays, ci03_expectation EXPECTED_MISS (advisory), async_flips, D-11 follow-up, local run receipts"
affects: ["247-28"]
tech-stack:
  added: []
  patterns:
    - "Pre-registered, training-only candidate selection with an explicit selection-record commit before any holdout replay"
    - "Prediction through the production runner itself (MIX_BIN=false stops at the serial compile), cross-checked against its printed per-partition weights"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/min_balance.py
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B5-WEIGHTS.md
  modified:
    - test/partition_weights_min.txt
    - .planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md
decisions:
  - "R3 selected candidate B (per-file max): both eligible (A 1.000071, B 1.00011 predicted); worst training spread A 1.348 vs B 1.161"
  - "R5 ci03_expectation = EXPECTED_MISS (advisory): worst spread over five observations 1.273 on B4 holdout 40451533079, dominated by deps_audit_gate_test.exs; Plan 28 runs the cohort regardless"
  - "Follow-up if CI-03 misses: the D-11 split of test/threadline/deps_audit_gate_test.exs into two module files (named, not implemented)"
  - "CI-03 not marked complete: it is decided only by Plan 28's measured main ratios (D-24)"
metrics:
  duration: 17min
  completed: 2026-10-28
  tasks: 3
  files: 4
estimate:
  tokens: 24000
actuals:
  tokens: 13100
  tasks: 3
  commits: 4
plan_head_before: 18f9ac33a40be87539390469f4f680defd98bbc3
plan_head_after: c407918b3d5c53ca2de9ace549ea93ee7a302a1f
---

# Phase 247 Plan 27: B5 min-lane weights (D-25(b)) Summary

The min-lane weights are now re-derived from the three hash-verified B4 main runs. A pre-registered rule, applied to training runs only, chose candidate B (the per-file maximum). It predicts a 1.00011 ratio at N=4. The advisory `ci03_expectation` is EXPECTED_MISS: holdout 40451533079 replays at 1.273, with `deps_audit_gate_test.exs` as its async floor. All five local partitioned runs are green, including one on the exact min toolchain against postgres:15.

## What was done

**Task 1 (3b510219), tracer.** `pre_registration_commit` is 425a3965, the last commit that touched `247-27-PLAN.md` before any number. It contains the R1–R5 block unchanged.

`tools/min_balance.py` is stdlib-only and runs under `python3 -I`. Its parts:
- `fetch` verified all 20 min TSVs (12 training, 8 holdout) against `247-FROZEN-REPLAY.json`, whose own sha256 is pinned.
- `predict` runs the production runner with `MIX_BIN=false`. It recomputes S/A/L/D and the cost per partition. It also checks every file's effective weight, and every partition's file count and weight sum, against the runner's own output.

Before any change, the existing min weights predicted 1.000015, which reproduces Plan 16's figure. Strict ingest produced candidate A, which predicts 1.000071. The tracer gate re-ran the Task 1 verify end to end before expansion: the self-tests, the hash fetch, the unchanged-files check, the predict, the runner `--self-test`, and the topology and scope contracts (46 tests, 0 failures on postgres:16).

**Task 2 (8ef4b801, b46d935c).** Training replays, made before any selection:

| Candidate | Predicted | Eligible | …597 / …708 / …580 | Worst |
|---|---|---|---|---|
| A (median) | 1.000071 | yes | 1.281 / 1.180 / 1.348 | 1.348 |
| B (per-file max) | 1.00011 | yes | 1.054 / 1.032 / 1.161 | 1.161 |

R3 selects B. The selection-record commit 8ef4b801 (`selected_weights_commit`) also commits B as `test/partition_weights_min.txt`. After that commit, the holdouts were replayed once:
- 40451533079: 1.273
- 40504321590: 1.044

Over the five observations, the worst spread is 1.273. The predicted ratios are min 1.00011, current 1.000017 and latest 1.000046, so R5 gives **EXPECTED_MISS**. This is advisory only. These numbers match the checker's scratch replay exactly.

The record also holds:
- `async_flips` = [`test/threadline/storage/local_test.exs` async→sync], derived from the git diff;
- `dominating_files`, led by `deps_audit_gate_test.exs` and `public_surface_contract_test.exs`;
- the D-11 `follow_up`.

The plan's Task 2 verify passes. It regenerates both candidates in a `git archive` copy, reproduces their hashes, spreads and predictions, recomputes R3 and R5, and checks commit ancestry.

**Task 3 (c407918b).** Five green local runs, all exit 0 with 0 failures:

| Run | Toolchain | PG | Scope | Tests | Printed ratio |
|---|---|---|---|---|---|
| host-min-1 | Elixir 1.17.3 / OTP 27 | 16 | toolchain | 2564 | 1.29 |
| host-min-2 | Elixir 1.17.3 / OTP 27 | 16 | toolchain | 2564 | 1.30 |
| host-min-3 | Elixir 1.17.3 / OTP 27 | 16 | toolchain | 2564 | 1.23 |
| host-full-1 | Elixir 1.17.3 / OTP 27 | 16 | full | 3384 | 1.61 |
| exact-min-1 | Elixir 1.15.8 / OTP 26.2.5.21 (cached hexpm image, gawk 5.2.1) | 15 | toolchain | 2564 | 1.12 |

Local ratios are informational only (arm64 host). All containers labelled `dev.threadline.plan=247-27` and their network were removed.

## Verification

- Task 1 verify passed: the tool's self-test, the 20-TSV hash fetch, the unchanged runner/current/latest/ci.yml check, the min weights differing from origin/main, a four-partition predict, the runner `--self-test`, and both contracts.
- Task 2 verify passed (`b5 selection + expectation: PASS B EXPECTED_MISS 1.273`). It passed again after Task 3.
- Task 3 verify passed (`b5 local runs: PASS EXPECTED_MISS`), and `bin/verify-repo-hygiene` is green.
- `git diff --quiet origin/main HEAD -- test/partition_weights.txt test/partition_weights_latest.txt bin/ci-test-partitions .github/workflows/ci.yml` holds. No 247-27 commit touches `test/partition_colocate.txt`.
- No changes were made to lib/, mix.exs, mix.lock, .github/ or bin/. There was no CI dispatch, push or merge.

## Deviations from Plan

**1. [Rule 3 - Blocking, environmental] Discarded one host min-scope invocation run with a non-normalized TMPDIR**
- **Found during:** Task 3 (a), first attempt.
- **Issue:** I had exported `TMPDIR` as a scratch path containing `..`. Four path-equality assertions failed because they compared `a/../b` with `b`: `source_family_test.exs:24` and `:40`, and `deps_audit_gate_test.exs:279` and `:1151`. This was an invocation artifact, not a defect in the new mix.
- **Fix:** No code change. I restarted the whole (a)–(c) sequence from the first host run with the default `TMPDIR`, and all five runs were green. The discarded run is disclosed in the record's prose and not counted. The test-side fragility (no `Path.expand`) is logged in `deferred-items.md`.
- **Commit:** none; disclosed in c407918b.

**2. [Note] Holdout replay count.** R4's single holdout replay was made once, after 8ef4b801. `dominating_files` was computed from that replay together with the earlier training replay, not from a second replay. Later re-replays happen only inside the plan's own Task 2 verify command, which is a reproduction check and never feeds the selection.

## Known Stubs

None.

## Threat Flags

None. The tool reads GitHub artifacts only through `gh run download` into scratch, and checks each one against pinned hashes (T-247-57).

## Self-Check: PASSED

- FOUND: tools/min_balance.py, 247-B5-WEIGHTS.md, test/partition_weights_min.txt (sha256 cb833068…b187)
- FOUND commits: 3b510219, 8ef4b801, b46d935c, c407918b (all ancestors of HEAD)
