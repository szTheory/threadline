---
phase: 120-root-auth-integration-proof
plan: 01
subsystem: testing
tags: [phx-gen-auth, integration-test, plug, export-auth]

requires: []
provides:
  - Root CI proof for phx-gen-auth-reference lane (AUTH-PROOF-01, AUTH-PROOF-02)
affects: [120-02]

key-files:
  created:
    - test/support/phx_gen_auth_fixtures.ex
    - test/threadline/integrations/phx_gen_auth_integration_test.exs
  modified: []

requirements-completed: [AUTH-PROOF-01, AUTH-PROOF-02]

completed: 2026-05-27
---

# Phase 120 Plan 01 Summary

**Root integration tests prove phx.gen.auth-shaped scope assigns, 1-arity admin authorize_fn, and a single Threadline.Plug smoke — without Sigra or a lib adapter.**

## Accomplishments

- `Threadline.PhxGenAuthFixtures` for scope/header/current_user conn building
- `Threadline.Integrations.PhxGenAuthReference.AuditActor` test-local module matching guide semantics
- Nine tests across actor_fn, ExportAuthPlug authorize mirror, and one Plug composition smoke

## Deviations

- `actor_ref_from_conn/1` unwraps `ActorRef.new/2` to return `%ActorRef{}` (Plug contract); guide snippet still shows bare `ActorRef.new/2`
