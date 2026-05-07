defmodule ThreadlinePhoenixWeb.Router do
  use ThreadlinePhoenixWeb, :router
  import Threadline.OperatorSurface.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin_auth do
    plug :require_authenticated_admin
  end

  def require_authenticated_admin(conn, _opts) do
    if conn.assigns[:current_user] && conn.assigns[:current_user].is_admin do
      conn
    else
      conn
      |> Plug.Conn.put_status(403)
      |> Phoenix.Controller.text("Forbidden")
      |> Plug.Conn.halt()
    end
  end

  def my_actor_fn(conn) do
    if user = conn.assigns[:current_user] do
      %{
        id: to_string(user.id),
        name: user.name || "Admin",
        role: "admin",
        avatar_url: nil
      }
    else
      nil
    end
  end

  def my_authorize_fn(%Plug.Conn{} = conn) do
    if conn.assigns[:current_user] && conn.assigns[:current_user].is_admin do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  def my_authorize_fn(%Phoenix.LiveView.Socket{} = _socket) do
    :ok
  end

  pipeline :api do
    # doc: start: router-pipeline-actor-fn
    plug(:accepts, ["json"])

    plug(Threadline.Plug,
      actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
      context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
    )

    # doc: end: router-pipeline-actor-fn
  end

  scope "/api", ThreadlinePhoenixWeb do
    pipe_through(:api)

    post "/posts", PostController, :create

    get "/audit_transactions/:id/changes", AuditTransactionController, :changes
  end

  # doc: start: operator-surface-mount
  scope "/audit" do
    pipe_through [:browser, :admin_auth]

    threadline_operator_surface "/",
      actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
      authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
      repo: ThreadlinePhoenix.Repo
  end
  # doc: end: operator-surface-mount
end
