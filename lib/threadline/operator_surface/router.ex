if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Router do
    @moduledoc """
    Mounts Threadline's operator interface in a Phoenix router with host-owned
    authorization and query scoping.

    A mount must provide a usable one-argument `:authorize_fn` or the exact
    literal `adopter_acknowledges_unauthenticated: true` opt-out. A host
    `pipe_through` remains responsible for middleware such as authentication,
    sessions and CSRF, but does not establish Threadline authorization.

    ## HTTP endpoints

    When Phoenix is available at compile time, the macro emits a sibling
    `POST <path>/theme` route and a sibling `scope <path>/exports` block with
    GET routes for `/changes.csv`, `/changes.json`, `/changes.ndjson`, and
    completed export downloads. These HTTP endpoints use the mount's
    authorization callbacks independently from the LiveView session.

    The HTTP scopes remain outside `live_session :threadline` because LiveView
    `on_mount` callbacks do not apply to controller routes. Route helper names
    and the host router's alias namespace remain untouched.

    """

    @doc """
    Adds the Threadline operator LiveView and sibling HTTP routes to the host router.

    The macro requires a usable one-argument `:authorize_fn` or an explicit
    literal acknowledgement that the mount is intentionally unauthenticated.
    Keep the host's `pipe_through` middleware; it does not replace
    `:authorize_fn`.

    ## Mount options

    - `:exports` — boolean; defaults to `true`. Set to `false` to suppress the
      sibling export-controller scope (rare LV-only adopters).
    - `:scope_query_fn` — `(Ecto.Query.t(), scope, %{surface: atom(), params: map()} -> Ecto.Query.t())`; optional. This host-owned query transform is used when `:authorize_fn` returns `{:ok, scope}`. Threadline treats `scope` as opaque data and calls this function for timeline, actor-history, transaction, and export flows.
    - `:export_authorize_fn` — `(Plug.Conn.t() -> :ok | true | {:ok, scope} | _)`; defaults to delegating to `:authorize_fn` via a synthetic `%{assigns: conn.assigns}` mirror. Use a separate callback when HTTP authorization needs more than the assigns inspected by the LiveView callback; the synthetic mirror is sufficient when authorization only reads values such as `assigns.current_user`.
    - `:coverage_authorize_fn` — `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`; optional. Explicitly gates the coverage dashboard and related badge, and defaults to fail closed.
    - `:policy_authorize_fn` — `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`; optional. Explicitly gates policy and retention surfaces, and defaults to fail closed.
    - `:evidence_authorize_fn` — `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`; optional. Explicitly gates the mounted evidence surface, and defaults to fail closed.
    - `:theme` — `:dark | :light | :system`; defaults to `:dark`. Selects the default server-rendered operator-surface theme lane. `:system` follows the visitor's OS preference through scoped CSS only. A runtime dark/light/system theme picker is available in the shell (session-backed and resolved server-side; a response cookie mirrors the choice); Threadline adds no JavaScript and no local storage.
    """
    defmacro threadline_operator_surface(path, opts \\ []) do
      has_auth_fn? = usable_authorize_fn_ast?(Keyword.get(opts, :authorize_fn))
      has_actor_fn? = Keyword.has_key?(opts, :actor_fn)
      has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated) === true
      exports_enabled? = Keyword.get(opts, :exports, true)
      {opts, authorize_fn_defs} = normalize_inline_authorize_fn(opts, has_auth_fn?)
      caller_file = __CALLER__.file
      caller_line = __CALLER__.line

      validate_theme!(Keyword.get(opts, :theme, :dark), caller_file, caller_line)

      quote do
        unquote_splicing(authorize_fn_defs)
        unquote(secure_mount_guard(has_auth_fn? or has_ack?, caller_file, caller_line))

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
            # `:theme_path` is the macro's own compile-time mount-path argument
            # (the router's literal path template, e.g. "/audit/theme" or, for
            # a host that nests the mount under a dynamic segment,
            # "/accounts/:account_id/audit/theme" with the param name left
            # un-substituted) — never `conn.request_path`, which would carry
            # whatever real value the router matched for that segment. This
            # keeps the `:authorize` event's `path` metadata bounded to a
            # fixed, host-authored string regardless of how a request was
            # routed.
            theme_plug_opts = Keyword.put(unquote(opts), :theme_path, unquote(path) <> "/theme")
            plug(Threadline.OperatorSurface.ThemeAuthPlug, theme_plug_opts)
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

    # Literal function forms are checked without evaluating the option AST.
    # Dynamic expressions remain opaque and are checked by the existing
    # fail-closed runtime callback handling.
    defp usable_authorize_fn_ast?(nil), do: false

    defp usable_authorize_fn_ast?({:fn, _meta, clauses}) when is_list(clauses) do
      clauses != [] and
        Enum.all?(clauses, fn
          {:->, _meta, [arguments, _body]} when is_list(arguments) -> length(arguments) == 1
          _ -> false
        end)
    end

    defp usable_authorize_fn_ast?({:&, _meta, [{:/, _arity_meta, [_function, arity]}]})
         when is_integer(arity),
         do: arity == 1

    defp usable_authorize_fn_ast?({:&, _meta, [expression]}) do
      case capture_placeholder_arity(expression) do
        {:ok, 1} -> true
        {:ok, _arity} -> false
        :unknown -> false
      end
    end

    defp usable_authorize_fn_ast?(ast), do: not literal_non_function_ast?(ast)

    defp normalize_inline_authorize_fn(opts, true) do
      case Keyword.fetch(opts, :authorize_fn) do
        {:ok, {:fn, _meta, clauses}} ->
          name = String.to_atom("__threadline_authorize_fn_#{System.unique_integer([:positive])}")

          definitions = Enum.map(clauses, &authorize_fn_clause(name, &1))
          capture = quote(do: &(__MODULE__.unquote(name) / 1))
          {Keyword.put(opts, :authorize_fn, capture), definitions}

        _ ->
          {opts, []}
      end
    end

    defp normalize_inline_authorize_fn(opts, _not_usable), do: {opts, []}

    defp authorize_fn_clause(name, {:->, meta, [arguments, body]}) do
      head =
        case arguments do
          [{:when, when_meta, [pattern, guard]}] ->
            {:when, when_meta, [{name, meta, [pattern]}, guard]}

          arguments ->
            {name, meta, arguments}
        end

      {:def, Keyword.put(meta, :generated, true), [head, [do: body]]}
    end

    defp capture_placeholder_arity(ast) do
      {_ast, arities} =
        Macro.prewalk(ast, [], fn
          {:&, _meta, [arity]} = node, arities when is_integer(arity) and arity > 0 ->
            {node, [arity | arities]}

          node, arities ->
            {node, arities}
        end)

      case arities do
        [] -> :unknown
        values -> {:ok, Enum.max(values)}
      end
    end

    defp literal_non_function_ast?(value)
         when is_atom(value) or is_number(value) or is_binary(value) or is_list(value),
         do: true

    defp literal_non_function_ast?({:%, _meta, _parts}), do: true
    defp literal_non_function_ast?({:%{}, _meta, _entries}), do: true
    defp literal_non_function_ast?({:<<>>, _meta, _parts}), do: true

    defp literal_non_function_ast?(value) when is_tuple(value) and tuple_size(value) == 2,
      do: true

    defp literal_non_function_ast?(_ast), do: false

    # Expands, in the host router, to a compile-time check that authorization
    # is explicit. A pipeline alone never satisfies the mount contract.
    defp secure_mount_guard(mount_authorized?, caller_file, caller_line) do
      quote do
        if not unquote(mount_authorized?) do
          raise CompileError,
            file: unquote(caller_file),
            line: unquote(caller_line),
            description:
              "Threadline.OperatorSurface.Router.threadline_operator_surface/2 requires either a one-argument `authorize_fn` or the exact `adopter_acknowledges_unauthenticated: true` opt-out. `pipe_through` alone does not authorize access. Add `authorize_fn: &MyApp.Audit.authorize_operator/1`, or use the exact opt-out only when this surface is intentionally unauthenticated."
        end
      end
    end

    defp validate_theme!(theme, _caller_file, _caller_line)
         when theme in [:dark, :light, :system],
         do: :ok

    defp validate_theme!(_theme, caller_file, caller_line) do
      raise CompileError,
        file: caller_file,
        line: caller_line,
        description: "Threadline Operator Surface theme must be one of :dark | :light | :system"
    end
  end
end
