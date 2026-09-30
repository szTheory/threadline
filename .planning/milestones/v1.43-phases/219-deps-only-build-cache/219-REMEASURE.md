# Phase 219: CI Re-measurement of the Deps-Only Build Cache (CACHE-01)

This record measures what the deps-only build cache changes in CI, against the phase 214 baseline (BASE-01, `.planning/phases/214-baseline-measurement/214-BASELINE.md`) and against the phase 218 re-measure (`.planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md`).

## 0. Method

- Code under measurement: the plan 02 commit, which lands on branch `land/v1.43-217-218` as the cherry-pick 7dbad5ff (the milestone branch carries it as cfa615a9). The branch also carries the phase 219 contract commits and the mint security bump (586a8fec), which changes `mix.lock`, so every sample below runs on post-fix cache keys. The first ci.yml run of this code is run 36446346094, a pull_request run for PR #60 at head 82c32fbc.
- Pushes: two to the PR (head 82c32fbc, then 9593d9f7), then eight granted `workflow_dispatch` runs on the branch at 9593d9f7, dispatched one at a time so each could read what the previous one saved (run 36447911272 through run 36457705448). No run was re-run or cancelled.
- Tools: the phase 218 collector, summarizer and citation checker, copied into this phase's `tools/` directory so that phase 219 runs never land in the 214 or 218 evidence. The copies differ from the 218 originals only in their self-path strings and in the checker's phase-number exemption, which now accepts phases 214 through 219 (`git diff --no-index .planning/phases/218-ci-economy-remove-waste/tools/check-citations.py .planning/phases/219-deps-only-build-cache/tools/check-citations.py`).
- Raw data: this phase's own `raw/ci/manifest.json` and `raw/ci/runs/`, written by `bash .planning/phases/219-deps-only-build-cache/tools/collect-ci-runs.sh --workflow ci.yml --event pull_request --status any --since 2026-09-28 --target 0 --min 1` and the same with `--event workflow_dispatch`.
- Figures: `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py --help` imports the copied summarizer's arithmetic unchanged (job duration, nearest-rank percentiles, unrounded and billed minutes). It reads the 214 and 218 raw data in place, read-only. Its `--set base` reproduces BASE-01 (per PR p50 46.3 unrounded and 55 billed runner-min, run 36086466934) and its `--set post218` reproduces the 218 headline (p50 44.4 unrounded, run 36362405054; 53 billed, run 36359795977), `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set post218`.
- Dropped runs: the `--since 2026-09-28` listings also return six runs of the same branch from before the phase 219 push, which ran the 218 code (run 36361003789, run 36362405054, run 36363356238, run 36364354586, run 36370035321, run 36370640310). They stay in the raw data and are excluded from every figure below: `git merge-base --is-ancestor 7dbad5ff <head>` is false for all six heads and true for all ten kept heads (`git merge-base --is-ancestor 7dbad5ff 9593d9f7`). The script's own `all219` filter (some job has a compile-on-miss step) keeps exactly the same ten runs (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples`). One of the six, run 36370035321, is also cancelled; cancelled runs are never samples.

**Hit / miss labels (D-18), from the committed job JSON only.** Each cached job carries up to two cache pairs: root (`Compile dependencies on build cache miss`) and example (`Compile example dependencies on cache miss`). The collector keeps each job's steps in list order and drops the step numbers, so order is list position.
- A pair votes only when the install step immediately before its compile-on-miss step concluded `success`. That install step runs unconditionally, except for the test job's `matrix.lane == 'current'` guard on the example block. So its success proves every earlier step succeeded and the lane guard let the block run.
- A voting pair is `hit` when its compile-on-miss step was `skipped` and `miss` when it concluded `success`. Anything else is `n/a`. So the min lane's lane-guarded example pair, or a pair skipped after an upstream failure, is `n/a` and never counts as a hit.
- A hit becomes `in-run` when another job of the same run had already saved that cache family when this pair's restore step started (step timestamps). The example family counts any sibling's `Save example deps and deps-only build cache`. The root family counts only the save in `Run test suite (current)`, the one job that saves the key PgBouncer restores; the min lane's root key differs. An `in-run` hit is cold-run evidence: no entry for that key existed in the scope when the run started, and a sibling job did the cold work minutes earlier.
- A run is `warm` when every voting pair is a genuine `hit`, `cold` when every voting pair is `miss` or `in-run`, and `mixed` otherwise. The labeller's synthetic cases pass (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py --self-test`).

**Cache scope.** A pull_request run saves to and restores from `refs/pull/60/merge`; a dispatch run uses `refs/heads/land/v1.43-217-218`. Neither reads the other's entries, and main holds no `build-v1` entry until phase 219 merges. So the first run in each scope is cold and every later run in the same scope is warm (`gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref,lastAccessedAt`).

**Baselines.** Every delta quotes the BASE-01 figure and the 218 figure with the run IDs behind each. Projections carry [inference] and cite the runs they rest on. The whole record is checked by `python3 .planning/phases/219-deps-only-build-cache/tools/check-citations.py .planning/phases/219-deps-only-build-cache/219-REMEASURE.md`.

## 1. Samples

Ten ci.yml runs of the phase 219 code, all concluded `success`: 2 cold and 8 warm, meeting D-25 (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples`). The Scope column names the cache scope each event reads (PR #60 and the land branch, run 36446346094).

| Run | Event | Head | Scope | Conclusion | Test (current) root | Test (current) example | Test (min) root | Test (min) example | PgBouncer root | Browser (Playwright) example | Capture example | Class | Regenerate |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| run 36446346094 | pull_request | 82c32fbc | refs/pull/60/merge | success | miss | in-run | miss | n/a | miss | miss | miss | cold | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36447864779 | pull_request | 9593d9f7 | refs/pull/60/merge | success | hit | hit | hit | n/a | hit | hit | hit | warm | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36447911272 | workflow_dispatch | 9593d9f7 | refs/heads/land/v1.43-217-218 | success | miss | in-run | miss | n/a | miss | miss | miss | cold | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36449352051 | workflow_dispatch | 9593d9f7 | refs/heads/land/v1.43-217-218 | success | hit | hit | hit | n/a | hit | hit | hit | warm | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36450388764 | workflow_dispatch | 9593d9f7 | refs/heads/land/v1.43-217-218 | success | hit | hit | hit | n/a | hit | hit | hit | warm | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36453043277 | workflow_dispatch | 9593d9f7 | refs/heads/land/v1.43-217-218 | success | hit | hit | hit | n/a | hit | hit | hit | warm | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36454272684 | workflow_dispatch | 9593d9f7 | refs/heads/land/v1.43-217-218 | success | hit | hit | hit | n/a | hit | hit | hit | warm | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36455432448 | workflow_dispatch | 9593d9f7 | refs/heads/land/v1.43-217-218 | success | hit | hit | hit | n/a | hit | hit | hit | warm | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36456537357 | workflow_dispatch | 9593d9f7 | refs/heads/land/v1.43-217-218 | success | hit | hit | hit | n/a | hit | hit | hit | warm | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |
| run 36457705448 | workflow_dispatch | 9593d9f7 | refs/heads/land/v1.43-217-218 | success | hit | hit | hit | n/a | hit | hit | hit | warm | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples` |

**Both first runs label `cold`, as the scope rule predicts.** The per-pair evidence for the two cold runs (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache --set cold`):
- Run 36446346094, the first PR run: Browser E2E and Capture missed and saved the example key (Capture's save completed 15:49:59Z, Browser E2E's 15:50:13Z). The current test lane restored the same example key at 15:54:28Z, after both saves, so its hit is `in-run` (run 36446346094).
- Run 36447911272, the first dispatch: the same pattern. Capture saved at 16:02:38Z and Browser E2E at 16:02:56Z; the current lane restored at 16:07:02Z (run 36447911272).
- In both, PgBouncer's root restore started before the current lane's root save completed, so PgBouncer compiled its own dependencies and shows a plain `miss` (run 36446346094, run 36447911272).
- The min lane's example pair is `n/a` in every run: its restore, install and compile steps are skipped by the lane guard (run 36446346094).

**Warm runs have no successful save anywhere,** which is what the save guard (D-14, D-15) implies for a run that hit every key. For example, in run 36447864779 every sibling save step concluded `skipped` (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache --set warm`).

The orchestrator's reading of the `THREADLINE_BUILD_CACHE` / `THREADLINE_EXAMPLE_BUILD_CACHE` log lines agrees with every label above. The labels themselves come from the committed JSON, not the logs (run 36446346094 through run 36457705448).

## 2. Runner-minutes per ci.yml run

Runner-minutes sum every job that occupied a runner, including `ci-required` (unrounded = seconds / 60; billed = per-job whole minutes rounded up), as in BASE-01 section 3a (run 36086466934).

| Unit | Set | n | Unrounded p50 | Unrounded p95 | Billed p50 | Billed p95 | Regenerate |
|---|---|---|---|---|---|---|---|
| per ci.yml run, every job that ran | set base | n=20 | unrounded p50 46.3 min (run 36086466934) | unrounded p95 49.3 min (run 36256339043) | billed p50 55 min (run 36086466934) | billed p95 59 min (run 36256339043) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set base` |
| per ci.yml run, every job that ran | set post218 | n=8 | unrounded p50 44.4 min (run 36362405054) | unrounded p95 46.9 min (run 36360336486) | billed p50 53 min (run 36359795977) | billed p95 57 min (run 36360336486) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set post218` |
| per ci.yml run, every job that ran | set warm | n=8 | unrounded p50 39.3 min (run 36455432448) | unrounded p95 41.7 min (run 36456537357) | billed p50 49 min (run 36450388764) | billed p95 50 min (run 36456537357) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set warm` |
| per ci.yml run, every job that ran | set cold | n=2 | unrounded p50 42.1 min (run 36447911272) | unrounded p95 43.6 min (run 36446346094) | billed p50 51 min (run 36447911272) | billed p95 52 min (run 36446346094) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set cold` |

- **Warm against 218:** 44.4 → 39.3 unrounded runner-min per ci.yml run at p50, a delta of −5.1; billed 53 → 49, −4 (run 36362405054 and run 36359795977 vs run 36455432448 and run 36450388764).
- **Warm against BASE-01:** 46.3 → 39.3 unrounded, −7.0; billed 55 → 49, −6 (run 36086466934 vs run 36455432448 and run 36450388764). This includes phase 218's own −1.9 / −2 (run 36362405054).
- **Cold against 218:** 44.4 → 42.1 unrounded, −2.3; billed 53 → 51, −2 (run 36362405054 vs run 36447911272). A cold run was not more expensive than a 218 run. Section 5 explains why: a miss moves the dependency compile into its own step rather than adding one, and in both cold runs the current lane's example compile was already served in-run (run 36446346094, run 36447911272). With n=2 this is a direction, not a measured saving [inference: run 36446346094, run 36447911272].

## 3. Wall clock and critical path

The critical-path end offset of a run is the latest `completed_at` of any successful voting job (every job except `ci-required`), measured from the run's first job start. This is the rule 218 used (run 36256339043).

| Figure | Set | n | p50 | p95 | min–max | Regenerate |
|---|---|---|---|---|---|---|
| wall clock | set base | n=20 | p50 629 s (run 34758417725) | p95 659 s (run 36255483521) | min–max 535–669 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py wall --set base` |
| wall clock | set post218 | n=8 | p50 648 s (run 36362405054) | p95 673 s (run 36360336486) | min–max 539–673 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py wall --set post218` |
| wall clock | set warm | n=8 | p50 552 s (run 36455432448) | p95 609 s (run 36453043277) | min–max 429–609 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py wall --set warm` |
| wall clock | set cold | n=2 | p50 640 s (run 36446346094) | p95 644 s (run 36447911272) | min–max 640–644 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py wall --set cold` |
| critical-path end offset | set base | n=20 | p50 623 s (run 36256339043) | p95 653 s (run 36255483521) | min–max 527–664 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py critical-path --set base` |
| critical-path end offset | set post218 | n=8 | p50 643 s (run 36362405054) | p95 665 s (run 36360336486) | min–max 529–665 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py critical-path --set post218` |
| critical-path end offset | set warm | n=8 | p50 547 s (run 36455432448) | p95 600 s (run 36453043277) | min–max 420–600 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py critical-path --set warm` |
| critical-path end offset | set cold | n=2 | p50 635 s (run 36446346094) | p95 637 s (run 36447911272) | min–max 635–637 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py critical-path --set cold` |

Which job finishes last (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py critical-path --set warm`):
- Base: Browser E2E in 16 of 20 runs, the current test lane in 3, Tier A capture in 1 (run 36256339043).
- Post218: Browser E2E in 7 of 8 runs, the current test lane in 1 (run 36362405054).
- Warm: Browser E2E in 6 of 8 runs, the current test lane in 1, Tier A capture in 1 (run 36455432448).
- Cold: Browser E2E in 2 of 2 (run 36446346094).

**Delta:**
- Critical-path end offset p50, warm: 643 → 547 s against 218, −96 s (run 36362405054 vs run 36455432448); 623 → 547 s against BASE-01, −76 s (run 36256339043 vs run 36455432448).
- Wall clock p50, warm: 648 → 552 s against 218, −96 s (run 36362405054 vs run 36455432448); 629 → 552 s against BASE-01, −77 s (run 34758417725 vs run 36455432448).
- Cold: critical path 643 → 635 s against 218, −8 s, inside the spread (run 36362405054 vs run 36446346094).

**Reading:** the critical path is still Browser E2E, and the warm saving on the critical path is that job's own saving (section 4). The warm spread is wide, 420–600 s, because the Playwright step itself is bimodal (365–544 s warm, run 36449352051, run 36453043277, `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm`). So n=8 carries noise of the same order as the saving; the p50 is the headline, and the min–max is reported rather than hidden.

## 4. Per-job p50 against BASE-01 and against 218

### 4a. Cached jobs

| Job id | Job name | Base p50 | Post-218 p50 | Warm p50 | Cold p50 | Delta vs 214 | Delta vs 218 | Regenerate |
|---|---|---|---|---|---|---|---|---|
| verify-test | Run test suite (current) | 546 s (run 34755536474) | 573 s (run 36359132030) | 457 s (run 36456537357) | 496 s (run 36447911272) | −89 s | −116 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| verify-test | Run test suite (min) | 395 s (run 35788765371) | 318 s (run 36359132030) | 341 s (run 36449352051) | 387 s (run 36446346094) | −54 s | +23 s, not demonstrated (4b) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| verify-pgbouncer-topology | PgBouncer transaction topology | 109 s (run 36083676177) | 114 s (run 36362405054) | 72 s (run 36457705448) | 112 s (run 36446346094) | −37 s | −42 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| verify-example-browser | Example app browser E2E (Playwright) | 623 s (run 36256339043) | 643 s (run 36362405054) | 547 s (run 36455432448) | 634 s (run 36446346094) | −76 s | −96 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| verify-capture | Tier A capture lane (byte-stable evidence) | 532 s (run 36258071425) | 499 s (run 36359132030) | 413 s (run 36450388764) | 325 s (run 36447911272) | −119 s | −86 s, noisy (4b) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |

The base, post218 and cold columns come from the same subcommand with `--set base`, `--set post218` and `--set cold` (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set cold`).

**Reconciliation [inference]:** the five cached jobs' deltas against 218 sum to −116 + 23 − 42 − 96 − 86 = −317 s, about −5.3 runner-min, against the measured −5.1 unrounded runner-min per run in section 2 (run 36362405054 vs run 36455432448, `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm`). The uncached jobs' net drift makes up the rest (section 4c).

### 4b. Where the saving shows, step by step

Phase 219 moved each job's dependency compile into its own `Compile … on … miss` step (D-07). Before it, the compile ran inside the steps below, so those steps are where a warm hit should shrink. p50 per step, successful steps only (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm`, and the same with `--set base`, `--set post218`, `--set cold`):

| Job | Step | Base p50 | Post-218 p50 | Warm p50 | Delta vs 218 | Regenerate |
|---|---|---|---|---|---|---|
| Test (current) | Compile (warnings as errors) | 42 s (run 34758417725) | 47 s (run 36359171595) | 6 s (run 36453043277) | −41 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| Test (current) | Run tests | 268 s (run 34755536474) | 273 s (run 36359132030) | 281 s (run 36454272684) | +8 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| Test (current) | Verify Threadline Phoenix example | 197 s (run 34755536474) | 203 s (run 36364354586) | 122 s (run 36453043277) | −81 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| Test (min) | Compile (warnings as errors) | 49 s (run 35800922940) | 40 s (run 36359132030) | 7 s (run 36454272684) | −33 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| Test (min) | Run tests | 306 s (run 35788765371) | 239 s (run 36359171595) | 292 s (run 36450388764) | +53 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| PgBouncer | Bootstrap test DB (direct Postgres, bypass pooler) | 49 s (run 34756114944) | 48 s (run 36364354586) | 1 s (run 36450388764) | −47 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| PgBouncer | Compile (warnings as errors), new in 219 | absent (run 34756114944) | absent (run 36364354586) | 5 s (run 36456537357) | +5 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| Browser E2E | Run example Playwright suite | 582 s (run 36256339043) | 594 s (run 36362405054) | 500 s (run 36455432448) | −94 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| Capture | Regenerate Tier A capture | 441 s (run 34756114944) | 450 s (run 36361003789) | 369 s (run 36450388764) | −81 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |

- **Test (current): saving confirmed, −116 s at job level.** The compile step dropped 47 → 6 s and the example step 203 → 122 s, together −122 s (run 36359171595, run 36364354586 vs run 36453043277). `Run tests` moved +8 s, and the suite ran 2466 tests in 240.6 s at 218 and 2502 tests in 238.2 s warm, by ExUnit's own count (run 36363356238, run 36455432448).
- **Test (min): step saving confirmed, job saving not demonstrated against 218.** The compile step dropped 40 → 7 s, −33 s (run 36359132030 vs run 36454272684), close to the expected −38 s. But `Run tests` grew 239 → 292 s at p50 (run 36359171595 vs run 36450388764). ExUnit's own timer shows the growth is inside the suite and not dependency compile: `Finished in 212.4 seconds` for 2466 tests at 218, `Finished in 294.1 seconds` for 2502 tests warm, and the warm log has no `Generated … app` line after the compile step (run 36363356238, run 36455432448). The job-level delta against 218 is therefore +23 s, recorded here and not dropped; the cause of the min-lane suite slowdown is outside this phase and not investigated [inference: one log pair, run 36363356238, run 36455432448]. Against BASE-01 the job is −54 s (run 35788765371 vs run 36449352051).
- **PgBouncer: saving confirmed, −42 s.** Before 219 the bootstrap step compiled every dependency (48 s); warm, it takes 1 s, and the new compile step compiles only threadline in 5 s (run 36364354586 vs run 36450388764, run 36456537357).
- **Browser E2E: saving confirmed at p50, −96 s, with a wide spread.** The Playwright step's warm range is 365–544 s (run 36449352051, run 36453043277), against 488–612 s at 218 (run 36362405054, `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set post218`). The cold runs' own miss step measured the dependency compile the warm hit skips: 78–81 s (run 36446346094, run 36447911272, section 5).
- **Capture: saving present but noise-level against its own spread.** The `Regenerate Tier A capture` step is bimodal in every set: 265–479 s at 218 (run 36362405054), 275–375 s warm (run 36454272684), and 219–243 s in the two cold runs, which is why the cold job p50 (325 s) sits below the warm one (run 36447911272, run 36446346094). The dependency compile the warm hit skips measured 51–57 s in the cold runs (run 36447911272, run 36446346094). So the job-level −86 s against 218 overstates what the cache alone can explain; the cache's share is about the 51–57 s miss step [inference: run 36447911272, run 36446346094, run 36450388764].

### 4c. Uncached jobs (no phase 219 change)

Uncached jobs moved by 13 s or less at p50 against 218 (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` against `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set post218`):
- credo 74 → 78 s (run 36361003789 vs run 36449352051); format 17 → 19 s (run 36359795977 vs run 36453043277);
- compile-no-optional 51 → 60 s (run 36361003789 vs run 36454272684); dialyzer 157 → 159 s (run 36360336486 vs run 36454272684);
- deps-audit 33 → 34 s (run 36359795977 vs run 36447864779); repo-hygiene 8 → 8 s (run 36363356238 vs run 36447864779); release-shape 7 → 7 s (run 36359795977 vs run 36454272684);
- bump-rehearsal 163 → 150 s (run 36361003789 vs run 36449352051); hex-evaluator 65 → 71 s, with one slow warm sample of 100 s at p95 (run 36363356238 vs run 36447864779, run 36456537357).

## 5. Cache step cost (restore, deps.compile, rm, save)

p50 per cache step, split by label, over all ten runs (`python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219`). The `rm` step is the removal of the job's own build before the save; PgBouncer restores but never saves (D-11).

| Job | Cache | Restore (hit) | Restore (miss or in-run) | Compile on miss | rm | Save (miss) | Regenerate |
|---|---|---|---|---|---|---|---|
| Test (current) | root | 1 s, n=8 (run 36450388764) | 1 s, n=2 (run 36446346094) | 40 s, 40–41 s (run 36447911272) | 0 s (run 36453043277) | 1 s, 1–2 s (run 36447911272) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219` |
| Test (current) | example | 2 s, n=8 (run 36449352051) | in-run 1 s, n=2 (run 36447911272) | not run (in-run hit) (run 36446346094) | 0 s (run 36453043277) | not run (run 36446346094) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219` |
| Test (min) | root | 1 s, n=8 (run 36453043277) | 0 s, n=2 (run 36446346094) | 42 s, 42–42 s (run 36446346094) | 0 s (run 36453043277) | 1 s, 1–2 s (run 36447911272) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219` |
| PgBouncer | root | 1 s, n=8 (run 36454272684) | 0 s, n=2 (run 36447911272) | 42 s, 42–43 s (run 36446346094) | 0 s (run 36453043277) | no save step (run 36446346094) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219` |
| Browser E2E | example | 2 s, n=8 (run 36450388764) | 0 s, n=2 (run 36446346094) | 78 s, 78–81 s (run 36446346094) | 0 s (run 36454272684) | 0 s, 0–0 s (run 36446346094) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219` |
| Capture | example | 0 s, p95 2 s, n=8 (run 36457705448) | 0 s, n=2 (run 36446346094) | 51 s, 51–57 s (run 36447911272) | 0 s (run 36453043277) | 1 s, 1–2 s (run 36446346094) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219` |

**The cold-miss penalty is the overhead steps, not the compile.** On a miss the `Compile … on … miss` step does the dependency compile that every job did before phase 219 inside a later step, so it moves work rather than adding it. The added cost of a miss is restore + rm + save: at most 1 + 0 + 2 = 3 s per saving job at p95 (run 36446346094, run 36447911272). A hit costs a 0–3 s restore (run 36457705448, run 36449352051). Step timestamps are whole seconds, so these are resolved to ±1 s (run 36446346094).

## 6. Correctness evidence

All quotes below come from `gh run view <run id> --log --job <job id> --repo szTheory/threadline`, with ANSI colour stripped; timestamps are trimmed and no line contains a runner home path (run 36455432448, run 36446346094).

**Warm root hit and warm example hit, current test lane, run 36455432448 (job 109040463875):**

```
Remove own build (never cached, never reused)                  THREADLINE_BUILD_CACHE=hit key=ubuntu-24.04-otp-OTP-27.3.4.15-elixir-v1.17.3-otp-27-build-v1-root-test-full-0c194951d817bc592cff4f743beba763f761a313fe126834ac763f71d7579d29-e098d77b7acc4b6c74360c91f1d8df156a90b3285ad667cd492eb224b1287843
Remove example app's own build (never cached, never reused)    THREADLINE_EXAMPLE_BUILD_CACHE=hit key=ubuntu-24.04-otp-OTP-27.3.4.15-elixir-v1.17.3-otp-27-build-v1-example-test-full-831b9543da606c7c6d0d3ed9cd79cd294865a22c6e1ad6b5a183af04b64dfbbb-ccc5e4587d280ed25dc8c302a57d9288ac19a976a26ad8bf4e950f7bfcddcc71
```

- **Key shape (RESEARCH A1):** each rendered key ends `-full-<64 hex>-<64 hex>`. Both segments after `-full-` are exactly 64 lowercase hex characters for both keys, so the config-file glob matched and hashed real files (run 36455432448, `gh run view 36455432448 --log --job 109040463875 --repo szTheory/threadline`). The same root and example keys appear in the cold run 36446346094, so the key is stable across the two scopes for one lock and config.
- **No dependency compile on a hit, first-party code recompiled.** The warm job's only `Generated … app` lines are first-party (run 36455432448):

```
Compile (warnings as errors)          Compiling 156 files (.ex)
Compile (warnings as errors)          Generated threadline app
Verify Threadline Phoenix example     ==> threadline
Verify Threadline Phoenix example     Compiling 137 files (.ex)
Verify Threadline Phoenix example     Generated threadline app
Verify Threadline Phoenix example     ==> threadline_phoenix
Verify Threadline Phoenix example     Compiling 84 files (.ex)
Verify Threadline Phoenix example     Generated threadline_phoenix app
```

- The warm Browser E2E job (job 109040463598) and the warm Capture job (job 109040463691) show the same thing for the example: `THREADLINE_EXAMPLE_BUILD_CACHE=hit`, and the only `Generated … app` lines are `threadline` and `threadline_phoenix`, inside `Run example Playwright suite` and `Regenerate Tier A capture` (run 36455432448).
- **Min-lane warm hit, its own key:** the min lane (job 109040463624) logged `THREADLINE_BUILD_CACHE=hit key=ubuntu-24.04-otp-OTP-26.2.5.21-elixir-v1.15.8-otp-26-build-v1-root-test-full-0c194951…-e098d77b…`. Its only `Generated … app` line is `Generated threadline app`, in `Compile (warnings as errors)`, and its suite reported `9 properties, 2502 tests, 0 failures, 3 excluded` (run 36455432448).

**Cold counterpart, run 36446346094.** The current lane (job 109009532219) logged `THREADLINE_BUILD_CACHE=miss` with the same root key, and its `Compile dependencies on build cache miss` step printed 38 `==> <dep>` banners and 37 `Generated <dep> app` lines, starting (run 36446346094):

```
Compile dependencies on build cache miss    ==> file_system
Compile dependencies on build cache miss    Generated file_system app
Compile dependencies on build cache miss    ==> stream_data
Compile dependencies on build cache miss    Generated stream_data app
```

- Browser E2E (job 109009532380) logged `THREADLINE_EXAMPLE_BUILD_CACHE=miss` with the same example key; its miss step printed 52 `==> <dep>` banners and 49 `Generated <dep> app` lines, and `Run example Playwright suite` still compiled `threadline` and `threadline_phoenix` itself (run 36446346094).
- The current lane's example restore in the same cold run logged `THREADLINE_EXAMPLE_BUILD_CACHE=hit`, about four minutes after Capture and Browser E2E saved that key. That is the `in-run` hit of section 1, and it is why the log line alone cannot label a run cold or warm (run 36446346094).

**Pre-219 contrast:** in the 218 run 36363356238, the min lane compiled every dependency inside its test job (`Generated file_system app` through `Generated ex_aws app`, then `Generated threadline app`), with no cache step at all (run 36363356238).

## 7. Cache storage against the 10 GB budget

Read on 2026-09-28 after the last sample, with `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref,lastAccessedAt,createdAt` and `gh api repos/szTheory/threadline/actions/cache/usage`.

| Ref | Key (to the lock hash) | Bytes | Created | Regenerate |
|---|---|---|---|---|
| refs/pull/60/merge | …OTP-27.3.4.15-elixir-v1.17.3-otp-27-build-v1-root-test-full-0c194951… | 10628593 (10.6 MB) | 2026-09-28T15:49:37Z (run 36446346094) | `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref,createdAt` |
| refs/pull/60/merge | …OTP-26.2.5.21-elixir-v1.15.8-otp-26-build-v1-root-test-full-0c194951… | 9980409 (10.0 MB) | 2026-09-28T15:49:37Z (run 36446346094) | `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref,createdAt` |
| refs/pull/60/merge | …OTP-27.3.4.15-elixir-v1.17.3-otp-27-build-v1-example-test-full-831b9543… | 18768261 (18.8 MB) | 2026-09-28T15:49:59Z (run 36446346094) | `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref,createdAt` |
| refs/heads/land/v1.43-217-218 | …OTP-27.3.4.15-elixir-v1.17.3-otp-27-build-v1-root-test-full-0c194951… | 10627331 (10.6 MB) | 2026-09-28T16:02:13Z (run 36447911272) | `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref,createdAt` |
| refs/heads/land/v1.43-217-218 | …OTP-26.2.5.21-elixir-v1.15.8-otp-26-build-v1-root-test-full-0c194951… | 9980888 (10.0 MB) | 2026-09-28T16:02:19Z (run 36447911272) | `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref,createdAt` |
| refs/heads/land/v1.43-217-218 | …OTP-27.3.4.15-elixir-v1.17.3-otp-27-build-v1-example-test-full-831b9543… | 18767714 (18.8 MB) | 2026-09-28T16:02:38Z (run 36447911272) | `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref,createdAt` |

- Six `build-v1` entries exist, one per key per scope, created by the two cold runs only; the eight warm runs saved nothing (run 36446346094, run 36447911272, `gh cache list --key ubuntu-24.04- --limit 100 --json key,ref,createdAt`).
- Together they hold 78753196 bytes, 78.8 MB, which is 0.8 % of 10 GB. The whole repository cache holds 753373323 bytes in 69 entries, 7.5 % of 10 GB (`gh api repos/szTheory/threadline/actions/cache/usage`).
- Against D-16's estimates: the root entries match (about 10.5 MB estimated, 10.0–10.6 MB measured); the example entry is larger, 18.8 MB against about 14.6 MB (`gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes`). D-16's steady state of about 1.1 GB assumed the smaller example entry. At the measured sizes, three entries per scope cost about 39.4 MB, so the space left under 10 GB holds more than 200 such scopes before eviction pressure [inference: `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes`, `gh api repos/szTheory/threadline/actions/cache/usage`].
- After merge, main's scope will hold one set of three entries that every PR reads; PR scopes are created only when a PR changes the lock or a hashed config and expire after seven days unused (D-16) [inference: scope rule, run 36447864779].

## 8. Expected effect vs measured

Every D-26 figure is an [inference] from research, set against the measured warm p50 and its delta against 218, the comparison D-26 was made for (run 36362405054, run 36455432448).

| Figure | Expected (D-26) | Measured, warm vs 218 | Verdict | Regenerate |
|---|---|---|---|---|
| Critical path | about −76 s [inference] | −96 s, 643 → 547 s (run 36362405054, run 36455432448) | confirmed; Browser E2E still critical in 6 of 8 | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py critical-path --set warm` |
| Test (current) | about −115 s [inference] | −116 s, 573 → 457 s (run 36359132030, run 36456537357) | confirmed | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| Capture | about −73 s [inference] | −86 s job, 499 → 413 s (run 36359132030, run 36450388764); miss step 51–57 s (run 36447911272) | saving present, job figure noise-level against the capture step's own spread | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| Test (min) | about −38 s [inference] | job +23 s, 318 → 341 s (run 36359132030, run 36449352051); compile step −33 s (run 36454272684) | step saving confirmed; job saving not demonstrated, masked by a suite slowdown | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| PgBouncer | about −38 s [inference] | −42 s, 114 → 72 s (run 36362405054, run 36457705448) | confirmed | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| Billed runner-min per run | about −5 [inference] | −4 billed, 53 → 49 (run 36359795977, run 36450388764); −5.1 unrounded (run 36455432448) | confirmed within rounding | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set warm` |
| Added cost of a miss per saving job | about 3–6 s [inference] | at most 3 s at p95, restore + rm + save (run 36446346094, run 36447911272) | at or below the estimate | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219` |

Browser E2E was not given its own D-26 figure; it measured −96 s against 218 (run 36362405054, run 36455432448) and carries the critical-path saving.

## 9. Summary of deltas

| Figure | BASE-01 | post-218 | post-219 warm | Delta vs 214 | Delta vs 218 | Status | Regenerate |
|---|---|---|---|---|---|---|---|
| Runner-min per ci.yml run, unrounded p50 | 46.3 (run 36086466934) | 44.4 (run 36362405054) | 39.3, n=8 (run 36455432448) | −7.0 | −5.1 | measured | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set warm` |
| Runner-min per ci.yml run, billed p50 | 55 (run 36086466934) | 53 (run 36359795977) | 49, n=8 (run 36450388764) | −6 | −4 | measured | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set warm` |
| Critical-path end offset p50 | 623 s (run 36256339043) | 643 s (run 36362405054) | 547 s (run 36455432448) | −76 s | −96 s | measured | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py critical-path --set warm` |
| Wall clock p50 | 629 s (run 34758417725) | 648 s (run 36362405054) | 552 s (run 36455432448) | −77 s | −96 s | measured | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py wall --set warm` |
| Run test suite (current) p50 | 546 s (run 34755536474) | 573 s (run 36359132030) | 457 s (run 36456537357) | −89 s | −116 s | measured | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| Run test suite (min) p50 | 395 s (run 35788765371) | 318 s (run 36359132030) | 341 s (run 36449352051) | −54 s | +23 s | measured; compile step −33 s, suite slowdown outside the cache | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| PgBouncer p50 | 109 s (run 36083676177) | 114 s (run 36362405054) | 72 s (run 36457705448) | −37 s | −42 s | measured | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| Browser E2E p50 | 623 s (run 36256339043) | 643 s (run 36362405054) | 547 s (run 36455432448) | −76 s | −96 s | measured, wide spread | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
| Capture p50 | 532 s (run 36258071425) | 499 s (run 36359132030) | 413 s (run 36450388764) | −119 s | −86 s | measured; noise-level against the capture step's spread, cache share about 51–57 s | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py steps --set warm` |
| Cold run, unrounded p50 | 46.3 (run 36086466934) | 44.4 (run 36362405054) | 42.1, n=2 (run 36447911272) | −4.2 | −2.3 | measured, n=2 | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set cold` |
| Added cost of a miss | none (run 36086466934) | none (run 36362405054) | at most 3 s per saving job (run 36446346094) | +3 s | +3 s | measured | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py cache-steps --set all219` |
| Cache storage, `build-v1` | none (run 36086466934) | none (run 36362405054) | 78.8 MB in six entries, 0.8 % of 10 GB (run 36447911272) | +78.8 MB | +78.8 MB | measured | `gh cache list --key ubuntu-24.04- --limit 100 --json key,sizeInBytes,ref` |
| SC1 runtime half | not applicable (run 36086466934) | not applicable (run 36362405054) | root and example hits logged with two 64-hex segments; no dependency compile on a hit; threadline and threadline_phoenix recompiled (run 36455432448) | proven | proven | measured | `gh run view 36455432448 --log --job 109040463875 --repo szTheory/threadline` |

**Push-to-main unit [inference].** No push to main was measured; the milestone has not merged. Once phase 219 merges, main's scope holds the entries and every PR that does not change the lock or a hashed config reads them, so a typical PR's first run should be warm, not cold. The first post-merge PR run is the measurement that confirms or corrects this [inference: scope rule, run 36447864779, run 36455432448].
