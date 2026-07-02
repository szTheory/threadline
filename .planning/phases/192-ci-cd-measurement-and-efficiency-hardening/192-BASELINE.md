---
phase: 192
artifact: ci-cd-baseline
audited: 2026-07-02
scope: v1.39-ci-efficiency-baseline
requirements: [CI-01]
status: complete
source_precedence:
  - runtime / gh-api run-history evidence
  - static ci.yml analysis
  - planning / residual history
---

# Phase 192 CI/CD Efficiency Baseline (CI-01)

This is a **read-only** measurement artifact. Phase 192 Wave 1 does not edit any
`.github/workflows/*` file, `mix.exs`, `CONTRIBUTING.md`, `README.md`, or any
source or test file. "Measure before optimize" is a hard ordering (D-05): this
baseline captures the cache-absent, `deps.get`-×N, browser-lane-dominated state
of `ci.yml` **before** Wave 2 touches any workflow, so Phase 193 (CLOSE-01) can
do a pure in-repo before/after diff against it. Editing the pipeline here would
be an observer effect on the thing being measured.

## Executive Summary

- **Full parallel fan-out, zero serialization.** All 10 `ci.yml` jobs run in
  parallel — `grep -c 'needs:' ci.yml` = **0**. Wall-clock per run is therefore
  the single longest job (the critical path), not the sum of jobs.
- **Zero caching today.** `grep -c 'actions/cache' ci.yml` = **0**;
  `erlef/setup-beam@v1` ships no built-in dependency cache. `mix deps.get` runs
  **cold on 8 of the 10 jobs** (`grep -cE 'mix deps.get' ci.yml` = 8). This is
  the primary CI-02 target and is pre-justified by this baseline.
- **Two heavy lanes own the critical path.** Across 15 GREEN `push`-on-`main`
  runs, `verify-test` owns the **p50** critical path (244 s) and
  `verify-example-browser` owns the **p95** tail (326 s). The browser lane is the
  most variable job (p50 174 s → p95 326 s: +152 s spread). The D-05 headline
  "browser lane ≈ 98% of the ~5m52s critical path" is corroborated by the
  spot-checked green run `27082048346` (browser lane ~344 s of a ~349 s run), and
  **refined** by the 15-run aggregate: the browser lane dominates the tail while
  `verify-test` dominates the median — both are the Wave-2 caching targets.
- **No concurrency control.** `grep -c 'concurrency:' ci.yml` = **0** — superseded
  PR runs are not cancelled today (CI-03 D-23 target).
- **Single pinned lane, one `:latest` image.** All jobs run
  `elixir 1.17.3 / OTP 27.0` (ci.yml:28-29); `edoburu/pgbouncer:latest` at
  **ci.yml:225** is the only floating image tag in the file (CI-03/CI-04 targets).
- **Flaky/rerun signal is clean in the sampled window.** 0 of 15 sampled GREEN
  runs had `run_attempt > 1` — recorded honestly as "0 reruns observed," not a
  measurement failure.
- **Two metrics are genuinely unavailable** (billed minutes, cache-hit rate) and
  are recorded as honest rows carrying the DNA Nyquist-debt metadata
  (owner / date / superseding-evidence pointer / reopen trigger), never as
  fabricated numbers.

## Evidence Contract

Runtime `gh api` run-history evidence decides the timing numbers; static parse of
`ci.yml` decides the structural findings; planning history frames the "why."
Where a metric cannot be sourced from the live API (billing) or does not exist
yet (cache telemetry), the row is recorded as honest-unavailable rather than
inferred. Sample: 15 GREEN runs, `status=success & event=push & branch=main`,
paged past the red-heavy recent window (successes cluster earlier than the
2026-06-26 failure cluster). Run ids sampled:
`27082029121, 26899776964, 26898408658, 26896632942, 26896081822, 26895537879,
26893642149, 26858178899, 26857249986, 26856836058, 26856195805, 26849709941,
26849209280, 26683633002, 26683325390`.

Reproduce with the throwaway aggregator (lives under `.planning/`, never in CI):

```
bash .planning/phases/192-ci-cd-measurement-and-efficiency-hardening/scripts/aggregate-ci-baseline.sh
```

## Ranked Per-Job Timing (D-03 columns)

Ordered by p95 wall-clock (critical-path prominence). Durations in seconds,
aggregated over the 15-run GREEN window. "Repeated setup cost" reflects the
current cold state (no cache). Job display names from the API are mapped to the
stable `ci.yml` job key (e.g. `Run test suite` → `verify-test`,
`Example app browser E2E (Playwright)` → `verify-example-browser`).

| job (key) | p50 (s) | p95 (s) | on critical path? | repeated setup cost (deps.get + setup-beam) | cache state | flaky/rerun (run_attempt>1) | evidence source |
|-----------|--------:|--------:|-------------------|---------------------------------------------|-------------|-----------------------------|-----------------|
| verify-example-browser | 174 | 326 | **yes — p95 tail** | cold `deps.get` + setup-beam + `npm ci` + `playwright install chromium` | none | 0/15 | gh api runs/{id}/jobs |
| verify-test | 244 | 257 | **yes — p50 median** | cold `deps.get` + setup-beam | none | 0/15 | gh api runs/{id}/jobs |
| verify-pgbouncer-topology | 106 | 121 | no | cold `deps.get` (in `run` block) + setup-beam | none | 0/15 | gh api runs/{id}/jobs |
| verify-docs | 76 | 83 | no | cold `deps.get` + setup-beam | none | 0/15 | gh api runs/{id}/jobs |
| verify-credo | 73 | 76 | no | cold `deps.get` + setup-beam | none | 0/15 | gh api runs/{id}/jobs |
| verify-compile-no-optional | 63 | 69 | no | cold `deps.get` + setup-beam | none | 0/15 | gh api runs/{id}/jobs |
| verify-hex-evaluator | 55 | 62 | no | setup-beam only (nested hex project; **no root `deps.get`**) | none | 0/15 | gh api runs/{id}/jobs |
| verify-format | 14 | 16 | no | cold `deps.get` + setup-beam | none | 0/15 | gh api runs/{id}/jobs |
| verify-hex-package | 14 | 16 | no | cold `deps.get` + setup-beam | none | 0/15 | gh api runs/{id}/jobs |
| verify-release-shape | 5 | 7 | no | **none** (no setup-beam, no `deps.get`) | none | 0/15 | gh api runs/{id}/jobs |

### Aggregate critical path (parallel fan-out ⇒ longest single job per run)

| metric | value | evidence source |
|--------|------:|-----------------|
| critical-path p50 | 244 s (~4m04s) | gh api — longest job per run, `verify-test`-dominated at median |
| critical-path p95 | 326 s (~5m26s) | gh api — `verify-example-browser`-dominated at tail |
| reruns observed (`run_attempt>1`) | 0 of 15 runs | gh api runs/{id} |

**Caching-target implication (pre-justifies CI-02):** the two heavy lanes
(`verify-test`, `verify-example-browser`) that own the critical path both pay the
cold `deps.get` cost; the browser lane additionally pays cold `npm ci` +
`playwright install`. These are exactly the D-06/D-07/D-08 cache targets. The 8
non-critical jobs also pay cold `deps.get` but do not gate wall-clock because of
the parallel fan-out — so caching them improves runner-minute cost, not latency.

## Static-Analysis Findings (structural, from `ci.yml` parse)

| finding | measured value | ci.yml anchor | routes to |
|---------|----------------|---------------|-----------|
| Job fan-out | 10 jobs, **0 `needs:`** (all parallel) | `grep -c 'needs:'` = 0 | baseline context |
| Cache blocks | **0 `actions/cache`** | `grep -c 'actions/cache'` = 0 | CI-02 (D-06/07/08) |
| Concurrency control | **0 `concurrency:` blocks** | `grep -c 'concurrency:'` = 0 | CI-03 (D-23) |
| Cold `mix deps.get` | **8 occurrences** across jobs | `grep -cE 'mix deps.get'` = 8 | CI-02 (D-06) |
| Version lane | single pinned `elixir 1.17.3 / OTP 27.0` | ci.yml:28-29 | CI-04 (D-15 matrix) |
| Floating image tag | `edoburu/pgbouncer:latest` (only `:latest` in file) | ci.yml:225 | CI-03 (D-22 pin) |
| Postgres service | `postgres:16` hardcoded on `verify-test` | ci.yml | CI-04 (D-15 matrix pg) |

## Honest-Unavailable Metrics (Nyquist-debt ledger — D-04)

These metrics cannot be sourced today. Per DNA deferred-validation shape
(`threadline-elixir-oss-dna.md:16`), each carries **owner / date /
superseding-evidence pointer / reopen trigger** — never a bare "unavailable"
and never a fabricated number.

| metric | status | owner | date | superseding evidence pointer | reopen trigger |
|--------|--------|-------|------|------------------------------|----------------|
| Billed minutes (CI runner cost) | Unavailable | maintainer (szTheory) | 2026-07-02 | GitHub Actions billing API `actions/workflows/ci.yml/timing` returns empty `{"billable":{}}` for this **public** repo; an org-level billing export would be the superseding source | Repo becomes private, or an org-level Actions billing export becomes available |
| Cache-hit rate | N/A (does not exist yet) | Phase 193 (CLOSE-01) | 2026-07-02 | No `actions/cache` configured today ⇒ no restore/save telemetry exists; `actions/cache` step logs + run telemetry become the source once Wave 2 caches land | **Phase 193 after Wave 2 caches land** (D-06/07/08 introduce the first cache blocks) |

## Baseline → Phase 193 Diff Anchor

Phase 193 (CLOSE-01) captures the after-data and diffs it against this artifact:

- **Critical path:** expect p50/p95 to drop as `deps/` (D-06), Playwright (D-07),
  and npm (D-08) caches warm the two heavy lanes; compare against p50 244 s /
  p95 326 s here.
- **Cache-hit rate:** the honest-unavailable row above flips to a measured value.
- **Cache blocks:** 0 → the D-06/07/08 blocks; `concurrency:` 0 → 1 (D-23);
  `:latest` count 1 → 0 (D-22).
- **Version lanes:** single pinned lane → `Run test suite (min)` + `(current)`
  matrix (D-15/D-19).

All comparisons are pure in-repo before/after; no live API is required to read
this artifact.
