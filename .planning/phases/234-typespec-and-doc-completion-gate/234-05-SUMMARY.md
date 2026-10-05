---
phase: 234-typespec-and-doc-completion-gate
plan: 05
subsystem: api
tags: [elixir, typespecs, ex_doc, dialyzer]
requires:
  - phase: 234-01
    provides: Exact documentation/specification coverage ratchets and the frozen rubric
  - phase: 234-02
    provides: Facade contracts that reference the schema and result types
  - phase: 234-04
    provides: Named types and documentation across export and operations APIs
provides:
  - Precise field types for ActorRef, capture and semantics schemas, investigation results, Page, NotFoundError, and Health.Finding
  - A generic result spec and named option types for Audit.transaction/3
  - Updated documentation/type ratchets with only the two unrelated gaps left pinned
affects: [234-06, 235, SPEC-01, SPEC-02]
actuals:
  tokens: 6224
  tasks: 3
  commits: 6
  plan_head_before: 4c6fcff23f2d91cb2032bdb47155a61cae9678d8
  plan_head_after: d16c27536c2e88cc9f00a83aaf5b56379bb0576f
tech-stack:
  added: []
  patterns:
    - Hand-written complete struct types preserve precise field contracts without adding a schema-generation dependency
    - R1/R2 opaque-input allowances are named in the permanent bare-type rubric
key-files:
  created: []
  modified:
    - lib/threadline/audit.ex
    - lib/threadline/capture/audit_change.ex
    - lib/threadline/capture/audit_transaction.ex
    - lib/threadline/health/finding.ex
    - lib/threadline/investigation/incident_bundle.ex
    - lib/threadline/investigation/linked_change.ex
    - lib/threadline/not_found_error.ex
    - lib/threadline/page.ex
    - lib/threadline/semantics/actor_ref.ex
    - lib/threadline/semantics/audit_action.ex
    - lib/threadline/semantics/audit_context.ex
    - test/threadline/doc_rubric_contract_test.exs
    - test/threadline/doc_spec_coverage_contract_test.exs
key-decisions:
  - "ActorRef.from_map/1 remains an R2 arbitrary-input validator; its term() boundary is documented and pinned."
  - "Audit.transaction/3 keeps callback results and caller-owned rollback reasons opaque under R1."
  - "This plan adds no field-stability promise; Phase 235 owns stability and may only add fields to t."
requirements-completed: [SPEC-01, SPEC-02]
coverage:
  - id: D1
    description: ActorRef helpers and capture/semantics schema types have precise field contracts.
    requirement: SPEC-01
    verification:
      - kind: unit
        ref: "mix test test/threadline/semantics/actor_ref_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs"
        status: pass
      - kind: other
        ref: "mix verify.dialyzer"
        status: pass
    human_judgment: false
  - id: D2
    description: Page, NotFoundError, Investigation, and Health.Finding expose precise result types; Audit.transaction/3 is generic over its result.
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: "mix test test/threadline/page_test.exs test/threadline/not_found_error_test.exs test/threadline/health_findings_doc_contract_test.exs test/threadline/audit_doc_contract_test.exs test/threadline/health_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs"
        status: pass
      - kind: other
        ref: "mix verify.dialyzer"
        status: pass
    human_judgment: false
  - id: D3
    description: Domain-language module/type documentation, the corrected actor cursor description, and the Audit.transaction/3 example are published without ExDoc warnings.
    verification:
      - kind: unit
        ref: "mix test test/threadline/page_test.exs test/threadline/not_found_error_test.exs test/threadline/health_findings_doc_contract_test.exs test/threadline/audit_doc_contract_test.exs test/threadline/health_test.exs test/threadline/doc_spec_coverage_contract_test.exs test/threadline/doc_rubric_contract_test.exs"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: true
    rationale: Tests and ExDoc validate documented contracts and structure; human review is still needed to judge whether the prose is clear to library adopters.
duration: 31min
completed: 2026-10-04
status: complete
---

# Phase 234 Plan 05: Typespec and Doc Completion Gate Summary

**Complete field-level types across capture, semantics, investigation, and health structs, plus generic Audit.transaction/3 options and result contract.**

## Performance

- **Duration:** 31 min, measured from the first task commit; initial plan loading and worktree dependency setup preceded that timestamp.
- **Started:** 2026-10-04T22:13:45-04:00 (first task commit)
- **Completed:** 2026-10-04T22:44:49-04:00
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Added precise ActorRef types and specs for its JSON helpers; facade specs that reference ActorRef.t() remain Dialyzer-green.
- Typed every capture/semantics schema field and the investigation, paging, not-found, and health result structs.
- Replaced Audit.transaction/3's broad keyword options and term callback with named option types and a generic result variable; corrected the actor cursor docs and removed the stale Health.Finding function pointer.

## Task Commits

Each task was committed atomically; TDD tasks have separate failing-test and implementation commits.

1. **Task 1: ActorRef precise type and helper specs** — test `ca2e3e1`; implementation `86ee8d6`
2. **Task 2: Capture and semantics schema field types** — test `1dbb51e`; implementation `1f842bf`
3. **Task 3: Result structs and Audit.transaction/3** — test `8a08ece`; implementation `d16c275`

**Plan metadata:** This SUMMARY is committed separately; its commit hash is recorded in the execution report.

## Files Created/Modified

- `lib/threadline/semantics/actor_ref.ex` — actor type, precise struct shape, JSON map type, and helper specs/docs.
- `lib/threadline/capture/audit_change.ex`, `lib/threadline/capture/audit_transaction.ex` — complete capture schema field types.
- `lib/threadline/semantics/audit_action.ex`, `lib/threadline/semantics/audit_context.ex` — typed semantic action and context fields.
- `lib/threadline/page.ex`, `lib/threadline/not_found_error.ex` — precise paging cursor/error contracts.
- `lib/threadline/investigation/linked_change.ex`, `lib/threadline/investigation/incident_bundle.ex` — typed linked and bundled investigation results.
- `lib/threadline/health/finding.ex` — finite code/severity and JSON details types; domain-language opening.
- `lib/threadline/audit.ex` — named options, generic transaction result, and an indented usage example.
- `test/threadline/doc_spec_coverage_contract_test.exs`, `test/threadline/doc_rubric_contract_test.exs` — removed completed gaps from the ratchets and recorded the intentional R1/R2 boundaries.

## Decisions Made

- Kept `ActorRef.from_map/1` broad at its input boundary because it validates arbitrary caller input (R2).
- Kept Audit.transaction/3 callback output and caller-owned rollback reasons opaque; its new option types describe accepted values without widening the public result contract.
- Followed D-50: Phase 235 may add fields to these types, and this plan makes no field-stability promise.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Cleared a Credo warning in the updated coverage contract**
- **Found during:** Task 3 verification
- **Issue:** The required Credo run flagged `Enum.count/2` in the changed gap assertions.
- **Fix:** Replaced the count checks with `Enum.any?/2` and `Enum.all?/2`, retaining the same assertions.
- **Files modified:** `test/threadline/doc_spec_coverage_contract_test.exs`
- **Verification:** `mix verify.credo` passed with no issues; focused and plan-level test suites passed.
- **Committed in:** `d16c275`

**Total deviations:** 1 auto-fixed (Rule 3 - Blocking).
**Impact on plan:** One focused lint correction; no scope or public behavior change.

## Issues Encountered

- The ExUnit RED run correctly failed on the planned assertion, but `gsd_run check tdd-red-evidence` classified it as `INVALID_RED zero_tests_discovered`; that helper did not recognize this ExUnit output. The assertion failure was confirmed directly before implementing the fix.
- The fresh worktree had no dependencies or Dialyzer PLT. Hex could not write its default cache, so dependencies and the example app were run with `HEX_HOME=/tmp/threadline-hex-234-05`; the local Dialyzer PLT was built in the worktree. No dependency versions changed.
- An overlapping initial `mix verify.example` invocation hit a PostgreSQL deadlock and connection limit. The isolated rerun passed: 130 tests, 0 failures.

## Verification

- Focused ActorRef tests: 34 tests, 0 failures.
- Capture/semantics boundary and schema tests: 45 tests, 0 failures.
- Result/documentation tests and plan-level suite: 60 tests, 0 failures.
- `mix compile --warnings-as-errors`: passed.
- `mix verify.dialyzer`: passed, 0 errors.
- `MIX_ENV=dev mix docs --warnings-as-errors`: passed without warnings.
- `mix verify.credo`: passed with no issues.
- `HEX_HOME=/tmp/threadline-hex-234-05 mix verify.example`: passed, 130 tests, 0 failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 234-05 is complete; plan 234-06 can continue the remaining documentation gate work.
- Phase 235 can use these types as the current field set and may add fields; no cross-release stability contract was introduced.
- No changes were made to STATE.md or ROADMAP.md; the orchestrator retains those updates.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-04*

## Self-Check: PASSED

- Summary and all 13 key files exist.
- All six task commits are present.
- STATE.md and ROADMAP.md are unchanged.
