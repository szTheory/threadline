---
phase: 192-ci-cd-measurement-and-efficiency-hardening
plan: 01
subsystem: ci-cd-baseline
tags: [ci-01, baseline, gh-api, measurement-first, observer-effect, nyquist-debt]
requires:
  - "gh CLI authed as szTheory (keyring) + jq — live read-only Actions API access"
  - "189-QUALITY-AUDIT.md frontmatter+ranked-table shape (template to mirror)"
provides:
  - "192-BASELINE.md — durable read-only CI-01 baseline in the Phase-189 audit shape"
  - "Per-job p50/p95 timing from 15 GREEN push-on-main ci.yml runs + aggregate critical path"
  - "Static findings: 10 parallel jobs / 0 needs / 0 actions/cache / 0 concurrency / deps.get cold x8 / pgbouncer:latest@225"
  - "Honest-unavailable ledger (billed minutes, cache-hit rate) with owner/date/superseding-pointer/reopen-trigger"
  - "Throwaway aggregate-ci-baseline.sh under .planning/ (never wired into CI)"
affects:
  - "Phase 193 (CLOSE-01) — pure in-repo before/after diff anchor"
  - "Wave 2 (192-02..04) — pre-justifies CI-02 cache targets on the two heavy critical-path lanes"
tech-stack:
  added: []
  patterns:
    - "Measure-before-optimize: read-only baseline lands before any workflow edit (D-05 observer effect)"
    - "Page past red-heavy recent window to collect ~15 GREEN runs of one event type (not last-15-total)"
    - "API display-name -> stable ci.yml job-key mapping when tabulating jobs endpoint"
    - "Honest-unavailable rows carry DNA Nyquist-debt shape, never a bare 'unavailable' or a fabricated number"
key-files:
  created:
    - .planning/phases/192-ci-cd-measurement-and-efficiency-hardening/192-BASELINE.md
    - .planning/phases/192-ci-cd-measurement-and-efficiency-hardening/scripts/aggregate-ci-baseline.sh
  modified: []
decisions:
  - "Resolved D-02 open question: sampled event=push on main (most stable; honors path-filter+main invariant)"
  - "Refined the D-05 headline honestly: across 15 runs verify-test owns the p50 critical path (244s) while verify-example-browser owns the p95 tail (326s); the 'browser lane ~98%' figure is corroborated by spot-check run 27082048346, not contradicted"
  - "verify-hex-evaluator recorded as setup-beam-only (nested hex deps, no root deps.get); verify-release-shape as no-setup-beam/no-deps.get — matches RESEARCH 8-of-10 nuance"
metrics:
  duration: ~18m
  completed: 2026-07-02
status: complete
---

# Phase 192 Plan 01: CI-01 Read-Only Baseline Summary

Produced `192-BASELINE.md`, a durable read-only CI efficiency baseline in the
Phase-189 audit shape, capturing the cache-absent, `deps.get`-×8,
browser-lane-dominated state of `ci.yml` BEFORE any Wave-2 workflow edit — so
Phase 193 has a clean in-repo before/after anchor.

## What Was Built

- **`scripts/aggregate-ci-baseline.sh`** (Task 1) — throwaway `gh`/`jq`
  aggregator under `.planning/` (never referenced by any workflow). Pages
  `workflows/ci.yml/runs?status=success&event=push&branch=main` until it has
  ~15 GREEN runs (past the red-heavy 2026-06-26 window), reads per-job
  `started_at`/`completed_at` from `runs/{id}/jobs`, maps API display names to
  stable job keys, and prints per-job p50/p95 + the aggregate critical path.
- **`192-BASELINE.md`** (Task 2) — Phase-189-shaped frontmatter
  (`phase/artifact/audited/scope/requirements: [CI-01]/status: complete/source_precedence`),
  an executive summary, a ranked table with all 8 D-03 columns, a
  static-analysis findings table, a Nyquist-debt honest-unavailable ledger, and
  a Phase-193 diff anchor section.

## Measured Facts (15 GREEN push-on-main runs)

- Critical path: **p50 244 s (~4m04s)** (`verify-test`-dominated median),
  **p95 326 s (~5m26s)** (`verify-example-browser`-dominated tail).
- `verify-example-browser` is the most variable job (p50 174 s → p95 326 s).
- Static: 10 jobs, **0** `needs:`, **0** `actions/cache`, **0** `concurrency:`,
  **8** cold `mix deps.get`, single pinned `elixir 1.17.3 / OTP 27.0`,
  `edoburu/pgbouncer:latest` at ci.yml:225 (only `:latest` in file).
- Flaky/rerun: **0 of 15** runs had `run_attempt > 1` (recorded honestly).

## Honest-Unavailable Metrics (D-04)

- **Billed minutes** — unavailable: public-repo `actions/.../ci.yml/timing`
  returns empty `{"billable":{}}`. Owner: maintainer; reopen trigger: repo goes
  private or org billing export appears.
- **Cache-hit rate** — N/A: no `actions/cache` today. Owner: Phase 193; reopen
  trigger: after Wave 2 caches land.

## Deviations from Plan

### Auto-fixed / Refinements (no architectural change)

**1. [Rule 1 — Honesty correction] Refined the D-05 "browser lane ≈ 98% of
critical path" headline against the 15-run aggregate.**
- **Found during:** Task 2 (transcribing Task 1 output).
- **Issue:** The D-05 spot-check (run `27082048346`, browser lane ~344 s of a
  ~349 s run) is a single-run figure. Across the 15-run window the critical path
  alternates: `verify-test` owns the p50 (244 s), `verify-example-browser` owns
  the p95 tail (326 s). Parroting "98%" as the aggregate would have been a
  fabricated-precision claim.
- **Fix:** Recorded both — the spot-check as corroboration and the aggregate as
  the refinement — so the baseline is honest and Phase 193 diffs against real
  p50/p95 numbers. Both heavy lanes remain the Wave-2 cache targets, so the
  CI-02 pre-justification is unchanged.
- **Files:** `192-BASELINE.md`.
- **Commit:** d3762c8c.

No architectural (Rule 4) deviations. No workflow, source, or test files were
edited (D-05 read-only contract honored).

## Prohibitions Honored

- Zero `.github/workflows/*.yml` edits; zero `ci.yml`/`release.yml`/
  `flake-detection.yml`/`CONTRIBUTING.md`/`README.md`/`mix.exs`/test edits.
- No fabricated numbers — unavailable metrics carry reopen triggers.
- Aggregation script lives under `.planning/` only, never wired into CI.
- `git diff` confined to `.planning/phases/192-.../` (plus incidental GSD
  STATE.md/config.json state-churn handled in the state-update step).

## Self-Check: PASSED

- `192-BASELINE.md` exists; `scripts/aggregate-ci-baseline.sh` exists.
- Task 1 verify: `AGG_OK` (script prints `verify-test`).
- Task 2 verify: `BASELINE_OK` (`requirements: [CI-01]`, `on critical path`,
  `reopen trigger` all present).
- Commits `1329bbf7` (script) and `d3762c8c` (baseline) present in `git log`.
