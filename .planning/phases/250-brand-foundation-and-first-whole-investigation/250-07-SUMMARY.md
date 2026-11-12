---
phase: 250-brand-foundation-and-first-whole-investigation
plan: "07"
subsystem: admin
tags: [phoenix-liveview, timeline, row-history, query-filters]
requires:
  - phase: "250-06"
    provides: "Shared operator presentation and mounted loading/error renderer contracts."
provides:
  - "Validated Timeline return context through transaction and row-history navigation."
  - "Explicit unfiltered from= marker preservation and path/query identity separation."
affects: ["Phase 250 Plan 08", "Admin investigation journeys"]
actuals:
  tokens: 22026259
  executor_usage:
    input_tokens: 21897449
    cached_input_tokens: 21457408
    output_tokens: 128810
    reasoning_output_tokens: 84118
  managed_executor_seconds: 2694.987
  tasks: 2
  commits: 5
  plan_head_before: 4ad59ed1549b0cba6c3c7a29c96d9fbb1a7fef64
  plan_head_after: 21d317a7f00e3d70395e54c447b98d9b0f2762b5
tech-stack:
  added: []
  patterns:
    - "Validate retained URI context through existing FilterParams and Query owners."
    - "Keep path identity separate from allowlisted query filters."
key-files:
  created:
    - ".planning/phases/250-brand-foundation-and-first-whole-investigation/deferred-items.md"
  modified:
    - "lib/threadline/operator_surface/live/transaction_live.ex"
    - "lib/threadline/operator_surface/live/timeline_live.ex"
    - "lib/threadline/operator_surface/live/timeline_live/changes.ex"
    - "lib/threadline/operator_surface/live/timeline_live/helpers.ex"
    - "lib/threadline/operator_surface/live/row_history_live.ex"
    - "lib/threadline/operator_surface/live/row_history_component.ex"
    - "test/threadline/operator_surface/transaction_live_test.exs"
    - "test/threadline/operator_surface/live/timeline_live_test.exs"
    - "test/threadline/operator_surface/live/row_history_live_test.exs"
    - "test/threadline/operator_surface/rendered_output_contract_test.exs"
key-decisions:
  - "Reuse FilterParams parsing and Query timeline validation; invalid retained context falls back to direct-entry routes."
  - "Keep route table identity from the row path even when query table filters name another table."
  - "Preserve from= only when the incoming URL explicitly carried an empty from key and the remaining filter set is empty."
  - "Leave phase-wide ADM requirement completion to the parent after the whole-flow proof."
patterns-established:
  - "Timeline links serialize only validated supported raw filters and the existing origin=timeline marker."
  - "Row-history URI filters are decoded separately from route table and record identity."
requirements-completed: []
duration: "45min"
completed: 2026-11-12
status: complete
coverage:
  - id: D1
    description: "Transaction details preserve action, DB transaction, row-change, actor, exact-value, time, and unavailable-state distinctions."
    verification:
      - kind: integration
        ref: "mix verify.test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/ui_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Validated Timeline filters survive transaction and row-history return and snapshot navigation, while invalid context is discarded."
    requirement: "ADM-14"
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/transaction_live_test.exs#Timeline-origin transaction preserves validated filters on return and history links"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/live/row_history_live_test.exs#timeline origin preserves validated filters separately from row identity"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/live/row_history_live_test.exs#invalid timeline filters discard the entire retained context"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/live/row_history_live_test.exs#explicit empty from marker survives row-history as-of changes"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/live/timeline_live_test.exs#explicit empty from marker follows transaction and row-history links"
        status: pass
    human_judgment: false
  - id: D3
    description: "Existing history presentation and full-ID copy contracts remain covered by focused component and copy tests."
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/row_history_component_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/copy_contract_test.exs"
        status: pass
      - kind: integration
        ref: "test/threadline/operator_surface/presentation_test.exs"
        status: pass
    human_judgment: false
---

# Phase 250 Plan 07: Brand foundation and first whole investigation Summary

**Validated Timeline context now survives transaction and row-history navigation, including the explicit unfiltered from= marker.**

## Performance

- **Duration:** Parent will reconcile from the managed process receipt; no worker duration is inferred here.
- **Started:** Parent-managed launch receipt is authoritative.
- **Completed:** 2026-11-12
- **Tasks:** 2
- **Files modified:** 10 task/evidence files (9 source and test files plus the deferred issue note).

## Accomplishments

- Kept transaction action, DB transaction, row-change, actor, exact-value, UTC-time, missing, empty, and unavailable distinctions covered through existing presentation owners.
- Preserved validated supported filters from Timeline through transaction links, breadcrumbs, row-history links, close paths, and selected-snapshot links.
- Kept route table identity separate from a query table filter, rejected invalid origin=timeline context, and preserved an explicit empty from= marker.
- Kept existing presentation and copy checks unchanged; left the rendered-output receipt intact and recorded its pre-existing mismatch.

## TDD Evidence

- **Task 1 RED:** 1fc4eda5 added the Timeline-origin transaction case; it failed on the missing retained query context. **GREEN:** 5da88345 added validated context handling and passed the focused 138-test transaction/presentation/UI suite.
- **Task 2 RED:** ae3ed830 added mounted path/query collision, invalid-context, and empty-marker cases; the 77-test run exposed the expected missing behavior. **GREEN:** 21d317a7 added validation and context serialization; the focused row-history/Timeline suite passed 77 tests.

## Task Commits

1. **Task 1 RED: filtered transaction context test** — 1fc4eda5
2. **Task 1 GREEN: preserve validated Timeline context on transactions** — 5da88345
3. **Task 2 RED: row-history return-context tests** — ae3ed830
4. **Task 2 GREEN: preserve validated row-history return context** — 21d317a7

## Files Created/Modified

- transaction_live.ex and transaction_live_test.exs — validate and retain supported Timeline context through transaction links and history routes.
- timeline_live.ex, timeline_live/changes.ex, and timeline_live/helpers.ex — validate link context, retain explicit from=, and serialize the existing Timeline links.
- row_history_live.ex and row_history_component.ex — decode filters independently from path identity and carry validated state through close/as-of changes.
- timeline_live_test.exs and row_history_live_test.exs — cover supported filters, table-name collision, invalid context, direct entry, and marker behavior.
- deferred-items.md — records the pre-existing rendered-output receipt mismatch for parent triage.

## Decisions Made

- Use the existing filter parser and query validator; do not create a second filter vocabulary or alter public routes.
- Preserve supported raw filter values in canonical order and keep the row table in the path authoritative for row identity.
- Preserve from= only when the original URL carries that empty key and no non-empty filter replaces it.
- Keep phase-wide requirements pending until the parent-owned whole-flow proof is complete.

## Verification

- The accepted check-before materialization guard passed before source edits.
- Task 1 focused verification passed: 138 tests, 0 failures.
- Task 2 focused row-history and Timeline verification passed: 77 tests, 0 failures.
- mix verify.format passed.
- The required Task 2 seven-file mix verify.test command ran 219 tests and had 1 failure in RenderedOutputContractTest: row_history.shell rendered 116 elements with digest 1527bbb72674a8b5e493c2e9242ef257479ccf44412ae3f50698b112cb19bdb6, while the committed receipt expects 118 elements and digest baf2ca11fb3c1a3d0a91a9238bad66472bf7453b30f4a8f50b44c864fb80bac0. All other tests in that invocation passed.
- The Task 1 focused suite was rerun after Task 2 and passed 138 tests, 0 failures.
- A diagnostic rerun of the receipt test with the Task 2 row-history files restored to their pre-task versions reproduced the same 116-element output and failure. The expected receipt was not regenerated.
- Task 2’s initial focused runs exposed two implementation defects: a duplicated origin query key and a marker lost when Timeline reloaded results. Both were corrected before the final 77-test pass.

## Deviations from Plan

None — the planned route owners and existing public query names were retained.

## Issues Encountered

The initial full Task 2 verification failed on a row-history structure receipt already mismatched with pre-task history source. Parent resolved this gate with the causal comparison and narrow current receipt described below; the original failure remains recorded. An initial diagnostic attempt to restore those files was blocked by the local Git metadata permission boundary before any file changed; the files were verified intact, then the diagnostic was run with scoped Git access and the task edits were restored.

No browser keyboard, deferred clipboard, or rendered-overflow proof is claimed here; Plan 08 owns that browser journey.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

The mounted return-context behavior is ready for Plan 08’s whole-browser-flow proof after the parent integrates the committed sources and records the serving-source provenance. Parent causally reconciled the receipt and the combined affected suite now passes. Actual retained-app startup provenance and the whole browser flow remain Plan08 obligations. The current test checkout and parent-served checkout remain distinct; no browser proof was performed from this worktree.

## Self-Check: PASSED

All nine task source/test files, the deferred issue note, and the four task commits are present on this branch. Verification outcomes and the pre-existing receipt mismatch are recorded above.

---
*Phase: 250-brand-foundation-and-first-whole-investigation*
*Completed: 2026-11-12 after parent integration verification.*

## Parent integration reconciliation

The original executor completion label was held pending the failed corpus gate. The parent integrated the committed sources through the declared GSD manifest and corrected the summary to pending before accepting the plan.

The current shell failed the historical receipt. Restoring only the previous header and logo made all seven historical receipts pass; exact current source bytes were then restored. The approved supplied artwork changes the logo from13 elements to9, and the immediate theme controls from7 to9, accounting for the net118→116 shell elements. The current shell digest changed with those approved structures and accessible names. Only the current row_history.shell receipt is new; every historical receipt, the other six current pins, selectors, canonicalizer and mutation negative controls remain intact. This is an attributed migration, not blind regeneration.

On the restored current source, the union of both plan verification commands passed:243 tests,0 failures. Warnings-as-errors compilation, mix verify.format and git diff --check passed. The corpus gate is closed; deferred-items.md retains its original report and resolved disposition. This is scoped integration evidence, not a new full-root or browser result. Independent phase review still inspects the correction in Plan08.

Duration is the actual managed executor span. Usage comes from the executor terminal event: cached input is included in input_tokens and reasoning output is included in output_tokens; neither subset is added twice. Parent reconciliation usage is not available. Phase-wide requirements remain pending and no rendered whole-flow claim is made here.
