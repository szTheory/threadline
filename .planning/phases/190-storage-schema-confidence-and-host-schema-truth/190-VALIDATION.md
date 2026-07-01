---
phase: 190
slug: storage-schema-confidence-and-host-schema-truth
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-01
---

# Phase 190 - Validation Strategy

> Per-phase validation contract for storage-schema and host-schema feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 with real PostgreSQL through `Threadline.Test.Repo`, plus static Markdown/source contracts with `rg`. |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix compile --warnings-as-errors && mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/storage_schema_prefix_contract_test.exs` |
| **Full suite command** | `mix test`; use `mix ci.all` only if closeout needs full local parity beyond targeted storage/host-schema proof. |
| **Estimated runtime** | 30-90 seconds for focused commands; full suite runtime follows current project baseline. |

---

## Sampling Rate

- **After every task commit:** Run the task's automated command from the map below.
- **After every schema/core module edit:** Run `mix compile --warnings-as-errors` before targeted tests.
- **After any later edit to `lib/threadline/storage_schema.ex`:** Rerun `mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs`.
- **After every plan wave:** Run all focused commands for plans completed in that wave plus `mix format --check-formatted`.
- **Before `/gsd:verify-work`:** Run the closing proof bundle in `190-10-PLAN.md` and record any residual broad-suite failures explicitly.
- **Max feedback latency:** Focused task feedback should stay under 90 seconds except real PostgreSQL dual-schema proof, which may exceed that when installing/cleaning schemas.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 190-01-01 | 01 | 1 | SCHEMA-03 | T-190-01/T-190-03 | Invalid storage identifiers fail before generated SQL can be emitted. | unit/source | `mix compile --warnings-as-errors && mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs` | existing | pending |
| 190-01-02 | 01 | 1 | SCHEMA-03 | T-190-01/T-190-02 | Generated migration SQL quotes storage schema identifiers consistently. | source contract | `mix compile --warnings-as-errors && mix test test/threadline/storage_schema_migration_contract_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs` | existing | pending |
| 190-01-03 | 01 | 1 | SCHEMA-03 | T-190-04 | Public docs state generated migrations freeze storage schema at generation time. | doc contract | `mix test test/threadline/readme_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs` | existing | pending |
| 190-02-01 | 02 | 1 | SCHEMA-02 | T-190-05 | Owned schemas cannot force the default Threadline storage prefix. | static/source | `mix compile --warnings-as-errors && bash -lc '! rg -n "@schema_prefix \\"threadline\\"" lib/threadline/capture/audit_transaction.ex lib/threadline/capture/audit_change.ex lib/threadline/semantics/audit_action.ex lib/threadline/governance/evidence_record.ex lib/threadline/governance/export_job.ex lib/threadline/governance/retention_run.ex lib/threadline/governance/saved_view.ex' && mix test test/threadline/storage_schema_prefix_contract_test.exs` | missing W0 | pending |
| 190-02-02 | 02 | 1 | SCHEMA-02 | T-190-05/T-190-06 | Test cleanup and fixtures use explicit storage prefixes after fixed prefixes are removed. | integration support | `mix compile --warnings-as-errors && mix test test/threadline/storage_schema_prefix_contract_test.exs test/threadline/query_test.exs` | missing W0 | pending |
| 190-03-01 | 03 | 2 | SCHEMA-01/SCHEMA-02 | T-190-06/T-190-07 | Core writes and semantic action linkage carry the selected storage prefix. | integration | `mix compile --warnings-as-errors && mix test test/threadline/semantics/audit_action_test.exs test/threadline/audit_transaction_test.exs` | existing | pending |
| 190-03-02 | 03 | 2 | SCHEMA-01/SCHEMA-02 | T-190-07 | Core query joins and preloads read from the selected storage prefix. | integration | `mix compile --warnings-as-errors && mix test test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/export_test.exs` | existing | pending |
| 190-04-01 | 04 | 3 | SCHEMA-01 | T-190-08/T-190-10 | Queued export jobs and cleanup use the configured storage schema contract. | integration | `mix compile --warnings-as-errors && mix test test/threadline/export/orchestrator_test.exs test/threadline/export/cleanup_test.exs` | existing | pending |
| 190-04-02 | 04 | 3 | SCHEMA-01 | T-190-08 | Export downloads keep actor authorization while using configured storage. | controller | `mix compile --warnings-as-errors && mix test test/threadline/operator_surface/controllers/export_controller_test.exs` | existing | pending |
| 190-05-01 | 05 | 2 | SCHEMA-01 | T-190-09/T-190-10 | Retention dry-run and purge target selected storage only. | integration | `mix compile --warnings-as-errors && mix test test/threadline/retention_test.exs` | existing | pending |
| 190-05-02 | 05 | 2 | SCHEMA-01 | T-190-09/T-190-10 | Pruner abandoned-run updates target selected storage only. | integration | `mix compile --warnings-as-errors && mix test test/threadline/retention/pruner_test.exs` | existing | pending |
| 190-06-01 | 06 | 3 | SCHEMA-01/SCHEMA-02 | T-190-11/T-190-12 | Operator saved views, export jobs, and visible Timeline preloads use configured storage. | LiveView/integration | `mix compile --warnings-as-errors && mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs` | existing | pending |
| 190-06-02 | 06 | 3 | SCHEMA-01/SCHEMA-02 | T-190-12 | Operator evidence, retention, actor, and home reads use configured storage without auth changes. | LiveView/integration | `mix compile --warnings-as-errors && mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs` | existing | pending |
| 190-07-01 | 07 | 2 | SCHEMA-04/SCHEMA-03 | T-190-13/T-190-14 | `support.tickets` trigger and coverage paths validate host schema without changing storage schema. | source/catalog | `mix compile --warnings-as-errors && mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/verify_coverage_task_test.exs test/threadline/verify_coverage_policy_test.exs` | existing | pending |
| 190-07-02 | 07 | 2 | SCHEMA-04 | T-190-14 | Continuity readiness works for selected host schema or fails loudly at the edge. | integration | `mix compile --warnings-as-errors && mix test test/threadline/continuity_brownfield_test.exs` | existing | pending |
| 190-08-01 | 08 | 3 | SCHEMA-04 | T-190-15/T-190-16 | Policy CLI validates selected host schema and reports the selected schema in machine output. | Mix task | `mix compile --warnings-as-errors && mix test test/threadline/operator_surface/policy_show_mix_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` | existing | pending |
| 190-08-02 | 08 | 3 | SCHEMA-04 | T-190-15/T-190-16/T-190-17 | Redaction presenter and LiveView inspect selected host schema and link Timeline with `table_schema`. | presenter/LiveView | `mix compile --warnings-as-errors && mix test test/threadline/policy/redaction_presenter_test.exs test/threadline/policy/redaction_presenter_catalog_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs` | existing | pending |
| 190-09-01 | 09 | 4 | SCHEMA-04 | T-190-17 | Timeline, coverage, and export filter links preserve host-table schema identity. | LiveView/source | `mix compile --warnings-as-errors && mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` | existing | pending |
| 190-09-02 | 09 | 4 | SCHEMA-04 | T-190-18 | Docs and row-history contracts separate storage schema from host schema and document duplicate-name limits. | doc contract | `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` | existing | pending |
| 190-10-01 | 10 | 5 | SCHEMA-01/SCHEMA-02 | T-190-19/T-190-20 | Dual-schema fixture installs `audit` and leaves `threadline` sentinels as false-positive traps. | integration support | `mix test test/threadline/storage_schema_integration_test.exs --trace` | missing W0 | pending |
| 190-10-02 | 10 | 5 | SCHEMA-01/SCHEMA-02 | T-190-19/T-190-20 | Capture, query, semantics, evidence, export, and retention use only selected storage. | integration | `mix test test/threadline/storage_schema_integration_test.exs test/threadline/query_test.exs test/threadline/evidence_test.exs test/threadline/export_test.exs test/threadline/export/orchestrator_test.exs test/threadline/retention_test.exs` | missing W0 | pending |
| 190-10-03 | 10 | 5 | SCHEMA-01/SCHEMA-02/SCHEMA-03/SCHEMA-04 | T-190-19/T-190-20/T-190-21 | Final proof reruns storage-schema contracts after later helper edits and covers operator-relevant reads. | closing proof | `mix compile --warnings-as-errors && mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/storage_schema_prefix_contract_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs` | missing W0 | pending |

*Status: pending, green, red, flaky.*

---

## Static Validation Commands

These commands are intentionally separate. A broad single pattern is not enough because each contract protects a different failure mode.

### owned-prefix-contract

```bash
bash -lc 'set -euo pipefail
! rg -n "@schema_prefix \"threadline\"" \
  lib/threadline/capture/audit_transaction.ex \
  lib/threadline/capture/audit_change.ex \
  lib/threadline/semantics/audit_action.ex \
  lib/threadline/governance/evidence_record.ex \
  lib/threadline/governance/export_job.ex \
  lib/threadline/governance/retention_run.ex \
  lib/threadline/governance/saved_view.ex
mix test test/threadline/storage_schema_prefix_contract_test.exs
'
```

### storage-schema-contract

```bash
bash -lc 'set -euo pipefail
mix compile --warnings-as-errors
mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs
'
```

### host-schema-contract

```bash
bash -lc 'set -euo pipefail
mix compile --warnings-as-errors
mix test \
  test/threadline/capture/trigger_sql_storage_schema_test.exs \
  test/threadline/verify_coverage_task_test.exs \
  test/threadline/verify_coverage_policy_test.exs \
  test/threadline/continuity_brownfield_test.exs \
  test/threadline/operator_surface/policy_show_mix_test.exs \
  test/threadline/operator_surface/live/policy_redaction_live_test.exs
'
```

### closing-dual-schema-proof

```bash
bash -lc 'set -euo pipefail
mix compile --warnings-as-errors
mix test \
  test/threadline/storage_schema_test.exs \
  test/threadline/storage_schema_migration_contract_test.exs \
  test/threadline/storage_schema_prefix_contract_test.exs \
  test/threadline/storage_schema_integration_test.exs \
  test/threadline/query_test.exs \
  test/threadline/evidence_test.exs \
  test/threadline/export_test.exs \
  test/threadline/export/orchestrator_test.exs \
  test/threadline/retention_test.exs
'
```

---

## Wave 0 Requirements

- [ ] `test/support/storage_schema_case.ex` - helpers for temporary storage-schema config, explicit repo opts, cleanup, custom-schema install, and sentinel rows.
- [ ] `test/threadline/storage_schema_prefix_contract_test.exs` - static source contract plus representative prefix/preload proof for SCHEMA-02.
- [ ] `test/threadline/storage_schema_integration_test.exs` - real PostgreSQL dual-schema sentinel proof for SCHEMA-01/SCHEMA-02.
- [ ] Extensions to `test/threadline/storage_schema_migration_contract_test.exs` - quoted generated migration and generation-time freeze contracts for SCHEMA-03.
- [ ] Extensions to host-schema tests for `support.tickets`, `--schema=support`, selected redaction, continuity, and Timeline links for SCHEMA-04.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator copy keeps storage schema separate from host schema | SCHEMA-04 | Automated contracts can catch key literals, but copy clarity depends on reading the full flow. | Review README and guides for "Storage schema" vs "Host schema" wording. Confirm `storage_schema: "audit"` is Threadline-owned storage and `--schema=support` or `table_schema=support` is host-table identity. |
| Duplicate host-table limits are not overstated | SCHEMA-04 | The remaining limit, if any, may be narrower than a token check can prove. | Review docs and tests after Plan 09. Confirm schema-qualified row-history keys are used where implemented and any unsupported duplicate-name path is named directly. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing test artifacts
- [x] No watch-mode flags
- [x] `mix compile --warnings-as-errors` included for schema/core module edit plans
- [x] Later `lib/threadline/storage_schema.ex` edits rerun SCHEMA-03 contract tests
- [x] Feedback latency target stated for focused commands and PostgreSQL integration proof
- [x] `nyquist_compliant: true` set in frontmatter
- [x] `status: approved` set in frontmatter

**Approval:** approved 2026-07-01
