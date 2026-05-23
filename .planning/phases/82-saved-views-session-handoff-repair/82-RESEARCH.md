# Phase 82: Saved Views Session Handoff Repair - Research

**Researched:** 2026-05-23
**Domain:** Phoenix router composition, LiveView session handoff, saved-view ownership, and current-tree closeout evidence
**Confidence:** HIGH

## Summary

Phase 82 is a runtime-repair phase, not a new saved-views feature phase. The current tree already has the major pieces:

- `Threadline.OperatorSurface.SessionPlug` can evaluate `actor_fn` on a `conn` and persist a serialized `ActorRef` into the session.
- `Threadline.OperatorSurface.Auth` already prefers session actor data and only falls back to scope-derived actor data when the session actor is absent.
- `TimelineLive` already scopes saved-view loading and mutations through `@threadline_actor_ref`.

The broken seam is the default mount path. `threadline_operator_surface/2` accepts `:actor_fn`, but the router macro never installs `SessionPlug`, so the standard `actor_fn`-driven mount recipe does not reliably populate `@threadline_actor_ref` for LiveViews. The example Phoenix router compounds the problem by returning a plain map from `my_actor_fn/1`, which `SessionPlug` intentionally ignores because it only serializes `%Threadline.Semantics.ActorRef{}` values.

**Primary recommendation:** make `threadline_operator_surface/2` auto-wire the existing `SessionPlug` whenever `:actor_fn` is present, keep session actor data authoritative over scope fallback, add explicit proof for conflicting session-vs-scope actor sources, then close Phase 77 with current-tree verification and Nyquist validation artifacts.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Actor handoff from request to LiveView | Router macro | `SessionPlug` | The macro owns the default mount DX; `SessionPlug` stays the reusable implementation seam. |
| Saved-view ownership source | Session actor | Scope fallback | Locked phase decisions require `actor_fn` authority when present and compatibility fallback only when absent. |
| Mismatch handling | `Auth` | Telemetry/logging | Conflicting actor sources should be visible instead of silently normalized. |
| Canonical integration story | Example router and guides | Doc-contract tests | The default docs must match the repaired runtime path, not the older manual-plug story. |
| Phase 77 closure evidence | Planning artifacts | Current-tree tests/code | The audit gap is both behavior and missing verification/validation proof. |

## Current Tree Findings

### Verified current strengths

- `lib/threadline/operator_surface/session_plug.ex` already serializes `%ActorRef{}` into the `"threadline_actor_ref"` session key.
- `lib/threadline/operator_surface/auth.ex` already reads session actor data before consulting scope fallback and already converts legacy `scope.user_id` into an `ActorRef`.
- `lib/threadline/operator_surface/live/timeline_live.ex` already gates saved-view queries and event handlers on `socket.assigns[:threadline_actor_ref]`.
- The docs already teach `actor_fn` as the actor-authority seam and `authorize_fn` as the authorization seam.

### Verified gaps

- `lib/threadline/operator_surface/router.ex` never installs `Threadline.OperatorSurface.SessionPlug`, so the normal mount path does not hand actor identity into LiveView.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` returns a free-form map from `my_actor_fn/1`, which is incompatible with `SessionPlug` and contradicts the documented contract.
- The current tests prove `SessionPlug` and `Auth` in isolation, but they do not prove that a normal `threadline_operator_surface/2` mount with `:actor_fn` yields actor-owned saved-view behavior end to end.
- Phase 77 has summaries only; `77-VERIFICATION.md` and `77-VALIDATION.md` do not exist.

## Recommended Runtime Shape

### Pattern 1: Macro-owned session handoff when `:actor_fn` is present

The repaired default path should stay simple for adopters:

- `threadline_operator_surface/2` receives `:actor_fn`
- the generated router code installs the existing `SessionPlug`
- LiveView mounts read the actor from session automatically

Recommended posture:

- auto-wire handoff only when `:actor_fn` is present
- preserve mounts without `:actor_fn` as valid, but do not imply actor-owned saved-view behavior there
- keep `SessionPlug` as a real public module for advanced/manual composition, but stop making it the canonical recipe

### Pattern 2: Session actor wins over scope fallback, with explicit mismatch signal

`Auth` already has the right precedence shape. The repair should make that contract observable:

- if session actor exists, keep it authoritative
- only assign fallback actor data from `scope.actor_ref` or `scope.user_id` when no session actor exists
- if both sources exist and disagree, emit an explicit warning/telemetry signal instead of silently hiding the conflict

This protects the "actor_fn is identity, authorize_fn is authorization" boundary without inventing a second actor channel.

### Pattern 3: Canonical example must return a real `ActorRef`

The example app is part of the public contract and must exercise the repaired path honestly. `my_actor_fn/1` should return a `%Threadline.Semantics.ActorRef{}` (or `nil`), not a generic map. The surrounding guides and contract tests should then describe the repaired default path as:

- browser/admin pipeline first
- `threadline_operator_surface` with `actor_fn` + `authorize_fn`
- no extra router plug required for standard saved-view ownership

### Pattern 4: Close Phase 77 with current-tree evidence, not old summaries

Phase 82 should create:

- `77-VERIFICATION.md` proving the repaired default mount path, saved-view ownership, no-actor behavior, compatibility fallback, and mismatch precedence on the current tree
- `77-VALIDATION.md` in the current Nyquist format with explicit task/requirement mappings and executable checks

## Common Pitfalls

### Pitfall 1: Teaching a manual `SessionPlug` prerequisite as the default story

That preserves the audit gap and keeps the main operator-surface mount recipe misleading.

### Pitfall 2: Letting scope override session actor silently

That would reopen the identity/authorization ambiguity the phase is explicitly trying to close.

### Pitfall 3: Fixing only docs or only isolated unit tests

The defect is in composed router behavior. Phase 82 needs end-to-end proof from a normal mounted surface, not just module-local tests.

### Pitfall 4: Keeping the example router on a non-`ActorRef` shape

Even if the library runtime is repaired, the reference app would still fail to prove the documented contract and future adopters would copy the wrong shape.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix LiveView tests |
| Quick run | `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/session_plug_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1` |
| Phase gate | `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/session_plug_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs --max-failures 1` |

### Requirement Map

| Req ID | Runtime truth to prove | Expected evidence |
|--------|------------------------|-------------------|
| VIEW-01 | Standard `actor_fn` mounts hand actor identity into LiveView automatically | router/auth/session/timeline tests plus `77-VERIFICATION.md` |
| VIEW-02 | Saved-view flows behave as actor-owned features on the repaired default path | timeline tests plus `77-VERIFICATION.md` |

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/v1.20-MILESTONE-AUDIT.md`
- `.planning/phases/82-saved-views-session-handoff-repair/82-CONTEXT.md`
- `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md`
- `.planning/phases/77-saved-views-ergonomics/77-DISCUSSION.md`
- `.planning/phases/77-saved-views-ergonomics/77-01-SUMMARY.md`
- `.planning/phases/77-saved-views-ergonomics/77-02-SUMMARY.md`
- `lib/threadline/operator_surface/router.ex`
- `lib/threadline/operator_surface/session_plug.ex`
- `lib/threadline/operator_surface/auth.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
- `guides/operator-surface.md`
- `guides/integration-contracts.md`
- `guides/getting-started-saas.md`
- `examples/threadline_phoenix/README.md`
- `test/threadline/operator_surface/router_test.exs`
- `test/threadline/operator_surface/session_plug_test.exs`
- `test/threadline/operator_surface/auth_test.exs`
- `test/threadline/operator_surface/live/timeline_live_test.exs`
- `test/threadline/operator_surface_doc_contract_test.exs`
- `test/threadline/integration_contracts_doc_contract_test.exs`
- `test/threadline/example_phoenix_readme_contract_test.exs`
- `test/threadline/getting_started_saas_doc_contract_test.exs`

## RESEARCH COMPLETE
