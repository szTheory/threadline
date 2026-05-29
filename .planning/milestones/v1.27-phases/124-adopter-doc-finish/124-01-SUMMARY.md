---
phase: 124-adopter-doc-finish
plan: 01
subsystem: testing
tags: [docs, doc-contract, getting-started, iex, adopt-auth, sigra]

requires:
  - phase: 123-first-hour-config
    provides: dual-contract pattern and one-artifact-per-REQ doc tests
provides:
  - IEx-first §6 audited write with demo-corr handoff to §8
  - Collapsed Sigra HTTP staging inside details only
  - Dedicated DOC-01 and DOC-02 doc contract tests
affects:
  - 124-02-PLAN
  - 124-03-PLAN

tech-stack:
  added: []
  patterns:
    - "Dual-contract: getting-started neutral IEx path; example README retains sigra HTTP SSOT"
    - "HTML fence marker getting-started-sigra-http-staging-fence inside §6 details"
    - "One verify artifact per REQ (DOC-01 §6 test, DOC-02 §5 test)"

key-files:
  created: []
  modified:
    - guides/getting-started-saas.md
    - test/threadline/getting_started_saas_doc_contract_test.exs

key-decisions:
  - "§6 primary exercise is IEx with host-built AuditContext; HTTP auth depth deferred to collapsed details and example README"
  - "Monolith walkthrough test no longer asserts open Sigra cookie literals; example_phoenix_readme_contract_test.exs retains SSOT"

patterns-established:
  - "§6 open prose is auth-neutral; all _threadline_phoenix_key references live inside details after getting-started-sigra-http-staging-fence"
  - "ADOPT-AUTH literals locked in dedicated §5-scoped test with :binary.match ordering"

requirements-completed: [DOC-01, DOC-02]

duration: 8min
completed: 2026-05-28
---

# Phase 124 Plan 01: Getting-Started §6 IEx-First + ADOPT-AUTH Contracts Summary

**IEx-first audited write in getting-started §6 with demo-corr handoff, Sigra HTTP collapsed into details, and dedicated DOC-01/DOC-02 doc contract tests**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-28T00:00:00Z
- **Completed:** 2026-05-28T00:08:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `### Run your first audited write in IEx` with `AuditContext`, `demo-corr`, and `audit_transaction_id` handoff to §8
- Renamed §6 HTTP subsection to `### HTTP requests and host auth` with canonical lane IDs; moved all cookie/curl prose into `<details>`
- Evolved doc contracts: monolith no longer requires open Sigra literals; new dedicated DOC-01 and DOC-02 tests with ordering asserts

## Task Commits

Each task was committed atomically:

1. **Task 1: Restructure getting-started §6 (DOC-01 prose)** - `bb0ac41` (docs)
2. **Task 2: Evolve getting_started doc contracts (DOC-01 + DOC-02)** - `7f9c94e` (test)

**Plan metadata:** `0dce9a0` (docs: complete plan)

## Files Created/Modified

- `guides/getting-started-saas.md` - §6 IEx-first exercise, collapsed HTTP auth, canonical lane table
- `test/threadline/getting_started_saas_doc_contract_test.exs` - DOC-01 §6 and DOC-02 §5 dedicated tests; monolith cleanup

## Decisions Made

None beyond plan — followed D-01 through D-09 as specified in 124-CONTEXT.md.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Verification

```bash
mix test test/threadline/getting_started_saas_doc_contract_test.exs  # 7 tests, 0 failures
mix test test/threadline/example_phoenix_readme_contract_test.exs      # 7 tests, 0 failures
```

## Self-Check: PASSED

- Task 1 grep acceptance: IEx subsection present, HTTP subsection renamed, old heading absent, `_threadline_phoenix_key` only inside `<details>`, `demo-corr` in §6 before §8
- Task 2 tests green; dedicated DOC-01/DOC-02 test names present; monolith has no `_threadline_phoenix_key` assert

## Next Phase Readiness

Ready for 124-02-PLAN (operator-surface `:schemas` documentation).

---
*Phase: 124-adopter-doc-finish*
*Completed: 2026-05-28*
