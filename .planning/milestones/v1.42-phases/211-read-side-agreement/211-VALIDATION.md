---
phase: "211"
slug: "read-side-agreement"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-25"
---

# Phase 211 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, `Threadline.DataCase`, real PostgreSQL with no Ecto sandbox (triggers fire at the DB level), `async: false` |
| **Config file** | `config/test.exs` (`Threadline.Test.Repo`, database `threadline_test`) |
| **Quick run command** | `mix test test/threadline/query/ test/threadline/query_test.exs` plus any task-specific files |
| **Full suite command** | `mix verify.test` (phase gate: `mix ci.all`) |
| **Estimated runtime** | ~60 seconds scoped; the full suite takes several minutes |

---

## Sampling Rate

- **After every task commit:** run the quick run command, scoped to the files the task touched
- **After every plan wave:** run `mix verify.test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green. Never run playwright directly.
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

*The planner fills in one row per task. Every task needs an `<automated>` command.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 211-01-T1 | 01 | 1 | READ-01 | T-211-01, T-211-03 | Whole-map = on PostgreSQL-rendered key; nil rejected pre-query | real-PG integration | `mix test test/threadline/query/row_key_read_test.exs` | ❌ W0 (created by task) | ⬜ pending |
| 211-01-T2 | 01 | 1 | READ-01 | T-211-04, T-211-17 | as_of/row_history paths rewired; dropped-table history readable via fallback type map; unmappable type raises; drawer rescues ArgumentError | real-PG integration | `mix test test/threadline/query/row_key_read_test.exs test/threadline/query_test.exs test/threadline/investigation_test.exs` | ✅ | ⬜ pending |
| 211-01-T3 | 01 | 1 | READ-01 | — | Existing fake-schema suites read via fallback map, no fixture tables, no skips | full suite | `mix verify.test` | ✅ | ⬜ pending |
| 211-02-T1 | 02 | 2 | READ-02 | T-211-07 | Composite keys never match siblings or subsets; dropped composite (bigint, uuid) table stays readable | real-PG integration | `mix test test/threadline/query/row_key_composite_test.exs` | ❌ W0 | ⬜ pending |
| 211-02-T2 | 02 | 2 | READ-02, CONF-01 | T-211-06 | Eager D-03 errors; no atomization of caller keys; override columns | unit (async, no DB) + real-PG | `mix test test/threadline/query/row_key_validation_test.exs test/threadline/query/row_key_override_test.exs` | ❌ W0 | ⬜ pending |
| 211-02-T3 | 02 | 2 | READ-02, READ-03 | T-211-08 | Type matrix byte-parity under DateStyle; mixed eras; sentinels never match | real-PG integration | `mix test test/threadline/query/row_key_types_test.exs test/threadline/query/row_key_legacy_test.exs` | ❌ W0 | ⬜ pending |
| 211-03-T1 | 03 | 3 | IDX-01 | T-211-12 | EXPLAIN (seqscan off, SET LOCAL) names the index for history | real-PG EXPLAIN | `mix test test/threadline/query/row_history_index_explain_test.exs` | ❌ W0 | ⬜ pending |
| 211-03-T2 | 03 | 3 | IDX-01 | T-211-10 | Install template creates index in configured schema; as_of/row_history_query EXPLAIN | contract + real-PG | `mix test test/threadline/storage_schema_migration_contract_test.exs test/threadline/query/row_history_index_explain_test.exs` | ✅ | ⬜ pending |
| 211-03-T3 | 03 | 3 | IDX-01 | T-211-11 | Generator: CONCURRENTLY, no DDL txn, rerun-safe, qualified DROP | Mix task + real-PG | `mix test test/mix/tasks/threadline/gen_row_history_index_test.exs test/threadline/public_surface_contract_test.exs` | ❌ W0 | ⬜ pending |
| 211-04-T1 | 04 | 4 | READ-04 | T-211-14 | No row link for composite/{}/{"id":null} keys | LiveView render | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ | ⬜ pending |
| 211-04-T2 | 04 | 4 | READ-02, IDX-01 | T-211-16 | Docs and doc contracts aligned; no planning IDs shipped | doc contract | `mix test test/threadline/audit_indexing_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs` | ✅ | ⬜ pending |
| 211-04-T3 | 04 | 4 | CONF-01 (all) | — | Phase gate | full gate | `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Row-key read tests (`test/threadline/query/row_key_{read,composite,validation,override,types,legacy}_test.exs`) for READ-01, READ-02, READ-03 and CONF-01 (read half). The pure-validation cases need no DB.
- [ ] `test/mix/tasks/threadline/gen_row_history_index_test.exs` for the IDX-01 generator
- [ ] An EXPLAIN test (with `enable_seqscan = off`) for IDX-01 / D-12
- [ ] Extend `test/threadline/storage_schema_migration_contract_test.exs` with the new install index (D-09)
- [ ] Extend the transaction LiveView render test for READ-04 / D-08

---

## Manual-Only Verifications

*None. All phase behaviors have automated verification (zero human verification by default).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
