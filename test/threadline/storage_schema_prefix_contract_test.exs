defmodule Threadline.StorageSchemaPrefixContractTest do
  use ExUnit.Case, async: true

  @owned_schemas [
    {Threadline.Capture.AuditTransaction, "lib/threadline/capture/audit_transaction.ex",
     "audit_transactions"},
    {Threadline.Capture.AuditChange, "lib/threadline/capture/audit_change.ex", "audit_changes"},
    {Threadline.Semantics.AuditAction, "lib/threadline/semantics/audit_action.ex",
     "audit_actions"},
    {Threadline.Governance.EvidenceRecord, "lib/threadline/governance/evidence_record.ex",
     "threadline_evidence_records"},
    {Threadline.Governance.ExportJob, "lib/threadline/governance/export_job.ex",
     "threadline_export_jobs"},
    {Threadline.Governance.RetentionRun, "lib/threadline/governance/retention_run.ex",
     "threadline_retention_runs"},
    {Threadline.Governance.SavedView, "lib/threadline/governance/saved_view.ex",
     "threadline_saved_views"}
  ]

  test "owned Threadline schemas do not force the default storage prefix" do
    for {module, _path, source} <- @owned_schemas do
      assert module.__schema__(:source) == source
      assert module.__schema__(:prefix) == nil
    end
  end

  test "owned schema source files cannot reintroduce the default prefix attribute" do
    for {_module, path, _source} <- @owned_schemas do
      source = File.read!(path)

      refute source =~ ~s(@schema_prefix "threadline"),
             "#{path} must rely on Repo prefix options, not a fixed schema prefix"
    end
  end
end

defmodule Threadline.StorageSchemaCaseContractTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias Threadline.StorageSchemaCase
  alias Threadline.Test.Repo

  setup do
    StorageSchemaCase.ensure_storage_schema!("audit")
    StorageSchemaCase.clean_storage_schemas!(["threadline", "audit"])

    on_exit(fn ->
      StorageSchemaCase.clean_storage_schemas!(["threadline", "audit"])
    end)

    :ok
  end

  test "repo option helpers support insert, fetch, delete, and clean for custom storage" do
    opts = StorageSchemaCase.repo_opts("audit")
    txn = insert_transaction!(opts, %{txid: System.unique_integer([:positive])})

    assert %AuditTransaction{id: id} = Repo.get!(AuditTransaction, txn.id, opts)

    {1, nil} = Repo.delete_all(from(at in AuditTransaction, where: at.id == ^id), opts)
    assert Repo.get(AuditTransaction, id, opts) == nil
  end

  test "temporary storage schema helper restores application config after success and errors" do
    original = Application.get_env(:threadline, :storage_schema)

    assert "audit" =
             StorageSchemaCase.with_storage_schema("audit", fn ->
               Application.get_env(:threadline, :storage_schema)
             end)

    assert Application.get_env(:threadline, :storage_schema) == original

    assert_raise RuntimeError, "boom", fn ->
      StorageSchemaCase.with_storage_schema("audit", fn ->
        raise "boom"
      end)
    end

    assert Application.get_env(:threadline, :storage_schema) == original
  end

  test "cleanup removes default and custom storage rows in FK-safe order" do
    for schema <- ["threadline", "audit"] do
      opts = StorageSchemaCase.repo_opts(schema)

      action = insert_action!(opts)
      txn = insert_transaction!(opts, %{action_id: action.id})
      insert_change!(txn, opts)

      assert Repo.aggregate(AuditChange, :count, :id, opts) == 1
      assert Repo.aggregate(AuditTransaction, :count, :id, opts) == 1
      assert Repo.aggregate(AuditAction, :count, :id, opts) == 1
    end

    StorageSchemaCase.clean_storage_schemas!(["threadline", "audit"])

    for schema <- ["threadline", "audit"] do
      opts = StorageSchemaCase.repo_opts(schema)

      assert Repo.aggregate(AuditChange, :count, :id, opts) == 0
      assert Repo.aggregate(AuditTransaction, :count, :id, opts) == 0
      assert Repo.aggregate(AuditAction, :count, :id, opts) == 0
    end
  end

  defp insert_action!(opts) do
    {:ok, actor_ref} = ActorRef.new(:user, "storage-schema-case")

    %{
      name: "storage_schema.case",
      actor_ref: actor_ref,
      status: :ok
    }
    |> AuditAction.changeset()
    |> Repo.insert!(opts)
  end

  defp insert_transaction!(opts, attrs) do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    defaults
    |> Map.merge(attrs)
    |> AuditTransaction.changeset()
    |> Repo.insert!(opts)
  end

  defp insert_change!(txn, opts) do
    %{
      transaction_id: txn.id,
      table_schema: "public",
      table_name: "users",
      table_pk: %{"id" => "storage-schema-case"},
      op: "insert",
      data_after: %{"id" => "storage-schema-case"},
      changed_fields: ["id"],
      captured_at: DateTime.utc_now()
    }
    |> AuditChange.changeset()
    |> Repo.insert!(opts)
  end
end
