---
phase: 62-mix-task-and-example-app-wiring
plan: 01
subsystem: mix_tasks
tags:
  - operator-surface
  - mix-task
  - json
dependency_graph:
  requires:
    - Threadline.incident_bundle/2
  provides:
    - mix threadline.incident
  affects:
    - mix.exs
tech_stack:
  added: []
  patterns:
    - Ecto structs to map conversion for JSON serialization
key_files:
  created:
    - lib/mix/tasks/threadline.incident.ex
    - test/mix/tasks/threadline.incident_test.exs
  modified:
    - mix.exs
key_decisions:
  - Added a private map conversion function in the Mix task to handle JSON serialization of `Threadline.Investigation.IncidentBundle` since Ecto structs do not implement `Jason.Encoder` natively in this context without leaking internal metadata.
metrics:
  duration: ~15 mins
  completed_date: "2026-05-06T16:00:00Z"
---

# Phase 62 Plan 01: Implement threadline.incident Mix Task

Implemented the `mix threadline.incident <transaction_id>` operator path. This Mix task allows SSH-only operators to query transaction incidents without needing the LiveDashboard UI, and provides `--json` output suitable for piping to `jq`.

## Deviations from Plan

None - plan executed exactly as written. (Added an internal `bundle_to_map` helper since the plan required "encode the bundle using Jason.encode!" but `IncidentBundle` and other Ecto schemas do not natively derive `Jason.Encoder`. This ensures strictly compliant JSON output).

## Known Stubs

None found.

## Threat Flags

None found.

## Execution Details

- Task 1: Implemented `lib/mix/tasks/threadline.incident.ex` reflecting the requirements. Added tests and confirmed `mix verify.test` passed.
  - Commit: 5e7e007