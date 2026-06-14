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
    assert html =~ "Register"
    assert html =~ "Log in"
    assert html =~ "operator surface is mounted"
    assert html =~ ~s|href="/favicon.ico"|
    refute html =~ "threadline-admin-favicon.svg"
    refute html =~ "Signed in as"
    refute html =~ ~s|href="/audit"|
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
    refute html =~ "Open Threadline admin"
    refute html =~ ~s|href="/audit"|

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "Signed in as"
    assert html =~ email
  end

  test "admin home exposes full operator links", %{conn: conn} do
    user = user_fixture(email: "admin@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "agent")

    conn =
      conn
      |> login_via_sigra(user)
      |> get(~p"/")

    html = html_response(conn, 200)
    assert html =~ "Open Threadline admin"
    assert html =~ ~s|href="/audit"|
    assert html =~ ~s|href="/audit/evidence"|
    assert html =~ ~s|href="/audit/policy/redaction"|
    assert html =~ ~s|href="/audit/coverage"|
  end

  test "support home exposes scoped operator links only", %{conn: conn} do
    user = user_fixture(email: "support-flow-#{System.unique_integer()}@example.com")
    org = organization_fixture()
    membership_fixture(org, user_id: to_string(user.id), role: "support")

    conn =
      conn
      |> login_via_sigra(user)
      |> get(~p"/")

    html = html_response(conn, 200)
    assert html =~ "Open Threadline admin"
    assert html =~ ~s|href="/audit"|
    assert html =~ ~s|href="/audit/timeline?|
    refute html =~ ~s|href="/audit/evidence"|
    refute html =~ ~s|href="/audit/policy/redaction"|
    refute html =~ ~s|href="/audit/coverage"|
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
    assert html =~ ~s|type="image/svg+xml"|
    assert html =~ ~s|href="/images/threadline-admin-favicon.svg"|
    refute html =~ ~s|href="/favicon.ico"|
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

    html = html_response(conn, 403)
    assert html =~ "Operator access required"
    assert html =~ ~s|href="/images/threadline-admin-favicon.svg"|
    refute html == "Forbidden"
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

    assert redirected_to(conn) == ~p"/users/log_in"

    assert get_session(conn, :user_return_to) ==
             "/audit/transactions/00000000-0000-0000-0000-000000000000"
  end
end
