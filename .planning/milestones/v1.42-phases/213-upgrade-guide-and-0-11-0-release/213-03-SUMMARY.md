---
phase: 213-upgrade-guide-and-0-11-0-release
plan: 03
subsystem: release
tags: [changelog, release-gates, landing-branch, pgbouncer, hand-off]

requires:
  - phase: 213-upgrade-guide-and-0-11-0-release
    provides: "213-01's guide/CHANGELOG security note and 213-02's real-PG upgrade+rollback proof, both cited as pre-land evidence"
provides:
  - "CHANGELOG.md `## [0.11.0] - 2026-09-26` dated entry with adopter highlights, above Security/Breaking changes/Required action, plus a fresh `## Unreleased — highlights` standing block"
  - "Every D-11 local pre-land and pre-release gate run on the final milestone tree, recorded with exit code"
  - "Local branch land/v1.42: one ID-free `feat!:` commit on origin/main, tree-equal to milestone/v1.42 outside .planning/, ci.all green on it, never pushed"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-PR-BODY.md — PR body for the maintainer's `gh pr create --body-file`"
  - "Ordered 10-step maintainer hand-off (below) and a re-derived stray-branch list"
affects: []

actuals:
  tokens: 5100
  tasks: 3
  commits: 2
  plan_head_before: 683a9ba9

tech-stack:
  added: []
  patterns:
    - "Config.json protection pattern: save diff + file copy, git stash push on the named path only, run the gate, pop, verify byte-identical — used twice (verify.release, landing build) to keep the maintainer's uncommitted config edit intact across branch switches."
    - "Landing branch built with a hand-run cherry-pick-and-filter loop (gsd-pr-branch's create_pr_branch algorithm, targeting a plan-chosen branch name and origin/main instead of the workflow's default `<branch>-pr` naming) rather than invoking the skill directly, because the plan needed a specific branch name (land/v1.42) and a soft-reset collapse to one commit afterward."

key-files:
  created:
    - .planning/phases/213-upgrade-guide-and-0-11-0-release/213-PR-BODY.md
  modified:
    - CHANGELOG.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "0.11.0 highlights paragraph (4 sentences) leads with capture's primary-key resolution and read-side agreement, names the shared-capture-function security fix, and points at guides/upgrading-to-0.11.md, per the plan's exact content instruction."
  - "Landing branch squash subject used the plan's suggested wording verbatim (`feat!: capture every primary-key shape, read it back exactly, and detect broken capture`); it passed the ID-free and dated-heading checks with no edit needed."
  - "112 of 215 non-merge commits between origin/main and milestone/v1.42 qualified for the landing branch under the strict per-commit rule (NON_PLANNING > 0); the other 103 were .planning/-only and excluded. All 112 cherry-picked cleanly with zero conflicts outside the .planning/ filter."
  - "The gsd-plan-head-before-213-03 commit ledger was first written against the wrong base (6887a21e, the phase's last test commit) because the git-dir sentinel was created before confirming actual pre-plan HEAD; corrected to 683a9ba9 (the real pre-plan HEAD, per the phase-start git status) before computing the actuals.commits count, so the recorded count reflects only this plan's own commits."

requirements-completed: []

coverage:
  - id: D1
    description: "CHANGELOG.md carries a dated ## [0.11.0] entry with highlights prose, Security/Breaking changes/Required action above the feature tour, and a fresh unbracketed Unreleased standing block"
    requirement: "REL-03"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix verify.bump_rehearsal passes with no synthesised stand-in, on both the Task 1 commit and the final Task 2 tree"
    requirement: "REL-03"
    verification:
      - kind: integration
        ref: "mix verify.bump_rehearsal (run twice, see gate table)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every D-11 local pre-land gate ran on the final milestone tree with exit code recorded, including PgBouncer topology, hex_evaluator, and the unscoped browser lane at exactly the 8 known failures"
    requirement: "REL-03"
    verification:
      - kind: integration
        ref: "gate table below, logs in /tmp/threadline-213-gates/"
        status: pass
    human_judgment: false
  - id: D4
    description: "A local land/v1.42 branch, built with the gsd-pr-branch cherry-pick flow onto origin/main with every .planning/ path filtered out, holds exactly one ID-free feat! commit, its tree equals milestone/v1.42 outside .planning/, and ci.all is green on it"
    requirement: "REL-03"
    verification:
      - kind: integration
        ref: "git diff/rev-list checks below; mix ci.all on land/v1.42, log in /tmp/threadline-213-landing/ci_all.log"
        status: pass
    human_judgment: false
  - id: D5
    description: "The checkout ends on milestone/v1.42 with config.json restored byte-for-byte and .tool-versions untracked; nothing pushed; REL-03 stays Pending with a maintainer-action note"
    requirement: "REL-03"
    verification:
      - kind: integration
        ref: "cmp against the pre213-03 backup; git ls-remote --heads origin land/v1.42 (empty); REQUIREMENTS.md row"
        status: pass
    human_judgment: false

duration: ~1h25min (spans one supervisor-flagged idle gap around Task 3's included-commit computation; see Deviations)
completed: 2026-09-26
status: complete
---

# Phase 213 Plan 03: Upgrade Guide and 0.11.0 Release Summary

**Dated the 0.11.0 CHANGELOG entry, ran and recorded every local pre-land/pre-release gate on the final milestone tree (ci.all, verify.release, bump rehearsal, pins, docs, hex.build, doc contracts, PgBouncer topology, hex evaluator, and the unscoped browser lane at exactly its 8 known failures), then built and verified a one-commit, ID-free `land/v1.42` landing branch — never pushed — leaving an exact 10-step maintainer hand-off.**

## Performance

- **Duration:** ~1h25min wall clock (includes one idle gap the supervising orchestrator flagged and resumed; see Deviations)
- **Started:** 2026-09-26T~13:40Z
- **Completed:** 2026-09-26T~15:05Z
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified) on `milestone/v1.42`; plus the disposable `land/v1.42` branch (never pushed, not part of this file count)

## Accomplishments

- `CHANGELOG.md`: retitled the `## Unreleased — highlights` block's content into a dated `## [0.11.0] - 2026-09-26` entry with a 4-sentence adopter highlights paragraph, keeping the Security/Breaking changes/Required action sections above the feature tour (moved verbatim), and left a fresh `_Nothing yet for the next release._` line under the standing `## Unreleased — highlights` heading for the next cycle.
- Ran the fast release-shape chain on that commit: the five doc-contract test files (56 tests, 0 failures), `mix release.pins --check` (0 drift), and `mix verify.bump_rehearsal` (byte-identical tree, no `synthesising` line).
- Ran every D-11 gate on the final milestone tree — full gate table below — including `mix ci.all` (130+2207 tests/0 failures, Dialyzer 0 errors, browser 318 passed/26 skipped/0 failed), `mix verify.release` (config.json protected via stash/pop, byte-identical restore verified), the PgBouncer topology + `verify.threadline` lane (2 tagged tests, not excluded), `mix verify.hex_evaluator` (19 tests, 0 failures), and the unscoped browser lane at exactly the 8 documented `operator-screenshot-regression.spec.ts` failures (326 passed/8 failed/16 skipped).
- Built `land/v1.42` locally from `origin/main` (0 commits behind at build time): cherry-picked 112 of 215 non-merge commits (the ones touching at least one non-`.planning/` path), filtering `.planning/` out of every pick with zero real conflicts, then collapsed to one `feat!:` commit (`244f5809`) with an ID-free subject and body and a `BREAKING CHANGE:` footer. Verified: tree-equal to `milestone/v1.42` outside `.planning/`, zero `.planning/` paths in the diff against `origin/main`, exactly 1 commit, zero ID-pattern matches in the message.
- Ran `mix ci.all` on `land/v1.42` in place: exit 0, 130+2207 tests/0 failures, Dialyzer 0 errors, browser 318 passed/26 skipped/0 failed.
- Restored the checkout to `milestone/v1.42`; popped the stashed `.planning/config.json` change and confirmed it is byte-identical (via `cmp`) to the backup taken before this plan started; confirmed `.tool-versions` is present and untracked.
- Wrote `.planning/phases/213-upgrade-guide-and-0-11-0-release/213-PR-BODY.md` (#49-style: what adopters get, breaking changes/required action, security note, upgrade guide pointer, a "Repository and quality work" list, commit-count/filter note, Claude Code attribution line) and marked `REL-03`'s traceability row `Pending (maintainer action: push, merge, publish)` in `REQUIREMENTS.md`, checkbox left unchecked.

## Task Commits

1. **Task 1 (tracer): date the 0.11.0 entry and prove the release-shape chain end to end** — `1205f1f7` (docs)
2. **Task 2: run and record the full local pre-land gate list** — no commit (verification-only task; its only listed file, the browser-lane scorecards, is written by the run and restored with `git checkout --`, never committed, per the plan's own instruction)
3. **Task 3: build, verify and leave a local landing branch; restore the checkout; record the hand-off** — committed together with this SUMMARY (docs)

## Gate Table (Task 2, final milestone tree, `milestone/v1.42` @ `1205f1f7`)

| Gate | Command | Exit | Key result |
|------|---------|------|------------|
| origin sync | `git fetch origin && git rev-list --count HEAD..origin/main` | — | `0` (in sync) |
| ci.all | `mix ci.all` | 0 | 130 tests/0 failures; `9 properties, 2207 tests, 0 failures, 2 excluded`; Dialyzer `Total errors: 0`; browser `318 passed / 26 skipped` |
| verify.release | `mix verify.release` (config.json stashed and popped around it) | 0 | package built, tree byte-identical after; config.json diff identical pre/post |
| bump_rehearsal (final tree) | `mix verify.bump_rehearsal` | 0 | no `synthesising` line |
| release.pins --check | `mix release.pins --check` | 0 | `0 pin site(s) differ` |
| docs | `MIX_ENV=dev mix docs --warnings-as-errors` | 0 | html/markdown/epub generated, no warnings |
| hex.build | `mix hex.build` | 0 | package built; untracked `.tar` deleted after (per plan step 6) |
| doc contracts | `mix test test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/upgrading_to_0_11_doc_contract_test.exs` | 0 | 37 tests, 0 failures |
| PgBouncer topology | `mix verify.topology` @ port 6432 | 0 | `9 properties, 2207 tests, 0 failures, 2214 excluded` (2 tagged tests ran) |
| PgBouncer threadline lane | `mix verify.threadline` @ port 6432 | 0 | `0 gated error(s)` on the expected canary table; documented not-gated/warning findings present as expected |
| hex_evaluator | `mix verify.hex_evaluator` | 0 | 19 tests, 0 failures |
| browser (unscoped) | `mix verify.example_browser` | 1 (expected) | `326 passed / 8 failed / 16 skipped` — exactly the four `operator-screenshot-regression.spec.ts` lines (:108, :115, :136, :145) on desktop-chromium and mobile-chromium; scorecards restored with `git checkout --` after |

Full logs: `/tmp/threadline-213-gates/*.log` and `*.exit` (machine-local, not committed).

## Landing Branch (Task 3)

- **Branch:** `land/v1.42` (local only)
- **Base:** `origin/main` @ `b37d7bd4`
- **Commit:** `244f580992a826b883c930b245b822a123835bc1` — `feat!: capture every primary-key shape, read it back exactly, and detect broken capture`
- **Built from:** 112 cherry-picked commits (of 215 non-merge commits between `origin/main` and `milestone/v1.42`), every `.planning/` path filtered out per commit, then collapsed with `git reset --soft origin/main` + one commit.
- **Verification, all passed:**
  - `git diff --quiet milestone/v1.42 land/v1.42 -- . ':(exclude).planning'` → tree-equal outside `.planning/`
  - `git diff --name-only origin/main land/v1.42 | grep -c '^\.planning/'` → `0`
  - `git rev-list --count origin/main..land/v1.42` → `1`
  - ID-pattern grep on the commit message (phase/plan/decision/requirement IDs) → `0` matches
  - `mix ci.all` on `land/v1.42` in place → exit 0, 130+2207 tests/0 failures, Dialyzer 0 errors, browser 318 passed/26 skipped/0 failed (log: `/tmp/threadline-213-landing/ci_all.log`)
- **Not pushed.** `git ls-remote --heads origin land/v1.42` prints nothing.
- **`land/v1.41`** (stale, pre-existing local branch) was left untouched, per the halt clause.

## Restore Verification

- `git branch --show-current` on `milestone/v1.42` after Restore.
- `diff <(git diff .planning/config.json) /tmp/threadline-213-landing/config.diff` — empty (identical).
- `cmp .planning/config.json /Users/<user>/.claude/jobs/77cf1bdd/tmp/config.json.pre213-03` — identical, byte-for-byte, to the backup taken before this plan's first write.
- `.tool-versions` present, `git ls-files .tool-versions` empty (untracked).
- `git status --porcelain --untracked-files=all` shows only ` M .planning/config.json` and `?? .tool-versions`.

## Maintainer Hand-Off

REL-03's post-merge truths (release-please proposing exactly 0.11.0, `main` CI green on the released SHA, no stray branches or open PRs) are **maintainer action, pending** — never marked verified by this plan. Run these in order, confirming each before the next:

1. **Push the branch.**
   ```
   git push -u origin land/v1.42
   ```
   (Use `land/v1.42:<name>` if you prefer a different remote name. A stale local `land/v1.41` also exists — leave it, or delete it yourself; this plan never touches it.)

2. **Open the PR.**
   ```
   gh pr create --base main --head land/v1.42 \
     --title "feat!: capture every primary-key shape, read it back exactly, and detect broken capture" \
     --body-file .planning/phases/213-upgrade-guide-and-0-11-0-release/213-PR-BODY.md
   ```

3. **Watch checks.**
   ```
   gh pr checks <N> --watch
   ```

4. **Squash-merge with an explicit subject/body** (so cherry-picked commit subjects never reach release-please's notes):
   ```
   gh pr merge <N> --squash --match-head-commit 244f580992a826b883c930b245b822a123835bc1 \
     --subject "feat!: capture every primary-key shape, read it back exactly, and detect broken capture (#<N>)" \
     --body "Land the v1.42 capture-correctness milestone: PK-agnostic capture, exact history/as-of key matching, and broken-capture detection, with a security fix and upgrade guide for 0.11.0."
   ```

5. **Inspect the release-please PR.**
   ```
   gh pr list --state open
   gh pr view <R> --json title,files
   ```
   Expect title `chore(main): release 0.11.0`. Then:
   ```
   gh pr diff <R> | grep -nE '\b[0-9]{3}-[0-9]{2}\b|Phase [0-9]|\bD-[0-9]{2,}\b'
   ```
   must print nothing. Then:
   ```
   gh pr checks <R> --watch
   ```

6. **Merge the release-please PR.**
   ```
   gh pr merge <R> --squash --match-head-commit <R head SHA>
   ```

7. **Find and approve the release run.**
   ```
   gh run list --workflow release.yml --limit 3
   gh api repos/szTheory/threadline/actions/runs/<run_id>/pending_deployments --jq '.[].environment.id'
   ```
   The release runbook's remembered value for the `production-hex` environment id is `20753768806` — re-verify it with the command above before using it, since this plan did not (no run exists yet to query). Then:
   ```
   gh api -X POST repos/szTheory/threadline/actions/runs/<run_id>/pending_deployments \
     -F 'environment_ids[]=<env_id>' -f state=approved -f comment='Publish 0.11.0'
   ```

8. **Confirm publish and smoke.**
   ```
   gh run watch <run_id>
   mix hex.info threadline
   ```
   Confirm the publish and smoke jobs succeeded and `hex.info` lists `0.11.0`.

9. **Merge the distribution-sync PR** once its checks are green:
   ```
   gh pr checks <S>
   gh pr merge <S> --squash --match-head-commit <S head SHA>
   ```

10. **Confirm main is clean.**
    ```
    gh run list --branch main --limit 5
    gh pr list --state open
    ```
    Expect the run list green on the released SHA and the open-PR list empty.

**Then close the loop:** report back the PR merge SHA, the release SHA, and the run IDs from steps 7-8 so `REL-03` can be marked verified.

### Stray-branch deletions (maintainer action; re-derived at execution time, 2026-09-26)

Re-derived via `git branch --list`, `git ls-remote --heads origin`, and `gh pr list --state open` immediately after Task 3. The branch set has moved since D-15 was written — `fix/branch-protection-after-ci`, `phase-200/hosted-checkpoint`, and any `release/sync-0.10.0-*` branch no longer exist on `origin`. Current stray branches:

- Local: `land/v1.41` — `git branch -D land/v1.41`
- Remote: `origin/release/sync-0.10.2-36085532676` — `git push origin --delete release/sync-0.10.2-36085532676`
- Remote: `origin/release-please--branches--main` — delete only *after* 0.11.0 is published (release-please reuses it): `git push origin --delete release-please--branches--main`
- The landing branch itself (`land/v1.42`, or whatever remote name step 1 used), if GitHub does not auto-delete it after the squash merge in step 4.

`gh pr list --state open --json number --jq length` printed `0` both before this task and after (unchanged — no PR opened by this plan).

### Finding for the maintainer (no fix made here)

`CONTRIBUTING.md` line 690 still says "The Release PR bumps `mix.exs`, `CHANGELOG.md`, **and** the adoption-pilot SSOT line together" — stale since the CHANGELOG split made `CHANGELOG.md` human-owned and `CHANGELOG-GENERATED.md` release-please's actual target. Worth a one-line fix in a future docs pass; out of this plan's file scope (`CHANGELOG.md`, `REQUIREMENTS.md`, `213-PR-BODY.md` only).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `for HASH in $VAR` word-split the wrong way under this environment's default shell**
- **Found during:** Task 3, computing the included-commit list
- **Issue:** The environment's Bash tool runs commands under `zsh`, not `bash`. An unquoted `for HASH in $ALL_COMMITS` (a multi-line command-substitution result) does not word-split on newlines under `zsh` the way it does under `bash` — `pr-branch.md` itself documents this exact hazard (#4109) for its own loops. The first attempt passed the entire 215-line commit list as a single argument to `git diff-tree`, which failed immediately with `fatal: failed to stat`.
- **Fix:** Rewrote the included-commit computation and the cherry-pick loop as standalone `#!/bin/bash` scripts (`/tmp/threadline-213-landing/compute_included.sh`, `build_branch.sh`) invoked explicitly with `bash <script>`, using `while IFS= read -r` line-at-a-time iteration instead of an unquoted `for`, and ran them backgrounded with output redirected to a log, polled to completion.
- **Files modified:** none (scratch scripts under `/tmp/`, not part of this plan's tracked output)
- **Impact:** No change to the landing branch's content or verification — same 112-commit inclusion set the plan's own rule would have produced correctly under `bash`.

**2. [Rule 3 - Blocking] The commit ledger for `actuals.commits` was first written against the wrong base**
- **Found during:** writing this SUMMARY's `actuals` block
- **Issue:** The git-dir sentinel file (`gsd-plan-head-before-213-03`) was written from `STATE.md`'s `state_head` (`6887a21e`, the phase's last *test* commit) before confirming the actual pre-plan-03 `HEAD`, which was one commit later — `683a9ba9`, the 213-02 plan-metadata commit (visible in the initial `git status` snapshot's "Recent commits"). Left uncorrected, `actuals.commits` would have double-counted `683a9ba9` as this plan's own work.
- **Fix:** Overwrote the sentinel with `683a9ba9` before computing `git rev-list --count`, so `actuals.commits` reflects only this plan's own commits (Task 1's CHANGELOG commit + this closing commit).
- **Files modified:** none (the sentinel lives under `.git/`, not tracked)

**3. [Process, no rule] One supervisor-flagged idle gap during Task 3**
- **Found during:** between computing the included-commit list (first, failed attempt above) and resuming with the corrected script
- **Issue:** The orchestrator observed roughly 50 minutes of no forward progress with `.planning/config.json` still stashed and `land/v1.42` not yet built, and sent an explicit resume instruction. The state on disk at that point matched exactly what is recorded above (all Task 2 gates already exited 0, browser lane already at its expected 8-failure result, stash still present, branch still `milestone/v1.42`, no stray `mix` processes) — nothing was lost or needed re-running; work resumed directly into Task 3's landing-branch build per the resume instruction's own steps 1-7.
- **Fix:** N/A — no plan content changed as a result; recorded here for the audit trail per the coordinator's explicit request to report it.

---

**Total deviations:** 2 auto-fixed (both Rule 3 blocking, both process/tooling, no product or plan-content change), 1 process note (idle gap, no content change).
**Impact on plan:** None on the plan's deliverables — the landing branch's commit set, gate results, and hand-off content are identical to what the plan specified; the deviations were entirely in *how* two intermediate computations were run.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None — no external service configuration required. The maintainer hand-off above is the next human action, not a setup step.

## Next Phase Readiness

- REL-03 stays **Pending (maintainer action: push, merge, publish)** in `REQUIREMENTS.md`; it is marked verified only after the maintainer reports the merge SHA, release SHA, and run IDs from the hand-off above.
- The v1.42 milestone's local half is complete: every D-11 gate is green on the final tree, `land/v1.42` exists locally with `ci.all` green on it, and the maintainer has one exact ordered command list to publish 0.11.0.
- No remote state changed: `land/v1.42` does not exist on `origin`; the open-PR list is unchanged (`0` before and after).

---
*Phase: 213-upgrade-guide-and-0-11-0-release*
*Completed: 2026-09-26*

## Self-Check: PASSED

- `CHANGELOG.md` contains `## [0.11.0] - 2026-09-26`: confirmed (`grep -n '^## \[0.11.0\]' CHANGELOG.md` → line 29).
- `.planning/phases/213-upgrade-guide-and-0-11-0-release/213-PR-BODY.md` exists and ends with the Claude Code attribution line: confirmed.
- `.planning/REQUIREMENTS.md` REL-03 row reads `Pending (maintainer action: push, merge, publish)`: confirmed.
- Task 1 commit `1205f1f7` exists on `milestone/v1.42`: confirmed (`git log --oneline -3`).
- Landing branch `land/v1.42` @ `244f5809` exists locally, one commit ahead of `origin/main`, `ci.all` exit 0 on it: confirmed.
- `git ls-remote --heads origin land/v1.42` prints nothing (never pushed): confirmed.
- Checkout ended on `milestone/v1.42` with `.planning/config.json` byte-identical to the pre-plan backup and `.tool-versions` untracked: confirmed via `cmp` and `git status --porcelain`.

## Post-review rebuild

After the code review (213-REVIEW.md: 0 critical, 2 warning, 2 info), fix commits 0fa38e63 (frozen 0.10.2 per-table function fixture) and d538f708 (CONTRIBUTING release-PR bump target) landed on milestone/v1.42. `land/v1.42` was rebuilt from `origin/main` as the same single `feat!:` commit, now `244f580992a826b883c930b245b822a123835bc1` (replaces 9629f84a). Tree equals milestone/v1.42 outside `.planning/`, 0 `.planning/` paths, 1 commit ahead of origin/main. `mix ci.all` on it: exit 0; browser 317 passed + 1 flaky (known `operator-motion.spec.ts:323` mobile toast flake, passed on retry) / 26 skipped / 0 failed. config.json restored and verified with `cmp`. The hand-off above uses the new SHA.
