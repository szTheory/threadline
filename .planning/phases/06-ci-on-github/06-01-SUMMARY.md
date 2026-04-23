---
phase: 06-ci-on-github
plan: "01"
subsystem: infra
tags: [github-actions, mix, ci, credo]

requires:
  - phase: 05-repository-remote
    provides: canonical origin, ci.yml on main
provides:
  - CI-01 grep-verified job keys and main-only triggers on ci.yml
  - Local `mix ci.all` parity (compile `--warnings-as-errors` before tests) — supports CI-02 reproducibility on a workstation; **not** GitHub CI-02 (live green run on `origin/main` closed in Phase 8).
affects:
  - phase-07-hex

tech-stack:
  added: []
  patterns:
    - "Local mix ci.all mirrors verify-test job order (compile strict before mix test)."

key-files:
  created:
    - .planning/phases/06-ci-on-github/06-01-SUMMARY.md
  modified:
    - mix.exs

key-decisions:
  - "No ci.yml edits required — Task 1 contract greps passed on existing workflow."

patterns-established: []

requirements-completed:
  - CI-01

duration: 5 min
completed: 2026-04-23
---

# Phase 6 Plan 01: CI contract and local parity — Summary

**GitHub workflow already satisfied CI-01; `mix ci.all` now runs `compile --warnings-as-errors` before tests so local runs match the `verify-test` job.**

## Performance

- **Duration:** ~5 min
- **Tasks:** 3
- **Files modified:** `mix.exs` only (`ci.yml` unchanged)

## Accomplishments

- Task 1: All CI-01 acceptance greps passed on `.github/workflows/ci.yml` (`verify-format`, `verify-credo`, `verify-test`, `branches: [main]` for push and pull_request).
- Task 2: Updated `"ci.all"` alias to `["verify.format", "verify.credo", "compile --warnings-as-errors", "verify.test"]`; exact-line grep passes.
- Task 3: No workflow glue fix — `git diff` showed no `ci.yml` change requirement.

## CI-01 grep evidence

- `^  verify-format:`, `^  verify-credo:`, `^  verify-test:` — all present under `jobs:`.
- `push:` / `pull_request:` each followed by `branches: [main]` in file context — PASS.

## Verification

- `MIX_ENV=test mix ci.all` — exit 0 (78 tests, 0 failures) after `mix.exs` change.

## Task Commits

1. **Task 1–3 implementation** — `mix.exs` parity + verification (see git history for `feat(06-01)` / `docs(06-01)` commits).

## Files Created/Modified

- `mix.exs` — `ci.all` alias aligned with GitHub `verify-test` job.
- `.planning/phases/06-ci-on-github/06-01-SUMMARY.md` — this file.

## Deviations from Plan

None.

## Self-Check: PASSED

Greps and `MIX_ENV=test mix ci.all` succeeded locally.
