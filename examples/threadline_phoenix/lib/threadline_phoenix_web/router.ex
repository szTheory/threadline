defmodule ThreadlinePhoenixWeb.Router do
  use ThreadlinePhoenixWeb, :router

  import ThreadlinePhoenixWeb.UserAuth
  import Ecto.Query, only: [where: 3]
  import Threadline.OperatorSurface.Router
  alias Threadline.Semantics.ActorRef

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: false)
    plug(:put_layout, html: {ThreadlinePhoenixWeb.Layouts, :app})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug :fetch_current_scope
  end

  pipeline :admin_auth do
    plug(:require_authenticated_admin)
  end

  pipeline :operator_browser do
    plug(:put_root_layout, html: {ThreadlinePhoenixWeb.Layouts, :app})
    plug(ThreadlinePhoenixWeb.Plugs.AssignOperatorUser)
  end

  pipeline :operator_auth do
    plug(:require_authenticated_operator)
  end

  def require_authenticated_operator(conn, _opts) do
    cond do
      is_nil(conn.assigns[:current_scope]) ->
        require_authenticated_user(conn, [])

      match?(%{is_admin: true}, conn.assigns[:current_user]) ->
        Plug.Conn.put_session(conn, :threadline_current_user, conn.assigns.current_user)

      match?(
        %{role: :support, organization_id: org_id} when is_binary(org_id) and org_id != "",
        conn.assigns[:current_user]
      ) ->
        Plug.Conn.put_session(conn, :threadline_current_user, conn.assigns.current_user)

      true ->
        render_operator_forbidden(conn)
    end
  end

  defp render_operator_forbidden(conn) do
    conn
    |> Plug.Conn.put_status(:forbidden)
    |> Phoenix.Controller.put_view(html: ThreadlinePhoenixWeb.ErrorHTML)
    |> Phoenix.Controller.render(:"403")
    |> Plug.Conn.halt()
  end

  def require_authenticated_admin(conn, _opts) do
    case conn.assigns[:current_user] do
      %{is_admin: true} = user ->
        Plug.Conn.put_session(conn, :threadline_current_user, user)

      _ ->
        render_operator_forbidden(conn)
    end
  end

  def my_actor_fn(conn) do
    if user = conn.assigns[:current_user] do
      if user.is_admin do
        %ActorRef{type: :user, id: to_string(user.id)}
      else
        nil
      end
    else
      nil
    end
  end

  def my_authorize_fn(%{assigns: assigns}) do
    case assigns[:current_user] do
      %{is_admin: true} ->
        :ok

      %{role: :support, organization_id: org_id} when is_binary(org_id) and org_id != "" ->
        {:ok, %{access: :support_read_only, organization_id: org_id}}

      _ ->
        {:error, :unauthorized}
    end
  end

  def my_export_authorize_fn(%{assigns: assigns}) do
    case assigns[:current_user] do
      %{is_admin: true} -> :ok
      _ -> {:error, :unauthorized}
    end
  end

  def my_evidence_authorize_fn(%{assigns: assigns}) do
    case assigns[:current_user] do
      %{is_admin: true} -> :ok
      _ -> {:error, :unauthorized}
    end
  end

  def my_coverage_authorize_fn(%{assigns: assigns}) do
    case assigns[:current_user] do
      %{is_admin: true} -> :ok
      _ -> {:error, :unauthorized}
    end
  end

  def my_policy_authorize_fn(%{assigns: assigns}) do
    case assigns[:current_user] do
      %{is_admin: true} -> :ok
      _ -> {:error, :unauthorized}
    end
  end

  def scope_operator_query(query, %{organization_id: org_id}, %{surface: :actor_history})
      when is_binary(org_id) and org_id != "" do
    where(query, [at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
  end

  def scope_operator_query(query, %{organization_id: org_id}, %{surface: :transaction_header})
      when is_binary(org_id) and org_id != "" do
    where(query, [at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
  end

  def scope_operator_query(query, %{organization_id: org_id}, %{surface: surface})
      when surface in [:timeline, :transaction, :export, :row_history] and
             is_binary(org_id) and org_id != "" do
    where(query, [_ac, at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
  end

  def scope_operator_query(query, _scope, _context), do: query

  pipeline :api do
    plug(:fetch_session)
    plug(:fetch_current_scope)

    # doc: start: router-pipeline-actor-fn
    plug(:accepts, ["json"])

    plug(Threadline.Plug,
      actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
      context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
    )

    # doc: end: router-pipeline-actor-fn
  end

  scope "/", ThreadlinePhoenixWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
  end

  scope "/api", ThreadlinePhoenixWeb do
    pipe_through(:api)

    post("/posts", PostController, :create)

    get("/audit_transactions/:id/changes", AuditTransactionController, :changes)
  end

  # E2E light-lane proof (Phase 168, A11Y-02 part 2): the operator-surface mount
  # macro requires a literal `:theme` atom and exactly one mount per router, so the
  # env selects the lane at COMPILE time. Default (no env) stays `:dark` — existing
  # dark e2e/demo behavior is unchanged. `THREADLINE_E2E_THEME=system` serves the
  # `:system` lane so Playwright `colorScheme: "light"` resolves the
  # `[data-tl-theme="system"]` light branch (run-e2e.sh forces a recompile so the
  # compile-time gate reflects the current invocation).
  if System.get_env("THREADLINE_E2E_THEME") == "system" do
    scope "/audit" do
      pipe_through([:browser, :operator_browser, :operator_auth])

      threadline_operator_surface("/",
        actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
        authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
        export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
        evidence_authorize_fn: &ThreadlinePhoenixWeb.Router.my_evidence_authorize_fn/1,
        coverage_authorize_fn: &ThreadlinePhoenixWeb.Router.my_coverage_authorize_fn/1,
        policy_authorize_fn: &ThreadlinePhoenixWeb.Router.my_policy_authorize_fn/1,
        scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
        schemas: %{
          "tickets" => ThreadlinePhoenix.HelpDesk.Ticket,
          "ticket_replies" => ThreadlinePhoenix.HelpDesk.TicketReply
        },
        repo: ThreadlinePhoenix.Repo,
        theme: :system
      )
    end
  else
    # doc: start: operator-surface-mount
    scope "/audit" do
      pipe_through([:browser, :operator_browser, :operator_auth])

      threadline_operator_surface("/",
        actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
        authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
        export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
        evidence_authorize_fn: &ThreadlinePhoenixWeb.Router.my_evidence_authorize_fn/1,
        coverage_authorize_fn: &ThreadlinePhoenixWeb.Router.my_coverage_authorize_fn/1,
        policy_authorize_fn: &ThreadlinePhoenixWeb.Router.my_policy_authorize_fn/1,
        scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
        schemas: %{
          "tickets" => ThreadlinePhoenix.HelpDesk.Ticket,
          "ticket_replies" => ThreadlinePhoenix.HelpDesk.TicketReply
        },
        repo: ThreadlinePhoenix.Repo
      )
    end

    # doc: end: operator-surface-mount
  end

  # Sigra authentication

  pipeline :require_authenticated do
    plug :require_authenticated_user
    plug :require_mfa
  end

  pipeline :require_sudo do
    plug Sigra.Plug.RequireSudo, error_handler: ThreadlinePhoenixWeb.AuthErrorHandler
  end

  # Phase 14 Plan 03: organization-aware pipelines (opt-in).
  # Apps that want to gate routes by active organization membership
  # pipe_through :require_org (any active membership) or
  # :require_org_owner (owner role only). Phase 16 wires these to
  # the organization picker + switcher.
  pipeline :require_org do
    plug Sigra.Plug.RequireMembership, error_handler: ThreadlinePhoenixWeb.AuthErrorHandler
  end

  pipeline :require_org_owner do
    plug Sigra.Plug.RequireMembership,
      error_handler: ThreadlinePhoenixWeb.AuthErrorHandler,
      roles: [:owner]
  end

  # MFA challenge (accessible with mfa_pending sessions, D-24)
  scope "/users", ThreadlinePhoenixWeb do
    pipe_through [:browser]

    get "/mfa", MFAChallengeController, :new
    post "/mfa", MFAChallengeController, :create
  end

  scope "/users", ThreadlinePhoenixWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    # Phase 10.1.1 B9: login page is a plain controller, not a LiveView.
    get "/log_in", SessionController, :new

    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create

    post "/log_in", SessionController, :create
    get "/log_in/:token", SessionController, :magic_link

    get "/confirm", ConfirmationController, :new
    post "/confirm", ConfirmationController, :create
    get "/confirm/:token", ConfirmationController, :confirm
    post "/confirm/resend", ConfirmationController, :resend

    get "/reset-password", ResetPasswordController, :new
    post "/reset-password", ResetPasswordController, :create
    get "/reset-password/:token", ResetPasswordController, :edit
    put "/reset-password/:token", ResetPasswordController, :update
  end

  scope "/users", ThreadlinePhoenixWeb do
    pipe_through [:browser, :require_authenticated]

    delete "/log_out", SessionController, :delete

    get "/sudo", Auth.SudoController, :new
    post "/sudo", Auth.SudoController, :create
  end

  scope "/users", ThreadlinePhoenixWeb do
    pipe_through [:browser, :require_authenticated, :require_sudo]
  end

  # Dormant Sigra settings/MFA routes (compile-time verified route targets only).
  scope "/users", ThreadlinePhoenixWeb do
    pipe_through [:browser, :require_authenticated]

    get "/settings", DormantAuthController, :not_available
    get "/reactivation", DormantAuthController, :not_available
    post "/settings/mfa/disable", DormantAuthController, :not_available
    post "/settings/mfa/regenerate", DormantAuthController, :not_available
    post "/settings/mfa/revoke-trust", DormantAuthController, :not_available
    get "/settings/mfa/enroll", DormantAuthController, :not_available
    post "/settings/mfa/confirm", DormantAuthController, :not_available
    post "/settings/mfa/complete", DormantAuthController, :not_available
  end

  if Application.compile_env(:threadline_phoenix, :dev_routes) do
    scope "/dev", ThreadlinePhoenixWeb do
      pipe_through [:browser, :operator_browser]

      post "/help_desk/ticket_reply", HelpDeskDevController, :ticket_reply
    end

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
