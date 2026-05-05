---
phase: 50-direct-sigra-host-wiring
plan: 50-01
subsystem: integration
tags: [sigra, phoenix, plug, tests]
provides:
  - canonical direct Sigra callback wiring with no example-local delegate seam
  - adapter and example request-path tests covering the direct callback contract
  - router-driven proof for Sigra correlation fallback when x-correlation-id is absent
affects: [SIGRA-04, SIGRA-05]
requirements-completed: [SIGRA-04, SIGRA-05]
tech-stack:
  added: []
  patterns: [direct Threadline.Plug callback wiring, router-path proof over helper seams]
key-files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - lib/threadline/integrations/sigra.ex
    - test/threadline/integrations/sigra_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs
  deleted:
    - examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex
key-decisions:
  - the example app teaches Threadline.Integrations.Sigra directly rather than an app-local alias
  - the no-header correlation fallback is proven through the real Phoenix router path
duration: 20min
completed: 2026-05-05
---

# Plan 50-01 summary

Removed the dead example-local **`ThreadlinePhoenix.AuditActor`** seam and tightened the runtime proof surface around the canonical direct Sigra callback pair used by **`Threadline.Plug`**.

## Task commits

Executed in the existing dirty Phase 50 worktree without resetting unrelated in-flight changes.

## Self-check

PASSED — `mix test test/threadline/integrations/sigra_test.exs`
PASSED — `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs`
