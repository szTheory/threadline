---
phase: 190-storage-schema-confidence-and-host-schema-truth
reviewed: 2026-07-01T23:24:29Z
depth: standard
files_reviewed: 67
files_reviewed_list:
  - README.md
  - guides/domain-reference.md
  - guides/getting-started-saas.md
  - guides/operator-surface.md
  - lib/mix/tasks/threadline.policy.show.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_change.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/capture/migration.ex
  - lib/threadline/continuity.ex
  - lib/threadline/evidence.ex
  - lib/threadline/export/cleanup_task.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/governance/evidence_record.ex
  - lib/threadline/governance/export_job.ex
  - lib/threadline/governance/migration.ex
  - lib/threadline/governance/retention_run.ex
  - lib/threadline/governance/saved_view.ex
  - lib/threadline/investigation.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/policy/redaction_presenter.ex
  - lib/threadline/query.ex
  - lib/threadline/retention.ex
  - lib/threadline/retention/pruner.ex
  - lib/threadline/semantics/audit_action.ex
  - lib/threadline/semantics/migration.ex
  - lib/threadline/storage_schema.ex
  - test/support/data_case.ex
  - test/support/storage_schema_case.ex
  - test/threadline/audit_transaction_test.exs
  - test/threadline/capture/trigger_sql_storage_schema_test.exs
  - test/threadline/continuity_brownfield_test.exs
  - test/threadline/evidence_test.exs
  - test/threadline/export/cleanup_test.exs
  - test/threadline/export/orchestrator_test.exs
  - test/threadline/export_test.exs
  - test/threadline/getting_started_saas_doc_contract_test.exs
  - test/threadline/investigation_test.exs
  - test/threadline/operator_surface/controllers/export_controller_test.exs
  - test/threadline/operator_surface/coverage_doc_contract_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/live/evidence_live_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
  - test/threadline/operator_surface/live/policy_redaction_live_test.exs
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/operator_surface/live/start_live_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/policy_show_doc_contract_test.exs
  - test/threadline/operator_surface/policy_show_mix_test.exs
  - test/threadline/policy/redaction_presenter_test.exs
  - test/threadline/query_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/retention/pruner_test.exs
  - test/threadline/retention_test.exs
  - test/threadline/semantics/audit_action_test.exs
  - test/threadline/storage_schema_integration_test.exs
  - test/threadline/storage_schema_migration_contract_test.exs
  - test/threadline/storage_schema_prefix_contract_test.exs
  - test/threadline/storage_schema_test.exs
  - test/threadline/verify_coverage_task_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 190: Code Review Report

**Reviewed:** 2026-07-01T23:24:29Z
**Depth:** standard
**Files Reviewed:** 67
**Status:** issues_found

## Summary

Reviewed the explicit Phase 190 scope for storage-schema confidence, host-schema separation, Ecto prefix use, SQL identifier safety, background export drift, operator authorization boundaries, and test blind spots. The prompt's `files_reviewed_expected` says 66, but the explicit file list contains 67 paths; all 67 were reviewed.

The implementation improves prefix propagation in most query and governance paths, but two correctness defects remain: storage schema validation accepts invalid values that can route data into the wrong schema, and queued exports do not carry their storage schema into the background worker.

## Critical Issues

### CR-01: BLOCKER - Storage schema validation accepts `nil` and overlong PostgreSQL identifiers

**File:** `lib/threadline/storage_schema.ex:31`

**Issue:** `validate!/1` treats every atom as a schema by calling `Atom.to_string/1`, so `StorageSchema.get(storage_schema: nil)` returns `"nil"` instead of rejecting or defaulting. The same validator also accepts identifiers longer than PostgreSQL's 63-byte identifier limit at lines 33-37. I confirmed locally that `mix run --no-start -e 'IO.inspect(Threadline.StorageSchema.get(storage_schema: nil)); IO.inspect(Threadline.StorageSchema.get(storage_schema: String.duplicate("a", 64)))'` prints `"nil"` and the 64-character string.

This is a data-isolation bug: callers that pass through a nullable config value can silently read/write schema `"nil"`, and overlong quoted identifiers can be truncated by PostgreSQL, making two distinct configured schema names collide or fail differently between generated DDL and Ecto prefix calls.

**Fix:**
```elixir
@max_identifier_bytes 63

def validate!(nil), do: invalid!(nil)
def validate!(value) when is_boolean(value), do: invalid!(value)
def validate!(value) when is_atom(value), do: value |> Atom.to_string() |> validate!()

def validate!(value) when is_binary(value) do
  value = String.trim(value)

  if Regex.match?(@identifier, value) and byte_size(value) <= @max_identifier_bytes do
    value
  else
    invalid!(value)
  end
end

defp invalid!(value) do
  raise ArgumentError,
        "Threadline storage schema must be a non-empty PostgreSQL identifier " <>
          "matching #{@identifier.source} and at most #{@max_identifier_bytes} bytes, got: #{inspect(value)}"
end
```

Add tests for `storage_schema: nil`, booleans, and 64-byte identifiers.

### CR-02: BLOCKER - Queued exports lose the selected storage schema before the worker runs

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:279`

**Issue:** The LiveViews insert export jobs using the currently selected storage schema, but enqueue only `job.id` (`timeline_live.ex:288`, `export_status_live.ex:73`). The queue adapters then call `Threadline.Export.Orchestrator.run(job_id)` without schema context, and `Orchestrator.run/2` re-resolves `StorageSchema.get(opts)` from the worker's current application config (`lib/threadline/export/orchestrator.ex:19`).

That means a job queued under `"audit"` can later be fetched and completed in `"threadline"` if the worker starts on a node with different config, after a deploy/config flip, or where the same UUID exists in both schemas. The existing orchestrator test only flips config after `Orchestrator.run/2` has already captured the schema; it does not cover drift between enqueue and worker start.

**Fix:**
```elixir
storage_schema = StorageSchema.get()
storage_opts = StorageSchema.repo_opts(storage_schema: storage_schema)
job = repo.insert!(job, storage_opts)

case adapter.enqueue(job.id, storage_schema: storage_schema) do
  :ok -> ...
end
```

Then update the queue behaviour/adapters so Task and Oban persist and pass that value:

```elixir
Threadline.Export.Orchestrator.run(job_id, storage_schema: storage_schema)

# Oban args should include both values:
worker_mod.new(%{job_id: job_id, storage_schema: storage_schema}, queue: queue)
```

Add a regression test where config changes after enqueue but before `perform/1`/Task execution; the worker must still fetch and export from the schema used when the job was created.

## Warnings

### WR-01: WARNING - Alternate-schema test fixture does not prove generated migration constraints

**File:** `test/support/storage_schema_case.ex:80`

**Issue:** `ensure_storage_schema!/2` creates alternate storage tables with `CREATE TABLE ... (LIKE "threadline"."table" INCLUDING ALL)` instead of applying the generated capture/semantics/governance migrations for that storage schema. PostgreSQL `LIKE` does not copy foreign key constraints, so tests using the `"audit"` fixture can pass even if generated migrations point a foreign key at the wrong schema or omit a required cross-table constraint.

This weakens the exact storage-schema confidence Phase 190 is trying to establish: the suite can verify query prefixing while missing migration-level isolation mistakes.

**Fix:** Build alternate storage schemas in tests through the same generated migration SQL that hosts receive, or explicitly assert `pg_constraint` rows for the important schema-local FKs, especially `audit_changes.transaction_id -> audit_transactions.id` and `audit_transactions.action_id -> audit_actions.id`, in each configured storage schema.

---

_Reviewed: 2026-07-01T23:24:29Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
