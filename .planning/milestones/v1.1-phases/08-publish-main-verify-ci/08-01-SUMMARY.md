---
phase: 08-publish-main-verify-ci
plan: 01
subsystem: infra
tags: [git, github, ci]

requires:
  - phase: 06-ci-on-github
    provides: CI workflow on main branch
provides:
  - Local `main` and `origin/main` at same SHA (REPO-03)
  - Evidence of canonical origin URL vs mix.exs @source_url
affects: [phase-08-02, hex-publish]

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/08-publish-main-verify-ci/08-01-SUMMARY.md
  modified: []

key-decisions:
  - "Used plain git push origin main (no force) per plan threat model."

patterns-established: []

requirements-completed: [REPO-03]

duration: 15min
completed: 2026-04-23
---

# Phase 8: Publish main & verify CI — Plan 08-01 Summary

**Pushed 22 local commits on `main` to `origin` so GitHub CI monitors the same HEAD as local development.**

## Performance

- **Duration:** ~15 min (orchestrated inline)
- **Started:** 2026-04-23
- **Completed:** 2026-04-23
- **Tasks:** 3
- **Files modified:** 0 (git remote state + this SUMMARY only)

## Accomplishments

- Confirmed `origin` URL is `https://github.com/szTheory/threadline.git`, matching `mix.exs` `@source_url` path `szTheory/threadline`.
- Recorded drift before push: `git rev-list --left-right --count origin/main...main` → `0	22` (local ahead by 22).
- `git push origin main` succeeded (`4519320..5cef03a  main -> main`).
- Post-fetch: `main` and `origin/main` both `5cef03a1a122cf87496e9ba68d7c11891ded2864`.
- Ran `MIX_ENV=test mix ci.all` — exit 0 (format, credo, compile --warnings-as-errors, tests).

## Task Commits

Tasks 1–3 were verified in the working tree; deliverable is this SUMMARY (single documentation commit for the plan):

1. **Task 1: Confirm canonical `origin` and drift** — recorded above; no repo file change.
2. **Task 2: Push `main` to `origin`** — push completed; see git output in verification.
3. **Task 3: Local CI health** — `MIX_ENV=test mix ci.all` exit 0.

**Plan commit:** `b352856` — docs(08-01): complete REPO-03 — sync main to origin

## Files Created/Modified

- `.planning/phases/08-publish-main-verify-ci/08-01-SUMMARY.md` — REPO-03 evidence and task log.

## Verification

1. `git fetch origin main && [ "$(git rev-parse main)" = "$(git rev-parse origin/main)" ]` → OK at `5cef03a1a122cf87496e9ba68d7c11891ded2864`.
2. `git remote get-url origin` contains `github.com/szTheory/threadline`.
3. `.github/workflows/ci.yml` uses `branches: [main]` for `push` and `pull_request` (read during plan).
4. No `--force` / `--force-with-lease` used on push.

## Deviations

- None.

## Self-Check: PASSED
