defmodule ThreadlinePhoenix.HelpDeskAuditTest do
  use ThreadlinePhoenix.DataCase, async: false

  import Ecto.Query
  import ThreadlinePhoenix.HelpDeskFixtures

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias ThreadlinePhoenix.HelpDesk
  alias ThreadlinePhoenix.Repo

  @truncate_sql """
  TRUNCATE TABLE
    ticket_replies,
    tickets,
    agents,
    org_memberships,
    organizations,
    audit_changes,
    audit_transactions,
    audit_actions
  RESTART IDENTITY CASCADE
  """

  test "ticket_replied_and_closed captures multi-table write with masked internal note" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      org = organization_fixture()
      agent = agent_fixture(org, %{user_id: "agent-user-1"})
      ticket = ticket_fixture(org, agent)
      note_secret = "super-secret-internal-#{System.unique_integer([:positive])}"
      ctx = audit_context_for_user("agent-user-1")

      assert {:ok, result} =
               HelpDesk.ticket_replied_and_closed(
                 ctx,
                 org,
                 ticket,
                 %{body: "public reply", internal_note_body: note_secret},
                 %{status: "closed", closed_at: DateTime.utc_now(:second)},
                 []
               )

      changes =
        Repo.all(
          from(ac in AuditChange,
            where: ac.transaction_id == ^result.audit_transaction_id,
            where: ac.table_name in ["tickets", "ticket_replies"]
          )
        )

      assert length(changes) == 2

      at = Repo.get!(AuditTransaction, result.audit_transaction_id)
      assert at.meta["organization_id"] == to_string(org.id)
      assert %ActorRef{type: :user, id: "agent-user-1"} = at.actor_ref

      action =
        Repo.one!(
          from(a in AuditAction,
            where: a.id == ^at.action_id,
            where: a.name == "ticket_replied_and_closed"
          )
        )

      refute is_nil(action)

      reply_change =
        Enum.find(changes, &(&1.table_name == "ticket_replies" and &1.op == "insert"))

      refute is_nil(reply_change)
      encoded = Jason.encode!(reply_change.data_after)
      assert encoded =~ "[REDACTED]"
      refute encoded =~ note_secret

      Repo.query!(@truncate_sql, [])
    end)
  end

  test "hard delete on ticket_reply produces delete audit row" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      org = organization_fixture()
      agent = agent_fixture(org, %{user_id: "agent-user-2"})
      ticket = ticket_fixture(org, agent)
      ctx = audit_context_for_user("agent-user-2")

      assert {:ok, %{reply: reply}} =
               HelpDesk.ticket_replied_and_closed(
                 ctx,
                 org,
                 ticket,
                 %{body: "to delete", internal_note_body: nil},
                 %{status: "closed", closed_at: DateTime.utc_now(:second)},
                 []
               )

      {:ok, actor_ref} = ActorRef.new(:user, "agent-user-2")
      json = actor_ref |> ActorRef.to_map() |> Jason.encode!()

      Repo.transaction(fn ->
        Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
        Repo.delete!(reply)

        {1, _} =
          Repo.update_all(
            from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
            set: [meta: %{"organization_id" => to_string(org.id)}]
          )
      end)

      delete_change =
        Repo.one!(
          from(ac in AuditChange,
            where: ac.table_name == "ticket_replies",
            where: ac.op == "delete",
            where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(reply.id)),
            order_by: [desc: ac.captured_at]
          )
        )

      assert delete_change.changed_fields == nil
      assert delete_change.data_after == nil

      Repo.query!(@truncate_sql, [])
    end)
  end
end
