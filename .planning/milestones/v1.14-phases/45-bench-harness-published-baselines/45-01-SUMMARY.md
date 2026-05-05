---
phase: 45-bench-harness-published-baselines
plan: 01
subsystem: bench
tags:
  - benchmarking
  - harness
  - config
dependency_graph:
  requires: []
  provides:
    - Independent benchmarking harness for Threadline
  affects:
    - bench/
tech_stack:
  added: []
  patterns:
    - sibling-mix-project
    - standalone-ecto-scripts
key_files:
  created:
    - bench/mix.exs
    - bench/README.md
    - bench/scripts/seed_audit_changes.exs
    - bench/scripts/teardown.exs
    - bench/.formatter.exs
  modified:
    - .gitignore
key_decisions:
  - Created an independent sibling Mix project in `bench/` to prevent benchmarking dependencies (`benchee`, `benchee_html`) from bleeding into the root library.
  - Wrote robust Ecto state management scripts (`seed_audit_changes.exs` and `teardown.exs`) that can load or truncate three benchmarking presets (`cold_single_table`, `warm_loaded`, `concurrent_purge`).
metrics:
  duration: 4m
  tasks_completed: 2
  tasks_total: 2
  files_modified: 6
  completed_at: "2026-05-01T21:40:00Z"
---

# Phase 45 Plan 01: Setup Independent Benchmarking Harness Summary

Established an independent sibling project in `bench/` to isolate benchee dependencies and implemented state-management scripts for predictable workload testing.

## Summary of Changes

- **Harness Scaffolding**: Configured `bench/mix.exs` as an independent sibling project with a local path dependency on the root `threadline` application. Added `benchee` and associated formatting dependencies.
- **State Management**: Created `seed_audit_changes.exs` to seed database state corresponding to three presets (`cold_single_table`, `warm_loaded`, `concurrent_purge`) and `teardown.exs` to clean up state after benchmarking runs via raw SQL truncation.
- **Documentation**: Added `bench/README.md` to document the harness architecture and the available workload presets.

## Deviations from Plan

**1. [Rule 2 - Auto-add missing critical functionality] Track formatter config**
- **Found during:** Task 2
- **Issue:** The benchmarking scripts reside outside standard source directories, requiring an explicit `.formatter.exs` for `mix format --check-formatted` to succeed correctly.
- **Fix:** Created `bench/.formatter.exs` to include `{scripts}/**/*.{ex,exs}` and fixed a minor `.gitignore` accident.
- **Files modified:** `bench/.formatter.exs`, `.gitignore`
- **Commit:** daaf4a8

## Threat Flags

None found.

## Self-Check: PASSED
- `bench/mix.exs` exists.
- `bench/scripts/seed_audit_changes.exs` exists.
- Commits track all tasks.
