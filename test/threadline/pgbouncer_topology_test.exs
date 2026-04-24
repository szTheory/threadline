defmodule Threadline.PgbouncerTopologyTest do
  @moduledoc """
  Runs only when `THREADLINE_PGBOUNCER_TOPOLOGY=1` (see `mix threadline.verify_topology`).

  Exercises capture + transaction-local GUC through **PgBouncer transaction pooling** —
  DDL for the fixture table is applied by `priv/ci/topology_bootstrap.exs`, not here.
  """
  use ExUnit.Case, async: false

  import Ecto.Query, only: [from: 2]

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.AuditAction
  alias Threadline.Test.Repo

  @moduletag :pgbouncer_topology

  @table "threadline_pooler_topology_ctx"

  setup do
    Repo.delete_all(AuditChange)
    Repo.delete_all(AuditTransaction)
    Repo.delete_all(AuditAction)

    Repo.query!("ALTER TABLE #{@table} DISABLE TRIGGER USER")
    Repo.query!("DELETE FROM #{@table}")
    Repo.query!("ALTER TABLE #{@table} ENABLE TRIGGER USER")
    :ok
  end

  test "GUC + audited insert through PgBouncer transaction pool (STG-01 CI)" do
    json = Jason.encode!(%{"type" => "user", "id" => "pooler-ci"})

    Repo.transaction(fn ->
      Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
      Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('through-pgbouncer', 1)")
    end)

    assert [%AuditTransaction{} = txn] =
             Repo.all(from(t in AuditTransaction, order_by: [asc: t.txid]))

    assert %Threadline.Semantics.ActorRef{type: :user, id: "pooler-ci"} = txn.actor_ref
  end
end
