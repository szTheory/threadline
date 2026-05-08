if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Auth do
    @moduledoc """
    Authentication contract for the Threadline operator surface.
    """

    import Phoenix.LiveView

    def on_mount(opts, _params, session, socket) do
      authorize_fn = Keyword.get(opts, :authorize_fn, fn _socket -> true end)
      scope_query_fn = Keyword.get(opts, :scope_query_fn)
      repo = Keyword.get(opts, :repo)
      schemas = Keyword.get(opts, :schemas, %{})

      socket =
        socket
        |> maybe_assign_session_user(session)
        |> Phoenix.Component.assign(:threadline_repo, repo)
        |> Phoenix.Component.assign(:threadline_schemas, schemas)
        |> Phoenix.Component.assign(:threadline_scope_query_fn, scope_query_fn)

      try do
        case authorize_fn.(socket) do
          :ok ->
            emit_telemetry(:granted, socket, nil)
            {:cont, socket}

          true ->
            emit_telemetry(:granted, socket, nil)
            {:cont, socket}

          {:ok, scope} when is_map(scope) ->
            emit_telemetry(:granted, socket, scope)
            {:cont, Phoenix.Component.assign(socket, :threadline_scope, scope)}

          {:ok, scope} ->
            emit_telemetry(:granted, socket, nil)
            {:cont, Phoenix.Component.assign(socket, :threadline_scope, scope)}

          _ ->
            halt_unauthorized(socket, :denied)
        end
      rescue
        _ ->
          halt_unauthorized(socket, :error)
      end
    end

    defp halt_unauthorized(socket, result) do
      emit_telemetry(result, socket, nil)
      {:halt, redirect(socket, to: "/")}
    end

    defp emit_telemetry(result, _socket, scope) do
      scope_keys = if is_map(scope), do: Map.keys(scope) |> Enum.sort(), else: []

      actor_ref =
        if is_map(scope), do: Map.get(scope, :actor_ref) || Map.get(scope, :user_id), else: nil

      :telemetry.execute(
        [:threadline, :operator_surface, :authorize],
        %{result: result},
        %{path: "", actor_ref: actor_ref, scope_keys: scope_keys}
      )
    end

    defp maybe_assign_session_user(socket, session) do
      case {socket.assigns[:current_user], session_user(session)} do
        {nil, nil} -> socket
        {nil, user} -> Phoenix.Component.assign(socket, :current_user, user)
        _ -> socket
      end
    end

    defp session_user(session) when is_map(session) do
      Map.get(session, "threadline_current_user") || Map.get(session, :threadline_current_user)
    end

    defp session_user(_session), do: nil
  end
end
