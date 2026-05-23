---
phase: 81-retention-runtime-closure
plan: 01
subsystem: retention-runtime
tags: [otp, retention, liveview, verification]
dependency_graph:
  requires: [phase-76 retention implementation]
  provides: [built-in retention supervision, supervised trigger api, runtime-path tests]
  affects: [RET-01, RET-02, RET-03, phase-76 verification]
tech_stack:
  added: []
  patterns: [application-owned-runtime, named-pruner-api, supervised-liveview-trigger]
key_files:
  created:
    - lib/threadline/application.ex
  modified:
    - mix.exs
    - config/config.exs
    - config/test.exs
    - lib/threadline/retention/pruner.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - test/threadline/retention/pruner_test.exs
    - test/threadline/retention_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
decisions_made:
  - Keep retention on the built-in OTP path with a conditional `Threadline.Application` child instead of introducing a second runtime abstraction.
  - Route the UI button through `Threadline.Retention.Pruner.trigger/0` so manual and scheduled pruning share the same named supervised process.
metrics:
  duration: inline-execution
  tasks_completed: 3
  tasks_total: 3
---

# Phase 81 Plan 01: Runtime Repair Summary

## Completed Work

1. Added a real `Threadline.Application` startup path and wired it through `mix.exs` so retention can start from the library-owned supervision tree when enabled and a repo is configured.
2. Added a public `Threadline.Retention.Pruner.trigger/0` API and updated `RetentionHistoryLive` to use the supervised runtime path instead of a raw named cast.
3. Strengthened retention tests so the repaired path is proven at three layers: application-owned pruner startup, LiveView-triggered manual pruning, and `threadline_retention_runs` completion metadata.

## Task Commits

1. **Task 1: Add a built-in application supervisor for retention runtime** — `688d44d` (`feat`)
2. **Task 2: Route the retention UI through an explicit supervised-runtime API** — `f687315` (`feat`)
3. **Task 3: Reconfirm runtime tracking invariants on the repaired path** — `80914fc` (`test`)

## Verification

- `mix test test/threadline/retention/pruner_test.exs --max-failures 1`
- `mix test test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1`
- `mix test test/threadline/retention/pruner_test.exs test/threadline/retention_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1`

## Deviations From Plan

None in scope. The repair stayed on the built-in retention runtime path and did not widen into export or scheduler redesign work.
