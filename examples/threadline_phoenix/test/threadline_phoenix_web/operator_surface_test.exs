defmodule ThreadlinePhoenixWeb.OperatorSurfaceTest do
  use ThreadlinePhoenixWeb.ConnCase, async: true

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
end
