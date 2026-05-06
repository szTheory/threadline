---
phase: 63
plan: 01
subsystem: docs
tags:
  - operator-surface
  - guides
  - documentation
  - security
dependency_graph:
  requires:
    - Phase 60 (Actor Window Screen)
    - Phase 61 (Row History and As-of Sub-view)
  provides:
    - Definitive operator manual
    - Documentation hub discovery paths
  affects:
    - Adopter onboarding
tech_stack:
  added: []
  patterns: []
key_files:
  created:
    - guides/operator-surface.md
  modified:
    - README.md
    - examples/threadline_phoenix/README.md
    - guides/production-checklist.md
decisions:
  - Kept the core library README lean by providing a 1-minute mount example and delegating policy details to the new comprehensive guide.
metrics:
  duration_minutes: 5
  completed_date: "2026-05-06"
---

# Phase 63 Plan 01: Create Operator Surface Guide and Update Hubs Summary

Created the definitive Operator Surface guide and updated documentation hubs to make the v1.17 LiveView surface discoverable and securely mountable.

## Tasks Completed

- **Task 1:** Created `guides/operator-surface.md` covering the 1-minute mount, security (fail-closed, `authorize_fn`), available screens, and the CLI Mix task.
- **Task 2:** Updated `README.md` with an `## Operator Surface` section and updated `examples/threadline_phoenix/README.md` to explain the example's authenticated admin pipeline.
- **Task 3:** Added a row to `guides/production-checklist.md` to ensure adopters mount the UI securely.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None - the new guide explicitly mitigates T-63-01 by documenting the fail-closed default and requiring a strict `:authorize_fn` policy.

## Self-Check: PASSED
- `guides/operator-surface.md` exists.
- `README.md` includes `## Operator Surface`.
- Commits exist: `d4d2c6c`, `f4c0aa8`, `e556481`.
