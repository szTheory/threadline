---
phase: 247-ci-critical-path-and-suite-lanes
plan: 25
subsystem: testing
tags: [exunit, docker, ci-evidence, recheck]
requires:
  - phase: 247-24
    provides: explicit one-series authorization and approved executable source hashes
provides:
  - One candidate-bound terminal local preflight receipt and machine-projected report
  - Independent disposition of compiler, container, timing, and main-CI evidence limits
affects: [ci-evidence, phase-247]
tech-stack:
  added: []
  patterns: [write-once local observation reservation, strict source-bound preflight]
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK-DECISION.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK-PREFLIGHT.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK.reservation.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-RECHECK-DISPOSITION.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-25-SUMMARY.md
  modified: []
key-decisions:
  - "Treat any compile-smoke stderr as terminal INVALID; the success marker does not override the strict producer gate."
  - "Keep CR-05 open, preserve historical AMD64 cause as UNPROVEN, and keep CI-02/CI-03 acceptance unchanged."
metrics:
  duration: 15 min
  completed: 2026-10-27
  status: complete
actuals:
  tokens: 3071
  tasks: 2
  commits: 2
commits: 2
plan_head_before: d42f0912f17dc8dcd265a52f72c41d9f58e4e4b0
plan_head_after: c7d92fcc4eb463f4c94aeeee39a4415be6b2db20
requirements-completed: []
---

# Phase 247 Plan 25: Local Recheck Evidence Summary

**One reserved ARM64 preflight compiled the runner but failed the strict stderr gate on an unused-variable warning, so no ExUnit arms ran.**

## Performance

- **Duration:** Approximately 15 minutes
- **Started:** 2026-10-27T17:14:00Z (approximate; start time was not captured)
- **Completed:** 2026-10-27T17:29:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Bound the one-use machine decision to committed source HEAD `d42f0912f17dc8dcd265a52f72c41d9f58e4e4b0`; all three approved executable hashes matched Plan 24.
- Reserved and ran exactly one cached native ARM64 compile preflight. The child exited 0 and emitted `THREADLINE_COMPILE_SMOKE|ok`, but stderr's unused `mode` warning made the strict result `INVALID`; zero ExUnit arms ran and no series receipt was fabricated.
- Verified the owned CID against its inspected name and removed that CID successfully. Rendered and verified the terminal preflight report.
- Independently reviewed raw evidence, historical pins, and CI scope. The review recorded unavailable exact-version source text, missing elapsed-time fields in the preflight, and the weaker INVALID-verification path.
- Preserved B4's four successes/two failed exclusions and `median_wall_s=null`; CI-03 remains a MISS at `1.24/1.28/1.27`; Phase 247 remains 2/4.

## Task Commits

Each task was committed atomically:

1. **Task 1: Run one source-bound compiler preflight and terminal local series** — `af114693` (docs)
2. **Task 2: Independently review the receipt and state the remaining main-CI route** — `c7d92fcc` (docs)

## Files Created/Modified

- `247-LOCAL-CANARY-RECHECK-DECISION.md` — exact four-line grant bound to the execution HEAD.
- `247-LOCAL-CANARY-RECHECK-PREFLIGHT.json` — terminal INVALID preflight with runtime, image, stderr, owned CID, and cleanup evidence.
- `247-LOCAL-CANARY-RECHECK.reservation.json` — one-use reservation consumed before Docker launch.
- `247-LOCAL-CANARY-RECHECK.md` — machine-generated report projection, verified against the raw preflight.
- `247-RECHECK-DISPOSITION.md` — independent review, source and timing limits, and future main-CI gates.

## Decisions Made

- The producer's strict `compile_smoke_stderr_present` verdict is authoritative for this grant. The emitted compile marker and zero exit do not promote the preflight to VALID.
- CR-05 remains open. WR-04 ownership evidence is satisfied for this sole Plan 25 child; this does not repair Plan 22's historical missing identity evidence.
- Local native ARM64 evidence does not establish the historical AMD64 cause. CI-02 and CI-03 acceptance remain unchanged.

## Deviations from Plan

None — the terminal invalidity path, no-retry rule, independent review, and future-scope barriers followed the plan.

## Issues Encountered

- The full runner compile smoke emitted an unused-variable warning on stderr. This was recorded as terminal INVALID; no source repair or retry was made.
- The first Task 1 git-index write was denied by the sandbox before staging. The same narrowly scoped commit was then made with escalated permission and normal hooks; no `--no-verify` was used.

## User Setup Required

None.

## Next Phase Readiness

The one local grant is consumed. A future CI-03 candidate needs a separate scope decision based on fixed B4 residuals and locally verified fixture/source changes; any landing and new bounded main cohort require another explicit maintainer grant. B4 and diagnostic caps do not roll over. A future main cohort must provide five qualifying successes for the CI-02 median and three consecutive ratios per lane for CI-03.

---
*Phase: 247-ci-critical-path-and-suite-lanes*
*Completed: 2026-10-27*

## Self-Check: PASSED

- The decision, terminal preflight, reservation, report, disposition, and summary files exist.
- Task commits `af114693` and `c7d92fcc` are ancestors of this worktree HEAD.
- The raw preflight/report verification passed (`INVALID; 0 attempted arms`), and the plan-scope commit check found both task commits with no out-of-scope files.
