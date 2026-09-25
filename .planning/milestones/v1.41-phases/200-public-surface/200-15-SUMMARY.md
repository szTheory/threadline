---
phase: 200-public-surface
plan: 15
subsystem: documentation
tags: [hex-package, source-vocabulary, plug, ecto, retention, query]
requires:
  - phase: 200-public-surface
    provides: exact zero-allowlist archive matcher and finalized public module surface
provides:
  - durable Mix, capture, Plug, query, and retention source rationale without planning provenance
  - green exact archive-owner projections for the five remaining core packaged source files
affects: [200-14, public-docs, hex-package]
actuals:
  tokens: 1526
  tasks: 2
  commits: 2
plan_head_before: ecfe1922f894ff514fa1c434991d9770dbab4baf
tech-stack:
  added: []
  patterns: [present-tense contract prose, public-facade references, exact nonempty source ownership]
key-files:
  created: []
  modified:
    - lib/mix/tasks/threadline.health.coverage.ex
    - lib/threadline/capture/audit_transaction.ex
    - lib/threadline/plug.ex
    - lib/threadline/query.ex
    - lib/threadline/retention/policy.ex
key-decisions:
  - "Public and implementation rationale states stable behavior and ownership boundaries without release, requirement, or planning chronology."
  - "Threadline.Audit.transaction/3 and Getting started §6 are the supported bridge references; direct set_config callers retain a documented manual path."
  - "The current timeline index tradeoff belongs to the capture migration boundary, while anonymous actor equivalence and retention remain explicit present-tense contracts."
patterns-established:
  - "Source rationale names the durable invariant, current tradeoff, and supported public destination rather than the planning event that introduced it."
requirements-completed: [SURFACE-01, SURFACE-02, SURFACE-07]
coverage:
  - id: D1
    description: "Mix coverage, capture transaction, and Plug source use durable contract language and resolve bridge readers to supported public documentation."
    requirement: SURFACE-01
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/audit_transaction_test.exs test/threadline/plug_test.exs (60 tests)"
        status: pass
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs --only source_vocab_core_runtime"
        status: pass
    human_judgment: false
  - id: D2
    description: "Query and retention source explain ordering, anonymous identity, and global policy semantics without planning chronology."
    requirement: SURFACE-07
    verification:
      - kind: integration
        ref: "test/threadline/query_test.exs test/threadline/retention/policy_test.exs (61 tests)"
        status: pass
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs --only source_vocab_core_query_policy"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 15: Core Source Vocabulary Summary

**Five core packaged source files now explain their contracts in durable Elixir, Ecto, Plug, PostgreSQL, and operator terms, with exact archive-owner proofs and unchanged runtime behavior.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-12T10:46:28Z
- **Completed:** 2026-09-12T10:49:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Replaced planning IDs in the coverage Mix task and capture schema with stable viewer-exit, transaction-grouping, and nullable-context explanations.
- Kept the Plug's public PostgreSQL bridge while routing new integrations to `Threadline.Audit.transaction/3` and direct GUC callers to the canonical Getting started section.
- Reframed timeline ordering around the real single-column index tradeoff and capture migration ownership boundary without changing either query.
- Documented anonymous actor equivalence and the single global retention policy as current contracts rather than release chronology.
- Proved both exact source cohorts are nonempty, archive-backed, zero-allowlist clean, and sensitive to an injected offender; all 121 focused tests remain green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Clean Mix, capture, and Plug provenance without changing their contracts** - `69d1ab18` (docs)
2. **Task 2: Replace query and retention chronology with stable contract language** - `8310feee` (docs)

## Files Created/Modified

- `lib/mix/tasks/threadline.health.coverage.ex` - explains viewer exit behavior and the separate failing CI command.
- `lib/threadline/capture/audit_transaction.ex` - explains PgBouncer-safe transaction grouping and nullable contextual attribution.
- `lib/threadline/plug.ex` - points PostgreSQL bridge readers at the public audit helper and canonical manual guide.
- `lib/threadline/query.ex` - records the current ordering-index tradeoff, capture-layer ownership, and anonymous identity semantics.
- `lib/threadline/retention/policy.ex` - states the global window, enablement, cleanup, and no-override contract in present tense.

## Decisions Made

- Kept the manual GUC example because it is a supported escape hatch, but made `Threadline.Audit.transaction/3` the primary public destination for new integrations.
- Described the composite-index opportunity without promising a schedule or hiding that migrations own the index choice.
- Changed prose and comments only; no callback, query expression, policy validation, return value, or exit behavior changed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan's trailing `-x` has no exclusion value and is rejected by the pinned Mix runner. Consistent with earlier Phase 200 plans, each exact path/tag selection was run without only that malformed option; all selections were nonempty and passed.

## Known Stubs

None. The empty/nil comparisons reported by the mechanical scan are established validation and pagination branches, not placeholders or unwired data.

## Threat Flags

None. The plan changes documentation strings and comments only; it adds no endpoint, authorization path, filesystem behavior, schema, dependency, or runtime trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 200-14 can consume both exact core owner projections in the final full-source and unpacked-archive vocabulary gates.
- Plans 200-16 through 200-18 retain independent ownership of the remaining operator infrastructure and LiveView source cohorts.

## Self-Check: PASSED

- All five modified source files and this summary exist.
- Task commits `69d1ab18` and `8310feee` are present after the recorded plan base.
- Both coverage deliverables classify as fully automated and passing.
- The stub and threat-surface scans found no unresolved placeholder or new security boundary.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
