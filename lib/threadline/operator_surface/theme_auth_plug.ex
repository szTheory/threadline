if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ThemeAuthPlug do
    @moduledoc false

    @behaviour Plug

    import Plug.Conn

    @impl Plug
    def init(opts), do: opts

    @impl Plug
    def call(conn, opts) do
      conn
      |> ensure_session_fetched(opts)
      |> authorize(opts)
    end

    defp ensure_session_fetched(%Plug.Conn{halted: true} = conn, _opts), do: conn

    defp ensure_session_fetched(conn, opts) do
      if session_fetched?(conn) do
        conn
      else
        halt_unauthorized(conn, :denied, opts)
      end
    end

    defp authorize(%Plug.Conn{halted: true} = conn, _opts), do: conn

    defp authorize(conn, opts) do
      authorize_fn = Keyword.get(opts, :authorize_fn, fn _ -> true end)

      try do
        mirror = %{assigns: conn.assigns}

        case authorize_fn.(mirror) do
          :ok ->
            emit_telemetry(:granted, opts, nil)
            conn

          true ->
            emit_telemetry(:granted, opts, nil)
            conn

          {:ok, scope} when is_map(scope) ->
            emit_telemetry(:granted, opts, scope)
            assign(conn, :threadline_scope, scope)

          {:ok, scope} ->
            emit_telemetry(:granted, opts, nil)
            assign(conn, :threadline_scope, scope)

          _ ->
            halt_unauthorized(conn, :denied, opts)
        end
      rescue
        _ -> halt_unauthorized(conn, :error, opts)
      end
    end

    defp session_fetched?(conn) do
      conn.private[:plug_session_fetch] == :done and is_map(conn.private[:plug_session])
    end

    defp halt_unauthorized(conn, result, opts) do
      emit_telemetry(result, opts, nil)

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(403, "forbidden")
      |> halt()
    end

    # `path` is read from the plug's own `:theme_path` option — the macro's
    # compile-time mount-path literal (see router.ex) — never from
    # `conn.request_path`, so a host that nests this mount under a dynamic
    # router segment never leaks the matched segment's real value here
    # (WR-02).
    defp emit_telemetry(result, opts, scope) do
      path = Keyword.get(opts, :theme_path)
      Threadline.Telemetry.emit_operator_surface_authorize(result, path, scope)
    end
  end
end
