---
phase: "229"
slug: "adopter-api-and-health-additions"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-02"
---

# Phase 229 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) + StreamData properties |
| **Config file** | `mix.exs` aliases (`verify.test`, `verify.test_partitioned`, `ci.all`); `test/test_helper.exs` |
| **Quick run command** | `mix test <single touched test file>` (e.g. `mix test test/threadline/query_test.exs`) |
| **Full suite command** | `mix verify.test` (wave merge) / `mix ci.all` (phase gate) |
| **Estimated runtime** | ~5-30 seconds per file; full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run the single touched test file(s)
- **After every plan wave:** Run `mix verify.test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green; VERIFICATION.md reports suite wall clock before/after (D-28)
- **Max feedback latency:** 60 seconds per task

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| QRY-01 | `limit: n` caps, validates, tiebreak order | unit + property | `mix test test/threadline/query_test.exs` | ✅ extend | ⬜ pending |
| QRY-02 | No-`:limit` behavior unchanged | unit (regression) | `mix test test/threadline/query_test.exs` | ✅ extend | ⬜ pending |
| HLTH-01 | `--strict` severity × strict matrix | integration | `mix test test/threadline/operator_surface/coverage_mix_test.exs` | ✅ extend | ⬜ pending |
| HLTH-02 | `--all-schemas` table/JSON, mutual exclusion | integration | `mix test test/threadline/operator_surface/coverage_mix_test.exs` | ✅ extend | ⬜ pending |
| HLTH-03 | `:unresolved_legacy_keys` finding on pre-0.11 fixture | integration (DB) | `mix test test/threadline/upgrade_backfill_test.exs` | ✅ extend | ⬜ pending |
| HLTH-04 | Docs state malformed `:trigger_capture` raises | doc contract | `mix test test/threadline/health_findings_doc_contract_test.exs` | ✅ extend | ⬜ pending |

Plan task IDs are filled in by the planner/executor; per-task commands map to the rows above.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. A brand-new test file (if the planner splits one out) must get a line in `test/partition_colocate.txt` grouping it with its nearest sibling.

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
