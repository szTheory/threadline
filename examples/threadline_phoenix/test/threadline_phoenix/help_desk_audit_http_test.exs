defmodule ThreadlinePhoenix.HelpDeskAuditHttpTest do
  use ThreadlinePhoenixWeb.ConnCase, async: false

  import ThreadlinePhoenix.AccountsFixtures
  import ThreadlinePhoenix.HelpDeskFixtures

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.ActorRef
  alias ThreadlinePhoenix.Repo

  test "ticket reply via dev route captures actor_ref from Sigra session" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      user = user_fixture()
      org = organization_fixture()
      membership_fixture(org, user_id: to_string(user.id), role: "agent")
      agent = agent_fixture(org, user_id: to_string(user.id))
      ticket = ticket_fixture(org, agent)

      conn =
        build_conn()
        |> login_via_sigra(user)
        |> recycle()
        |> get(~p"/")

      assert conn.assigns.current_scope.user.id
      assert %ActorRef{type: :user, id: _} = Threadline.Integrations.Sigra.actor_ref_from_conn(conn)

      conn =
        post(conn, ~p"/dev/help_desk/ticket_reply", %{
          "organization_id" => org.id,
          "ticket_id" => ticket.id,
          "body" => "Thanks for contacting support"
        })

      assert %{"audit_transaction_id" => tx_id} = json_response(conn, 200)

      at = Repo.get!(AuditTransaction, tx_id)

      assert %ActorRef{type: :user, id: user_id} = at.actor_ref
      assert user_id == to_string(user.id)
      assert at.meta["organization_id"] == to_string(org.id)
    end)
  end
end
