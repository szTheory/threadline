---
phase: "58"
plan: "03"
subsystem: "Operator Surface"
tags:
  - tdd
  - auth
  - liveview
  - telemetry
depends_on: ["01"]
requires:
  - "Threadline operator surface macro"
provides:
  - "on_mount/4 lifecycle hook for authorization"
affects:
  - "lib/threadline/operator_surface/auth.ex"
tech_stack:
  added: []
  patterns:
    - "LiveView lifecycle hooks"
    - "Telemetry execution"
key_files:
  created:
    - "test/threadline/operator_surface/auth_test.exs"
  modified:
    - "lib/threadline/operator_surface/auth.ex"
key_decisions:
  - "Handled missing `authorize_fn` gracefully by defaulting to `true`."
  - "Extracted scope keys and `actor_ref` to populate telemetry metadata."
metrics:
  duration: 120
  completed_date: 2024-05-15
---

# Phase 58 Plan 03: Operator Surface Auth Hook Summary

Implemented the `on_mount/4` LiveView hook to enforce authorization contracts and emit detailed telemetry for granted, denied, and error outcomes.

## Objectives Achieved

- Created `test/threadline/operator_surface/auth_test.exs` covering all outcome branches (TDD RED).
- Implemented `Threadline.OperatorSurface.Auth.on_mount/4` executing the `authorize_fn` correctly handling `:ok`, `true`, `{:ok, scope}`, `false/nil/invalid`, and crashes.
- Emitted telemetry events `[:threadline, :operator_surface, :authorize]` with appropriate outcomes (`:granted`, `:denied`, `:error`) and metadata (`scope_keys`, `actor_ref`, `path`).
- Halts connection and redirects to `/` for unauthorized requests, protecting the WebSocket/HTTP upgrade boundary (T-58-03-01).

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

- **File**: `lib/threadline/operator_surface/auth.ex`, Line 45
- **Reason**: The `path` attribute in telemetry metadata is currently hardcoded to `""` because `Phoenix.LiveView.Socket` doesn't natively expose the request path universally without custom `get_connect_info/2` setup from the integrating application. This will be updated if/when the integration pattern passes the path in explicitly.

## TDD Gate Compliance

The implementation followed the TDD workflow, producing a `test(...)` commit (failing test) followed by a `feat(...)` commit (passing implementation).

## Self-Check: PASSED
FOUND: test/threadline/operator_surface/auth_test.exs
FOUND: lib/threadline/operator_surface/auth.ex
