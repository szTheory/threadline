---
phase: "212"
slug: "detection-and-adopter-twins"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-26"
---

# Phase 212 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, real PostgreSQL (`Threadline.Test.Repo`, `Threadline.Test.MigrationHarness`, `Threadline.Test.LegacyTriggerSQL`); example app and hex evaluator suites are separate Mix projects |
| **Config file** | `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/health_test.exs` plus the task's new test file(s) |
| **Full suite command** | `mix verify.test` (phase gate: `mix ci.all` + `mix verify.topology` + `mix verify.hex_evaluator` + unscoped `mix verify.example_browser`) |
| **Estimated runtime** | ~60 seconds scoped; full suite about 2 minutes; `ci.all` several minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the files the task touches.
- **After every plan wave:** Run `mix verify.test`. Plans that touch a twin also run `mix verify.example` and/or `mix verify.hex_evaluator`. Plans that touch the PgBouncer path also run `mix verify.topology`.
- **Before `/gsd-verify-work`:** All of the following must pass:
  - `mix ci.all` green, with its browser line at 318 passed / 26 skipped / 0 failed;
  - `mix verify.topology` green;
  - `mix verify.hex_evaluator` (rehearsal mode) green;
  - unscoped `mix verify.example_browser`, with exactly the 8 known screenshot failures and no ninth (D-22).
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

Filled in by the planner from the final plan set (7 plans, waves 1-5; execution is sequential on the main checkout).

| Task | Plan | Wave | Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|------|-------------|----------|-----------|-------------------|-------------|--------|
| 212-01-T1 | 01 | 1 | HLTH-01, HLTH-05 | Finding struct, catalog read, `:capture_trigger_disabled` ('D'/'R', negative 'O'/'A'), telemetry, Finding grouped | real-PG | `mix test test/threadline/health/trigger_findings_test.exs test/threadline/public_surface_contract_test.exs test/threadline/source_size_contract_test.exs` | ❌ W0 (created by task) | ⬜ pending |
| 212-01-T2 | 01 | 1 | HLTH-01, HLTH-05 | `:duplicate_capture_trigger`, D-03 union, LIKE pinned to Naming, schema filter, ordering, adjacency/empty edges | real-PG | `mix test test/threadline/health/trigger_findings_test.exs` | ✅ after T1 | ⬜ pending |
| 212-01-T3 | 01 | 1 | HLTH-05, HLTH-01 | `trigger_coverage/1` excludes 'D'/'R'; zero-grant role reads identical findings; CHANGELOG Breaking | real-PG + `SET LOCAL ROLE` | `mix test test/threadline/health_test.exs test/threadline/health/trigger_findings_non_owner_test.exs test/threadline/changelog_contract_test.exs test/threadline/verify_coverage_task_test.exs` | ❌ W0 (non-owner file created) | ⬜ pending |
| 212-02-T1 | 02 | 2 | HLTH-02, HLTH-03, HLTH-01 | legacy warning on `id`, `:pk_drift` legacy-on-non-id and key mismatch, set equality, byte-exact names | real-PG (LegacyTriggerSQL) | `mix test test/threadline/health/trigger_findings_key_test.exs test/threadline/health/trigger_findings_test.exs` | ❌ W0 (created by task) | ⬜ pending |
| 212-02-T2 | 02 | 2 | HLTH-03 | override-aware expected key; every `:pk_drift` reason; malformed config raises; shared PrimaryKeySQL fragments | real-PG | `mix test test/threadline/health/trigger_findings_key_test.exs test/threadline/capture test/threadline/query/row_key_override_test.exs` | ✅ after T1 | ⬜ pending |
| 212-02-T3 | 02 | 2 | HLTH-04 | `:shared_capture_function` per table, global never flagged, cross-schema, partitions | real-PG | `mix test test/threadline/health/trigger_findings_test.exs test/threadline/health/trigger_findings_key_test.exs` | ✅ | ⬜ pending |
| 212-03-T1 | 03 | 3 | HLTH-06 | `partition_findings/2`; verify_coverage gate, NOT GATED, warnings print only | pure + Mix task in-process | `mix test test/threadline/verify_coverage_policy_test.exs test/threadline/verify_coverage_task_test.exs test/threadline/operator_surface/coverage_mix_test.exs` | ✅ | ⬜ pending |
| 212-03-T2 | 03 | 3 | HLTH-06 | health.coverage FINDINGS text + additive JSON `findings` | Mix task | `mix test test/threadline/operator_surface/coverage_mix_test.exs test/threadline/verify_coverage_task_test.exs` | ✅ | ⬜ pending |
| 212-03-T3 | 03 | 3 | HLTH-06 | OS-level exit status 1/0 via System.cmd; config errors as Mix.Error | Mix task subprocess | `mix test test/threadline/verify_coverage_task_test.exs test/threadline/operator_surface/coverage_mix_test.exs test/threadline/verify_coverage_policy_test.exs` | ✅ | ⬜ pending |
| 212-05-T1 | 05 | 3 | TWIN-01 | example fixtures + generated trigger migration + suite-scoped up/down; composite round trip | example ExUnit | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/shape_fixtures_round_trip_test.exs` | ❌ W0 (created by task) | ⬜ pending |
| 212-05-T2 | 05 | 3 | TWIN-01 | every shape round-trips; TWIN edges; no fixture findings | example suite | `mix verify.example` | ✅ after T1 | ⬜ pending |
| 212-05-T3 | 05 | 3 | TWIN-01 | regenerate-diff contract (AST, version-stripped name, non-vacuous control) | example ExUnit | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/shape_fixtures_migration_contract_test.exs` | ❌ W0 (created by task) | ⬜ pending |
| 212-04-T1 | 04 | 4 | HLTH-01 | findings through PgBouncer, owner and zero-grant role | pgbouncer_topology lane | `MIX_ENV=test DB_HOST=localhost DB_PORT=5433 THREADLINE_TOPOLOGY_BOOTSTRAP=1 mix run priv/ci/topology_bootstrap.exs && MIX_ENV=test DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix verify.topology` (or BLOCKED-INFRA recorded) | ✅ (extends existing) | ⬜ pending |
| 212-04-T2 | 04 | 4 | HLTH-06, HLTH-01 | CHANGELOG Added, guides, code-list doc contract | doc contract | `mix test test/threadline/health_findings_doc_contract_test.exs test/threadline/production_checklist_doc_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/guide_graph_contract_test.exs` | ❌ W0 (created by task) | ⬜ pending |
| 212-06-T1 | 06 | 4 | TWIN-01 | evaluator fixtures, packaged-generator migration, composite round trip | hex evaluator lane | `mix verify.hex_evaluator` | ❌ W0 (created by task) | ⬜ pending |
| 212-06-T2 | 06 | 4 | TWIN-01 | every shape, no findings, packaged regenerate-diff contract | hex evaluator lane | `mix verify.hex_evaluator` | ✅ after T1 | ⬜ pending |
| 212-07-T1 | 07 | 5 | all | ci.all (browser 318/26/0), PgBouncer lane | phase gate | `mix ci.all` + topology commands | ✅ | ⬜ pending |
| 212-07-T2 | 07 | 5 | all | hex evaluator, unscoped browser (exactly 8 known failures), docs build, vocabulary scan | phase gate | `mix verify.hex_evaluator && MIX_ENV=dev mix docs --warnings-as-errors`; `mix verify.example_browser` | ✅ | ⬜ pending |

Requirement coverage: HLTH-01 (01, 02, 04), HLTH-02 (02), HLTH-03 (02), HLTH-04 (02), HLTH-05 (01), HLTH-06 (03, 04), TWIN-01 (05, 06), gate (07).

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Every Wave 0 file is created by the task that first needs it (tracer-first), so no separate scaffold plan exists:

- [ ] `test/threadline/health/trigger_findings_test.exs` (212-01-T1) and `test/threadline/health/trigger_findings_key_test.exs` (212-02-T1) — HLTH-01..05
- [ ] `test/threadline/health/trigger_findings_non_owner_test.exs` (212-01-T3) — HLTH-01 non-owner
- [ ] PgBouncer-tagged test inside `test/threadline/pgbouncer_topology_test.exs` (212-04-T1) — HLTH-01 PgBouncer
- [ ] Mix task tests extend `test/threadline/verify_coverage_task_test.exs`, `test/threadline/verify_coverage_policy_test.exs`, `test/threadline/operator_surface/coverage_mix_test.exs` (212-03) — HLTH-06
- [ ] `test/threadline/health_findings_doc_contract_test.exs` (212-04-T2) — doc alignment
- [ ] Example app: `priv/shape_fixtures/migrations/`, round-trip and regenerate-diff contract tests (212-05) — TWIN-01
- [ ] Hex evaluator: fixture migrations, round-trip and contract tests (212-06) — TWIN-01

---

## Manual-Only Verifications

All phase behaviors have automated verification (zero human verification by default).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
