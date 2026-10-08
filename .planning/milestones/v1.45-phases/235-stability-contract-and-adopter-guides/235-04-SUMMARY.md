---
phase: 235-stability-contract-and-adopter-guides
plan: 04
subsystem: testing
tags: [elixir, postgres, public-contract, export, mix-tasks, phoenix]

requires:
  - phase: 235-01
    provides: Stability and redaction contract context for the public-set assertions.
provides:
  - Literal CSV/JSON export and Health.Finding code contract tests.
  - Literal Threadline Mix-task flags and operator mount option/route contracts.
affects: [235-05, 236-support-floor-and-partition-weights]

actuals:
  tokens: 4115.5
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 3f06f05e1b5e400cd80ea442ecb6eb3525b8bf57
plan_head_after: ccf2e4681df06835838ad1c396b17232c2fd34ff

tech-stack:
  added: []
  patterns:
    - Observe public export functions with named PostgreSQL fixtures and compare outputs to literal key pins.
    - Compare implementation-discovered public sets with literal pins and actionable added/removed diffs.

key-files:
  created:
    - test/threadline/export_public_contract_test.exs
    - test/threadline/public_options_contract_test.exs
  modified: []

key-decisions:
  - "Pin JSON action metadata by observed linked-action presence; JSON has no include_action_metadata option, while CSV appends its two metadata columns only when requested."
  - "Treat the operator macro's LiveView route identity separately from its sibling HTTP routes and pin documented adopter paths alongside the full mounted route set."

patterns-established:
  - "Contract diffs report added and removed members by name so review can identify the exact public-set drift."

requirements-completed: [CONTRACT-04]
coverage:
  - id: D1
    description: "CSV and JSON export keys, optional action metadata, and all Health.Finding codes are pinned against observed outputs and producer paths."
    requirement: CONTRACT-04
    verification:
      - kind: integration
        ref: "mix verify.test test/threadline/export_public_contract_test.exs"
        status: pass
      - kind: unit
        ref: "mix verify.format"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every shipped Threadline Mix task's accepted flags and operator mount options/routes have explicit literal pins and mutation controls."
    requirement: CONTRACT-04
    verification:
      - kind: unit
        ref: "mix verify.test test/threadline/public_options_contract_test.exs"
        status: pass
      - kind: unit
        ref: "mix verify.format"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-10-07
status: complete
---

# Phase 235 Plan 04: Export and Operator Public-Set Contracts Summary

**Observed CSV/JSON export shapes, Health.Finding codes, all Threadline Mix-task flags, and operator mount options/routes are pinned by focused literal contracts.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-10-07T00:56:02Z
- **Completed:** 2026-10-07T00:59:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added named database fixtures that observe CSV headers in order, JSON key sets, no-action omission, linked-action metadata, and CSV's optional metadata columns.
- Pinned all six Finding code producers and included deliberate removed/added member controls with attributable diffs.
- Pinned all 12 shipped Threadline Mix tasks, including the task with no Threadline-owned flags, and compared strict flags and aliases with literal maps.
- Pinned macro options, all mounted LiveView and HTTP route templates, documented adopter routes, and removed/added route mutation controls.

## Task Commits

1. **Task 1: Pin exported headers and health finding codes** - `1bfd52f0` (test)
2. **Task 2: Pin every Threadline Mix-task flag and operator mount surface** - `ccf2e468` (test)

## Files Created/Modified

- `test/threadline/export_public_contract_test.exs` - Observed export contracts and literal Finding code set.
- `test/threadline/public_options_contract_test.exs` - Literal task flag, router option, and route-template contracts.

## Decisions Made

- JSON action keys are present when a row is linked to an AuditAction and absent when it is not; `include_action_metadata` controls CSV columns only.
- Route identity pins distinguish LiveView routes from HTTP methods and preserve route templates instead of incidental source order.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first export test attempt passed `include_action_metadata` to `to_json_document/2`, which correctly rejects that option. The contract was corrected to observe the JSON action object from a linked AuditAction fixture; CSV retains the explicit option toggle.
- The first route-contract run labeled LiveView declarations as `GET`; the literal route identities were corrected to `LIVE` to match the router macro declarations.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 235-05 can add stable Ecto-field subsets and additive captured-data contracts. The full focused 235-04 contract run and formatting gate pass.

---
*Phase: 235-stability-contract-and-adopter-guides*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Both contract test files and this summary exist.
- Task commits `1bfd52f0` and `ccf2e468` are ancestors of HEAD.
- Stub scan found no placeholders or unfinished contract fixtures.
