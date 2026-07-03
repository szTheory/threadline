---
phase: 190-storage-schema-confidence-and-host-schema-truth
plan: 03
subsystem: storage-schema
tags: [ecto, postgres, query, export, audit-actions]

requires:
  - phase: 190-storage-schema-confidence-and-host-schema-truth
    provides: 190-02 prefix-free owned Ecto schemas and explicit storage-schema test helpers
provides:
  - Prefix-aware audited transaction helper writes, metadata updates, action linkage, and transaction lookup
  - Prefix-aware query and investigation preloads for transaction/action context
  - Runtime custom-storage tests for core query joins and export reads
affects: [phase-190, core-api, query, export, investigation]

tech-stack:
  added: []
  patterns:
    - "Audited transaction helpers preserve storage_schema through resolved options."
    - "Query preload call sites pass Threadline.Query.storage_opts/2 instead of relying on default prefixes."
    - "Focused tests seed Threadline-owned rows through explicit repo_opts/1 after owned schemas became prefix-free."

key-files:
  created:
    - .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-03-SUMMARY.md
  modified:
    - lib/threadline/audit.ex
    - lib/threadline/query.ex
    - lib/threadline/investigation.ex
    - test/threadline/semantics/audit_action_test.exs
    - test/threadline/audit_transaction_test.exs
    - test/threadline/query_test.exs
    - test/threadline/investigation_test.exs
    - test/threadline/export_test.exs

key-decisions:
  - "Threadline.Audit.transaction/3 now treats transaction-level storage_schema as authoritative for action recording, metadata update, linkage, and lookup."
  - "Query preloads are explicitly prefix-aware even when loaded structs may carry Ecto metadata prefixes, keeping D-190-08 visible at the call site."

patterns-established:
  - "Custom-storage sentinel tests compare audit and threadline rows in the same focused test to expose wrong-prefix reads and writes."
  - "Preload source contract: Query preload call sites must pass resolved storage options."

requirements-completed: [SCHEMA-01, SCHEMA-02]

duration: 7m17s
completed: 2026-07-01
status: complete
---

# Phase 190 Plan 03: Core Storage Schema API, Query, Preload, and Export Summary

**Core writes, transaction linkage, investigation preloads, query joins, and export reads now honor selected Threadline storage schemas.**

## Performance

- **Duration:** 7m17s
- **Started:** 2026-07-01T20:01:16Z
- **Completed:** 2026-07-01T20:08:33Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Threaded `storage_schema:` through `Threadline.Audit.transaction/3` option resolution, action recording, metadata updates, action linkage, and transaction lookup.
- Added dual-storage sentinel tests for `Threadline.record_action/2`, audited transactions, timeline correlation joins, investigation transaction/action preloads, export JSON/count/stream reads, and default-schema exclusion.
- Updated query preload boundaries to pass resolved storage options for investigation context, transaction preloads, and audit-change preloads.
- Repaired focused fixtures to seed prefix-free owned schemas through explicit `repo_opts/1`.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Core storage schema write contracts** - `082885cc` (test)
2. **Task 1 GREEN: Audited transaction storage schema plumbing** - `3e2cac3c` (feat)
3. **Task 2 RED: Query/export storage schema contracts** - `508f226a` (test)
4. **Task 2 GREEN: Prefix-aware query preloads** - `04dd8fb7` (feat)

## Files Created/Modified

- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-03-SUMMARY.md` - Plan completion summary.
- `lib/threadline/audit.ex` - Carries resolved `storage_schema` through audited transaction action recording, linkage, metadata update, and lookup.
- `lib/threadline/query.ex` - Passes storage options to investigation, transaction, and audit-change preload calls.
- `lib/threadline/investigation.ex` - Forwards opts into prefix-aware investigation preloads.
- `test/threadline/semantics/audit_action_test.exs` - Proves `record_action/2` inserts into selected storage and repairs default-storage reads.
- `test/threadline/audit_transaction_test.exs` - Proves audited transaction linkage and capture-only metadata target selected storage.
- `test/threadline/query_test.exs` - Proves custom-storage timeline correlation joins and locks preload call sites.
- `test/threadline/investigation_test.exs` - Proves transaction context preloads selected-storage action data.
- `test/threadline/export_test.exs` - Proves JSON export, count, and stream reads exclude default-schema sentinels.

## Decisions Made

- Used transaction-level `storage_schema:` as the authoritative storage prefix for semantic action inserts inside `Audit.transaction/3`; action tuple extras cannot silently redirect the action to another storage schema.
- Kept preload prefixing explicit at each `repo.preload/3` call site rather than depending on Ecto loaded-struct metadata.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired focused tests after prefix-free schema removal**
- **Found during:** Task 1 and Task 2 RED baseline runs
- **Issue:** Existing focused assertions and fixtures still read or inserted `AuditAction`, `AuditTransaction`, and `AuditChange` without repo prefix options after Plan 190-02 removed fixed `@schema_prefix` attributes.
- **Fix:** Updated the touched test fixtures/assertions to use `repo_opts()` for default Threadline storage and `repo_opts("audit")` for custom storage.
- **Files modified:** `test/threadline/semantics/audit_action_test.exs`, `test/threadline/audit_transaction_test.exs`, `test/threadline/investigation_test.exs`, `test/threadline/export_test.exs`
- **Verification:** Focused Task 1 and Task 2 test commands pass.
- **Committed in:** `082885cc`, `508f226a`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** Required to make the plan's own focused verification meaningful after the intentional prefix removal from 190-02. No product scope expansion.

## Issues Encountered

- Task 2's RED source contract initially expected an invalid Elixir call shape for `repo.preload/3` with a middle keyword argument. The GREEN commit corrected the contract and implementation to use `[transaction: :action]`.

## Known Stubs

None - stub scan found only ordinary `nil` and empty-list test assertions plus existing query logic.

## Threat Flags

None - the security-relevant storage-prefix trust boundary is covered by the plan threat model (`T-190-07`, `T-190-08`) and was mitigated with explicit repo options.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix compile --warnings-as-errors` - PASSED
- `mix test test/threadline/semantics/audit_action_test.exs test/threadline/audit_transaction_test.exs` - PASSED (21 tests, 0 failures)
- `mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/export_test.exs` - PASSED (97 tests, 0 failures)
- `mix format --check-formatted` - PASSED

## TDD Gate Compliance

- Task 1 RED failed only on the new audited transaction custom-storage tests (`:missing_audit_transaction_for_link`), then GREEN passed after storage-schema plumbing was added.
- Task 2 RED failed only on the new preload call-site source contract, then GREEN passed after prefix-aware preloads were implemented.

## Next Phase Readiness

Core API/query/export paths are storage-prefix aware for this plan's scope. Later Phase 190 plans can build on the same `StorageSchema.repo_opts/1` pattern for queued export jobs, retention/pruning, operator reads, and host-schema truth.

## Self-Check: PASSED

- Found summary path to be created: `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-03-SUMMARY.md`
- Found task commits: `082885cc`, `3e2cac3c`, `508f226a`, `04dd8fb7`
- Final production/test worktree was clean before summary creation.

---
*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Completed: 2026-07-01*
