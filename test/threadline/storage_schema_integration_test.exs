defmodule Threadline.StorageSchemaIntegrationTest do
  use Threadline.DataCase

  alias Ecto.Adapters.SQL
  alias Threadline.{Evidence, Export, Retention}
  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Governance.RetentionRun
  alias Threadline.Semantics.ActorRef
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

  describe "custom audit storage isolation matrix" do
    test "trigger-fired capture writes support.tickets changes to audit storage only" do
      prepare_dual_storage!()
      prepare_support_tickets_table!(storage_schema: "audit")

      insert_storage_sentinel!("threadline", label: "threadline-trigger-sentinel")
      insert_support_ticket!("ticket-audit-capture", subject: "Captured in audit storage")

      audit_results =
        Threadline.timeline(
          [repo: Repo, table_schema: "support", table: "tickets"],
          storage_schema: "audit"
        )

      assert Enum.any?(audit_results, &(&1.table_pk == %{"id" => "ticket-audit-capture"}))
      refute Enum.any?(audit_results, &(&1.table_pk == %{"id" => "threadline-trigger-sentinel"}))

      assert storage_counts("threadline").changes == 1
      assert storage_counts("audit").changes == 1
    end

    test "query correlation preloads return only audit semantic action rows" do
      prepare_dual_storage!()
      prepare_support_tickets_table!(storage_schema: "audit")

      insert_storage_sentinel!("threadline", label: "threadline-correlation-sentinel")
      insert_support_ticket!("ticket-action-link", subject: "Before action")
      actor_ref = actor_ref!("operator-1")

      assert {:ok, %{audit_transaction_id: audit_transaction_id}} =
               Threadline.Audit.transaction(
                 Repo,
                 [
                   storage_schema: "audit",
                   actor_ref: actor_ref,
                   action: :ticket_closed,
                   correlation_id: "audit-correlation"
                 ],
                 fn ->
                   update_support_ticket!("ticket-action-link", status: "closed")
                   %{ticket_id: "ticket-action-link"}
                 end
               )

      assert Repo.get(AuditTransaction, audit_transaction_id, repo_opts("audit"))

      audit_results =
        Threadline.timeline(
          [repo: Repo, correlation_id: "audit-correlation"],
          storage_schema: "audit"
        )

      assert [change] = audit_results
      assert change.table_schema == "support"
      assert change.table_name == "tickets"
      assert change.table_pk == %{"id" => "ticket-action-link"}
      assert change.transaction.action.correlation_id == "audit-correlation"

      assert Threadline.timeline(repo: Repo, correlation_id: "audit-correlation") == []
    end

    test "evidence, export, and retention operate only on selected audit storage" do
      prepare_dual_storage!()
      configure_retention_for_integration!()

      old = DateTime.add(DateTime.utc_now(:microsecond), -10, :day)

      insert_storage_sentinel!("threadline",
        label: "threadline-governance-sentinel",
        occurred_at: old,
        captured_at: old
      )

      audit_sentinel =
        insert_storage_sentinel!("audit",
          label: "audit-governance-sentinel",
          occurred_at: old,
          captured_at: old
        )

      assert {:ok, evidence} =
               Evidence.record_retention_run(
                 %{run_id: "audit-evidence"},
                 %{summary_status: "completed", detail: %{"deleted_count" => 1}},
                 repo: Repo,
                 storage_schema: "audit"
               )

      assert [%{id: evidence_id}] =
               Evidence.list_history([repo: Repo, subject: :retention_run],
                 storage_schema: "audit",
                 limit: 1
               )

      assert evidence_id == evidence.id

      assert {:ok, %{data: data}} =
               Export.to_json_document([repo: Repo, table: "tickets"], storage_schema: "audit")

      exported_ids =
        data
        |> IO.iodata_to_binary()
        |> Jason.decode!()
        |> Map.fetch!("changes")
        |> Enum.map(&get_in(&1, ["table_pk", "id"]))

      assert "audit-governance-sentinel" in exported_ids
      refute "threadline-governance-sentinel" in exported_ids

      assert %{deleted_changes: 1, deleted_transactions: 1} =
               Retention.purge(
                 repo: Repo,
                 storage_schema: "audit",
                 batch_size: 10,
                 max_batches: 10,
                 sleep_ms: 0
               )

      refute Repo.get(AuditChange, audit_sentinel.change.id, repo_opts("audit"))
      assert storage_counts("threadline").changes == 1
      assert Repo.aggregate(RetentionRun, :count, :id, repo_opts("audit")) == 2
      assert Repo.aggregate(RetentionRun, :count, :id, repo_opts("threadline")) == 1
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

  defp actor_ref!(id) do
    {:ok, actor_ref} = ActorRef.new(:user, id)
    actor_ref
  end

  defp configure_retention_for_integration! do
    previous = Application.get_env(:threadline, :retention)

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    on_exit(fn ->
      if previous do
        Application.put_env(:threadline, :retention, previous)
      else
        Application.delete_env(:threadline, :retention)
      end
    end)
  end
end
