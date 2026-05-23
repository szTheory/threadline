---
phase: 79-scale-adapters
plan: 01
subsystem: Core / Configuration
tags: [architecture, deps, core]
dependency_graph:
  requires: []
  provides: [init callbacks, optional dependencies]
  affects: [mix.exs, Threadline.Storage, Threadline.ExportQueue]
tech_stack:
  added: []
  patterns: [optional-dependencies, initialization-safeguards]
key_files:
  created: []
  modified:
    - mix.exs
    - lib/threadline/export_queue.ex
    - lib/threadline/storage.ex
    - lib/threadline/export_queue/task_adapter.ex
    - lib/threadline/storage/local.ex
decisions_made:
  - Add optional enterprise dependencies to `mix.exs` without changing defaults.
  - Require an `init/1` callback on adapter behaviours to fail early if missing dependencies.
metrics:
  duration: 1m
  tasks_completed: 3
  tasks_total: 3
---

# Phase 79 Plan 01: Core Behaviours and Optional Dependencies Summary

Prepared `mix.exs` with optional dependencies and extended the core `Threadline.Storage` and `Threadline.ExportQueue` behaviours with an `init/1` callback.

## Completed Work

1. Added `oban`, `ex_aws`, `ex_aws_s3`, `hackney`, and `sweet_xml` as optional dependencies in `mix.exs`.
2. Added `@callback init(keyword()) :: :ok | {:error, term()}` to `Threadline.ExportQueue` and `Threadline.Storage`.
3. Implemented `init/1` in `Threadline.ExportQueue.TaskAdapter` and `Threadline.Storage.Local` built-in adapters.

## Deviations from Plan

None - plan executed exactly as written.
