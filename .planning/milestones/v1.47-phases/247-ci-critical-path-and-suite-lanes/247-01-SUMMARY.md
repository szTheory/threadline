---
phase: 247-ci-critical-path-and-suite-lanes
plan: 01
subsystem: release
tags: [landing, squash-merge, cherry-pick, ci, git]
status: complete

requires: []
provides:
  - "Land A1: v1.47 Phases 244 + 245 (and the 245 review fixes) on origin/main as one non-releasable `ci:` squash, fea5250bf91a582754e82c57ec9196077e4e6c00"
  - "247-LANDING.md `## Land A1` evidence (branch, picks, tree proof, hygiene, CHANGELOG finding, PR #91, run 40354035917, squash SHA)"
affects: [247-02, "Land A2", "246-LANDING readiness check", "D-01 main-measured gates"]

actuals:
  tokens: 1126
  tasks: 3
  commits: 2
plan_head_before: 186d2c2786f602743e08d3c3f7b33632a8e8c481
plan_head_after: 92b0037b01bbdc6e396acfa851f4e73228ff6f77

tech-stack:
  added: []
  patterns:
    - "Land branch from origin/main: in-order `cherry-pick -x` of pre-C1 non-planning commits plus one `docs(planning): sync` commit that mirrors milestone `.planning` exactly, deletions included"
    - "Tree proof `git diff --quiet 4b2c3f89^ HEAD -- . ':!.planning'` in place of a full ci.all when main has not moved"

key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
  modified: []

key-decisions:
  - "247-01: a mixed code+planning commit (b2b152a1) that conflicts only on planning paths is applied path-scoped (`git show <sha> -- . ':!.planning' | git apply --index`) with original authorship, and the planning hunks travel in the sync commit; the tree proof backs the result"
  - "247-01: the planning sync removes the old v1.44/v1.45 phase directories after checking every file exists in the milestone archive, so main gets no duplicate phase dirs"
  - "247-01: the CHANGELOG diff touches only the maintainer-facing header comment, so the `ci:` subject strands no adopter-facing entry (D-03)"

metrics:
  duration: "about 2h wall clock, including the maintainer push/PR/merge checkpoint"
  completed: 2026-10-26
---

# Phase 247 Plan 01: Land A1 Summary

**v1.47 Phases 244 and 245 landed on origin/main as the non-releasable squash `fea5250b` ("ci: land v1.47 release flow and supply chain (244, 245)", PR #91). The squash tree is identical to a land branch that was proven tree-equal to the pre-C1 milestone tree.**

## What happened

- **Task 1 (tracer, `5be267f5`):** cut `land/v1.47-a1` from origin/main `23178fb0`, which was still the merge base. Cherry-picked the 47 non-planning commits older than C1 `4b2c3f89` (no `Removal-Slice:` trailers) and added one planning sync commit, giving land head `eed57370`. The tree proof exited 0, `bin/verify-repo-hygiene` exited 0 and the CHANGELOG check came back clean. The evidence and PR body were written.
- **Task 2 (checkpoint:human-action):** the maintainer pushed the branch and opened PR #91. All 16 checks were green, including `CI required`. The maintainer squash-merged at 2026-10-26T16:26:45Z.
- **Task 3 (`92b0037b`):** recorded the merge in `## Land A1`. That covers PR #91, green ci.yml run `40354035917` on head `eed57370`, and squash `fea5250bf91a582754e82c57ec9196077e4e6c00` with parent `23178fb0`. `git diff --quiet fea5250b eed57370` exits 0. The temporary land worktree is removed and the local branch is kept. No 247-01 postgres container was ever started.

## Remote branch

`git ls-remote --heads origin land/v1.47-a1` returns nothing, so the remote branch is already gone, likely through GitHub's delete-on-merge. The local branch shows `[gone]` tracking. Nothing was deleted by the executor.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Path-scoped pick of mixed commit `b2b152a1`**
- **Found during:** Task 1
- **Issue:** a plain cherry-pick conflicted only on `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`, because main's planning files predate v1.47.
- **Fix:** aborted the pick without hand-resolving it, then applied the commit's non-planning diff verbatim with the original metadata as land commit `129881f1`. The planning hunks travel in the sync commit. The tree proof confirms the result.
- **Commit:** recorded in `5be267f5` (247-LANDING.md)

**2. [Rule 1 - Bug] Planning sync must mirror deletions**
- **Found during:** Task 1
- **Issue:** `git checkout milestone/v1.47 -- .planning` does not remove files. The v1.44/v1.45 phase directories moved to `.planning/milestones/` would have been duplicated on main.
- **Fix:** each of the 349 old copies was checked against the archive (348 byte-identical, 1 newer in the archive), then removed on the land branch. Land `.planning` equals milestone/v1.47.
- **Commit:** recorded in `5be267f5`

**3. [Rule 1 - Verify mismatch] Row label for the Task 3 grep**
- **Found during:** Task 3
- **Issue:** the plan's `grep -Eq 'squash.*[0-9a-f]{40}'` is case-sensitive, and the first row label was "Squash on origin/main".
- **Fix:** relabeled the row "A1 squash SHA on origin/main". The verify passes.
- **Commit:** `92b0037b`

## Known Stubs

None.

## Next

247-02 (the critic-removal squash, Land A2) can now run the 246-LANDING readiness check against origin/main `fea5250b`.

## Self-Check: PASSED

- FOUND: .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
- FOUND: 5be267f5, 92b0037b (ancestors of HEAD)
- FOUND: fea5250b on origin/main with subject `ci: land v1.47 release flow and supply chain (244, 245)`
