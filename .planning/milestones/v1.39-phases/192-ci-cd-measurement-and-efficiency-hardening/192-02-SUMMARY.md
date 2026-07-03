---
phase: 192-ci-cd-measurement-and-efficiency-hardening
plan: 02
subsystem: ci-cd
tags: [ci, github-actions, caching, matrix, concurrency, supply-chain]
requires:
  - "192-01 baseline (critical path, cache state, browser-lane timing)"
provides:
  - "deps/ source-only cache on 8 ci.yml jobs + flake-detection verify-flake"
  - "Playwright + npm caches on verify-example-browser (e2e-lockfile scoped)"
  - "verify-test min/current matrix posting two new checks: Run test suite (min) / (current)"
  - "PR-scoped concurrency on ci.yml"
  - "pgbouncer image pinned to a real tag (no :latest in ci.yml)"
affects:
  - "Branch protection required-checks (rename handled in Plan 04 — human-gated)"
  - "phase06_nyquist_ci_contract_test.exs (regression lock extended in Plan 04)"
tech-stack:
  added:
    - "actions/cache@v4 (deps/, Playwright browsers, npm download dir)"
  patterns:
    - "Base-axis matrix (lane) + include for gate-preserving check naming (RESEARCH M1 construction A)"
    - "Source-only dependency cache keyed on mix.lock; never _build"
    - "Tag-pin service images (symmetric with postgres:16 policy)"
key-files:
  created: []
  modified:
    - ".github/workflows/ci.yml"
    - ".github/workflows/flake-detection.yml"
decisions:
  - "D-06/D-10: cache deps/ (source only), never _build — the gate keeps its teeth"
  - "D-07/D-08/D-09: Playwright + npm caches keyed to e2e/package-lock.json, never folded into the root mix.lock key"
  - "D-15/D-18/D-19: base-axis lane matrix; min lane runs compile-strict + mix test only"
  - "D-22: pin edoburu/pgbouncer:v1.25.2-p0 (behavior-neutral vs today's latest)"
  - "D-23: PR-scoped concurrency cancels only superseded pull_request runs"
metrics:
  duration: "~15 min"
  completed: "2026-07-02"
  tasks: 2
  files_changed: 2
status: complete
---

# Phase 192 Plan 02: CI Efficiency, Compatibility Matrix & Hygiene Summary

`deps/` source-only caching on the 8 root-deps ci.yml jobs plus flake-detection, Playwright/npm caches scoped to the e2e subtree lockfile, a gate-preserving min/current `verify-test` matrix, PR-scoped concurrency, and a pinned pgbouncer image — all speed/compat/hygiene changes with zero gate weakening (CI-02/CI-03/CI-04).

## What Was Built

### Task 1 — deps/ + Playwright/npm caches (`2610c804`)
- Added `actions/cache@v4` for `path: deps` (key `${{ runner.os }}-mix-deps-${{ hashFiles('mix.lock') }}`, `restore-keys` prefix) after `setup-beam` and before `mix deps.get` on the **8 jobs that run a root deps.get**: verify-format, verify-credo, verify-compile-no-optional, verify-test, verify-example-browser, verify-pgbouncer-topology, verify-docs, verify-hex-package.
- Added the identical `deps` cache to `flake-detection.yml`'s `verify-flake` job.
- `verify-example-browser` only: added `cache: npm` + `cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json` to `setup-node@v5` (no root lockfile exists — omitting the path hard-fails the job), plus a second `actions/cache@v4` for `~/.cache/ms-playwright` keyed on the same e2e lockfile.
- No `_build` cache anywhere (D-10). No cache on verify-hex-evaluator (nested hex project) or verify-release-shape (no setup-beam). `mix deps.get`/`npm ci`/`playwright install` all still run (D-12).
- Result: exactly **9** `actions/cache@v4` uses in ci.yml (8 deps + 1 Playwright).

### Task 2 — matrix, concurrency, pin (`cce7f409`)
- `verify-test` now carries a base-axis `matrix.lane: [min, current]` + `include:` entries keyed by `lane` (elixir/otp/pg/runner). Static `name: Run test suite` → GitHub posts exactly **`Run test suite (min)`** and **`Run test suite (current)`** (include-only keys do not append to the suffix — RESEARCH M1 construction A).
  - min → elixir 1.15 / otp 26 / postgres:14 / ubuntu-22.04
  - current → elixir 1.17.3 / otp 27 / postgres:16 / ubuntu-24.04
- `runs-on: ${{ matrix.runner }}`, `services.postgres.image: postgres:${{ matrix.pg }}`, setup-beam `elixir-version`/`otp-version` are all matrix-driven.
- The four heavier steps (verify.threadline, createdb, verify.example, verify.doc_contract) gated `if: matrix.lane == 'current'`; min lane runs `mix deps.get` → `mix compile --warnings-as-errors` → `mix verify.test` only (D-18).
- `verify-compile-no-optional` left untouched as its own standalone job (D-20).
- Added top-level PR-scoped `concurrency` block: `group: ${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` (D-23).
- Pinned pgbouncer service image `edoburu/pgbouncer:latest` → `edoburu/pgbouncer:v1.25.2-p0`; scram/transaction env untouched; no `:latest` remains in ci.yml (D-22).

## Verification

- Task 1 grep gate: `CACHE_OK` (9 cache uses, e2e cache-dependency-path present, Playwright path present, flake-detection deps cache present).
- Task 2 grep gate: matrix `lane: [min, current]`, `postgres:${{ matrix.pg }}`, `runs-on: ${{ matrix.runner }}`, four `if: matrix.lane == 'current'` gates, pgbouncer pin, PR concurrency, verify-compile-no-optional standalone — all confirmed (initial `${{ }}` grep misses were regex `{{`-metachar artifacts; re-confirmed with `grep -F` and direct line inspection at lines 122/128/24).
- `python3 yaml.safe_load` on both workflows: **YAML OK**.
- `actionlint` on both workflows: **clean**.
- No `_build` path in any cache step; `mix deps.get`/`npm ci`/`playwright install` steps all still present.

## Deviations from Plan

None — plan executed exactly as written. No auto-fixes required; no authentication gates encountered.

## Known Stubs

None.

## Follow-ups (out of this plan's scope — Plan 04)

- Branch-protection reconfiguration to require `Run test suite (min)` / `Run test suite (current)` (drops `Run test suite (verify-test)`) — human-gated (D-19).
- Throwaway matrix run confirming `elixir 1.15 / otp 26` resolves on `ubuntu-22.04` via setup-beam (D-17) — live-run check, not a static assertion.
- Contract-test extensions (`phase06_nyquist_ci_contract_test.exs`) that lock these constructs (D-26) land in Wave 3.

## Self-Check: PASSED

- FOUND: .github/workflows/ci.yml (modified, 9 cache uses, matrix, concurrency, pin)
- FOUND: .github/workflows/flake-detection.yml (modified, deps cache)
- FOUND commit 2610c804 (Task 1)
- FOUND commit cce7f409 (Task 2)
