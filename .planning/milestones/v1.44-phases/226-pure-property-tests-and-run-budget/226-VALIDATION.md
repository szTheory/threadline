---
phase: 226
slug: pure-property-tests-and-run-budget
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-01
---

# Phase 226 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData 1.4.0 (locked test dep) |
| **Config file** | `test/test_helper.exs` (no StreamData app config — per-call `max_runs:` via `PropertyRuns`, D-09) |
| **Quick run command** | `mix test test/threadline/query/cursors_property_test.exs test/threadline/change_diff_property_test.exs test/threadline/capture/redaction_policy_property_test.exs test/threadline/export_property_test.exs test/threadline/property_scale_contract_test.exs` |
| **Full suite command** | `mix test` (whole, unpartitioned locally); `mix ci.all` before phase gate |
| **Estimated runtime** | quick ~10-20 s at scale 1; full suite per 225-BASELINE.md |

---

## Sampling Rate

- **After every task commit:** Run the touched property/contract file alone (`mix test <file>`)
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green; Flake Detection at scale 5 on phase head (maintainer-granted dispatch, D-12)
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

Filled by the planner per task; requirement → test map from RESEARCH.md:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| PROP-01 | Cursor paging round-trips tie-heavy lists, no dupes/gaps, independent ordering | property, async | `mix test test/threadline/query/cursors_property_test.exs` | ❌ W0 | ⬜ pending |
| PROP-01 (D-05) | DB agrees with the pure model on SQL tiebreak | integration, async:false | `mix test test/threadline/query_test.exs` | ✅ | ⬜ pending |
| PROP-02 | ChangeDiff matches independent oracle over op × before_values | property, async | `mix test test/threadline/change_diff_property_test.exs` | ❌ W0 | ⬜ pending |
| PROP-03 | Redaction-policy validation accepts valid / rejects invalid (incl. D-18 fixes) | property, async | `mix test test/threadline/capture/redaction_policy_property_test.exs` | ❌ W0 | ⬜ pending |
| PROP-05 | Export CSV/JSON round-trip via independent decoder (incl. D-17 bare-CR) | property, async | `mix test test/threadline/export_property_test.exs` | ❌ W0 | ⬜ pending |
| PROP-08 | `THREADLINE_PROPERTY_SCALE` wiring pinned | contract, async | `mix test test/threadline/property_scale_contract_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/property_runs.ex` — PropertyRuns helper (scale multiplier)
- [ ] `test/support/cursor_generators.ex`, `change_fact_generators.ex`, `redaction_policy_generators.ex`, `export_hostile_value_generators.ex` — bias-named generators
- [ ] `test/support/strict_rfc4180.ex` — independent CSV decoder (D-16)
- [ ] Property, contract and generator-coverage test files (net new)
- [ ] Framework install: none — StreamData already locked

---

## Manual-Only Verifications

All phase behaviors have automated verification. Mutation controls (SC-4) and wall-clock before/after (SC-5) are agent-run and recorded in VERIFICATION.md; the scale-5 Flake Detection dispatch needs a maintainer grant (push/dispatch), not human judgment.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
