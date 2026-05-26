---
phase: 96-evidence-persistence-and-public-api
plan: 01
subsystem: api
tags: [evidence, ecto, governance, api]
requires:
  - phase: 95
    provides: append-only evidence schema and closed subject inventory
provides:
  - public evidence write context
  - subject-focused record helpers
  - normalized defaults and provenance contract
affects: [phase-96, phase-97, phase-98, evidence-api]
tech-stack:
  added: []
  patterns: [subject-focused writers, explicit repo boundaries, mechanical defaults only]
key-files:
  created:
    - lib/threadline/evidence.ex
    - test/threadline/evidence_test.exs
  modified:
    - lib/threadline/governance/evidence_record.ex
key-decisions:
  - "Kept the supported public surface narrow with one `record_*` helper per closed evidence subject family."
  - "Auto-filled only library-owned mechanics (`subject`, `subject_ref`, `recorded_at`, `schema_version`, and provenance) while leaving semantic meaning explicit."
patterns-established:
  - "Evidence writes use explicit `repo:` handling and return tuple-shaped success/error results."
  - "Subject refs are normalized to string-keyed maps before persistence so later read helpers can query one stable shape."
requirements-completed: [PROOF-01]
duration: 4min
completed: 2026-05-25
---

# Phase 96: Evidence Persistence And Public API Summary

**Threadline now records owned evidence facts through a dedicated public context instead of exposing the schema as the contract.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-25T19:49:12Z
- **Completed:** 2026-05-25T19:53:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `Threadline.Evidence` with subject-focused write helpers for redaction, trigger coverage, retention run/policy, export delivery, and support-scope posture.
- Required explicit `repo:` handling at the public boundary while keeping write outcomes in the usual `{:ok, record}` / `{:error, reason}` shape.
- Normalized string-keyed `subject_ref` payloads and stable provenance metadata before insert, then proved the contract with focused evidence tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the public evidence write context with subject-focused helpers** - Not committed in this run because the working tree already contained unrelated local changes.
2. **Task 2: Capture mechanical defaults and narrow provenance without inventing semantic meaning** - Not committed in this run because the working tree already contained unrelated local changes.

**Plan metadata:** Not committed in this run.

## Files Created/Modified
- `lib/threadline/evidence.ex` - Added the public evidence write boundary and shared normalization logic.
- `lib/threadline/governance/evidence_record.ex` - Tightened structural validation for maps, non-empty strings, and positive schema version values.
- `test/threadline/evidence_test.exs` - Added proof for helper coverage, explicit repo handling, normalized defaults, and semantic-field rejection.

## Decisions Made
- Kept the private insert builder private so callers cannot bypass the closed subject boundary with a generic write-anything API.
- Allowed helper-specific provenance labels to be deterministic and library-owned instead of ambient or Phoenix-derived.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The first implementation pass piped attrs into `EvidenceRecord.changeset/2` incorrectly. Fixing the insert call to build `%EvidenceRecord{}` explicitly resolved the issue without changing the public contract.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 96 read-side work can now project over one stable, Phoenix-optional evidence write contract instead of reaching into schema internals.

---
*Phase: 96-evidence-persistence-and-public-api*
*Completed: 2026-05-25*
