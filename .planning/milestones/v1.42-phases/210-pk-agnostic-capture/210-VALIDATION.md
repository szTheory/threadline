---
phase: "210"
slug: "pk-agnostic-capture"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-25"
---

# Phase 210 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, real-PG tests per Phase 209 patterns (`Threadline.Test.Repo`, `Threadline.Test.MigrationHarness`, `Threadline.Test.LegacyTriggerSQL`) |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix test test/threadline/capture/` |
| **Full suite command** | `mix verify.test` (phase gate: `mix ci.all`) |
| **Estimated runtime** | ~60 seconds scoped; full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/capture/` (plus any task-specific files)
- **After every plan wave:** Run `mix verify.test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green; `bench/pk_capture_bench.exs` run and before/after numbers recorded (D-07)
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 210-01-T1 | 01 | 1 | CAP-01 | T-210-01, T-210-03 | DO block resolves the key from pg_index; identifiers are validated literals; rerun detection still parses | real-PG migration (tracer) | `mix test test/threadline/capture/trigger_pk_shapes_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs` | ❌ W0 (created in task) | ⬜ pending |
| 210-01-T2 | 01 | 1 | CAP-01, CAP-02 | T-210-02 | Every key column stored; INCLUDE excluded; PK position order | real-PG | `mix test test/threadline/capture/trigger_pk_shapes_test.exs` | ❌ W0 | ⬜ pending |
| 210-01-T3 | 01 | 1 | CAP-06 | T-210-02 | No catalog lookup or baked key literal in any function body | static invariant + full suite | `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/operator_surface/policy_show_mix_test.exs test/threadline/policy/ test/threadline/source_size_contract_test.exs` then `mix verify.test` | ❌ W0 | ⬜ pending |
| 210-02-T1 | 02 | 2 | CAP-04 | T-210-06, T-210-07 | Frozen 0.10.2 SQL on an id table stores identical output | real-PG (frozen SQL, tracer) | `mix test test/threadline/capture/legacy_trigger_pk_fallback_test.exs` | ❌ W0 | ⬜ pending |
| 210-02-T2 | 02 | 2 | CAP-04 | T-210-05 | Unresolvable key stores `{}`; host write never fails; regeneration swaps args in place | real-PG | `mix test test/threadline/capture/legacy_trigger_pk_fallback_test.exs test/threadline/capture/legacy_trigger_regeneration_test.exs test/threadline/capture/trigger_pk_shapes_test.exs` | ❌ W0 | ⬜ pending |
| 210-03-T1 | 03 | 3 | CAP-03 | T-210-10, T-210-11 | PK-less table refused at migrate time with paste-ready HINT; nothing applied | real-PG migration (tracer) | `mix test test/threadline/capture/trigger_migrate_time_errors_test.exs` | ❌ W0 | ⬜ pending |
| 210-03-T2 | 03 | 3 | CAP-03 | T-210-10 | Key type allowlist with domain resolution; legacy trigger keeps capturing | real-PG migration | `mix test test/threadline/capture/trigger_migrate_time_errors_test.exs test/threadline/capture/legacy_trigger_pk_fallback_test.exs` | ❌ W0 | ⬜ pending |
| 210-03-T3 | 03 | 3 | CAP-05 | T-210-08, T-210-09 | Detected key in mask/exclude refused; DO-block list pinned to function rules | real-PG migration + text + full suite | `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/operator_surface/policy_show_mix_test.exs test/threadline/policy/ test/threadline/source_size_contract_test.exs` then `mix verify.test` | ❌ W0 | ⬜ pending |
| 210-04-T1 | 04 | 4 | CONF-01 | T-210-12 | Declared override captured end to end; loader exposes primary_key | real-PG migration (tracer) | `mix test test/threadline/capture/trigger_pk_override_test.exs test/threadline/capture/trigger_migrate_time_errors_test.exs` | ❌ W0 | ⬜ pending |
| 210-04-T2 | 04 | 4 | CONF-01, CAP-05 | T-210-12, T-210-14, T-210-15 | Raw-value validation: identifiers validated before SQL; redaction overlap refused | unit | `mix test test/threadline/capture/trigger_capture_config_test.exs test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/policy/` | ❌ W0 | ⬜ pending |
| 210-04-T3 | 04 | 4 | CONF-01 | T-210-13 | Override refused unless an exact qualifying unique index matches; per-index reasons | real-PG migration + full suite | `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/policy/ test/threadline/source_size_contract_test.exs` then `mix verify.test` | ❌ W0 | ⬜ pending |
| 210-05-T1 | 05 | 5 | CAP-06 | T-210-16, T-210-17 | Per-row overhead ≤ 1.10x of 0.10.2; sensitivity control ≥ 1.25x | benchmark (executor-run, recorded) + fixture pin | `cd bench && mix deps.get && MIX_ENV=test mix run pk_capture_bench.exs` and `mix test test/threadline/capture/legacy_trigger_pk_fallback_test.exs` | ❌ W0 | ⬜ pending |
| 210-05-T2 | 05 | 5 | CONF-01 | T-210-18 | Docs name config/config.exs for the override | doc contract | `mix test test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/public_surface_contract_test.exs` | ✅ | ⬜ pending |
| 210-05-T3 | 05 | 5 | all | — | Phase gate | full gate | `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/capture/trigger_pk_shapes_test.exs` — CAP-01, CAP-02 (210-01-T1/T2)
- [ ] `test/threadline/capture/trigger_migrate_time_errors_test.exs` — CAP-03, CAP-05 (210-03); `test/threadline/capture/trigger_pk_override_test.exs` — CONF-01 migrate-time half (210-04)
- [ ] `test/threadline/capture/legacy_trigger_pk_fallback_test.exs` (reuses and extends `Threadline.Test.LegacyTriggerSQL`) — CAP-04 (210-02)
- [ ] `bench/pk_capture_bench.exs` + `bench/fixtures/threadline_capture_changes_v0_10_2.sql` — CAP-06 (210-05-T1)
- [ ] `test/threadline/capture/trigger_body_invariants_test.exs` over `$threadline_trigger$` bodies — CAP-06 (210-01-T3)
- [ ] `test/threadline/capture/trigger_capture_config_test.exs` (new; no config test file existed) — CONF-01 (210-04-T2)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Benchmark within noise of 0.10.x | CAP-06 | Timing is not CI-gated (noisy); executor runs it and records numbers | `cd bench && MIX_ENV=test mix run pk_capture_bench.exs`; recorded in `bench/baselines/pk_capture_bench.md` and 210-05-SUMMARY.md, copied into phase verification |

*The benchmark is run by the executor, not a human (zero human verification by default).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
