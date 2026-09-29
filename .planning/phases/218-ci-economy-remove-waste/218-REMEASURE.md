# Phase 218: CI Re-measurement After the Economy Cuts (ECON-07)

This record measures what CI costs after ECON-01 through ECON-06 landed, and states each change against the phase 214 baseline (BASE-01, `.planning/phases/214-baseline-measurement/214-BASELINE.md`).

## 0. Method

- Approach (D-11): cited dispatch runs of the pushed code, plus cadence arithmetic. No weekly or nightly scheduled sample is waited for; none was.
- Code under measurement: branch `land/v1.43-217-218` (draft PR #60 against main), pushed 2026-09-27T23:34:10Z. It is origin/main plus the phase 217/218 code commits, then the landing fixes recorded under Samples. The first ci.yml run on it is run 36359132030.
- Tools: the phase 214 collector, summarizer and citation checker, copied into this phase's `tools/` directory so that post-change runs never land in the phase 214 evidence. The copies differ from the originals only in their self-path strings and in the checker's phase-number exemption, which accepts phases 214 through 218.
- Raw data: this phase's own `raw/ci/manifest.json` and `raw/ci/runs/`, written by `bash .planning/phases/218-ci-economy-remove-waste/tools/collect-ci-runs.sh --workflow ci.yml --event pull_request --status any --since 2026-09-27 --target 0 --min 1`, the same with `--event workflow_dispatch`, and the same for `--workflow flake-detection.yml` and `--workflow browser-full.yml` with `--event workflow_dispatch`.
- A new script, not an edited copy: the copied summarizer's `jobs`, `wall`, `critical-path` and `runner-minutes` modes read only the plain manifest keys, which this collection does not write (`python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py runner-minutes --unit push` exits with "manifest has no entry"). So `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py --help` imports the copied summarizer's arithmetic unchanged (job duration, nearest-rank percentiles, unrounded and billed minutes) and applies it to named sample sets. Its `--set base` reproduces the BASE-01 figures exactly: per PR p50 46.3 unrounded and 55 billed runner-min (run 36086466934), wall p50 629 s (run 34758417725), `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py runner-minutes --set base`.
- The copied summarizer's `workflow-cost` mode does read the since-keyed entries, so the Flake Detection and Browser-full sections use it directly.
- Baseline: every delta quotes the 214-BASELINE figure and the run IDs behind it.
- Citation rule: every per-run figure cites a run ID or the backticked command that printed it, checked by `python3 .planning/phases/218-ci-economy-remove-waste/tools/check-citations.py .planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md`.
- Projections: every monthly figure is `measured run × cadence`, is labeled [inference], and cites the measured run it multiplies.

## 1. Samples

The `--since 2026-09-27` listing also returns runs of other PRs created earlier that day, before the push, running pre-218 code with the old 17-job roster (run 36318716184 through run 36324736224 on pull_request, run 36319472710 and run 36320837739 on workflow_dispatch). They are kept in the raw data but excluded from every post-change figure: the script keeps only runs created at or after the push instant (`python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples`).

The eight post-landing ci.yml runs:

| Run | Event | Head | Conclusion | Jobs that ran | Jobs not success | Regenerate |
|---|---|---|---|---|---|---|
| run 36359132030 | pull_request | 0d000785 | failure | 15 jobs | CI required, Repo hygiene (no machine-local paths) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples` |
| run 36359171595 | workflow_dispatch | 0d000785 | failure | 15 jobs | CI required, Repo hygiene (no machine-local paths) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples` |
| run 36359795977 | workflow_dispatch | 0d000785 | failure | 15 jobs | CI required, Repo hygiene (no machine-local paths) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples` |
| run 36360336486 | workflow_dispatch | 0d000785 | failure | 15 jobs | CI required, Repo hygiene (no machine-local paths) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples` |
| run 36361003789 | workflow_dispatch | 0d000785 | failure | 15 jobs | CI required, Repo hygiene (no machine-local paths) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples` |
| run 36362405054 | pull_request | c18f2b2f | failure | 15 jobs | CI required, Repo hygiene (no machine-local paths) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples` |
| run 36363356238 | pull_request | a72fcd32 | success | 15 jobs | none | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples` |
| run 36364354586 | pull_request | 37e36cb2 | success | 15 jobs | none | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples` |

**Failed runs are valid timing samples.** In each of the six failed runs, the only jobs that did not succeed are "Repo hygiene (no machine-local paths)" and the "CI required" aggregate. All other 13 jobs ran to completion with conclusion `success`, and all 15 jobs ran in every run (column "Jobs not success" above, from the committed job data: `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py samples`). The hygiene job took 6–8 s when it failed and 8–9 s when it passed (run 36359171595, run 36364354586, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set post`), so a failed run does not undercount runner-minutes.

**Post-fix labels.** The hygiene failure was the published `.planning/` snapshot on the land branch (a 218-08 landing deviation, run 36359132030), not a ci.yml job change. Every sampled SHA runs the same ci.yml job set:
- 0d000785 is the first push: 5 samples, 1 pull_request (run 36359132030) and the 4 granted workflow_dispatch top-ups (run 36359171595, run 36359795977, run 36360336486, run 36361003789).
- c18f2b2f adds the Playwright dependency fix (deviation 1), which only changes what Browser-full runs (run 36362405054).
- a72fcd32 is the first green run, after the hygiene scrub (run 36363356238).
- 37e36cb2 adds the flake-lane resize (deviation 3), which only changes `mix verify.flake` (run 36364354586).
- So run 36363356238 and run 36364354586 are the post-fix samples. The figures below use all eight runs as the primary set and also report the pull_request-only, dispatch-only and success-only subsets.

Workflow dispatches (one granted each, plus one re-dispatch each after a landing fix):
- Flake Detection: run 36359135268 at 0d000785 (failure, classified `inconclusive`) and run 36364688861 at 37e36cb2 (success, classified `pass`, post-fix), from `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event workflow_dispatch --since 2026-09-27`.
- Browser-full: run 36359136941 at 0d000785 (failure) and run 36363979144 at a72fcd32 (success, post-fix), from `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event workflow_dispatch --since 2026-09-27`.

## 2. Runner-minutes per ci.yml run

Runner-minutes sum every job that occupied a runner, including `ci-required` (unrounded = seconds / 60; billed = per-job whole minutes rounded up), as in BASE-01 section 3a. The BASE-01 figure is one ci.yml pull_request run: unrounded p50 46.3 min, billed p50 55 min (run 36086466934, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit pr`).

| Unit | Set | n | Unrounded p50 | Unrounded p95 | Billed p50 | Billed p95 | Regenerate |
|---|---|---|---|---|---|---|---|
| per ci.yml run, every job that ran | set base | n=20 | unrounded p50 46.3 min (run 36086466934) | unrounded p95 49.3 min (run 36256339043) | billed p50 55 min (run 36086466934) | billed p95 59 min (run 36256339043) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py runner-minutes --set base` |
| per ci.yml run, every job that ran | set post | n=8 | unrounded p50 44.4 min (run 36362405054) | unrounded p95 46.9 min (run 36360336486) | billed p50 53 min (run 36359795977) | billed p95 57 min (run 36360336486) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py runner-minutes --set post` |
| per ci.yml run, every job that ran | set post-pr | n=4 | unrounded p50 44.4 min (run 36362405054) | unrounded p95 46.4 min (run 36364354586) | billed p50 52 min (run 36362405054) | billed p95 55 min (run 36364354586) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py runner-minutes --set post-pr` |
| per ci.yml run, every job that ran | set post-dispatch | n=4 | unrounded p50 44.3 min (run 36359795977) | unrounded p95 46.9 min (run 36360336486) | billed p50 53 min (run 36359795977) | billed p95 57 min (run 36360336486) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py runner-minutes --set post-dispatch` |
| per ci.yml run, every job that ran | set post-success | n=2 | unrounded p50 42.2 min (run 36363356238) | unrounded p95 46.4 min (run 36364354586) | billed p50 51 min (run 36363356238) | billed p95 55 min (run 36364354586) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py runner-minutes --set post-success` |
| per ci.yml run, excluding jobs added since BASE-01 by phases 215-217 | set base | n=20 | unrounded p50 46.3 min (run 36086466934) | unrounded p95 49.3 min (run 36256339043) | billed p50 55 min (run 36086466934) | billed p95 59 min (run 36256339043) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py comparable-minutes --set base` |
| per ci.yml run, excluding jobs added since BASE-01 by phases 215-217 | set post | n=8 | unrounded p50 43.7 min (run 36362405054) | unrounded p95 46.2 min (run 36360336486) | billed p50 51 min (run 36359795977) | billed p95 55 min (run 36360336486) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py comparable-minutes --set post` |
| per ci.yml run, excluding jobs added since BASE-01 by phases 215-217 | set post-success | n=2 | unrounded p50 41.5 min (run 36363356238) | unrounded p95 45.7 min (run 36364354586) | billed p50 49 min (run 36363356238) | billed p95 53 min (run 36364354586) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py comparable-minutes --set post-success` |

Which figure is the headline: the eight-run `post` set. All eight ran the identical 15-job set, and their failures were confined to the 6–8 s hygiene job (section 1). The success-only set has n=2, so its p50 is its smaller sample and is not used as the headline (run 36363356238).

- **All jobs:** 46.3 → 44.4 unrounded runner-min per ci.yml run at p50, a delta of −1.9; billed 55 → 53, a delta of −2 (run 36086466934 vs run 36362405054 and run 36359795977, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py runner-minutes --set post`).
- **Attributable to phase 218** (excluding the two jobs phases 215 and 217 added, section 4c): 46.3 → 43.7 unrounded, −2.6; billed 55 → 51, −4 (run 36086466934 vs run 36362405054 and run 36359795977, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py comparable-minutes --set post`).

## 3. Wall clock and critical path

The critical-path end offset of a run is the latest `completed_at` of any successful voting job (every job except `ci-required`), measured from the run's first job start. That is BASE-01's critical-path rule, taken per run rather than per job.

| Figure | Set | n | p50 | p95 | min–max | Regenerate |
|---|---|---|---|---|---|---|
| wall clock | set base | n=20 | p50 629 s (run 34758417725) | p95 659 s (run 36255483521) | min–max 535–669 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py wall --set base` |
| wall clock | set post | n=8 | p50 648 s (run 36362405054) | p95 673 s (run 36360336486) | min–max 539–673 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py wall --set post` |
| wall clock | set post-pr | n=4 | p50 648 s (run 36362405054) | p95 664 s (run 36359132030) | min–max 539–664 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py wall --set post-pr` |
| wall clock | set post-dispatch | n=4 | p50 620 s (run 36361003789) | p95 673 s (run 36360336486) | min–max 588–673 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py wall --set post-dispatch` |
| critical-path end offset | set base | n=20 | p50 623 s (run 36256339043) | p95 653 s (run 36255483521) | min–max 527–664 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py critical-path --set base` |
| critical-path end offset | set post | n=8 | p50 643 s (run 36362405054) | p95 665 s (run 36360336486) | min–max 529–665 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py critical-path --set post` |
| critical-path end offset | set post-pr | n=4 | p50 643 s (run 36362405054) | p95 659 s (run 36359132030) | min–max 529–659 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py critical-path --set post-pr` |
| critical-path end offset | set post-dispatch | n=4 | p50 613 s (run 36361003789) | p95 665 s (run 36360336486) | min–max 584–665 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py critical-path --set post-dispatch` |

Which job finishes last:
- Base: verify-example-browser in 16 of 20 runs, "Run test suite (current)" in 3, Tier A capture in 1 (run 36256339043, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py critical-path --set base`).
- Post: verify-example-browser in 7 of 8 runs, "Run test suite (current)" in 1 (run 36362405054, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py critical-path --set post`).

**Delta:**
- Critical-path end offset p50: 623 → 643 s, +20 s (run 36256339043 vs run 36362405054).
- Wall clock p50: 629 → 648 s, +19 s (run 34758417725 vs run 36362405054).

**Reading:** phase 218 did not target the critical path, and did not shorten it. Every removed job (verify-mechanical, verify-docs, verify-hex-package) and the removed capture step finished hundreds of seconds before the browser job in BASE-01. The critical path is still the browser E2E job, and its own p50 moved 623 → 643 s (run 36256339043 vs run 36362405054, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set post`). The +20 s is inside that job's BASE-01 spread of 452–664 s (run 36256339043, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py jobs --workflow ci.yml --event pull_request --job "Example app browser E2E (Playwright)" --format md`) and is not credited to any 218 change [inference: n=8 against n=20, run 36362405054]. The critical path belongs to the later wall-clock phases, not to ECON.

## 4. Per-job attribution

### 4a. Per-job p50, base vs post

| Job id | Job name | Base p50 (full sample unless noted) | Post p50 (all post runs unless noted) | Delta | Cause | Regenerate |
|---|---|---|---|---|---|---|
| verify-mechanical | Mechanical checker (committed scorecards) | 87 s (run 34755017258) | removed | −87 s, −2 billed min | 218-04 (ECON-06) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set base` |
| verify-docs | Build ExDoc (dev) | 75 s (run 34755017258) | removed | −75 s, −2 billed min | 218-04 (ECON-06) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set base` |
| verify-hex-package | Hex package tarball | 17 s (run 34758417725) | removed | −17 s, −1 billed min | 218-04 (ECON-06) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set base` |
| verify-capture | Tier A capture lane (byte-stable evidence) | 532 s (run 36258071425) | 499 s (run 36359132030) | −33 s | 218-04 removed the trailing mechanical step, whose own p50 was 49 s (run 35800922940) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py steps --set base` |
| verify-dialyzer | Dialyzer (current toolchain), PLT hit samples only | 83 s, n=15 (run 35800922940) | 157 s, n=5 (run 36360336486) | +74 s, +1 billed min | 218-03 (ECON-05), section 4b | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| verify-test | Run test suite (current) | 546 s (run 34755536474) | 573 s (run 36359132030) | +27 s | confounded, section 4d | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set post` |
| verify-test | Run test suite (min) | 395 s (run 35788765371) | 318 s (run 36359132030) | −77 s | confounded, section 4d | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set post` |
| verify-deps-audit | Dependency audit (all lockfiles) | not in BASE-01 | 33 s (run 36359795977) | +33 s | phase 215, unrelated | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set post` |
| verify-repo-hygiene | Repo hygiene (no machine-local paths) | not in BASE-01 | 8 s, n=2 successful (run 36363356238) | +8 s | phase 217, unrelated | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set post` |

Jobs that ECON did not change moved by ten seconds or less each: credo 70 → 74 s, format 17 → 17 s, compile-no-optional 61 → 51 s, hex-evaluator 62 → 65 s, pgbouncer 109 → 114 s, release-shape 6 → 7 s, bump-rehearsal 165 → 163 s (`python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set post` against `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set base`). One Tier A capture dispatch sample took only 318 s (run 36359171595). It is the minimum, not the p50, and is left in.

**Reconciliation [inference]:** the per-job deltas sum to −87 −75 −17 −33 +74 = −138 s, about −2.3 runner-min. The measured attributable delta in section 2 is −2.6 unrounded. The remaining −0.3 min is the net of the unchanged jobs' drift and the confounded test lanes (run 36362405054, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py comparable-minutes --set post`). Billed, the three removed jobs are −5 whole minutes per run and verify-dialyzer is +1 (83 s bills 2 min, 157 s bills 3), so −4, which matches the measured billed delta of 55 → 51 (run 36086466934, run 36359795977).

### 4b. verify-dialyzer: PLT hit / miss labels

Each sample is labeled from its `Report exact PLT cache hit` step. That step runs only on an exact cache-key hit and prints `THREADLINE_DIALYZER_PLT_CACHE=hit`. On a miss, `Build and measure Dialyzer PLT on cache miss` runs instead and prints `THREADLINE_DIALYZER_PLT_CACHE=miss` and the PLT build wall time.
- Post-landing samples: the step output was read from all eight job logs (`gh run view --repo szTheory/threadline --job <job id> --log`, grep `THREADLINE_DIALYZER_PLT`).
- Baseline samples: labeled from the step conclusions in the committed 214 raw job data. Two logs were retrieved as spot checks, and both agree: run 35721615532 printed `miss` with a 137.07 s PLT build, and run 36086466934 printed `hit` (`gh run view --repo szTheory/threadline --job <job id> --log`).

| Run | Label | Job | PLT build step | Regenerate |
|---|---|---|---|---|
| run 36359132030 | miss (warm: prefix-restored PLT, logged build 0.64 s) | 162 s | success 1 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| run 36359171595 | miss (warm: prefix-restored PLT, logged build 0.66 s) | 167 s | success 1 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| run 36359795977 | hit | 162 s | skipped | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| run 36360336486 | hit | 157 s | skipped | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| run 36361003789 | hit | 158 s | skipped | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| run 36362405054 | hit | 135 s | skipped | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| run 36363356238 | hit | 147 s | skipped | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| run 36364354586 | miss (warm: prefix-restored PLT, logged build 0.48 s) | 127 s | success 1 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |

| Samples | Set | n | p50 | p95 | min–max | Regenerate |
|---|---|---|---|---|---|---|
| verify-dialyzer hit samples | set base | n=15 | p50 83 s (run 35800922940) | p95 88 s (run 36255483521) | min–max 62–88 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set base` |
| verify-dialyzer miss samples | set base | n=5 | p50 86 s (run 35793597110) | p95 226 s (run 35763570382) | min–max 73–226 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set base` |
| verify-dialyzer hit samples | set post | n=5 | p50 157 s (run 36360336486) | p95 162 s (run 36359795977) | min–max 135–162 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| verify-dialyzer miss samples | set post | n=3 | p50 162 s (run 36359132030) | p95 167 s (run 36359171595) | min–max 127–167 s | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |

The baseline misses are of two kinds (`python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set base`):
- Two cold PLT builds: 137 s and 139 s build steps, jobs 221 s and 226 s (run 35721615532, run 35763570382).
- Three warm prefix-restore misses with a 0–1 s build step (run 35793597110, run 36084754688, run 36256339043).

None of the post-landing misses is cold. 218-03 expected the first post-landing run to build the PLT cold, because the exact cache key hashes `mix.exs`. It did not, because the `restore-keys` prefix restored an older PLT and the update took 0.64 s (run 36359132030).

**Attribution (hit samples only):** verify-dialyzer grew by +74 s at p50, from 83 s to 157 s (run 35800922940 vs run 36360336486). The new work shows in the hit samples' steps:
- the postgres service container that 218-03 added: `Initialize containers` p50 22 s, a step the base job did not have (run 36359795977, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py steps --set post`);
- the `Live Dialyzer slice proof (fails closed)` step: p50 54 s, most of it a test-env compile before the single test runs (run 36360336486, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py steps --set post`).

The shared steps did not grow: compile 59 → 53 s and analysis 8 → 8 s at p50 (run 34757305454 vs run 36360336486, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py steps --set base`).

The slowest post sample took 167 s (run 36359171595), about a quarter of the 12-minute job timeout 218-03 set (`git grep -n -A2 'verify-dialyzer:' -- .github/workflows/ci.yml`).

### 4c. Unrelated changes landed since BASE-01 (not credited to phase 218)

Between BASE-01's origin/main and the land branch, ci.yml also changed for reasons outside ECON (`git log --oneline 5e78b2f05d00619e11aa9b29bc8f612087756846..HEAD -- .github/workflows/ci.yml`):
- Phase 215 added `verify-deps-audit` to ci-required (83eb1cf8). It adds p50 33 s per run (run 36359795977).
- Phase 217 added `verify-repo-hygiene` to ci-required (85b84f85). It adds p50 8 s per run (run 36363356238).
- Toolchain commits moved the min test lane from ubuntu-22.04 to ubuntu-24.04, pinned the matrix, and installed `.tool-versions` in every non-matrix job (6f7d40ca, ddb0c771, 8642610e). The cache and upload actions moved to their Node 24 majors (702d3d5f). These changes touch every job's setup time and the min lane's runner image (`git show --stat 6f7d40ca`).

The attributable runner-minute line removes the two added jobs. The toolchain changes cannot be subtracted per job; they are the main reason the test-lane rows below are not attributed.

### 4d. verify-test lanes (ECON-05's test-lane saving)

ECON-05 took the `:live_dialyzer` test out of default `mix test`, so the test lanes no longer pay its dev-env compile and vacuous Dialyzer call (BASE-01 section 8).

The measured `Run tests` step medians (p50):
- current lane: 268 → 273 s (run 34755536474 vs run 36359132030, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py steps --set post`);
- min lane: 306 → 239 s (run 35788765371 vs run 36359171595, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py steps --set post`).

The job-level deltas are +27 s (current) and −77 s (min) (run 36359132030, `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set post`).

These deltas are not attributable to ECON-05, for two reasons:
- The suite grew from 2207 tests at BASE-01 (`bash .planning/phases/214-baseline-measurement/tools/measure-local.sh slowest`) to 2460 at 0d000785 (run 36359135268).
- The min lane changed runner image (see the unrelated-changes list above).

The removed cost is bounded, not measured. BASE-01's local cold-PLT row was a 1.21 s vacuous pass plus a dev compile that the local run did not pay. On CI, a comparable dev compile is the verify-dialyzer `Compile full optional build` step, p50 59 s. So the saving is at most about one minute per lane per run [inference: `bash .planning/phases/214-baseline-measurement/tools/measure-local.sh live-dialyzer`, run 34757305454]. The min lane's −67 s step delta is consistent with that bound. The current lane's +5 s is not, because suite growth outweighs it there (run 36359171595, run 36359132030).

## 5. Flake Detection

Both dispatches ran the full suite; the SHA gate printed `decision=run` / `reason=no prior proof of this SHA and no red upstream; running the suite` in each (run 36359135268, run 36364688861).

| Workflow | Event / regime | Figure | Figure | Figure | Figure | Regenerate |
|---|---|---|---|---|---|---|
| flake-detection.yml | workflow_dispatch | 2 runs 2026-09-27 to 2026-09-28 (run 36359135268 to run 36364688861) | failure 1, success 1 | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event workflow_dispatch --since 2026-09-27` |
| flake-detection.yml | workflow_dispatch | successful wall n=1 | p50 45.7 min (run 36364688861) | p95 45.7 min (run 36364688861) | min–max 45.7–45.7 min | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event workflow_dispatch --since 2026-09-27` |
| flake-detection.yml | workflow_dispatch | window total | unrounded 102.2 min | billed 103 min | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event workflow_dispatch --since 2026-09-27` |
| flake-detection.yml | regime: failure (>= 10 min) | 1 runs | first 2026-09-27 (run 36359135268) | last 2026-09-27 (run 36359135268) | wall 56.6–56.6 min | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event workflow_dispatch --since 2026-09-27 --regimes` |
| flake-detection.yml | regime: success | 1 runs | first 2026-09-28 (run 36364688861) | last 2026-09-28 (run 36364688861) | wall 45.7–45.7 min | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event workflow_dispatch --since 2026-09-27 --regimes` |

**Before the resize, run 36359135268 at 0d000785: `inconclusive`, budget did not hold.**
- The classify step printed `Flake Detection classification: inconclusive (completed iterations: 16, exit: 124)` (run 36359135268).
- The issue step carried `REASON: budget exhausted after 15 clean iteration(s); iteration 16 was cut off by the time budget` (run 36359135268).
- All 15 completed suite runs reported `9 properties, 2460 tests, 0 failures, 3 excluded`: 268.3 s cold, then 206.2–213.5 s per repeat (run 36359135268).
- The `Repeat the suite until failure` step ran the full 3300 s, which is the 55-minute `timeout(1)` budget, and the job took 56.6 min (run 36359135268).
- This is 218-08 deviation 3. 218-05 sized 15 repeats from BASE-01's 1698-test figures (run 35967937335), which the grown suite no longer fits. The fix resized the lane to 12 repeats and left the budget and timeouts unchanged (`git show --stat fbfbcb11`).

**After the resize, run 36364688861 at 37e36cb2: `pass`, budget held.**
- The classify step printed `Flake Detection classification: pass (completed iterations: 13, exit: 0)` (run 36364688861).
- All 13 suite runs reported `9 properties, 2469 tests, 0 failures, 3 excluded`: 255.9 s cold, then 197.4–201.2 s per repeat (run 36364688861).
- The repeat step took 2650 s, 650 s (about 20%) under the 3300 s budget, and the job took 45.7 min (run 36364688861).
- The close step then closed #36 (run 36364688861).

**Monthly [inference]:** Flake Detection is now weekly (Monday 07:00 UTC) plus on demand, and a scheduled run skips a SHA the workflow already proved green (`git grep -n cron -- .github/workflows/flake-detection.yml`).
- At most 52/12 ≈ 4.33 scheduled runs per month × 45.7 min ≈ 198 runner-min per month, if every weekly run lands on a new SHA [inference: 4.33 × run 36364688861].
- About 0 on weeks where main has not moved since the last green flake run [inference: SHA gate `decision=skip` path, run 36364688861].
- Against BASE-01's steady-state 2,940–4,110 runner-min per month [inference: 30 × run 36106137910 and run 36225676728], that is about 2,742–3,912 fewer runner-min per month [inference: run 36364688861, run 36106137910, run 36225676728].
- No weekly scheduled sample was waited for (D-11). The weekly figure is the dispatch run times the cadence (run 36364688861).

## 6. Browser-full

| Workflow | Event / regime | Figure | Figure | Figure | Figure | Regenerate |
|---|---|---|---|---|---|---|
| browser-full.yml | workflow_dispatch | 2 runs 2026-09-27 to 2026-09-28 (run 36359136941 to run 36363979144) | failure 1, success 1 | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event workflow_dispatch --since 2026-09-27` |
| browser-full.yml | workflow_dispatch | successful wall n=1 | p50 6.4 min (run 36363979144) | p95 6.4 min (run 36363979144) | min–max 6.4–6.4 min | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event workflow_dispatch --since 2026-09-27` |
| browser-full.yml | workflow_dispatch | window total | unrounded 11.1 min | billed 12 min | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event workflow_dispatch --since 2026-09-27` |
| browser-full.yml | regime: fast failure (< 10 min) | 1 runs | first 2026-09-27 (run 36359136941) | last 2026-09-27 (run 36359136941) | wall 4.7–4.7 min | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event workflow_dispatch --since 2026-09-27 --regimes` |
| browser-full.yml | regime: success | 1 runs | first 2026-09-28 (run 36363979144) | last 2026-09-28 (run 36363979144) | wall 6.4–6.4 min | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event workflow_dispatch --since 2026-09-27 --regimes` |

**Projects, from the job logs.** Both runs printed the same notice line, `::notice::Browser-full projects: --project=graded-capture --project=refute-capture --project=route-capture --project=storybook-capture`. These are the four projects ci.yml does not run (run 36359136941, run 36363979144, `gh run view --repo szTheory/threadline --job <job id> --log`).
- Run 36359136941, at 0d000785: `Running 4 tests using 1 worker`, then `1 failed` / `3 passed (2.0m)`. The failure was refute-capture's `missing tier-a cell dir for refute.hierarchy.flattened.polished — run the tier-a-capture lane first` (run 36359136941). This is 218-08 deviation 1: 218-07's partition removed tier-a-capture from Browser-full, and refute-capture had an undeclared dependency on it.
- Run 36363979144, at a72fcd32, after refute-capture declared `dependencies: ["tier-a-capture"]`: `Running 5 tests using 1 worker` and `5 passed (4.0m)`. The fifth test is tier-a-capture, pulled in as the declared dependency (run 36363979144). The Playwright step took 332 s, well inside its 45-minute step timeout, so the cost question deviation 1 left open is answered (run 36363979144).

**Per run:** 6.4 min for the post-fix run, against BASE-01's 18.0 min p50 per push run (run 35780709940) and 14.5 min p50 per successful nightly (run 34932091760). That is −11.6 min per push run [inference: run 36363979144 vs run 35780709940; a dispatch run stands in for the push run, same job and project list].

**Monthly [inference]:**
- Nightly: about 0 runner-min on unchanged SHAs. The nightly now skips a SHA it already proved green through `bin/ci-sha-gate`, and every main SHA gets a push-event Browser-full run first. BASE-01 put the nightly at 30 × 14.5 = 435 runner-min per month [inference: run 34932091760 × 30 nights; skip path per 218-07, run 36363979144].
- Push lane: at BASE-01's 20 pushes per window, 20 × 6.4 ≈ 128 runner-min per month, against BASE-01's 331.2 [inference: run 36363979144 × 20, run 33138291365 to run 36258719891].
- No nightly scheduled sample was waited for (D-11).

## 7. Tracking issues and release PR

Both issue states were read with `gh issue view 28 --repo szTheory/threadline --json number,title,state,closedAt,stateReason` and the same for 36.

- **#28** "Browser (full project set) is failing": `CLOSED`, stateReason `COMPLETED`, closedAt 2026-09-28T01:01:34Z. It was closed by run 36363979144's step `Close the browser-lane tracking issue on green`, which logged `✓ Closed issue szTheory/threadline#28` / `action=close` / `issue_number=28`. Earlier, the failed run 36359136941 had updated #28 (`action=update`, `issue_number=28`) (run 36363979144, run 36359136941).
- **#36** "Flake Detection: test suite reported unknown": `CLOSED`, stateReason `COMPLETED`, closedAt 2026-09-28T01:52:01Z. It was closed by run 36364688861's step `Close the flake tracking issue on a passing run`, which logged `✓ Closed issue szTheory/threadline#36` / `action=close` / `issue_number=36`. Earlier, the `inconclusive` run 36359135268 had updated #36 with the inconclusive reason (`action=update`, `issue_number=36`) (run 36364688861, run 36359135268).
- Both closes came from workflow_dispatch runs on the land branch, not from main. The `--close` path (218-02, wired in 218-06 and 218-07) is therefore proven end to end on real issues. The 218-02 hand-off is discharged (run 36363979144, run 36364688861).

**ECON-03 (release PR single run) [inference].** No release cycle ran in this phase. In BASE-01, each release PR head was tested twice on one SHA: v0.11.0 by run 36256339043 (pull_request) and run 36256344029 (workflow_dispatch bootstrap). With the 218-01 guard, the bootstrap dispatches only when `RELEASE_PLEASE_TOKEN` is absent. So a release cycle with the token configured drops one full ci.yml run: 47.2 unrounded / 58 billed runner-min at BASE-01 prices (run 36256344029), or about 44.4 at this phase's per-run p50 (run 36362405054). The guard is pinned by `mix test test/threadline/release_control_plane_contract_test.exs` and its mutation controls [inference: run 36256339043, run 36256344029].

## 8. Live Dialyzer in verify-dialyzer

The first post-landing verify-dialyzer job (run 36359132030) and all seven after it ran the new `Live Dialyzer slice proof (fails closed)` step with a PLT present: an exact hit or a warm prefix restore, never an absent PLT (section 4b). Its output in run 36359132030 (`gh run view --repo szTheory/threadline --job <job id> --log`):

```
Run mix verify.dialyzer_slice
  MIX_ENV: test
Running ExUnit with seed: 307864, max_cases: 8
Excluding tags: [:test, {:pgbouncer_topology, true}]
Including tags: [:live_dialyzer]
.
Finished in 8.9 seconds (0.00s async, 8.9s sync)
17 tests, 0 failures, 16 excluded
```

The same `Including tags: [:live_dialyzer]` / `17 tests, 0 failures, 16 excluded` pair appears in all eight post-landing verify-dialyzer logs (run 36359132030 through run 36364354586).

**What the log does and does not show.** The plan expected the literal lines `verified slice critic-tooling: 3/40 sealed warnings` and `0 live warnings` in the CI log. They are not there. The test captures the verifier's stdout through `System.cmd` and asserts on it, and ExUnit prints nothing on a pass. The CI evidence is therefore indirect, but it is tight (run 36359132030):
- exactly one test ran, the `:live_dialyzer` one (the single `.`, 16 excluded) (run 36359132030);
- that test asserts `status == 0`, `output =~ "verified slice critic-tooling: 3/40 sealed warnings"` and `output =~ "0 live warnings"` (`git grep -n -A6 'committed critic-tooling slice has no live warnings' -- test/threadline/dialyzer_slice_contract_test.exs`);
- since 218-03, the verifier fails with `Dialyzer did not complete` when the raw output lacks dialyxir's completion marker, so a missing PLT can no longer pass vacuously (`git grep -n 'Dialyzer did not complete' -- bin/verify-dialyzer-slice`).

A pass therefore means the verifier printed both strings on CI. The literal lines were printed and quoted locally in 218-03 (`MIX_ENV=test mix test test/threadline/dialyzer_slice_contract_test.exs --only live_dialyzer`). Printing them in the CI log needs a code change and another push. That is recorded in `deferred-items.md`, not done here.

## 9. Summary of deltas

| Figure | BASE-01 | Post-change | Delta | Status | Regenerate |
|---|---|---|---|---|---|
| Runner-min per ci.yml run, every job | unrounded p50 46.3 / billed 55 (run 36086466934) | unrounded p50 44.4 (run 36362405054) / billed 53 (run 36359795977), n=8 | −1.9 unrounded / −2 billed | measured | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py runner-minutes --set post` |
| Runner-min per ci.yml run, attributable to 218 | unrounded p50 46.3 / billed 55 (run 36086466934) | unrounded p50 43.7 (run 36362405054) / billed 51 (run 36359795977), n=8 | −2.6 unrounded / −4 billed | measured | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py comparable-minutes --set post` |
| Critical-path end offset | p50 623 s (run 36256339043) | p50 643 s (run 36362405054) | +20 s, inside the browser job's own spread | measured, not credited | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py critical-path --set post` |
| Wall clock per ci.yml run | p50 629 s (run 34758417725) | p50 648 s (run 36362405054) | +19 s | measured | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py wall --set post` |
| verify-dialyzer, PLT hit only | p50 83 s, n=15 (run 35800922940) | p50 157 s, n=5 (run 36360336486) | +74 s (container init plus live step) | measured | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py dialyzer --set post` |
| Removed jobs and capture step | 87 + 75 + 17 s jobs, 49 s step (run 34755017258, run 34758417725, run 35800922940) | 0 | −179 s jobs, capture job −33 s | measured | `python3 .planning/phases/218-ci-economy-remove-waste/tools/remeasure-218.py jobs --set base` |
| Flake Detection per run | successful nightly 98.0–137.0 min (run 36106137910, run 36225676728) | 45.7 min, `pass`, 13 iterations (run 36364688861) | about −52 to −91 min per run | measured | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event workflow_dispatch --since 2026-09-27` |
| Flake Detection per month | 2,940–4,110 (run 36106137910, run 36225676728) | at most about 198, about 0 on an unchanged SHA (run 36364688861) | about −2,742 to −3,912 | [inference] | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow flake-detection.yml --event workflow_dispatch --since 2026-09-27` |
| Browser-full per run | push p50 18.0 min (run 35780709940) | 6.4 min, 4 projects plus tier-a-capture as a dependency (run 36363979144) | −11.6 min | measured (dispatch standing in for push) | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event workflow_dispatch --since 2026-09-27` |
| Browser-full per month | nightly 435 plus push 331.2 (run 34932091760, run 36258719891) | nightly about 0 on unchanged SHAs, push about 128 (run 36363979144) | about −638 | [inference] | `python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py workflow-cost --workflow browser-full.yml --event workflow_dispatch --since 2026-09-27` |
| Release cycle | PR head tested twice (run 36256339043, run 36256344029) | once when `RELEASE_PLEASE_TOKEN` is set | −1 ci.yml run, about −47 runner-min per release | [inference] | `mix test test/threadline/release_control_plane_contract_test.exs` |
| Tracking issues #28 / #36 | open (218-02 hand-off) | both `CLOSED` by the green dispatch runs (run 36363979144, run 36364688861) | resolved | measured | `gh issue view 36 --repo szTheory/threadline --json state,closedAt` |

**Push-to-main unit [inference].** No push to main was measured (the milestone has not merged). Derived from the per-job deltas, BASE-01's push unit p50 of 66.2 unrounded (run 36087413569) drops by about 2.6 on CI and 11.6 on Browser-full, and gains about 0.7 from the two unrelated jobs, landing near 52.7 runner-min per push [inference: run 36087413569, run 36362405054, run 36363979144]. The first post-merge push run is the measurement that confirms or corrects this.
