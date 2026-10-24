---
phase: "224"
slug: "capture-and-bench-fixes"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-30"
---

# Phase 224 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + ExUnitProperties (`stream_data ~> 1.4`, test-only) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/capture/trigger_rerun_test.exs test/threadline/capture/trigger_rerun_property_test.exs` |
| **Full suite command** | `mix verify.test` (phase gate: `mix ci.all`) |
| **Estimated runtime** | quick ~30 seconds; full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick command above (plus `mix verify.bench_compile` for bench tasks)
- **After every plan wave:** Run `mix verify.test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green, and both mutation controls (D-11, D-16) must be recorded in VERIFICATION.md
- **Max feedback latency:** ~60 seconds for the quick command

---

## Per-Task Verification Map

To be filled by the planner/executor per task. Requirement → test map (from RESEARCH.md §Validation Architecture):

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| CAPT-01 | First-run `down` unconditionally emits the guarded drop, no CASCADE | unit (exact output) | `mix test test/mix/tasks/threadline/gen_triggers_test.exs` | ✅ (assertions updated per D-12) | ⬜ pending |
| CAPT-02 | Deterministic two-migration repro, partial and full-chain rollback | integration (DB) | `mix test test/threadline/capture/trigger_rerun_test.exs` | ❌ W0 | ⬜ pending |
| CAPT-02 | Property: 1–4 run sequences, zero orphans after full rollback | property (DB, max_runs 20) | `mix test test/threadline/capture/trigger_rerun_property_test.exs` | ❌ W0 | ⬜ pending |
| SUITE-05 | `bench/` compiles bare | CI step + contract test | `mix verify.bench_compile` | ❌ W0 | ⬜ pending |
| SUITE-06 | Suite wall clock before/after vs `dd780e68` | measurement | `time mix verify.test` (+ CI run IDs) | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/capture/trigger_rerun_test.exs`: new `describe` block plus an `apply_down!/1` helper (or reuse `MigrationHarness`)
- [ ] `test/threadline/capture/trigger_rerun_property_test.exs`: new file
- [ ] `test/support/trigger_run_generators.ex`: new generator
- [ ] Bench `preferred_envs` contract test (D-16)

---

## Manual-Only Verifications

None. All phase behaviors have automated verification. The mutation controls (D-11, D-16) are agent-run and recorded in VERIFICATION.md, not human steps.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
