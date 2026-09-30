# Phase 216 evidence

## Release Please action v5 rehearsal (pre-landing)

- **Date:** 2026-09-26
- **origin/main SHA:** `5e78b2f05d00619e11aa9b29bc8f612087756846`
- **Version mapping (library bundled by each action release):**
  - `googleapis/release-please-action` v4.4.1 → `release-please` 17.3.0
  - `googleapis/release-please-action` v5.0.0 → `release-please` 17.6.0
- **Environment:** `npm_config_ignore_scripts=true`, node v22, one-shot `npx` (never added to a manifest), `--dry-run` only.

Command (run from the repo root; the token is passed only as `$(gh auth token)` and never written anywhere):

```bash
export npm_config_ignore_scripts=true
for v in 17.3.0 17.6.0; do
  npx -y release-please@$v release-pr \
    --repo-url=szTheory/threadline --token="$(gh auth token)" --target-branch=main \
    --config-file=release-please-config.json --manifest-file=.release-please-manifest.json \
    --dry-run 2>&1 | sed "s/\x1b\[[0-9;]*m//g" | grep -v "^npm warn" > /tmp/rp-$v.log
done
diff /tmp/rp-17.3.0.log /tmp/rp-17.6.0.log && echo IDENTICAL
```

**Result:** `IDENTICAL` (both logs 32 lines, `diff` exit 0).

Key lines of the 17.6.0 log (identical in the 17.3.0 log):

```
❯ Fetching release-please-config.json from branch main
❯ Fetching .release-please-manifest.json from branch main
❯ .: elixir
❯ Found release for path ., v0.11.0
❯ release for path: ., version: 0.11.0, sha: 8312290d6d2cc2dd080badd42f011d6315619c9b
✔ Considering: 2 commits
✔ No user facing commits found since 8312290d6d2cc2dd080badd42f011d6315619c9b - skipping
Would open 0 pull requests
```

**Limitation:** the dry-run reads origin's `main`, so it rehearses config and manifest parsing and
commit analysis on published history, not the unpushed milestone commits. The live proof is the
first post-landing Release run, which executes `release-please-action@v5` for real.

## Pre-push negative controls

Recorded by plan 216-06 Task 1 on 2026-09-26/27, before the maintainer push gate.

### Recipe proven on the drifted pre-phase main run

- **Run:** `36258719902` (pre-phase `main`, https://github.com/szTheory/threadline/actions/runs/36258719902)
- **Capture:** `bash -c 'gh run view 36258719902 --log | perl -pe "s/\e\[[0-9;]*m//g" > /tmp/ci-baseline.log'` (20074 lines)
- **Min-job filter:** `perl -ne 's/\e\[[0-9;]*m//g; print if /^Run test suite \(min\)\t/' /tmp/ci-baseline.log > /tmp/ci-baseline-min.log` (5045 lines, non-empty)

(a) Unique `Installing Erlang/OTP` lines (count, line):

```
   1 Installing Erlang/OTP OTP-26.2.5.21 - built on amd64/ubuntu-22.04
  12 Installing Erlang/OTP OTP-27.0.1 - built on amd64/ubuntu-24.04
   1 Installing Erlang/OTP OTP-27.3.4.18 - built on amd64/ubuntu-24.04
```

(b) Unique `Installing Elixir` lines:

```
   1 Installing Elixir v1.15.8-otp-26
  13 Installing Elixir v1.17.3-otp-27
```

(c) `Node.js 20 is deprecated` count: **12**. Sample:

```
Run Credo (strict)	Complete job	2026-09-26T17:22:32.9570384Z ##[warning]Node.js 20 is deprecated. The following actions target Node.js 20 but are being forced to run on Node.js 24: actions/cache@v4. ...
```

(d) Min-job log lines (`Run test suite (min)` job only):

```
Run test suite (min)	Set up job	2026-09-26T17:21:14.9564891Z Image: ubuntu-22.04
Run test suite (min)	Run erlef/setup-beam@v1	2026-09-26T17:21:39.2983917Z ##[group]Installing Erlang/OTP OTP-26.2.5.21 - built on amd64/ubuntu-22.04
Run test suite (min)	Compile (warnings as errors)	2026-09-26T17:22:24.8120014Z Downloading precompiled NIF to /home/runner/.cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.12.tar.gz
```

Zero `from source` lines in the min-job log.

Post-push check verdicts this recipe would give run 36258719902:

- otp-pin: would FAIL (`OTP-27.0.1` in 12 jobs; min lane OTP built on `amd64/ubuntu-22.04`; current lane `OTP-27.3.4.18` instead of the pinned `27.3.4.15`)
- min-image: would FAIL (`Set up job` shows `Image: ubuntu-22.04`)
- nif-download: would FAIL (artifact is `lazy_html-nif-2.16-x86_64-linux-gnu-0.1.12.tar.gz`, not the locked `0.1.13`)
- node20: would FAIL (12 lines)

- CONTROL OK: recipe detects the pre-phase drift

### Local gate on HEAD

- `bash -c 'mix ci.all'`: exit 0 in 2131 s (about 35.5 min), with no Dialyzer PLT rebuild needed. Key lines:
  - `9 properties, 2317 tests, 0 failures, 2 excluded`
  - `130 tests, 0 failures`
  - `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`
  - `done (passed successfully)`
  - Browser lane (CI=true): `316 passed`, `2 flaky`, `26 skipped`, 0 failed. The 2 flaky tests failed on the first attempt (a mobile-chromium timeout, and a context teardown timeout) and passed on retry, so the lane finished at 318/0/26 as designed. Flaky tests:
    `[mobile-chromium] operator-component-contracts.spec.ts:161` and `[mobile-chromium] operator-phase-175-uat.spec.ts:170`.
- `mix test` (standalone): exit 0, `9 properties, 2317 tests, 0 failures, 2 excluded`, `Finished in 168.1 seconds` (1380 s wall clock including setup)
- `actionlint -shellcheck=`: exit 0, no findings.

### Push-readiness brief

- **Branch:** `milestone/v1.43`
- **HEAD:** `2e27d9cda086fb2d634c612bb1918e937cd3a503`
- **origin/main:** `5e78b2f05d00619e11aa9b29bc8f612087756846` (fetched 2026-09-26)
- **Commits ahead of origin/main:** 321 (this count includes `.planning/` commits and earlier milestone history)
- **Release Please bump commit:** `21bb7e1bbdc395826ca2510edbd6846d99378059`
  `ci(release): move Release Please to the Node 24 action major`, `git show --numstat`:

  ```
  1	1	.github/workflows/release.yml
  ```

- **Phase 216 product commits** (`git log --format='%h %s' origin/main..HEAD -- .github .tool-versions test bin CONTRIBUTING.md`, limited to this phase):

  ```
  4a8514d6 docs(release): document the Release Please action upgrade rehearsal
  060cf713 ci(actions): fail closed on any workflow action not verified for Node 24
  702d3d5f ci(actions): move cache and upload-artifact to their Node 24 majors
  21bb7e1b ci(release): move Release Please to the Node 24 action major
  0ed0a5c5 ci(toolchain): install the committed toolchain in the browser and scheduled workflows
  8b4a4858 ci(release): read the toolchain pin from the workflow commit in release jobs
  7a7e93ee test(ci): forbid the deprecated runner image and the OS-family cache key in ci.yml
  6f7d40ca ci(toolchain): pin the test matrix strictly and run the min lane on ubuntu-24.04
  ddb0c771 ci(toolchain): install the committed toolchain in every non-matrix CI job
  8642610e ci(toolchain): track .tool-versions and read it in the format job
  ```

- **CI trigger note:** `ci.yml` runs on `push` to main and `pull_request` to main only, so the pushed branch gets a CI run once a PR targets main.
- **Landing shape (OD-2):** the maintainer decides: push `milestone/v1.43` (this publishes its `.planning/` history), or push a filtered branch without `.planning/` (`/gsd-pr-branch`). Milestone tags stay local either way. A squash landing folds the Release Please commit into one commit on main. The standalone commit then survives only on the milestone branch (SHA above), which is what the criterion inspects.

## Post-push CI evidence

Recorded by plan 216-06 Task 3 on 2026-09-27, after the maintainer push gate.

- **Push gate:** cleared by the maintainer's own direct grant in-session. Landing shape (the maintainer's
  call, OD-2): filtered branch `land/v1.43-215-216` (29 commits from phases 215 and 216, zero `.planning/`
  paths; tree identical to `milestone/v1.43` outside `.planning/`). The Release Please bump kept its own
  one-line commit on that branch: `4dc227bf` (numstat `1	1	.github/workflows/release.yml`; the milestone
  equivalent is `21bb7e1b`).
- **PR:** #55 (https://github.com/szTheory/threadline/pull/55), head `1b1e82993421cd3a5e35ccd8b9f671aec092a624`
  (`gh pr view 55 --json headRefOid`).
- **Precondition (filtered branch):** the tree of the head branch has `uses: googleapis/release-please-action@v5`
  at `.github/workflows/release.yml:95` (`git show origin/land/v1.43-215-216:.github/workflows/release.yml`).
- **Run:** `36318716184` (https://github.com/szTheory/threadline/actions/runs/36318716184), event
  `pull_request`, head `1b1e8299`, status `completed`, conclusion `success` (17/17 jobs success)
- **Capture:** `bash -c 'gh run view 36318716184 --log | perl -pe "s/\e\[[0-9;]*m//g" > /tmp/ci-post.log'`
  (20650 lines). Min-job filter (same as the control): `/tmp/ci-post-min.log` 5081 lines,
  `/tmp/ci-post-rest.log` 15569 lines.

- PASS otp-pin: rest-of-run `14 Installing Erlang/OTP OTP-27.3.4.15 - built on amd64/ubuntu-24.04` (only unique line); min job `1 Installing Erlang/OTP OTP-26.2.5.21 - built on amd64/ubuntu-24.04` (only unique line); `OTP-27.0.1` count 0; `amd64/ubuntu-22.04` count 0
- PASS elixir-pin: unique lines are exactly `Installing Elixir v1.15.8-otp-26` (1) and `Installing Elixir v1.17.3-otp-27` (14)
- PASS min-image: `Run test suite (min)	Set up job	2026-09-27T12:22:20.7522203Z Image: ubuntu-24.04`
- PASS nif-download: `Run test suite (min)	Compile (warnings as errors)	2026-09-27T12:23:30.9906977Z Downloading precompiled NIF to /home/runner/.cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.13.tar.gz`
- PASS nif-no-source-compile: `grep -ci 'compile lazy_html from source' /tmp/ci-post-min.log` = 0 (and `grep -ci 'from source'` = 0)
- PASS node20: `grep -c 'Node.js 20 is deprecated' /tmp/ci-post.log` = 0 (the control run had 12)
- PASS conclusion: run concluded `success`; `CI required` job `success` (alls-green `outcome=success;conclusion=success`)

Information, not a check: the cold-cache marker `THREADLINE_DIALYZER_PLT_CACHE=miss` appears twice, as
expected for the first run on the new cache key shapes.

## Post-landing Release evidence

Recorded by plan 216-07 on 2026-09-27. The Task 1 tracer control was run read-only against the historical
run. The landing gate (Task 2) had already been cleared by the maintainer's own direct grant before this
section was written. The landing brief below is therefore a factual record of what the maintainer chose,
not a pre-merge ask.

### Control

- **Run:** `36258719890` (pre-phase Release, `push` to main, head `5e78b2f05d00619e11aa9b29bc8f612087756846`,
  conclusion `success`, https://github.com/szTheory/threadline/actions/runs/36258719890)
- **Capture:** `bash -c 'gh run view 36258719890 --log | perl -pe "s/\e\[[0-9;]*m//g" > /tmp/release-baseline.log'` (250 lines)
- **Job list:** only `Release Please` ran (success). Every other job was skipped, including `Sync install pins on Release PR`: that run opened no release PR.
- **Action download line:**

  ```
  Release Please	UNKNOWN STEP	2026-09-26T17:21:15.3728517Z Download action repository 'googleapis/release-please-action@v4' (SHA:5c625bfb5d1ff62eadeeb3772007f7f66fdcf071)
  ```

- **`Node.js 20 is deprecated` count:** 1

  ```
  ##[warning]Node.js 20 is deprecated. The following actions target Node.js 20 but are being forced to run on Node.js 24: googleapis/release-please-action@v4. ...
  ```

- Verdicts this recipe gives the control run: release-action-v5 would FAIL (`@v4` download line), release-node20 would FAIL (1 line).

- CONTROL OK: recipe distinguishes the v4 action

### Landing brief

- **PR:** #55 (https://github.com/szTheory/threadline/pull/55), head `1b1e82993421cd3a5e35ccd8b9f671aec092a624`,
  `CI required` = `SUCCESS` (run `36318716184`, 17/17).
- **Merge method consequences (OD-2):**
  - merge commit or rebase: the one-line Release Please commit stays a separate commit on main.
  - squash: the Release Please commit is folded into the single squash commit on main. The standalone commit remains on the landing branch as `4dc227bfa821dbaca345d9e60a0325139ad24972` (numstat `1	1	.github/workflows/release.yml`) and on the milestone branch as `21bb7e1bbdc395826ca2510edbd6846d99378059`.
- **Maintainer's decision:** squash, run by the orchestrator under the maintainer's own direct grant. It merged at `2026-09-27T12:34:16Z` as `ff346b1ab0b9c33c68884874d3cdc74fd1f269f0`. The release PR, its merge and the `production-hex` approval stayed with the maintainer (see `### Publish follow-through`).

### Initial landing ff346b1a (Release failed; gap closed by 216-08)

This is the first landing SHA (PR #55's `mergeCommit`). Its Release run failed. The failure is recorded
here as it happened. It is the gap that plan 216-08 closed; see `## Post-landing regression (sparse checkout)`.

- **Release:** `36319430805` (https://github.com/szTheory/threadline/actions/runs/36319430805), conclusion `failure`
- **CI push:** `36319430827` (https://github.com/szTheory/threadline/actions/runs/36319430827), conclusion `success`
- **Browser-full push:** `36319430799` (https://github.com/szTheory/threadline/actions/runs/36319430799), conclusion `success`

- PASS release-action-v5: `Download action repository 'googleapis/release-please-action@v5' (SHA:45996ed1f6d02564a971a2fa1b5860e934307cf7)`, no `@v4` line
- PASS release-node20: 0 `Node.js 20 is deprecated` lines
- FAIL release-conclusion: run concluded `failure` (`Sync install pins on Release PR=failure`)
- FAIL sync-pins: the job ran (release-please created branch `release-please--branches--main` for release PR #56) and installed `OTP-27.3.4.15` / `Elixir v1.17.3-otp-27` on `Image: ubuntu-24.04`, but `Fetch dependencies` failed with `** (Mix) Could not find a Mix.Project`: sparse config survived into the root checkout on git 2.55.0
- PASS main-ci-otp: min job `1 Installing Erlang/OTP OTP-26.2.5.21 - built on amd64/ubuntu-24.04`; rest `14 Installing Erlang/OTP OTP-27.3.4.15 - built on amd64/ubuntu-24.04`; conclusion `success`
- PASS main-node20: 0 lines in CI and Browser-full logs
- PASS browser-full-otp: `Installing Erlang/OTP OTP-27.3.4.15 - built on amd64/ubuntu-24.04`, conclusion `success`

### Landing 3d8ab205

This is the gap-closure landing: PR #57, squash `3d8ab205415628e6e3fbb74834247639117ec920`, merged
`2026-09-27T12:57:46Z` on top of `ff346b1a`. It is the first main SHA that carries the whole phase
including the 216-08 fix. The seven checks below come from its runs, captured through the perl ANSI strip into
`/tmp/release-post.log`, `/tmp/ci-main.log` and `/tmp/browser-main.log`.

- **Release:** `36320746183` (https://github.com/szTheory/threadline/actions/runs/36320746183), `push`, conclusion `success` (860 log lines)
- **CI push:** `36320746124` (https://github.com/szTheory/threadline/actions/runs/36320746124), conclusion `success` (19968 log lines)
- **Browser-full push:** `36320746147` (https://github.com/szTheory/threadline/actions/runs/36320746147), conclusion `success` (1484 log lines)

- PASS release-action-v5: `Download action repository 'googleapis/release-please-action@v5' (SHA:45996ed1f6d02564a971a2fa1b5860e934307cf7)`; zero `release-please-action@v4` lines
- PASS release-node20: `grep -c 'Node.js 20 is deprecated' /tmp/release-post.log` = 0
- PASS release-conclusion: `success` (jobs: `Release Please=success`, `Sync install pins on Release PR=success`, `Bootstrap CI on Release PR=success`, the publish chain skipped because no release was cut on this SHA)
- PASS sync-pins: release-please `found 1 open release pull requests` and updated release PR #56 (`chore(main): release 0.11.1`, 0.11.0 → 0.11.1). `Sync install pins on Release PR` succeeded:
  - Toolchain checkout step: `Run actions/checkout@v5` with `path: .toolchain-pin`, `sparse-checkout: .tool-versions`, `persist-credentials: false`, and `git version 2.55.0`.
  - setup-beam read `version-file: .toolchain-pin/.tool-versions`, then `Installing Erlang/OTP OTP-27.3.4.15 - built on amd64/ubuntu-24.04` and `Installing Elixir v1.17.3-otp-27`.
  - The root checkout fetched `release-please--branches--main`, and `mix deps.get`, `mix release.pins`, `mix release.pins --check` and the push step all ran.
  - Release PR #56 file list (`gh pr view 56 --json files`): `.release-please-manifest.json`, `CHANGELOG-GENERATED.md`, `guides/adoption-pilot-backlog.md`, `guides/evaluating-threadline.md`, `mix.exs`.
- PASS main-ci-otp: min job `1 Installing Erlang/OTP OTP-26.2.5.21 - built on amd64/ubuntu-24.04`; all other jobs `14 Installing Erlang/OTP OTP-27.3.4.15 - built on amd64/ubuntu-24.04`; `OTP-27.0.1` = 0, `amd64/ubuntu-22.04` = 0; Elixir lines only `v1.15.8-otp-26` (1) and `v1.17.3-otp-27` (14); conclusion `success`
- PASS main-node20: 0 `Node.js 20 is deprecated` lines in `/tmp/ci-main.log` and 0 in `/tmp/browser-main.log`
- PASS browser-full-otp: `Installing Erlang/OTP OTP-27.3.4.15 - built on amd64/ubuntu-24.04` (only OTP line), `Installing Elixir v1.17.3-otp-27`; conclusion `success` (no screenshot failures to record on this run)

### Publish follow-through (information, not a check)

The maintainer took each of these steps, or granted them in their own words:
- PR #58 (`6f07e21b`) added the dated `## [0.11.1] - 2026-09-27` CHANGELOG entry.
- Release PR #56 was rebased onto main and squash-merged as `2a75a795` at `2026-09-27T13:47:03Z`.
- The maintainer approved `production-hex`.

- **Release `36323594205`** on `2a75a795` (https://github.com/szTheory/threadline/actions/runs/36323594205): conclusion `success`.
  - `Release Please`, `Select release ref`, `Verify CI is green on release SHA`, `Publish to Hex.pm`, `Smoke test the published release (threadline from hex.pm)` and `Post-publish distribution sync` all succeeded.
  - `release-please-action@v5` download line present, 0 `Node.js 20 is deprecated` lines.
  - `Publish to Hex.pm` and the smoke job each installed `Erlang/OTP OTP-27.3.4.15` and `Elixir v1.17.3-otp-27`, which proves the `.toolchain-pin` isolation in `publish-hex` and `smoke-published`.
- CI `36323594152` and Browser-full `36323594181` on `2a75a795`: both `success`, same OTP lines as above, 0 Node 20 lines. The same holds for CI `36322796103` and Browser-full `36322796095` on `6f07e21b` (both `success`).
- hex.pm `latest_stable_version` = `0.11.1` (GET https://hex.pm/api/packages/threadline).
- Distribution sync PR #59 (`release/sync-0.11.1-36323594205`) is open and left for the maintainer.

## Post-landing regression (sparse checkout)

Found after PR #55 landed (merge `ff346b1a`); closed by plan 216-08.

- **Failure:** main Release run `36319430805`, job `Sync install pins on Release PR`, step `Fetch dependencies` (`mix deps.get`):

  ```
  ** (Mix) Could not find a Mix.Project, please ensure you are running Mix in a directory with a mix.exs file
  ##[error]Process completed with exit code 1.
  ```

  The runner's post-job cleanup logs `git version 2.55.0`.
- **Root cause:** plan 216-03 read the pin through a sparse, non-cone checkout (`sparse-checkout: .tool-versions`, `sparse-checkout-cone-mode: false`) at the workspace root. The target-ref checkout then reused that repository. In the non-cone path, actions/checkout turns sparse mode on through plain config (`core.sparseCheckout=true` plus an `info/sparse-checkout` file). On git 2.55, `git sparse-checkout disable` leaves both in place when sparse was enabled that way, so the release-branch checkout produced a tree holding only `.tool-versions`. Plan 03's assumption A2 (the second checkout disables sparse mode) did not hold on the runner's git. `publish-hex` and `smoke-published` had the same shape and would have failed at publish time.
- **Reproduction (Docker `alpine:edge`, `git version 2.55.0`):** the actions/checkout command sequence run against a local copy of the repository:
  - Before (shared root repository, then `git sparse-checkout disable` and the release-branch checkout): `mix.exs? NO`, and `core.sparseCheckout=true` with the `.tool-versions`-only sparse file still present.
  - With the path fix (pin checkout in `.toolchain-pin`, then the root checkout, which actions/checkout v5 empties first because the root has no `.git`): `mix.exs? yes; pin dir left? no; sparse=unset`.
- **Fix:** in all three jobs the toolchain checkout writes into `path: .toolchain-pin`, and setup-beam reads `version-file: .toolchain-pin/.tool-versions` (`version-type: strict`, `id: beam`). The target-ref checkout is unchanged and still checks out at the workspace root. The toolchain contract (`toolchain_source_errors/3`) now requires a `path:` on a pin checkout that differs from a later `ref:` checkout's path, and a setup-beam `version-file` under that path. Two new mutation controls fail on (a) a pathless pin checkout (the run `36319430805` shape) and (b) a root `version-file` with the pin in `.toolchain-pin`.
