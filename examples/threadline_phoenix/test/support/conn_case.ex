defmodule ThreadlinePhoenixWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ThreadlinePhoenixWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.

  ## Authentication helpers

  - `sigra_conn/2` — stages auth through the `:user_token` session key (compatible
    with `fetch_current_scope/2` on the `:api` pipeline).
  - `login_via_sigra/3` — default `:http` POSTs `/users/log_in` through the real plug chain;
    pass `mode: :session` for a faster session-token path when HTTP login is flaky.
  """

  use ExUnit.CaseTemplate
  use ThreadlinePhoenixWeb, :verified_routes

  import Phoenix.ConnTest

  using do
    quote do
      # The default endpoint for testing
      @endpoint ThreadlinePhoenixWeb.Endpoint

      use ThreadlinePhoenixWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ThreadlinePhoenixWeb.ConnCaseHelpers
      import ThreadlinePhoenixWeb.ConnCase
    end
  end

  setup tags do
    ThreadlinePhoenix.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def sigra_conn(conn, attrs \\ %{}) do
    alias ThreadlinePhoenix.Accounts
    alias ThreadlinePhoenix.Accounts.UserSession
    alias ThreadlinePhoenix.Repo

    user = Map.get(attrs, :user) || ThreadlinePhoenix.AccountsFixtures.user_fixture()
    token = Accounts.generate_user_session_token(user)

    if org_id = Map.get(attrs, :active_organization_id) do
      {_authed_user, session} = Accounts.get_user_and_session_by_token(token)

      session.id
      |> then(&Repo.get!(UserSession, &1))
      |> Ecto.Changeset.change(%{active_organization_id: org_id})
      |> Repo.update!()
    end

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  @doc """
  Logs `user` in through Sigra.

  Default `mode: :http` exercises the full browser pipeline (session + `fetch_current_scope`).
  Use `mode: :session` for faster tests when HTTP login is flaky.
  """
  def login_via_sigra(conn, user, opts \\ []) do
    password = Keyword.get(opts, :password, "password123456")
    mode = Keyword.get(opts, :mode, :http)

    case mode do
      :http ->
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> post(~p"/users/log_in", %{
          "user" => %{"email" => user.email, "password" => password}
        })

      :session ->
        ThreadlinePhoenixWeb.ConnCaseHelpers.log_in_user(conn, user)
    end
  end
end
