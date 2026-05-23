---
phase: 77-saved-views-ergonomics
verified: 2026-05-23T19:29:52Z
status: passed
score: 5/5 truths verified
overrides_applied: 1
---

# Phase 77: Saved Views Ergonomics — Verification Report

**Phase Goal:** Prove on the current tree that saved views now work as actor-owned features on the standard operator-surface mount path, with truthful public docs and explicit session-versus-scope ownership behavior.

**Verified:** 2026-05-23T19:29:52Z
**Status:** passed
**Re-verification:** Yes — verified after Phase 82 repaired the missing `threadline_operator_surface/2` session handoff and rewrote the public example/docs around the repaired path

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `threadline_operator_surface/2` now auto-installs `Threadline.OperatorSurface.SessionPlug` on the standard LiveView mount path whenever `actor_fn` is present. | ✓ VERIFIED | `lib/threadline/operator_surface/router.ex`; `test/threadline/operator_surface/router_test.exs` |
| 2 | `SessionPlug` still serializes only real `ActorRef` values into the session, and `Threadline.OperatorSurface.Auth` still reads that session actor back into LiveView on mount. | ✓ VERIFIED | `lib/threadline/operator_surface/session_plug.ex`; `lib/threadline/operator_surface/auth.ex`; `test/threadline/operator_surface/session_plug_test.exs`; `test/threadline/operator_surface/auth_test.exs` |
| 3 | Session actor data stays authoritative over compatibility-only scope fallback, and mismatches emit explicit telemetry instead of silently replacing the session-owned actor. | ✓ VERIFIED | `lib/threadline/operator_surface/auth.ex`; `test/threadline/operator_surface/auth_test.exs` |
| 4 | Saved-view behavior now works on the normal `actor_fn` mount path, while a no-actor mount does not overclaim actor-owned saved-view affordances and the legacy scope-only fallback still works. | ✓ VERIFIED | `test/threadline/operator_surface/live/timeline_live_test.exs`; `lib/threadline/operator_surface/live/timeline_live.ex` |
| 5 | The canonical example router and operator-surface guides now teach the repaired default path truthfully: real `ActorRef` callback, standard `/audit` mount, and no extra manual `SessionPlug` for the primary recipe. | ✓ VERIFIED | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`; `guides/operator-surface.md`; `guides/integration-contracts.md`; `guides/getting-started-saas.md`; `examples/threadline_phoenix/README.md`; doc-contract tests |

**Score:** 5/5 truths verified

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| VIEW-01 | 77-01, 82-01 | Saved-view ownership relies on the host `actor_fn` and reaches LiveView on the normal mount path without forcing a host User schema dependency. | ✓ SATISFIED | `lib/threadline/operator_surface/router.ex`; `lib/threadline/operator_surface/session_plug.ex`; `lib/threadline/operator_surface/auth.ex`; `test/threadline/operator_surface/auth_test.exs`; `test/threadline/operator_surface/live/timeline_live_test.exs` |
| VIEW-02 | 77-02, 82-01 | Operators can create, apply, and delete saved views on the repaired path, while non-actor mounts do not advertise actor-owned behavior. | ✓ SATISFIED | `lib/threadline/operator_surface/live/timeline_live.ex`; `test/threadline/operator_surface/live/timeline_live_test.exs`; public docs and example router |

### Commands Run On Final Tree

1. Default mount-path handoff proof

```bash
rg -n 'threadline_actor_session|SessionPlug|actor_fn|pipe_through' \
  lib/threadline/operator_surface/router.ex \
  lib/threadline/operator_surface/session_plug.ex \
  test/threadline/operator_surface/router_test.exs
```

Result: PASS

2. Session-first ownership and mismatch signaling proof

```bash
rg -n 'threadline_actor_ref|actor_ref_mismatch|scope_actor_ref|legacy_user_id_to_actor' \
  lib/threadline/operator_surface/auth.ex \
  test/threadline/operator_surface/auth_test.exs
```

Result: PASS

3. Saved-view runtime and doc-contract proof

```bash
mix test \
  test/threadline/operator_surface/router_test.exs \
  test/threadline/operator_surface/session_plug_test.exs \
  test/threadline/operator_surface/auth_test.exs \
  test/threadline/operator_surface/live/timeline_live_test.exs \
  test/threadline/operator_surface_doc_contract_test.exs \
  test/threadline/integration_contracts_doc_contract_test.exs \
  test/threadline/example_phoenix_readme_contract_test.exs \
  test/threadline/getting_started_saas_doc_contract_test.exs \
  --max-failures 1
```

Result: PASS

### Verification Notes

- This artifact intentionally supersedes the older summary-only truth surface from Phase 77. The active proof is the repaired final tree: the router installs session handoff, auth keeps session actor ownership authoritative, and the LiveView/doc surfaces now match that implementation.
- The closeout language stays inside the saved-view handoff boundary. It does not claim export-runtime startup, cleanup, Oban runtime integration, or S3-backed download closure owned by Phases 83-84.

### Gaps Summary

No blocking gaps remain for VIEW-01 or VIEW-02 on the current tree. Remaining milestone blockers live outside Phase 77's saved-view scope and are still owned by Phases 83-84.
