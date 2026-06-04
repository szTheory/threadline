---
phase: 138-find-cluster-polish
plan: "02"
subsystem: operator-surface-ui
tags: [operator-surface, transaction, row-history, presentation, liveview, tdd]

requires:
  - phase: 138-find-cluster-polish
    plan: "01"
    provides: shared Find value-token helpers and CSS primitives
provides:
  - Transaction diff rendering with semantic value tokens and INSERT data_after fallback rows
  - Verifiable Transaction and correlation refs with full titles and enabled copy affordances
  - Row-history snapshot rendering with shared value tokens while preserving sorted key/value rows
affects: [transaction, row-history, find-cluster]

tech-stack:
  added: []
  patterns: [Phoenix LiveView HEEx value-token rendering, local diff normalization, scoped component tests]

key-files:
  created:
    - .planning/phases/138-find-cluster-polish/138-02-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/row_history_component_test.exs

key-decisions:
  - "Transaction INSERT fallback derives fields only from already-loaded change_diff data_after maps."
  - "Transaction and Row-history render Presentation value-token maps through HEEx interpolation, not raw HTML."
  - "Row-history remains a sorted key/value snapshot and does not adopt transaction before/after arrows."

patterns-established:
  - "TransactionLive.normalized_fields/1 is a local presentation-only fallback for empty INSERT field_changes."
  - "RowHistoryComponent.snapshot_rows/1 returns {key, Presentation.value_token(value)} tuples for template rendering."

requirements-completed: [POLISH-FIND]

duration: 12min
completed: 2026-06-04
---

# Phase 138 Plan 02: Transaction and Row-History Value Rendering Summary

**Transaction diffs and Row-history snapshots now share the Find value vocabulary for nulls, redactions, timestamps, strings, and verifiable refs.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-04T08:55:00Z
- **Completed:** 2026-06-04T09:06:42Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Transaction detail pages now render INSERT rows from loaded `data_after` when `field_changes` is empty, avoiding blank diff panels when captured row data exists.
- UPDATE diffs now use explicit before/after value tokens with `.tl-diff__arrow`, semantic `null`, redacted labels, and timestamp titles.
- Transaction and correlation identifiers use `Presentation.secondary_ref/2`, full `title`, `[data-tl-copy]`, and enabled secondary copy-button styling.
- Row-history snapshots now render sorted key/value rows with `Presentation.value_token/1`, so nil, timestamps, redacted strings, and escaped user strings match Transaction semantics without before/after arrows.

## Task Commits

1. **Task 1 RED: Add failing Transaction value-rendering tests** - `b8ad46c` (test)
2. **Task 1 GREEN: Render Transaction diffs with semantic values** - `1f02175` (feat)
3. **Task 2 RED: Add failing Row-history value-token tests** - `1aa10ef` (test)
4. **Task 2 GREEN: Render Row-history snapshots with value tokens** - `fed7438` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/live/transaction_live.ex` - Uses secondary refs/copy controls, local field normalization, and `Presentation.change_value_token/2` rendering.
- `lib/threadline/operator_surface/live/row_history_component.ex` - Uses `Presentation.value_token/1` for sorted snapshot rows.
- `test/threadline/operator_surface/transaction_live_test.exs` - Covers F-201(render), F-701, F-702, and F-705 behavior.
- `test/threadline/operator_surface/row_history_component_test.exs` - Covers F-706 value tokens, HTML escaping, no diff arrows, and scoped row-history behavior.
- `.planning/phases/138-find-cluster-polish/138-02-SUMMARY.md` - Captures execution results.

## Decisions Made

- Kept INSERT fallback local to `TransactionLive` and derived only from already-loaded `change.change_diff["data_after"]`; no query, schema, route, or public API changes.
- Kept Row-history as sorted key/value rows; it consumes the same value tokens but does not render transaction-style arrows.
- Preserved existing `scope`, `scope_query_fn`, `surface: :transaction`, Transaction history patch params, and Row-history `Threadline.history/3` / `Threadline.as_of/4` calls.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first RED fixture for `AuditAction` omitted required actor/status fields and used the wrong `ActorRef` input shape. Fixed before the RED commit so test failure evidence reflected missing UI behavior, not invalid setup.
- Two RED commands were initially run in parallel and shared the same test database. Subsequent verification was run sequentially to avoid cross-process test-data interference.

## Known Stubs

None. Stub scan only found legitimate empty-list comparisons, nil handling, and existing fallback helpers; no placeholder UI or unwired data sources were introduced.

## Threat Flags

None - no new endpoints, auth paths, file access, schema changes, or network surfaces were introduced.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/presentation_test.exs` - 25 tests, 0 failures
- `mix test test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/transaction_live_test.exs` - 14 tests, 0 failures
- `mix test test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/row_history_component_test.exs test/threadline/operator_surface/presentation_test.exs` - 28 tests, 0 failures
- `rg -n "inspect\\(field\\[\\\"before\\\"\\]\\)|inspect\\(field\\[\\\"after\\\"\\]\\)" lib/threadline/operator_surface/live/transaction_live.ex || true` - no raw field-value inspect calls found
- `rg -n "inspect\\(value\\)" lib/threadline/operator_surface/live/row_history_component.ex || true` - no snapshot value inspect calls found
- `rg -n "Threadline\\.history\\(|Threadline\\.as_of\\(|scope_query_fn" lib/threadline/operator_surface/live/row_history_component.ex` - scoped history/as-of seams still present
- `git diff --check -- lib/threadline/operator_surface/live/transaction_live.ex lib/threadline/operator_surface/live/row_history_component.ex test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/row_history_component_test.exs` - clean

## TDD Gate Compliance

- RED Transaction test commit exists before implementation: `b8ad46c`
- GREEN Transaction implementation commit follows it: `1f02175`
- RED Row-history test commit exists before implementation: `1aa10ef`
- GREEN Row-history implementation commit follows it: `fed7438`

## Next Phase Readiness

Plans 03 and 04 can rely on `Presentation.value_token/1`, `Presentation.change_value_token/2`, and `Presentation.secondary_ref/2` being actively consumed by Find-cluster surfaces. Orchestrator-owned `.planning/STATE.md` and `.planning/ROADMAP.md` were intentionally not modified in this delegated run.

## Self-Check: PASSED

- Key files exist on disk.
- Commits `b8ad46c`, `1f02175`, `1aa10ef`, and `fed7438` exist in git history.
- Final focused verification passed with 28 tests, 0 failures.

---
*Phase: 138-find-cluster-polish*
*Completed: 2026-06-04*
