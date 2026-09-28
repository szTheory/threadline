---
phase: 219-deps-only-build-cache
plan: 03
subsystem: ci
tags: [ci, github-actions, actions-cache, build-cache, measurement, remeasure]
status: complete

requires:
  - phase: 219-02
    provides: "exact-keyed deps-only root and example caches, THREADLINE_BUILD_CACHE / THREADLINE_EXAMPLE_BUILD_CACHE log fields, split compile-on-miss steps"
  - phase: 218
    provides: "collector, summarizer, citation checker and the post218 raw data (read-only)"
  - phase: 214
    provides: "BASE-01 raw data (read-only)"
provides:
  - "219 copies of collect-ci-runs.sh, summarize-ci.py, check-citations.py (exemption 21[4-9]) and fixtures"
  - "remeasure-219.py: sets base/post218/all219/warm/cold/mixed; label_pair, in_run_source, label_run_pairs, label_run; subcommands samples, cache, cache-steps, runner-minutes, wall, critical-path, jobs, steps"
  - "raw/ci manifest and 16 run JSON files (10 of the 219 code, 6 dropped 218-era)"
  - "219-REMEASURE.md: cited before/after for CACHE-01 against BASE-01 and 218"
affects: [220, 221, 222]

actuals:
  tokens: 196028   # chars/4 over the added lines of the plan diff; 26224 of it is authored text and code, the rest is collected run JSON
  tasks: 4
  commits: 5       # measured 69961a7e..HEAD before the docs commit; includes the orchestrator's mint fix 1ee0e352 and landing note 82ad495e
plan_head_before: 69961a7e06ed344d640b4d25a56861c785ab1c34
plan_head_after: 92389a7c

tech-stack:
  added: []
  patterns:
    - "Hit/miss labels from committed step JSON by list position, with in-run relabelling from sibling save timestamps"
    - "Step-level attribution (steps subcommand) where job-level deltas are masked by unrelated step variance"

key-files:
  created:
    - .planning/phases/219-deps-only-build-cache/tools/collect-ci-runs.sh
    - .planning/phases/219-deps-only-build-cache/tools/summarize-ci.py
    - .planning/phases/219-deps-only-build-cache/tools/check-citations.py
    - .planning/phases/219-deps-only-build-cache/tools/fixtures/cited.md
    - .planning/phases/219-deps-only-build-cache/tools/fixtures/uncited.md
    - .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py
    - .planning/phases/219-deps-only-build-cache/raw/ci/manifest.json
    - .planning/phases/219-deps-only-build-cache/raw/ci/runs/
  modified:
    - .planning/phases/219-deps-only-build-cache/219-REMEASURE.md

key-decisions:
  - "Landing option (a): the 219 commits went onto land/v1.43-217-218 / PR #60, giving a PR scope and a dispatch scope, so two cold samples were reachable without deleting caches"
  - "Test (min)'s job-level delta against 218 (+23 s) is recorded as not demonstrated, not dropped: its compile step fell 40 -> 7 s but its ExUnit suite time grew 212.4 -> 294.1 s, outside the cache"
  - "Capture's -86 s against 218 is recorded as noise-level against the Regenerate Tier A capture step's own bimodal spread; the cache's share is the 51-57 s miss step"
  - "A miss's added cost is restore + rm + save (at most 3 s per saving job); the compile-on-miss step moves work that pre-219 jobs did elsewhere"

requirements-completed: [CACHE-01]

coverage:
  - id: D1
    description: "Copied tools reproduce BASE-01 and the 218 figures from 219's directory"
    requirement: "CACHE-01"
    verification:
      - kind: other
        ref: "python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py runner-minutes --set post218; ... --set base"
        status: pass
      - kind: unit
        ref: "python3 .planning/phases/219-deps-only-build-cache/tools/check-citations.py --self-test"
        status: pass
    human_judgment: false
  - id: D2
    description: "Labeller reproduces the orchestrator's log-read labels from committed JSON: 2 cold, 8 warm"
    requirement: "CACHE-01"
    verification:
      - kind: unit
        ref: "python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py --self-test"
        status: pass
      - kind: other
        ref: "python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py samples"
        status: pass
    human_judgment: false
  - id: D3
    description: "219-REMEASURE.md fully cited (30 distinct run IDs), with warm root/example hit quotes, a cold miss quote, and [inference] labels on every D-26 figure"
    requirement: "CACHE-01"
    verification:
      - kind: other
        ref: "python3 .planning/phases/219-deps-only-build-cache/tools/check-citations.py .planning/phases/219-deps-only-build-cache/219-REMEASURE.md"
        status: pass
      - kind: other
        ref: "bin/verify-repo-hygiene"
        status: pass
    human_judgment: false

duration: about 2h40m wall (15:00Z to 17:40Z), most of it the landing checkpoint and ten CI runs
completed: 2026-09-28
---

# Phase 219 Plan 03: Measure the deps-only build cache Summary

**On a warm cache, a ci.yml run costs 39.3 unrounded / 49 billed runner-min, down from 44.4 / 53 after phase 218 and 46.3 / 55 at BASE-01. The critical path is 547 s, down from 643 s (218) and 623 s (BASE-01). The runtime half of SC1 is proven from logs: both caches hit, both key hashes are 64 hex characters, no dependencies compiled, and threadline and threadline_phoenix recompiled.**

## Performance

- **Duration:** about 2h40m wall. Most of it was the maintainer landing checkpoint and ten sequential CI runs.
- **Tasks:** 4 of 4. Task 3 was the maintainer checkpoint, resolved by the orchestrator under the maintainer's grant.
- **Files:** 27 changed across the plan (`git diff --stat 69961a7e..HEAD`).

## Accomplishments

- **Task 1 (6cb595a6).** Copied the tools and wrote `remeasure-219.py`. Its `base` and `post218` sets reproduce BASE-01 and 218-REMEASURE exactly (see "Reproduced baselines").
- **Task 2 (3e095a34).** Added the hit/miss/in-run labeller. `--self-test` passes cases (a) to (h). Also added the re-measure skeleton.
- **Task 4 (92389a7c).**
  - Collected 16 runs with the copied collector.
  - Dropped six 218-era runs by ancestry to 7dbad5ff. `git merge-base --is-ancestor` agrees with the script's `all219` filter.
  - Labelled 2 cold and 8 warm runs. The labels match the orchestrator's table built from the logs, pair for pair.
  - Wrote the full cited `219-REMEASURE.md`, sections 0 through 9.

## Measured headline (warm p50 against 218 / BASE-01)

| Figure | Change vs 218 | Change vs BASE-01 |
|---|---|---|
| Runner-min per run, unrounded | 44.4 → 39.3 (−5.1) | 46.3 → 39.3 (−7.0) |
| Runner-min per run, billed | 53 → 49 (−4) | 55 → 49 (−6) |
| Critical path | 643 → 547 s (−96) | 623 → 547 s (−76) |
| Test (current) | 573 → 457 s (−116) | 546 → 457 s (−89) |
| PgBouncer | 114 → 72 s (−42) | 109 → 72 s (−37) |
| Browser E2E | 643 → 547 s (−96) | 623 → 547 s (−76) |
| Capture | 499 → 413 s (−86), noise-level | 532 → 413 s (−119) |
| Test (min) | 318 → 341 s (+23); compile step −33 s, suite slowdown outside the cache | 395 → 341 s (−54) |

- **D-26 expectations:** the critical path, Test (current), PgBouncer and billed-minutes figures were confirmed. Capture's saving is present but noise-level. Test (min)'s job-level saving is not demonstrated.
- **Cost of a miss:** at most 3 s per saving job.
- **Storage:** the `build-v1` entries total 78.8 MB, 0.8 % of the 10 GB budget. The example entry is 18.8 MB, against D-16's estimate of 14.6 MB.

## Tool copies: complete diffs against the 218 originals

```
### collect-ci-runs.sh
11c11
< #   bash .planning/phases/218-ci-economy-remove-waste/tools/collect-ci-runs.sh \
> #   bash .planning/phases/219-deps-only-build-cache/tools/collect-ci-runs.sh \
### summarize-ci.py
44c44
< SELF = "python3 .planning/phases/218-ci-economy-remove-waste/tools/summarize-ci.py"
> SELF = "python3 .planning/phases/219-deps-only-build-cache/tools/summarize-ci.py"
### check-citations.py
5,6c5,6  usage lines: 218 path -> 219 path
10c10    docstring range (214-218) -> (214-219)
31c31
<     re.compile(r"\b21[4-8](?:-0\d)?\b"),             # phase / plan numbers (214-218)
>     re.compile(r"\b21[4-9](?:-0\d)?\b"),             # phase / plan numbers (214-219)
### fixtures/cited.md, fixtures/uncited.md
identical
```

## Reproduced baselines (Task 1 tracer)

- `remeasure-219.py runner-minutes --set post218`: unrounded p50 44.4 min (run 36362405054), billed p50 53 min (run 36359795977). This equals 218-REMEASURE §2 `set post`.
- `remeasure-219.py runner-minutes --set base`: unrounded p50 46.3 min, billed p50 55 min (run 36086466934). Wall p50 is 629 s (run 34758417725). These equal BASE-01.
- `jobs --set post218` reproduces 218-REMEASURE §4a: current test lane 573 s, min lane 318 s, capture 499 s, pgbouncer 114 s, browser 643 s.

## Gate results

- **Task 2 phase gate:** green before the checkpoint. After the orchestrator's mint fix, `mix ci.all` was green at 1ee0e352: 2502 tests, 0 failures, and the browser lane passed 317 with 0 failures (per the checkpoint resolution).
- **Task 4:**
  - The citation checker exits 0 on `219-REMEASURE.md`, and `--self-test` passes both fixtures.
  - `bin/verify-repo-hygiene` is clean over 4062 tracked files, with the new files staged.
  - The username `git grep` prints nothing.
  - 214 and 218 are untouched.
  - No `Pending:` line remains.
  - 30 distinct run IDs are cited.
  - Both hit lines and `[inference]` are present.
  - HEAD lists only phase-219 paths.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing functionality] Added a `steps` subcommand to remeasure-219.py**
- **Found during:** Task 4.
- **Issue:** the job-level deltas for Test (min) and Capture were masked by step variance that has nothing to do with the cache. The two causes were the min lane's suite time and the bimodal Regenerate Tier A capture step. Showing where the saving lands needs per-step p50s, and every one of them must be cited by a command. The plan's subcommand list had no step-level view outside the cache steps.
- **Fix:** added `STEPS` and `sub_steps`, modelled on remeasure-218's `steps`. The labeller and all existing subcommands are unchanged, and `--self-test` still prints `self-test: ok`.
- **Files modified:** `.planning/phases/219-deps-only-build-cache/tools/remeasure-219.py`. This file was not in Task 4's file list, but it is under the phase directory, so the "HEAD lists only phase-219 paths" criterion holds.
- **Commit:** 92389a7c.

**2. [Rule 1 - Honest labelling] Two D-26 jobs recorded as not demonstrated or noise-level, not dropped**
- **Test (min):** +23 s against 218.
  - The compile step fell by 33 s (40 → 7 s).
  - `Run tests` rose by 53 s. ExUnit's own timer shows the rise is suite time: 212.4 s for 2466 tests before, 294.1 s for 2502 tests after (run 36363356238 against run 36455432448).
  - The warm log has no dependency compile in that step.
  - The cause is outside this phase and was not investigated.
- **Capture:** job p50 −86 s.
  - The Regenerate step itself spans 219 to 479 s across the three sets. That is why the cold job p50 of 325 s sits below the warm p50.
  - The cache's share is the 51–57 s miss step.

The orchestrator made two commits between the checkpoint and this continuation: 1ee0e352 (mint security fix) and 82ad495e (landing note in STATE). Both count toward the measured commits. Neither is an executor deviation.

## Known Stubs

None.

## Threat Flags

None. The run JSON, log quotes and prose contain no home paths and no username. The only GitHub calls were read-only: `gh run list/view`, `gh cache list` and `gh api` GETs. No dispatches, pushes, re-runs or cache deletes were made by the executor.

## Next Phase Readiness

- Phase 222 can read the per-run delta (−5.1 unrounded / −4 billed against 218) and the critical-path delta (−96 s) from `219-REMEASURE.md` §9.
- The first post-merge PR run should be warm from main's scope. The re-measure lists that run as the pending confirmation, marked `[inference]`.
- Worth a later look (not in this scope): the min lane's suite time grew about 82 s between 2466 and 2502 tests.

## Self-Check: PASSED

- Commits found: 6cb595a6, 3e095a34, 92389a7c (plus orchestrator 1ee0e352, 82ad495e).
- Files found: tools/remeasure-219.py, tools/check-citations.py, raw/ci/manifest.json, 219-REMEASURE.md.
