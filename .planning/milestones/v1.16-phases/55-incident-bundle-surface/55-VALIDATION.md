---
phase: 55
slug: incident-bundle-surface
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `test/test_helper.exs` and `examples/threadline_phoenix/test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/investigation_test.exs --max-failures 1` |
| **Example app command** | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs --max-failures 1` |
| **Full suite command** | `mix verify.test` and `mix verify.example` |
| **Estimated runtime** | ~25 seconds for focused checks, longer for full suite |

---

## Sampling Rate

- **After every task commit:** Run the focused command for that task's surface.
- **After Plan 55-01 completes:** Run the focused library suite for `incident_bundle/2` semantics and raw-helper compatibility.
- **After Plan 55-02 completes:** Run the Phoenix request-path proof for `401`, `400`, `404`, and `200`.
- **Before `$gsd-verify-work`:** Run the targeted library proof, the targeted Phoenix proof, then `mix verify.test` and `mix verify.example`.
- **Max feedback latency:** 25 seconds for focused checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 55-01-01 | 01 | 1 | INCIDENT-06 | T-55-01 / T-55-02 | `Threadline.incident_bundle/2` returns `{:ok, bundle}` for existing transactions, preserves ordered linked changes, packages `change_diff`, and keeps raw linked structs reachable. | unit/integration | `mix test test/threadline/investigation_test.exs --max-failures 1` | ✅ | ✅ green |
| 55-01-02 | 01 | 1 | INCIDENT-06 | T-55-01 / T-55-03 | The new bundle contract distinguishes `{:error, :not_found}` from `{:ok, %IncidentBundle{changes: []}}` while `transaction_context/2` and `audit_changes_for_transaction/2` remain backward-compatible. | unit/regression | `mix test test/threadline/investigation_test.exs test/threadline/query_test.exs --max-failures 1` | ✅ | ✅ green |
| 55-02-01 | 02 | 2 | INCIDENT-07 | T-55-04 / T-55-05 / T-55-06 | The Phoenix incident controller uses `Threadline.incident_bundle/2`, keeps auth endpoint-local, maps malformed UUIDs to `400`, missing transactions to `404`, and renders through a dedicated JSON module. | integration | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs --max-failures 1` | ✅ | ✅ green |
| 55-02-02 | 02 | 2 | INCIDENT-07 | T-55-04 / T-55-05 / T-55-06 | The request-path suite proves `401`, `400`, `404`, and `200` outcomes against the real Phoenix router and bundled incident JSON contract. | integration | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Requirement Coverage

| Requirement | Coverage | Automated Proof |
|-------------|----------|-----------------|
| `INCIDENT-06` | Plan `55-01` validates the library contract, existence-aware semantics, diff packaging, ordering, and raw-helper compatibility. | `mix test test/threadline/investigation_test.exs --max-failures 1` and `mix test test/threadline/investigation_test.exs test/threadline/query_test.exs --max-failures 1` |
| `INCIDENT-07` | Plan `55-02` validates the example endpoint migration, curated JSON renderer, and required HTTP status behavior. | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/posts_incident_json_path_test.exs --max-failures 1` |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- Inspect the final incident bundle naming and example JSON wording for clarity so the new library contract reads distinctly from the raw Phase 54 helper shapes.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency <= 30s for focused checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
