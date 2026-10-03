---
phase: "231"
slug: "facade-topology-and-the-capture-semantics-edge"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-03"
---

# Phase 231 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/public_surface_contract_test.exs test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~60 seconds (quick), several minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run targeted `mix test` on the touched files
- **After every plan wave:** Run `mix compile --warnings-as-errors && mix test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 231-01-T1 | 01 | 1 | API-07 | T-231-01 | hydrate reads actions only from the caller's storage schema; one batched query | unit/integration (tracer) | `mix test test/threadline/query/action_hydration_test.exs test/threadline/investigation_test.exs test/threadline/query_test.exs test/threadline/storage_schema_integration_test.exs` | ❌ W0 (new action_hydration_test.exs) | ⬜ pending |
| 231-01-T2 | 01 | 1 | API-07 | T-231-03 | no association either way; action_id/FK/migrations/trigger SQL untouched | unit + regression + diff gate | `mix test test/threadline/capture_semantics_boundary_test.exs test/threadline/investigation_test.exs test/threadline/query_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/mix/tasks/threadline.incident_test.exs test/threadline/query/action_hydration_test.exs` + `git diff --quiet 0e5eda11 -- lib/threadline/capture/migration.ex lib/threadline/semantics/migration.ex lib/threadline/capture/trigger_sql.ex priv` | ❌ W0 (new capture_semantics_boundary_test.exs) | ⬜ pending |
| 231-01-T3 | 01 | 1 | API-07 | T-231-02 | nested :action preload raises ArgumentError before repo.preload; deprecated path warns once | unit | `mix test test/threadline/query/action_hydration_test.exs test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/changelog_contract_test.exs` | ✅ (file from T1) | ⬜ pending |
| 231-02-T1 | 02 | 2 | API-04 | T-231-05 | skip lists pinned to exact single values | contract (tracer) | `mix test test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs` | ✅ | ⬜ pending |
| 231-02-T2 | 02 | 2 | API-04 | — | N/A | docs build | `MIX_ENV=dev mix docs -f html` with no warning location in lib/ | ✅ | ⬜ pending |
| 231-02-T3 | 02 | 2 | API-04 | — | N/A | docs gate + doc contracts | `MIX_ENV=dev mix docs --warnings-as-errors` + `mix test test/threadline/*_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/public_surface_contract_test.exs` | ✅ | ⬜ pending |
| 231-03-T1 | 03 | 3 | API-04 | T-231-07 | scanner non-vacuous (self-test, non-empty globs, mutation control) | contract (tracer) | `mix test test/threadline/facade_only_references_contract_test.exs` | ❌ W0 (new facade_only_references_contract_test.exs) | ⬜ pending |
| 231-03-T2 | 03 | 3 | API-04, API-07 | T-231-03 | full gate | smoke/full | `MIX_ENV=test mix compile --warnings-as-errors --force`, `mix test --warnings-as-errors`, `mix verify.example`, `MIX_ENV=dev mix docs --warnings-as-errors`, `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/facade_only_references_contract_test.exs` — SC2 / API-04 (D-12)
- [ ] Association-absence test (location chosen by planner) — SC3 / API-07

Existing `test/support/` helpers cover all fixtures.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
