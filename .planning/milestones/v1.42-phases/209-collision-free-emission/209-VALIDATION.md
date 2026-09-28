---
phase: "209"
slug: "collision-free-emission"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-25"
---

# Phase 209 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3) + StreamData 1.4.0, real PostgreSQL, no SQL Sandbox (by design) |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs` |
| **Full suite command** | `mix verify.test` (phase gate: `mix ci.all`) |
| **Estimated runtime** | ~150 seconds (full suite), a few seconds (quick) |

---

## Sampling Rate

- **After every task commit:** Run the quick command.
- **After every plan wave:** Run `mix verify.test`.
- **Before `/gsd-verify-work`:** `mix ci.all` must be green in the main checkout. The browser lane, if run, has exactly 8 pre-existing screenshot failures; a 9th is a regression.
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

The planner fills in task IDs. This table maps each requirement to the command that proves it. The full map is in `209-RESEARCH.md` § Validation Architecture.

| Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|-----------------|-----------|-------------------|-------------|--------|
| NAME-02 / SC1 | Same-named tables across schemas and 36-byte-prefix pairs each run only their own mask/exclude rules | real-PG via `Ecto.Migrator` | `mix test test/threadline/capture/collision_free_emission_test.exs` | ❌ W0 | ⬜ pending |
| NAME-02 / D-05 | A migration that would move a sibling onto another table's rules raises, with a HINT, and applies nothing | real-PG via `Ecto.Migrator` | same | ❌ W0 | ⬜ pending |
| NAME-03 / SC2 | Regenerating from the 0.9, 0.10.0 or 0.10.2 frozen forms leaves exactly one Threadline trigger per table, with byte-identical names | real-PG | same | ❌ W0 | ⬜ pending |
| NAME-03 / D-08 | `rerun?` matches on the `ON` clause, including the 46-byte prefix case, `public.a_b` vs `a.b`, and unquoted case folding, plus a property test | unit + property | `mix test test/threadline/mix/trigger_migration_test.exs` | ✅ rewrite | ⬜ pending |
| NAME-04 / SC3 | A rollback or drop leaves every other table's trigger enabled. The generated SQL has no `CASCADE` and every identifier is ≤63 bytes | real-PG + generated-SQL | `mix test test/threadline/capture/collision_free_emission_test.exs test/mix/tasks/threadline/gen_triggers_test.exs` | partial | ⬜ pending |
| SC4 / D-09 / D-10 | A truncation NOTICE fails the suite. Positive control, 63-byte negative control, and canary non-zero exit | unit + contract | `mix test test/threadline/capture/notice_guard_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Task IDs (from the plans' verify commands)

| Task | Requirement / Decision | Automated Command |
|------|------------------------|-------------------|
| 209-01-T1 | SC4 / D-09 / D-10 (controls; trigger_rerun 67-byte fix) | `mix test test/threadline/capture/notice_guard_test.exs test/threadline/capture/trigger_rerun_test.exs` then `mix verify.test` |
| 209-01-T2 | SC4 / D-10 (canary, client_min_messages) | `mix test test/threadline/capture/notice_guard_canary_test.exs test/threadline/capture/notice_guard_test.exs test/threadline/zero_skips_contract_test.exs test/threadline/test_structure_contract_test.exs` |
| 209-02-T1 | NAME-03 / D-08 | `mix test test/threadline/mix/trigger_migration_test.exs test/mix/tasks/threadline/gen_triggers_test.exs` |
| 209-02-T2 | NAME-03 / D-08 property | `mix test test/threadline/mix/trigger_migration_property_test.exs test/threadline/capture/naming_property_test.exs test/threadline/mix/trigger_migration_test.exs` |
| 209-03-T1 | NAME-02 / SC1 fresh install | `mix test test/threadline/capture/collision_free_emission_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/capture/trigger_rerun_test.exs` |
| 209-03-T2 | NAME-04 / SC3 / D-01 D-02 D-03 D-04 D-07 | `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/operator_surface/policy_show_mix_test.exs test/threadline/source_size_contract_test.exs` then `mix verify.test` |
| 209-04-T1 | NAME-02 / D-05 raise (+ gen_triggers up-list with guard) | `mix test test/threadline/capture/legacy_function_upgrade_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/mix/tasks/threadline/gen_triggers_test.exs` |
| 209-04-T2 | NAME-02 / NAME-04 upgrade orders (mask + exclude) | `mix test test/threadline/capture/legacy_function_upgrade_test.exs test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/capture/collision_free_emission_test.exs test/threadline/source_size_contract_test.exs` then `mix verify.test` |
| 209-05-T1 | docs / CHANGELOG (D-01 D-02 D-04) | `mix test test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/changelog_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/code_walkthrough_doc_contract_test.exs` |
| 209-05-T2 | D-05 docs | `mix test test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/source_size_contract_test.exs` then `mix verify.test` |
| 209-06-T1 | D-06 advisory | `mix test test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/mix/trigger_migration_test.exs` |
| 209-06-T2 | NAME-03 / SC2 / D-07 | `mix test test/threadline/capture/legacy_trigger_regeneration_test.exs test/mix/tasks/threadline/gen_triggers_test.exs` |
| 209-06-T3 | NAME-04 / D-11 static; phase gate | `mix test test/mix/tasks/threadline/gen_triggers_test.exs` then `mix ci.all` |

---

## Wave 0 Requirements

- [ ] `test/support/notice_guard.ex`, plus the `test/test_helper.exs` attach, `after_suite` and `client_min_messages` assertion
- [ ] `test/support/notice_guard_canary.exs` (run only by explicit path)
- [ ] `test/threadline/capture/notice_guard_test.exs`
- [ ] Fix the deliberate 67-byte `CREATE FUNCTION` in `test/threadline/capture/trigger_rerun_test.exs`, in the same commit as the guard
- [ ] Frozen legacy fixtures for the 0.9, 0.10.0 and 0.10.2 forms (`test/support/legacy_trigger_sql.ex` or `test/fixtures/legacy_trigger_migrations/`)
- [ ] `test/threadline/capture/collision_free_emission_test.exs` (real-PG harness using `Ecto.Migrator.up/down`)

---

## Manual-Only Verifications

All phase behaviors have automated verification (zero human verification by default).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
