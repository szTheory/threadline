defmodule Threadline.StorageSchemaIntegrationTest do
  use Threadline.DataCase

  alias Ecto.Adapters.SQL
  alias Threadline.Test.Repo

  describe "dual-schema storage fixture" do
    test "prepares threadline and audit storage tables plus capture functions" do
      prepare_dual_storage!()

      for schema <- ["threadline", "audit"] do
        assert storage_table_exists?(schema, "audit_transactions")
        assert storage_table_exists?(schema, "audit_changes")
        assert storage_table_exists?(schema, "audit_actions")
        assert storage_table_exists?(schema, "threadline_evidence_records")
        assert storage_table_exists?(schema, "threadline_export_jobs")
        assert storage_table_exists?(schema, "threadline_retention_runs")
        assert storage_table_exists?(schema, "threadline_saved_views")
        assert capture_function_exists?(schema)
      end
    end

    test "seeds plausible sentinels in both storage schemas and cleans them" do
      prepare_dual_storage!()

      default = insert_storage_sentinel!("threadline", label: "default-storage-sentinel")
      selected = insert_storage_sentinel!("audit", label: "selected-storage-sentinel")

      assert default.change.table_pk == %{"id" => "default-storage-sentinel"}
      assert selected.change.table_pk == %{"id" => "selected-storage-sentinel"}

      assert storage_counts("threadline") == %{
               actions: 1,
               transactions: 1,
               changes: 1,
               evidence_records: 1,
               export_jobs: 1,
               retention_runs: 1,
               saved_views: 1
             }

      assert storage_counts("audit") == %{
               actions: 1,
               transactions: 1,
               changes: 1,
               evidence_records: 1,
               export_jobs: 1,
               retention_runs: 1,
               saved_views: 1
             }

      clean_storage_schemas!(["threadline", "audit"])

      assert storage_counts("threadline") == empty_storage_counts()
      assert storage_counts("audit") == empty_storage_counts()
    end
  end

  defp storage_table_exists?(schema, table) do
    %{rows: [[exists?]]} =
      SQL.query!(
        Repo,
        """
        SELECT EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = $1 AND table_name = $2
        )
        """,
        [schema, table]
      )

    exists?
  end

  defp capture_function_exists?(schema) do
    %{rows: [[exists?]]} =
      SQL.query!(
        Repo,
        """
        SELECT EXISTS (
          SELECT 1
          FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
          WHERE n.nspname = $1 AND p.proname = 'threadline_capture_changes'
        )
        """,
        [schema]
      )

    exists?
  end

  defp empty_storage_counts do
    %{
      actions: 0,
      transactions: 0,
      changes: 0,
      evidence_records: 0,
      export_jobs: 0,
      retention_runs: 0,
      saved_views: 0
    }
  end
end
