defmodule ThreadlinePhoenixWeb.UserAuth do
  @moduledoc """
  Authentication helpers for the web layer.

  This module handles login, logout, session management, and
  provides plugs for authentication pipelines. Security-critical
  operations delegate to Sigra library plugs.
  """
  use ThreadlinePhoenixWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  use Gettext, backend: ThreadlinePhoenixWeb.Gettext

  alias ThreadlinePhoenix.Accounts.Scope

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_threadline_phoenix_user_remember_me"
  @impersonator_user_token_key :impersonator_user_token
  @impersonation_return_to_key :impersonation_return_to
  @remember_me_static_options [
    sign: true,
    max_age: @max_age,
    same_site: "Lax",
    http_only: true
  ]

  # Resolve remember-me cookie options at RUNTIME so that the `:cookie_domain`
  # config value is honored without recompiling this module. See Phase 10 D-09.
  #
  # NOTE: `Sigra.Env.current/0` is used instead of `Mix.env/0` directly because
  # the `:mix` application is NOT included in production releases (`mix release`
  # excludes it by design). Calling `Mix.env()` unguarded at runtime in a
  # release raises `UndefinedFunctionError` and breaks remember-me logins.
  defp remember_me_options do
    config = ThreadlinePhoenix.Accounts.sigra_config()
    env = Sigra.Env.current()
    base = Keyword.put(@remember_me_static_options, :secure, env == :prod)

    case config.cookie_domain do
      nil -> base
      domain when is_binary(domain) -> Keyword.put(base, :domain, domain)
    end
  end

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renewal in
  `Plug.Session.COOKIE`.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out.
  """
  def log_in_user(conn, user, params \\ %{}) do
    ip = conn.remote_ip && to_string(:inet.ntoa(conn.remote_ip))
    user_agent = conn |> get_req_header("user-agent") |> List.first() || ""

    token =
      ThreadlinePhoenix.Accounts.generate_user_session_token(user, ip: ip, user_agent: user_agent)

    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  @doc """
  Stores an already-created Sigra session token in the Plug session.

  Use this from controller flows that upgrade an existing Sigra session,
  such as completing MFA verification. It renews the Plug session before
  writing the token, matching `log_in_user/3`'s fixation protection.
  """
  def put_user_session_token(conn, token) when is_binary(token) do
    conn
    |> renew_session()
    |> put_token_in_session(token)
  end

  def begin_impersonation(conn, impersonation_token, admin_token, opts \\ [])
      when is_binary(impersonation_token) and is_binary(admin_token) do
    conn
    |> renew_session()
    |> put_session(@impersonator_user_token_key, admin_token)
    |> maybe_put_impersonation_return_to(Keyword.get(opts, :return_to))
    |> put_token_in_session(impersonation_token)
  end

  def restore_impersonation(conn) do
    case get_session(conn, @impersonator_user_token_key) do
      admin_token when is_binary(admin_token) ->
        conn
        |> renew_session()
        |> put_token_in_session(admin_token)

      _ ->
        clear_auth_session(conn)
    end
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, remember_me_options())
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && ThreadlinePhoenix.Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      ThreadlinePhoenixWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_scope(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    {conn, _user, session, scope} = load_current_scope(conn, user_token)

    conn
    |> put_private(:sigra_session, session)
    |> assign(:current_scope, scope)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  def impersonation_return_to(conn) do
    get_session(conn, @impersonation_return_to_key)
  end

  defp load_current_scope(conn, nil), do: {conn, nil, nil, nil}

  defp load_current_scope(conn, user_token) when is_binary(user_token) do
    case ThreadlinePhoenix.Accounts.get_user_and_session_by_token(user_token) do
      {user, session} ->
        maybe_handle_impersonation(conn, user, session)

      _ ->
        {conn, nil, nil, nil}
    end
  end

  defp maybe_handle_impersonation(conn, user, session) do
    admin_token = get_session(conn, @impersonator_user_token_key)
    admin_user = admin_token && ThreadlinePhoenix.Accounts.get_user_by_session_token(admin_token)
    scope = build_current_scope(user, session, admin_user)

    if is_binary(admin_token) do
      case Sigra.Impersonation.evaluate_timeout(
             ThreadlinePhoenix.Accounts.sigra_config(),
             timeout_scope(scope),
             session,
             admin_token: valid_admin_token(admin_token, admin_user)
           ) do
        {:ok, %{expired?: true, action: :restore_admin}} ->
          restored_conn = restore_impersonation(conn)
          load_current_scope(restored_conn, get_session(restored_conn, :user_token))

        {:ok, %{expired?: true}} ->
          cleared_conn = clear_auth_session(conn)
          {cleared_conn, nil, nil, nil}

        {:ok, _result} ->
          {conn, user, session, scope}
      end
    else
      {conn, user, session, scope}
    end
  end


  defp build_current_scope(user, _session, admin_user) do
    user
    |> Scope.for_user()
    |> maybe_put_impersonating_from(admin_user)
  end


  defp maybe_put_impersonating_from(scope, nil), do: scope
  defp maybe_put_impersonating_from(scope, admin_user), do: %{scope | impersonating_from: admin_user}

  defp valid_admin_token(admin_token, admin_user)
       when is_binary(admin_token) and not is_nil(admin_user),
       do: admin_token

  defp valid_admin_token(_admin_token, _admin_user), do: nil

  defp maybe_put_impersonation_return_to(conn, path) when is_binary(path) do
    put_session(conn, @impersonation_return_to_key, path)
  end

  defp maybe_put_impersonation_return_to(conn, _path), do: conn

  defp clear_auth_session(conn), do: renew_session(conn)

  defp timeout_scope(scope) do
    %{
      user: plain_user(scope.user),
      impersonating_from: plain_user(scope.impersonating_from)
    }
  end

  defp plain_user(nil), do: nil
  defp plain_user(user), do: %{id: user.id}

  @doc """
  Handles mounting and authenticating the current_scope in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_scope` - Assigns current_scope
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_scope to socket assigns based
      on user_token. Redirects to login page if there's no
      logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_scope:

      defmodule ThreadlinePhoenixWeb.PageLive do
        use ThreadlinePhoenixWeb, :live_view

        on_mount {ThreadlinePhoenixWeb.UserAuth, :mount_current_scope}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{ThreadlinePhoenixWeb.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive
      end
  """
  def on_mount(:mount_current_scope, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      if user_token = session["user_token"] do
        admin_user =
          session[@impersonator_user_token_key |> Atom.to_string()]
          |> ThreadlinePhoenix.Accounts.get_user_by_session_token()

        case ThreadlinePhoenix.Accounts.get_user_and_session_by_token(user_token) do
          {user, sigra_session} when not is_nil(user) ->
            build_current_scope(user, sigra_session, admin_user)
          _ ->
            nil
        end
      end
    end)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_scope] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.

  Delegates to `Sigra.Plug.RequireAuthenticated` for the core
  authentication check.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_scope] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  @doc """
  Plug that handles unconfirmed users based on configuration.

  When `:unconfirmed_access` is `:allow_with_banner` (default):
    - Sets info flash reminding the user to confirm their email
    - Allows request to continue

  When `:unconfirmed_access` is `:block`:
    - Auto-resends confirmation email (D-04)
    - Sets error flash and redirects to confirmation page
    - Halts the connection

  ## Usage

  In your router:

      pipe_through [:browser, :require_authenticated_user, :require_confirmed_user]

  Or with explicit mode override:

      plug :require_confirmed_user, unconfirmed_access: :block

  """
  def require_confirmed_user(conn, opts \\ []) do
    user = conn.assigns[:current_scope] && conn.assigns.current_scope.user

    cond do
      is_nil(user) ->
        conn

      user.confirmed_at != nil ->
        conn

      unconfirmed_access_mode(opts) == :allow_with_banner ->
        conn
        |> put_flash(:info, dgettext("sigra", "Please confirm your email. Check your inbox or request a new confirmation email."))

      unconfirmed_access_mode(opts) == :block ->
        # D-04: auto-resend confirmation on blocked login attempt
        ThreadlinePhoenix.Accounts.deliver_user_confirmation_instructions(
          user,
          &url(conn, ~p"/users/confirm/#{&1}")
        )

        conn
        |> put_flash(:error, dgettext("sigra", "You must confirm your email before logging in. We've sent a new confirmation email."))
        |> redirect(to: ~p"/users/confirm")
        |> halt()
    end
  end

  defp unconfirmed_access_mode(opts) do
    Keyword.get(opts, :unconfirmed_access, :allow_with_banner)
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  @doc """
  Used for routes that require the user to have completed MFA verification.

  If the user has MFA enabled and the session is in `mfa_pending` state,
  redirects to the MFA challenge page. Delegates to `Sigra.Plug.RequireMFA`
  for the core check.

  Per D-33: auto-inserted into authenticated pipeline by generator.
  """
  def require_mfa(conn, _opts) do
    scope = conn.assigns[:current_scope]

    if scope && match?(%{type: :mfa_pending}, conn.private[:sigra_session]) do
      conn
      |> maybe_store_return_to()
      |> put_session(:mfa_return_to, current_path(conn))
      |> redirect(to: ~p"/users/mfa")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Plug that checks if the user must change their password.

  If `must_change_password` is true on the current user, redirects to
  the settings page password section. The settings page itself is
  exempt from this check to avoid redirect loops.

  Delegates to `Sigra.Plug.RequirePasswordChange` pattern (D-38).

  ## Usage

  In your router, add after `require_authenticated_user`:

      pipe_through [:browser, :require_authenticated_user, :require_password_unchanged]

  """
  def require_password_unchanged(conn, _opts) do
    user = conn.assigns[:current_scope] && conn.assigns.current_scope.user

    if user && Map.get(user, :must_change_password, false) do
      conn
      |> put_flash(:error, "You must change your password before you can continue using your account.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/settings#password")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Plug that checks if the user's account is scheduled for deletion.

  If the user has a non-nil `deleted_at`, redirects to the reactivation
  page where they can cancel the deletion or sign out (D-15, T-8-15).

  ## Usage

  In your router, add after `require_authenticated_user`:

      pipe_through [:browser, :require_authenticated_user, :check_account_active]

  """
  def check_account_active(conn, _opts) do
    user = conn.assigns[:current_scope] && conn.assigns.current_scope.user

    if user && user.deleted_at do
      conn
      |> redirect(to: ~p"/users/reactivation")
      |> halt()
    else
      conn
    end
  end

  defp signed_in_path(_conn), do: ~p"/"
end
