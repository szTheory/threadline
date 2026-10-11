---
phase: 242-export-and-retention-operations
plan: "02"
subsystem: retention
tags: [phoenix-liveview, ecto, postgresql, advisory-locks, retention]

requires:
  - phase: 242-01
    provides: shared export and operator-surface lifecycle patterns
provides:
  - Persisted queued retention acceptance and one run identity through terminal outcome.
  - Partial committed deletion counts and safe terminal failure categories.
  - Global configured-schema prune explanation, exact confirmation, and persisted run history.
affects: [242-03, 243]

actuals:
  tokens: 14450
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 2d9ef0e5f760c47d8c3326a43f26c5b0e079a764
plan_head_after: 961c4db49601dd5ea116e8c195c14f5f809af301

tech-stack:
  added: []
  patterns: [transactional accepted-run persistence, checkpointed batch outcomes, async LiveView history states]

key-files:
  created: []
  modified:
    - lib/threadline/retention/pruner.ex
    - lib/threadline/retention.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - test/threadline/retention/pruner_test.exs
    - test/threadline/retention_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs

key-decisions:
  - "Persist the queued RetentionRun before acknowledging; serialize acceptance and coalesce scheduled and direct active requests."
  - "Track committed deletion batches on the accepted run and expose only finite safe failure categories."
  - "Keep global configured-schema scope, exact server-derived confirmation, event-time authorization, and audit-before-prune ordering."

patterns-established:
  - "Retention history distinguishes loading, successful empty, read error, and populated states while preserving page identity."
  - "Tests synchronize with the asynchronous LiveView mailbox before asserting loaded retention history."

requirements-completed: [UIO-05]
coverage:
  - id: D1
    description: "A prune is acknowledged only after a queued run is persisted, and active requests reuse its identity."
    requirement: UIO-05
    verification:
      - kind: unit
        ref: "test/threadline/retention/pruner_test.exs; mix test task-focused retention suite"
        status: pass
    human_judgment: false
  - id: D2
    description: "Partial committed deletions and safe terminal outcomes are visible on the accepted run."
    requirement: UIO-05
    verification:
      - kind: unit
        ref: "test/threadline/retention_test.exs and test/threadline/retention/pruner_test.exs; 23 tests"
        status: pass
    human_judgment: false
  - id: D3
    description: "Operators see global scope, exact policy confirmation, and authoritative retention history."
    requirement: UIO-05
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/live/retention_history_live_test.exs"
        status: pass
      - kind: automated_ui
        ref: "Mounted Chromium check on /audit/policy/retention: history, configured-schema scope, exact token, consequence, and cancel"
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-10-10
status: complete
---

# Phase 242 Plan 02: Confirmed global prune Summary

**Retention pruning now has a durable accepted run, preserves partial deletion outcomes, and presents its configured-schema scope and persisted history clearly.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-10-10T21:10:06Z
- **Completed:** 2026-10-10T21:29:19Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Persisted and coalesced queued prune requests, carrying one run identity through execution.
- Recorded cumulative committed deletion counts and safe failure categories on failed runs while preserving public purge behavior.
- Added truthful loading, empty, read-error, populated, and partial-failure history states plus a full global-scope confirmation.

## Task Commits

1. **Task 1: Persist one run before prune acknowledgment and execute that same run** - `9f81e7ea` (`fix(242-02): persist accepted retention runs`)
2. **Task 2: Record partial deletion and safe terminal failure on the accepted run** - `f7e68a33` (`fix(242-02): retain partial prune outcomes`)
3. **Task 3: Show global prune scope and authoritative run outcomes in confirmation and history** - `961c4db4` (`fix(242-02): show authoritative retention outcomes`)

## Files Created/Modified

- `lib/threadline/retention/pruner.ex` - durable acceptance, active-run coalescing, and same-run terminal tracking.
- `lib/threadline/retention.ex` - committed-batch outcome tracking with preserved public result/error semantics.
- `lib/threadline/operator_surface/live/retention_history_live.ex` - exact authorized confirmation, safe audit feedback, and persisted history states.
- `test/threadline/retention/pruner_test.exs` - acceptance ordering, coalescing, and failure lifecycle regressions.
- `test/threadline/retention_test.exs` - partial-batch failure and public purge behavior regressions.
- `test/threadline/operator_surface/live/retention_history_live_test.exs` - scope, history truth states, audit failure, and confirmation coverage.

## Decisions Made

- Kept retention policy and schema behavior within the existing API/schema and used the existing advisory-lock mechanism; no dependency was added.
- Preserved the audit-before-trigger sequence and required a stable identifiable actor before writing the destructive AuditAction.
- Kept history loading asynchronous for connected LiveViews and synchronized test assertions with the queued load event.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Reject malformed actor references before auditing a prune**
- **Found during:** Task 3
- **Issue:** A directly constructed non-anonymous ActorRef with an empty ID passed the struct check and could be recorded as the accountable operator.
- **Fix:** Require `ActorRef.identifiable?/1` before attempting the destructive AuditAction; return safe audit failure feedback otherwise.
- **Files modified:** `lib/threadline/operator_surface/live/retention_history_live.ex`, `test/threadline/operator_surface/live/retention_history_live_test.exs`
- **Verification:** Focused retention suite passed (49 tests, 0 failures).
- **Committed in:** `961c4db4`

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** Closed an accountability edge within the approved audit-before-prune boundary; no API, schema, or dependency expansion.

## Executed Checks

- `mix test test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/retention/pruner_test.exs test/threadline/retention_test.exs` — 49 tests, 0 failures.
- `mix format --check-formatted` for the two Task 3 files — passed.
- `git diff --check` for the Task 3 files — passed.
- Mounted Chromium route check — passed for authenticated retention history, configured-schema scope, connected LiveView, canonical confirmation token, consequence copy, and cancellation without pruning.
- The named wrapper `mix verify.example_browser --grep 'Retention|offline|reconnect'` stalled after npm setup before server startup at its silent browser-install stage. The existing cached Chromium was used for the successful direct mounted check instead.

## Issues Encountered

The mounted browser wrapper did not reach application startup after installing its test packages. A direct mounted check using the cached Chromium and a local example server completed successfully. Hex also reported an expired authentication session during dependency resolution; no private package was needed.

## User Setup Required

None.

## Next Phase Readiness

Plan 242-02 is complete. Plan 242-03 can now add native mutation gating and real transport-loss/reconnect verification over the persisted retention state.

## Self-Check: PASSED

- Summary file exists at the required path.
- Task commits `9f81e7ea`, `f7e68a33`, and `961c4db4` are ancestors of the current plan head.

---
*Phase: 242-export-and-retention-operations*
*Completed: 2026-10-10*
