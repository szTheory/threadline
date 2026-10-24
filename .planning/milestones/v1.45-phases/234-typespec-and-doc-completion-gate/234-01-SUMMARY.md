---
phase: 234-typespec-and-doc-completion-gate
plan: 01
subsystem: testing
tags: [elixir, ex_doc, typespecs, credo, dialyzer]
requires: []
provides:
  - Exact documentation/spec coverage and hidden-entry ratchets for the public BEAM docs universe
  - Reusable test-only typespec, option-parity, and Markdown contract walkers
  - A frozen binary documentation and typespec review rubric for plans 234-02 through 234-06
affects: [234-02, 234-03, 234-04, 234-05, 234-06, SPEC-01, SPEC-02, SPEC-03]
actuals:
  tokens: 21752
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns:
    - Pure test helpers inspect Code.fetch_docs and Code.Typespec output without runtime dependencies
    - Exact measured ratchets fail when findings are added or removed unexpectedly
key-files:
  created:
    - test/threadline/doc_rubric_contract_test.exs
    - .planning/phases/234-typespec-and-doc-completion-gate/234-SPEC-RUBRIC.md
  modified:
    - test/support/doc_contract.ex
    - test/threadline/doc_spec_coverage_contract_test.exs
    - test/threadline/facade_naming_contract_test.exs
    - test/threadline/dialyzer_ignore_contract_test.exs
    - test/partition_weights.txt
    - guides/integration-contracts.md
key-decisions:
  - "The measured current surface has 52 documented modules, 92 visible function/macro entries, and 74 gaps: 53 missing specs, 6 missing docs, and 15 missing typedocs."
  - "The existing explicitly hidden helper set has 23 entries, correcting the plan's 22-entry estimate; the eight D-07 transitional entries make the hidden pin 31."
  - "The visible-doc M4 scanner measures two deprecated references under the plan's metadata and visibility rules, despite the context note's hand-count of ten."
  - "The permanent Page allowance is Threadline.Page.t/0; its parameterized t/1 is a separate public type."
requirements-completed: [SPEC-01, SPEC-02, SPEC-03]
coverage:
  - id: D1
    description: "Doc/spec coverage checker, exact gap baseline, hidden pin, and vacuity sentinels"
    requirement: SPEC-01
    verification:
      - kind: unit
        ref: test/threadline/doc_spec_coverage_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: "Option parity, M2/M4/M6/M7/M8, broad-type, and hidden/private-type ratchets"
    requirement: SPEC-02
    verification:
      - kind: unit
        ref: test/threadline/doc_rubric_contract_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: "Facade group and Dialyzer suppression contracts"
    requirement: SPEC-03
    verification:
      - kind: unit
        ref: test/threadline/facade_naming_contract_test.exs
        status: pass
      - kind: unit
        ref: test/threadline/dialyzer_ignore_contract_test.exs
        status: pass
    human_judgment: false
  - id: D4
    description: "Frozen binary rubric covers R1-R5 and the D/S/M review checklist"
    verification:
      - kind: other
        ref: "rubric ID, username, and partition-weight shell contract"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D5
    description: "The docs build no longer references a hidden query-scope helper"
    verification:
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 3h 7m
completed: 2026-10-04
status: complete
---

# Phase 234 Plan 01: Coverage Gates and Frozen Rubric Summary

**SPEC-01/02/03 now have exact baseline gates and a frozen documentation rubric before any public typespec or doc rewrites.**

## Performance

- **Duration:** 3h 7m
- **Started:** 2026-10-04T16:21:40Z
- **Completed:** 2026-10-04T19:28:17Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added the docs-entry coverage checker and pinned its measured universe: 52 modules, 92 visible functions/macros, and 74 gaps (53 missing specs, 6 missing docs, 15 missing typedocs). The six missing-doc findings overlap the missing-spec set, leaving 54 distinct function entries with a gap.
- Pinned the 23 currently hidden helpers and the eight D-07 transitions, all 23 facade group assignments, the 24 option-parity findings, and the Dialyzer ignore contracts.
- Added pure fixture-tested walkers for option types, named type keys, broad types, first paragraphs, and code stripping; pinned 21 M2 findings, 2 M4 references, 1 M6 voice finding, 7 `since` entries, 6 M8 code-block failures, and 42 broad-type findings. The three permanent allowances are ActorRef.identifiable?/1, Storage.options/0, and Page.t/0.
- Committed `234-SPEC-RUBRIC.md` before changing public specs or docs. Updated the integration guide's hidden-helper link so ExDoc builds with warnings as errors.

## Task Commits

1. **Task 1: Coverage checker and gap ratchet** — `185e15a8` (test), `a85b027d` (implementation)
2. **Task 2: Hidden, facade-group, and Dialyzer ratchets** — `a2799361` (test), `ac7024d6` (implementation)
3. **Task 3: Rubric analyzers and frozen standard** — `07320d53` (test), `dcbdff91` (implementation and rubric)

**Plan metadata:** committed with the GSD summary/state update.

## Files Created/Modified

- `test/support/doc_contract.ex` — test-only coverage, docs, options, and typespec walkers.
- `test/threadline/doc_spec_coverage_contract_test.exs` — exact gap and hidden-entry gates.
- `test/threadline/doc_rubric_contract_test.exs` — option, prose, example, broad-type, and private-reference ratchets.
- `test/threadline/facade_naming_contract_test.exs` — facade group map and mutation control.
- `test/threadline/dialyzer_ignore_contract_test.exs` — no inline suppressions or `:no_*` flags.
- `test/partition_weights.txt` — weight for the new rubric contract suite.
- `.planning/phases/234-typespec-and-doc-completion-gate/234-SPEC-RUBRIC.md` — frozen review standard.
- `guides/integration-contracts.md` — removed an ExDoc link to a hidden helper.

## Decisions Made

- The exact visible-doc scanner is the source of truth for M4 ratchets: it resolves deprecated entries from docs metadata, scans visible docs and moduledocs, and exempts the facade moduledoc plus deprecated entries' own docs.
- `Page.t/0` is the permanent broad-type exception; the generic `Page.t(entry)` definition is a distinct arity and remains outside that allowance.

## Deviations from Plan

### Auto-fixed Issues

**1. Corrected the hidden-helper baseline from 22 to 23.**
- **Found during:** Task 2
- **Issue:** The plan's stated count did not match the exact enumerated hidden set.
- **Fix:** Pinned all 23 current helpers plus the eight transitional entries.
- **Files modified:** `test/threadline/doc_spec_coverage_contract_test.exs`, `test/threadline/facade_naming_contract_test.exs`
- **Verification:** Hidden-entry and facade ratchets pass.
- **Committed in:** `ac7024d6`

**2. Removed a stale link to a hidden internal helper.**
- **Found during:** Plan-level docs build
- **Issue:** `mix docs --warnings-as-errors` warned that `Threadline.Query.Scope.apply/2` is hidden.
- **Fix:** Rephrased the guide sentence in adopter-facing terms.
- **Files modified:** `guides/integration-contracts.md`
- **Verification:** `MIX_ENV=dev mix docs --warnings-as-errors` passes.
- **Committed in:** `dcbdff91`

**3. The context's manual M4 estimate differs from the exact scanner output.**
- **Found during:** Task 3
- **Issue:** The context says ten hits; the specified scanner, using visible docs and `:deprecated` metadata, measures two: `Threadline.as_of/4` and the Continuity moduledoc.
- **Fix:** Pinned the scanner's exact measured result; the frozen rubric retains the context's examples for the exhaustive review.
- **Files modified:** `test/threadline/doc_rubric_contract_test.exs`, `234-SPEC-RUBRIC.md`
- **Verification:** M4 ratchet passes.
- **Committed in:** `dcbdff91`

**Total deviations:** 3 auto-fixed (2 baseline corrections, 1 docs-build fix)
**Impact on plan:** The gates remain test-only and no `lib/` files changed. The docs wording fix removes a hidden ExDoc reference needed for the plan's docs gate.

## Issues Encountered

- The first `Code.compile_string/1` fixture did not retain a Docs chunk in the test process. Setting and restoring compiler options for docs and debug info made the fixture reflect the compiled BEAM.
- Credo initially flagged nested analyzer logic and one facade helper. The checks were split into focused helpers; the final strict Credo run reports no issues.

## User Setup Required

None.

## Next Phase Readiness

Ready for `234-02-PLAN.md`; its public type and documentation work can now consume the frozen rubric and exact ratchets.

---
*Phase: 234-typespec-and-doc-completion-gate*
*Completed: 2026-10-04*
