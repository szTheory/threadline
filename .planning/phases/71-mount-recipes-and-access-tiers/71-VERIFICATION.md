---
phase: 71-mount-recipes-and-access-tiers
verified: 2026-05-08T15:25:00Z
status: passed
score: 5/5 truths verified
repaired_by:
  - Phase 73
---

# Phase 71: Mount Recipes & Access Tiers — Verification Report

**Phase Goal:** Ship canonical, host-owned admin and support-read-only mount recipes for the operator surface, keep the auth/scope contract honest across LiveView and export transport, and preserve explicit fallback paths for capture-only adopters.

**Verified:** 2026-05-08T15:25:00Z
**Status:** passed
**Re-verification:** Yes — verified on the final post-Phase-73 tree after the example-authorizer and scoped-access gaps were repaired

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The canonical `/audit` recipe now teaches one shared assigns-shaped `authorize_fn` instead of a LiveView-only escape hatch | ✓ VERIFIED | `guides/operator-surface.md`; `guides/integration-contracts.md`; `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`; focused doc-contract suite passed |
| 2 | The support-read-only recipe names a real host-owned `scope_query_fn` seam and keeps `exports: false` as the default export posture | ✓ VERIFIED | `guides/operator-surface.md`; `guides/getting-started-saas.md`; `guides/integrations/sigra.md`; `examples/threadline_phoenix/README.md`; focused doc-contract suite passed |
| 3 | Timeline, actor, transaction, and export flows now enforce the same host-owned scope callback instead of storing `:threadline_scope` as a no-op | ✓ VERIFIED | `lib/threadline/operator_surface/scope.ex`; `lib/threadline/query.ex`; `lib/threadline/investigation.ex`; scoped LiveView/controller tests passed |
| 4 | The example `/audit` path is runnable under the repaired shared callback contract and no longer depends on an unconditional socket allow path | ✓ VERIFIED | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`; `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`; `mix ci.all` passed |
| 5 | The repaired proof surface now fails fast if the shared authorizer, scope seam, or support-runbook wording drifts again | ✓ VERIFIED | `test/threadline/operator_surface_doc_contract_test.exs`; `test/threadline/integration_contracts_doc_contract_test.exs`; `test/threadline/example_phoenix_readme_contract_test.exs`; `test/threadline/operator_surface/live/*`; `test/threadline/operator_surface/controllers/export_controller_test.exs` |

**Score:** 5/5 truths verified

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| INTEG-03 | 71-01, 71-02, 71-03 | Documented and tested host-owned access pattern for router checks, mount checks, and scoped investigation queries | ✓ SATISFIED | Repaired docs and example contract; new shared `scope_query_fn` seam; scoped timeline/actor/transaction/export tests |
| ADOPT-08 | 71-01, 71-02, 71-03 | Canonical admin and support-read-only mount recipes are real, aligned, and provable | ✓ SATISFIED | Admin-first `/audit` runbook, support `exports: false` default, example README/router alignment, full focused proof surface green |

### Commands Run On Final Tree

1. Repaired Phase 71 + Phase 73 focused proof surface

```bash
mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs --max-failures 1
```

Result: PASS (`83 tests, 0 failures`)

2. Capture-only compile gate

```bash
mix verify.compile_no_optional
```

Result: PASS

3. Full repo gate

```bash
mix ci.all
```

Result: PASS (`543 tests, 0 failures`, repo gate green; existing non-blocking warning in `test/threadline/verify_coverage_task_test.exs` remains a warning only)

### Verification Notes

- This artifact closes the v1.19 audit findings that Phase 71 lacked a final verification report and that the support-read-only scope story was only partially real on the shipped tree.
- The example router previously kept a LiveView-only allow branch inside `my_authorize_fn/1`; the repaired tree removes that branch and carries the authenticated user through the session-backed LiveView path instead.
- The support-read-only proof is now behavioral. It is no longer limited to `:threadline_scope` assignment smoke coverage.

### Gaps Summary

No blocking gaps remain for Phase 71 on the repaired tree. Remaining milestone closeout work is Phase 74 bookkeeping for Phase 72, not unresolved Phase 71 behavior.

