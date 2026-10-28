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

## Land B1
B1 end SHA: be29f3c70b449050dae9fd1c723fd6c18e008a13

The Phase 247 CI critical-path work (CI-01, D-13 monitor, D-14/D-15 watchdog and timeout
layering, D-12 ratio row, D-09/D-10 lane scope, `bin/measure-main-ci`) plus the six 246-05
`test:` fixes, as one non-releasable `ci:` squash (D-02 step 1, second half; D-03).

**Status: LANDED.** The B1 squash `3463fa74` is on origin/main (see "### Merge" at the end of this section).

| Field | Value |
|-------|-------|
| B1 end SHA | `be29f3c7` = `git log -1 --diff-filter=A --format=%H milestone/v1.47 -- .planning/phases/247-ci-critical-path-and-suite-lanes/247-07-SUMMARY.md` (`docs(247-07): complete CI-03 classification plan`), an ancestor of milestone/v1.47 |
| `(247-09)` commits in `4b2c3f89..B1_END` | 0 |
| Land branch | `land/v1.47-b1` (local; temporary worktree `${TMPDIR}/threadline-land-247-b1`) |
| origin/main at cut | `9f69a904cf99f7691d50754785d42d8feef1162c` (the A2 removal squash) |
| Pick list | `git log --reverse --format=%H 4b2c3f89..B1_END -- . ':!.planning'` minus the `Removal-Slice:` commits (8 of the 9 are in that range; C1 `4b2c3f89` is its exclusive base) |
| Picked commits | 20 (`cherry-pick -x`, exit 0, no conflicts, none touch `.planning/`); first `f29a40bf` (215 WR-04), last `58a7cd3d` (247-07 Node on the current lane) |
| 246-05 `test:` commits carried | 6: `f29a40bf`, `1df4c803`, `f9764172`, `9ff63692`, `6e439225`, `46efd9d4` (246-LANDING landing-order step 2.3) |
| Phase 247 commits carried | 14 (247-03 ×3, 247-04 ×2, 247-05 ×3, 247-06 ×2, 247-07 ×4) |
| Planning sync commit | 1 (`docs(planning): sync v1.47 planning through 247-08`, `git checkout milestone/v1.47 -- .planning`); no stale planning files to remove (0 tracked on the land branch but absent on milestone/v1.47) |
| Land branch commits over origin/main | 21 |
| Land branch head | `a99dd65346a1e26159c97608022aa34590022277` |
| `Removal-Slice:` trailers on the branch (`origin/main..HEAD`) | 0 |
| CHANGELOG | `git diff origin/main HEAD -- CHANGELOG.md` is empty: no adopter-facing entry |
| PR diff outside `.planning` | 76 files, 3665 insertions, 63 deletions |

### Tree proof

```
git diff --quiet be29f3c70b449050dae9fd1c723fd6c18e008a13 HEAD -- . ':!.planning'   # exit 0 (land worktree)
git diff --cached --quiet milestone/v1.47 -- .planning                                  # exit 0 (planning mirror, before the sync commit)
```

### Hygiene

`bin/verify-repo-hygiene` in the land worktree: exit 0
(`4542 tracked text file(s) clean; 8 allowlist entries used, 0 inert`).

### Gate

Which tree: **the land worktree.** `git diff --quiet "$B1_END" HEAD -- . ':!.planning'`
exited 1 in the quality-baseline worktree, because 247-09 code (`bin/browser-full-projects`
and its tests) has already landed on milestone/v1.47 after `B1_END`. So the gate ran on the
land branch tree, which equals `B1_END` outside `.planning`, after `mix deps.get`.

Command: `DB_HOST=127.0.0.1 DB_PORT=<port> CI=true mix ci.all` on an ephemeral `postgres:16`
container labelled `dev.threadline.plan=247-08`, log ANSI-stripped. Result: **exit 0**, and no
`[1-9][0-9]* failures?` line.

| Step | Decisive line |
|------|---------------|
| credo | `5670 mods/funs, found no issues.` |
| deps audit | `findings: none` (the example-only Bandit advisories report as the non-blocking tier, as designed) |
| repo hygiene | `verify-repo-hygiene: 4542 tracked text file(s) clean; 8 allowlist entries used, 0 inert` |
| xref cycles | `No cycles found` |
| library tests | `32 properties, 3361 tests, 0 failures, 3 excluded` |
| example tests | `132 tests, 0 failures` |
| Dialyzer | `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` / `done (passed successfully)` |
| Dialyzer slice | `17 tests, 0 failures, 16 excluded` |
| CI browser lane (desktop + mobile chromium) | `418 passed (6.7m)`, `56 skipped`, 0 failed |

The first gate attempt on the fresh worktree exited 2 for two environmental reasons. Neither
needed a code change. (1) Two `BrowserJourneyEvidenceContractTest` cases failed with
`Playwright CLI is missing; install the locked E2E dependencies`: in a fresh checkout,
`verify.test` runs before the browser step's `npm ci`. (2) Dialyzer stopped with `Could not
read PLT file ... no_such_file`, the known PLT cache miss. After `npm ci` in
`examples/threadline_phoenix/e2e` and `mix dialyzer --plt`, the unchanged tree passed with the
lines above.

### Deviation: partition monitor test fix (PR #94, CI run 40387745942)

PR #94's CI run `40387745942` failed `Build and test (current)` and `Build and test (latest)`
in `test/threadline/partition_monitor_test.exs` (247-04, D-16(b)). The `min` lane passed.

| Lane | Case | Cause |
|------|------|-------|
| current (1.17.3) | `:72` hung `setup_all` | The sandbox deadline was 2000 ms of VM wall time, so it counts boot and code loading. It fired at 2326 ms on a loaded runner while the sandbox was still loading code. `setup_all` had not started, so the report said `nothing in flight` |
| latest (1.20.x) | `:86` passing suite | The assertion matched only `1 tests?, 0 failures`. ExUnit 1.19+ prints `Result: 1 passed` |

Fix (Rule 1, test-only; `partition_monitor.ex` is unchanged): each hang fixture writes a marker
holding the VM wall time at which it entered the hang. A run counts as conclusive only when that
marker predates the deadline by at least 1000 ms. Otherwise the run is retried on a longer
deadline (2000, then 8000, then 30000 ms). If no run is conclusive, the test flunks and prints
every attempt's output. A conclusive run is still asserted strictly: `<file>:<line>` or
`(setup_all)`, a `Process.sleep/1` stack frame and a non-zero exit. The passing case accepts
both summary formats. No other parse of ExUnit's summary line was added in 247. The
`parse_counts` function in `bin/ci-test-partitions` (from #71) already handles both formats, and
`flake_classifier_contract_test.exs` (from #60) only uses a fixture string.

| Field | Value |
|-------|-------|
| Fix commit on milestone/v1.47 | `f839f1161cc154815927f79e7116915c68fa2036` `test(247-08): make partition monitor sandbox test load- and version-robust` |
| Picked onto `land/v1.47-b1` | `525ea1d508506f8c3ba260116d7d74c76a577491` (`cherry-pick -x`, no conflicts) |
| Land branch head (new) | `525ea1d508506f8c3ba260116d7d74c76a577491` (was `a99dd653`) |
| Land branch commits over origin/main | 22 |

Proof on the fixed file, with Elixir 1.17.3 unless noted, against an ephemeral `postgres:16`
container labelled `dev.threadline.plan=247-08-fix`:

- 10 seeds: all `3 tests, 0 failures`, about 5.5 s each.
- 54 `yes` CPU burners on 18 cores: 1 run, `3 tests, 0 failures` (58.7 s).
- Elixir 1.20.4 / OTP 29 via asdf: 1 run, `Result: 3 passed`.

The same matrix also passed on the version before a credo-only refactor (a helper was extracted
for nesting depth): 10 seeds, 3 loaded runs, and 4 runs on 1.20.4.
- Full default suite: `32 properties, 3371 tests, 0 failures, 3 excluded`.

To check that the retry is honest, the first deadline was temporarily set to 300 ms. The
fixtures entered their hangs at about 250 ms, so those runs were inconclusive and retried on
the 8000 ms rung, which passed. With 300 ms as the only rung, both hang cases flunked with
`no run reached the hang`. Elixir 1.15.8 is not installed locally; the `min` lane passed on CI.
The weights row (5200 ms) still matches the about 5.5 s file time, so it is unchanged.

Tree proof, revised: `git diff --quiet $B1_END HEAD -- . ':!.planning'` now holds modulo
exactly this fix commit. In the land worktree:

```
git diff --name-only be29f3c7 HEAD -- . ':!.planning'                                   # only test/threadline/partition_monitor_test.exs
git diff be29f3c7 HEAD -- . ':!.planning' | git patch-id --stable                      # e5c2c8a25babdc494b4923a5ed423d648bda0138
git show 525ea1d5 | git patch-id --stable                                              # e5c2c8a2... (same)
git show f839f116 | git patch-id --stable                                              # e5c2c8a2... (same, milestone side)
git diff --quiet be29f3c7 HEAD -- . ':!.planning' ':!test/threadline/partition_monitor_test.exs'   # exit 0
```

The `ci.all` gate above ran on `a99dd653`, before this fix. The `throwaway/247-hang-repro`
branch below was also cut from `a99dd653` and does not carry the fix.

### D-16(c) repro branch (local only)

| Field | Value |
|-------|-------|
| Branch | `throwaway/247-hang-repro` (local; temporary worktree `${TMPDIR}/threadline-247-repro`), cut from `land/v1.47-b1` head `a99dd653` |
| Commit | `e1c2a3f0ec5f0acda09b9ac43bb63d0173817f3a` `test: throwaway PR #89 hang-shape reproduction (do not merge)` |
| Content | `test/threadline/zz_hang_repro_test.exs` (`Threadline.ZzHangReproTest`, `async: false`, `setup_all` → `Process.sleep(:infinity)`, one trivial test, no tag) plus the weights row `1000 test/threadline/zz_hang_repro_test.exs` in sorted position (last) |
| Pushed | no: a maintainer checkpoint command; never merged, never a PR |

### Merge

| Field | Value |
|-------|-------|
| PR | #94 (`ci: publish browser spec timings, name hung tests, and scope repo contracts to the current lane (247)`), pushed, opened and squash-merged by the orchestrator under the maintainer's own-words grant |
| First PR run | `40387745942` on `a99dd653`: `Build and test (current)` and `(latest)` red in `partition_monitor_test.exs` (fixed above), `Build and test (min)` green (job `121800408825`) |
| Green PR run | `40392212575` on `525ea1d5`: all 15 checks green, `CI required` = pass; `Build and test (min)` job `121815845365` green with `partition-timings-min-40392212575` = 4 TSVs (D-13 Elixir 1.15 proof) |
| Merge | `gh pr merge --squash --match-head-commit 525ea1d5` at 2026-10-26T20:16:59Z |
| B1 squash SHA on origin/main | `3463fa7416696578faa8a9933de0900e61dc9d48` (parent `9f69a904`, the A2 removal squash) |
| Squash subject | `ci: publish browser spec timings, name hung tests, and scope repo contracts to the current lane (247)` (non-releasable, D-03) |
| Squash tree check | `git diff --quiet 3463fa74 525ea1d5` exit 0: the squash tree equals the proven land head |
| Main runs read (D-02 step 2) | `40394247390` (push), `40396194471` (workflow_dispatch), `40398138085` (workflow_dispatch); attempt 1, all success, head `3463fa74`; dispatched one at a time. Numbers in `247-OBSERVATION.md` |
| D-16(c) repro run | `40387548421` on `throwaway/247-hang-repro` (`e1c2a3f0`): failure, `Build and test (min)` job `121799736736` red in 525 s with `Threadline.ZzHangReproTest (setup_all)` named (see `247-OBSERVATION.md`) |
| Remote branches | `land/v1.47-b1` and `throwaway/247-hang-repro` deleted on origin by the orchestrator after the reads (`git ls-remote --heads` returns nothing); both local branches kept (`[gone]`) |
| Archive tag | `archive/ui-critic-loop` pushed by the orchestrator: `git ls-remote origin refs/tags/archive/ui-critic-loop` = `9afd6c92…` (closes the Land A2 hand-off) |
| Temp worktrees | land and repro worktrees removed with `git worktree remove`; neither is in `git worktree list` |
| Postgres containers | none left: `docker ps -a --filter label=dev.threadline.plan=247-08` and `…=247-08-fix` are empty |

## Land B2

The CI-02 browser split and receipt fan-in (247-09, 247-10, 247-11), the CI-derived partition
weights and fitted async factor (247-12), and the `bin/measure-main-ci` gh 2.101 fix (247-13),
as one non-releasable `ci:` squash (D-02 step 3, D-03).

**Status: LANDED** (PR #95, squash `29abf565`, see `### Landed` below). The push, the PR,
the merge and the main sample dispatches were orchestrator checkpoint commands (247-13 Task 2),
run under the maintainer's own-words grant.

| Field | Value |
|-------|-------|
| Land branch | `land/v1.47-b2` (local; temporary worktree `${TMPDIR}/threadline-land-247-b2`) |
| origin/main at cut | `3463fa7416696578faa8a9933de0900e61dc9d48` (the B1 squash) |
| B1 end SHA (pick base) | `be29f3c70b449050dae9fd1c723fd6c18e008a13`, read with the `^B1 end SHA:` sed from `## Land B1` |
| Candidate list | `git log --reverse --format=%H "$B1_END"..milestone/v1.47 -- . ':!.planning'`: 8 commits |
| Excluded | `f839f116` (247-08 partition monitor fix): already on main through the B1 squash, see below |
| Picked commits | 7 (`cherry-pick -x`, exit 0, no conflicts, none touch `.planning/`) |
| Planning sync commit | 1 (`docs(planning): sync v1.47 planning through 247-12`, `git checkout milestone/v1.47 -- .planning`); 0 stale planning files to remove |
| Land branch commits over origin/main | 8 |
| Land branch head | `e85195dac39e347534bcf66e9afb5b34c1ad0284` |
| `Removal-Slice:` trailers on the branch | 0 |
| CHANGELOG | `git diff origin/main HEAD -- CHANGELOG.md` is empty: no adopter-facing entry |
| PR diff outside `.planning` | 14 files, 1542 insertions, 430 deletions |

Picks, in order (milestone → land):

| Plan | Milestone | Land | Subject |
|------|-----------|------|---------|
| 247-09 | `b2c16eef` | `3e832c12` | `feat(247-09): N-file journey receipt inputs runnable under plain node` |
| 247-09 | `a209ccbe` | `4136bc41` | `feat(247-09): resolve ${{ matrix.project }} in bin/browser-full-projects, fail closed` |
| 247-10 | `e8df648b` | `fbcb4326` | `ci(247-10): split browser E2E per Playwright project with a receipt fan-in` |
| 247-12 | `5ba88242` | `26af38a9` | `test(247-12): refresh partition weights from CI current-lane timings` |
| 247-12 | `c87eaecc` | `1406cecb` | `feat(247-12): fit the async partition factor from CI timings` |
| 247-11 | `3613a9f4` | `99cfd6c8` | `test(247-11): pin the browser split with mutation-controlled fan-in rules` |
| 247-13 | `d1261dfd` | `7237af8c` | `fix(247-13): feature-detect gh --allow-escape-sequences for job-log reads` |

### Why `f839f116` is not re-picked

It is the B1 deviation fix. It was carried onto `land/v1.47-b1` as `525ea1d5`, and the B1
squash tree equals that head:

```
git show f839f116 | git patch-id --stable    # e5c2c8a25babdc494b4923a5ed423d648bda0138
git show 525ea1d5 | git patch-id --stable    # e5c2c8a25babdc494b4923a5ed423d648bda0138 (same)
git diff --quiet 3463fa74 525ea1d5           # exit 0
git diff --quiet origin/main milestone/v1.47 -- test/threadline/partition_monitor_test.exs   # exit 0
```

`git cherry` cannot show this match, because the squash folds the patch into one commit. The
patch-id equality and the file equality above are the proof.

### Tree proof

```
git diff --quiet milestone/v1.47 HEAD -- . ':!.planning'   # exit 0 (land worktree, before the sync commit)
git diff --cached --quiet milestone/v1.47 -- .planning      # exit 0 (planning mirror)
git diff --quiet milestone/v1.47 HEAD                       # exit 0 (after the sync commit)
```

The milestone side is `d1261dfd`, the tree the gate below ran on.

### Hygiene

`bin/verify-repo-hygiene` in the land worktree: exit 0
(`4548 tracked text file(s) clean; 8 allowlist entries used, 0 inert`).

### Gate

Which tree: **milestone/v1.47 at `d1261dfd`** in the quality-baseline worktree. The land tree
equals it, so no second gate ran on the land branch. Command: `DB_HOST=127.0.0.1
DB_PORT=<port> CI=true mix ci.all` on an ephemeral `postgres:16` container labelled
`dev.threadline.plan=247-13` (removed afterwards), log ANSI-stripped.

**Run 1: exit 2, red.** Two library failures. Every other step was green (example 132/0,
Dialyzer 0 errors, browser lane `418 passed`, 56 skipped):

| Case | Failure |
|------|---------|
| `test/threadline/query/row_key_read_test.exs:204` | `as_of(..., DateTime.utc_now())` returned `{:error, :before_audit_horizon}` immediately after the write |
| `test/threadline/query/as_of_property_test.exs:94` | the property's own guard: `tie or clock step: captured_at did not strictly increase` |

Both cases compare the database's `captured_at` with wall-clock time. Neither file, nor
`lib/threadline/query.ex`, is in the B2 diff: the B2 diff has no `lib/` path, and those
files last changed in `371ce3ac`, which is already on main. A bracketed host-vs-container clock
read showed no skew. Re-run in isolation with run 1's seed (`414420`) and with seeds 1 to 4,
both files passed every time (`2 properties, 9 tests, 0 failures`).

**Run 2 (same tree, unchanged): exit 0, green.**

| Step | Decisive line |
|------|---------------|
| credo | `5689 mods/funs, found no issues.` |
| deps audit | `findings: none` |
| repo hygiene | `verify-repo-hygiene: 4548 tracked text file(s) clean; 8 allowlist entries used, 0 inert` |
| xref cycles | `No cycles found` |
| library tests | `32 properties, 3378 tests, 0 failures, 3 excluded` |
| example tests | `132 tests, 0 failures` |
| Dialyzer | `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` |
| Dialyzer slice | `17 tests, 0 failures, 16 excluded` |
| CI browser lane (desktop + mobile chromium) | `418 passed (5.9m)`, `56 skipped`, 0 failed |

The run 1 flake is logged in `deferred-items.md` as a pre-existing, time-sensitive `as_of`
pair. It is not fixed here, because it is outside B2's scope.

### Measurement script fix (deferred item from 247-08)

`bin/measure-main-ci --ratios` now reads `gh api --help` once, and only when `--ratios` is
set. If gh lists `--allow-escape-sequences`, the script passes it to the `job-log` read
(gh 2.101+ refuses ANSI job logs without it). If gh does not list it, the flag is left off,
because older gh rejects it as unknown. The fake gh now emulates both generations: the new
one refuses the bare logs read, and the old one rejects the flag. Two new contract cases pin
the flag choice and show that the probe never runs without `--ratios`. A mutation check that
forces the flag off fails the new case. A live read-only smoke on gh 2.101.0 against main run
`40394247390` returned `{"min":[1.68],"latest":[1.52],"current":[1.49]}` with no `GH_BIN` shim.

### Landed

| Field | Value |
|-------|-------|
| PR | #95, head `land/v1.47-b2` at `e85195dac39e347534bcf66e9afb5b34c1ad0284` |
| PR CI run | `40412545694`: all 17 checks green, incl. both browser legs, `Browser journey receipt` and `CI required`; no 403 on the receipt download |
| Merge | squash with `--match-head-commit e85195da`, 2026-10-26T22:35:26Z |
| Squash on main | `29abf5653a0e1c31b70d73d71a3f6c552d9b9712` (parent `3463fa74`) |
| Main vs milestone | `git diff --quiet origin/main milestone/v1.47 -- . ':!.planning'` exits 0 |
| Remote branch | `land/v1.47-b2` deleted by the orchestrator; local branch kept |
| Main samples (sequential, attempt 1, success) | `40413601357` (push), `40414924903`, `40416330436`, `40417290637`, `40418204130` (workflow_dispatch) |
| Local gate decision | ci.all run 1 was red on two time-sensitive `as_of` cases outside the B2 diff (see `### Gate`). The orchestrator took run 2 (green, same tree) as the local gate, with the PR CI run as the deciding gate. |

Measurements on these samples: `247-MEASUREMENT.md` (CI-02 median 468 s PASS; CI-03 ratios MISS).


## Land B3 — lane-specific weights and exact-head candidate gate

B3 tested land HEAD: 9fa28fad40ac0fb1ca3b83e48ce95a3845df698f

Candidate branch `land/v1.47-ci03-weights`, isolated under scratch `threadline-247-b3-land`, starts at `origin/main` 29abf565. Seven reviewed source/test commits were cherry-picked with provenance; the six Plan 14 picks are a85f2555, 97e34de8, 9d71d142, 636a6045, 4300ffd9, 377ca161. Necessary Plan 15 test synchronization source b35750bd maps to land 9fa28fad. Planning snapshot commits: 9cb3ed38 and da718fe3. No unrelated production changes.

Exact non-planning tree proof, run inside the landing worktree after the green gate:

```
git diff --quiet milestone/v1.47 HEAD -- . ':!.planning'
```

Exit 0. `CHANGELOG.md` is unchanged from origin/main. Candidate changes six non-planning files: runner, three weights files, topology contract and one existing accessibility test. Required workflow job IDs, all three Build and test lanes, both browser project legs, receipt fan-in, timing uploads and watchdog layering are unchanged.

### Exact-head local gate

Command run **inside the landing worktree**: `CI=true DB_HOST=127.0.0.1 DB_PORT=<discovered ephemeral port> mix ci.all`, followed by `bin/ci-test-partitions --self-test`, `bin/verify-repo-hygiene`, and read-only `bin/verify-branch-protection`. The PostgreSQL 16 container carried label `dev.threadline.plan=247-15` and a dynamically discovered loopback port. The complete command group exited **0** on the tested land head above.

| Gate | Evidence |
|---|---|
| format / Credo | clean; 5691 mods/funs, no issues |
| dependency audit | three lockfiles clean at their configured gates; 11 already non-blocking example-only findings |
| hygiene | 4563 tracked text files clean; 8 used allowlist entries, 0 inert |
| compile / xref / no-optional / bench compile | green; no cycles |
| root suite | 32 properties, 3381 tests, 0 failures, 3 configured exclusions |
| Phoenix example suite | 132 tests, 0 failures |
| Dialyzer | 0 errors; passed successfully |
| live Dialyzer slice | 17 tests, 0 failures, 16 not-in-slice exclusions |
| desktop + mobile browser gate | 418 passed, 56 configured skips, zero failures (5.5 min) |
| runner self-test | all original cases plus min/all routing, assignment mutation, ingestion integrity markers green |
| branch protection | exactly `CI required@15368`, no stacked classic rule |

### Gate corrections before publication

1. The first candidate stopped at hygiene because the authored gap plans embedded a machine-local execution path. Source 9c783673 / land da718fe3 replaced that with portable HOME-based references; hygiene then passed.
2. The fresh land checkout lacked the existing `.dialyzer` PLT directory. Copied the existing local cache; no dependency or source change. The complete unchanged-head gate was rerun.
3. That full run passed root/example/Dialyzer but failed one existing desktop accessibility case: 417 browser passes, 56 skips, toast remained visible after keyboard Enter. The browser tree was byte-identical to main. The case passed 20 isolated executions and all 18 desktop accessibility cases, identifying timing sensitivity. A controlled 50 ms animation-frame deferral at modal close plus a 300 ms diagnostic pause before Enter reproduced the same failure with focus on Show Modal. Phoenix's local JS focus/pop-focus implementation reapplies focus in nested animation frames. Source b35750bd adds four lines to the existing test: await modal hidden and its opener focused before moving focus to toast Close. The identical delayed-frame probe passed with the fix, then the normal case passed on both browser projects with retries disabled (2/2). All temporary diagnostics were removed. Independent review approved the sixth-file delta; no new finding. The complete exact-head gate was rerun green on 9fa28fad.

No new retry or relaxed assertion was added. Main numeric thresholds remain 540 seconds and 1.15; this local gate claims neither numeric performance acceptance nor phase completion. Finalized local review/landing receipts remain in the source worktree; the immutable candidate carries its pre-gate planning snapshot.


### B3 protected-main landing

B3 squash SHA: 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2

- PR #96: `https://github.com/szTheory/threadline/pull/96`, created and merged under D-01's standing own-green-quality-PR grant. Non-releasable `ci:` squash; no Hex publication.
- PR CI run 40432374330, **attempt 1** at exact tested head 9fa28fad: all **17 jobs/checks success** (three Build and test lanes, desktop/mobile browser legs, Browser journey receipt and CI required included). Exact-head merge guard used; GitHub rejected no head mismatch.
- Receipt job 121955196349: `Validated 31 named journeys across desktop-chromium, mobile-chromium.` Both browser-timings artifacts, all three partition-timings families and operator-ci-evidence artifact present and unexpired (14 days).
- Squash tree proof: after fetch, origin/main equals the B3 squash SHA and `git diff --quiet origin/main 9fa28fad -- . ':!.planning'` exits 0. Landing checkout HEAD remains the tested 9fa28fad.
- Automatic main push run **40433193088**, created 2026-10-27T01:32:42Z at 89add23e, concluded success on attempt 1 with all 17 jobs green. No additional main run was dispatched before that terminal result.

The GitHub connector performed PR creation and the SHA-guarded squash merge. Canonical CLI reads use explicit attempt-1 endpoints because the connector's jobs wrapper exposes only the latest attempt. This preserves the same exact-head/attempt-1 contract as the documented gh precedent.

Post-merge branch-protection readback: exactly `CI required@15368`, emitted once on main head 89add23e, no stacked classic protection. The planned exact-head, required-context and non-planning squash-tree checks all passed after the main push run. Task 2 complete; proceed to serial five-run measurement.


### B3 final main measurement chronology

Five qualifying attempt-1 successes, all at 89add23e: 40433193088 (push, 423 s), 40434036118 (dispatch, 471 s), 40434884357 (dispatch, 451 s), 40436597341 (dispatch, 442 s), 40437416932 (dispatch, 444 s). Chronological run 40435657557 failed the unchanged mobile motion-fixture toast case and is excluded; it was not rerun. All six run records have attempt 1, and each new dispatch was created after the preceding run's terminal updated_at. Dispatch stopped at five qualifying successes.

| Main run | Successful jobs | Receipt job | Named journeys |
|---|---:|---|---:|
| 40433193088 | 17/17 | 121957702849 | 31 |
| 40434036118 | 17/17 | 121960622423 | 31 |
| 40434884357 | 17/17 | 121963299391 | 31 |
| 40436597341 | 17/17 | 121968849454 | 31 |
| 40437416932 | 17/17 | 121971494579 | 31 |

All five runs have the two browser-timings artifacts, three lane-scoped partition-timings artifacts and receipt artifact present and unexpired. Median wall **444 s, CI-02 PASS**; fixed first-three lane ratios yield **CI-03 MISS** (seven of nine above 1.15). Full values, per-partition diagnosis and exclusion details are in 247-MEASUREMENT.md and the captured canonical JSON. No numeric limit was changed; phase 247 remains open.


## Land B4 candidate

B4 tested land HEAD: 4ff7af655315a927eb5a62e14cb2abc7e72d4ab8

Candidate `land/v1.47-ci03-duration-floor` is isolated in scratch `threadline-247-b4-land`, based on main 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2. Reviewed source picks a0b678c9/e989ae15/94a34440/832bfe5e map to 280db792/da984e9b/ed97fe68/cab00efc. Planning snapshot commit 0e313435 freezes the approved gap plans and execution evidence before the gate. Only six non-planning files differ from main: runner, three weights, topology contract and motion fixture. No CHANGELOG or release/API change.

### Initial local gate (historical head 0e313435)

This first local receipt belongs to 0e313435. The final corrected-head receipt is in "Corrected B4 exact-head gate" below.

Ran inside the candidate on pinned Elixir 1.17.3 / OTP 27 with Bash 5 available, `CI=true DB_HOST=127.0.0.1 DB_PORT=<discovered ephemeral port> npm_config_cache=<scratch cache> mix ci.all`. Ephemeral postgres:16 is labelled dev.threadline.plan=247-18 and bound only to loopback. Local caches were copied, not linked; locked E2E dependencies were installed before the successful gate. Full command exited 0 on the exact head above.

| Gate | Result |
|---|---|
| format / Credo | clean; 5692 mods/funs, no issues |
| dependency audit | three lockfiles clean at configured gates; 11 unchanged non-blocking example-only findings |
| root suite | 32 properties, 3382 tests, zero failures, 3 configured exclusions |
| example suite | 132 tests, zero failures |
| Dialyzer / live slice | zero errors; 17 slice tests passed, 16 outside-slice exclusions |
| desktop + mobile browsers | 418 passed, 56 configured skips; 5.8 min; zero failures |
| Bash 5.2 + Bash 3.2 runner self-tests | both exit 0, including duration floor, strict lane ingestion, exact-once routing and hang safeguards |
| hygiene | 4571 tracked text files clean; 8 used allowlist entries, zero inert |
| branch protection (read-only) | exactly CI required@15368, no stacked classic protection |

After the gate, candidate HEAD is unchanged, tracked status is clean, and `git diff --quiet milestone/v1.47 HEAD -- . ':!.planning'` inside the candidate exits 0. Source and candidate non-planning trees are identical. Independent reviews of Plans 16 and 17 found no issues. This proves local readiness, not main numeric acceptance.

### Local setup and process corrections

An initial PATH put Homebrew Elixir ahead of the pinned asdf toolchain; corrected PATH without source edits. A fresh-checkout run exposed two missing-Playwright-CLI discovery failures; installed the locked E2E dependencies. That alias continued after the root failures, and an early restart briefly overlapped it; stopped both identified task-owned process trees, confirmed terminal exits, replaced the task-owned database and reran the whole gate in isolation. The successful final run above is the complete unchanged-head receipt. No failed local attempt is credited as green, no assertions/thresholds changed, and nothing was pushed before full success.


### B4 hosted landing

B4 PR number: 97
B4 PR head SHA: 4ff7af655315a927eb5a62e14cb2abc7e72d4ab8
B4 PR run ID: 40448573344

PR https://github.com/szTheory/threadline/pull/97 opened under D-01's standing quality-PR grant only after the complete exact-head local gate. Initial hosted run 40446515239 completed failure: all three Build and test lanes stopped in the unconditional self-test with GNU awk 5.2.1 fatal Node_array_tree. Both browser legs and other checks completed; this run is not credited as green and was not rerun. No merge or main measurement occurred. Source correction f81f859c, land 4ff7af65, forces scalar numeric cost inputs; a one-file Linux reproduction changed from the same crash to the expected assignment, full GNU awk and both Mac Bash self-tests passed, 45 focused contracts passed, all B3 fit/load results are identical, and independent review found no issues. The complete local gate is being repeated on corrected land HEAD 4ff7af655315a927eb5a62e14cb2abc7e72d4ab8 before any push.


### Corrected B4 exact-head gate

Initial locally green head 0e313435 was not merged: PR run 40446515239 exposed a GNU awk 5.2.1 unset-array-argument crash in every lane's self-test. The empirical one-file reproduction and original seven-file self-test both failed on Linux; coercing the cost arguments to numeric values made the minimized and whole Linux loops pass. Changing only the ternary result or passing the omitted scratch argument did not fix it. No model, weights, inventory, assertion or threshold changed.

Source f81f859c maps to land 4ff7af65. On exact final head 4ff7af655315a927eb5a62e14cb2abc7e72d4ab8, the complete pinned-toolchain `CI=true mix ci.all` exited 0 again: 32 properties / 3382 root tests / 0 failures / 3 configured exclusions; 132 example tests / 0 failures; Dialyzer 0 errors; live slice 17/0; browsers 418 passed / 56 configured skips (6.8 min). Both Bash self-tests, hygiene and sole required-context readback also exited 0 on this final candidate. Its runner hash equals the fully passing GNU awk container copy. The three-lane B3 model-fit and new assignments are byte-for-byte numerically unchanged; 45 focused topology/scope tests passed; independent review found no issues.

A checkout mix-up while preparing this correction was caught before another push; the resulting old-head gate was stopped and the empty cherry-pick aborted. Explicit `git -C` paths, fail-fast command sequencing, exact-SHA assertion, clean status and non-planning tree equality guarded the successful amended run. Failed/interrupted receipts are never used as the complete gate. The candidate is now ready to update the same PR; merge still requires new exact-head hosted success.


B4 squash SHA: 02d115a32e4479f353d284c04fc838ba58938d16

PR #97 was squash-merged under D-01 with `--match-head-commit` at the exact locally and hosted-tested head. Run 40448573344 attempt 1 passed all 17 jobs, including all three Build and test lanes, both browser projects, Browser journey receipt and CI required. All ten named phase artifacts are present and unexpired; downloaded browser payloads have two correctly ranked top-20 arrays, the receipt reconciles all 31 required journeys, and the three timing families each contain four correctly labelled TSVs. The earlier failed PR run 40446515239 is preserved and was never retried. Protected-main squash and tested-candidate non-planning trees are identical; CHANGELOG/API/CI job IDs remain unchanged. Main measurements are not yet claimed.

Post-merge required-context readback initially confirmed the sole configured context but correctly failed its emitted-check assertion because the new main push was still running and had not emitted CI required yet. Awaiting that automatic run before the final readback and any optional dispatch. No protection setting was changed.


B4 automatic main push run: 40449332597

Automatic main attempt 1 run 40449332597 completed success on 02d115a32e4479f353d284c04fc838ba58938d16 before any optional dispatch. Final `bin/verify-branch-protection` inside the candidate exited 0: exactly CI required@15368, emitted once on that main head, no stacked classic protection. The earlier transient missing-emission readback is resolved without configuration changes. Plan 18 exact PR/tested-head/squash/tree/readback checks all pass; Plan 19 may collect the bounded same-head sample.


## B4 bounded main chronology — INCOMPLETE

B4 measurement: INCOMPLETE

| Run | Event | Exact head | Started at UTC | Dispatch time / automatic | Conclusion |
|---|---|---|---|---|---|
| 40449332597 | push | 02d115a32e4479f353d284c04fc838ba58938d16 | 2026-10-27T04:22:00Z | automatic merge push | success |
| 40450141708 | workflow_dispatch | 02d115a32e4479f353d284c04fc838ba58938d16 | 2026-10-27T04:30:47Z | 2026-10-27T04:30:46.132531+00:00 | success |
| 40450801580 | workflow_dispatch | 02d115a32e4479f353d284c04fc838ba58938d16 | 2026-10-27T04:38:00Z | 2026-10-27T04:37:58.707584+00:00 | success |
| 40451533079 | workflow_dispatch | 02d115a32e4479f353d284c04fc838ba58938d16 | 2026-10-27T04:45:58Z | 2026-10-27T04:45:56.932421+00:00 | success |
| 40452150109 | workflow_dispatch | 02d115a32e4479f353d284c04fc838ba58938d16 | 2026-10-27T04:52:47Z | 2026-10-27T04:52:45.981837+00:00 | failure |
| 40452833440 | workflow_dispatch | 02d115a32e4479f353d284c04fc838ba58938d16 | 2026-10-27T05:00:17Z | 2026-10-27T05:00:15.797550+00:00 | failure |

Used 6/6 total runs and 5/5 extra serial dispatches. Four successes, two failed exclusions (40452150109 and 40452833440); no retries or seventh run. Five-success wall gate is INCOMPLETE; fixed first-three ratio gate is MISS. The complete measurement/projection gate is not claimed, and Plan 19 halts at its designed budget stop. Fixture-isolation diagnosis and a further sampling budget are a new scope decision; do not blindly refresh weights.


## Land B5 — min-lane fixtures and weights

B5 tested land HEAD: 14f9562115153c58a792a349f7ef6479496d2d44

Candidate `land/v1.47-ci03-min-b5` is isolated in scratch `threadline-247-b5-land`, based on main 02d115a32e4479f353d284c04fc838ba58938d16 (the B4 squash; `origin/main` had not moved). The precondition passed before any push: 247-B5-WEIGHTS.md holds exactly one B5-WEIGHTS-JSON block, its `weights_sha256` equals the sha256 of `test/partition_weights_min.txt` (cb833068…b187), and `ci03_expectation` is EXPECTED_MISS. That value is advisory and never halts this plan (D-25).

Pick map, from `git log --reverse f81f859c..milestone/v1.47 -- . ':!.planning'`, all `git cherry-pick -x` with no conflict:

| Source | Land | Subject |
|---|---|---|
| 136bb932 | 5e494ebe | test: serialize shared local export fixtures |
| 714b4dbb | 58979913 | test: own retention worker lifetime in pruner fixtures |
| 14badb2c | 7007e706 | test(247-26): add failing test that retention live prune workers are test-owned |
| d4688d58 | a431f0cd | test(247-26): own retention live prune worker lifetime |
| eed59aa2 | f4af5640 | test(247-26): describe the lock-held prune worker as waiting |
| 3b510219 | c04500d8 | ci(247-27): re-derive min partition weights from B4 main timings |
| 8ef4b801 | 8973fd3b | docs(247-27): record B5 min weights selection (B) |

Planning snapshot commit 14f95621 (`docs(planning): sync v1.47 planning through phase 247 plan 28`) syncs `.planning` from milestone/v1.47 at be93b37a. No tracked planning file on main was absent on milestone/v1.47, so nothing was removed.

Tree proofs, inside the land worktree on the tested head: `git diff --quiet milestone/v1.47 HEAD -- . ':!.planning'` exits 0, and `git diff --quiet milestone/v1.47 HEAD -- .planning` exits 0.

Scope proof (D-03): `git diff --name-only origin/main HEAD -- . ':!.planning'` lists only six files under test/: `test/partition_colocate.txt`, `test/partition_weights_min.txt`, `test/threadline/ci_topology_contract_test.exs`, `test/threadline/operator_surface/live/retention_history_live_test.exs`, `test/threadline/retention/pruner_test.exs` and `test/threadline/storage/local_test.exs`. `git diff --quiet origin/main HEAD -- lib/ bin/ .github/ mix.exs mix.lock CHANGELOG.md` exits 0.

### B5 exact-head local gate

Ran inside the land worktree on the pinned Elixir 1.17.3 / OTP 27 toolchain (asdf shims first on PATH, Bash 5.2 available): `CI=true DB_HOST=127.0.0.1 DB_PORT=<discovered ephemeral port> npm_config_cache=<scratch cache> mix ci.all`. The ephemeral postgres:16 (16.14) carried label `dev.threadline.plan=247-28` and was bound to loopback only. `deps`, `_build`, `.dialyzer` and the example app's `deps`/`_build` were copied from the source root, not linked. The locked example E2E dependencies were installed with `npm ci` into a scratch cache first. The whole command exited 0 on the first attempt, then the follow-up checks below also exited 0. Tracked status stayed clean.

| Gate | Result |
|---|---|
| format / Credo | clean; 5693 mods/funs, no issues |
| dependency audit | three lockfiles clean at their configured gates; 11 unchanged non-blocking example-only advisories |
| hygiene (inside ci.all and standalone) | 4636 tracked text files clean; 8 allowlist entries used, 0 inert |
| root suite | 32 properties, 3384 tests, 0 failures, 3 configured exclusions |
| Phoenix example suite | 132 tests, 0 failures |
| Dialyzer | 0 errors; passed successfully |
| live Dialyzer slice | 17 tests, 0 failures, 16 outside-slice exclusions |
| desktop + mobile browsers | 418 passed, 56 configured skips, 0 failures (5.6 min) |
| runner self-test | `bin/ci-test-partitions --self-test` exits 0 under Bash 5.2 and under /bin/bash 3.2 |
| branch protection (read-only) | exactly `CI required@15368`, emitted on main 02d115a3, no stacked classic protection |

This proves local readiness on the exact head, not main numeric acceptance. Thresholds stay 540 s and 1.15.

### B5 hosted landing

B5 PR number: 98
B5 PR head SHA: 14f9562115153c58a792a349f7ef6479496d2d44
B5 PR run ID: 40690983585
B5 squash SHA: 824c28517820c1cd6595f2e0e60b34ec3ce64d14
B5 automatic main push run: 40692111621

The land branch was pushed once with a plain `git push -u`, and PR https://github.com/szTheory/threadline/pull/98 was opened under D-01's standing own-green-quality-PR grant. Its body states `ci03_expectation` EXPECTED_MISS with the B5-WEIGHTS `risk` sentence, the two fixed mechanisms, rule B, all five replay spreads, the three predicted ratios, the D-11 follow-up and the local gate. Only one PR head ever ran ci.yml, and the PR timeline has zero `head_ref_force_pushed` events.

PR run 40690983585, attempt 1 at the exact tested head, concluded success with all 17 jobs green, including all three Build and test lanes, both browser projects, Browser journey receipt and CI required. `gh pr merge 98 --squash --match-head-commit 14f95621…` merged it as a non-releasable `ci:` squash, and GitHub reported no head mismatch. After fetch, `origin/main` equals the PR mergeCommit 824c2851, and `git diff --quiet origin/main 14f95621 -- . ':!.planning'` exits 0. The remote land branch was deleted.

Automatic main push run 40692111621 was created 2026-10-28T12:57:17Z at the squash. Its attempt 1 concluded success at 13:04:46Z with 17/17 jobs green. No dispatch happened before that terminal state. The post-merge `bin/verify-branch-protection` readback then exited 0: exactly `CI required@15368`, emitted on main head 824c2851, no stacked classic protection. The land worktree and the `dev.threadline.plan=247-28` container were removed after this readback.


## B5 bounded main chronology

| Run | Event | Exact head | Created at UTC | Dispatch time / automatic | Attempt-1 updated at UTC | Conclusion |
|---|---|---|---|---|---|---|
| 40692111621 | push | 824c28517820c1cd6595f2e0e60b34ec3ce64d14 | 2026-10-28T12:57:17Z | automatic merge push | 2026-10-28T13:04:46Z | success |
| 40693451272 | workflow_dispatch | 824c28517820c1cd6595f2e0e60b34ec3ce64d14 | 2026-10-28T13:06:31Z | dispatched after 13:06:24Z | 2026-10-28T13:14:08Z | success |
| 40694602284 | workflow_dispatch | 824c28517820c1cd6595f2e0e60b34ec3ce64d14 | 2026-10-28T13:14:19Z | dispatched after 13:14:13Z | 2026-10-28T13:21:49Z | success |
| 40695763585 | workflow_dispatch | 824c28517820c1cd6595f2e0e60b34ec3ce64d14 | 2026-10-28T13:22:02Z | dispatched after 13:21:56Z | 2026-10-28T13:29:43Z | success |
| 40696978392 | workflow_dispatch | 824c28517820c1cd6595f2e0e60b34ec3ce64d14 | 2026-10-28T13:30:06Z | dispatched after 13:29:59Z | 2026-10-28T13:39:55Z | success |

Used 5/6 total runs and 4/5 extra serial dispatches. Sampling stopped at five attempt-1 successes, so the sixth slot was not used. Before each dispatch a guard confirmed that `origin/main` still equalled the B5 squash, that no ci.yml main run was queued or in progress, and that fewer than six push/dispatch runs existed at the squash. Each dispatched run was created after the previous run's attempt-1 terminal time. There were no failed runs, no exclusions, no retries and no job re-runs. Neither B4 failure (`row_history_live_test.exs:361` FK, `orchestrator_test.exs:239` rm_rf) recurred: every cohort run passed all 17 jobs.

The last run's 589 s wall includes runner pickup delay: its Build and test jobs were created at 13:30:07Z but started between 13:30:47Z and 13:32:03Z. The full attempt-1 wall is counted as measured, as for every run.

`bin/measure-main-ci --since 824c28517820c1cd6595f2e0e60b34ec3ce64d14 --count 5 --ratios --format json` returned `state: measured`, `found: 5`. Its unedited stdout is `247-B5-MEASUREMENT.json`. No `247-B5-INCOMPLETE.json` exists.
