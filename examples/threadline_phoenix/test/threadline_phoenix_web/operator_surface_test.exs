defmodule ThreadlinePhoenixWeb.OperatorSurfaceTest do
  use ThreadlinePhoenixWeb.ConnCase, async: false

  import Ecto.Query
  import ThreadlinePhoenix.AccountsFixtures
  import ThreadlinePhoenix.HelpDeskFixtures

  alias Threadline.Capture.AuditChange
  alias Threadline.Semantics.{ActorRef, AuditContext}
  alias ThreadlinePhoenix.Blog
  alias ThreadlinePhoenix.Demo.Tables
  alias ThreadlinePhoenix.HelpDesk
  alias ThreadlinePhoenix.Repo

  test "anonymous request is rejected", %{conn: conn} do
    conn = get(conn, "/audit/transactions/123")
    assert response(conn, 403) == "Forbidden"
  end

  test "authenticated admin request reaches the surface", %{conn: conn} do
    user = user_fixture(email: "admin@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "agent")

    conn =
      conn
      |> login_via_sigra(user)
      |> get("/audit/transactions/00000000-0000-0000-0000-000000000000")

    assert html_response(conn, 200) =~ "Transaction Not Found"
  end

  test "support user only sees transactions scoped to their organization", %{conn: conn} do
    user = user_fixture(email: "support@example.com")
    org1 = organization_fixture()
    org2 = organization_fixture()
    membership_fixture(org1, user_id: to_string(user.id), role: "support")

    {:ok, visible_tx} = create_post_for_org(to_string(org1.id), "support-visible")
    {:ok, hidden_tx} = create_post_for_org(to_string(org2.id), "support-hidden")

    conn = login_via_sigra(conn, user)

    visible_conn = get(conn, "/audit/transactions/#{visible_tx}")
    visible_html = html_response(visible_conn, 200)
    refute visible_html =~ "Transaction Not Found"
    assert visible_html =~ "posts"

    hidden_conn = get(conn, "/audit/transactions/#{hidden_tx}")
    assert html_response(hidden_conn, 200) =~ "Transaction Not Found"
  end

  test "admin user can reach evidence surface", %{conn: conn} do
    user = user_fixture(email: "admin@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "agent")

    conn =
      conn
      |> login_via_sigra(user)
      |> get("/audit/evidence")

    html = html_response(conn, 200)
    refute html =~ "Evidence view unavailable."
  end

  test "support user sees unsupported evidence view", %{conn: conn} do
    user = user_fixture(email: "support@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "support")

    conn =
      conn
      |> login_via_sigra(user)
      |> get("/audit/evidence")

    assert html_response(conn, 200) =~ "Evidence view unavailable."
  end

  test "support user cannot export from the shared operator surface", %{conn: conn} do
    user = user_fixture(email: "support@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "support")

    conn =
      conn
      |> login_via_sigra(user)
      |> get("/audit/exports/changes.csv?from=2020-01-01T00:00&to=2099-01-01T00:00")

    assert response(conn, 403) == "forbidden"
  end

  test "admin reaches ticket_replies row history via :schemas mount", %{conn: conn} do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      org = organization_fixture()
      agent = agent_fixture(org, %{user_id: "history-admin"})
      ticket = ticket_fixture(org, agent)
      ctx = audit_context_for_user("history-admin")

      assert {:ok, result} =
               HelpDesk.ticket_replied_and_closed(
                 ctx,
                 org,
                 ticket,
                 %{body: "public reply", internal_note_body: nil},
                 %{status: "closed", closed_at: DateTime.utc_now(:second)},
                 []
               )

      reply_change =
        Repo.one!(
          from(ac in AuditChange,
            where: ac.transaction_id == ^result.audit_transaction_id,
            where: ac.table_name == "ticket_replies",
            where: ac.op == "insert"
          )
        )

      reply_pk = reply_change.table_pk["id"]
      tx_id = result.audit_transaction_id

      user = user_fixture(email: "admin@example.com")
      membership_fixture(org, user_id: to_string(user.id), role: "agent")

      conn =
        conn
        |> login_via_sigra(user)
        |> get("/audit/transactions/#{tx_id}/history/ticket_replies/#{reply_pk}")

      html = html_response(conn, 200)
      assert html =~ "Row History: ticket_replies / #{reply_pk}"
      refute html =~ "not mapped to an Ecto schema"

      Repo.query!(Tables.truncate_sql(), [])
    end)
  end

  test "agent membership without admin email receives 403 on audit", %{conn: conn} do
    user = user_fixture(email: "agent-only@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "agent")

    conn =
      conn
      |> login_via_sigra(user)
      |> get("/audit")

    assert response(conn, 403) == "Forbidden"
  end

  defp create_post_for_org(org_id, slug) do
    unique_slug = "#{slug}-#{System.unique_integer([:positive])}"

    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      {:ok, actor_ref} = ActorRef.new(:user, "support-#{org_id}")

      audit_context = %AuditContext{
        actor_ref: actor_ref,
        request_id: "req-#{unique_slug}",
        correlation_id: "corr-#{unique_slug}"
      }

      with {:ok, %{audit_transaction_id: tx_id}} <-
             Blog.create_post(audit_context, %{title: unique_slug, slug: unique_slug},
               organization_id: org_id
             ),
           true <- is_binary(tx_id) do
        {:ok, tx_id}
      else
        _ -> {:error, :missing_audit_transaction_id}
      end
    end)
  end
end
