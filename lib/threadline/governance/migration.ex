defmodule Threadline.Governance.Migration do
  @moduledoc false

  alias Threadline.StorageSchema

  # The generated migration is assembled from ordered parts: the module header,
  # the `up` statements (schema, the four tables, then the evidence indexes), and
  # the `down` statements in reverse dependency order. Each statement is a
  # heredoc ending in a newline, and statements are joined with one blank line.
  # The output is pinned byte for byte in the storage schema migration contract
  # test, because adopters have already run it.

  @doc """
  Returns the full migration content as a string, ready to write to a `.exs` file.
  """
  def migration_content do
    names = migration_names()

    IO.iodata_to_binary([
      """
      defmodule ThreadlineGovernanceSchema do
        use Ecto.Migration

        def up do
      """,
      Enum.join(up_statements(names), "\n"),
      """
        end

        def down do
      """,
      Enum.join(down_statements(names), "\n"),
      """
        end
      end
      """
    ])
  end

  defp migration_names do
    storage_schema = StorageSchema.get()
    storage_opts = [storage_schema: storage_schema]

    %{
      quoted_schema: StorageSchema.quote_ident(storage_schema),
      export_jobs: StorageSchema.table("threadline_export_jobs", storage_opts),
      retention_runs: StorageSchema.table("threadline_retention_runs", storage_opts),
      saved_views: StorageSchema.table("threadline_saved_views", storage_opts),
      evidence_records: StorageSchema.table("threadline_evidence_records", storage_opts),
      evidence_subject_idx:
        StorageSchema.qualify(storage_schema, "threadline_evidence_records_subject_idx"),
      evidence_recorded_at_idx:
        StorageSchema.qualify(storage_schema, "threadline_evidence_records_recorded_at_idx"),
      evidence_subject_ref_idx:
        StorageSchema.qualify(storage_schema, "threadline_evidence_records_subject_ref_idx")
    }
  end

  defp up_statements(names) do
    [
      create_schema(names),
      create_export_jobs(names),
      create_retention_runs(names),
      create_saved_views(names),
      create_evidence_records(names)
      | create_evidence_indexes(names)
    ]
  end

  defp create_schema(names) do
    """
        execute \"\"\"
        CREATE SCHEMA IF NOT EXISTS #{names.quoted_schema}
        \"\"\"
    """
  end

  defp create_export_jobs(names) do
    """
        execute \"\"\"
        CREATE TABLE IF NOT EXISTS #{names.export_jobs} (
          id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
          status         text        NOT NULL,
          query_params   jsonb       NOT NULL,
          actor_ref      jsonb,
          file_path      text,
          error_message  text,
          started_at     timestamptz,
          completed_at   timestamptz,
          expires_at     timestamptz,
          inserted_at    timestamptz NOT NULL DEFAULT now(),
          updated_at     timestamptz NOT NULL DEFAULT now()
        )
        \"\"\"
    """
  end

  defp create_retention_runs(names) do
    """
        execute \"\"\"
        CREATE TABLE IF NOT EXISTS #{names.retention_runs} (
          id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
          status         text        NOT NULL,
          deleted_count  integer,
          duration_ms    integer,
          error_message  text,
          started_at     timestamptz,
          completed_at   timestamptz,
          inserted_at    timestamptz NOT NULL DEFAULT now(),
          updated_at     timestamptz NOT NULL DEFAULT now()
        )
        \"\"\"
    """
  end

  defp create_saved_views(names) do
    """
        execute \"\"\"
        CREATE TABLE IF NOT EXISTS #{names.saved_views} (
          id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
          name           text        NOT NULL,
          actor_ref      jsonb       NOT NULL,
          filters        jsonb       NOT NULL,
          inserted_at    timestamptz NOT NULL DEFAULT now(),
          updated_at     timestamptz NOT NULL DEFAULT now()
        )
        \"\"\"
    """
  end

  defp create_evidence_records(names) do
    """
        execute \"\"\"
        CREATE TABLE IF NOT EXISTS #{names.evidence_records} (
          id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
          subject        text        NOT NULL,
          subject_ref    jsonb       NOT NULL,
          summary_status text        NOT NULL,
          recorded_at    timestamptz NOT NULL,
          actor_ref      jsonb,
          provenance     jsonb       NOT NULL DEFAULT '{}'::jsonb,
          detail         jsonb       NOT NULL DEFAULT '{}'::jsonb,
          schema_version integer     NOT NULL DEFAULT 1,
          inserted_at    timestamptz NOT NULL DEFAULT now()
        )
        \"\"\"
    """
  end

  defp create_evidence_indexes(names) do
    [
      """
          execute \"\"\"
          CREATE INDEX IF NOT EXISTS threadline_evidence_records_subject_idx
            ON #{names.evidence_records} (subject)
          \"\"\"
      """,
      """
          execute \"\"\"
          CREATE INDEX IF NOT EXISTS threadline_evidence_records_recorded_at_idx
            ON #{names.evidence_records} (recorded_at)
          \"\"\"
      """,
      """
          execute \"\"\"
          CREATE INDEX IF NOT EXISTS threadline_evidence_records_subject_ref_idx
            ON #{names.evidence_records}
            USING gin (subject_ref)
          \"\"\"
      """
    ]
  end

  # Indexes first, then tables in reverse creation order.
  defp down_statements(names) do
    indexes = [
      names.evidence_subject_ref_idx,
      names.evidence_recorded_at_idx,
      names.evidence_subject_idx
    ]

    tables = [names.evidence_records, names.saved_views, names.retention_runs, names.export_jobs]

    Enum.map(indexes, &drop_statement("INDEX", &1)) ++
      Enum.map(tables, &drop_statement("TABLE", &1))
  end

  defp drop_statement(kind, name) do
    """
        execute \"\"\"
        DROP #{kind} IF EXISTS #{name}
        \"\"\"
    """
  end
end
