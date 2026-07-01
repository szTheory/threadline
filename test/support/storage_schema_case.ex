defmodule Threadline.StorageSchemaCase do
  @moduledoc """
  Test helpers for exercising Threadline-owned tables in explicit storage schemas.
  """

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Governance.{EvidenceRecord, ExportJob, RetentionRun, SavedView}
  alias Threadline.Semantics.AuditAction
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
end
