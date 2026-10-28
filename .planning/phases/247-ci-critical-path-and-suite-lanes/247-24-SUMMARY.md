---
phase: 247-ci-critical-path-and-suite-lanes
plan: 24
subsystem: testing
tags: [exunit, docker, authorization, ci-evidence]
requires:
  - phase: 247-23
    provides: reviewed pure repairs for the pinned-runtime recheck path
provides:
  - A fresh explicit authorization for one bounded local recheck series
  - A decision record bound to the reviewed executable SHA-256 hashes
affects: [247-25, ci-evidence]
tech-stack:
  added: []
  patterns: [write-once human scope authorization, approved-source hash binding]
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK-AUTHORIZATION.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-24-SUMMARY.md
  modified: []
key-decisions:
  - "Authorize exactly one native ARM64 cached-image local recheck, capped at 150 seconds; stop on the first invalid result."
requirements-completed: []
actuals:
  tokens: 1656
  tasks: 1
  commits: 1
plan_head_before: f5acad55b7addf911e3507bef8e33b72c163251b
plan_head_after: 8f3af149b8661876d9f925b6559df689a564a436
commits: 1
duration: 8 min
completed: 2026-10-27
status: complete
---

# Phase 247 Plan 24: Local Canary Recheck Authorization Summary

**A fresh maintainer decision authorizes one source-bound local recheck series with a 150-second cap and a first-invalid stop.**

## Performance

- **Duration:** Approximately 8 minutes
- **Started:** 2026-10-27T17:11:00Z (approximate; start time was not captured)
- **Completed:** 2026-10-27T17:20:31Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Recorded the maintainer’s fresh reply, “what do u rec? let's follow ur recs”, as authorization for the recommendation to run exactly one bounded local recheck series.
- Bound approval to reviewed repair commit `9fae282de737701af0d2a4009632afa662bd381d` and the verified SHA-256 hashes of the producer, runner, and formatter source files.
- Preserved the fixed native ARM64 cached-image scope, 45-second preflight cap, 15-second child caps, 150-second total cap, first-invalid stop, and verified-CID-only cleanup requirements.
- Left the consumed Plan 22 grant untouched. No Docker, Elixir, Mix, network, production suite, hosted CI, or new observation was run.

## Verification

- The Plan 24 automated decision/cap assertion passed: exactly one recognized `Decision:` line and the required 15-, 45-, 150-second and no-replacement limits were present.
- SHA-256 of all three current source files matched the corresponding bytes in reviewed commit `9fae282d`.
- Authorization record committed as `8f3af149` before this summary. No product or executable files changed.

## Task Commits

1. **Task 1: Decide one exact local recheck cap** — `8f3af149` (docs)

**Plan metadata:** committed separately after this summary was written.

## Decisions Made

- Followed the maintainer’s request for the recommendation and selected `authorize-one-recheck-series`; this is a new scope grant, separate from the consumed Plan 22 authorization.
- The recommendation was one local recheck capped at 150 seconds total, with no retry after the first invalid result and no hosted CI or new main cohort.

## Deviations from Plan

None — the selected authorization path and verification followed the plan. Plan 24 intentionally did not start the observation; Plan 25 owns the candidate-bound machine grant and preflight.

## Next Phase Readiness

Plan 25 may proceed after this summary is committed, provided it rechecks the three approved hashes before creating its separate machine grant, reservation, or starting any preflight. Only metadata commits occurred between the authorization record and this point.

## Self-Check: PASSED

- Authorization record and this summary exist in the specified phase directory.
- Authorization task commit `8f3af149` is an ancestor of the current worktree HEAD.
- Approved producer, runner, and formatter hashes were independently checked against commit `9fae282d`.

---
*Phase: 247-ci-critical-path-and-suite-lanes*
*Completed: 2026-10-27*
