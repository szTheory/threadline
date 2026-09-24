---
phase: "207"
slug: "gen-triggers-rerun-name-collision-storage-schema-default-doc"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-24"
---

# Phase 207 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `207-RESEARCH.md` §Validation Architecture. There are no REQ-IDs
> (tech-debt closure W1/W2), so the CONTEXT.md decisions D-01..D-13 act as the requirements.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3 local; 1.15 / PostgreSQL 14 on the CI min lane) |
| **Config file** | `test/test_helper.exs` (excludes only `pgbouncer_topology`) |
| **Quick run command** | `bash -c 'cd /Users/jon/projects/threadline && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/capture/trigger_rerun_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/storage_schema_test.exs test/threadline/mix/'` |
| **Full suite command** | `bash -c 'cd /Users/jon/projects/threadline && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test'` |
| **Estimated runtime** | ~20 s for the quick run; a few minutes for the full suite |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Run the quick run command plus the contract batch (`install_test.exs`, `changelog_contract_test.exs`, `release_artifact_contract_test.exs`, `public_surface_contract_test.exs`, `code_walkthrough_doc_contract_test.exs`, `guide_graph_contract_test.exs`, and the `*_doc_contract_test.exs` files for the edited guides)
- **Before `/gsd-verify-work`:** The full suite must be green, and so must the static gates `mix verify.format`, `MIX_ENV=test mix verify.credo`, `MIX_ENV=dev mix verify.dialyzer`, `mix verify.xref_cycles`, and `MIX_ENV=dev mix docs --warnings-as-errors`
- **Max feedback latency:** 60 seconds

---

## Per-Decision Verification Map

The planner fills in the Task IDs when it creates the plans.

| Decision | Behavior | Test Type | Test (file :: case) | RED today? | File Exists | Status |
|---|---|---|---|---|---|---|
| D-01 | Two runs of `--tables posts` → distinct Ecto names, increasing 14-digit versions | file | `gen_triggers_test.exs` :: rerun gets a distinct Ecto name | yes | ❌ W0 | ⬜ pending |
| D-01 | A first run keeps the name `threadline_triggers_posts` / module `ThreadlineTriggersPosts` (pin) | file | `gen_triggers_test.exs` :: first-run name unchanged | no (pin) | ❌ W0 | ⬜ pending |
| D-02 | Two runs → distinct `defmodule` modules; mixed-case table module unchanged | file | `gen_triggers_test.exs` :: rerun gets a distinct module | yes | ❌ W0 | ⬜ pending |
| D-02 | Lookalike tables (`posts_2` vs a `posts` rerun; `a_b` vs `a,b`) → no clash | file | `gen_triggers_test.exs` :: lookalike names | yes | ❌ W0 | ⬜ pending |
| D-01/02 | A legacy `*_threadline_triggers_posts.exs` present → new run takes `_2` | file | `gen_triggers_test.exs` :: legacy migration present | yes | ❌ W0 | ⬜ pending |
| D-03 | SQL text is `CREATE OR REPLACE TRIGGER` | unit | `trigger_sql_storage_schema_test.exs:25` (edit the assertion first) | yes after edit | ✅ | ⬜ pending |
| D-03 | Applying `create_trigger` twice succeeds | DB | `trigger_rerun_test.exs` :: idempotent create | yes (`already exists`) | ❌ W0 | ⬜ pending |
| D-03 | A per-table rerun re-points `tgfoid`; an UPDATE records `changed_from` | DB | `trigger_rerun_test.exs` :: rerun function wins | yes | ❌ W0 | ⬜ pending |
| D-04 | The drift view and coverage still read the swapped trigger | DB | existing `policy_show_mix_test`, `redaction_presenter_catalog_test`, `health_test` (full suite) | no (net) | ✅ | ⬜ pending |
| D-05 | Default-mode `up` drops the orphan per-table function after the trigger, no `CASCADE` | file + unit | `gen_triggers_test.exs` :: orphan drop follows trigger; `trigger_sql_storage_schema_test.exs` :: refute CASCADE | yes | ❌ W0 | ⬜ pending |
| D-05 | Switching from per-table to default removes the orphan function | DB | `trigger_rerun_test.exs` :: orphan removed | yes | ❌ W0 | ⬜ pending |
| D-06 | Rerun-table `down` has no drops; first-run table keeps them; mixed table sets | file | `gen_triggers_test.exs` :: down per table | yes | ❌ W0 | ⬜ pending |
| D-06/07 | Rollback comment present (capture stays on; unredacted rollback case named) | file | `gen_triggers_test.exs` :: same case, stable phrases | yes | ❌ W0 | ⬜ pending |
| D-10/11 | No guide or README claims a default other than `public`; guard flags 4 offenders; non-vacuous | unit (doc) | `storage_schema_test.exs` :: default guard | yes (4 sites) | ✅ extend | ⬜ pending |
| D-12 | Rerun guidance updated (production-checklist:45, domain-reference:52-53, moduledoc) | doc | `=~` assertion on the new rerun phrase | n/a | ❌ optional | ⬜ pending |
| D-13 | CHANGELOG Unreleased shape and planning-vocabulary scan | contract | `changelog_contract_test.exs`, `release_artifact_contract_test.exs` | no (guard) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Security (ASVS L1, V5):** table names go through `StorageSchema.validate!/1` and are quoted with `quote_ident`. The detector uses `Regex.escape/1` on the suffix. Host migration files are only ever regex-scanned, never compiled or evaluated.

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/threadline/gen_triggers_test.exs`: D-01/D-02/D-05/D-06/D-07, RED first
- [ ] `test/threadline/capture/trigger_rerun_test.exs`: D-03/D-05 DB tier, RED first
- [ ] `test/threadline/mix/trigger_migration_test.exs` (optional): pure resolver and detector
- [ ] Extend `test/threadline/storage_schema_test.exs`: D-11 guard, RED against the 4 sites

No framework install needed.

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
