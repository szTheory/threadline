---
phase: 98-mounted-evidence-views-on-audit
plan: 02
subsystem: auth
tags: [phoenix, liveview, auth, evidence, mix]
requires:
  - phase: 98-01
    provides: mounted /audit/evidence surface and LiveView tests
provides:
  - fail-closed host-owned evidence capability seam
  - shared verdict presentation between mounted evidence and CLI proof output
  - auth and parity tests for denied access and shared semantic labels
affects: [operator-surface, auth, evidence, mix-task]
tech-stack:
  added: []
  patterns: [capability-specific on_mount flags, shared proof presenter for mounted and CLI surfaces]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/evidence/proof.ex
    - lib/threadline/operator_surface/unsupported.ex
    - test/threadline/operator_surface/auth_test.exs
    - test/mix/tasks/threadline.evidence_show_test.exs
patterns-established:
  - "Evidence visibility is host-owned and fail-closed via evidence_authorize_fn."
  - "Mounted and CLI evidence surfaces share verdict semantics through Threadline.Evidence.Proof helpers."
requirements-completed: [SURF-02, SURF-03]
duration: 1h
completed: 2026-05-26
---

# Phase 98: Mounted Evidence Views On `/audit` Summary

**Evidence access is now explicitly host-gated and mounted/CLI surfaces share one verdict vocabulary rooted in `Threadline.Evidence.Proof`**

## Performance

- **Duration:** 1h
- **Started:** 2026-05-26T12:05:00Z
- **Completed:** 2026-05-26T13:07:30Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added `evidence_authorize_fn` and `threadline_evidence_enabled` so mounted evidence fails closed unless the host explicitly allows it.
- Added a shared proof presenter seam in `Threadline.Evidence.Proof` so mounted evidence and CLI rendering use the same semantic verdict labels.
- Extended auth, LiveView, and Mix-task tests to prove denied access plus semantic parity.

## Task Commits

No task commits were created. The worktree already contained unrelated user changes across overlapping files, so execution stayed uncommitted to avoid mixing phase work with unrelated edits.

## Files Created/Modified
- `lib/threadline/operator_surface/auth.ex` - fail-closed evidence capability assignment
- `lib/threadline/evidence/proof.ex` - shared verdict presenter for mounted and CLI surfaces
- `lib/threadline/operator_surface/unsupported.ex` - explicit evidence fallback copy
- `test/threadline/operator_surface/auth_test.exs` - evidence capability coverage
- `test/threadline/operator_surface/live/evidence_live_test.exs` - denied access and semantic label assertions

## Decisions Made
- Introduced a dedicated evidence capability seam rather than reusing policy access implicitly.
- Reused `Threadline.Evidence.Proof` as the semantic center so mounted UI and Mix-task output cannot drift into separate verdict vocabularies.

## Deviations from Plan

### Auto-fixed Issues

**1. Full-suite verification blocked by unrelated alias drift**
- **Found during:** post-implementation verification
- **Issue:** `mix verify.test` fails in `Threadline.CiTopologyContractTest` because `mix.exs` alias text no longer matches the topology contract assertion.
- **Fix:** Left the unrelated failure untouched and recorded it explicitly; targeted evidence/auth/Mix-task verification for this phase is green.
- **Files modified:** none
- **Verification:** `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` and `MIX_ENV=test mix test test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1` pass

---

**Total deviations:** 1 auto-fixed
**Impact on plan:** Phase 98 implementation is complete on the current tree, but full-suite milestone verification still depends on the unrelated CI topology alias fix.

## Issues Encountered
- None inside the evidence implementation itself; the only red gate is the pre-existing CI topology alias drift.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Host-owned evidence gating and semantic parity are implemented and covered by targeted tests.
- Final verify-work should wait until the unrelated `mix verify.test` alias-drift failure is resolved or accepted as external to this phase.

---
*Phase: 98-mounted-evidence-views-on-audit*
*Completed: 2026-05-26*
