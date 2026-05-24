defmodule ThreadlinePhoenixWeb.OperatorSurfaceTest do
  use ThreadlinePhoenixWeb.ConnCase, async: false

  alias Threadline.Semantics.{ActorRef, AuditContext}
  alias ThreadlinePhoenix.Blog
  alias ThreadlinePhoenix.Repo

  test "anonymous request is rejected", %{conn: conn} do
    conn = get(conn, "/audit/transactions/123")
    assert response(conn, 403) == "Forbidden"
  end

  test "authenticated admin request reaches the surface", %{conn: conn} do
    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> assign(:current_user, %{id: 1, name: "Admin", is_admin: true})
      |> get("/audit/transactions/00000000-0000-0000-0000-000000000000")

    assert html_response(conn, 200) =~ "Transaction Not Found"
  end

  test "support user only sees transactions scoped to their organization", %{conn: conn} do
    {:ok, visible_tx} = create_post_for_org("support-org-1", "support-visible")
    {:ok, hidden_tx} = create_post_for_org("support-org-2", "support-hidden")

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> assign(:current_user, %{
        id: 2,
        name: "Support",
        role: :support,
        organization_id: "support-org-1",
        is_admin: false
      })

    visible_conn = get(conn, "/audit/transactions/#{visible_tx}")
    visible_html = html_response(visible_conn, 200)
    refute visible_html =~ "Transaction Not Found"
    assert visible_html =~ "posts"

    hidden_conn = get(conn, "/audit/transactions/#{hidden_tx}")
    assert html_response(hidden_conn, 200) =~ "Transaction Not Found"
  end

  test "support user cannot export from the shared operator surface", %{conn: conn} do
    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> assign(:current_user, %{
        id: 2,
        name: "Support",
        role: :support,
        organization_id: "support-org-1",
        is_admin: false
      })

    export_conn =
      get(conn, "/audit/exports/changes.csv?from=2020-01-01T00:00&to=2099-01-01T00:00")

    assert response(export_conn, 403) == "forbidden"
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
