---
phase: 76
plan: 02
subsystem: "ui"
tags: ["liveview", "retention"]
dependency_graph:
  requires: ["01"]
  provides: ["LiveView for retention history"]
  affects: ["operator_surface"]
tech_stack:
  added: []
  patterns: ["Phoenix.LiveView.stream", "Process.send_after auto-refresh"]
key_files:
  created:
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - test/threadline/operator_surface/live/retention_history_live_test.exs
  modified:
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/retention/pruner.ex
key_decisions:
  - Added `handle_cast(:prune, state)` to `Threadline.Retention.Pruner` to allow immediate manual triggering.
  - Used exact copywriting from UI-SPEC for the empty state of retention runs.
  - Test retention policy is manually enabled during `RetentionHistoryLiveTest` setup to allow actual retention run logging.
metrics:
  duration_minutes: 2
  tasks_completed: 2
  files_modified: 5
---

# Phase 76 Plan 02: Retention History LiveView Summary

Operator can view a history of past and active retention runs, and manually trigger a pruning batch via UI.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Functionality] Added `:prune` handle_cast to Pruner**
- **Found during:** Task 2
- **Issue:** The UI triggers a manual GenServer.cast(`Threadline.Retention.Pruner`, `:prune`), but the GenServer didn't have a callback for it, which would crash the process.
- **Fix:** Added `handle_cast(:prune, state)` to send `:run_purge` to itself.
- **Files modified:** `lib/threadline/retention/pruner.ex`
- **Commit:** 1a56638

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
