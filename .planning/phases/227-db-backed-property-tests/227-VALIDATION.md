---
phase: 227
slug: db-backed-property-tests
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-01
---

# Phase 227 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData (ExUnitProperties), already a dependency since phase 226 |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix test test/threadline/capture/redaction_leak_property_test.exs test/threadline/query/as_of_property_test.exs test/threadline/retention/cutoff_property_test.exs` |
| **Full suite command** | `mix test` (unscaled); `THREADLINE_PROPERTY_SCALE=5 mix test` (scaled, Flake Detection equivalent) |
| **Estimated runtime** | ~30 seconds for the quick run; full suite is measured per D-23 |

---

## Sampling Rate

- **After every task commit:** run the touched property or example test file (`mix test <file>`), plus one `--repeat-until-failure 20` pass for a new property file (D-27)
- **After every plan wave:** run `mix test` (full unscaled suite) to catch suite-order effects
- **Before `/gsd-verify-work`:** `THREADLINE_PROPERTY_SCALE=5 mix test` green once, plus the mutation-control runner for every control in D-12/D-16/D-21
- **Max feedback latency:** 60 seconds for per-task runs

---

## Per-Task Verification Map

Filled in by the planner and the executor from the PLAN.md task IDs.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 227-01-xx | 01 | 1 | PROP-04/06/07 (harness) | — | N/A | contract | `mix test test/threadline/property_scale_contract_test.exs` | ✅ | ⬜ pending |
| 227-0x-xx | — | 2 | PROP-04 | T-227 (V9 data protection) | redacted plaintext never in stored change, diff, or export | property (DB) | `mix test test/threadline/capture/redaction_leak_property_test.exs` | ❌ W0 | ⬜ pending |
| 227-0x-xx | — | 2 | PROP-06 | — | N/A | property (DB) | `mix test test/threadline/query/as_of_property_test.exs` | ❌ W0 | ⬜ pending |
| 227-0x-xx | — | 2 | PROP-07 | — | survivors at or after cutoff unchanged | property (DB) | `mix test test/threadline/retention/cutoff_property_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/db_property.ex`: shared per-iteration harness (D-01/D-02)
- [ ] `test/support/leak_oracle.ex`: PROP-04 detection module (D-10)
- [ ] generator modules for redaction leak, row history, and retention cutoff (D-03)
- [ ] the new `test/threadline/retention/` directory
- [ ] the `property_scale_contract_test.exs` extension (D-06), landed before or with the first DataCase property file

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
