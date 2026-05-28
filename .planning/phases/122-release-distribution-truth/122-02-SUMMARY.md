---
phase: 122-release-distribution-truth
plan: 02
subsystem: infra
tags: [hex, release, ci, distribution, maintainer-gate]

requires:
  - phase: 122-01
    provides: Wave 1 doc-contract scaffolding and @version 0.6.0 SSOT
provides:
  - threadline 0.6.0 published on hex.pm (tag v0.6.0)
  - Green Release workflow run with gate-ci-green, publish-hex, Hex API verify
  - Evidence URL for Wave 3 distribution sync
affects: [122-03]

tech-stack:
  added: []
  patterns:
    - "Canonical publish lane via .github/workflows/release.yml workflow_dispatch bootstrap"

key-files:
  created:
    - git tag v0.6.0
  modified: []

key-decisions:
  - "Used release.yml bootstrap dispatch (not legacy hex-publish.yml)"
  - "Publish succeeded on run 26583473336 despite overall workflow failure from distribution-sync PR step"

patterns-established:
  - "Maintainer gate: confirm green main CI before dispatch; re-dispatch idempotently if publish skipped"

requirements-completed: [DIST-01]

duration: 20min
completed: 2026-05-28
---

# Phase 122 Plan 02 Summary

**Published threadline 0.6.0 to hex.pm via Release workflow bootstrap — gate-ci-green, publish-hex, and Hex API verify all succeeded**

## Performance

- **Duration:** ~20 min (maintainer ops)
- **Started:** 2026-05-28T15:11:00Z
- **Completed:** 2026-05-28T15:13:00Z
- **Tasks:** 3 (all manual maintainer-gate)
- **Files modified:** 0 (publish-only; no repo edits)

## Accomplishments

- Confirmed green CI on `main` and `@version "0.6.0"` in mix.exs
- Dispatched `release.yml` bootstrap with `tag=v0.6.0`, `release_version=0.6.0`
- Jobs **Verify CI is green on release SHA**, **Publish to Hex.pm**, and **Verify version on Hex.pm** succeeded
- hex.pm lists **0.6.0** as latest (`mix hex.info threadline` confirms)

## Task Commits

1. **Task 1: Confirm green CI on main** — verified via `gh run list --workflow=ci.yml`
2. **Task 2: Dispatch release.yml bootstrap** — run https://github.com/szTheory/threadline/actions/runs/26583473336
3. **Task 3: Confirm registry state** — Hex API + publish job attestation

**Plan metadata:** maintainer-gate (no code commits)

## Registry Evidence

| Field | Value |
|-------|-------|
| Tag | `v0.6.0` |
| Workflow | https://github.com/szTheory/threadline/actions/runs/26583473336 |
| Hex latest | 0.6.0 (2026-05-28) |
| Publish job | success (idempotent skip check passed, publish + verify succeeded) |

## Deviations from Plan

### distribution-sync PR creation failed in same run

- **Issue:** Run 26583473336 overall conclusion `failure` because **Post-publish distribution sync** step "Create distribution sync PR" failed
- **Impact:** Publish and Hex verify succeeded; Wave 3 handled separately (122-03)
- **Root cause:** GitHub Actions PR creation step failure (bot branch/PR permissions or race)

## Issues Encountered

- Workflow overall status shows `failure` while publish jobs succeeded — use per-job status for attestation, not run conclusion alone

## User Setup Required

None (maintainer gate complete)

## Next Phase Readiness

- Wave 3 (122-03): distribution sync PR opened and merged; adopter surfaces updated

---
*Phase: 122-release-distribution-truth*
*Completed: 2026-05-28*
