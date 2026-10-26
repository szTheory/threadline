---
phase: 247-ci-critical-path-and-suite-lanes
plan: 02
subsystem: release
tags: [landing, squash-merge, cherry-pick, archive-tag, git]
status: complete

requires:
  - "247-01 Land A1 (A1 squash fea5250b on origin/main)"
provides:
  - "Land A2: the 246 critic removal (nine Removal-Slice commits C1..C8) on origin/main as its own non-releasable squash 9f69a904cf99f7691d50754785d42d8feef1162c, `chore: retire the UI critic loop (DEBT-02)` (PR #93)"
  - "Local annotated tag archive/ui-critic-loop on the squash parent fea5250bf91a582754e82c57ec9196077e4e6c00 (push handed to the maintainer)"
  - "ARCHIVE-REGISTER row archive/ui-critic-loop, Rows: 12"
  - "247-LANDING.md `## Land A2` evidence: readiness, picks, corrected slice proof, PR, run, squash, tag, D-14"
affects: [247-03, 247-08, "CI-02 split on the post-removal suite", "CI-02/CI-03 measured gates", "Land B (46efd9d4 lands there)"]

actuals:
  tokens: 1956
  tasks: 3
  commits: 2   # the two 247-02 commits; rev-list over the ledger range is 21 because plans 247-04..07 and 247-09 committed in between
plan_head_before: 423ffdf9bbc2d5e36f2113050648429ef21f109f
plan_head_after: 0a2c8cc0a34e81301bb2d8ae4163a2f06b051904

tech-stack:
  added: []
  patterns:
    - "Slice proof by patch-id: when a non-slice commit edits a slice path, prove the residual `git diff <last-slice> HEAD -- $paths` equals that commit reversed (`git patch-id --stable`), rather than editing slices to make a literal tree-equality pass"
    - "Archive tag on `$SQUASH^` on origin/main, never on a milestone commit; message built from the 246-LANDING D-31 template with the real diffstat"

key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-02-SUMMARY.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
    - .planning/ARCHIVE-REGISTER.md

key-decisions:
  - "247-02: the literal slice proof `git diff --quiet e9a97139 HEAD -- $paths` cannot exit 0 while 46efd9d4 (a 246-05 test: commit that edits a slice path) lands after the removal; the accepted proof is patch-id equality of the residual with 46efd9d4 reversed (421fbeb9e0c3749e4ee84a61f1ae05783a859a13), with 46efd9d4 landing in Land B"
  - "247-02: the remote branch land/v1.47-critic-removal is left on origin and the local branch is kept; only the temp land worktree is removed"

metrics:
  duration: "about 6h wall clock, most of it the maintainer push/PR/merge checkpoint"
  completed: 2026-10-26
---

# Phase 247 Plan 02: Land A2 Summary

**The 246 UI critic removal is on origin/main as the single revertable, non-releasable squash `9f69a904` ("chore: retire the UI critic loop (DEBT-02)", PR #93, green run 40375604860). The local annotated tag `archive/ui-critic-loop` pins its parent `fea5250b`, the register has the row, and the tag push is handed to the maintainer.**

## Performance

- **Started:** 2026-10-26 (Task 1 commit 98fba89f at 12:32 local)
- **Completed:** 2026-10-26
- **Tasks:** 3 (Task 2 was the maintainer checkpoint)
- **Files modified:** 2 (+ this SUMMARY)

## Accomplishments

- Readiness check `git diff --quiet 4b2c3f89^ origin/main -- $paths` exited 0 over the 528-path slice set (0 `.planning/` paths).
- Built `land/v1.47-critic-removal` from the A1 squash with nine named cherry-picks and no conflicts: 9 commits, 9 `Removal-Slice:` trailers, head `c3babc69`.
- The maintainer pushed the branch, opened PR #93 and squash-merged it at 2026-10-26T18:36:24Z after all 15 checks went green (`CI required` passed). The squash tree equals the land head (`git diff --quiet 9f69a904 c3babc69` exit 0).
- Created the annotated tag `archive/ui-critic-loop` locally on `fea5250b`. Its message follows the D-31 shape and the hygiene grep printed nothing.
- D-14 local checks: the tag tree has 5 `lib/threadline/critic_trust/` paths, and the tag is an ancestor of origin/main (exit 0). `git ls-remote` for the tag is empty, as expected before the push.
- Added the ARCHIVE-REGISTER row and changed the count to `**Rows: 12.**`. Removed the temp land worktree.

## Task Commits

1. **Task 1: readiness, nine named picks, slice proof** - `98fba89f` (docs). Recorded HALTED at the literal slice proof.
2. **Task 2: maintainer push / PR / squash-merge** - no commit (maintainer; PR #93, squash `9f69a904` on main).
3. **Task 3: archive tag, register row, D-14, hand-off** - `0a2c8cc0` (docs).

## Files Created/Modified

- `.planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md` - `## Land A2`: status LANDED, corrected slice proof, merge table, archive tag, D-14 results, maintainer hand-off.
- `.planning/ARCHIVE-REGISTER.md` - `archive/ui-critic-loop` row, Rows 11 → 12.

## Decisions Made

See key-decisions. The maintainer chose the slice-proof correction (Option 1). The executor did not choose it.

## Deviations from Plan

### Checkpoint-resolved

**1. [Rule 4 - decision] The literal slice proof replaced by a patch-id proof**
- **Found during:** Task 1
- **Issue:** `git diff --quiet e9a97139 HEAD -- $paths` exited 1 on `test/threadline/ci_workflow_parity_contract_test.exs` only. The difference is `46efd9d4`, a 246-05 `test:` commit between C5 and C6. It is not a slice, and it lands later with Land B (246-LANDING step 2.3).
- **Resolution:** The maintainer accepted Option 1, and the orchestrator re-verified it. The residual's patch-id equals the patch-id of `46efd9d4` reversed: both are `421fbeb9e0c3749e4ee84a61f1ae05783a859a13`. No slice was changed.
- **Commit:** `98fba89f` (halt record), `0a2c8cc0` (accepted proof)

### Other notes

- The tag message scratch file went to the session scratchpad instead of `${TMPDIR}`. It is uncommitted either way.
- `commits:` counts the two 247-02 commits. A raw `git rev-list --count` over the ledger range gives 21, because sequential plans 247-04..07 and 247-09 committed between Task 1 and Task 3.

## Issues Encountered

None after the checkpoint.

## User Setup Required

**Maintainer hand-off (non-blocking, 246 D-13).** Push the one tag ref, and never use the flag that pushes all tags:

```
! git push origin refs/tags/archive/ui-critic-loop
```

Then check that `git ls-remote origin refs/tags/archive/ui-critic-loop` prints one line. The remote branch `land/v1.47-critic-removal` is still on origin. Deleting it is the maintainer's call; this plan did not delete it.

## Next Phase Readiness

main now has the post-removal suite and Playwright project set, so the CI-02 split and the CI-02/CI-03 measured gates can run against it. Land B still has to carry `46efd9d4` and the rest of the v1.47 commits.

## Self-Check: PASSED

- FOUND: 247-LANDING.md `## Land A2` with `git push origin refs/tags/archive/ui-critic-loop`
- FOUND: ARCHIVE-REGISTER.md `archive/ui-critic-loop` row and `**Rows: 12.**`
- FOUND: commits 98fba89f, 0a2c8cc0 (ancestors of HEAD)
- FOUND: tag `archive/ui-critic-loop` (type `tag`, `^{commit}` = fea5250b), ancestor of origin/main
- FOUND: squash 9f69a904 is an ancestor of origin/main
