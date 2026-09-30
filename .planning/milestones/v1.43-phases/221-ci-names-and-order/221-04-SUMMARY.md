---
phase: 221-ci-names-and-order
plan: 04
status: complete
subsystem: ci-landing
tags: [ci, landing, measurement]
requires:
  - "221-01..03: gate contract, order contract + move, one-pass rename"
provides:
  - "Phase 221 (plus 220 follow-ups and 3 flake fixes) on main via squash PR #63 (67572c12)"
  - "time-to-red.py era boundary: RENAME_SHA, ERA_BOUNDARY_RUN, MAIN_MERGE_SHA"
affects: [222]
key-files:
  created:
    - .planning/phases/221-ci-names-and-order/221-04-SUMMARY.md
  modified:
    - .planning/phases/221-ci-names-and-order/tools/time-to-red.py
decisions:
  - "The PR run started on its own, so no workflow_dispatch was used"
  - "MAIN_MERGE_SHA was set right after the merge, not deferred to the next planning sync, because the value was known"
metrics:
  commits: 3
---

# Phase 221 Plan 04: Landing Summary

Phase 221 landed on main as squash PR #63 (merge commit `67572c12d9fa6b312578a0a2a1cdde017ff5c433`). The PR CI run posted exactly the 16 expected check names, all green, including `CI required`.

## Task 1: gate and land branch (executor)
- The NAME_HISTORY post-221 names were committed as `6b3b5fcc`, with a collision/orphan self-check that the `order` and `check` commands run.
- `mix ci.all` on milestone/v1.43 passed first try: 2515 tests, 0 failures; the Playwright CI lane was 318 passed, 26 skipped.
- `land/v1.43-221` was cut from origin/main `3c4ac9b1` and holds 10 cherry-picks with no conflicts: d7d44fd1, 2099d17b, 9ebd6af5, 997ad1d0, c005baa8, a8a53c3f, 7ebb66ad, c72e13a7, 24b7a2b2 and 194eee6a, plus the planning sync `3ed3238f`.
- The land-vs-milestone diff outside `.planning` was exactly the six release files. `.planning` was identical, and repo hygiene was clean.

## Task 2: push, PR, check, merge (orchestrator, under the maintainer's grant)
- The maintainer granted it on 2026-09-29: "yeah i can push pr all that and squash merge if/when ci green".
- Pushed `land/v1.43-221` at `3ed3238f` and opened PR #63.
- **ERA_BOUNDARY_RUN = 36586103573.** This is the PR run; its headSha equals the pushed tip. The conclusion was success, with 16 of 16 jobs green.
- The sorted list of posted names equals the expected list: `true`.
- **RENAME_SHA = 327165f038d5a0c601cbbe996f9a47cacfdcfe13.** This is the land-branch SHA of the rename commit.
- **MAIN_MERGE_SHA = 67572c12d9fa6b312578a0a2a1cdde017ff5c433.**
- Squash-merged with the remote branch deleted. The /tmp land worktree was already gone, and was pruned.

## Deviations
- MAIN_MERGE_SHA was set in this plan rather than left as a follow-up, because the merge happened in the same session.

## Self-Check: PASSED
- `time-to-red.py check` prints "time-to-red order matches".
- `bin/verify-repo-hygiene` is clean.
