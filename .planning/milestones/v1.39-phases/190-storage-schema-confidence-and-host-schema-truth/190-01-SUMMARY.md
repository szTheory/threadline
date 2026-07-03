---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 01
subsystem: storage-schema
tags: [ecto, postgres, migrations, docs, schema]

requires:
  - phase: 189-quality-baseline-and-authority-surface-audit
    provides: storage-schema risk ranking and SCHEMA-03 routing
provides:
  - Validated one-segment storage schema identifier contract for generated SQL
  - Helper-quoted generated capture, semantics, and governance migration SQL
  - Documentation that custom storage schema config must be set before install generation
affects: [phase-190, generated-migrations, storage-schema, adopter-docs]

tech-stack:
  added: []
  patterns:
    - StorageSchema helpers are the single quoting seam for generated storage SQL
    - Generated migration source is parse-checked after quoted identifiers are embedded
    - Doc contracts lock migration generation-time storage schema freezing

key-files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-01-SUMMARY.md
  modified:
    - lib/threadline/capture/migration.ex
    - lib/threadline/semantics/migration.ex
    - lib/threadline/governance/migration.ex
    - test/threadline/storage_schema_test.exs
    - test/threadline/storage_schema_migration_contract_test.exs
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - README.md
    - guides/getting-started-saas.md

key-decisions:
  - "Generated install migration SQL uses Threadline.StorageSchema quoted identifiers for every validated storage-schema table, function, and drop/index reference touched by SCHEMA-03."
  - "Adopter docs now show storage_schema: \"audit\" before mix threadline.install and state that generated migration files freeze the configured schema name."

patterns-established:
  - "Generated migration parse contract: migration_content/0 output is checked with Code.string_to_quoted/1 when quoted identifiers are embedded."
  - "Storage/host schema vocabulary: Threadline storage_schema controls Threadline-owned tables/functions; host-table schema remains public/support/app-owned."

requirements-completed: [SCHEMA-03]

duration: 8m31s
completed: 2026-07-01
status: complete
---

# Phase 190 Plan 01: Quote Storage-Schema Identifiers and Freeze Generated Migration Contracts Summary

**Generated install migrations now validate and double-quote configured storage-schema identifiers, preserve mixed-case schemas, and document that install generation freezes the configured schema name.**

## Performance

- **Duration:** 8m31s
- **Started:** 2026-07-01T19:35:22Z
- **Completed:** 2026-07-01T19:43:53Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Locked `Threadline.StorageSchema` helper behavior for valid identifiers (`audit`, `threadline`, `AuditLog`, `_audit1`) and invalid single-segment violations before generated SQL is emitted.
- Updated capture, semantics, and governance migration generators to use `StorageSchema` quoted/qualified identifiers for storage-schema SQL references.
- Added generated migration parse contracts so quoted identifiers cannot produce invalid `.exs` migration source.
- Updated README and SaaS getting-started docs to show `storage_schema: "audit"` before `mix threadline.install`, state generation-time freezing, and separate Threadline storage schema from host-table schema.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Identifier and generation-time freeze contracts** - `07ee6635` (test)
2. **Task 1 GREEN: Quoted generated migration schema contracts** - `50cdba4e` (feat)
3. **Task 2 RED: Full migration quote contracts** - `021e0338` (test)
4. **Task 2 GREEN: Quote all generated migration SQL references** - `d6bc0753` (feat)
5. **Task 3 RED: Storage schema doc contracts** - `67816323` (test)
6. **Task 3 GREEN: Custom storage schema install docs** - `fc4283d0` (docs)

## Files Created/Modified

- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-01-SUMMARY.md` - Plan completion summary.
- `lib/threadline/capture/migration.ex` - Uses quoted storage schema/table identifiers in generated capture migration SQL.
- `lib/threadline/semantics/migration.ex` - Uses quoted storage schema/table identifiers in generated semantics migration SQL.
- `lib/threadline/governance/migration.ex` - Uses quoted storage schema/table/index identifiers in generated governance migration SQL.
- `test/threadline/storage_schema_test.exs` - Locks valid and invalid storage-schema identifier helper behavior.
- `test/threadline/storage_schema_migration_contract_test.exs` - Locks quoted generated SQL, mixed-case/custom schema freeze behavior, invalid config rejection, and generated source parseability.
- `test/threadline/readme_doc_contract_test.exs` - Locks README custom storage-schema install timing and schema vocabulary.
- `test/threadline/getting_started_saas_doc_contract_test.exs` - Locks SaaS guide custom storage-schema install timing and schema vocabulary.
- `README.md` - Documents `storage_schema: "audit"` before install generation and migration freezing.
- `guides/getting-started-saas.md` - Documents the custom storage-schema install path and storage-vs-host schema distinction.

## Decisions Made

- Used the existing `Threadline.StorageSchema` seam instead of adding a second quoting helper.
- Kept `storage_schema` as one PostgreSQL identifier segment; dotted host-table identifiers remain a separate host-schema/table concern.
- Chose generated-source parseability as a contract because quoted SQL inside generated `.exs` files can otherwise be textually correct but syntactically invalid.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed invalid generated migration source after quoted identifiers**
- **Found during:** Task 2 (Quote generated capture, semantics, and governance migration SQL)
- **Issue:** Single-line generated `execute "..."` calls became invalid Elixir source once quoted identifiers such as `"AuditLog"` were embedded.
- **Fix:** Added a parseability contract with `Code.string_to_quoted/1` and switched quoted generated SQL references to heredoc `execute` blocks.
- **Files modified:** `test/threadline/storage_schema_migration_contract_test.exs`, `lib/threadline/capture/migration.ex`, `lib/threadline/semantics/migration.ex`, `lib/threadline/governance/migration.ex`
- **Verification:** `mix compile --warnings-as-errors && mix test test/threadline/storage_schema_migration_contract_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs`
- **Committed in:** `d6bc0753`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix was required for correctness of generated migrations and stayed within SCHEMA-03 scope.

## Issues Encountered

- The TDD Task 2 RED contract exposed invalid generated migration source after Task 1's partial quote implementation. This was fixed before completion and covered by a permanent parseability assertion.

## Known Stubs

None - stub scan found no placeholder/TODO-style stubs in modified files.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix compile --warnings-as-errors` - PASSED
- `mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs` - PASSED (16 tests, 0 failures)
- `mix test test/threadline/readme_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs` - PASSED (29 tests, 0 failures)
- `mix format --check-formatted` - PASSED

## Next Phase Readiness

Plan 190-01 closes SCHEMA-03 for generated migration SQL and docs. Wave 1 can continue with 190-02 to remove fixed owned Ecto prefixes and add explicit storage-schema test support.

## Self-Check: PASSED

- Found summary file: `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-01-SUMMARY.md`
- Found task commits: `07ee6635`, `50cdba4e`, `021e0338`, `d6bc0753`, `67816323`, `fc4283d0`

---
*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Completed: 2026-07-01*
