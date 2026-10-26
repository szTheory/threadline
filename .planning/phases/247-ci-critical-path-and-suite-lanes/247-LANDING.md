# Phase 247 landing log

Evidence for the D-02 landing sequence. Each land gets its own section. 247-01 writes
`## Land A1`; later plans append `## Land A2`, `## Land B1` and `## Land B2`.

## Land A1

Pre-removal v1.47 work (Phases 244 and 245, plus the 245 review fixes) as one
non-releasable `ci:` squash (D-01, D-02 step 1, D-03).

| Field | Value |
|-------|-------|
| Land branch | `land/v1.47-a1` (local; temporary worktree `${TMPDIR}/threadline-land-247-a1`) |
| origin/main at cut | `23178fb0c4b9b302e3b4d5186f8d49d12a2c53a6` |
| Merge base (origin/main, milestone/v1.47) | `23178fb0c4b9b302e3b4d5186f8d49d12a2c53a6` (main has not moved) |
| Pick range | `git log --reverse origin/main..4b2c3f89^ -- . ':!.planning'` |
| Picked commits | 47 (first `74d631a5`, last `03dc8320`) |
| Planning sync commit | 1 (`docs(planning): sync v1.47 planning through phase 247 planning`) |
| Land branch commits over origin/main | 48 |
| Land branch head | `eed57370b478ca21ef5c11313a6f47a4528ad8af` |
| `Removal-Slice:` trailers in pick list / on branch | 0 / 0 |

### Tree proof

Main had not moved, so the proof is tree equality rather than a substitute ci.all run:

```
git diff --quiet 4b2c3f89^ HEAD -- . ':!.planning'   # exit 0
git diff --quiet milestone/v1.47 HEAD -- .planning    # exit 0 (planning mirror)
```

### Hygiene

`bin/verify-repo-hygiene` in the land worktree: exit 0
(`5005 tracked text file(s) clean; 8 allowlist entries used, 0 inert`).

### CHANGELOG finding

`git diff origin/main HEAD -- CHANGELOG.md` changes only the maintainer-facing HTML
comment at the top of the file (one sentence: the release workflow, not release-please,
renames the Unreleased block on the release branch). `## Unreleased — highlights` still
reads `_Nothing yet for the next release._`. There is no adopter-facing entry, so the
`ci:` subject strands nothing (D-03, RESEARCH Open Question 1).

### Deviations while building the branch

1. **Mixed commit `b2b152a1` picked path-scoped.** `feat(245-01): four-class
   self-closing deps-health lane` touches code plus `.planning/REQUIREMENTS.md` and
   `.planning/ROADMAP.md`. A plain `git cherry-pick -x` conflicted only on those two
   planning paths (`DU`/`UU`), because main's planning files predate v1.47. The pick
   was aborted, not hand-resolved. The commit's non-planning diff was then applied
   verbatim (`git show b2b152a1 -- . ':!.planning' | git apply --index`) with the
   original author, date and message plus a `cherry picked from` line, as land commit
   `129881f1`. The dropped planning hunks are carried by the planning sync commit. The
   tree proof above confirms the result equals the milestone tree outside `.planning`.
2. **Planning sync also mirrors deletions.** `git checkout milestone/v1.47 -- .planning`
   adds and updates files but does not remove them. On milestone/v1.47 the v1.44 and
   v1.45 phase directories (224 through 237, 349 files) were moved into
   `.planning/milestones/v1.44-phases/` and `v1.45-phases/`. Before removing the old
   copies from the land branch, each one was checked to exist in the archive: 348
   byte-identical, 0 missing, and 1 that differs only by a later v1.47 edit in the
   archive (`231-REVIEW-DISPOSITION.md`, WR-01 `open` → `fixed`, from `e29e6c5f`). The sync commit therefore makes
   `.planning` on the land branch identical to milestone/v1.47, with no duplicate
   phase directories.
