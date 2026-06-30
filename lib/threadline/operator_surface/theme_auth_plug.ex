if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ThemeAuthPlug do
    @moduledoc """
    Conn-shaped authorize and session guard for the Threadline runtime theme
    picker endpoint.

    The LiveView `on_mount` callbacks do not apply to the sibling
    `POST /theme` controller route. This plug mirrors the LiveView
    `:authorize_fn` contract with `%{assigns: conn.assigns}` and requires the
    host browser pipeline to have fetched a session before the theme controller
    can write `:tl_theme`.
    """

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
      scope_keys = if is_map(scope), do: Map.keys(scope) |> Enum.sort(), else: []

      actor_ref =
        if is_map(scope), do: Map.get(scope, :actor_ref) || Map.get(scope, :user_id), else: nil

      :telemetry.execute(
        [:threadline, :operator_surface, :authorize],
        %{result: result},
        %{path: conn.request_path || "", actor_ref: actor_ref, scope_keys: scope_keys}
      )
    end
  end
end
