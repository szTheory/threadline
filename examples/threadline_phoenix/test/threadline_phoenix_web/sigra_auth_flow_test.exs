defmodule ThreadlinePhoenixWeb.SigraAuthFlowTest do
  @moduledoc """
  ConnCase integration tests for Phase 106 human UAT scenarios.

  Replaces manual browser verification: full Sigra register/login/logout
  and `/audit` authorization through the real browser plug pipeline.
  """
  use ThreadlinePhoenixWeb.ConnCase, async: false

  import ThreadlinePhoenix.AccountsFixtures
  import ThreadlinePhoenix.HelpDeskFixtures

  alias ThreadlinePhoenix.Repo

  @password valid_user_password()

  test "cold start: Sigra users table exists after migrations" do
    assert {:ok, %{num_rows: 0}} = Repo.query("SELECT 1 FROM users LIMIT 0")
  end

  test "logged-out home exposes register and log in links", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "RelayDesk"
    assert html =~ "Support operations demo app"
    assert html =~ "Demo credentials"
    assert html =~ "admin@example.com"
    assert html =~ "Threadline admin"
    assert html =~ "Register"
    assert html =~ "Log in"
    refute html =~ "Signed in as"
  end

  test "register creates account, provisions workspace, and keeps session on reload" do
    email = unique_user_email()

    conn =
      build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})
      |> post(~p"/users/register", %{
        "user" => %{"email" => email, "password" => @password}
      })

    assert redirected_to(conn) == ~p"/"
    conn = get(conn, ~p"/")

    html = html_response(conn, 200)
    assert html =~ "RelayDesk"
    assert html =~ "Signed in as"
    assert html =~ email
    assert html =~ "Open Threadline admin"

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "Signed in as"
    assert html =~ email
  end

  test "admin allowlist email reaches operator audit surface", %{conn: conn} do
    user = user_fixture(email: "admin@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "agent")

    conn =
      conn
      |> login_via_sigra(user)
      |> get(~p"/audit/transactions/00000000-0000-0000-0000-000000000000")

    html = html_response(conn, 200)
    assert html =~ "Transaction Not Found"
    refute html =~ ~s|class="rd-shell"|
    refute html =~ ~s|class="rd-topbar"|
    refute html =~ "RelayDesk Support Ops Demo"
  end

  test "agent without admin allowlist receives 403 on audit", %{conn: conn} do
    user = user_fixture(email: "agent-flow-#{System.unique_integer()}@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "agent")

    conn =
      conn
      |> login_via_sigra(user)
      |> get(~p"/audit")

    assert response(conn, 403) == "Forbidden"
  end

  test "logout clears session and blocks audit access", %{conn: conn} do
    user = user_fixture(email: "logout-flow-#{System.unique_integer()}@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "agent")

    conn =
      conn
      |> login_via_sigra(user)

    conn = delete(conn, ~p"/users/log_out")
    assert redirected_to(conn) == ~p"/"
    refute get_session(conn, :user_token)

    conn =
      get(conn, ~p"/audit/transactions/00000000-0000-0000-0000-000000000000")

    assert response(conn, 403) == "Forbidden"
  end
end
