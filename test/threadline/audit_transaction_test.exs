defmodule Threadline.AuditTransactionTest do
  use Threadline.DataCase

  @moduletag :integration

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.ActorRef

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
    Repo.delete_all(AuditTransaction)
    :ok
  end

  defp insert_row!(name) do
    Repo.query!("INSERT INTO test_audit_helper_target (name) VALUES ($1)", [name])
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
               Repo.get!(AuditTransaction, id).actor_ref
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

      assert [%AuditTransaction{actor_ref: nil}] = Repo.all(AuditTransaction)
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

      assert Repo.get!(AuditTransaction, id).meta == %{"organization_id" => "org-1"}
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

      at = Repo.get!(AuditTransaction, id)
      assert at.meta == %{"organization_id" => "org-capture-only"}
      assert is_nil(at.action_id)
    end
  end
end
