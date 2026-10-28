---
phase: 247-ci-critical-path-and-suite-lanes
plan: 26
subsystem: test-fixtures
status: complete
tags: [ci, min-lane, fixtures, flake, retention, exports, gap-closure]
requires: ["247-25"]
provides:
  - "247-MIN-FIXTURE-AUDIT.md (schema threadline.phase247-min-fixture-audit/1): exact B4 replays, negative controls, A/B/C searches, sweep, masking review, gates"
  - "CR-05 closed-by-descoping in 247-REVIEW-DISPOSITION.md (open 2 -> 1)"
  - "RetentionHistoryLiveTest Pruner workers owned by a test Task.Supervisor (sibling of the B4 P3 FK race)"
affects: ["247-27", "247-28"]
tech-stack:
  added: []
  patterns:
    - "Test-owned Task.Supervisor injected into the Pruner task_start seam, with an advisory-lock-held ownership assertion as the red-capable regression"
    - "Scratch-only ExUnit formatter probe listing live Task processes at :test_finished to find product-started workers that outlive a test"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-MIN-FIXTURE-AUDIT.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW-DISPOSITION.md
    - test/threadline/operator_surface/live/retention_history_live_test.exs
decisions:
  - "RetentionHistoryLiveTest's Pruner workers are a confirmed class A sibling of the B4 P3 FK race; fixed in test code only (no lib/ change)"
  - "Classes B and C have no new hazard; the 136bb932 export group is the only cross-partition writer of priv/threadline_exports"
  - "D-26: CR-05 closed-by-descoping; no canary run, canary tools byte-unchanged"
  - "CI-02/CI-03 not marked complete: this plan protects the cohort, but the measured gates belong to Plans 27-28"
metrics:
  duration: 35min
  completed: 2026-10-28
  tasks: 2
  files: 3
estimate:
  tokens: 20000
actuals:
  tokens: 17895
  tasks: 2
  commits: 5
plan_head_before: 6c5dc51441c9dde44b9647d6b12e7729226f040b
plan_head_after: f8b11d856ff949860007eb1e4a9a90b183ee6cbb
---

# Phase 247 Plan 26: Min-lane fixture audit and CR-05 descoping Summary

Both B4 min-lane failures were replayed green on their exact partition file lists and seeds. The replays ran on Elixir 1.15.8 / OTP 26.2.5.21 against an ephemeral PostgreSQL 15. Each fix has a mutation control: red when the fix is reverted, green when restored. A three-class sibling sweep found and fixed one more Pruner-worker race, in RetentionHistoryLiveTest, using test code only. CR-05 is closed by descoping (D-26).

## What was done

**Task 1 (dfdbc2cc).** The failed runs' own `partition-<i>.files` were downloaded from the `partition-logs-min-*` artifacts:
- 40452150109 P3: 31 files, sha256 `b463e6de…`.
- 40452833440 P1: 36 files, sha256 `2bb15856…`.

Each failing test and seed was confirmed in the ANSI-stripped logs. The scratch source was a `git archive` of HEAD. It ran in the cached min image (arm64) on a private Docker network with postgres:15 (15.18).

| Replay | Result |
|---|---|
| P3, seed 675682 | 397 tests, 0 failures, 1 excluded. Same counts as CI. |
| P1, seed 856063 | 532 tests, 0 failures. Same count as CI. |
| Export group + topology, seed 856063 | 81 tests, 0 failures |
| Control (i): pruner `task_start` reverted to `Task.start` | 9 tests, 1 failure ("the accepted worker must belong to the test supervisor"); restored: 9/0 |
| Control (ii): export colocation line deleted | `:264` red with "export fixture overlap"; restored: 31/0 (30 excluded) |
| Natural reproduction: P3 with pre-fix `pruner_test.exs` (02d115a3), 3 attempts (cap) | All green. The deterministic controls are the oracle. |

D-26: CR-05 is `closed-by-descoping` (frontmatter, title and table row), and `open:` went from 2 to 1. WR-04 is unchanged. No canary ran, and no `tools/exunit_boundary_*` file changed.

**Task 2 (14badb2c RED, d4688d58 GREEN, eed59aa2 comment, f8b11d85 record).**
- **Class A:** the seeded grep found 7 sites, all safe, each with a mechanistic reason. The search was widened by a grep for Pruner starts and by a scratch-only ExUnit formatter. Over the whole default suite on the min toolchain, the formatter listed every live Task at each `:test_finished` event. It found 2 Pruner workers still running queries after `RetentionHistoryLiveTest`'s prune tests, the same mechanism as B4 P3. The fix is a test-owned `Task.Supervisor` injected into the `task_start` seam. RED: the classifier returned `RED_EVIDENCE_OK` on a TAP report from the min toolchain. Mutation control: 30 tests, 1 failure; restored: 30/0. After the fix, the probe found 0 rows across 3384 tests.
- **Class B:**
  - The checkout-root grep produced 114 results in 61 files, each with a verdict.
  - All 335 `File.*` mutation sites were resolved by hand.
  - The export-root writer probe ran 30 candidate files; only the four 136bb932 files write the root.
  - Nested `mix` shell-outs change only `.mix/.mix_test_failures`.
  - No shared `unique_integer` temp prefix collides.
  - The repo-root sentinel is already covered by colocation group 1.
- **Class C:** the async × delete intersection found 10 files. All are safe: prose "truncate" matches or scanner strings. The real deletes are in the `async: false` second module of `storage_schema_prefix_contract_test.exs`. A module-level scan, including deletes reached through test/support helpers, found nothing.
- **Masking review:** the hard gate counts 0 added lines. The 2 removed `assert` lines are 714b4dbb re-indentations. No timing line was added. Five review-only forms were each recorded as checked.
- **Gates (postgres:16):** `mix verify.format` exit 0. `mix verify.credo` exit 0, 0 issues. `mix verify.test` exit 0: 3384 tests, 32 properties, 0 failures, 3 excluded, seed 318628. The min replays after the fix stay green: P3 397/0, P1 533/0 (one more test than CI, from the new regression), export group 81/0.

## TDD Gate Compliance

- RED: commit 14badb2c, `test(247-26): add failing test that retention live prune workers are test-owned`.
  - Evidence: `{command: mix test …retention_history_live_test.exs:721 --seed 675682 (scratch copy, min toolchain, PG15, TAP reporter), exitCode: 2, targetTest: "…an accepted prune's worker is owned by this test and cannot outlive it"}`.
  - Classifier: `RED_EVIDENCE_OK` / `target_test_failed`.
  - semanticAssessment: the target executed (1 of 30; 29 excluded by the line filter). It failed on its planned ownership assertion while the advisory lock kept the worker alive. There was no compile, fixture or setup fault.
- GREEN: commit d4688d58. The target now passes, and the whole file passes 30/0 on both toolchains.
- REFACTOR: none. eed59aa2 only rewords a comment.
- The commit subjects use `test(247-26)` for both RED and GREEN, as the plan requires (`test:` subjects for test-code fixes).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Sibling Pruner worker race in RetentionHistoryLiveTest**
- **Found during:** Task 2, class A widened search (outlive probe)
- **Issue:** `start_supervised` Pruner kept its default unlinked `Task.start` seam. An accepted prune's worker outlived its test and was still running its orphan sweep.
- **Fix:** a test-owned `Task.Supervisor` replaces the `task_start` seam, plus a lock-held ownership regression inside the existing file. No new `*_test.exs` was added.
- **Files modified:** `test/threadline/operator_surface/live/retention_history_live_test.exs`. The plan's `files_modified` did not list it; it was added under the plan's "fix every confirmed hazard in test code" instruction.
- **Commits:** 14badb2c, d4688d58, eed59aa2

**2. [Rule 3 - Blocking] The masking gate tripped on comment prose**
- **Found during:** the Task 2 masking review
- **Issue:** the regression comment used the word "retries", which the hard `\bretr(y|ies)\b` gate matches.
- **Fix:** reworded to "waits for it" in a separate commit. No behaviour change, and the gate is unchanged.
- **Commit:** eed59aa2

**3. [Process] Searches widened beyond the seed greps**
- The class A greps cannot see product-started workers, so a runtime probe was added. That probe is how deviation 1 was found.
- Class B added an export-root probe, a nested-mix `_build` check and a temp-prefix collision check.
- Class C added a module-level scan.
- All widenings are recorded with their commands in `searches[].widenings`.

**4. [Process] Container lifecycle**
- The min and postgres:15 containers were kept from the end of Task 1 until after Task 2, instead of being removed right after the Task 1 commit. Task 2 changed a test file, which required re-running the Task 1 replays.
- Every container labelled `dev.threadline.plan=247-26`, and the scratch network, was removed after both verifies passed. `docker ps -aq --filter label=dev.threadline.plan=247-26` is empty.

**5. [Process] Requirements not marked complete**
- CI-02 and CI-03 stay open. This plan removes flake mechanisms but does not measure either gate; that is Plans 27–28.

## Known Stubs

None.

## Threat Flags

None. All changes are test code and planning records.

## Self-Check: PASSED

- FOUND: .planning/phases/247-ci-critical-path-and-suite-lanes/247-MIN-FIXTURE-AUDIT.md
- FOUND: .planning/phases/247-ci-critical-path-and-suite-lanes/247-REVIEW-DISPOSITION.md
- FOUND: test/threadline/operator_surface/live/retention_history_live_test.exs
- FOUND commits: dfdbc2cc, 14badb2c, d4688d58, eed59aa2, f8b11d85 (all ancestors of HEAD)
- Both plan `<verify>` blocks passed at f8b11d85, and `git status --short -- test/ lib/` is empty.
