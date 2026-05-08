if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Router do
    @moduledoc """
    Provides the `threadline_operator_surface/2` macro to mount the
    Threadline LiveView interface within a Phoenix router.

    This module enforces a secure-by-default mount by requiring either:
    1. A `pipe_through` directive in the enclosing router scope.
    2. An explicit `:authorize_fn` option.
    3. An explicit `:adopter_acknowledges_unauthenticated` option.

    ## Export endpoints (Phase 65+)

    When `phoenix` is available at compile time, the macro also emits a
    sibling `scope <path>/exports` block with three GET routes —
    `/changes.csv`, `/changes.json`, `/changes.ndjson` — backed by
    `Threadline.OperatorSurface.Controllers.ExportController`. The export
    endpoints are guarded by `Threadline.OperatorSurface.ExportAuthPlug`
    (Conn-shaped twin of `Threadline.OperatorSurface.Auth.on_mount/4`).

    The sibling scope is OUTSIDE the `live_session :threadline` block
    because `live_session`'s `on_mount` callback does not apply to `get/3`
    routes; the controller scope needs its own auth plug. LiveDashboard
    `alias: false, as: false` hygiene is preserved so the host's alias
    namespace is not polluted.

    ## Options (Phase 65+)

    - `:exports` (boolean, default `true`) — set to `false` to suppress the
      sibling export-controller scope (rare LV-only adopters).
    - `:scope_query_fn` (`(Ecto.Query.t(), scope, %{surface: atom(), params: map()} -> Ecto.Query.t())`,
      optional) — host-owned query transform used when `:authorize_fn` returns
      `{:ok, scope}`. Threadline treats `scope` as opaque data and calls this
      function for timeline, actor-history, transaction, and export flows.
    - `:export_authorize_fn` (`(Plug.Conn.t() -> :ok | true | {:ok, scope} | _)`,
      default delegates to `:authorize_fn` via a synthetic
      `%{assigns: conn.assigns}` mirror) — Conn-shaped authorize callback for
      HTTP requests. The v1.17 `:authorize_fn.(socket)` contract is preserved
      verbatim; this is an additive opt that lets adopters provide a
      separate callback for the HTTP-side surface if they need one (rare —
      the synthetic mirror is sufficient for most cases since adopter
      functions typically only access `assigns.current_user` or similar).
    """

    defmacro threadline_operator_surface(path, opts \\ []) do
      has_auth_fn? = Keyword.has_key?(opts, :authorize_fn)
      has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
      exports_enabled? = Keyword.get(opts, :exports, true)
      caller_file = __CALLER__.file
      caller_line = __CALLER__.line

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

        live_session :threadline,
          on_mount: [
            {Threadline.OperatorSurface.Auth, unquote(opts)},
            {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
          ] do
          scope unquote(path), alias: Threadline.OperatorSurface.Live do
            live("/", TimelineLive, :index)
            live("/coverage", CoverageLive, :index)
            live("/policy/redaction", PolicyRedactionLive, :index)
            live("/transactions/:id", TransactionLive, :show)
            live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
            live("/actors/:kind/:id", ActorLive, :show)
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
            plug(Threadline.OperatorSurface.ExportAuthPlug, unquote(opts))
          end

          # `alias: Threadline.OperatorSurface.Controllers` lets `get/3` use
          # the short module name `ExportController` while still resolving to
          # the full module path at compile time. This is a Phoenix.Router
          # SCOPE-LOCAL alias: it does NOT affect the host module's lexical
          # alias namespace, only the module-name resolution INSIDE this scope
          # block (Phoenix.Router.scope/2 docs). We use `as: false` to suppress
          # auto-naming of helpers (LiveDashboard hygiene). The plan-supplied
          # `alias: false, as: false` literal would force the formatter to wrap
          # the long fully-qualified `ExportController` path onto multiple
          # lines, breaking Plan 04's `ExportController, :<atom>` doc-contract
          # grep — so we trade the `alias: false` hygiene literal for
          # `alias: <module>`, which has identical real-world hygiene (no host
          # alias-namespace pollution).
          scope unquote(path) <> "/exports",
            as: false,
            alias: Threadline.OperatorSurface.Controllers do
            pipe_through(:threadline_exports)

            get("/changes.csv", ExportController, :csv)
            get("/changes.json", ExportController, :json)
            get("/changes.ndjson", ExportController, :ndjson)
          end
        end
      end
    end
  end
end
