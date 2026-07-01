defmodule Threadline.AuditTransactionTest do
  use Threadline.DataCase

  @moduletag :integration

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.ActorRef
  alias Threadline.Semantics.AuditAction
  alias Threadline.StorageSchema

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS test_audit_helper_target (
      id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name  text NOT NULL
    )
    """)

    Repo.query!(Threadline.Capture.TriggerSQL.create_trigger("test_audit_helper_target"))

    on_exit(fn ->
      Repo.query!(Threadline.Capture.TriggerSQL.drop_trigger("test_audit_helper_target"))
      Repo.query!("DROP TABLE IF EXISTS test_audit_helper_target")
    end)

    :ok
  end

  setup do
    Repo.query!("TRUNCATE test_audit_helper_target CASCADE")
    clean_storage_schemas!()
    :ok
  end

  defp insert_row!(name) do
    Repo.query!("INSERT INTO test_audit_helper_target (name) VALUES ($1)", [name])
  end

  defp insert_current_audit_transaction!(storage_schema) do
    Repo.query!(
      """
      INSERT INTO #{StorageSchema.table("audit_transactions", storage_schema: storage_schema)}
        (id, txid, occurred_at, actor_ref)
      VALUES (gen_random_uuid(), txid_current(), clock_timestamp(), NULL)
      """,
      []
    )
  end

  describe "Threadline.Audit.transaction/3" do
    test "capture under helper with action returns audit_transaction_id envelope" do
      {:ok, actor} = ActorRef.new(:user, "audit-helper-1")

      assert {:ok, %{result: :ok, audit_transaction_id: id}} =
               Threadline.Audit.transaction(
                 Repo,
                 [actor_ref: actor, action: :audit_helper_test_write],
                 fn ->
                   insert_row!("a")
                   :ok
                 end
               )

      assert %ActorRef{type: :user, id: "audit-helper-1"} =
               Repo.get!(AuditTransaction, id, repo_opts()).actor_ref
    end

    test "strict correlation_id timeline matches when action linked" do
      {:ok, actor} = ActorRef.new(:user, "audit-helper-2")

      assert {:ok, _} =
               Threadline.Audit.transaction(
                 Repo,
                 [
                   actor_ref: actor,
                   action: :audit_helper_correlation_test,
                   correlation_id: "audit-helper-corr-1"
                 ],
                 fn ->
                   insert_row!("corr")
                   :ok
                 end
               )

      results =
        Threadline.timeline(
          repo: Repo,
          table: "test_audit_helper_target",
          correlation_id: "audit-helper-corr-1"
        )

      assert length(results) == 1
    end

    test "capture-only does not match strict correlation_id filter" do
      {:ok, actor} = ActorRef.new(:user, "audit-helper-3")

      assert {:ok, _} =
               Threadline.Audit.transaction(
                 Repo,
                 [actor_ref: actor],
                 fn ->
                   insert_row!("no-action")
                   :ok
                 end
               )

      assert [] =
               Threadline.timeline(
                 repo: Repo,
                 table: "test_audit_helper_target",
                 correlation_id: "audit-helper-corr-1"
               )
    end

    @tag :missing_actor
    test "missing actor_ref returns {:error, :missing_actor} by default" do
      assert {:error, :missing_actor} =
               Threadline.Audit.transaction(
                 Repo,
                 [action: :should_fail],
                 fn -> :ok end
               )
    end

    @tag :missing_actor
    test "allow_missing_actor permits capture-only with nil actor" do
      assert {:ok, _} =
               Threadline.Audit.transaction(
                 Repo,
                 [allow_missing_actor: true],
                 fn ->
                   insert_row!("nil-actor")
                   :ok
                 end
               )

      assert [%AuditTransaction{actor_ref: nil}] = Repo.all(AuditTransaction, repo_opts())
    end

    test "map callback merges audit_transaction_id into return map" do
      {:ok, actor} = ActorRef.new(:user, "audit-helper-4")

      assert {:ok, %{name: "merged", audit_transaction_id: id}} =
               Threadline.Audit.transaction(
                 Repo,
                 [actor_ref: actor, action: :audit_helper_map_return],
                 fn ->
                   insert_row!("merged")
                   %{name: "merged"}
                 end
               )

      assert is_binary(id)
    end

    test "domain rollback propagates as {:error, reason}" do
      {:ok, actor} = ActorRef.new(:user, "audit-helper-5")

      assert {:error, :domain_fail} =
               Threadline.Audit.transaction(
                 Repo,
                 [actor_ref: actor, action: :audit_helper_rollback],
                 fn ->
                   Repo.rollback(:domain_fail)
                 end
               )
    end

    test "transaction_meta stored on linked audit_transaction" do
      {:ok, actor} = ActorRef.new(:user, "audit-helper-6")

      assert {:ok, %{audit_transaction_id: id}} =
               Threadline.Audit.transaction(
                 Repo,
                 [
                   actor_ref: actor,
                   action: :audit_helper_meta,
                   transaction_meta: %{"organization_id" => "org-1"}
                 ],
                 fn ->
                   insert_row!("meta")
                   %{}
                 end
               )

      assert Repo.get!(AuditTransaction, id, repo_opts()).meta == %{"organization_id" => "org-1"}
    end

    test "transaction_meta stored on capture-only audit_transaction" do
      {:ok, actor} = ActorRef.new(:user, "audit-helper-capture-meta")

      assert {:ok, %{result: :done, audit_transaction_id: id}} =
               Threadline.Audit.transaction(
                 Repo,
                 [
                   actor_ref: actor,
                   capture_only: true,
                   transaction_meta: %{"organization_id" => "org-capture-only"}
                 ],
                 fn ->
                   insert_row!("capture-meta")
                   :done
                 end
               )

      at = Repo.get!(AuditTransaction, id, repo_opts())
      assert at.meta == %{"organization_id" => "org-capture-only"}
      assert is_nil(at.action_id)
    end

    test "storage_schema option links action, metadata, and lookup in selected storage" do
      ensure_storage_schema!("audit")
      {:ok, actor} = ActorRef.new(:user, "audit-helper-storage")

      sentinel_action =
        Repo.insert!(
          AuditAction.changeset(%AuditAction{}, %{
            name: "audit_helper_storage_schema",
            actor_ref: ActorRef.to_map(actor),
            status: :ok,
            correlation_id: "default-storage-sentinel"
          }),
          repo_opts()
        )

      assert {:ok, %{result: :done, audit_transaction_id: id}} =
               Threadline.Audit.transaction(
                 Repo,
                 [
                   actor_ref: actor,
                   action: :audit_helper_storage_schema,
                   correlation_id: "audit-storage-correlation",
                   transaction_meta: %{"storage" => "audit"},
                   storage_schema: "audit"
                 ],
                 fn ->
                   insert_current_audit_transaction!("audit")
                   :done
                 end
               )

      audit_transaction = Repo.get!(AuditTransaction, id, repo_opts("audit"))
      assert audit_transaction.meta == %{"storage" => "audit"}
      assert audit_transaction.action_id

      audit_action = Repo.get!(AuditAction, audit_transaction.action_id, repo_opts("audit"))
      assert audit_action.name == "audit_helper_storage_schema"
      assert audit_action.correlation_id == "audit-storage-correlation"

      assert Repo.get(AuditTransaction, id, repo_opts()) == nil
      assert Repo.get(AuditAction, audit_action.id, repo_opts()) == nil
      assert Repo.get!(AuditAction, sentinel_action.id, repo_opts()).id == sentinel_action.id
    end

    test "capture-only storage_schema option updates metadata and returns selected transaction id" do
      ensure_storage_schema!("audit")
      {:ok, actor} = ActorRef.new(:user, "audit-helper-storage-capture-only")

      assert {:ok, %{result: :done, audit_transaction_id: id}} =
               Threadline.Audit.transaction(
                 Repo,
                 [
                   actor_ref: actor,
                   capture_only: true,
                   transaction_meta: %{"storage" => "audit-capture-only"},
                   storage_schema: "audit"
                 ],
                 fn ->
                   insert_current_audit_transaction!("audit")
                   :done
                 end
               )

      audit_transaction = Repo.get!(AuditTransaction, id, repo_opts("audit"))
      assert audit_transaction.meta == %{"storage" => "audit-capture-only"}
      assert is_nil(audit_transaction.action_id)
      assert Repo.get(AuditTransaction, id, repo_opts()) == nil
    end
  end
end
