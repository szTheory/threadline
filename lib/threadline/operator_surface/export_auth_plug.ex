if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportAuthPlug do
    @moduledoc false

    @behaviour Plug

    import Plug.Conn

    @impl Plug
    def init(opts), do: opts

    @impl Plug
    def call(conn, opts) do
      authorize_fn = Keyword.get(opts, :authorize_fn, fn _ -> true end)
      export_authorize_fn = Keyword.get(opts, :export_authorize_fn)
      scope_query_fn = Keyword.get(opts, :scope_query_fn)
      repo = Keyword.get(opts, :repo)

      conn = assign(conn, :threadline_repo, repo)
      conn = assign(conn, :threadline_scope_query_fn, scope_query_fn)

      authorizer =
        case export_authorize_fn do
          fun when is_function(fun, 1) ->
            fn -> fun.(conn) end

          nil ->
            fn ->
              mirror = %{assigns: conn.assigns}
              authorize_fn.(mirror)
            end
        end

      try do
        case authorizer.() do
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

    defp halt_unauthorized(conn, result) do
      emit_telemetry(result, conn, nil)

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(403, "forbidden")
      |> halt()
    end

    defp emit_telemetry(result, _conn, scope) do
      scope_keys = if is_map(scope), do: Map.keys(scope) |> Enum.sort(), else: []

      actor_ref =
        if is_map(scope), do: Map.get(scope, :actor_ref) || Map.get(scope, :user_id), else: nil

      :telemetry.execute(
        [:threadline, :operator_surface, :authorize],
        %{result: result},
        %{path: "", actor_ref: actor_ref, scope_keys: scope_keys}
      )
    end
  end
end
