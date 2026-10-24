---
phase: 235-stability-contract-and-adopter-guides
plan: 02
subsystem: documentation
tags: [elixir, postgres, exdoc, adopter-guides, contract-tests]

# Dependency graph
requires:
  - phase: 235-01
    provides: generated trigger migration guard and redaction guide conventions
  - phase: 234
    provides: settled option typespec and 1.x compatibility policy
provides:
  - Claim-tested 1.x stability guide
  - Before-install PostgreSQL table eligibility matrix
  - ExDoc Adopt lane registration and guide graph contracts
affects: [235-03, 235-04, 235-05, adopter-documentation]

# Actuals (#2632), chars/4 over the realized implementation diff.
actuals:
  tokens: 3911
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Named required-claim contracts with a deletion mutation control
    - Evidence-attributed adopter matrix rows tied to implementation and tests

key-files:
  created:
    - guides/stability.md
    - guides/supported-tables.md
    - test/threadline/guides/stability_contract_test.exs
    - test/threadline/guides/table_shapes_contract_test.exs
  modified:
    - mix.exs
    - test/threadline/guide_graph_contract_test.exs
    - guides/getting-started-saas.md

key-decisions:
  - "Pin the settled 1.x API, database, operator-surface, and backport claims in a focused contract."
  - "State table eligibility with its full prerequisites and operational caveat in one pre-install matrix."

patterns-established:
  - "Adopter claims name the implementation or test evidence beside the condition."
  - "New Adopt guides are explicit ExDoc extras, assigned to one lane, and linked from the Adopt landing."

requirements-completed: [CONTRACT-01, DOCS-01]
coverage:
  - id: D1
    description: "1.x stability promises are published and deletion-tested."
    requirement: CONTRACT-01
    verification:
      - kind: unit
        ref: "test/threadline/guides/stability_contract_test.exs"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Table-shape eligibility, conditions, and caveats are published and contract-tested."
    requirement: DOCS-01
    verification:
      - kind: unit
        ref: "test/threadline/guides/table_shapes_contract_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/guide_graph_contract_test.exs"
        status: pass
    human_judgment: false

plan_head_before: ce4b0f8c
plan_head_after: 686afe1431545669e4560f80a828ff7841faaf83
commits: 2
duration: 7min
completed: 2026-10-06
status: complete
---

# Phase 235 Plan 02: Stability Contract and Adopter Guides Summary

The Adopt lane now publishes a contract-tested 1.x stability policy and a pre-install matrix covering PostgreSQL table eligibility, key prerequisites, and operational caveats.

## Performance

- **Duration:** 7 minutes
- **Started:** 2026-10-07T00:41:44Z
- **Completed:** 2026-10-07T00:48:36Z
- **Tasks:** 2
- **Files modified or created:** 7 implementation and contract files

## Accomplishments

- Published the 1.x API, database, operator-surface, option-type, and 0.12.x backport promises, with a named claim contract and removal mutation control.
- Published a before-install matrix for key types and overrides, schema-qualified tables, identifiers, `char(n)`, partitioned and unlogged tables, and unsupported views.
- Registered both guides in ExDoc's Adopt lane and expanded the guide-graph contract and landing links.

## Task Commits

1. **Task 1: State the exact 1.x upgrade promise and pin its claims** - `922758ef` (feat)
2. **Task 2: Give adopters a tested table-shape eligibility matrix** - `686afe14` (feat)

**Measured plan commits:** 2 (`ce4b0f8c` to `686afe1431545669e4560f80a828ff7841faaf83`).

## Verification

- Task 1: `mix verify.test test/threadline/guides/stability_contract_test.exs test/threadline/guide_graph_contract_test.exs` — passed, 11 tests, 0 failures.
- Task 1: `mix verify.format` — passed.
- Task 2: `mix verify.test test/threadline/guides/table_shapes_contract_test.exs test/threadline/guide_graph_contract_test.exs` — passed, 12 tests, 0 failures.
- Task 2: `mix verify.format` — passed.
- Task 2: `MIX_ENV=dev mix docs --warnings-as-errors` — passed; ExDoc generated HTML, Markdown, and EPUB docs without warnings.

## Files Created/Modified

- `guides/stability.md` — adopter-facing 1.x compatibility policy.
- `guides/supported-tables.md` — table-shape install eligibility and caveats.
- `test/threadline/guides/stability_contract_test.exs` — named stability claims and mutation control.
- `test/threadline/guides/table_shapes_contract_test.exs` — matrix claims, implementation conditions, evidence, and mutation control.
- `mix.exs` — ExDoc extras and Adopt lane registration.
- `test/threadline/guide_graph_contract_test.exs` — exact guide graph registration.
- `guides/getting-started-saas.md` — routes adopters to both new guides.

## Decisions Made

- Kept the settled 1.x compatibility policy intact and pinned each required promise in a narrow claim contract.
- Put each supported table shape's status, required conditions, and caveat/evidence together in one matrix.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Routed the new guides from the Adopt landing**
- **Found during:** Task 1 and Task 2 guide-graph verification
- **Issue:** The graph contract requires each Adopt guide to be linked from Getting Started; registering the guides alone left the published guide graph incomplete.
- **Fix:** Added links to both guides in `guides/getting-started-saas.md`.
- **Files modified:** `guides/getting-started-saas.md`
- **Verification:** `mix verify.test test/threadline/guides/table_shapes_contract_test.exs test/threadline/guide_graph_contract_test.exs` passed.
- **Committed in:** `922758ef` and `686afe14` (one link per task)

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** Required routing completed ExDoc's existing Adopt graph contract; no dependency or runtime behavior changed.

## Issues Encountered

- The first Task 1 verification exposed source-line-sensitive assertion wording and Markdown links to non-guide source files. The contract was changed to assert semantic claim fragments, and implementation/test evidence is named by repository path. The final focused contract passed.
- The sandbox initially denied Git index writes; the two requested normal commits were created after the repository metadata write was approved by the sandbox reviewer. Hooks were not bypassed.

## User Setup Required

None.

## Next Phase Readiness

Phase 235 Plan 03 can build on the stable API and adopter-facing table-shape contracts. The two guides and graph registration are in place.

---
*Phase: 235-stability-contract-and-adopter-guides*
*Completed: 2026-10-06*

## Self-Check: PASSED

- Summary file exists.
- Task commits `922758ef` and `686afe14` are ancestors of `HEAD`.
- Final combined guide and graph contracts passed (14 tests, 0 failures).
