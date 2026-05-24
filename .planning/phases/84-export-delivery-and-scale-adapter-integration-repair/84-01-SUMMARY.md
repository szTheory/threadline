---
phase: 84-export-delivery-and-scale-adapter-integration-repair
plan: 01
subsystem: export-delivery
tags: [exports, phoenix, liveview, storage, s3]
dependency_graph:
  requires: [phase-82 actor-owned operator surface, phase-83 built-in export lifecycle repair]
  provides: [actor-owned backend-aware export delivery, phase-84 export status ui parity]
  affects: [EXP-03, ADAPT-02, operator-surface export UX]
tech_stack:
  added: []
  patterns: [controller-owned-delivery-resolution, storage-agnostic-export-ui]
key_files:
  created: []
  modified:
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/storage/local.ex
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - test/threadline/operator_surface/live/export_status_live_test.exs
decisions_made:
  - Keep one actor-owned download route keyed by export job ID and branch to local `send_file` or adapter-backed redirect only after authorization succeeds.
  - Remove route knowledge from `Threadline.Storage.Local.download_url/2` so storage adapters stay backend-facing while the controller owns operator-surface delivery.
  - Treat expired or unavailable artifacts as truthful no-download states in both the controller and the status UI rather than rendering dead links.
requirements-completed: [EXP-03, ADAPT-02]
metrics:
  duration: inline-execution
  tasks_completed: 2
  tasks_total: 2
---

# Phase 84 Plan 01: Delivery Repair Summary

## Completed Work

1. Reworked `ExportController.download/2` into a backend-aware delivery path that authorizes by actor and job ID first, then serves local exports with `send_file` or redirects adapter-backed exports through `download_url/2`.
2. Brought `ExportStatusLive` into the locked Phase 84 contract with `Download Export`, `Preparing download`, `Expires At`, failed-state error messaging, and no dead completed-state links.
3. Expanded the controller and LiveView tests to prove local delivery, remote redirect delivery, expiry handling, non-ready placeholders, and failed-state messaging on the repaired tree.

## Verification

- `mix test test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1`
- `mix test test/threadline/operator_surface/live/export_status_live_test.exs --max-failures 1`

## Deviations From Plan

None in scope. The repair stayed on the actor-owned delivery boundary and UI parity without widening into adapter startup or evidence closeout work.
