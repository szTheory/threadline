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

### Merge

| Field | Value |
|-------|-------|
| PR | #91 (`ci: land v1.47 release flow and supply chain (244, 245)`), opened and merged by the maintainer |
| PR head | `eed57370b478ca21ef5c11313a6f47a4528ad8af` (the land branch head above) |
| Green ci.yml run | `40354035917` (event `pull_request`, conclusion `success`, head `eed57370`); `CI required` = pass; all 16 checks green |
| Merged at | 2026-10-26T16:26:45Z |
| A1 squash SHA on origin/main | `fea5250bf91a582754e82c57ec9196077e4e6c00` (parent `23178fb0`) |
| Squash subject | `ci: land v1.47 release flow and supply chain (244, 245)` (non-releasable, D-03) |
| Squash tree check | `git diff --quiet fea5250b eed57370` exit 0 (squash tree equals the proven land head) |
| Remote branch | `git ls-remote --heads origin land/v1.47-a1` returns nothing: already gone on origin (local branch kept, tracking shows `[gone]`) |
| Land worktree | removed with `git worktree remove`; no longer in `git worktree list` |
| Postgres container | none started (main had not moved); `docker ps -q --filter label=dev.threadline.plan=247-01` is empty |

## Land A2

The 246 critic removal as its own non-releasable `chore:` squash (246 D-12, D-02 step 1).

**Status: LANDED.** The removal squash `9f69a904` is on origin/main. The archive tag exists
locally on its parent. Pushing the tag is a non-blocking maintainer hand-off (see below).
Task 1 first stopped at the literal slice proof. The maintainer accepted the corrected proof
(Option 1) and landed the branch unchanged.

| Field | Value |
|-------|-------|
| Land branch | `land/v1.47-critic-removal` (local; temporary worktree `${TMPDIR}/threadline-land-247-a2`) |
| origin/main at cut | `fea5250bf91a582754e82c57ec9196077e4e6c00` (the A1 squash; `^ci: land v1.47 release flow` count = 1) |
| Slice path set | union of the nine `Removal-Slice:` commits' file lists: **528** paths, **0** under `.planning/` |
| Readiness check | `git diff --quiet 4b2c3f89^ origin/main -- $paths` **exit 0** |
| Cherry-pick | `git cherry-pick 4b2c3f89 cbb804a6 9ea29dc4 1258c014 35243789 61f58954 8eb54275 f57237d6 e9a97139` (nine names) exit 0, no conflicts |
| Land branch commits over origin/main | 9 (9 `Removal-Slice:` trailers) |
| Land branch head | `c3babc69ebceaec09083c15558e422c3f5eab6c5` |
| PR diff | 528 files, 985 insertions, 114609 deletions; `.planning/` paths: **0** |

Picks, in order: C1 `c862dd4d`, C2 `9a2eb4af`, C3a `747fad7d`, C3b `a36a0255`, C4 `c231591f`,
C5 `c1a297cb`, C6 `a497c3bb`, C7 `7b8573ad`, C8 `c3babc69`.

### Slice proof

`git diff --quiet e9a97139 HEAD -- $paths` **exit 1**. One file differs:

```
test/threadline/ci_workflow_parity_contract_test.exs | 20 +++-----------------
 1 file changed, 3 insertions(+), 17 deletions(-)
```

Cause: `e9a97139`'s tree is not the slices alone. Between C5 and C6 sit the six 246-05
`test:` commits (246-LANDING Prerequisite 3 names them), and one of them,
`46efd9d4 test: compare the cache-key runner label with runs-on (216 IN-01)`, edits a slice
path. It is the only non-slice, non-planning commit in `4b2c3f89^..e9a97139` that touches the
528 paths. The residual is exactly that commit, reversed:
`git patch-id --stable` of `git diff e9a97139 HEAD -- <file>` and of
`git diff 46efd9d4 46efd9d4^ -- <file>` are both `421fbeb9e0c3749e4ee84a61f1ae05783a859a13`.

So the branch carries the nine slices and nothing else, as intended; the proof as written
in 247-02-PLAN cannot exit 0 while `46efd9d4` lands after the removal (246-LANDING landing
order step 2.3). Per the plan's halt rule, no slice was re-ordered, edited, dropped or
squashed, and the branch was not pushed. A decision is needed on the proof (see the 247-02
checkpoint).

### Corrected slice proof (accepted, Option 1)

The maintainer accepted Option 1, which the checkpoint recommended. The orchestrator
re-verified it independently. The corrected proof is:

1. `git diff e9a97139 HEAD -- $paths` touches exactly one file,
   `test/threadline/ci_workflow_parity_contract_test.exs`.
2. Its `git patch-id --stable` is `421fbeb9e0c3749e4ee84a61f1ae05783a859a13`. The reverse
   of `46efd9d4`, taken as `git diff 46efd9d4 46efd9d4^ -- test/threadline/ci_workflow_parity_contract_test.exs`,
   has the same patch-id, `421fbeb9e0c3749e4ee84a61f1ae05783a859a13`.

So the residual is exactly `46efd9d4`, a 246-05 `test:` commit and not a slice. It is
missing from the land branch on purpose: 246-LANDING landing-order step 2.3 lands it later,
with Land B. The branch carries the nine slices and nothing else. No slice was edited or
re-ordered to make the literal proof pass.

### Merge

| Field | Value |
|-------|-------|
| PR | #93 (`chore: retire the UI critic loop (DEBT-02)`), pushed, opened and squash-merged by the maintainer |
| PR head | `c3babc69ebceaec09083c15558e422c3f5eab6c5` (the land branch head above) |
| Green ci.yml run | `40375604860` (event `pull_request`, conclusion `success`, head `c3babc69`); `CI required` = pass; all 15 checks green |
| Merged at | 2026-10-26T18:36:24Z |
| Removal squash SHA on origin/main | `9f69a904cf99f7691d50754785d42d8feef1162c` (parent `fea5250b`, the A1 squash) |
| Squash subject | `chore: retire the UI critic loop (DEBT-02)` (non-releasable, D-03) |
| Squash tree check | `git diff --quiet 9f69a904 c3babc69` exit 0: the squash tree equals the proven land head |
| Squash diffstat | `git diff --stat fea5250b 9f69a904`: 528 files changed, 985 insertions(+), 114609 deletions(-) |
| Remote branch | `land/v1.47-critic-removal` **still exists on origin** (`git ls-remote --heads` returns `c3babc69`). It was deliberately not deleted, and the local branch is kept too |
| Land worktree | removed with `git worktree remove`; no longer in `git worktree list` |

### Archive tag (246 D-11, D-13)

| Field | Value |
|-------|-------|
| SQUASH | `9f69a904cf99f7691d50754785d42d8feef1162c` (`git merge-base --is-ancestor "$SQUASH" origin/main` exit 0) |
| PARENT (tag target) | `fea5250bf91a582754e82c57ec9196077e4e6c00` (`git rev-parse "$SQUASH^"`; a main commit, never a milestone/v1.47 commit) |
| Tag | `archive/ui-critic-loop`, annotated (`git cat-file -t` = `tag`), `^{commit}` = `fea5250bf91a582754e82c57ec9196077e4e6c00`, **local only** |
| Message | the 246-LANDING D-31 shape, with both SHAs, the full real `git diff --stat fea5250b 9f69a904` and archive date 2026-10-26; kept as an uncommitted scratch file |
| Message hygiene | `grep -nF -e "$HOME" -e "$(id -un)" <message-file>` printed nothing |
| Register | `.planning/ARCHIVE-REGISTER.md` gains the `archive/ui-critic-loop` row in the `:23` column order; `**Rows: 11.**` → `**Rows: 12.**`; no `archive-subject` comment line |

### Landing evidence (D-14)

| command | result |
|---------|--------|
| `git ls-tree -r --name-only archive/ui-critic-loop \| grep -c lib/threadline/critic_trust/` | `5` (> 0: the tag carries the retired code) |
| `git merge-base --is-ancestor archive/ui-critic-loop origin/main` | exit 0 (the tag pins a main commit) |
| `git ls-remote origin refs/tags/archive/ui-critic-loop` | empty. **Pending the maintainer push below**; it must be non-empty after the push |
| `git grep -n 'archive/ui-critic-loop' origin/main -- .github test bin` | only the three expected lines: `ci_topology_contract_test.exs:681`, `:692` and `ui_critic_retirement_doc_contract_test.exs:16`. None of them resolves the ref |

### Maintainer hand-off (non-blocking, 246 D-13)

Push this one ref only, and never with the flag that pushes all tags (that would publish the
local-only `vX.Y` milestone tags):

```
! git push origin refs/tags/archive/ui-critic-loop
```

Follow-up check (it must print one line, the tag object):

```
git ls-remote origin refs/tags/archive/ui-critic-loop
```

This push does not block Phase 247.
