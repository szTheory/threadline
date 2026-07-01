defmodule Threadline.StorageSchemaCase do
  @moduledoc """
  Test helpers for exercising Threadline-owned tables in explicit storage schemas.
  """

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.TriggerSQL
  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Governance.{EvidenceRecord, ExportJob, RetentionRun, SavedView}
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias Threadline.StorageSchema
  alias Threadline.Test.Repo

  @known_storage_schemas ["threadline", "audit"]

  @owned_tables ~w(
    audit_actions
    audit_transactions
    audit_changes
    threadline_evidence_records
    threadline_export_jobs
    threadline_retention_runs
    threadline_saved_views
  )

  @cleanup_order [
    AuditChange,
    AuditTransaction,
    AuditAction,
    EvidenceRecord,
    ExportJob,
    RetentionRun,
    SavedView
  ]

  def repo_opts(storage_schema_or_opts \\ [])

  def repo_opts(storage_schema) when is_binary(storage_schema) or is_atom(storage_schema) do
    StorageSchema.repo_opts(storage_schema: storage_schema)
  end

  def repo_opts(opts) when is_list(opts) do
    StorageSchema.repo_opts(opts)
  end

  def prepare_dual_storage!(repo \\ Repo) do
    prepare_storage_schema!("threadline", repo)
    prepare_storage_schema!("audit", repo)
    clean_storage_schemas!(@known_storage_schemas, repo)
  end

  def with_storage_schema(storage_schema, fun) when is_function(fun, 0) do
    storage_schema = StorageSchema.validate!(storage_schema)
    missing = make_ref()
    original = Application.get_env(:threadline, :storage_schema, missing)

    try do
      Application.put_env(:threadline, :storage_schema, storage_schema)
      fun.()
    after
      if original == missing do
        Application.delete_env(:threadline, :storage_schema)
      else
        Application.put_env(:threadline, :storage_schema, original)
      end
    end
  end

  def ensure_storage_schema!(storage_schema, repo \\ Repo) do
    storage_schema = StorageSchema.validate!(storage_schema)

    SQL.query!(
      repo,
      "CREATE SCHEMA IF NOT EXISTS #{StorageSchema.quote_ident(storage_schema)}",
      []
    )

    for table <- @owned_tables do
      SQL.query!(
        repo,
        """
        CREATE TABLE IF NOT EXISTS #{StorageSchema.qualify(storage_schema, table)}
        (LIKE #{StorageSchema.qualify("threadline", table)} INCLUDING DEFAULTS)
        """,
        []
      )
    end

    :ok
  end

  def prepare_storage_schema!(storage_schema, repo \\ Repo) do
    storage_schema = StorageSchema.validate!(storage_schema)

    unless storage_schema == "threadline" do
      SQL.query!(
        repo,
        "DROP SCHEMA IF EXISTS #{StorageSchema.quote_ident(storage_schema)} CASCADE",
        []
      )
    end

    ensure_storage_schema!(storage_schema, repo)
    install_capture_function!(storage_schema, repo)
  end

  def install_capture_function!(storage_schema, repo \\ Repo) do
    SQL.query!(repo, TriggerSQL.install_function(storage_schema: storage_schema), [])
    :ok
  end

  def insert_storage_sentinel!(storage_schema, opts \\ []) do
    storage_schema = StorageSchema.validate!(storage_schema)
    label = Keyword.fetch!(opts, :label)
    now = DateTime.utc_now()
    repo_opts = repo_opts(storage_schema)
    actor_ref = actor_ref!("storage-schema-sentinel-#{storage_schema}")

    action =
      %{
        name: "storage_schema.sentinel",
        actor_ref: actor_ref,
        status: :ok,
        category: "storage_schema",
        verb: "sentinel",
        correlation_id: "storage-schema-#{label}"
      }
      |> AuditAction.changeset()
      |> Repo.insert!(repo_opts)

    transaction =
      %{
        txid: System.unique_integer([:positive]),
        occurred_at: now,
        source: "storage_schema_integration",
        meta: %{"sentinel" => label},
        actor_ref: actor_ref,
        action_id: action.id
      }
      |> AuditTransaction.changeset()
      |> Repo.insert!(repo_opts)

    change =
      %{
        transaction_id: transaction.id,
        table_schema: "support",
        table_name: "tickets",
        table_pk: %{"id" => label},
        op: "insert",
        data_after: %{"id" => label, "subject" => "#{label} subject"},
        changed_fields: ["id", "subject"],
        captured_at: now
      }
      |> AuditChange.changeset()
      |> Repo.insert!(repo_opts)

    evidence =
      %{
        subject: "retention_run",
        subject_ref: %{"run_id" => label},
        summary_status: "supported",
        recorded_at: now,
        actor_ref: actor_ref,
        provenance: %{"writer" => "threadline", "entrypoint" => "storage-schema-test"},
        detail: %{"sentinel" => label},
        schema_version: 1
      }
      |> EvidenceRecord.changeset()
      |> Repo.insert!(repo_opts)

    export_job =
      %{
        status: "completed",
        query_params: %{"table_schema" => "support", "table" => "tickets"},
        actor_ref: actor_ref,
        file_path: "#{label}.csv",
        completed_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      }
      |> ExportJob.changeset()
      |> Repo.insert!(repo_opts)

    retention_run =
      %{
        status: "completed",
        deleted_count: 0,
        duration_ms: 1,
        started_at: now,
        completed_at: now
      }
      |> RetentionRun.changeset()
      |> Repo.insert!(repo_opts)

    saved_view =
      %{
        name: "#{label} saved view",
        actor_ref: actor_ref,
        filters: %{"table_schema" => "support", "table" => "tickets", "sentinel" => label}
      }
      |> SavedView.changeset()
      |> Repo.insert!(repo_opts)

    %{
      action: action,
      transaction: transaction,
      change: change,
      evidence: evidence,
      export_job: export_job,
      retention_run: retention_run,
      saved_view: saved_view
    }
  end

  def storage_counts(storage_schema, repo \\ Repo) do
    opts = repo_opts(storage_schema)

    %{
      actions: repo.aggregate(AuditAction, :count, :id, opts),
      transactions: repo.aggregate(AuditTransaction, :count, :id, opts),
      changes: repo.aggregate(AuditChange, :count, :id, opts),
      evidence_records: repo.aggregate(EvidenceRecord, :count, :id, opts),
      export_jobs: repo.aggregate(ExportJob, :count, :id, opts),
      retention_runs: repo.aggregate(RetentionRun, :count, :id, opts),
      saved_views: repo.aggregate(SavedView, :count, :id, opts)
    }
  end

  def clean_storage_schemas!(schemas \\ @known_storage_schemas, repo \\ Repo)
      when is_list(schemas) do
    Enum.each(schemas, &clean_storage_schema!(&1, repo))
    :ok
  end

  def clean_storage_schema!(storage_schema, repo \\ Repo) do
    storage_schema = StorageSchema.validate!(storage_schema)

    if storage_schema_exists?(repo, storage_schema) do
      for schema <- @cleanup_order,
          table_exists?(repo, storage_schema, schema.__schema__(:source)) do
        repo.delete_all(schema, repo_opts(storage_schema))
      end
    end

    :ok
  end

  defp storage_schema_exists?(repo, storage_schema) do
    %{rows: [[exists?]]} =
      SQL.query!(
        repo,
        "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = $1)",
        [storage_schema]
      )

    exists?
  end

  defp table_exists?(repo, storage_schema, table) do
    %{rows: [[exists?]]} =
      SQL.query!(
        repo,
        """
        SELECT EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = $1 AND table_name = $2
        )
        """,
        [storage_schema, table]
      )

    exists?
  end

  defp actor_ref!(id) do
    {:ok, actor_ref} = ActorRef.new(:system, id)
    actor_ref
  end
end
