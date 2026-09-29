# Phase 214 CI baseline (BASE-01)

This is the re-measured CI baseline. Later phases measure their deltas against it
(ECON-07 and SCOPE-01). Every figure below reproduces from the
committed raw data under `raw/ci/` with the committed command printed next to it.

## 0. Method

**Measured:** 2026-09-26 (UTC). Raw data fetched by `bash .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh --workflow ci.yml --event pull_request`; each manifest entry records its own fetch time (`jq '.entries[].fetched_at_utc' .planning/phases/214-baseline-measurement/raw/ci/manifest.json`).

**Code under measurement:** origin/main at 5e78b2f05d00619e11aa9b29bc8f612087756846 (`git rev-parse origin/main` after `git fetch origin main`).

**Sample selection.** For each workflow and event, the collector runs `gh run list --repo szTheory/threadline --workflow <file> --event <event> --status success --limit 200` and keeps the most recent 20 runs (`--target 20`, and it refuses fewer than `--min 10`). Only completed, successful runs are duration samples. `workflow_dispatch` runs are collected under their own manifest key and never enter the `pull_request` or `push` samples. Each run is counted once, at its latest attempt: the jobs come from `gh api repos/szTheory/threadline/actions/runs/<id>/jobs`, which returns the latest attempt. The exact list command and the selected run IDs are in the manifest (`jq '.entries' .planning/phases/214-baseline-measurement/raw/ci/manifest.json`).

The push sample reaches further back than the PR sample, because many push runs in between were red: it spans 2026-06-03 to 2026-09-26, the PR sample 2026-09-13 to 2026-09-26 (`jq -r '.created_at' .planning/phases/214-baseline-measurement/raw/ci/runs/*.json`). Old push runs predate some jobs, so those jobs have fewer samples; each row states its own n.

**Job duration** is the job's `completed_at` minus its `started_at`, in integer seconds. Queue time before a runner picks the job up is excluded. Only jobs whose conclusion is `success` count as samples.

**Percentiles** are nearest-rank on integer seconds: samples are sorted by (seconds, run ID) ascending and the value at rank ceil(q × n), 1-indexed, is reported, together with the run ID it came from (`python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py --help`). With n = 10 the p95 is the maximum; with n = 20 it is the 19th sample (`python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py --help`). A job with no successful sample prints `n=0 — not measured`, never 0 s. Rows are ordered by job id, then job name, so re-running the summarizer on the same raw data gives byte-identical output.

**Runner-minutes** are reported two ways, each labelled: *unrounded* is the sum of job seconds divided by 60, to one decimal; *billed* is the sum of each job's seconds rounded up to a whole minute, which is how GitHub bills a hosted job (`python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py --help`).

**Research numbers.** Figures carried from `.planning/research/FEATURES.md` without re-measurement carry a `[research]` label and the research run ID. Estimates and projections carry an `[inference]` label and cite their inputs.

**Citation convention.** Every non-heading line outside a code fence that still contains a digit after dates, p50/p95, requirement IDs, phase numbers, SHAs and version strings are removed must carry either `run <id>` (an 8+ digit GitHub Actions run ID) or a backticked command starting with gh, mix, MIX_ENV=, git, python3, bash, jq, psql or elixir. The checker enforces this and proves it goes red on an uncited fixture: `python3 .planning/phases/214-baseline-measurement/tools/check-citations.py .planning/phases/214-baseline-measurement/214-BASELINE.md` (self-test: `python3 .planning/phases/214-baseline-measurement/tools/check-citations.py --self-test`).

## 1. Per-job duration (ci.yml)

Each row is pasted verbatim from `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event <event> --min 10 --format md`; the last column regenerates that row alone. Both events exit 0 at `--min 10`, so every job has at least ten successful samples (`python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --min 10 --format md`).

Two push runs in the sample predate the min/current lane matrix and report the test job under the legacy name "Run test suite" (run 26899776964, run 27082029121). The current ci.yml cannot produce that name, so it has no row; those two runs still count toward every other job and toward wall clock. `ci-required` is the aggregate check, listed for completeness.

### 1a. pull_request

| Job id | Job name | Event | n | p50 | p95 | min–max | Regenerate |
|---|---|---|---|---|---|---|---|
| ci-required | CI required | pull_request | n=20 | p50 4 s (run 35781240139) | p95 5 s (run 35788765371) | min–max 2–5 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "CI required" --format md` |
| verify-bump-rehearsal | Bump rehearsal (next minor) | pull_request | n=13 | p50 165 s (run 36255483521) | p95 171 s (run 36256339043) | min–max 122–171 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Bump rehearsal (next minor)" --format md` |
| verify-capture | Tier A capture lane (byte-stable evidence) | pull_request | n=20 | p50 532 s (run 36258071425) | p95 549 s (run 35800922940) | min–max 494–552 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Tier A capture lane (byte-stable evidence)" --format md` |
| verify-compile-no-optional | Compile without optional deps | pull_request | n=20 | p50 61 s (run 35793597110) | p95 63 s (run 35800922940) | min–max 46–65 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Compile without optional deps" --format md` |
| verify-credo | Run Credo (strict) | pull_request | n=20 | p50 70 s (run 34757305454) | p95 78 s (run 36084754688) | min–max 48–78 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Run Credo (strict)" --format md` |
| verify-dialyzer | Dialyzer (current toolchain) | pull_request | n=20 | p50 83 s (run 35800922940) | p95 221 s (run 35721615532) | min–max 62–226 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Dialyzer (current toolchain)" --format md` |
| verify-docs | Build ExDoc (dev) | pull_request | n=20 | p50 75 s (run 34755017258) | p95 80 s (run 35721615532) | min–max 60–180 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Build ExDoc (dev)" --format md` |
| verify-example-browser | Example app browser E2E (Playwright) | pull_request | n=20 | p50 623 s (run 36256339043) | p95 650 s (run 36255483521) | min–max 452–664 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Example app browser E2E (Playwright)" --format md` |
| verify-format | Check formatting | pull_request | n=20 | p50 17 s (run 35800922940) | p95 22 s (run 36086466934) | min–max 14–55 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Check formatting" --format md` |
| verify-hex-evaluator | Hex evaluator smoke (threadline from hex.pm) | pull_request | n=20 | p50 62 s (run 36086466934) | p95 68 s (run 36083676177) | min–max 55–77 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Hex evaluator smoke (threadline from hex.pm)" --format md` |
| verify-hex-package | Hex package tarball | pull_request | n=20 | p50 17 s (run 34758417725) | p95 21 s (run 35781240139) | min–max 14–22 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Hex package tarball" --format md` |
| verify-mechanical | Mechanical checker (committed scorecards) | pull_request | n=20 | p50 87 s (run 34755017258) | p95 92 s (run 35793597110) | min–max 74–93 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Mechanical checker (committed scorecards)" --format md` |
| verify-pgbouncer-topology | PgBouncer transaction topology | pull_request | n=20 | p50 109 s (run 36083676177) | p95 120 s (run 35763570382) | min–max 87–121 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "PgBouncer transaction topology" --format md` |
| verify-release-shape | Release metadata (version / changelog) | pull_request | n=20 | p50 6 s (run 35793597110) | p95 11 s (run 35763570382) | min–max 4–41 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Release metadata (version / changelog)" --format md` |
| verify-test | Run test suite (current) | pull_request | n=20 | p50 546 s (run 34755536474) | p95 610 s (run 36258071425) | min–max 464–623 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Run test suite (current)" --format md` |
| verify-test | Run test suite (min) | pull_request | n=20 | p50 395 s (run 35788765371) | p95 438 s (run 36258071425) | min–max 265–444 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Run test suite (min)" --format md` |

### 1b. push (to main)

| Job id | Job name | Event | n | p50 | p95 | min–max | Regenerate |
|---|---|---|---|---|---|---|---|
| ci-required | CI required | push | n=18 | p50 3 s (run 35801770602) | p95 5 s (run 36258719902) | min–max 2–5 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "CI required" --format md` |
| verify-bump-rehearsal | Bump rehearsal (next minor) | push | n=12 | p50 164 s (run 36258719902) | p95 197 s (run 35787338903) | min–max 130–197 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Bump rehearsal (next minor)" --format md` |
| verify-capture | Tier A capture lane (byte-stable evidence) | push | n=18 | p50 530 s (run 34758908342) | p95 548 s (run 36085532687) | min–max 411–548 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Tier A capture lane (byte-stable evidence)" --format md` |
| verify-compile-no-optional | Compile without optional deps | push | n=20 | p50 60 s (run 35780710013) | p95 68 s (run 34733180013) | min–max 44–169 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Compile without optional deps" --format md` |
| verify-credo | Run Credo (strict) | push | n=20 | p50 68 s (run 35789879500) | p95 79 s (run 34733180013) | min–max 47–80 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Run Credo (strict)" --format md` |
| verify-dialyzer | Dialyzer (current toolchain) | push | n=18 | p50 86 s (run 36087413569) | p95 242 s (run 34733180013) | min–max 64–242 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Dialyzer (current toolchain)" --format md` |
| verify-docs | Build ExDoc (dev) | push | n=20 | p50 75 s (run 35787338903) | p95 80 s (run 36257162368) | min–max 63–81 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Build ExDoc (dev)" --format md` |
| verify-example-browser | Example app browser E2E (Playwright) | push | n=20 | p50 629 s (run 34758908342) | p95 651 s (run 36258719902) | min–max 174–666 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Example app browser E2E (Playwright)" --format md` |
| verify-format | Check formatting | push | n=20 | p50 16 s (run 35793569116) | p95 22 s (run 35787338903) | min–max 13–22 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Check formatting" --format md` |
| verify-hex-evaluator | Hex evaluator smoke (threadline from hex.pm) | push | n=20 | p50 62 s (run 35789879500) | p95 73 s (run 35764881231) | min–max 54–75 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Hex evaluator smoke (threadline from hex.pm)" --format md` |
| verify-hex-package | Hex package tarball | push | n=20 | p50 16 s (run 34755997103) | p95 18 s (run 36085532687) | min–max 13–20 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Hex package tarball" --format md` |
| verify-mechanical | Mechanical checker (committed scorecards) | push | n=18 | p50 86 s (run 34756589365) | p95 91 s (run 35797666621) | min–max 81–91 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Mechanical checker (committed scorecards)" --format md` |
| verify-pgbouncer-topology | PgBouncer transaction topology | push | n=20 | p50 111 s (run 35764881231) | p95 125 s (run 36256231845) | min–max 97–151 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "PgBouncer transaction topology" --format md` |
| verify-release-shape | Release metadata (version / changelog) | push | n=20 | p50 6 s (run 35797666621) | p95 7 s (run 36257162368) | min–max 4–8 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Release metadata (version / changelog)" --format md` |
| verify-test | Run test suite (current) | push | n=18 | p50 574 s (run 34756589365) | p95 646 s (run 36257162368) | min–max 417–646 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Run test suite (current)" --format md` |
| verify-test | Run test suite (min) | push | n=18 | p50 387 s (run 34757804720) | p95 434 s (run 36258719902) | min–max 267–434 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event push --job "Run test suite (min)" --format md` |

### 1c. workflow_dispatch (release-PR bootstrap and manual dispatches, reported separately)

These runs are the Release workflow's "Bootstrap CI on Release PR" dispatches plus manual dispatches. They are never merged into the pull_request or push rows. Only the successful ones are samples, so n is small (`bash .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh --workflow ci.yml --event workflow_dispatch --min 1`).

| Job id | Job name | Event | n | p50 | p95 | min–max | Regenerate |
|---|---|---|---|---|---|---|---|
| ci-required | CI required | workflow_dispatch | n=4 | p50 4 s (run 35781265625) | p95 5 s (run 36084856985) | min–max 3–5 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "CI required" --format md` |
| verify-bump-rehearsal | Bump rehearsal (next minor) | workflow_dispatch | n=4 | p50 155 s (run 36084856985) | p95 162 s (run 36256344029) | min–max 127–162 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Bump rehearsal (next minor)" --format md` |
| verify-capture | Tier A capture lane (byte-stable evidence) | workflow_dispatch | n=4 | p50 413 s (run 35781265625) | p95 536 s (run 36084856985) | min–max 409–536 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Tier A capture lane (byte-stable evidence)" --format md` |
| verify-compile-no-optional | Compile without optional deps | workflow_dispatch | n=6 | p50 62 s (run 26895798481) | p95 65 s (run 36256344029) | min–max 45–65 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Compile without optional deps" --format md` |
| verify-credo | Run Credo (strict) | workflow_dispatch | n=6 | p50 72 s (run 26895798481) | p95 80 s (run 36084856985) | min–max 67–80 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Run Credo (strict)" --format md` |
| verify-dialyzer | Dialyzer (current toolchain) | workflow_dispatch | n=4 | p50 84 s (run 36084856985) | p95 124 s (run 36256344029) | min–max 84–124 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Dialyzer (current toolchain)" --format md` |
| verify-docs | Build ExDoc (dev) | workflow_dispatch | n=6 | p50 76 s (run 36084856985) | p95 79 s (run 35781265625) | min–max 75–79 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Build ExDoc (dev)" --format md` |
| verify-example-browser | Example app browser E2E (Playwright) | workflow_dispatch | n=6 | p50 521 s (run 35781265625) | p95 626 s (run 36256344029) | min–max 176–626 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Example app browser E2E (Playwright)" --format md` |
| verify-format | Check formatting | workflow_dispatch | n=6 | p50 15 s (run 36084856985) | p95 17 s (run 35793724408) | min–max 12–17 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Check formatting" --format md` |
| verify-hex-evaluator | Hex evaluator smoke (threadline from hex.pm) | workflow_dispatch | n=6 | p50 64 s (run 35781265625) | p95 68 s (run 35793724408) | min–max 57–68 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Hex evaluator smoke (threadline from hex.pm)" --format md` |
| verify-hex-package | Hex package tarball | workflow_dispatch | n=6 | p50 15 s (run 35781265625) | p95 19 s (run 35793724408) | min–max 14–19 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Hex package tarball" --format md` |
| verify-mechanical | Mechanical checker (committed scorecards) | workflow_dispatch | n=4 | p50 88 s (run 36256344029) | p95 92 s (run 35793724408) | min–max 87–92 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Mechanical checker (committed scorecards)" --format md` |
| verify-pgbouncer-topology | PgBouncer transaction topology | workflow_dispatch | n=6 | p50 106 s (run 26895798481) | p95 114 s (run 35781265625) | min–max 98–114 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "PgBouncer transaction topology" --format md` |
| verify-release-shape | Release metadata (version / changelog) | workflow_dispatch | n=6 | p50 6 s (run 26895798481) | p95 6 s (run 35793724408) | min–max 5–6 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Release metadata (version / changelog)" --format md` |
| verify-test | Run test suite (current) | workflow_dispatch | n=4 | p50 578 s (run 35793724408) | p95 623 s (run 36256344029) | min–max 490–623 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Run test suite (current)" --format md` |
| verify-test | Run test suite (min) | workflow_dispatch | n=4 | p50 391 s (run 35781265625) | p95 409 s (run 35793724408) | min–max 359–409 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event workflow_dispatch --job "Run test suite (min)" --format md` |

For comparison, research measured "Run test suite (current)" at 593–646 s over 7 samples [research: run 36258719902].

## 2. Wall clock and critical path

**Wall clock** of a run is its last job's `completed_at` minus its first job's `started_at` (skipped jobs excluded), so it includes the `ci-required` aggregate.

| Workflow | Event | n | p50 | p95 | min–max | Regenerate |
|---|---|---|---|---|---|---|
| ci.yml | pull_request | n=20 | p50 629 s (run 34758417725) | p95 659 s (run 36255483521) | min–max 535–669 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py wall --workflow ci.yml --event pull_request` |
| ci.yml | push | n=20 | p50 640 s (run 34755997103) | p95 672 s (run 35780710013) | min–max 245–680 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py wall --workflow ci.yml --event push` |
| ci.yml | workflow_dispatch | n=6 | p50 568 s (run 36084856985) | p95 632 s (run 36256344029) | min–max 245–632 s | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py wall --workflow ci.yml --event workflow_dispatch` |

The push minimum comes from the two pre-matrix runs from June (run 26899776964, run 27082029121); the dispatch minimum is the June pre-matrix run 26895798481 (`python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py wall --workflow ci.yml --event push`).

### 2a. Critical path

Per run, the job on the critical path is the voting job (every job except `ci-required`) with the latest `completed_at`; its end offset is measured from the run's first job start. Ties list both jobs. "Last to finish" counts the runs where that job finished last; the end-offset percentiles are across all sampled runs.

| Job id | Job name | Event | Last to finish | n | End offset p50 | End offset p95 | Regenerate |
|---|---|---|---|---|---|---|---|
| verify-bump-rehearsal | Bump rehearsal (next minor) | pull_request | last in 0 of 20 runs | n=13 | end offset p50 166 s (run 36255483521) | p95 171 s (run 36256339043) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-capture | Tier A capture lane (byte-stable evidence) | pull_request | last in 1 of 20 runs | n=20 | end offset p50 533 s (run 36258071425) | p95 553 s (run 35793597110) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-compile-no-optional | Compile without optional deps | pull_request | last in 0 of 20 runs | n=20 | end offset p50 61 s (run 36084754688) | p95 76 s (run 35781240139) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-credo | Run Credo (strict) | pull_request | last in 0 of 20 runs | n=20 | end offset p50 70 s (run 35788765371) | p95 79 s (run 36084754688) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-dialyzer | Dialyzer (current toolchain) | pull_request | last in 0 of 20 runs | n=20 | end offset p50 84 s (run 35788765371) | p95 221 s (run 35721615532) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-docs | Build ExDoc (dev) | pull_request | last in 0 of 20 runs | n=20 | end offset p50 75 s (run 34760918002) | p95 94 s (run 35781240139) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-example-browser | Example app browser E2E (Playwright) | pull_request | last in 16 of 20 runs | n=20 | end offset p50 623 s (run 36256339043) | p95 653 s (run 36255483521) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-format | Check formatting | pull_request | last in 0 of 20 runs | n=20 | end offset p50 18 s (run 35721615532) | p95 22 s (run 36086466934) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-hex-evaluator | Hex evaluator smoke (threadline from hex.pm) | pull_request | last in 0 of 20 runs | n=20 | end offset p50 64 s (run 36258071425) | p95 78 s (run 35763570382) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-hex-package | Hex package tarball | pull_request | last in 0 of 20 runs | n=20 | end offset p50 17 s (run 36255483521) | p95 23 s (run 35788765371) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-mechanical | Mechanical checker (committed scorecards) | pull_request | last in 0 of 20 runs | n=20 | end offset p50 87 s (run 34755017258) | p95 93 s (run 36258071425) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-pgbouncer-topology | PgBouncer transaction topology | pull_request | last in 0 of 20 runs | n=20 | end offset p50 109 s (run 36256339043) | p95 142 s (run 35792496570) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-release-shape | Release metadata (version / changelog) | pull_request | last in 0 of 20 runs | n=20 | end offset p50 6 s (run 36084754688) | p95 14 s (run 35763570382) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-test | Run test suite (current) | pull_request | last in 3 of 20 runs | n=20 | end offset p50 546 s (run 34755536474) | p95 610 s (run 36258071425) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-test | Run test suite (min) | pull_request | last in 0 of 20 runs | n=20 | end offset p50 395 s (run 35788765371) | p95 439 s (run 35781240139) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event pull_request` |
| verify-bump-rehearsal | Bump rehearsal (next minor) | push | last in 0 of 20 runs | n=12 | end offset p50 165 s (run 36258719902) | p95 201 s (run 36085532687) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-capture | Tier A capture lane (byte-stable evidence) | push | last in 1 of 20 runs | n=18 | end offset p50 532 s (run 34755997103) | p95 657 s (run 36087413569) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-compile-no-optional | Compile without optional deps | push | last in 0 of 20 runs | n=20 | end offset p50 61 s (run 35780710013) | p95 68 s (run 34733180013) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-credo | Run Credo (strict) | push | last in 0 of 20 runs | n=20 | end offset p50 68 s (run 35789879500) | p95 79 s (run 34733180013) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-dialyzer | Dialyzer (current toolchain) | push | last in 0 of 20 runs | n=18 | end offset p50 88 s (run 36087413569) | p95 242 s (run 34733180013) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-docs | Build ExDoc (dev) | push | last in 0 of 20 runs | n=20 | end offset p50 75 s (run 35787338903) | p95 82 s (run 36257162368) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-example-browser | Example app browser E2E (Playwright) | push | last in 16 of 20 runs | n=20 | end offset p50 631 s (run 36257162368) | p95 651 s (run 36258719902) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-format | Check formatting | push | last in 0 of 20 runs | n=20 | end offset p50 17 s (run 34733180013) | p95 22 s (run 36087413569) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-hex-evaluator | Hex evaluator smoke (threadline from hex.pm) | push | last in 0 of 20 runs | n=20 | end offset p50 62 s (run 35793569116) | p95 74 s (run 35764881231) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-hex-package | Hex package tarball | push | last in 0 of 20 runs | n=20 | end offset p50 16 s (run 36087413569) | p95 20 s (run 35787338903) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-mechanical | Mechanical checker (committed scorecards) | push | last in 0 of 20 runs | n=18 | end offset p50 86 s (run 34756589365) | p95 98 s (run 35797666621) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-pgbouncer-topology | PgBouncer transaction topology | push | last in 0 of 20 runs | n=20 | end offset p50 112 s (run 34756589365) | p95 126 s (run 36256231845) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-release-shape | Release metadata (version / changelog) | push | last in 0 of 20 runs | n=20 | end offset p50 7 s (run 34755997103) | p95 8 s (run 36258719902) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-test | Run test suite (current) | push | last in 2 of 20 runs | n=18 | end offset p50 574 s (run 34756589365) | p95 648 s (run 36257162368) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |
| verify-test | Run test suite (min) | push | last in 0 of 20 runs | n=18 | end offset p50 387 s (run 34757804720) | p95 435 s (run 36256231845) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push` |

The job that finishes last most often is verify-example-browser, "Example app browser E2E (Playwright)": last in 16 of 20 pull_request runs and 16 of 20 push runs, end offset p50 623 s (run 36256339043) on pull_request and p50 631 s (run 36257162368) on push. "Run test suite (current)" is next (3 of 20 PR runs, 2 of 20 push runs, end offset p50 546 s, run 34755536474), then Tier A capture (1 of 20 on each event, run 36258071425). On one push run the pre-matrix "Run test suite" finished last (run 26899776964), which is why the push counts sum to 19 (`python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py critical-path --workflow ci.yml --event push`).

The research critical-path reading was "a near tie between browser E2E and test suite current" [research: run 36258719902]. Re-measured over 20 runs per event, the browser job is the critical path in most runs, with a p50 end-offset gap of about 77 s on pull_request (623 s vs 546 s) [inference: run 36256339043, run 34755536474].

## 3. Runner-minutes per unit of work

Runner-minutes add up every job that occupied a runner (skipped jobs excluded), including `ci-required`. Each figure is given twice: **unrounded** (sum of job seconds / 60, one decimal) and **billed** (sum of per-job whole minutes, rounded up), as defined in `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py --help`. Only the latest attempt of a run is counted, so the minutes of an earlier failed attempt that was re-run are not in these figures.

### 3a. Per PR and per push-to-main

A **push-to-main** unit is every `push` and `workflow_run` run on the pushed SHA: CI, Browser (full project set), Release and the three workflow_run hygiene workflows. Scheduled nightlies that later ran on the same unchanged SHA are not caused by the push and are excluded. The push SHAs are the ci.yml push sample from section 1b; their other runs were collected with `bash .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh --head-sha <sha> --min 1`.

| Unit | n | Unrounded p50 | Unrounded p95 | Billed p50 | Billed p95 | Regenerate |
|---|---|---|---|---|---|---|
| per PR (one ci.yml pull_request run) | n=20 | unrounded p50 46.3 min (run 36086466934) | unrounded p95 49.3 min (run 36256339043) | billed p50 55 min (run 36086466934) | billed p95 59 min (run 36256339043) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit pr` |
| per push-to-main (every push/workflow_run run on the pushed SHA; run = its ci.yml push run) | n=20 | unrounded p50 66.2 min (run 36087413569) | unrounded p95 79.7 min (run 35797666621) | billed p50 80 min (run 36087413569) | billed p95 96 min (run 36257162368) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push` |

Composition of a push-to-main, per workflow (the p50 and p95 are over the pushed SHAs that ran that workflow; the two June SHAs predate Browser-full and some hygiene workflows):

| Component | Runs on | Unrounded p50 | Unrounded p95 | Regenerate |
|---|---|---|---|---|
| component: Branch Protection | runs on 18 of 20 pushed SHAs | unrounded p50 0.1 min (run 35794478864) | unrounded p95 0.3 min (run 34755997174) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push --detail` |
| component: Browser (full project set) | runs on 18 of 20 pushed SHAs | unrounded p50 18.0 min (run 35780709940) | unrounded p95 18.6 min (run 35787338838) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push --detail` |
| component: CI | runs on 20 of 20 pushed SHAs | unrounded p50 46.9 min (run 36085532687) | unrounded p95 50.2 min (run 36257162368) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push --detail` |
| component: Community Health | runs on 12 of 20 pushed SHAs | unrounded p50 0.2 min (run 36086249204) | unrounded p95 0.2 min (run 36256883307) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push --detail` |
| component: Environment Protection | runs on 12 of 20 pushed SHAs | unrounded p50 0.1 min (run 35781923225) | unrounded p95 0.2 min (run 35766031494) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push --detail` |
| component: Release | runs on 20 of 20 pushed SHAs | unrounded p50 2.6 min (run 34758908351) | unrounded p95 13.6 min (run 36257162356) | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push --detail` |

The Release workflow is small on an ordinary push and large on a publishing push, because its `gate-ci-green` job polls until CI is green: see the p95 sample (run 36257162356) against the p50 sample (run 34758908351).

An ordinary landed PR (one PR run plus its squash-merge push) is therefore 46.3 + 66.2 = 112.5 unrounded runner-min at p50, or 55 + 80 = 135 billed [inference: p50 PR run 36086466934 plus p50 push unit run 36087413569, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit pr`].

### 3b. Per release cycle

A **release cycle** is every non-scheduled run whose head SHA is a commit of the release-please PR, the release merge commit on main, or a commit of the post-publish distribution-sync PR. The SHA set and run IDs are recorded in `raw/ci/release-<tag>.json` and were derived read-only by `bash .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh --release-tag v0.11.0` (gh release list, gh pr list, gh pr view, gh run list). release-please force-pushes its branch, so a PR head that was later overwritten is not in the PR's commit list; any run on such a SHA is missing from these totals.

| Tag | Commit | Workflow | Event | Conclusion | Unrounded | Billed | Run |
|---|---|---|---|---|---|---|---|
| v0.11.0 | release-please PR commit 9d52ab08 | CI | pull_request | cancelled | unrounded 18.1 min | billed 28 min | run 36256249852 |
| v0.11.0 | release-please PR commit 0745a341 | CI | pull_request | success | unrounded 49.3 min | billed 59 min | run 36256339043 |
| v0.11.0 | release-please PR commit 0745a341 | CI | workflow_dispatch | success | unrounded 47.2 min | billed 58 min | run 36256344029 |
| v0.11.0 | release merge commit on main 8312290d | Browser (full project set) | push | success | unrounded 14.6 min | billed 15 min | run 36257162355 |
| v0.11.0 | release merge commit on main 8312290d | Release | push | success | unrounded 13.6 min | billed 18 min | run 36257162356 |
| v0.11.0 | release merge commit on main 8312290d | CI | push | success | unrounded 50.2 min | billed 60 min | run 36257162368 |
| v0.11.0 | release merge commit on main 8312290d | Environment Protection | workflow_run | success | unrounded 0.1 min | billed 1 min | run 36257806897 |
| v0.11.0 | release merge commit on main 8312290d | Branch Protection | workflow_run | success | unrounded 0.2 min | billed 1 min | run 36257806933 |
| v0.11.0 | release merge commit on main 8312290d | Community Health | workflow_run | success | unrounded 0.2 min | billed 1 min | run 36257806948 |
| v0.11.0 | distribution-sync PR commit 198aa3db | CI | pull_request | success | unrounded 46.0 min | billed 56 min | run 36258071425 |
| v0.10.2 | release-please PR commit 43cf7b45 | CI | pull_request | success | unrounded 46.8 min | billed 56 min | run 36084754688 |
| v0.10.2 | release-please PR commit 43cf7b45 | CI | workflow_dispatch | success | unrounded 45.5 min | billed 55 min | run 36084856985 |
| v0.10.2 | release merge commit on main ee137e51 | Release | push | success | unrounded 12.8 min | billed 17 min | run 36085532676 |
| v0.10.2 | release merge commit on main ee137e51 | Browser (full project set) | push | success | unrounded 18.1 min | billed 19 min | run 36085532679 |
| v0.10.2 | release merge commit on main ee137e51 | CI | push | success | unrounded 46.9 min | billed 56 min | run 36085532687 |
| v0.10.2 | release merge commit on main ee137e51 | Branch Protection | workflow_run | success | unrounded 0.1 min | billed 1 min | run 36086249187 |
| v0.10.2 | release merge commit on main ee137e51 | Community Health | workflow_run | success | unrounded 0.2 min | billed 1 min | run 36086249204 |
| v0.10.2 | release merge commit on main ee137e51 | Environment Protection | workflow_run | success | unrounded 0.1 min | billed 1 min | run 36086249300 |
| v0.10.2 | distribution-sync PR commit 9af1f33a | CI | pull_request | success | unrounded 46.3 min | billed 55 min | run 36086466934 |

| Release cycle | Scope | Unrounded | Billed | Regenerate |
|---|---|---|---|---|
| v0.11.0 release cycle | 4 SHAs, 10 runs | unrounded 239.4 min | billed 297 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit release --tag v0.11.0` |
| v0.10.2 release cycle | 3 SHAs, 9 runs | unrounded 216.7 min | billed 261 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit release --tag v0.10.2` |

The release PR head is tested twice on the same SHA: once by the pull_request run and once by the release-bootstrap workflow_dispatch run (v0.11.0: run 36256339043 and run 36256344029; v0.10.2: run 36084754688 and run 36084856985).

Compared with an ordinary landed PR, a release cycle costs about 239.4 − 112.5 = 126.9 more unrounded runner-min for v0.11.0 and 216.7 − 112.5 = 104.2 more for v0.10.2 (billed: 297 − 135 = 162 and 261 − 135 = 126) [inference: `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit release --tag v0.11.0` and `--unit release --tag v0.10.2` against the section 3a p50 units, run 36086466934 and run 36087413569].

The distribution-sync PR's own squash-merge push is an ordinary push-to-main unit and is not in the cycle totals above: for v0.11.0 that is the push that ran CI run 36258719902, already in the section 3a sample.

Research estimated a release cycle at "~200+" runner-min on top of the landed PR [research: run 36256231909, run 36257162356].

## 4. Flake Detection cost

Flake Detection (`flake-detection.yml`, one job, nightly at 07:00 UTC) over every completed scheduled run since 2026-08-27, any conclusion, collected by `bash .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh --workflow flake-detection.yml --event schedule --status any --since 2026-08-27 --target 0 --min 1`.

| Workflow | Event / regime | Figure | Figure | Figure | Figure | Regenerate |
|---|---|---|---|---|---|---|
| flake-detection.yml | schedule | 31 runs 2026-08-27 to 2026-09-26 (run 33062137891 to run 36225676728) | cancelled 12, failure 17, success 2 | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27` |
| flake-detection.yml | schedule | successful wall n=2 | p50 98.0 min (run 36106137910) | p95 137.0 min (run 36225676728) | min–max 98.0–137.0 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27` |
| flake-detection.yml | schedule | window total | unrounded 1738.5 min | billed 1754 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27` |
| flake-detection.yml | regime: fast failure (< 10 min) | 17 runs | first 2026-08-27 (run 33062137891) | last 2026-09-12 (run 34679766829) | wall 2.5–3.9 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27 --regimes` |
| flake-detection.yml | regime: cancelled | 12 runs | first 2026-09-13 (run 34744327365) | last 2026-09-24 (run 35967937335) | wall 120.3–120.5 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27 --regimes` |
| flake-detection.yml | regime: success | 2 runs | first 2026-09-25 (run 36106137910) | last 2026-09-26 (run 36225676728) | wall 98.0–137.0 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27 --regimes` |

Regimes split runs by conclusion and wall clock: success; cancelled; fast failure = a failed run whose wall clock is under 10 min (600 s, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27 --regimes`).

- Fast failure: 2026-08-27 to 2026-09-12 inside this window (first run 33062137891, last run 34679766829). Research traced the streak back to 2026-08-18, before this window [research: run 32110527200].
- Cancelled at the old 120-min timeout: 2026-09-13 to 2026-09-24 (first run 34744327365, last run 35967937335).
- Success after the timeout went to 180 min: 2026-09-25 to 2026-09-26 (run 36106137910, run 36225676728).

At the current steady state, where every nightly completes, Flake Detection would cost about 30 × 98.0 to 30 × 137.0 = 2,940 to 4,110 runner-min per month [inference: 30 nightlies × the two successful runs, run 36106137910 and run 36225676728; only n=2, so this is a range, not a percentile]. The 30-day window above cost 1,738.5 unrounded runner-min only because most nights failed fast or were cancelled (`python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27`).

## 5. Browser-full cost

Browser (full project set) (`browser-full.yml`, one job) runs on every push to main and nightly at 05:00 UTC. Every completed run since 2026-08-27, any conclusion, collected by `bash .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh --workflow browser-full.yml --event push --status any --since 2026-08-27 --target 0 --min 1` and the same with `--event schedule`.

| Workflow | Event / regime | Figure | Figure | Figure | Figure | Regenerate |
|---|---|---|---|---|---|---|
| browser-full.yml | push | 20 runs 2026-08-28 to 2026-09-26 (run 33138291365 to run 36258719891) | failure 1, success 19 | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event push --since 2026-08-27` |
| browser-full.yml | push | successful wall n=19 | p50 18.0 min (run 35780709940) | p95 18.6 min (run 35787338838) | min–max 12.5–18.6 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event push --since 2026-08-27` |
| browser-full.yml | push | window total | unrounded 331.2 min | billed 343 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event push --since 2026-08-27` |
| browser-full.yml | regime: fast failure (< 10 min) | 1 runs | first 2026-08-28 (run 33138291365) | last 2026-08-28 (run 33138291365) | wall 2.1–2.1 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event push --since 2026-08-27 --regimes` |
| browser-full.yml | regime: success | 19 runs | first 2026-09-13 (run 34733180006) | last 2026-09-26 (run 36258719891) | wall 12.5–18.6 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event push --since 2026-08-27 --regimes` |
| browser-full.yml | schedule | 30 runs 2026-08-28 to 2026-09-26 (run 33152326369 to run 36220250465) | failure 16, success 14 | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event schedule --since 2026-08-27` |
| browser-full.yml | schedule | successful wall n=14 | p50 14.5 min (run 34932091760) | p95 19.8 min (run 35564064340) | min–max 11.4–19.8 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event schedule --since 2026-08-27` |
| browser-full.yml | schedule | window total | unrounded 245.4 min | billed 262 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event schedule --since 2026-08-27` |
| browser-full.yml | regime: fast failure (< 10 min) | 16 runs | first 2026-08-28 (run 33152326369) | last 2026-09-12 (run 34675082585) | wall 1.8–2.2 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event schedule --since 2026-08-27 --regimes` |
| browser-full.yml | regime: success | 14 runs | first 2026-09-13 (run 34739821872) | last 2026-09-26 (run 36220250465) | wall 11.4–19.8 min | `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event schedule --since 2026-08-27 --regimes` |

Per push to main, Browser-full adds p50 18.0 unrounded runner-min (run 35780709940), which is the second-largest component of a push-to-main unit after CI (section 3a, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push --detail`).

At the current steady state, where the nightly passes, the nightly alone would cost about 30 × 14.5 = 435 runner-min per month at its p50 [inference: p50 successful nightly run 34932091760 × 30 nights]. The push lane cost 331.2 unrounded runner-min over the 20 pushes in the window; at the same push rate that is about 331 runner-min per month [inference: `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event push --since 2026-08-27`, window of 2026-08-28 to 2026-09-26].

## 6. Inert-path share of merged PRs

This is the input SEED-006 (Phase 222, SCOPE-01) decides from. A PR is inert only if every file it touches matches an entry in `tools/inert-allowlist.txt`, and every entry carries the command whose empty output proves it inert. Any unmatched file makes the PR non-inert (fail-closed). An empty PR set prints `n=0 — not measured`, never 0% (`python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --self-test`).

**PR data.** Merged PRs into main come from `gh pr list --repo szTheory/threadline --state merged --base main --limit 500 --json number,title,mergedAt,headRefName,changedFiles`, saved as `raw/prs/index.json`. Each PR's full file list comes from `gh api --paginate repos/szTheory/threadline/pulls/<n>/files?per_page=100 --jq '.[].filename'`, saved sorted as `raw/prs/<n>.files.txt`. The classifier refuses to run if any list is missing or its line count differs from `changedFiles` (`jq length .planning/phases/214-baseline-measurement/raw/prs/index.json`).

**Windows.** *all* is every merged PR (merged 2026-05-28 to 2026-09-26). *30d* is mergedAt 2026-08-27 to 2026-09-26, the same window as sections 4 and 5. Both windows are fixed in the tool, so re-runs are byte-identical (`python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --window all`).

- all: 1 of 40 merged PRs touch only inert paths (2.5%), inert PR #8 (`python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --window all`)
- 30d: 0 of 20 merged PRs touch only inert paths (0%), no inert PR (`python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --window 30d`)

The one inert PR, #8, touched only `.planning/ROADMAP.md` and `.planning/STATE.md` (`gh api --paginate repos/szTheory/threadline/pulls/8/files?per_page=100 --jq '.[].filename'`, saved as `raw/prs/8.files.txt`).

**Allowlist.** Admission needs three things. The path is not in the Hex package `files:` list in mix.exs. The command `git grep -n -F '<path or dir>' -- test .github mix.exs bin examples` prints nothing. The path is not under .github/ and is not Markdown named by a doc-contract test. Entries are exact files or single `.planning/` subdirectories. There is no blanket `.planning/*`, no `*.md` and no extension glob. Each entry and its proof:

| Entry | Proof (empty output = inert) |
|---|---|
| `.planning/ARCHIVE-REGISTER.md` | `git grep -n -F '.planning/ARCHIVE-REGISTER.md' -- test .github mix.exs bin examples` |
| `.planning/CRITIQUE.md` | `git grep -n -F '.planning/CRITIQUE.md' -- test .github mix.exs bin examples` |
| `.planning/MILESTONES.md` | `git grep -n -F '.planning/MILESTONES.md' -- test .github mix.exs bin examples` |
| `.planning/PROJECT.md` | `git grep -n -F '.planning/PROJECT.md' -- test .github mix.exs bin examples` |
| `.planning/REQUIREMENTS.md` | `git grep -n -F '.planning/REQUIREMENTS.md' -- test .github mix.exs bin examples` |
| `.planning/RETROSPECTIVE.md` | `git grep -n -F '.planning/RETROSPECTIVE.md' -- test .github mix.exs bin examples` |
| `.planning/ROADMAP.md` | `git grep -n -E '\.planning/ROADMAP\.md([^.]|$)' -- test .github mix.exs bin examples` |
| `.planning/STATE.md` | `git grep -n -F '.planning/STATE.md' -- test .github mix.exs bin examples` |
| `.planning/WINDOWS.md` | `git grep -n -F '.planning/WINDOWS.md' -- test .github mix.exs bin examples` |
| `.planning/config.json` | `git grep -n -F '.planning/config.json' -- test .github mix.exs bin examples` |
| `.planning/design-system-ledger.json` | `git grep -n -F '.planning/design-system-ledger.json' -- test .github mix.exs bin examples` |
| `.planning/critic-scores/*` | `git grep -n -F '.planning/critic-scores' -- test .github mix.exs bin examples` |
| `.planning/debug/*` | `git grep -n -F '.planning/debug' -- test .github mix.exs bin examples` |
| `.planning/golden/*` | `git grep -n -F '.planning/golden' -- test .github mix.exs bin examples` |
| `.planning/quick/*` | `git grep -n -F '.planning/quick' -- test .github mix.exs bin examples` |
| `.planning/refute/*` | `git grep -n -F '.planning/refute' -- test .github mix.exs bin examples` |
| `.planning/research/*` | `git grep -n -F '.planning/research' -- test .github mix.exs bin examples` |
| `.planning/scorecards/*` | `git grep -n -F '.planning/scorecards' -- test .github mix.exs bin examples` |
| `.planning/seeds/*` | `git grep -n -F '.planning/seeds' -- test .github mix.exs bin examples` |
| `.planning/threads/*` | `git grep -n -F '.planning/threads' -- test .github mix.exs bin examples` |
| `.planning/todos/*` | `git grep -n -F '.planning/todos' -- test .github mix.exs bin examples` |
| `.planning/ui-reviews/*` | `git grep -n -F '.planning/ui-reviews' -- test .github mix.exs bin examples` |

The ROADMAP.md proof uses `-E` because the `-F` form also matches the separate path `.planning/ROADMAP.md.bak`. That path is rejected: test/threadline/removed_artifact_contract_test.exs turns the suite red if it is tracked. The rejected candidates and their reasons are in the comment block at the end of `tools/inert-allowlist.txt`. They include the blanket `.planning/*`, `.planning/audits`, `.planning/phases` and `.planning/milestones`, which all have references in test/ or bin/. They also include every package path, every Markdown file read by a doc-contract test, and `.dockerignore`, whose implicit consumer (docker build) grep cannot rule out.

Research's example of a docs-only PR is the `release/sync-*` distribution PR [research: run 36258071425]. Under this rule those PRs are not inert. All 8 of them touch `guides/adoption-pilot-backlog.md`, which ships in the Hex package and is read by doc-contract tests (`git grep -l -F 'adoption-pilot-backlog' -- test`, `jq -r '.[]|select(.headRefName|startswith("release/sync-"))|.number' .planning/phases/214-baseline-measurement/raw/prs/index.json`).

**What SEED-006 should read from this.** A skip-eligible-by-path classifier would have skipped 1 PR out of the 40 merged overall and none of the 20 merged in the 30-day window, so path-based lane skipping has no material share to save at the current PR mix (`python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --window 30d`). Phase 222 should re-run the same command after 218–219 before building anything.

## 7. `mix test --slowest 25`

Captured locally by `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` (raw output `raw/local/slowest-25.txt`, parsed summary `raw/local/slowest-25.summary.json`). The command is `MIX_ENV=test mix test --slowest 25`.

**Environment** (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh env`, raw `raw/local/env.txt`): captured 2026-09-26 at commit 5e461412, Darwin arm64 with 18 CPUs, Erlang/OTP 27.3.4.15 and Elixir 1.17.3, PostgreSQL 14.17 client and server. The `.dialyzer` PLT was present at the start (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh env`).

The local test DB still carries the stale `public.threadline_capture_changes()` function. It was recorded, not fixed, because this phase only measures. Unqualified references can pass locally and fail on CI because of it (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh env`).

**Suite summary.** 9 properties, 2207 tests, 0 failures, 2 excluded, exit 0. ExUnit reports 129.3 s, split 12.1 s async and 117.1 s sync. Wall clock was 130.32 s (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest`).

**This is a serial time, not the suite's parallel time.** `--slowest` turns on ExUnit trace mode (`max_cases: 1`), so every test runs one at a time. Do not compare the 130.32 s wall with the default parallel `mix test` run (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest`). For scale, CI's "Run tests" step took 310 s in the current lane and 346 s in the min lane on GitHub-hosted runners (run 36258719902, `jq '.jobs[].steps[] | select(.name=="Run tests")' .planning/phases/214-baseline-measurement/raw/local/ci-test-steps.json`).

The 25 slowest tests take 95.8 s, 74.2% of ExUnit's total. The first four (28.66 + 14.32 + 10.54 + 10.37 = 63.89 s) are about half of the serial suite's 129.3 s on their own (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest`).

| Rank | Test | Module | Location | Seconds | Regenerate |
|---|---|---|---|---|---|
| 1 | production CI config is exercised by a clean seven-case behavioral smoke | Threadline.PlaywrightFailFastContractTest | `test/threadline/playwright_fail_fast_contract_test.exs:7` | 28.66 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 2 | all 12 baseline-cohort group stories render without error across the matrix | Threadline.OperatorSurface.StressRouterTest | `test/threadline/operator_surface/stress_router_test.exs:493` | 14.32 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 3 | every ledger story is listed and direct navigation renders preview or reserved placeholder | Threadline.OperatorSurface.StressRouterTest | `test/threadline/operator_surface/stress_router_test.exs:459` | 10.54 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 4 | all local, external, and module-doc subjects have one exact owner | Threadline.PublicSurfaceContractTest | `test/threadline/public_surface_contract_test.exs:332` | 10.37 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 5 | committed checkout verifier proves exact committed HEAD stays clean while reviewed controls remain trackable | Threadline.CleanCheckoutContractTest | `test/threadline/clean_checkout_contract_test.exs:255` | 5.51 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 6 | aggregate failure restores planning before contained cleanup | Threadline.PlanningIndependenceContractTest | `test/threadline/planning_independence_contract_test.exs:45` | 3.21 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 7 | symlink replacement is rejected without touching the outside target or caller | Threadline.PlanningIndependenceContractTest | `test/threadline/planning_independence_contract_test.exs:126` | 2.75 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 8 | committed checkout verifier forced verifier failure cleans only its clone child and preserves caller state | Threadline.CleanCheckoutContractTest | `test/threadline/clean_checkout_contract_test.exs:276` | 2.72 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 9 | certifies exact committed HEAD with planning absent and preserves caller state | Threadline.PlanningIndependenceContractTest | `test/threadline/planning_independence_contract_test.exs:7` | 2.66 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 10 | restoration failure retains the clone and reports its quarantine | Threadline.PlanningIndependenceContractTest | `test/threadline/planning_independence_contract_test.exs:99` | 2.57 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 11 | committed critic-tooling slice has no live warnings **(`:live_dialyzer`)** | Threadline.DialyzerSliceContractTest | `test/threadline/dialyzer_slice_contract_test.exs:12` | 2.42 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 12 | the verifier delegates to this script classic protection falls back to branch metadata when REST denies the Actions token | Threadline.BranchProtectionComparisonContractTest | `test/threadline/branch_protection_comparison_contract_test.exs:211` | 1.25 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 13 | cross-origin and ambiguous login-looking redirects fail before Playwright | Threadline.E2ePreflightContractTest | `test/threadline/e2e_preflight_contract_test.exs:27` | 1.05 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 14 | relative and same-origin login redirects pass with normalized default ports | Threadline.E2ePreflightContractTest | `test/threadline/e2e_preflight_contract_test.exs:6` | 0.96 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 15 | irreducible residue requires an exact tuple, rationale, and removal trigger | Threadline.DialyzerSliceContractTest | `test/threadline/dialyzer_slice_contract_test.exs:71` | 0.79 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 16 | the verifier delegates to this script classic protection treats only HTTP 404 as absent and fails closed otherwise | Threadline.BranchProtectionComparisonContractTest | `test/threadline/branch_protection_comparison_contract_test.exs:163` | 0.79 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 17 | repository formatter configs give representative Elixir files exactly one owner | Threadline.FormatterTopologyContractTest | `test/threadline/formatter_topology_contract_test.exs:21` | 0.73 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 18 | API errors and malformed JSON fail without fallback invocations | Threadline.MainCiObserverContractTest | `test/threadline/main_ci_observer_contract_test.exs:139` | 0.63 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 19 | 2xx requires both operator shell markers | Threadline.E2ePreflightContractTest | `test/threadline/e2e_preflight_contract_test.exs:72` | 0.63 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 20 | safe temp-tree cleanup rejects every registered linked worktree root without mutating or unregistering it | Threadline.CleanCheckoutContractTest | `test/threadline/clean_checkout_contract_test.exs:140` | 0.60 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 21 | an undrained truncation notice makes mix test exit non-zero | Threadline.Capture.NoticeGuardCanaryTest | `test/threadline/capture/notice_guard_canary_test.exs:20` | 0.58 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 22 | Phoenix-style lowercase and mixed-case Location headers are accepted | Threadline.E2ePreflightContractTest | `test/threadline/e2e_preflight_contract_test.exs:19` | 0.57 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 23 | the entire readable archive is free of planning vocabulary | Threadline.ReleaseArtifactContractTest | `test/threadline/release_artifact_contract_test.exs:311` | 0.56 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 24 | the same run without a truncation exits zero | Threadline.Capture.NoticeGuardCanaryTest | `test/threadline/capture/notice_guard_canary_test.exs:29` | 0.54 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |
| 25 | all packaged source uses durable vocabulary | Threadline.ReleaseArtifactContractTest | `test/threadline/release_artifact_contract_test.exs:292` | 0.50 s | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest` |

Row 11 is the `:live_dialyzer` test (`@tag :live_dialyzer` in test/threadline/dialyzer_slice_contract_test.exs). With a warm PLT it took 2.42 s here. Section 8 isolates it (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest`).

## 8. Isolated `:live_dialyzer` cost (warm PLT and cold PLT)

Captured by `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer` (raw `raw/local/live-dialyzer.json`). The timed command is `MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer` under `/usr/bin/time -p`. The test shells out through bin/verify-dialyzer-slice to `MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status`.

| Condition | What it is | Seconds | Regenerate |
|---|---|---|---|
| warm PLT, warm dev compile | second consecutive run with `.dialyzer` present (a warm-up run took 3.20 s) | 3.11 s, exit 0 | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer` |
| warm PLT, raw Dialyzer command only | the shelled command on its own, 0 warning lines | 2.18 s, exit 0 | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer` |
| cold PLT, warm dev compile | `.dialyzer` moved aside for the run; `_build/dev` kept | 1.21 s, exit 0, **no analysis ran** | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer` |
| cold PLT, raw Dialyzer command only | fails with "Could not read PLT file … no_such_file", masked to exit 0 | 0.41 s, exit 0 | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer` |
| fresh PLT build (`MIX_ENV=dev mix dialyzer --plt`) | the real local cost of building the PLT, as CI's verify-dialyzer cache-miss step does | 32.99 s, exit 0 | `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer` |

**The cold-PLT figure is not a cold-analysis cost.** With no PLT, `--no-check` skips the PLT build. Dialyzer then fails with "Could not read PLT file", and `--ignore-exit-status` turns that into exit 0 with no warning lines. The verifier prints "0 live warnings" and the test passes without analyzing anything. So 1.21 s is the cost of a vacuous pass. `cold_plt_vacuous_pass` is `true` in the raw file (`jq '.cold_plt_vacuous_pass, .cold_plt_dialyzer_error' .planning/phases/214-baseline-measurement/raw/local/live-dialyzer.json`).

**Which one CI runs.** The CI test lanes (`verify-test`, min and current) cache only `deps` (ci.yml lines 338-342, `git grep -n -A4 'Cache deps' -- .github/workflows/ci.yml`). They restore no `.dialyzer` and no `_build`, so the test runs there with a cold PLT and an uncached dev compile. In the green push run, the test-suite jobs' logs contain no Dialyzer output, and "Run tests" took 310 s in the current lane and 346 s in the min lane (run 36258719902, step timings in `jq '.jobs[] | {name, steps: [.steps[] | select(.name=="Run tests" or .name=="Compile (warnings as errors)")]}' .planning/phases/214-baseline-measurement/raw/local/ci-test-steps.json`).

**Best local approximation of CI:** the cold-PLT row (1.21 s), plus a dev-env compile that the local run did not pay because `_build/dev` was warm. So on CI the `:live_dialyzer` test most likely also passes vacuously, costing a dev compile and no analysis [inference: CI caches no `.dialyzer` for the test lanes, and the cold local run passed with no PLT, `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer`]. Confirming this needs a CI log of the test's own output, which the passing run does not print. It is carried to the CI-economy phase in deferred-items.md. Local hardware (Darwin arm64, 18 CPUs) differs from GitHub-hosted runners, so no local seconds figure transfers to CI directly (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh env`).

**Research comparator.** Research measured a CI cold PLT build of 148.49 s on verify-dialyzer's cache miss [research: run 34731370786]. That is the same work as the local 32.99 s `mix dialyzer --plt` row, on different hardware (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer`). It is not what the test lane's `:live_dialyzer` test pays, because that test never builds a PLT.

## 9. PROJECT.md baseline facts (BASE-02)

Each fact below is in `raw/base02/facts.json` with the command that produced it (`jq '.commands' .planning/phases/214-baseline-measurement/raw/base02/facts.json`). PROJECT.md's `## Current Milestone` baseline states every one of them. The checker reads the expected values from facts.json and exits 1 on any miss, including the Out of Scope byte-identity check against ff8e53e9: `bash .planning/phases/214-baseline-measurement/tools/check-project-baseline.sh`.

- **Flake Detection streak and timeout:** the longest fast-failure streak is 79 consecutive scheduled runs, 06-26 → 09-12 (run 28225855438 to run 34679766829). A fast failure is a failed run under 10 min. The streak was measured over all 118 scheduled runs. verify-flake's timeout is now 180 min (`bash .planning/phases/214-baseline-measurement/tools/measure-base02.sh flake`).
- **Advisories:** root `mix.lock` has 2, mint 1.10.0 (MEDIUM) and lazy_html 0.1.12 (LOW). `bench/mix.lock` has 8 across decimal 2.3.0, plug 1.19.1 and postgrex 0.22.0, of which 3 are HIGH (3 MEDIUM, 2 LOW). The example app lockfile is clean, 0 advisories. Hex is 2.5.1 (`bash .planning/phases/214-baseline-measurement/tools/measure-base02.sh advisories`).
- **Tracked local-path files:** 387 tracked files at HEAD e58aa067 match the absolute or home-relative path patterns: 383 under `.planning/`, 2 in `prompts/prior-art/` and 2 under `.github/` (runner cache paths). The absolute pattern alone matches 303. At origin/main 5e78b2f0 the count is 345 (292 absolute-only, 2 in `prompts/prior-art/`). The patterns themselves live in the measuring script and in facts.json, not in this doc (`bash .planning/phases/214-baseline-measurement/tools/measure-base02.sh paths`).
- **xref cycles:** 0 compile-connected cycles, already gated in CI by `mix verify.xref_cycles`. There are 5 runtime cycles of length 2, and the capture↔semantics edge is present. 2 of the 5 are Ecto schema pairs and 3 are module call pairs. Disposition: no runtime-cycle gate (`bash .planning/phases/214-baseline-measurement/tools/measure-base02.sh xref`).

## 10. Research vs re-measured

Research figures come from `.planning/research/FEATURES.md` and keep their `[research]` label and research run IDs. Re-measured figures cite this doc's commands. Differences are stated, not reconciled.

| Figure | Research value | Re-measured value | Difference |
|---|---|---|---|
| CI wall clock, pull_request | median 10.4 min, n=60 over 30 days [research: `gh run list --repo szTheory/threadline --workflow ci.yml --event pull_request`] | p50 629 s = 10.5 min, n=20 (run 34758417725, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py wall --workflow ci.yml --event pull_request`) | +0.1 min; research took `gh run list` wall over 60 runs, this doc takes job timestamps of 20 successful runs |
| CI wall clock, push | median 10.8 min, n=21 [research: `gh run list --repo szTheory/threadline --workflow ci.yml --event push`] | p50 640 s = 10.7 min, n=20 (run 34755997103, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py wall --workflow ci.yml --event push`) | within 0.1 min |
| Runner-min per CI run | 46.0–50.2 unrounded, 56–60 billed, 7 samples [research: run 36258719902, run 36258071425] | per PR p50 46.3 unrounded / 55 billed (run 36086466934, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit pr`) | research gave a range over 7 runs; this is a p50 over 20 |
| Runner-min per push to main | ~69 [research: run 36258719902, run 36258719891] | p50 66.2 unrounded / 80 billed (run 36087413569, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit push`) | about 3 min lower unrounded |
| Runner-min per landed PR | ~117 [research: run 36258071425, run 36258719902] | 112.5 unrounded / 135 billed [inference: run 36086466934 plus run 36087413569] | about 4.5 min lower unrounded |
| Release cycle, extra over a landed PR | ~200+ [research: run 36256231909, run 36257162356] | v0.11.0 +126.9 unrounded / +162 billed; v0.10.2 +104.2 / +126 [inference: `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit release --tag v0.11.0`] | re-measured is 73–96 unrounded runner-min lower than the research estimate |
| Flake Detection, 30-day total | 1,740 wall-min, 31 runs [research: `gh run list --repo szTheory/threadline --workflow flake-detection.yml --event schedule`] | 1738.5 unrounded / 1754 billed, 31 runs (run 33062137891 to run 36225676728, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event schedule --since 2026-08-27`) | matches within rounding |
| Flake Detection, monthly at steady state | ~3,000–4,100 [research: run 36106137910, run 36225676728] | 2,940–4,110 [inference: 30 × run 36106137910 and run 36225676728] | same inputs; research rounded |
| Flake fast-failure streak | 08-18 → 09-12, at least 26 nightlies [research: run 32110527200, run 34679766829] | 06-26 → 09-12, 79 runs (run 28225855438 to run 34679766829, `bash .planning/phases/214-baseline-measurement/tools/measure-base02.sh flake`) | re-measured streak starts 53 days earlier and is 79 runs, not at least 26 |
| Browser-full push median | 18.1 min, n=20 [research: run 36258719891] | p50 18.0 min, n=19 successful (run 35780709940, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event push --since 2026-08-27`) | within 0.1 min |
| "Run test suite (current)" | 593–646 s, 7 samples [research: run 36258719902] | p50 546 s, p95 610 s on pull_request, n=20 (run 34755536474, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Run test suite (current)" --format md`) | re-measured p50 is 47 s below the research minimum; p95 is inside the research range |
| Cold PLT build | 148.49 s on CI [research: run 34731370786] | not re-measured on CI; the local `mix dialyzer --plt` build takes 32.99 s on different hardware (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer`) | not comparable (hardware); see section 8 |
