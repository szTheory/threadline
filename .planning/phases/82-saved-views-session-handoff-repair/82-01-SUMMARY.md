---
phase: 82-saved-views-session-handoff-repair
plan: 01
subsystem: operator-surface
tags: [liveview, auth, session, saved-views, docs]
dependency_graph:
  requires: [phase-77 saved-view implementation]
  provides: [default mount-path actor handoff, session-first mismatch telemetry, repaired saved-view docs]
  affects: [VIEW-01, VIEW-02, phase-77 verification]
tech_stack:
  added: []
  patterns: [router-owned-session-handoff, session-first-liveview-auth, actor-backed-doc-contract]
key_files:
  created: []
  modified:
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/auth.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - guides/operator-surface.md
    - guides/integration-contracts.md
    - guides/getting-started-saas.md
    - examples/threadline_phoenix/README.md
    - test/threadline/operator_surface/router_test.exs
    - test/threadline/operator_surface/session_plug_test.exs
    - test/threadline/operator_surface/auth_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/integration_contracts_doc_contract_test.exs
    - test/threadline/example_phoenix_readme_contract_test.exs
decisions_made:
  - Keep the existing `SessionPlug` as the single actor handoff mechanism and install it from the router macro instead of inventing a second path.
  - Preserve session-first actor ownership in `Auth` and emit mismatch telemetry when legacy scope fallback disagrees.
  - Rewrite the public example/docs around a real `ActorRef` callback and the repaired default mount path.
requirements-completed: [VIEW-01, VIEW-02]
metrics:
  duration: inline-execution
  tasks_completed: 3
  tasks_total: 3
---

# Phase 82 Plan 01: Runtime Repair Summary

## Completed Work

1. Wired `Threadline.OperatorSurface.SessionPlug` into `threadline_operator_surface/2` whenever `actor_fn` is present, so the standard `/audit` LiveView path now receives actor identity without extra adopter wiring.
2. Kept `Threadline.OperatorSurface.Auth` session-first, added explicit mismatch telemetry for conflicting scope fallback actor data, and strengthened the saved-view LiveView tests around actor-backed, no-actor, and compatibility-only mounts.
3. Updated the example router and public guides to teach the repaired path truthfully: real `ActorRef`, standard `actor_fn` mount, and manual `SessionPlug` only as an advanced escape hatch.

## Verification

- `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/session_plug_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1`
- `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs --max-failures 1`
- `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/session_plug_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs --max-failures 1`

## Deviations From Plan

None in scope. The repair stayed on the saved-view handoff and truth-surface boundary without widening into export-runtime work owned by later phases.
