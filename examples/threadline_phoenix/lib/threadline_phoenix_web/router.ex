defmodule ThreadlinePhoenixWeb.Router do
  use ThreadlinePhoenixWeb, :router
  import Threadline.OperatorSurface.Router
  alias Threadline.Semantics.ActorRef

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :admin_auth do
    plug(:require_authenticated_admin)
  end

  def require_authenticated_admin(conn, _opts) do
    if conn.assigns[:current_user] && conn.assigns[:current_user].is_admin do
      Plug.Conn.put_session(conn, :threadline_current_user, conn.assigns[:current_user])
    else
      conn
      |> Plug.Conn.put_status(403)
      |> Phoenix.Controller.text("Forbidden")
      |> Plug.Conn.halt()
    end
  end

  def my_actor_fn(conn) do
    if user = conn.assigns[:current_user] do
      %ActorRef{type: :user, id: to_string(user.id)}
    else
      nil
    end
  end

  def my_authorize_fn(%{assigns: assigns}) do
    case assigns[:current_user] do
      %{is_admin: true} ->
        :ok

      %{role: :support, organization_id: org_id} ->
        {:ok, %{access: :support_read_only, organization_id: org_id}}

      _ ->
        {:error, :unauthorized}
    end
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

    post("/posts", PostController, :create)

    get("/audit_transactions/:id/changes", AuditTransactionController, :changes)
  end

  # doc: start: operator-surface-mount
  scope "/audit" do
    pipe_through([:browser, :admin_auth])

    threadline_operator_surface("/",
      actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
      authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
      repo: ThreadlinePhoenix.Repo
    )

    # Support-read-only variation on the same `/audit` tree:
    #
    # threadline_operator_surface "/",
    #   actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    #   authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    #   scope_query_fn: &MyApp.Audit.scope_operator_query/3,
    #   exports: false,
    #   repo: ThreadlinePhoenix.Repo
  end

  # doc: end: operator-surface-mount
end
