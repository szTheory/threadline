---
phase: 95-evidence-model-lock-and-scope-guard
plan: 01
subsystem: database
tags: [ecto, postgres, governance, evidence]
requires: []
provides:
  - append-only evidence table contract
  - evidence record schema and changeset
  - targeted append-only evidence tests
affects: [phase-96, evidence-api, governance]
tech-stack:
  added: []
  patterns: [append-only governance records, explicit required-field changesets]
key-files:
  created:
    - lib/threadline/governance/evidence_record.ex
    - priv/repo/migrations/20260525210000_threadline_evidence_records.exs
    - test/threadline/governance/evidence_record_test.exs
  modified:
    - lib/threadline/governance/migration.ex
key-decisions:
  - "Kept evidence rows append-only by omitting `updated_at` from both schema and DDL."
  - "Added a forward migration for the checked-in repo while keeping `mix threadline.install` on the single governance migration path."
patterns-established:
  - "Governance evidence uses a dedicated table instead of overloading mutable runtime rows."
  - "Strict changesets require machine-readable evidence payload fields even when the database has fallback defaults."
requirements-completed: [EVID-01, EVID-02]
duration: 35min
completed: 2026-05-25
---

# Phase 95: Evidence Model Lock And Scope Guard Summary

**Append-only evidence records now have a dedicated governance table, stable schema contract, and executable insert proof.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-05-25T18:30:00Z
- **Completed:** 2026-05-25T19:04:54Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `threadline_evidence_records` to the generated governance migration with subject, provenance, detail, and version fields.
- Added a checked-in forward migration so current repos can materialize the evidence table without reinstalling.
- Created `Threadline.Governance.EvidenceRecord` plus targeted tests for valid shape, strict required fields, and repeated inserts for the same logical subject.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the evidence-record governance table to the existing install path** - Not committed in this run because the working tree already contained unrelated local changes.
2. **Task 2: Add the EvidenceRecord schema and prove the append-only contract** - Not committed in this run because the working tree already contained unrelated local changes.

**Plan metadata:** Not committed in this run.

## Files Created/Modified
- `lib/threadline/governance/migration.ex` - Expanded the generated governance schema with the evidence table and indexes.
- `lib/threadline/governance/evidence_record.ex` - Added the Ecto schema and strict changeset contract for evidence rows.
- `priv/repo/migrations/20260525210000_threadline_evidence_records.exs` - Added a forward migration for existing repos.
- `test/threadline/governance/evidence_record_test.exs` - Added targeted proof for valid payloads, missing-field rejection, and append-only repeated inserts.

## Decisions Made
- Added a new table instead of reusing `threadline_export_jobs` or `threadline_retention_runs` so evidence snapshots stay distinct from mutable operational state.
- Kept database defaults for provenance/detail/schema version while removing schema defaults so the Ecto contract still fails loud on missing inputs.

## Deviations from Plan

Added a checked-in forward migration under `priv/repo/migrations/` so the targeted test could exercise real inserts on the current repo schema. This stayed inside phase scope and preserved the install-path requirement.

## Issues Encountered

The first test run showed schema defaults were masking the required-field contract. Removing those schema-level defaults fixed the mismatch while preserving database defaults.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 96 can build persistence APIs on a stable append-only evidence primitive without redefining the storage contract.

---
*Phase: 95-evidence-model-lock-and-scope-guard*
*Completed: 2026-05-25*
