---
phase: 186-detail-governance-and-export-surfaces
plan: 03
subsystem: operator-surface
tags: [phoenix-liveview, retention, destructive-flow, source-contracts, motion]

requires:
  - phase: 186-detail-governance-and-export-surfaces
    provides: "Phase 186 Retention UI-SPEC, context, research, and validation contracts"
provides:
  - "Retention destructive prune flow with locked labels, visible failure/success feedback, one page-level prune entry, and focused window-health summary"
  - "Retention-local copy/source contracts for destructive-flow labels, policy-level action path, and stable table test ids"
  - "Retention-local style contract proving motion remains on the governed existing run-row animation"
affects: [operator-surface, retention, governance, phase-187-closeout]

tech-stack:
  added: []
  patterns:
    - "Retention LiveView keeps destructive-flow copy in a private prune_modal_copy/1 helper"
    - "Retention summary/action presentation is derived through private Retention-local helpers"
    - "Source contracts scope negative checks to Retention source blocks instead of broad file-wide bans"

key-files:
  created:
    - .planning/phases/186-detail-governance-and-export-surfaces/186-03-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "Resolved D-186-15 by removing the row-level destructive prune action and keeping one page-level policy prune entry."
  - "Rendered Retention-local flash alerts so mismatch and runtime-unavailable outcomes are visible in the LiveView output."
  - "Kept existing Retention row motion because it is already tokenized and inventory-governed; added a scoped guard instead of changing CSS."

patterns-established:
  - "Locked destructive-flow copy lives in one Retention-local helper and is consumed by both render and event branches."
  - "Retention source contracts assert row action blocks directly when preventing destructive-action drift."

requirements-completed: [GOV-01, GOV-03]

duration: 8 min
completed: 2026-06-30
status: complete
---

# Phase 186 Plan 03: Retention Destructive Flow and Source Contracts Summary

**Retention now presents one focused window-health workflow and keeps destructive prune copy, auth, audit, reconnect, focus, and source-contract guarantees pinned.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-30T11:26:25Z
- **Completed:** 2026-06-30T11:34:11Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Collapsed Retention away from a duplicate trust rail into one `Retention window health` summary below the page header.
- Locked destructive prune labels: `Run retention prune`, `Prune retention window permanently?`, `Keep retention window`, `Prune records permanently`, and `Could not prune - confirmation did not match.`
- Removed the row-level destructive prune action; the Retention table row action now only carries contextual Evidence review when enabled.
- Preserved the server-side prune guarantees: event-time auth re-check, canonical `default` policy, `Plug.Crypto.secure_compare/2`, audit-before-prune, runtime-unavailable handling, and reconnect-safe submit affordance.
- Added Retention-local copy and style source contracts without route, test-id, dependency, Tailwind, shadcn, external icon, or public component API changes.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Lock Retention destructive-flow contracts** - `d3a50e11` (test)
2. **Task 1 GREEN: Implement Retention destructive-flow contract** - `107fa9f4` (feat)
3. **Task 2: Add Retention source contracts** - `545d9a0b` (test)

## Files Created/Modified

- `lib/threadline/operator_surface/live/retention_history_live.ex` - Focused summary, visible flash alerts, locked modal copy helper, contextual Evidence action, row-level destructive prune removal.
- `test/threadline/operator_surface/live/retention_history_live_test.exs` - Locked Retention copy, summary, mismatch flash, focus/modal affordance, and single destructive entry coverage.
- `test/threadline/operator_surface/copy_contract_test.exs` - Retention-local source assertions for labels, state copy, policy-level action path, stable test ids, and dependency/prohibition boundaries.
- `test/threadline/operator_surface/style_contract_test.exs` - Scoped Retention motion contract for existing tokenized `#retention-runs > tr` animation and no Retention-specific keyframes.
- `.planning/phases/186-detail-governance-and-export-surfaces/186-03-SUMMARY.md` - Plan completion record.

## Decisions Made

- Removed the row-level prune action rather than relabeling it, matching the preferred D-186-15 resolution.
- Kept normal HTTP/navigation links out of the destructive path; only the page-level button opens the policy modal with `JS.push_focus()`.
- Added visible Retention-local flash alert rendering because the destructive-flow mismatch and runtime-unavailable copy must be user-visible in this LiveView.
- Left CSS unchanged and added a source guard because existing Retention motion is already tokenized, reduced-motion governed, and inventory-backed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Surfaced Retention destructive-flow flash messages**
- **Found during:** Task 1 (green step)
- **Issue:** The LiveView set mismatch/runtime flash messages, but the Retention test layout did not render flash output, so the locked mismatch copy was not visible to the operator.
- **Fix:** Added Retention-local error/info alert rendering after the page header.
- **Files modified:** `lib/threadline/operator_surface/live/retention_history_live.ex`
- **Verification:** `mix test test/threadline/operator_surface/live/retention_history_live_test.exs`
- **Committed in:** `107fa9f4`

---

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** The auto-fix was required for the planned mismatch/runtime-unavailable copy to be observable. No route, auth, dependency, component API, or destructive backend semantics changed.

## Issues Encountered

- The first Task 2 compile-backed contract run was blocked by unrelated concurrent Phase 186 edits in Actor/Redaction files. Those files were outside this plan's owned scope and were not modified here.
- A subsequent compile-backed copy/style run briefly failed an existing Timeline copy assertion, then passed on rerun without code changes.
- Task 2 source contracts passed the focused no-compile sanity run while the unrelated compile blocker was present, then passed the full compile-backed lane after the shared worktree cleared.

## Verification

- `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` - passed, 19 tests.
- `mix test test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` - passed, 59 tests.
- `mix test test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` - passed, 78 tests.
- `mix compile --warnings-as-errors` - passed.

## TDD Gate Compliance

- Task 1 followed RED/GREEN: failing Retention LiveView tests in `d3a50e11`, implementation in `107fa9f4`.
- Task 2 was a test-only source-contract task after Task 1 had already implemented the target behavior; the added contracts were committed as `545d9a0b` after compile-backed verification passed.

## Known Stubs

None. Stub-pattern scan hits were existing test assertions/static source snippets, not placeholder UI data or unwired mocked state.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, schema changes, package dependencies, or trust boundaries were introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Retention is ready for Phase 186 browser closeout proof and Phase 187 accessibility/motion closeout. GOV-03 is source- and LiveView-covered for destructive-flow copy, single policy-level action, server enforcement, visible failure/success feedback, and governed motion.

## Self-Check: PASSED

- Found `lib/threadline/operator_surface/live/retention_history_live.ex`.
- Found `test/threadline/operator_surface/live/retention_history_live_test.exs`.
- Found `test/threadline/operator_surface/copy_contract_test.exs`.
- Found `test/threadline/operator_surface/style_contract_test.exs`.
- Found `.planning/phases/186-detail-governance-and-export-surfaces/186-03-SUMMARY.md`.
- Found task commit `d3a50e11`.
- Found task commit `107fa9f4`.
- Found task commit `545d9a0b`.

---
*Phase: 186-detail-governance-and-export-surfaces*
*Completed: 2026-06-30*
