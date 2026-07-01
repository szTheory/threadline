---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 07
subsystem: storage-schema
tags: [postgres, host-schema, trigger-sql, coverage, continuity]

requires:
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: 190-01 quoted storage-schema contracts and 190-02 prefix-free owned schemas
provides:
  - support.tickets trigger SQL and selected-schema coverage/verify proof
  - Malformed host table identifiers fail before SQL generation
  - Continuity readiness for schema-qualified host tables and explicit host schema opts
affects: [phase-190, host-schema, coverage, continuity, storage-schema]

tech-stack:
  added: []
  patterns:
    - StorageSchema.parse_table_identifier/1 preserves empty dot segments so malformed host identifiers fail loudly
    - Coverage and verify use --schema as selected host schema while storage_schema remains Threadline-owned storage
    - Continuity readiness validates selected host schemas through CoverageSchemas before catalog and coverage queries

key-files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-07-SUMMARY.md
  modified:
    - lib/threadline/storage_schema.ex
    - lib/threadline/continuity.ex
    - test/threadline/storage_schema_test.exs
    - test/threadline/capture/trigger_sql_storage_schema_test.exs
    - test/threadline/verify_coverage_task_test.exs
    - test/threadline/continuity_brownfield_test.exs

key-decisions:
  - "Malformed host table identifiers such as support. and .tickets now raise instead of becoming public-schema shorthand."
  - "Continuity readiness treats support.tickets and schema: \"support\" as host-table identity only; Threadline storage_schema remains separate."

patterns-established:
  - "Selected-host-schema readiness: parse table identity, validate the host schema, then query catalog and coverage within that schema."
  - "Support-schema fixture: support.tickets test tables install normal Threadline triggers and assert coverage/verify through --schema=support."

requirements-completed: [SCHEMA-03, SCHEMA-04]

duration: 8 min
completed: 2026-07-01
status: complete
---

# Phase 190 Plan 07: Host-Schema Foundation Summary

**support.tickets now has executable trigger, coverage, verify, and continuity proof without changing Threadline-owned storage prefix semantics.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-01T20:25:28Z
- **Completed:** 2026-07-01T20:32:58Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added support-schema proof that trigger SQL targets `"support"."tickets"` while calling the configured Threadline storage function.
- Added real `support.tickets` catalog tests proving coverage and `mix threadline.verify_coverage --schema=support` report support tables only.
- Fixed host table parsing so malformed dotted identifiers fail loudly instead of falling back to `public`.
- Made continuity readiness accept `support.tickets` and `schema: "support"` while preserving public shorthand for bare table names.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: support host-schema trigger/coverage tests** - `9fa858d3` (test)
2. **Task 1 GREEN: host identifier validation** - `dfcb88b4` (feat)
3. **Task 2 RED: continuity host-schema readiness tests** - `36780227` (test)
4. **Task 2 GREEN: selected host-schema continuity readiness** - `cf2e4bae` (feat)

## Files Created/Modified

- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-07-SUMMARY.md` - Plan completion summary.
- `lib/threadline/storage_schema.ex` - Rejects malformed host table identifiers with empty dot segments.
- `lib/threadline/continuity.ex` - Parses schema-qualified host tables, validates selected host schemas, and checks readiness within that host schema.
- `test/threadline/storage_schema_test.exs` - Locks malformed host identifier rejection.
- `test/threadline/capture/trigger_sql_storage_schema_test.exs` - Locks configured storage function calls for `support.tickets` trigger SQL.
- `test/threadline/verify_coverage_task_test.exs` - Adds real `support.tickets` coverage and verify tests for `--schema=support`.
- `test/threadline/continuity_brownfield_test.exs` - Adds selected-host-schema readiness tests and prefix-aware existing fixture reads.

## Decisions Made

- Kept `--schema` and continuity `schema:` as host-schema selectors only; they do not feed `StorageSchema.repo_opts/1`.
- Used `CoverageSchemas.validate/2` at the continuity boundary so missing or invalid selected schemas fail before catalog/coverage lookup.
- Preserved bare table names as public shorthand for existing callers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Rejected malformed host table identifiers**
- **Found during:** Task 1 (support trigger, coverage, and verify behavior)
- **Issue:** `StorageSchema.parse_table_identifier/1` used `String.split(..., trim: true)`, so `.tickets`, `support.`, and `support..tickets` could collapse into valid-looking identifiers instead of failing.
- **Fix:** Trimmed the full input, preserved empty dot segments during splitting, and accepted only exactly `NAME` or `SCHEMA.NAME`.
- **Files modified:** `lib/threadline/storage_schema.ex`, `test/threadline/storage_schema_test.exs`
- **Verification:** `mix compile --warnings-as-errors && mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/verify_coverage_task_test.exs test/threadline/verify_coverage_policy_test.exs`
- **Committed in:** `dfcb88b4`

**2. [Rule 3 - Blocking] Repaired continuity test fixture reads after prefix removal**
- **Found during:** Task 2 RED run
- **Issue:** Existing continuity assertions queried `AuditChange` and `AuditTransaction` without `StorageSchema.repo_opts/1` after Plan 190-02 removed fixed owned schema prefixes.
- **Fix:** Updated the touched continuity fixture reads to use `repo_opts()`.
- **Files modified:** `test/threadline/continuity_brownfield_test.exs`
- **Verification:** `mix test test/threadline/continuity_brownfield_test.exs`
- **Committed in:** `36780227`

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking)
**Impact on plan:** Both fixes were required to satisfy the plan's host-schema threat mitigations and verification. No product scope or public API expansion.

## Issues Encountered

None remaining. The initial Task 2 RED run exposed the prefix-aware fixture gap above, which was fixed before implementation.

## Known Stubs

None - stub scan found only legitimate empty-list/nil test assertions and guard expressions in modified files.

## Threat Flags

None - the modified trust boundaries were already in the plan threat model and were mitigated with parser validation, schema validation, and selected-schema tests.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix compile --warnings-as-errors` - PASSED
- `mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs` - PASSED (13 tests, 0 failures)
- `mix test test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/verify_coverage_task_test.exs test/threadline/verify_coverage_policy_test.exs test/threadline/continuity_brownfield_test.exs` - PASSED (24 tests, 0 failures)
- `mix format --check-formatted` - PASSED

## TDD Gate Compliance

- Task 1 RED failed on malformed host identifiers falling back instead of raising, then GREEN passed after parser validation was tightened.
- Task 2 RED failed on `support.tickets` / `schema: "support"` continuity readiness still checking public, then GREEN passed after selected-host-schema readiness was implemented.

## Next Phase Readiness

Plan 190-07 completes the host-schema foundation for trigger generation, coverage/verify, and continuity readiness. Plans 190-08 and 190-09 can extend the same selected host-schema boundary into redaction and Timeline/row-history behavior.

## Self-Check: PASSED

- Found key files: `lib/threadline/storage_schema.ex`, `lib/threadline/continuity.ex`, `test/threadline/storage_schema_test.exs`, `test/threadline/capture/trigger_sql_storage_schema_test.exs`, `test/threadline/verify_coverage_task_test.exs`, `test/threadline/continuity_brownfield_test.exs`
- Found task commits: `9fa858d3`, `dfcb88b4`, `36780227`, `cf2e4bae`
- Final production/test worktree was clean before summary creation.

---
*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Completed: 2026-07-01*
