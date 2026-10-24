---
phase: "232"
slug: "consolidated-reads-deprecations-and-the-bounded-default"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| **Quick run command** | `mix test test/threadline/row_history_test.exs test/threadline/query_test.exs test/threadline/page_test.exs test/threadline/query/cursors_property_test.exs test/threadline/query/as_of_property_test.exs test/threadline/actor_reads_doc_contract_test.exs test/threadline/deprecation_parity_test.exs test/threadline/facade_naming_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/facade_only_references_contract_test.exs test/threadline/telemetry_registry_contract_test.exs test/threadline/telemetry_doc_contract_test.exs` |
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
| API-01 / SC1 | `row_history/3` defaults to 200, supports explicit bounds and cursor walk, rejects mixed `:limit`/`:cursor`, and retains unbounded `:infinity` behavior | integration (real PG) | `mix test test/threadline/row_history_test.exs test/threadline/query/as_of_property_test.exs` | ✅ `row_history_test.exs`, `as_of_property_test.exs` | ✅ green |
| API-01 / SC2 | Truncation telemetry is registered and leak-checked; unbounded `as_of` behavior remains covered | unit + property | `mix test test/threadline/telemetry_registry_contract_test.exs test/threadline/telemetry_doc_contract_test.exs test/threadline/query/as_of_property_test.exs` | ✅ | ✅ green |
| API-02 | `actor_history/2` and `actor_window/3` docs lead with their distinct return types and cross-link; actor paging and ordering behavior are exercised | doc-contract + integration/property | `mix test test/threadline/actor_reads_doc_contract_test.exs test/threadline/query_test.exs test/threadline/query/cursors_property_test.exs` | ✅ | ✅ green |
| API-03 | Paged reads return `%Threadline.Page{}` with exact empty/full-page/cursor behavior; old page structs are absent and only `timeline/timeline_page` remains paired | unit + integration/property | `mix test test/threadline/page_test.exs test/threadline/query_test.exs test/threadline/query/cursors_property_test.exs test/threadline/investigation_test.exs test/threadline/facade_naming_contract_test.exs` | ✅ | ✅ green |
| API-05 | Hidden helpers are absent from published docs and retired/hidden references are rejected in adopter docs and examples | docs contract | `mix test test/threadline/public_surface_contract_test.exs test/threadline/facade_only_references_contract_test.exs` | ✅ | ✅ green |
| API-08 / SC4 | Retired entry points are deprecated with specs/docs and behavioral parity; compile and example app remain warning-clean | unit + compile + example smoke | `mix test test/threadline/deprecation_parity_test.exs test/threadline/row_history_test.exs && mix compile --warnings-as-errors && mix verify.example` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Row-history bounded-default/cursor behavior (API-01/SC1)
- [x] `Threadline.Page` shape and paging invariants (API-03)
- [x] Facade naming rule (API-03)
- [x] Deprecated API parity and arity split (API-08/SC4)
- [x] Telemetry, public surface, and retired-name documentation contracts (API-01/API-05)

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verification or completed Wave 0 coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all previously missing references
- [x] No watch-mode flags
- [x] Focused test feedback is bounded to approximately 25 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated validation complete; no uncovered API-01/02/03/05/08 behavior found.

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
