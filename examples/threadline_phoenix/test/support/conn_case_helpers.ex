defmodule ThreadlinePhoenixWeb.ConnCaseHelpers do
  @moduledoc """
  Authentication test helpers for ConnCase.

  Import this module in your ConnCase to get authentication
  helper functions for integration tests.

  ## Setup

  Add to your `test/support/conn_case.ex`:

      import ThreadlinePhoenixWeb.ConnCaseHelpers

  Also add to your `config/test.exs`:

      # Speed up password hashing in tests
      config :argon2_elixir, t_cost: 1, m_cost: 8
  """

  @doc """
  Sets up the connection with a logged-in user.

  It creates a new user, generates a session token, and puts
  the token in the connection session.

      setup :register_and_log_in_user

  Alternatively, you can log in an existing user:

      user = user_fixture()
      conn = log_in_user(conn, user)

  """
  def register_and_log_in_user(%{conn: conn}) do
    user = ThreadlinePhoenix.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.

  ## Options

    * `:type` - Session type, either `:standard` (default) or `:remember_me`

  """
  def log_in_user(conn, user, opts \\ []) do
    type = Keyword.get(opts, :type, :standard)
    token = ThreadlinePhoenix.Accounts.generate_user_session_token(user, type: type)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
