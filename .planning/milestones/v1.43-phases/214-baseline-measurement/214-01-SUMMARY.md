---
phase: 214-baseline-measurement
plan: 01
subsystem: ci-measurement
tags: [ci, baseline, runner-minutes, github-actions, measurement]
status: complete
requires: []
provides:
  - "214-BASELINE.md sections 0-5: per-job p50/p95 (PR, push, dispatch), wall clock, critical path, runner-minutes per PR / push-to-main / release cycle, Flake Detection and Browser-full cost"
  - "Read-only collector tools/collect-ci-runs.sh (--workflow/--event, --head-sha, --release-tag, --status any --since)"
  - "Deterministic summarizer tools/summarize-ci.py (jobs, wall, critical-path, runner-minutes, workflow-cost)"
  - "Citation checker tools/check-citations.py with a negative self-test"
  - "Committed raw data under raw/ci (manifest.json, runs/*.json, release-v0.11.0.json, release-v0.10.2.json)"
affects: [214-02, 214-03, 218, 222]
tech-stack:
  added: []
  patterns:
    - "Nearest-rank percentiles on integer seconds, samples sorted by (seconds, run id)"
    - "Every figure line cites run <id> or a backticked regenerating command, enforced by check-citations.py"
key-files:
  created:
    - .planning/phases/214-baseline-measurement/214-BASELINE.md
    - .planning/phases/214-baseline-measurement/tools/collect-ci-runs.sh
    - .planning/phases/214-baseline-measurement/tools/summarize-ci.py
    - .planning/phases/214-baseline-measurement/tools/check-citations.py
    - .planning/phases/214-baseline-measurement/tools/fixtures/cited.md
    - .planning/phases/214-baseline-measurement/tools/fixtures/uncited.md
    - .planning/phases/214-baseline-measurement/raw/ci/manifest.json
    - .planning/phases/214-baseline-measurement/raw/ci/release-v0.11.0.json
    - .planning/phases/214-baseline-measurement/raw/ci/release-v0.10.2.json
  modified: []
decisions:
  - "Legacy pre-matrix job name 'Run test suite' (two June push runs) is excluded from per-job rows; those runs still count for every other job and for wall clock"
  - "Push-to-main unit = push + workflow_run runs on the pushed SHA; scheduled nightlies on the same SHA are excluded"
  - "Release cycle = non-scheduled runs on release-please PR commits + release merge commit + distribution-sync PR commits; the sync PR's own merge push is an ordinary push unit"
  - "BASE-01 not marked complete: 214-02 and 214-03 still own --slowest, :live_dialyzer and the inert-PR share"
metrics:
  duration: "~14 min"
  completed: 2026-09-26
estimate:
  tokens: 95000
  tasks: 3
actuals:
  tokens: 21000   # chars/4 over the authored doc, tools and fixtures (~84k chars); raw/ci JSON (~2.8 MB, generated) excluded
  tasks: 3
  commits: 3
plan_head_before: 8c99f027ad65e27a803959465e426a7109325241
---

# Phase 214 Plan 01: CI baseline measurement spine Summary

A read-only gh collector, a deterministic nearest-rank summarizer and a citation checker produce 214-BASELINE.md. It records per-job p50/p95 for all 16 ci.yml check names (n >= 10 on both PR and push), wall clock, the critical path (browser E2E finishes last in 16 of 20 runs on each event), runner-minutes per PR (46.3 unrounded / 55 billed at p50), per push-to-main (66.2 / 80) and per release cycle (v0.11.0 239.4 / 297, v0.10.2 216.7 / 261), plus the Flake Detection and Browser-full cost. Every line reproduces from committed raw/ci data.

## What was built

- **Task 1 (tracer, bc2d28e0):** collect-ci-runs.sh, summarize-ci.py `jobs`, check-citations.py plus fixtures. 214-BASELINE.md section 0 (method, origin/main 5e78b2f0, sample rule, duration definition, percentile contract, citation convention) and the two "Run test suite (current)" rows. The tracer gate (auto mode) re-ran `<verify>` green before expanding.
- **Task 2 (0ec0a808):** `wall` and `critical-path` subcommands. Section 1 has every job for pull_request, push and a separate workflow_dispatch group. Section 2 has wall clock (PR p50 629 s, push p50 640 s) and the critical-path table.
- **Task 3 (579f00b8):** `runner-minutes --unit pr|push|release` and `workflow-cost --regimes`. The collector gained `--release-tag`, `--status any --since` and uncapped `--head-sha`. Sections 3-5 cover per-unit minutes, per-release run breakdown, the Flake Detection regimes (fast failure 08-27..09-12, cancelled 09-13..09-24, success 09-25..09-26) with a 2,940-4,110 runner-min/month [inference] projection, and Browser-full push/nightly cost.

## Verification

- `check-citations.py --self-test` exits 0. uncited.md exits 1 with 2 "uncited figure" lines, and the doc exits 0.
- `summarize-ci.py jobs --min 10` exits 0 for both ci.yml events. `--min 18` on an n=18 job exits 0 and `--min 19` exits 2, so the boundary is exact.
- Two runs of the section generators produce byte-identical output. All 81 section 1-2 table rows and all of sections 3-5 are found verbatim in the doc.
- The write-verb grep on the collector and the path-leak grep on the doc, tools and raw data both find nothing.
- `git status --porcelain .github mix.exs test` is empty.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `--head-sha` capped at 20 runs dropped push-event runs**
- **Found during:** Task 3
- **Issue:** The default `--target 20` kept the newest 20 runs for a SHA. On SHAs that sat as main HEAD for weeks, the nightly scheduled runs are newest, so the cap dropped the oldest runs, which are the push-event ones.
- **Fix:** `--head-sha` now defaults to no cap (`--target 0`). The two affected SHAs were re-collected (86852f98 went from 20 to 31 runs).
- **Files modified:** tools/collect-ci-runs.sh
- **Commit:** 579f00b8

**2. [Rule 1 - Bug] Legacy matrix job name reported as a current job**
- **Found during:** Task 1/2
- **Issue:** Two June push runs predate the lane matrix and name the test job "Run test suite". That produced an n=2 row and a false `--min 10` failure for a job the current ci.yml cannot produce.
- **Fix:** summarize-ci.py drops an un-suffixed matrix name when suffixed variants exist. The rule is documented in the tool's contract and in doc sections 0 and 1.
- **Commit:** bc2d28e0 / 0ec0a808

**3. [Rule 2 - Missing functionality] Collector flags beyond the plan's list**
- Task 3 needs `--status any`, `--since` and a release-cycle derivation, so the collector gained `--status`, `--since` and `--release-tag`. All are read-only (`gh release list`, `gh pr list`, `gh pr view`, `gh run list`, and default-GET `gh api`).

### Notes

- The Task 1 acceptance jq (`min run_ids length >= 10`) held at Task 1 time. After Task 3 the manifest also holds `sha:<sha>` and dispatch entries with fewer runs by design. The ci.yml pull_request and push entries still have 20 each.
- Only 6 successful workflow_dispatch runs exist, so dispatch rows have n=4-6. They are reported separately, as the plan requires, and are not gated at n >= 10.
- The flake-detection success regime is n=2, so the monthly projection is a range labelled [inference], not a percentile.

## Known Stubs

None.

## Threat Flags

None. Collection is read-only. No new endpoints, auth paths or schema changes.

## Self-Check: PASSED

- FOUND: 214-BASELINE.md, tools/collect-ci-runs.sh, tools/summarize-ci.py, tools/check-citations.py, tools/fixtures/cited.md, tools/fixtures/uncited.md, raw/ci/manifest.json, raw/ci/release-v0.11.0.json, raw/ci/release-v0.10.2.json
- FOUND commits: bc2d28e0, 0ec0a808, 579f00b8
