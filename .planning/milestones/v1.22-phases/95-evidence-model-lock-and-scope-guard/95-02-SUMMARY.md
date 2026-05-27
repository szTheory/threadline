---
phase: 95-evidence-model-lock-and-scope-guard
plan: 02
subsystem: api
tags: [evidence, docs, boundaries, contracts]
requires:
  - phase: 95
    provides: closed evidence subject contract
provides:
  - closed evidence subject inventory
  - unsupported-subject validator
  - doc-contract evidence boundary lock
affects: [phase-96, phase-97, phase-99, documentation]
tech-stack:
  added: []
  patterns: [closed registries, doc-contract boundary enforcement]
key-files:
  created:
    - lib/threadline/evidence/subject.ex
    - test/threadline/evidence/subject_test.exs
  modified:
    - guides/how-threadline-works.md
    - guides/integration-contracts.md
    - test/threadline/how_threadline_works_doc_contract_test.exs
    - test/threadline/integration_contracts_doc_contract_test.exs
key-decisions:
  - "Subject support is a closed registry, not a free-form string surface."
  - "The evidence-plane non-goal language is locked directly in public docs and contract tests."
patterns-established:
  - "Threadline-owned evidence subjects are validated explicitly and reject host-owned policy categories with stable errors."
  - "Negative product claims are enforced in code and docs before later API/UI expansion."
requirements-completed: [EVID-03]
duration: 20min
completed: 2026-05-25
---

# Phase 95: Evidence Model Lock And Scope Guard Summary

**Evidence subjects are now explicitly bounded in code and the public guides repeat the same non-goal contract.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-25T18:45:00Z
- **Completed:** 2026-05-25T19:04:54Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `Threadline.Evidence.Subject` with a closed supported-subject list for Threadline-owned evidence families.
- Added validator tests proving the supported set and explicit rejection of `rbac_policy`, `tenant_membership`, `approval_workflow`, `legal_hold`, and `vendor_report_pack`.
- Updated the public crash-course and integration-contract guides so they lock the same evidence-plane non-goals as the code.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add a closed evidence-subject inventory with explicit unsupported-subject errors** - Not committed in this run because the working tree already contained unrelated local changes.
2. **Task 2: Lock the evidence non-goal boundary in public contract docs** - Not committed in this run because the working tree already contained unrelated local changes.

**Plan metadata:** Not committed in this run.

## Files Created/Modified
- `lib/threadline/evidence/subject.ex` - Added the closed evidence subject registry and validator.
- `test/threadline/evidence/subject_test.exs` - Added supported/unsupported subject proof.
- `guides/how-threadline-works.md` - Added narrow evidence-plane non-goal language.
- `guides/integration-contracts.md` - Added matching evidence boundary language while preserving the host-owned auth/scope seam.
- `test/threadline/how_threadline_works_doc_contract_test.exs` - Locked the new evidence-plane wording in the crash-course guide.
- `test/threadline/integration_contracts_doc_contract_test.exs` - Locked the integration guide’s evidence boundary language.

## Decisions Made
- Accepted both direct subjects and descriptor maps in the validator so later API and CLI layers can reuse one narrow contract.
- Kept the evidence-plane clause additive in `guides/integration-contracts.md` so it layers on top of the existing `scope_query_fn` host-owned seam rather than replacing it.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Doc-contract assertions initially matched multi-word wrapped strings too tightly. The tests were adjusted to assert stable boundary terms instead of a specific line wrap.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Later evidence APIs, Mix tasks, and mounted views now have an explicit boundary contract to build on without widening Threadline into an auth or compliance platform.

---
*Phase: 95-evidence-model-lock-and-scope-guard*
*Completed: 2026-05-25*
