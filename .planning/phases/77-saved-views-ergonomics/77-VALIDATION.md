---
phase: 77
slug: saved-views-ergonomics
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
updated: 2026-05-23T19:29:52Z
---

# Phase 77 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 77 is validated on the repaired final tree after Phase 82 closed the default mount-path handoff gap. The primary risk is drifting back to the older summary-only story or reintroducing scope-first ownership through later auth/router edits.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit runtime tests, doc-contract tests, and code-surface grep verification |
| **Config file** | `lib/threadline/operator_surface/router.ex`; `lib/threadline/operator_surface/session_plug.ex`; `lib/threadline/operator_surface/auth.ex`; `lib/threadline/operator_surface/live/timeline_live.ex`; `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`; `guides/operator-surface.md`; `guides/integration-contracts.md`; `guides/getting-started-saas.md`; `examples/threadline_phoenix/README.md` |
| **Quick run command** | `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/session_plug_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-20 seconds on a warm cache |
| **Estimated runtime — full** | ~90-180 seconds on a warm cache |

---

## Sampling Rate

- Re-run the saved-view runtime quartet after any change to `router.ex`, `session_plug.ex`, `auth.ex`, or `timeline_live.ex`.
- Re-run the doc-contract group whenever the example router or operator-surface guides change, so the public story remains aligned with the repaired default path.
- Re-run the grep proof when milestone evidence files are repaired so the active artifacts continue to name the default handoff path, session-first ownership, and mismatch telemetry explicitly.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 77-01-01 | 01 | 1 | VIEW-01 | T-82-01 | `threadline_operator_surface/2` auto-installs `Threadline.OperatorSurface.SessionPlug` when `actor_fn` is present on the standard mount path. | code-surface + targeted unit | `rg -n 'threadline_actor_session|SessionPlug|actor_fn' lib/threadline/operator_surface/router.ex lib/threadline/operator_surface/session_plug.ex test/threadline/operator_surface/router_test.exs && mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/session_plug_test.exs --max-failures 1` | ✅ | ✅ green |
| 77-01-02 | 01 | 1 | VIEW-01 | T-82-02 | `Threadline.OperatorSurface.Auth` keeps session actor data authoritative, preserves compatibility-only fallback, and emits mismatch telemetry when scope fallback disagrees. | code-surface + targeted unit | `rg -n 'actor_ref_mismatch|scope_actor_ref|legacy_user_id_to_actor' lib/threadline/operator_surface/auth.ex test/threadline/operator_surface/auth_test.exs && mix test test/threadline/operator_surface/auth_test.exs --max-failures 1` | ✅ | ✅ green |
| 77-02-01 | 02 | 2 | VIEW-02 | T-82-03 | Saved views work on the repaired default `actor_fn` mount path, no-actor mounts do not advertise actor-owned saved-view controls, and the legacy scope-only fallback still functions. | targeted liveview | `mix test test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 77-02-02 | 02 | 2 | VIEW-01, VIEW-02 | T-82-03 | The canonical example/docs teach the repaired mount contract truthfully: real `ActorRef`, default `/audit` mount, and no manual `SessionPlug` in the primary recipe. | doc-contract | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/77-saved-views-ergonomics/77-01-PLAN.md`
- [x] `.planning/phases/77-saved-views-ergonomics/77-02-PLAN.md`
- [x] `.planning/phases/77-saved-views-ergonomics/77-01-SUMMARY.md`
- [x] `.planning/phases/77-saved-views-ergonomics/77-02-SUMMARY.md`
- [x] `.planning/phases/77-saved-views-ergonomics/77-VERIFICATION.md`
- [x] `.planning/phases/77-saved-views-ergonomics/77-VALIDATION.md`

Wave 0 is complete. Phase 77 now has a full current-tree evidence chain for the repaired default saved-view handoff path.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review that the repaired saved-view closeout does not overclaim later export-runtime closure | VIEW-01, VIEW-02 | The highest-risk failure mode is milestone wording drift outside the saved-view boundary rather than broken runtime logic | Read `77-VERIFICATION.md` and confirm it stays scoped to router/session/auth/timeline/doc truth without claiming Phase 83-84 export closure. |

---

## Validation Sign-Off

- [x] Phase 77 has explicit automated coverage for router handoff wiring, session-first auth ownership, saved-view LiveView behavior, and public doc parity on the repaired tree.
- [x] The active evidence references the current repaired tree instead of relying on historical summary prose.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-23 after Phase 82 repaired the default saved-view actor handoff path and backfilled current-tree verification and Nyquist validation artifacts for Phase 77.
