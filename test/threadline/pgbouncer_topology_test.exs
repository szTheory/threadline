defmodule Threadline.PgbouncerTopologyTest do
  @moduledoc """
  Runs only when `THREADLINE_PGBOUNCER_TOPOLOGY=1` (see `mix threadline.verify_topology`).

  Exercises capture + transaction-local GUC through **PgBouncer transaction pooling** —
  DDL for the fixture table is applied by `priv/ci/topology_bootstrap.exs`, not here.
  """
  use ExUnit.Case, async: false

  import Ecto.Query, only: [from: 2]
  import Threadline.StorageSchemaCase

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Health
  alias Threadline.Semantics.AuditAction
  alias Threadline.Test.Repo

  @moduletag :pgbouncer_topology

  @table "threadline_pooler_topology_ctx"
  @disabled_table "threadline_pooler_topology_disabled"
  @reader_role "threadline_topology_reader"

  setup do
    Repo.delete_all(AuditChange, repo_opts())
    Repo.delete_all(AuditTransaction, repo_opts())
    Repo.delete_all(AuditAction, repo_opts())

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
             Repo.all(from(t in AuditTransaction, order_by: [asc: t.txid]), repo_opts())

    assert %Threadline.Semantics.ActorRef{type: :user, id: "pooler-ci"} = txn.actor_ref
  end

  test "trigger_findings/1 through PgBouncer as owner and as a zero-grant role (SC1)" do
    owner_findings = Health.trigger_findings(repo: Repo, schema: "public")

    assert [%{code: :capture_trigger_disabled, severity: :error, table: @disabled_table}] =
             Enum.filter(owner_findings, &(&1.table == @disabled_table))

    refute Enum.any?(owner_findings, &(&1.table == @table and &1.severity == :error))

    {:ok, {role_findings, current_user}} =
      Repo.transaction(fn ->
        SQL.query!(Repo, "SET LOCAL ROLE #{@reader_role}", [])

        %{rows: [[current_user]]} = SQL.query!(Repo, "SELECT current_user", [])

        findings = Health.trigger_findings(repo: Repo, schema: "public")

        {findings, current_user}
      end)

    assert current_user == @reader_role
    assert role_findings == owner_findings
  end
end
