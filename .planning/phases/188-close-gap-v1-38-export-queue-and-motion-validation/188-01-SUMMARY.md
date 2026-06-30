---
phase: 188-close-gap-v1-38-export-queue-and-motion-validation
plan: 01
plan_id: 188-01
title: Queued Export Replay Parser Closure
subsystem: export-worker-replay
tags:
  - exports
  - timeline
  - export-queue
  - filter-parser
  - operator-surface
requires:
  - phase: 184-timeline-investigation-flow
    provides: Timeline current-view export and canonical URL-backed filter handoff.
  - phase: 186-detail-governance-and-export-surfaces
    provides: Export Status failed-row treatment, download links, and queue affordance labels.
  - phase: 187-accessibility-motion-docs-and-adversarial-closeout
    provides: Keyboard/focus export-flow proof that exposed the queued replay completion gap.
provides:
  - Queued export worker replay now parses persisted string-keyed query_params through FilterParams.parse/1.
  - Persisted from/to datetime-local strings become DateTime filters before Threadline.Query receives them.
  - Invalid persisted datetime params fail closed with parser-derived error detail in the existing failed export row.
  - Worker source no longer creates atoms from persisted query_params.
affects:
  - TIME-01
  - GOV-02
  - A11Y-02
  - Phase 188 closeout
tech-stack:
  added: []
  patterns:
    - Reuse the operator-surface canonical URL filter parser at worker replay boundaries.
    - Preserve URL-shaped persisted job params and parse only at execution time.
key-files:
  created:
    - .planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-01-SUMMARY.md
  modified:
    - lib/threadline/export/orchestrator.ex
    - test/threadline/export/orchestrator_test.exs
    - test/threadline/operator_surface/live/export_status_live_test.exs
key-decisions:
  - "Threadline.Export.Orchestrator calls Threadline.OperatorSurface.Exports.FilterParams.parse/1 directly rather than adding a second queued-export parser."
  - "Invalid persisted query_params raise ArgumentError with parser detail and reuse the existing Orchestrator failure path that records ExportJob.error_message."
  - "ExportJob.query_params remains URL-shaped and string-keyed so Reopen source search links and existing queued job shape stay stable."
patterns-established:
  - "Worker replay tests seed inside/outside AuditChange rows and assert stored CSV contents through the public Orchestrator.run/2 boundary."
  - "Source-level atom-safety proof scans the worker source for unsafe String.to_atom/1."
requirements-completed:
  - TIME-01
  - GOV-02
  - A11Y-02
duration: 5min
completed: 2026-06-30T20:25:24Z
status: complete
---

# Phase 188 Plan 01: Queued Export Replay Parser Closure Summary

Queued Timeline export replay now uses the canonical URL filter parser, preserving string-keyed jobs while enforcing date windows and fail-closed invalid params.

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-30T20:20:35Z
- **Completed:** 2026-06-30T20:25:24Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added RED worker replay tests for persisted string `from`/`to` params, invalid persisted datetime failure detail, and worker atom-safety.
- Preserved the existing `Queue Timeline export` job shape proof with string-keyed URL params.
- Added failed-row proof that parser-derived error detail renders with `Export failed.` and `Reopen source search`.
- Replaced worker-side `String.to_atom/1` atomization with `FilterParams.parse/1`, keeping invalid params fail-closed through the existing job failure path.

## Task Commits

| Task | Name | Result | Commit |
|------|------|--------|--------|
| 1 | Add queued replay regression tests first | RED tests committed; `mix test test/threadline/export/orchestrator_test.exs` failed as expected with 3 failures | 56839e11 |
| 2 | Parse persisted worker params through the canonical filter parser | Worker replay fixed and targeted bundle green | 506f99eb |

## Files Created/Modified

- `lib/threadline/export/orchestrator.ex` - Parses persisted `ExportJob.query_params` through `FilterParams.parse/1` and records parser errors through the existing failed-job path.
- `test/threadline/export/orchestrator_test.exs` - Pins bounded date-window CSV replay, invalid persisted datetime failure detail, and no unsafe worker atomization.
- `test/threadline/operator_surface/live/export_status_live_test.exs` - Pins existing failed export row treatment for parser-derived worker errors.
- `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-01-SUMMARY.md` - Plan completion record.

## Verification

| Command | Result |
|---------|--------|
| `mix test test/threadline/export/orchestrator_test.exs` before Task 2 | RED as expected - 4 tests, 3 failures covering string datetime replay, parser detail, and `String.to_atom/1` |
| `mix test test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs` | PASS - 61 tests, 0 failures |
| `rg -n "FilterParams\\.parse\|String\\.to_atom" lib/threadline/export/orchestrator.ex` | PASS - `FilterParams.parse/1` present; no `String.to_atom/1` match |
| `rg -n "job\\.query_params ==" test/threadline/operator_surface/live/export_status_live_test.exs` | PASS - exact string-keyed `Queue Timeline export` job-shape assertion remains |
| `mix format lib/threadline/export/orchestrator.ex test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` | PASS |

## Decisions Made

- Used `FilterParams.parse/1` directly in the worker to avoid divergent parsing between direct downloads, Timeline URL state, Exports carried context, and queued replay.
- Kept `ExportJob.query_params` unchanged as the durable string-keyed URL map; replay converts to typed filters only when the job runs.
- Used `raise ArgumentError, message` for parser errors because the existing `Orchestrator.run/2` rescue path already marks the job failed and stores `Exception.message/1`.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; no UI label, route, selector, feature-gate, auth, schema, migration, dependency, or public API changes.

## Issues Encountered

None.

## Auth Gates

None.

## Known Stubs

None. Stub scan over the modified files found no runtime TODO/FIXME/placeholder text or hardcoded empty UI data placeholders. Existing empty-list assertions in tests are test expectations, not product stubs.

## Threat Flags

None. This plan changed the planned persisted-query-params trust boundary by mitigating it with the canonical allowlisted parser; no unplanned endpoint, auth path, schema, dependency, or file-access surface was introduced.

## Next Phase Readiness

Plan 188-02 can proceed to the `.tl-copy` motion-source gap. Plan 188-03 can use this summary and the targeted verification evidence to close the TIME-01/GOV-02/A11Y-02 queued export findings.

## Self-Check: PASSED

- Found summary file: `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-01-SUMMARY.md`
- Found modified files: `lib/threadline/export/orchestrator.ex`, `test/threadline/export/orchestrator_test.exs`, `test/threadline/operator_surface/live/export_status_live_test.exs`
- Found task commits: `56839e11`, `506f99eb`
- Final targeted verification passed: 61 tests, 0 failures

---
*Phase: 188-close-gap-v1-38-export-queue-and-motion-validation*
*Completed: 2026-06-30*
