# Phase 58 Validation

## Goal
Give hosts a one-line mount macro with the most conservative auth posture in the ecosystem (fail-closed by default, host-owned policy).

## Truths to Verify
1. A host can `import Threadline.OperatorSurface.Router` and call `threadline_operator_surface "/audit", opts` inside a `Phoenix.Router` scope's `pipe_through` to mount the surface in one line.
2. The mount macro raises a clear adopter-targeted compile error unless one of: the scope has at least one `pipe_through`, `:authorize_fn` is supplied, or `:adopter_acknowledges_unauthenticated: true` is explicit.
3. `:authorize_fn` accepts the documented shape with allowlist semantics (only `:ok`, `true`, `{:ok, scope}` permit access).
4. Every authorize check emits a `[:threadline, :operator_surface, :authorize]` telemetry event.

## Key Links
- Router macro validates AST and connects caller to LiveView mount.
- Auth on_mount hook validates connection and dispatches to telemetry.
