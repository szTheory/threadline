defmodule Threadline.Capture.TriggerContextTest do
  use Threadline.DataCase

  alias Threadline.Capture.AuditTransaction

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS test_audit_target_ctx (
      id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name  text NOT NULL,
      value integer
    )
    """)

    Repo.query!(Threadline.Capture.TriggerSQL.create_trigger("test_audit_target_ctx"))

    on_exit(fn ->
      Repo.query!(Threadline.Capture.TriggerSQL.drop_trigger("test_audit_target_ctx"))
      Repo.query!("DROP TABLE IF EXISTS test_audit_target_ctx")
    end)

    :ok
  end

  setup do
    Repo.query!("TRUNCATE test_audit_target_ctx CASCADE")
    :ok
  end

  test "transaction-local GUC populates audit_transactions.actor_ref (CTX-03)" do
    json = Jason.encode!(%{"type" => "user", "id" => "u1"})

    Repo.transaction(fn ->
      Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
      Repo.query!("INSERT INTO test_audit_target_ctx (name, value) VALUES ('with-ctx', 1)")
    end)

    assert [%AuditTransaction{} = txn] = Repo.all(AuditTransaction)
    assert %Threadline.Semantics.ActorRef{type: :user, id: "u1"} = txn.actor_ref
  end

  test "when GUC is unset, audit_transactions.actor_ref is NULL (CTX-04)" do
    Repo.query!("INSERT INTO test_audit_target_ctx (name, value) VALUES ('no-ctx', 2)")

    assert [%AuditTransaction{} = txn] = Repo.all(AuditTransaction)
    assert is_nil(txn.actor_ref)
  end
end
