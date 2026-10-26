---
phase: 228
slug: telemetry
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-01
---

# Phase 228 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in); `:telemetry` 1.4.2 (already locked) for the mechanics under test; StreamData for the extended PROP-04 property |
| **Config file** | `test/test_helper.exs`; partition weights `test/partition_weights.txt` (balance only, never correctness) |
| **Quick run command** | `mix test test/threadline/telemetry_registry_contract_test.exs test/threadline/telemetry_raising_handler_test.exs` (final names at planner discretion) |
| **Full suite command** | `mix test` per wave; `mix ci.all` at the phase gate |
| **Estimated runtime** | quick < 30 s; full local suite ~ as measured in 227 (see 227-EVIDENCE.md) |

---

## Sampling Rate

- **After every task commit:** the new or extended test file(s) for that task
- **After every plan wave:** `mix test`
- **Before `/gsd-verify-work`:** `mix ci.all` green and `bin/verify-repo-hygiene` clean
- **Max feedback latency:** 60 seconds for the per-task command

---

## Per-Task Verification Map

Filled by the planner per task (each task's `<automated>` verify). Requirement → test map from 228-RESEARCH.md:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| TELE-01 | export `:completed`/`:failed` with row_count, duration, format; both branches; eager, orchestrator, chunked paths | unit (DB) | `mix test test/threadline/export_test.exs` + orchestrator/controller test files (extended) | ✅ extended | ⬜ pending |
| TELE-02 | purge span start/stop/exception + one `batch_purged` per step; dry run emits none | unit (DB, async:false) | `mix test test/threadline/retention_test.exs` (extended) | ✅ extended | ⬜ pending |
| TELE-03 | runtime allowlist, static scan, raising handler, PROP-04 telemetry surface, D-17 strip | unit + property | `mix test test/threadline/telemetry_registry_contract_test.exs test/threadline/telemetry_raising_handler_test.exs test/threadline/capture/redaction_leak_property_test.exs` | ❌ W0 (2 new) / ✅ extended | ⬜ pending |
| TELE-04 | moduledoc table and `guides/telemetry.md` parity with `__events__/0`; guide registered; repo-query recipe caveats proven | unit (doc parity) | `mix test test/threadline/telemetry_registry_contract_test.exs test/threadline/guide_graph_contract_test.exs` | ❌ W0 / ✅ extended | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/telemetry_registry_contract_test.exs` — allowlist (D-12.1), static scan (D-12.2), doc parity (D-12.3)
- [ ] `test/threadline/telemetry_raising_handler_test.exs` — D-13
- Existing infrastructure (`test/support/telemetry_helpers.ex` `attach_telemetry!/1`, `test/support/leak_oracle.ex` telemetry surfaces) covers the rest; no framework install.

---

## Manual-Only Verifications

All phase behaviors have automated verification (project rule: zero human verification by default).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
