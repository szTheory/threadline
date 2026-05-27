---
phase: 114-release-0-6-0-packaging
plan: 03
subsystem: infra
tags: [hex, release, contributing, verify.release]

requires:
  - phase: 114-01
    provides: "@version 0.6.0 and CHANGELOG"
  - phase: 114-02
    provides: "install snippet SSOT ~> 0.6"
provides:
  - "CONTRIBUTING maintainer runbook at v0.6.0"
  - "Green mix verify.release on clean tree"
  - "Green mix ci.all after release-surface edits"
affects: []

tech-stack:
  added: []
  patterns: ["verify.release pre-flight before human tag"]

key-files:
  created: []
  modified:
    - CONTRIBUTING.md
    - test/threadline/release_artifact_contract_test.exs
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - examples/threadline_phoenix/README.md

key-decisions:
  - "Example router/README evidence_authorize_fn aligned to getting-started truth"

patterns-established: []

requirements-completed: [REL-03]

duration: 8min
completed: 2026-05-27
---

# Phase 114 Plan 03 Summary

**REL-03 publish-ready boundary: CONTRIBUTING v0.6.0 literals, verify.release and ci.all green**

## Performance

- **Duration:** 8 min
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Refreshed CONTRIBUTING tag/publish examples from v0.3.0 to v0.6.0
- Locked v0.6.0 in release artifact CONTRIBUTING contract test
- `mix verify.release` passes on clean tree (hex.build + docs + shape)
- `mix ci.all` passes (692 + 45 example tests)
- Aligned example router/README operator mount with `evidence_authorize_fn` for doc-contract parity

## Task Commits

1. **Task 1: Refresh CONTRIBUTING** - `c78abaa`
2. **Task 2: verify.release** - verified on clean tree (post `7d2dbcf`, `6d06752`)
3. **Task 3: ci.all** - verified green after example mount sync

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Blocking] Example operator mount evidence gate**
- **Found during:** Task 3 (`mix ci.all`)
- **Issue:** Getting-started guide included `evidence_authorize_fn` but example router/README did not — doc contract tests failed
- **Fix:** Added `my_evidence_authorize_fn/1` to router and synced README mount snippet
- **Files modified:** examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex, examples/threadline_phoenix/README.md
- **Verification:** `mix ci.all` exits 0

## Issues Encountered

Pre-existing WIP stashed temporarily for clean-tree `verify.release`; restored after phase commits.

## Next Phase Readiness

Maintainer manual gate: tag `v0.6.0` and push after CI green on main.

---
*Phase: 114-release-0-6-0-packaging*
*Completed: 2026-05-27*
