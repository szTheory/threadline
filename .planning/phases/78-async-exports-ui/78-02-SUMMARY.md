---
phase: "78"
plan: "02"
subsystem: "Export Artifact Cleanup & Download Route"
tags: [export, cleanup, download]
dependency_graph:
  requires: ["78-01"]
  provides: ["Cleanup task for old exports", "Secure download HTTP route"]
  affects: ["Storage", "HTTP Interface"]
tech_stack:
  added: []
  patterns: ["Periodic GenServer", "Plug.Conn.send_file/3"]
key_files:
  created:
    - lib/threadline/export/cleanup_task.ex
    - test/threadline/export/cleanup_test.exs
  modified:
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - lib/threadline/operator_surface/router.ex
    - test/threadline/operator_surface/controllers/export_controller_test.exs
decisions:
  - "Used `Plug.Conn.send_file/3` instead of reading the file contents into memory to securely serve massive CSVs and prevent OOMs."
  - "Added strict IDOR checks ensuring `actor_ref` matches the requester."
  - "Created `Threadline.Export.CleanupTask` to clean up expired jobs hourly via GenServer, similar to `Threadline.Retention.Pruner`."
metrics:
  duration_minutes: 35
  completed_tasks: 2
  total_tasks: 2
---

# Phase 78 Plan 02: Export Artifact Cleanup & Download Route Summary

Implemented an automated periodic background worker to clean up expired export CSV files and their database records, and established an efficient HTTP download route secured against IDOR.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed test insertions for Threadline.Semantics.ActorRef**
- **Found during:** Task 2 (Download tests)
- **Issue:** The schema for `ExportJob` requires `actor_ref` to be an instance of `%Threadline.Semantics.ActorRef{}` for casting properly when using `Repo.insert!`, but the initial test implementation supplied a string `"user_123"`.
- **Fix:** Swapped `"user_123"` with `%Threadline.Semantics.ActorRef{type: :user, id: "123"}` across all tests where an `ExportJob` was inserted or `threadline_actor_ref` was assigned in `conn`.
- **Files modified:** `test/threadline/operator_surface/controllers/export_controller_test.exs`
- **Commit:** `5ee370f`

## Threat Flags

None discovered outside the stated threat model. IDOR protections are firmly in place, and `Plug.Conn.send_file/3` correctly mitigates memory bloat for the D-27 (massive datasets) requirement.
