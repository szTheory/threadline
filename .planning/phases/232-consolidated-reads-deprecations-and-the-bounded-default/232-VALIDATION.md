---
phase: "232"
slug: "consolidated-reads-deprecations-and-the-bounded-default"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-03"
---

# Phase 232 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + stream_data ~> 1.4 (property tests), real PostgreSQL |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test <narrowest test file touched by the task>` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~5–15 seconds per file; full gate several minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest test file(s) touched by the task
- **After every plan wave:** Run `mix test --warnings-as-errors` + `mix verify.example`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** ~60 seconds per task

---

## Per-Task Verification Map

Filled by the planner per task; source map is `232-RESEARCH.md` → Validation Architecture → Phase Requirements → Test Map.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| API-01 / SC1 | `row_history/3` bounded default 200, limit overrides, cursor walk == `:infinity`, `:limit`+`:cursor` raises | integration (real PG) | `mix test test/threadline/row_history_test.exs` | ❌ W0 | ⬜ pending |
| API-01 / SC2 | truncation telemetry registered, leak-checked; export/as_of unbounded | unit | `mix test test/threadline/telemetry_registry_contract_test.exs test/threadline/query/as_of_property_test.exs` | partial | ⬜ pending |
| API-02 | actor_history/actor_window docs state return type first + cross-link | doc-contract | planner-chosen doc-contract test file | ❌ W0 | ⬜ pending |
| API-03 / SC3 | one `%Threadline.Page{}` shape; old page structs gone; only paired name is timeline/timeline_page | unit | planner-chosen page + facade-naming test files | ❌ W0 | ⬜ pending |
| API-05 | hidden names absent from `Code.fetch_docs/1`; no references in guides/README/example | unit | `mix test test/threadline/public_surface_contract_test.exs test/threadline/facade_only_references_contract_test.exs` | ✅ (extend) | ⬜ pending |
| API-08 / SC4 | retired names are one-line `@deprecated` delegates with parity tests + matching specs; warnings-as-errors clean | unit + compile | planner-chosen parity test + `MIX_ENV=test mix compile --warnings-as-errors --force` + `mix verify.example` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Row-history bounded-default/cursor test file (API-01/SC1)
- [ ] `Threadline.Page` struct + invariant test (API-03/SC3)
- [ ] Facade-naming test (SC3, D-19)
- [ ] Deprecation parity-test suite (API-08/SC4)
- [ ] Arity-collision compile-warning assertion (D-12)
- [ ] Extensions to `telemetry_registry_contract_test.exs`, `public_surface_contract_test.exs`, `facade_only_references_contract_test.exs`

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
