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
