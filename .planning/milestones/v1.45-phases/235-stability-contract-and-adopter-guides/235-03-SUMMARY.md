---
phase: 235-stability-contract-and-adopter-guides
plan: 03
subsystem: testing
tags: [elixir, postgres, ecto, compatibility, sql-contracts]

# Dependency graph
requires:
  - phase: 235-01
    provides: generated-trigger migration validation and the phase's stability boundaries
provides:
  - Live PostgreSQL catalog contract for required audit-table columns and indexes
  - Literal actor GUC and per-table function-name contracts with production call-site checks
affects: [235-04, 235-05, postgres-storage, adopter-compatibility]

# Actuals (#2632), chars/4 over the realized implementation diff.
actuals:
  tokens: 2755
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Live pg_catalog facts compared with literal required sets and attributable added/missing diffs
    - SQL public-name pins paired with exact production source-use counts and mutation controls

key-files:
  created:
    - test/threadline/storage_catalog_contract_test.exs
    - test/threadline/capture/public_sql_contract_test.exs
  modified: []

key-decisions:
  - "Keep installed database facts and public SQL names in separate, literal test contracts."
  - "Resolve catalog relations through the configured storage schema and pin every current column and index in PostgreSQL."

patterns-established:
  - "Live storage contracts compare required table, column, and index sets with named missing/added differences."
  - "Public SQL contracts pin outputs independently from production constants and protect the production call sites."

requirements-completed: [CONTRACT-02, CONTRACT-03]
coverage:
  - id: D1
    description: "Installed audit table columns, types, nullability, and indexes are pinned from live PostgreSQL catalogs."
    requirement: CONTRACT-02
    verification:
      - kind: integration
        ref: "mix verify.test test/threadline/storage_catalog_contract_test.exs"
        status: pass
      - kind: other
        ref: "mix verify.format"
        status: pass
    human_judgment: false
  - id: D2
    description: "The actor GUC, per-table function names, and production naming call sites are protected by literal contracts."
    requirement: CONTRACT-03
    verification:
      - kind: unit
        ref: "mix verify.test test/threadline/capture/public_sql_contract_test.exs"
        status: pass
      - kind: other
        ref: "mix verify.format"
        status: pass
    human_judgment: false

plan_head_before: 20feb77f583de855e2bfdbe62f0138e4b3b68a8d
plan_head_after: cf9f552513dad19162a040286c47ac37899785ec
commits: 2
duration: 3min
completed: 2026-10-07
status: complete
---

# Phase 235 Plan 03: Storage and SQL Name Contracts Summary

The compatibility suite now checks installed PostgreSQL storage facts and literal SQL names against independent, mutation-sensitive contracts.

## Performance

- **Duration:** 3 minutes
- **Started:** 2026-10-07T00:51:37Z
- **Completed:** 2026-10-07T00:54:17Z
- **Tasks:** 2
- **Files modified or created:** 2 contract tests

## Accomplishments

- Added a live catalog contract for the configured storage schema's three audit tables, all required columns and nullability/type facts, and shipped index names, uniqueness, key columns, and predicates.
- Added literal actor GUC and ordinary, schema-qualified, and long per-table function-name pins, plus exact production call-site checks for readers, writers, trigger naming, and function naming.
- Added focused mutation controls proving that removing a pinned catalog fact or renaming a SQL source use is detected.

## Task Commits

1. **Task 1: Pin installed audit tables and indexes from PostgreSQL catalogs** - `fd99af78` (`test`)
2. **Task 2: Pin actor GUC and per-table function naming as public SQL literals** - `cf9f5525` (`test`)

## Files Created/Modified

- `test/threadline/storage_catalog_contract_test.exs` - Queries live PostgreSQL catalogs and compares literal column and index facts with focused diffs.
- `test/threadline/capture/public_sql_contract_test.exs` - Pins public SQL names and production source call sites.

## Decisions Made

- Keep live database catalog facts separate from public SQL naming contracts so each failure identifies its own compatibility boundary.
- Treat the installed PostgreSQL catalog as authoritative, including indexes introduced by later migrations beyond the generated install migration.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first catalog run found the later-migration `audit_transactions_actor_ref_gin` index in the installed database. Added it to the literal expected index set; the live contract then passed.
- Git metadata was read-only under the workspace permission profile. The task commits were completed through managed escalation with normal hooks, staging only each declared test file.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Both database and public SQL compatibility boundaries now fail with named set differences. Plan 235-04 can build its separate export and health-code contracts on the same explicit pinning style.

## Self-Check: PASSED

- Both created contract test files exist.
- Task commits `fd99af78` and `cf9f5525` are ancestors of `HEAD`.
- The plan evaluation-scope check resolves both task commits on this branch.
- Both focused verification commands and `mix verify.format` passed.

---
*Phase: 235-stability-contract-and-adopter-guides*
*Completed: 2026-10-07*
