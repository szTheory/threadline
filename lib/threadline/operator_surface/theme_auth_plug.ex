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
      |> ensure_session_fetched()
      |> authorize(opts)
    end

    defp ensure_session_fetched(%Plug.Conn{halted: true} = conn), do: conn

    defp ensure_session_fetched(conn) do
      if session_fetched?(conn) do
        conn
      else
        halt_unauthorized(conn, :denied)
      end
    end

    defp authorize(%Plug.Conn{halted: true} = conn, _opts), do: conn

    defp authorize(conn, opts) do
      authorize_fn = Keyword.get(opts, :authorize_fn, fn _ -> true end)

      try do
        mirror = %{assigns: conn.assigns}

        case authorize_fn.(mirror) do
          :ok ->
            emit_telemetry(:granted, conn, nil)
            conn

          true ->
            emit_telemetry(:granted, conn, nil)
            conn

          {:ok, scope} when is_map(scope) ->
            emit_telemetry(:granted, conn, scope)
            assign(conn, :threadline_scope, scope)

          {:ok, scope} ->
            emit_telemetry(:granted, conn, nil)
            assign(conn, :threadline_scope, scope)

          _ ->
            halt_unauthorized(conn, :denied)
        end
      rescue
        _ -> halt_unauthorized(conn, :error)
      end
    end

    defp session_fetched?(conn) do
      conn.private[:plug_session_fetch] == :done and is_map(conn.private[:plug_session])
    end

    defp halt_unauthorized(conn, result) do
      emit_telemetry(result, conn, nil)

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(403, "forbidden")
      |> halt()
    end

    defp emit_telemetry(result, conn, scope) do
      Threadline.Telemetry.emit_operator_surface_authorize(result, conn, scope)
    end
  end
end
