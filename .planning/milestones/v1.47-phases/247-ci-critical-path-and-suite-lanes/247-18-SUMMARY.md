---
phase: 247-ci-critical-path-and-suite-lanes
plan: 18
subsystem: ci
status: complete
tags: [exact-head, main-landing, gnu-awk, gap-closure]
requires:
  - phase: 247-16
    provides: Duration-floor assignment and B3-derived weights
  - phase: 247-17
    provides: Proved motion-fixture focus synchronization
provides:
  - Exact local and hosted green candidate landed through guarded PR 97
  - GNU awk scalar-argument portability correction
  - Verified main squash and sole required-context readback
affects: [247-19, 247-verification]
key-files:
  created: []
  modified: [bin/ci-test-partitions, .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md]
requirements-completed: []
requirements-implemented: [CI-01, CI-02, CI-03, CI-04]
coverage:
  - id: checked-main-landing
    description: Only the exact green candidate crossed the protected-main boundary
    verification:
      - {kind: integration, ref: 'CI=true mix ci.all on 4ff7af65; PR run 40448573344; main run 40449332597; guarded PR 97 squash and source-tree equality', status: pass}
    human_judgment: false
  - id: gnu-awk-portability
    description: Empty group sums reach the cost helper as scalar numeric values on both awk implementations
    verification:
      - {kind: integration, ref: 'GNU awk 5.2.1 and Bash 5.2/3.2 runner self-tests; 45 focused contracts; three-lane assignment/model parity', status: pass}
    human_judgment: false
actuals: {tokens: 9000, tasks: 2, commits: 4}
completed: 2026-10-27
---

# Phase 247 Plan 18 Summary

**PR #97 landed the exact green duration-floor and motion-fixture candidate as protected-main squash 02d115a3. Numeric acceptance remains with Plan 19.**

## Exact identity

- Tested land HEAD and merged PR head: 4ff7af655315a927eb5a62e14cb2abc7e72d4ab8.
- PR: https://github.com/szTheory/threadline/pull/97.
- Hosted successful attempt-1 run: 40448573344, all 17 jobs green.
- Main squash: 02d115a32e4479f353d284c04fc838ba58938d16.
- Automatic main push: 40449332597, successful attempt 1 before optional dispatches.
- Guarded squash used `--match-head-commit`; GitHub merged state/head/mergeCommit, fetched main and tested/non-planning tree equality all agree. Sole required context remains CI required@15368 and is emitted on the new head, without stacked classic protection.

## Gate evidence

On final land HEAD, complete `CI=true mix ci.all` exited 0: 32 properties, 3382 root tests, zero failures, 3 configured exclusions; 132 example tests, zero failures; Dialyzer zero errors; live slice 17/0; desktop/mobile 418 passes and 56 configured skips (6.8 min). Both Bash self-tests, hygiene and read-only branch protection passed on that exact head. Final script hash matches the Linux-tested copy.

PR artifacts: all ten named phase artifacts present and unexpired. Two browser timing JSONs each contain correctly ranked top-20 arrays; the receipt reconciles all 31 required journeys across both projects; each of three partition timing families has four correctly labelled TSVs. All three Build and test jobs, both browser legs, receipt and CI required passed. Full local scope, job IDs, watchdog, warning-only ratio and 1.15/540 s limits are unchanged.

## GNU awk correction and retained failures

Initial local head 0e313435 passed the complete Mac gate but hosted run 40446515239 failed all three unconditional self-tests with GNU awk 5.2.1 `Node_array_tree` at a cost helper call. This run remains failed and was never retried.

A disposable Linux container reproduced the original self-test failure immediately, minimized to one sync file. Only explicit scalar numeric conversion of unset group arguments fixed that loop; coercing only the ternary result or passing the omitted scratch argument did not. Source f81f859c (land 4ff7af65) forces numeric helper inputs. Original full GNU awk self-test, both Mac Bash variants, 45 focused contracts and the corrected exact-head full gate all passed. B3 fit and actual new assignments are numerically identical on every lane. Independent reviewer found no issues. Existing unconditional Linux self-test is the real regression seam; no new dependency or weakened assertion.

The initial local setup/process corrections and caught checkout mix-up are documented in LANDING. Both accidental/failed process trees ended before the valid isolated runs; exact-SHA, explicit-checkout, clean-status and tree proofs guard the credited receipts. Initial post-merge branch readback correctly found the check had not yet been emitted; after automatic main success it passed without settings changes.

## Task commits

- Task 1 exact-head proofs: 943236b8, c5a038c3; portability source correction: f81f859c.
- Task 2 PR/main provenance and readback: see the reachable `docs(247-18): verify PR 97 squash and first green main run` commit.

## Deviations

Auto-fixed the hosted GNU awk portability bug inside the approved assignment boundary, then repeated the entire amended-head gate before push. This adds only numeric coercions to the runner; model, weight data and scope are unchanged. Initial environment/prerequisite corrections and interrupted local runs are retained honestly in LANDING. No Hex publication, old-workflow retry or main sampling threshold change.

## Self-Check: PASSED

Both modified paths and all five standalone B4 identity lines exist; plan-scoped commits are reachable; GitHub/main/tree checks, artifact validation and final protection readback passed. Phase completion and numeric CI-03 acceptance are not inferred from local or PR predictions.
