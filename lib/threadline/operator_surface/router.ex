if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Router do
    @moduledoc """
    Mounts Threadline's operator interface in a Phoenix router with host-owned
    authorization and query scoping.

    This module enforces a secure-by-default mount by requiring either:
    1. A `pipe_through` directive in the enclosing router scope.
    2. An explicit `:authorize_fn` option.
    3. An explicit `:adopter_acknowledges_unauthenticated` option.

    ## HTTP endpoints

    When Phoenix is available at compile time, the macro emits a sibling
    `POST <path>/theme` route and a sibling `scope <path>/exports` block with
    GET routes for `/changes.csv`, `/changes.json`, `/changes.ndjson`, and
    completed export downloads. These HTTP endpoints use the mount's
    authorization callbacks independently from the LiveView session.

    The HTTP scopes remain outside `live_session :threadline` because LiveView
    `on_mount` callbacks do not apply to controller routes. Route helper names
    and the host router's alias namespace remain untouched.

    ## Options

    - `:exports` (boolean, default `true`) — set to `false` to suppress the
      sibling export-controller scope (rare LV-only adopters).
    - `:scope_query_fn` (`(Ecto.Query.t(), scope, %{surface: atom(), params: map()} -> Ecto.Query.t())`,
      optional) — host-owned query transform used when `:authorize_fn` returns
      `{:ok, scope}`. Threadline treats `scope` as opaque data and calls this
      function for timeline, actor-history, transaction, and export flows.
    - `:export_authorize_fn` (`(Plug.Conn.t() -> :ok | true | {:ok, scope} | _)`,
      default delegates to `:authorize_fn` via a synthetic
      `%{assigns: conn.assigns}` mirror) — Conn-shaped authorize callback for
      HTTP requests. Use a separate callback when HTTP authorization needs
      more than the assigns inspected by the LiveView callback; the synthetic
      mirror is sufficient when authorization only reads values such as
      `assigns.current_user`.
    - `:coverage_authorize_fn` (`(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`,
      optional) — explicitly gates the coverage dashboard and related badge.
      Defaults to fail closed.
    - `:policy_authorize_fn` (`(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`,
      optional) — explicitly gates policy/retention surfaces. Defaults to fail
      closed.
    - `:evidence_authorize_fn` (`(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`,
      optional) — explicitly gates the mounted evidence surface. Defaults to
      fail closed.
    - `:theme` (`:dark | :light | :system`, default `:dark`) — selects the
      default server-rendered operator-surface theme lane. `:system` follows the
      visitor's OS preference through scoped CSS only. A runtime dark/light/system
      theme picker is available in the shell (session-backed and resolved
      server-side; a response cookie mirrors the choice); Threadline adds no
      JavaScript and no local storage.
    """

    defmacro threadline_operator_surface(path, opts \\ []) do
      has_auth_fn? = Keyword.has_key?(opts, :authorize_fn)
      has_actor_fn? = Keyword.has_key?(opts, :actor_fn)
      has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
      exports_enabled? = Keyword.get(opts, :exports, true)
      theme = Keyword.get(opts, :theme, :dark)
      caller_file = __CALLER__.file
      caller_line = __CALLER__.line

      unless theme in [:dark, :light, :system] do
        raise CompileError,
          file: caller_file,
          line: caller_line,
          description: "Threadline Operator Surface theme must be one of :dark | :light | :system"
      end

      quote do
        _scopes = @phoenix_top_scopes || %{pipes: []}

        _has_pipe? =
          _scopes
          |> List.wrap()
          |> Enum.any?(fn
            %{pipes: [_ | _]} -> true
            _ -> false
          end)

        if not (_has_pipe? or unquote(has_auth_fn?) or unquote(has_ack?)) do
          raise CompileError,
            file: unquote(caller_file),
            line: unquote(caller_line),
            description:
              "Threadline Operator Surface must be mounted inside a secure pipeline. Add `pipe_through :admin_browser` or explicitly provide an `:authorize_fn`."
        end

        import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]

        if unquote(has_actor_fn?) do
          pipeline :threadline_actor_session do
            plug(Threadline.OperatorSurface.SessionPlug, unquote(opts))
          end
        end

        live_session :threadline,
          on_mount: [
            {Threadline.OperatorSurface.Auth, unquote(opts)},
            {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
          ] do
          scope unquote(path), alias: Threadline.OperatorSurface.Live do
            if unquote(has_actor_fn?) do
              pipe_through(:threadline_actor_session)
            end

            live("/", StartLive, :index)
            live("/timeline", TimelineLive, :index)
            live("/evidence", EvidenceLive, :index)
            live("/coverage", CoverageLive, :index)
            live("/exports", ExportStatusLive, :index)
            live("/policy/redaction", PolicyRedactionLive, :index)
            live("/policy/retention", RetentionHistoryLive, :index)
            live("/rows/:table/:record_id", RowHistoryLive, :show)
            live("/transactions/:id", TransactionLive, :show)
            live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
            live("/actors/:kind/:id", ActorLive, :show)
          end
        end

        if Code.ensure_loaded?(Phoenix.Controller) do
          pipeline :threadline_theme do
            plug(Threadline.OperatorSurface.ThemeAuthPlug, unquote(opts))
          end

          scope unquote(path), as: false do
            pipe_through(:threadline_theme)

            post("/theme", Threadline.OperatorSurface.Controllers.ThemeController, :update)
          end
        end

        if unquote(exports_enabled?) and Code.ensure_loaded?(Phoenix.Controller) do
          # Phoenix.Router does not allow `plug` directly inside `scope` — it
          # must live inside a `pipeline`. The pipeline name `:threadline_exports`
          # is reserved (matches the `:threadline` reservation already used by
          # the `live_session :threadline` block above) so multiple
          # `threadline_operator_surface` mounts in one router would collide;
          # the macro is designed to be mounted exactly once per router.
          pipeline :threadline_exports do
            if unquote(has_actor_fn?) do
              plug(Threadline.OperatorSurface.SessionPlug, unquote(opts))
            end

            plug(Threadline.OperatorSurface.ExportAuthPlug, unquote(opts))
          end

          # The scope-local controller alias keeps route declarations readable
          # without changing the host module's lexical alias namespace. Disabling
          # helper names preserves the host router's route-helper namespace.
          scope unquote(path) <> "/exports",
            as: false,
            alias: Threadline.OperatorSurface.Controllers do
            pipe_through(:threadline_exports)

            get("/changes.csv", ExportController, :csv)
            get("/changes.json", ExportController, :json)
            get("/changes.ndjson", ExportController, :ndjson)
            get("/download/:job_id", ExportController, :download)
          end
        end
      end
    end
  end
end
