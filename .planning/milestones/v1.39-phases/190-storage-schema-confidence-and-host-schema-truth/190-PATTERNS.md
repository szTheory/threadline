# Phase 190: Storage Schema Confidence and Host-Schema Truth - Pattern Map

**Mapped:** 2026-07-01
**Files analyzed:** 74 likely new/modified files
**Analogs found:** 74 / 74

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/storage_schema.ex` | utility | transform | `lib/threadline/storage_schema.ex` | exact |
| `lib/threadline/capture/migration.ex` | migration generator | file-I/O / transform | `lib/threadline/capture/trigger_sql.ex` | exact |
| `lib/threadline/semantics/migration.ex` | migration generator | file-I/O / transform | `lib/threadline/capture/trigger_sql.ex` | exact |
| `lib/threadline/governance/migration.ex` | migration generator | file-I/O / transform | `lib/threadline/capture/trigger_sql.ex` | exact |
| `lib/threadline/capture/trigger_sql.ex` | SQL generator | transform | `lib/threadline/capture/trigger_sql.ex` | exact |
| `lib/mix/tasks/threadline.install.ex` | Mix task | file-I/O | `lib/mix/tasks/threadline.install.ex` | exact |
| `lib/mix/tasks/threadline.gen.triggers.ex` | Mix task | file-I/O / transform | `lib/mix/tasks/threadline.gen.triggers.ex` | exact |
| `lib/threadline/capture/audit_transaction.ex` | model | CRUD | `lib/threadline/capture/audit_change.ex` | exact |
| `lib/threadline/capture/audit_change.ex` | model | CRUD | `lib/threadline/capture/audit_transaction.ex` | exact |
| `lib/threadline/semantics/audit_action.ex` | model | CRUD | `lib/threadline/capture/audit_transaction.ex` | exact |
| `lib/threadline/governance/evidence_record.ex` | model | CRUD | `lib/threadline/governance/export_job.ex` | exact |
| `lib/threadline/governance/export_job.ex` | model | CRUD / batch | `lib/threadline/governance/retention_run.ex` | exact |
| `lib/threadline/governance/retention_run.ex` | model | CRUD / batch | `lib/threadline/governance/export_job.ex` | exact |
| `lib/threadline/governance/saved_view.ex` | model | CRUD | `lib/threadline/governance/export_job.ex` | exact |
| `lib/threadline.ex` | facade | request-response | `lib/threadline.ex` | exact |
| `lib/threadline/audit.ex` | service | CRUD / transaction | `lib/threadline/evidence.ex` | role-match |
| `lib/threadline/query.ex` | service | request-response / CRUD | `lib/threadline/query.ex` | exact |
| `lib/threadline/evidence.ex` | service | CRUD | `lib/threadline/evidence.ex` | exact |
| `lib/threadline/export.ex` | service | streaming / file-I/O | `lib/threadline/export.ex` | exact |
| `lib/threadline/export/orchestrator.ex` | service | batch / file-I/O | `lib/threadline/export/orchestrator.ex` | exact |
| `lib/threadline/export/cleanup_task.ex` | service | batch / file-I/O | `lib/threadline/export/cleanup_task.ex` | exact |
| `lib/threadline/retention.ex` | service | batch / destructive CRUD | `lib/threadline/retention.ex` | exact |
| `lib/threadline/retention/pruner.ex` | service | event-driven / batch | `lib/threadline/retention/pruner.ex` | exact |
| `lib/threadline/health.ex` | service | request-response / catalog query | `lib/threadline/health.ex` | exact |
| `lib/threadline/health/coverage_schemas.ex` | utility | validation / catalog query | `lib/threadline/health/coverage_schemas.ex` | exact |
| `lib/threadline/policy/redaction_presenter.ex` | presenter/service | transform / catalog query | `lib/threadline/policy/redaction_presenter.ex` | exact |
| `lib/mix/tasks/threadline.health.coverage.ex` | Mix task | request-response / catalog query | `lib/mix/tasks/threadline.verify_coverage.ex` | exact |
| `lib/mix/tasks/threadline.verify_coverage.ex` | Mix task | request-response / catalog query | `lib/mix/tasks/threadline.health.coverage.ex` | exact |
| `lib/mix/tasks/threadline.policy.show.ex` | Mix task | request-response / catalog query | `lib/mix/tasks/threadline.health.coverage.ex` | role-match |
| `lib/threadline/continuity.ex` | service | request-response / catalog query | `lib/threadline/health.ex` | role-match |
| `lib/threadline/operator_surface/live/coverage_live.ex` | LiveView | event-driven / request-response | `lib/threadline/operator_surface/live/coverage_live.ex` | exact |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | LiveView | event-driven / request-response | `lib/threadline/operator_surface/live/coverage_live.ex` | role-match |
| `lib/threadline/operator_surface/live/timeline_live.ex` | LiveView | event-driven / CRUD | `lib/threadline/operator_surface/live/timeline_live.ex` | exact |
| `lib/threadline/operator_surface/live/export_status_live.ex` | LiveView | event-driven / CRUD | `lib/threadline/operator_surface/live/export_status_live.ex` | exact |
| `lib/threadline/operator_surface/live/evidence_live.ex` | LiveView | event-driven / CRUD | `lib/threadline/evidence.ex` | role-match |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | LiveView | event-driven / CRUD | `lib/threadline/operator_surface/live/retention_history_live.ex` | exact |
| `lib/threadline/operator_surface/live/start_live.ex` | LiveView | event-driven / CRUD | `lib/threadline/operator_surface/live/start_live.ex` | exact |
| `lib/threadline/operator_surface/controllers/export_controller.ex` | controller | request-response / file-I/O | `lib/threadline/operator_surface/controllers/export_controller.ex` | exact |
| `guides/operator-surface.md` | docs | transform | `test/threadline/operator_surface/coverage_doc_contract_test.exs` | exact |
| `guides/domain-reference.md` | docs | transform | `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | role-match |
| `README.md` | docs | transform | `test/threadline/readme_doc_contract_test.exs` | exact |
| `guides/getting-started-saas.md` | docs | transform | `test/threadline/getting_started_saas_doc_contract_test.exs` | exact |
| `test/support/data_case.ex` | test support | CRUD / DB cleanup | `test/support/data_case.ex` | exact |
| `test/support/storage_schema_case.ex` | test support | CRUD / DB setup | `test/support/data_case.ex` | role-match |
| `test/threadline/storage_schema_test.exs` | test | transform | `test/threadline/storage_schema_test.exs` | exact |
| `test/threadline/storage_schema_migration_contract_test.exs` | test | source contract | `test/threadline/capture/trigger_sql_storage_schema_test.exs` | exact |
| `test/threadline/storage_schema_prefix_contract_test.exs` | test | source contract / CRUD | `test/threadline/storage_schema_migration_contract_test.exs` | role-match |
| `test/threadline/storage_schema_integration_test.exs` | test | CRUD / integration | `test/threadline/query_test.exs` | role-match |
| `test/threadline/capture/trigger_sql_storage_schema_test.exs` | test | source contract | `test/threadline/capture/trigger_sql_storage_schema_test.exs` | exact |
| `test/threadline/query_test.exs` | test | CRUD / request-response | `test/threadline/query_test.exs` | exact |
| `test/threadline/evidence_test.exs` | test | CRUD | `test/threadline/evidence_test.exs` | exact |
| `test/threadline/export_test.exs` | test | streaming / file-I/O | `test/threadline/export_test.exs` | exact |
| `test/threadline/export/orchestrator_test.exs` | test | batch / file-I/O | `test/threadline/export_test.exs` | role-match |
| `test/threadline/export/cleanup_test.exs` | test | batch / file-I/O | `test/threadline/export_test.exs` | role-match |
| `test/threadline/retention_test.exs` | test | batch / destructive CRUD | `test/threadline/retention_test.exs` | exact |
| `test/threadline/retention/pruner_test.exs` | test | event-driven / batch | `test/threadline/operator_surface/live/retention_history_live_test.exs` | role-match |
| `test/threadline/continuity_brownfield_test.exs` | test | CRUD / catalog query | `test/threadline/continuity_brownfield_test.exs` | exact |
| `test/threadline/verify_coverage_task_test.exs` | test | subprocess / catalog query | `test/threadline/verify_coverage_task_test.exs` | exact |
| `test/threadline/verify_coverage_policy_test.exs` | test | transform | `test/threadline/verify_coverage_policy_test.exs` | exact |
| `test/threadline/policy/redaction_presenter_test.exs` | test | transform / catalog query | `test/threadline/policy/redaction_presenter_test.exs` | exact |
| `test/threadline/policy/redaction_presenter_catalog_test.exs` | test | catalog query | `test/threadline/policy/redaction_presenter_test.exs` | role-match |
| `test/threadline/operator_surface/policy_show_mix_test.exs` | test | Mix task / catalog query | `test/threadline/operator_surface/policy_show_mix_test.exs` | exact |
| `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | test | source contract | `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` | test | source contract | `test/threadline/operator_surface/coverage_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface/live/coverage_live_test.exs` | test | LiveView / catalog query | `test/threadline/operator_surface/live/coverage_live_test.exs` | exact |
| `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | test | LiveView / catalog query | `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | exact |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | test | LiveView / CRUD | `test/threadline/operator_surface/live/timeline_live_test.exs` | exact |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | test | LiveView / CRUD | `test/threadline/operator_surface/live/evidence_live_test.exs` | exact |
| `test/threadline/operator_surface/live/export_status_live_test.exs` | test | LiveView / CRUD | `test/threadline/operator_surface/live/export_status_live_test.exs` | exact |
| `test/threadline/operator_surface/live/retention_history_live_test.exs` | test | LiveView / CRUD | `test/threadline/operator_surface/live/retention_history_live_test.exs` | exact |
| `test/threadline/operator_surface/live/start_live_test.exs` | test | LiveView / CRUD | `test/threadline/operator_surface/live/start_live_test.exs` | exact |
| `test/threadline/operator_surface/controllers/export_controller_test.exs` | test | controller / file-I/O | `test/threadline/operator_surface/controllers/export_controller_test.exs` | exact |
| `test/threadline/readme_doc_contract_test.exs` | test | source contract | `test/threadline/readme_doc_contract_test.exs` | exact |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | test | source contract | `test/threadline/getting_started_saas_doc_contract_test.exs` | exact |

## Pattern Assignments

### Storage Schema Helper Contract

**Apply to:** `lib/threadline/storage_schema.ex`, generated migrations, trigger SQL, Repo prefix plumbing, static source contracts.

**Analog:** `lib/threadline/storage_schema.ex`

**Imports and module contract** (lines 1-12):
```elixir
defmodule Threadline.StorageSchema do
  @moduledoc """
  Resolves and validates the PostgreSQL schema that stores Threadline-owned data.
  """

  @default "threadline"
  @identifier ~r/^[A-Za-z_][A-Za-z0-9_]*$/
```

**Resolution and validation pattern** (lines 23-42):
```elixir
def get(opts \\ []) when is_list(opts) do
  opts
  |> Keyword.get(:storage_schema, Application.get_env(:threadline, :storage_schema, @default))
  |> validate!()
end

def validate!(value) when is_binary(value) do
  value = String.trim(value)

  if Regex.match?(@identifier, value) do
    value
  else
    raise ArgumentError,
          "Threadline storage schema must be a non-empty PostgreSQL identifier " <>
            "matching #{@identifier.source}, got: #{inspect(value)}"
  end
end
```

**Quoting and Repo prefix pattern** (lines 50-66):
```elixir
def quote_ident(identifier), do: ~s("#{validate!(identifier)}")
def qualify(schema, name), do: "#{quote_ident(schema)}.#{quote_ident(name)}"

def table(name, opts \\ []) when name in @threadline_tables do
  qualify(get(opts), name)
end

def repo_opts(opts \\ []), do: [prefix: get(opts)]
def function(name, opts \\ []), do: qualify(get(opts), name)
```

**Host table parsing pattern** (lines 74-95):
```elixir
def parse_table_identifier(value) when is_binary(value) do
  case String.split(value, ".", trim: true) do
    [table] -> %{schema: "public", table: validate!(table)}
    [schema, table] -> %{schema: validate!(schema), table: validate!(table)}
    _ -> raise ArgumentError, "table must be NAME or SCHEMA.NAME, got: #{inspect(value)}"
  end
end

def qualified_host_table(value) do
  %{schema: schema, table: table} = parse_table_identifier(value)
  qualify(schema, table)
end
```

**Copy notes:**
- Keep `storage_schema:` per-call override over app config over default.
- Reuse `quote_ident/1`, `qualify/2`, `table/2`, and `function/2` for every raw SQL identifier. Do not interpolate `#{storage_schema}.table`.
- For host tables, use `parse_table_identifier/1` and `qualified_host_table/1`; do not confuse host schema with Threadline storage schema.
- If the identifier contract is narrowed for 63-byte or `pg_` rules, update `storage_schema_test.exs`, migration contracts, docs, and generated SQL contracts in the same wave.

### Generated Migration SQL

**Apply to:** `lib/threadline/capture/migration.ex`, `lib/threadline/semantics/migration.ex`, `lib/threadline/governance/migration.ex`, `lib/mix/tasks/threadline.install.ex`, `test/threadline/storage_schema_migration_contract_test.exs`.

**Analog:** `lib/threadline/capture/trigger_sql.ex`

**Existing wrong shape to replace** - capture migration (lines 19-29):
```elixir
storage_schema = StorageSchema.get()

"""
defmodule ThreadlineAuditSchema do
  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA IF NOT EXISTS #{storage_schema}"

    execute """
    CREATE TABLE IF NOT EXISTS #{storage_schema}.audit_transactions (
```

**Quoted pattern to copy** - trigger SQL (lines 117-119, 172-175, 437-456):
```elixir
def drop_function(opts \\ []) do
  "DROP FUNCTION IF EXISTS #{StorageSchema.function("threadline_capture_changes", opts)}()"
end

CREATE OR REPLACE FUNCTION #{StorageSchema.function("threadline_capture_changes", opts)}()

INSERT INTO #{StorageSchema.table("audit_transactions", opts)} (id, txid, occurred_at, actor_ref)
...
FROM #{StorageSchema.table("audit_transactions", opts)}
```

**Mix install generation pattern** (lines 23-35):
```elixir
def run(_args) do
  Mix.Task.run("app.config", [])

  path = migrations_path()
  File.mkdir_p!(path)

  capture_written =
    if existing_capture_migration?(path) do
      Mix.shell().info("Threadline audit schema migration already exists — skipping.")
      false
    else
      file = Path.join(path, "#{timestamp()}_threadline_audit_schema.exs")
      create_file(file, Threadline.Capture.Migration.migration_content())
```

**Test contract analog** - current contract to update (lines 4-20):
```elixir
migration = Threadline.Capture.Migration.migration_content()

assert migration =~ "CREATE SCHEMA IF NOT EXISTS threadline"
assert migration =~ "CREATE TABLE IF NOT EXISTS threadline.audit_transactions"
...
assert governance =~ "CREATE TABLE IF NOT EXISTS threadline.threadline_export_jobs"
```

**Copy notes:**
- In migration modules, compute quoted/qualified names once near `storage_schema = StorageSchema.get()`, for example `schema = StorageSchema.quote_ident(storage_schema)` and `audit_transactions = StorageSchema.table("audit_transactions")`.
- Generated migration string should freeze the configured schema at task generation time.
- Add contracts for `"AuditLog"` and `"audit"` to prove quoted identifiers, and invalid identifiers to prove shared runtime/generation semantics.
- Coordinate all three migration modules together; partial quoting leaves mixed case-folding behavior.

### Trigger SQL and Host-Qualified Capture

**Apply to:** `lib/threadline/capture/trigger_sql.ex`, `lib/mix/tasks/threadline.gen.triggers.ex`, `test/threadline/capture/trigger_sql_storage_schema_test.exs`, `test/threadline/storage_schema_integration_test.exs`.

**Analog:** `lib/threadline/capture/trigger_sql.ex`

**Trigger host table pattern** (lines 134-156):
```elixir
def create_trigger(table_name, :default, opts) do
  create_trigger_sql(
    table_name,
    "#{StorageSchema.function("threadline_capture_changes", opts)}()"
  )
end

defp create_trigger_sql(table_name, function_invocation) do
  trigger_name = "threadline_audit_#{StorageSchema.host_table_suffix(table_name)}"
  host_table = StorageSchema.qualified_host_table(table_name)

  """
  CREATE TRIGGER #{StorageSchema.quote_ident(trigger_name)}
  AFTER INSERT OR UPDATE OR DELETE ON #{host_table}
  FOR EACH ROW EXECUTE FUNCTION #{function_invocation}
  """
end
```

**Capture rows keep host schema** (lines 472-480):
```elixir
INSERT INTO #{StorageSchema.table("audit_changes", opts)} (
  id, transaction_id, table_schema, table_name,
  table_pk, op, data_after, changed_fields, changed_from, captured_at
) VALUES (
  gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
  v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, v_changed_from, clock_timestamp()
);
```

**Generator table parsing pattern** (lines 81-98, 131-137):
```elixir
tables =
  opts
  |> Keyword.get(:tables, "")
  |> String.split(",", trim: true)
  |> Enum.map(&String.trim/1)

forbidden = Enum.filter(tables, &StorageSchema.threadline_table?/1)

table_suffix = tables |> Enum.map(&StorageSchema.host_table_suffix/1) |> Enum.join("_")
file = Path.join(path, "#{timestamp()}_threadline_triggers_#{table_suffix}.exs")
create_file(file, migration_content(table_specs))
```

**Test analog** (lines 22-37):
```elixir
sql = TriggerSQL.create_trigger("support.tickets")

assert sql =~ ~S|CREATE TRIGGER "threadline_audit_support_tickets"|
assert sql =~ ~S|ON "support"."tickets"|
assert sql =~ ~S|EXECUTE FUNCTION "threadline"."threadline_capture_changes"()|
```

**Copy notes:**
- Keep qualified host tables as explicit `schema.table` inputs.
- Extend tests from source SQL shape to actual `support.tickets` execution when possible.
- If per-table functions need custom storage schema, pass `storage_schema:` opts through both install and trigger creation paths.

### Owned Ecto Schema Prefix Removal

**Apply to:** `lib/threadline/capture/audit_transaction.ex`, `lib/threadline/capture/audit_change.ex`, `lib/threadline/semantics/audit_action.ex`, `lib/threadline/governance/evidence_record.ex`, `lib/threadline/governance/export_job.ex`, `lib/threadline/governance/retention_run.ex`, `lib/threadline/governance/saved_view.ex`, `test/threadline/storage_schema_prefix_contract_test.exs`.

**Analog:** owned schema modules.

**Current fixed prefix to remove** - `AuditTransaction` (lines 41-48):
```elixir
use Ecto.Schema
import Ecto.Changeset

@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
@schema_prefix "threadline"

schema "audit_transactions" do
```

**Association pattern to keep** - `AuditChange` (lines 47-57):
```elixir
schema "audit_changes" do
  belongs_to(:transaction, Threadline.Capture.AuditTransaction, foreign_key: :transaction_id)

  field(:table_schema, :string)
  field(:table_name, :string)
  field(:table_pk, :map)
  field(:op, :string)
  field(:data_after, :map)
```

**Governance schema validation pattern to keep** - `EvidenceRecord` (lines 39-57):
```elixir
def changeset(record \\ %__MODULE__{}, attrs) do
  record
  |> cast(attrs, [
    :subject,
    :subject_ref,
    :summary_status,
    :recorded_at,
    :actor_ref,
    :provenance,
    :detail,
    :schema_version
  ])
  |> validate_required(@required_fields)
  |> validate_length(:subject, min: 1)
```

**Copy notes:**
- Remove only `@schema_prefix "threadline"` from owned schemas; preserve `schema "table_name"`, keys, associations, and changesets.
- Add a source contract that scans owned schema files and fails if the fixed prefix returns.
- After prefix removal, fixtures that insert owned schemas without `StorageSchema.repo_opts()` will break; update test support and call sites in the same wave.

### Repo Prefix on Public Query and Service Paths

**Apply to:** `lib/threadline.ex`, `lib/threadline/audit.ex`, `lib/threadline/query.ex`, `lib/threadline/evidence.ex`, `lib/threadline/export.ex`.

**Analog:** `lib/threadline/query.ex`, `lib/threadline/evidence.ex`, `lib/threadline/export.ex`.

**Public write pattern** - `record_action/2` (lines 41-51):
```elixir
def record_action(name, opts \\ []) when is_atom(name) do
  repo = Keyword.get(opts, :repo)
  actor_ref = Keyword.get(opts, :actor) || Keyword.get(opts, :actor_ref)

  result =
    with :ok <- validate_repo(repo),
         {:ok, validated_ref} <- validate_actor(actor_ref) do
      attrs = build_attrs(name, validated_ref, opts)
      changeset = AuditAction.changeset(attrs)
      repo.insert(changeset, StorageSchema.repo_opts(opts))
    end
```

**Query prefix helper** (lines 735-744):
```elixir
def storage_opts(filters \\ [], opts \\ []) do
  StorageSchema.repo_opts(storage_schema_opts(filters, opts))
end

defp storage_schema_opts(_filters, opts) do
  case Keyword.get(opts, :storage_schema) do
    nil -> []
    storage_schema -> [storage_schema: storage_schema]
  end
end
```

**Preload gaps to fix** - `Query` (lines 104-132, 664-670):
```elixir
def preload_investigation_context(changes, repo) when is_list(changes) and is_atom(repo) do
  repo.preload(changes, transaction: :action)
end

preloads when is_list(preloads) or is_atom(preloads) ->
  repo.preload(transaction, preloads)

preloads when is_list(preloads) ->
  repo.preload(results, preloads)
```

**Evidence CRUD prefix pattern** (lines 65-76, 149-173):
```elixir
EvidenceRecord
|> maybe_filter_subject(Keyword.get(filters, :subject))
|> maybe_filter_subject_ref(Keyword.get(filters, :subject_ref))
|> order_by([record], desc: record.recorded_at, desc: record.id)
|> repo.all(StorageSchema.repo_opts(filters ++ opts))

%EvidenceRecord{}
|> EvidenceRecord.changeset(attrs)
|> Keyword.fetch!(opts, :repo).insert(StorageSchema.repo_opts(opts))
```

**Export streaming prefix pattern** (lines 78-82, 349-355):
```elixir
rows =
  repo.all(
    Query.export_changes_query(filters, opts) |> limit(^limit),
    Query.storage_opts(filters, opts)
  )

case repo.all(q, Query.storage_opts(filters, opts)) do
```

**Copy notes:**
- For reads/writes that accept caller opts, use `StorageSchema.repo_opts(opts)` or `Query.storage_opts(filters, opts)`.
- For preloads, use `repo.preload(records, preloads, StorageSchema.repo_opts(opts))` where opts are available, or change helper signatures to carry storage opts.
- `Threadline.Audit` currently calls `StorageSchema.repo_opts()` without opts in transaction linkage (lines 224-257). Decide whether the transaction helper should accept/pass storage schema or be global-config only, then test-lock it.

### Async Export and Retention Global Contract

**Apply to:** `lib/threadline/export/orchestrator.ex`, `lib/threadline/export/cleanup_task.ex`, `lib/threadline/retention.ex`, `lib/threadline/retention/pruner.ex`, `lib/threadline/operator_surface/live/timeline_live.ex`, `lib/threadline/operator_surface/live/export_status_live.ex`, export/retention tests.

**Analog:** existing global `StorageSchema.repo_opts()` worker paths.

**Export orchestrator pattern** (lines 17-39, 82-100):
```elixir
def run(job_id, opts \\ []) do
  repo = Keyword.get(opts, :repo) || default_repo()
  storage = Application.get_env(:threadline, :storage_adapter, Threadline.Storage.Local)

  case fetch_and_mark_running(repo, job_id) do
    {:ok, job} ->
      ...
      filters = prepare_filters(job.query_params, repo)

      Export.stream_export_rows(filters, repo: repo)

defp fetch_and_mark_running(repo, job_id) do
  job = repo.get!(ExportJob, job_id, StorageSchema.repo_opts())
  ...
  |> repo.update(StorageSchema.repo_opts())
end
```

**Export cleanup pattern** (lines 78-95, 105-118):
```elixir
expired_jobs = repo.all(query, StorageSchema.repo_opts())

for job <- expired_jobs do
  if job.file_path do
    storage_adapter.delete(job.file_path)
  end

  repo.delete!(job, StorageSchema.repo_opts())
end

from(j in ExportJob, where: j.status == "running" and j.started_at < ^cutoff)
|> repo.update_all([...], StorageSchema.repo_opts())
```

**Retention destructive pattern** (lines 82-103, 202-232):
```elixir
run_record =
  repo.insert!(
    RetentionRun.changeset(%RetentionRun{}, %{status: "running", started_at: started_at}),
    StorageSchema.repo_opts()
  )

repo.delete_all(
  from(ac in AuditChange, where: ac.id in subquery(subq)),
  StorageSchema.repo_opts()
)
```

**Pruner event pattern** (lines 60-71, 90-99):
```elixir
from(r in RetentionRun,
  where: r.status == "running" and r.started_at < ^cutoff
)
|> repo.update_all([...], StorageSchema.repo_opts())

repo.checkout(fn ->
  if acquire_lock(repo) do
    try do
      Threadline.Retention.purge(repo: repo, sleep_ms: sleep_ms)
    after
      release_lock(repo)
    end
  end
end)
```

**Copy notes:**
- Phase decision allows either global-config contract or persisted/pass-through storage schema for jobs. Research recommends global-config for Phase 190; if planner chooses that, tests should set app config to `"audit"` before enqueuing and during worker execution.
- Do not silently move queued jobs across schemas. If not persisting schema in jobs, document that changing `storage_schema` after queueing requires draining/rerunning jobs.
- Destructive retention tests must prove `audit` rows are deleted and `threadline` sentinel rows remain.

### Selected Host Schema Coverage and Policy

**Apply to:** `lib/threadline/health.ex`, `lib/threadline/health/coverage_schemas.ex`, `lib/mix/tasks/threadline.health.coverage.ex`, `lib/mix/tasks/threadline.verify_coverage.ex`, `lib/mix/tasks/threadline.policy.show.ex`, `lib/threadline/policy/redaction_presenter.ex`, `lib/threadline/continuity.ex`, related Mix/task/presenter tests.

**Analog:** coverage task plus `CoverageSchemas`.

**Coverage service pattern** (lines 54-60, 89-105):
```elixir
def trigger_coverage(opts) do
  repo = Keyword.fetch!(opts, :repo)
  schema = Keyword.get(opts, :schema, "public")

  all_tables = fetch_all_user_tables(repo, schema)
  covered_tables = fetch_threadline_covered_tables(repo, schema)

sql = "SELECT tablename FROM pg_tables WHERE schemaname = $1"
%{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [schema])
```

**Edge validation pattern** (lines 17-35):
```elixir
def validate!(repo, schema) when is_binary(schema) do
  case validate(repo, schema) do
    {:ok, schema} -> schema
    {:error, message} -> raise ArgumentError, message
  end
end

def validate(repo, schema) when is_binary(schema) do
  if schema =~ @schema_regex do
    sql = "SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1"
```

**Mix `--schema` pattern** - coverage (lines 37-57, 84-98):
```elixir
{opts, _, _} = OptionParser.parse(argv, strict: [json: :boolean, schema: :string])
json? = Keyword.get(opts, :json, false)
schema = Keyword.get(opts, :schema, "public")
...
validate_schema!(repo, schema)
coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)

case CoverageSchemas.validate(repo, schema) do
  {:ok, _schema} -> :ok
  {:error, _message} -> Mix.raise(...)
end
```

**Policy task current public-only gap** (lines 31-44, 121-129):
```elixir
{opts, _, _} = OptionParser.parse(argv, strict: [json: :boolean])
json? = Keyword.get(opts, :json, false)
...
report = RedactionPresenter.build(repo: repo, schema: "public")

payload = %{
  "schema" => "public",
  "total_tables" => length(report.tables),
```

**Redaction presenter selected-schema pattern and bare-table gap** (lines 28-43, 70-89):
```elixir
def build(opts) do
  repo = Keyword.fetch!(opts, :repo)
  schema = Keyword.get(opts, :schema, "public")

  build_report(TriggerCaptureConfig.load(), fetch_deployed(repo, schema))
end

configured =
  Map.new(configured_tables, fn {table, entry} -> {table, normalize_policy(entry)} end)

deployed_by_table = Enum.group_by(deployed_rows, &to_string(Map.fetch!(&1, :table)))
```

**Continuity current public-only gap** (lines 56-75, 79-89):
```elixir
unless public_table_exists?(repo, table_name) do
  raise ArgumentError,
        "table #{inspect(table_name)} does not exist in schema public"
end

coverage = Threadline.Health.trigger_coverage(repo: repo)

defp public_table_exists?(repo, table_name) do
  Ecto.Adapters.SQL.query!(repo, """
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public' AND table_name = $1
  LIMIT 1
  """, [table_name])
end
```

**Copy notes:**
- Add `--schema=NAME` to `threadline.policy.show` by copying coverage task parsing and validation.
- Keep `--schema` meaning host schema only; do not route it into `StorageSchema.repo_opts/1`.
- In `RedactionPresenter`, normalize configured keys with `StorageSchema.parse_table_identifier/1`, then compare selected-schema deployed rows to matching configured entries. Display `support.tickets` where needed.
- In `Continuity`, parse `support.tickets` or accept schema opts and call `Health.trigger_coverage(repo: repo, schema: schema)`.

### Operator Surface Patterns

**Apply to:** `CoverageLive`, `PolicyRedactionLive`, `TimelineLive`, `ExportStatusLive`, `EvidenceLive`, `RetentionHistoryLive`, `StartLive`, `ExportController`, LiveView/controller tests.

**Analog:** `lib/threadline/operator_surface/live/coverage_live.ex`.

**Schema selector state and validation pattern** (lines 24-55, 74-84):
```elixir
socket =
  socket
  |> assign(:schema_param, "public")
  |> assign(:coverage_for_schema, initial)
  |> assign(:coverage_for_schema_name, "public")
  |> assign(:available_schemas, [])
  |> assign(:form_error, nil)

with {:ok, schemas} <- safe_available_schemas(socket),
     {:ok, schema} <- safe_validate_schema(socket, schema_param, schemas) do
  socket =
    socket
    |> assign(:schema_param, schema)
    |> assign(:available_schemas, schemas)
    |> assign(:form_error, nil)
    |> fetch_coverage_for_schema(schema)

def handle_event("select-schema", %{"schema" => schema}, socket) do
  ...
  push_patch(socket, to: "#{socket.assigns.base_path}/coverage?#{URI.encode_query(%{"schema" => schema})}")
end
```

**Non-public timeline link pattern** (lines 493-498):
```elixir
defp timeline_table_path(base_path, table, "public") do
  "#{base_path}/timeline?#{URI.encode_query(%{"table" => table})}"
end

defp timeline_table_path(base_path, table, schema) do
  "#{base_path}/timeline?#{URI.encode_query(%{"table_schema" => schema, "table" => table})}"
end
```

**PolicyRedaction current gaps** (lines 18-39, 89-95, 259-260):
```elixir
if socket.assigns[:threadline_policy_enabled] do
  report = RedactionPresenter.build(repo: resolve_repo(socket))
  ...
end

<.link navigate={timeline_table_path(@base_path, row.table)} ...>
...
<.link :if={@threadline_coverage_enabled and @base_path} navigate={"#{@base_path}/coverage"} ...>

defp timeline_table_path(base_path, table) do
  "#{base_path}/timeline?#{URI.encode_query(%{"table" => table})}"
end
```

**Timeline saved view/export job direct Repo pattern** (lines 42-50, 212-242, 273-307):
```elixir
repo.all(
  from(v in Threadline.Governance.SavedView,
    where: v.actor_ref == ^actor_ref,
    order_by: [desc: v.inserted_at]
  ),
  StorageSchema.repo_opts()
)

case socket.assigns.repo.insert(changeset, StorageSchema.repo_opts()) do
...
socket.assigns.repo.delete!(view, StorageSchema.repo_opts())
...
job = repo.insert!(job, StorageSchema.repo_opts())
```

**Timeline preload gap** (lines 860-861):
```elixir
defp preload_visible_context(%{entries: entries} = page, repo) do
  %{page | entries: repo.preload(entries, transaction: :action)}
end
```

**Other operator owned reads** (representative lines):
```elixir
# Export status, lines 365-371
from(j in ExportJob,
  where: j.actor_ref == ^actor_ref,
  order_by: [desc: j.inserted_at],
  limit: @default_limit
)
|> repo.all(StorageSchema.repo_opts())

# Retention history, lines 352-362
from(r in RetentionRun, order_by: [desc: r.started_at], limit: @default_limit)
|> repo.all(StorageSchema.repo_opts())
repo.exists?(from(r in RetentionRun), StorageSchema.repo_opts())

# Export controller, lines 61-64
case Ecto.UUID.cast(job_id) do
  {:ok, uuid} ->
    job = repo.get(Threadline.Governance.ExportJob, uuid, StorageSchema.repo_opts())
```

**Evidence LiveView delegates through Evidence API** (lines 215-231):
```elixir
defp fetch_records(%{subject: nil, subject_ref: nil, mode: :latest}, repo) do
  Evidence.list_overview([], repo: repo)
end

defp fetch_records(%{subject: subject, subject_ref: subject_ref, mode: :history}, repo) do
  Evidence.list_subject_ref_history(subject, subject_ref, repo: repo)
end
```

**Copy notes:**
- Use coverage LiveView's schema picker and invalid-schema alert for policy redaction if SCHEMA-04 is implemented there.
- Operator direct Repo reads should either use global configured `StorageSchema.repo_opts()` by contract or receive a deliberate storage schema. Do not mix operator host schema selection into storage prefix.
- Timeline `table_schema` filters already exist; preserve public links omitting `table_schema` and non-public links including it.

### Real DB Test and Fixture Patterns

**Apply to:** `test/support/data_case.ex`, new `test/support/storage_schema_case.ex`, `test/threadline/storage_schema_integration_test.exs`, `query/evidence/export/retention/operator` tests.

**Analog:** `test/support/data_case.ex`, `test/threadline/query_test.exs`, `test/threadline/operator_surface/live/coverage_live_test.exs`.

**DataCase baseline** (lines 1-28):
```elixir
defmodule Threadline.DataCase do
  @moduledoc """
  Test case for integration tests that require a real PostgreSQL database.
  """

  defmacro __using__(opts) do
    opts = Keyword.merge([async: false], opts)

    quote do
      use ExUnit.Case, unquote(opts)

      alias Threadline.Test.Repo
      alias Threadline.Capture.{AuditChange, AuditTransaction}
      import Ecto.Query
      import Threadline.AsyncHelpers

      setup do
        Repo.delete_all(AuditChange)
        Repo.delete_all(AuditTransaction)
        Repo.delete_all(Threadline.Semantics.AuditAction)
        :ok
      end
```

**Existing unprefixed fixture pattern that must change after prefix removal** (query test lines 14-31):
```elixir
defp insert_transaction(attrs \\ %{}) do
  defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}
  @repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
end

defp insert_change(transaction, attrs \\ %{}) do
  ...
  @repo.insert!(AuditChange.changeset(Map.merge(defaults, Map.new(attrs))))
end
```

**Host-schema DB setup pattern** (coverage LiveView test lines 402-428):
```elixir
Ecto.Adapters.SQL.query!(Threadline.Test.Repo, "CREATE SCHEMA IF NOT EXISTS tenant_demo", [])
Ecto.Adapters.SQL.query!(
  Threadline.Test.Repo,
  "CREATE TABLE IF NOT EXISTS tenant_demo.coverage_link_target (id bigint PRIMARY KEY)",
  []
)
Ecto.Adapters.SQL.query!(
  Threadline.Test.Repo,
  Threadline.Capture.TriggerSQL.create_trigger("tenant_demo.coverage_link_target")
)

on_exit(fn ->
  Ecto.Adapters.SQL.query!(Threadline.Test.Repo, "DROP TABLE IF EXISTS tenant_demo.coverage_link_target CASCADE", [])
  Ecto.Adapters.SQL.query!(Threadline.Test.Repo, "DROP SCHEMA IF EXISTS tenant_demo", [])
end)
```

**Env restore pattern** (retention test lines 8-19):
```elixir
setup do
  prev = Application.get_env(:threadline, :retention)

  on_exit(fn ->
    Application.put_env(:threadline, :retention, prev)
  end)

  Application.put_env(:threadline, :retention,
    enabled: true,
    keep_days: 1,
    delete_empty_transactions: true
  )
```

**Copy notes:**
- Build a helper that creates/drops `audit` and `support` schemas, creates Threadline-owned tables in both `threadline` and `audit` as needed, inserts sentinel rows with explicit repo prefixes, and restores `Application.get_env(:threadline, :storage_schema)`.
- Existing `DataCase` cleanup uses unprefixed deletes. Once owned schema prefixes are removed, cleanup must use `StorageSchema.repo_opts()` for default `"threadline"` and any custom `"audit"` helper cleanup.
- Dual-schema tests should fail if a path reads default `threadline` while selected/configured schema is `"audit"`.

### Mix Task Test Patterns

**Apply to:** coverage/verify/policy Mix task tests.

**Analog:** `test/threadline/verify_coverage_task_test.exs`, `test/threadline/operator_surface/policy_show_mix_test.exs`.

**Subprocess Mix task pattern** (lines 6-20):
```elixir
defp cmd_env(extra \\ %{}) do
  System.get_env()
  |> Map.merge(Map.new(extra))
  |> Map.to_list()
end

assert {output, 0} =
         System.cmd(
           "mix",
           ["threadline.verify_coverage"],
           cd: File.cwd!(),
           env: cmd_env(%{"MIX_ENV" => "test"}),
           stderr_to_stdout: true
         )
```

**In-process Mix task and DB fixture pattern** (policy show test lines 38-63, 87-100):
```elixir
setup do
  original = Application.get_env(:threadline, :trigger_capture)

  Application.put_env(:threadline, :trigger_capture,
    tables: %{
      @drift_table => [mask: ["email"], mask_placeholder: "[REDACTED]"]
    }
  )

  Repo.query!(TriggerSQL.install_function_for_table(@drift_table, mask: ["email"], mask_placeholder: "[DIFFERENT]", store_changed_from: true))
  Repo.query!(TriggerSQL.create_trigger(@drift_table, :per_table))

  Mix.Task.reenable("threadline.policy.show")

  on_exit(fn ->
    ...
    Application.put_env(:threadline, :trigger_capture, original)
  end)
end
```

**Copy notes:**
- For new `threadline.policy.show --schema=support`, copy coverage task validation tests and policy show fixture style.
- Use `Mix.Task.reenable/1` for in-process Mix task runs.
- JSON output tests should assert `"schema" => "support"` once the task accepts schema.

### LiveView Test Patterns

**Apply to:** coverage, policy redaction, timeline, evidence, export status, retention history, start, controller tests.

**Analog:** `test/threadline/operator_surface/live/coverage_live_test.exs`, `test/threadline/operator_surface/live/policy_redaction_live_test.exs`.

**Router/endpoint harness pattern** (coverage test lines 28-67):
```elixir
defmodule Threadline.OperatorSurface.CoverageLiveTest.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  require Threadline.OperatorSurface.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {Threadline.OperatorSurface.CoverageLiveTest.Layouts, :root})
  end

  scope "/" do
    pipe_through(:browser)
    Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
      coverage_authorize_fn: &Threadline.OperatorSurface.CoverageLiveTest.Auth.authorize/1
    )
  end
end
```

**Policy redaction fixture pattern** (lines 112-160, 322-332):
```elixir
setup do
  Repo.delete_all(AuditChange)
  Repo.delete_all(AuditTransaction)
  Repo.delete_all(AuditAction)

  original = Application.get_env(:threadline, :trigger_capture)
  Application.put_env(:threadline, :trigger_capture, tables: %{@alpha => [mask: ["email"]]})

  install_match_trigger!(@alpha, mask: ["email"], mask_placeholder: "[MASKED]")

  on_exit(fn ->
    reset_table!(@alpha)
    Application.put_env(:threadline, :trigger_capture, original)
  end)

  {:ok, conn: build_conn()}
end

defp install_match_trigger!(table, opts) do
  sql = TriggerSQL.install_function_for_table(table, ..., store_changed_from: true)
  Repo.query!(sql)
  Repo.query!(TriggerSQL.create_trigger(table, :per_table))
end
```

**Non-public schema assertion pattern** (coverage test lines 430-435):
```elixir
{:ok, _view, html} = live(conn, "/audit/coverage?schema=tenant_demo")

assert html =~ "Schema: tenant_demo"
assert html =~ "coverage_link_target"
assert html =~ "table_schema=tenant_demo"
assert html =~ "table=coverage_link_target"
```

**Copy notes:**
- Add policy redaction selected-schema tests into the existing policy LiveView test harness; do not create browser E2E unless backend/LiveView tests cannot cover the path.
- For operator storage-schema reads, prefer DB-level sentinel assertions over visual-only assertions.

### Docs and Source Contract Patterns

**Apply to:** `README.md`, `guides/operator-surface.md`, `guides/domain-reference.md`, `guides/getting-started-saas.md`, doc contract tests.

**Analog:** existing doc contract tests.

**README storage config copy** (lines 72-81):
```markdown
config :threadline,
  ecto_repos: [MyApp.Repo],
  storage_schema: "threadline"

`storage_schema` defaults to `"threadline"` and keeps Threadline-owned
tables/functions out of `public`. Set it to `"public"` explicitly if you want
the historical public-schema footprint, or to another PostgreSQL schema such
as `"audit"`.
```

**Operator surface coverage doc pattern** (lines 323-333, 365-373):
```markdown
Covered rows link to Timeline activity. Public-schema links omit `table_schema`; non-public links include `table_schema=NAME&table=TABLE`.

For non-public schemas, run:

    mix threadline.verify_coverage --schema=NAME

Capture-only adopters who do not mount the surface get the same data via:

    mix threadline.health.coverage
    mix threadline.health.coverage --json
    mix threadline.health.coverage --schema=NAME
```

**Domain reference schema distinction pattern** (lines 232-240, 309-311):
```markdown
**Schema scope.** Pass `:schema` to query a non-`public` schema...

**`mix threadline.policy.show`.** Viewer-only parity for redaction drift...

Example SQL uses placeholder schema **`your_schema`** for Threadline's storage schema...
Use `ac.table_schema` predicates when audited host tables live outside `public` or duplicate table names exist.
```

**Doc contract pattern** - coverage (lines 177-181):
```elixir
assert String.contains?(guide, "Selected schema readiness")
assert String.contains?(guide, "Use public schema")
assert String.contains?(guide, "table_schema=NAME&table=TABLE")
assert String.contains?(guide, "mix threadline.verify_coverage --schema=NAME")
```

**Doc contract pattern** - policy show (lines 54-63, 87-95):
```elixir
src = File.read!(@mix_task_path)

assert String.contains?(src, "mix threadline.policy.show")
assert String.contains?(src, "mix threadline.policy.show --json")

output = capture_io(fn ->
  Mix.Tasks.Threadline.Policy.Show.run(["--json"])
end)

parsed = Jason.decode!(output)
```

**Copy notes:**
- Keep operator copy as "Storage schema" for Threadline-owned tables and "Host schema" for app tables.
- Update doc contracts in the same wave as docs and task moduledocs.
- Document generated migrations freeze configured storage schema at generation time.

## Shared Patterns

### Authentication and Operator Gating

**Source:** LiveView test routers and operator router options.
**Apply to:** operator LiveView/controller tests only.

The phase does not change auth semantics. Reuse existing `*_authorize_fn` test modules when adding LiveView assertions:
```elixir
defmodule Threadline.OperatorSurface.PolicyRedactionLiveTest.Auth do
  def authorize(_mirror), do: Application.get_env(:threadline, :test_allow_policy, true)
end
```

### Error Handling

**Source:** existing `Mix.raise/1`, `ArgumentError`, and fail-closed presenter/UI patterns.
**Apply to:** Mix task schema validation, continuity, storage-schema validation, redaction presenter.

Concrete patterns:
- `StorageSchema.validate!/1` raises `ArgumentError` with the invalid value.
- Coverage Mix tasks call `CoverageSchemas.validate/2`, then `Mix.raise/1` with separate invalid-vs-not-found messages.
- `RedactionPresenter` returns `:could_not_introspect` with warnings rather than trusting unknown trigger SQL.

### Validation

**Source:** `StorageSchema.validate!/1` for storage identifiers; `CoverageSchemas.validate/2` for user-facing host schema selectors.
**Apply to:** all raw SQL generation and all untrusted `--schema` / URL `?schema=` inputs.

Do not use `String.to_atom/1` for schema/table names. Existing coverage doc contracts already check for this class of issue.

### Database Prefix

**Source:** `StorageSchema.repo_opts/1` and `Query.storage_opts/2`.
**Apply to:** all Threadline-owned Repo operations, including preloads, bulk deletes/updates, and operator reads.

Use:
```elixir
repo.all(query, StorageSchema.repo_opts(opts))
repo.insert(changeset, StorageSchema.repo_opts(opts))
repo.update_all(query, updates, StorageSchema.repo_opts(opts))
repo.preload(rows, preloads, StorageSchema.repo_opts(opts))
```

### Real PostgreSQL Proof

**Source:** `Threadline.DataCase`, coverage LiveView DB setup, retention env restore.
**Apply to:** `storage_schema_integration_test.exs` and focused path tests.

Required proof shape:
- Create `audit` storage schema and `support` host schema during setup.
- Keep plausible sentinel rows in `threadline`.
- Configure or pass `storage_schema: "audit"`.
- Assert reads/mutations/export/retention/operator paths use only `audit`.
- Restore app env in `on_exit`.

## Coordination Risks and Planning Waves

| Risk / Conflict | Files Involved | Planning Guidance |
|-----------------|----------------|-------------------|
| Removing `@schema_prefix` breaks existing unprefixed fixtures and `DataCase` cleanup. | Owned schema modules, `test/support/data_case.ex`, query/export/evidence/retention tests | Do prefix removal and test helper changes in the same early wave. Add `StorageSchema.repo_opts()` to test helpers before broad source changes. |
| Generated migration modules share one identifier contract. | `capture/migration.ex`, `semantics/migration.ex`, `governance/migration.ex`, install task, migration contract tests | Quote all three modules together; partial quoting leaves mixed SQL behavior. |
| Query preloads can silently use wrong prefix after read query succeeds. | `lib/threadline/query.ex`, `TimelineLive`, query/operator tests | Fix preload helper signatures and add sentinel association tests. |
| Async export jobs can move schemas if config changes after enqueue. | `Export.Orchestrator`, queue adapters, `TimelineLive`, `ExportStatusLive`, export tests/docs | Choose global-config-only or persisted schema explicitly. If global-only, document and test-lock it. |
| Retention is destructive. | `Retention`, `Pruner`, retention tests | Run sentinel tests that prove only `audit` rows are deleted while `threadline` rows remain. Keep retention fixes isolated from export. |
| Host schema and storage schema can be conflated in UI/CLI copy. | policy/coverage Mix tasks, LiveViews, docs | Keep `--schema`/`?schema=` as host schema. Keep `storage_schema:` as Threadline-owned storage only. |
| Redaction config keys may be qualified while deployed rows are bare table names. | `RedactionPresenter`, `TriggerCaptureConfig`, policy tests/docs | Normalize via `StorageSchema.parse_table_identifier/1`; display selected host schema labels intentionally. |
| LiveView schema selector reuse can touch shared UI copy/tests. | `CoverageLive`, `PolicyRedactionLive`, coverage/policy LiveView tests, doc contracts | Reuse coverage selector structure and existing `tl-*` classes. Avoid new UI patterns. |
| Doc contracts will fail if source/help text changes without docs. | README, guides, doc contract tests, Mix task moduledocs | Update docs and source-reading tests in the same wave as user-facing copy. |

Suggested wave order:

1. **Foundation contracts:** storage helper tests, generated migration quoting contracts, prefix source contract, test support helper.
2. **Owned schemas and core Repo paths:** remove fixed prefixes, fix query preloads, update query/evidence/export/retention fixtures.
3. **Dual-schema integration proof:** capture/query/semantics/evidence/export/retention/saved views sentinel tests.
4. **Host-schema truth:** continuity, redaction presenter, policy Mix `--schema`, selected host-schema tests.
5. **Operator and docs:** policy LiveView schema selector, operator reads/smoke, docs and doc contracts.

## No Analog Found

None. New files should copy from existing test/support, query, coverage, policy, and LiveView patterns listed above.

## Metadata

**Analog search scope:** `lib/threadline`, `lib/mix/tasks`, `test/support`, `test/threadline`, `guides`, `README.md`.
**Files scanned:** 100+ source/test/doc files through targeted `rg`, `wc`, and numbered reads.
**Pattern extraction date:** 2026-07-01
