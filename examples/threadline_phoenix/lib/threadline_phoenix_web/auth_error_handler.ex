defmodule ThreadlinePhoenixWeb.AuthErrorHandler do
  @moduledoc """
  Default error handler for Sigra authentication errors.

  Implements `Sigra.Plug.ErrorHandler` to handle authentication
  failures with appropriate redirects and error messages.

  Clauses for `:no_active_org` and `:insufficient_role` are generated
  by Sigra for organization-aware routes. Edit the redirect target or
  message to match your product's tone.
  """

  @behaviour Sigra.Plug.ErrorHandler

  use ThreadlinePhoenixWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  @impl true
  def auth_error(conn, :unauthenticated, _opts) do
    conn
    |> put_flash(:error, "You must log in to access this page.")
    |> redirect(to: ~p"/users/log_in")
  end

  @impl true
  def auth_error(conn, :stale_sudo, _opts) do
    conn
    |> put_flash(:error, "Please re-enter your password to continue.")
    |> redirect(to: ~p"/users/log_in")
  end

  @impl true
  def auth_error(conn, :rate_limited, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(429, "Too many requests. Please try again later.")
  end


  # Phase 24.1: under --no-organizations the /organizations route is
  # not wired, so the :no_active_org branch is unreachable (it is only
  # produced by org-related plugs which are also omitted under
  # --no-organizations). Stub it to root so the behaviour is fully
  # covered and the host app compiles under --warnings-as-errors.
  @impl true
  def auth_error(conn, :no_active_org, _opts) do
    redirect(conn, to: ~p"/")
  end


  @impl true
  def auth_error(conn, :insufficient_role, _opts) do
    conn
    |> put_flash(:error, "You don't have permission to access this page in the current organization.")
    |> put_status(:forbidden)
    |> put_view(ThreadlinePhoenixWeb.ErrorHTML)
    |> render(:"403")
    |> halt()
  end
end
