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
      theme = opts |> Keyword.get(:theme, :dark) |> normalize_theme()

      socket =
        socket
        |> maybe_assign_session_user(session)
        |> maybe_assign_session_actor(session)
        |> Phoenix.Component.assign(:threadline_theme, theme)
        |> Phoenix.Component.assign(:threadline_repo, repo)
        |> Phoenix.Component.assign(:threadline_schemas, schemas)
        |> Phoenix.Component.assign(:threadline_scope_query_fn, scope_query_fn)

      try do
        case authorize_fn.(socket) do
          :ok ->
            emit_telemetry(:granted, socket, nil)

            {:cont,
             socket
             |> Phoenix.Component.assign(:threadline_scope, nil)
             |> assign_exports_enabled(opts)
             |> assign_coverage_enabled(opts)
             |> assign_policy_enabled(opts)
             |> assign_evidence_enabled(opts)}

          true ->
            emit_telemetry(:granted, socket, nil)

            {:cont,
             socket
             |> Phoenix.Component.assign(:threadline_scope, nil)
             |> assign_exports_enabled(opts)
             |> assign_coverage_enabled(opts)
             |> assign_policy_enabled(opts)
             |> assign_evidence_enabled(opts)}

          {:ok, scope} when is_map(scope) ->
            socket =
              socket
              |> assign_fallback_actor(scope)
              |> Phoenix.Component.assign(:threadline_scope, scope)
              |> assign_exports_enabled(opts)
              |> assign_coverage_enabled(opts)
              |> assign_policy_enabled(opts)
              |> assign_evidence_enabled(opts)

            emit_telemetry(:granted, socket, scope)
            {:cont, socket}

          {:ok, scope} ->
            socket =
              socket
              |> Phoenix.Component.assign(:threadline_scope, scope)
              |> assign_exports_enabled(opts)
              |> assign_coverage_enabled(opts)
              |> assign_policy_enabled(opts)
              |> assign_evidence_enabled(opts)

            emit_telemetry(:granted, socket, nil)
            {:cont, socket}

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

    defp normalize_theme(:dark), do: "dark"
    defp normalize_theme(:light), do: "light"
    defp normalize_theme(:system), do: "system"
    defp normalize_theme(_), do: "dark"

    defp emit_telemetry(result, socket, scope) do
      scope_keys = if is_map(scope), do: Map.keys(scope) |> Enum.sort(), else: []

      actor_ref = Map.get(socket.assigns, :threadline_actor_ref)

      :telemetry.execute(
        [:threadline, :operator_surface, :authorize],
        %{result: result},
        %{path: "", actor_ref: actor_ref, scope_keys: scope_keys}
      )
    end

    defp maybe_assign_session_actor(socket, session) when is_map(session) do
      case Map.get(session, "threadline_actor_ref") do
        serialized when is_binary(serialized) ->
          with {:ok, decoded} <- Jason.decode(serialized),
               {:ok, actor_ref} <- Threadline.Semantics.ActorRef.from_map(decoded) do
            Phoenix.Component.assign(socket, :threadline_actor_ref, actor_ref)
          else
            _ -> socket
          end

        _ ->
          socket
      end
    end

    defp maybe_assign_session_actor(socket, _session), do: socket

    defp assign_fallback_actor(socket, scope) when is_map(scope) do
      case scope_actor_ref(scope) do
        nil ->
          socket

        scope_actor_ref ->
          case Map.get(socket.assigns, :threadline_actor_ref) do
            %Threadline.Semantics.ActorRef{} = session_actor_ref ->
              if session_actor_ref != scope_actor_ref do
                emit_actor_mismatch(session_actor_ref, scope_actor_ref)
              end

              socket

            _ ->
              Phoenix.Component.assign(socket, :threadline_actor_ref, scope_actor_ref)
          end
      end
    end

    defp assign_fallback_actor(socket, _scope), do: socket

    defp scope_actor_ref(scope) when is_map(scope) do
      Map.get(scope, :actor_ref) || legacy_user_id_to_actor(Map.get(scope, :user_id))
    end

    defp legacy_user_id_to_actor(nil), do: nil

    defp legacy_user_id_to_actor(id) when is_binary(id) or is_integer(id) do
      case Threadline.Semantics.ActorRef.new(:user, to_string(id)) do
        {:ok, ref} -> ref
        _ -> nil
      end
    end

    defp emit_actor_mismatch(session_actor_ref, scope_actor_ref) do
      :telemetry.execute(
        [:threadline, :operator_surface, :actor_ref_mismatch],
        %{count: 1},
        %{
          session_actor_ref: Threadline.Semantics.ActorRef.to_map(session_actor_ref),
          scope_actor_ref: Threadline.Semantics.ActorRef.to_map(scope_actor_ref)
        }
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

    defp assign_exports_enabled(socket, opts) do
      exports_enabled = Keyword.get(opts, :exports, true)
      export_authorize_fn = Keyword.get(opts, :export_authorize_fn)

      Phoenix.Component.assign(
        socket,
        :threadline_exports_enabled,
        exports_enabled_for_socket?(exports_enabled, export_authorize_fn, socket)
      )
    end

    defp exports_enabled_for_socket?(false, _export_authorize_fn, _socket), do: false
    defp exports_enabled_for_socket?(true, nil, _socket), do: true

    defp exports_enabled_for_socket?(true, export_authorize_fn, socket)
         when is_function(export_authorize_fn, 1) do
      mirror = %{assigns: socket.assigns}

      case export_authorize_fn.(mirror) do
        :ok -> true
        true -> true
        {:ok, _scope} -> true
        _ -> false
      end
    rescue
      _ -> false
    end

    defp assign_coverage_enabled(socket, opts) do
      coverage_authorize_fn = Keyword.get(opts, :coverage_authorize_fn, fn _ -> false end)

      Phoenix.Component.assign(
        socket,
        :threadline_coverage_enabled,
        coverage_enabled_for_socket?(coverage_authorize_fn, socket)
      )
    end

    defp coverage_enabled_for_socket?(nil, _socket), do: false

    defp coverage_enabled_for_socket?(coverage_authorize_fn, socket)
         when is_function(coverage_authorize_fn, 1) do
      mirror = %{assigns: socket.assigns}

      case coverage_authorize_fn.(mirror) do
        :ok -> true
        true -> true
        {:ok, _scope} -> true
        _ -> false
      end
    rescue
      _ -> false
    end

    defp assign_policy_enabled(socket, opts) do
      policy_authorize_fn = Keyword.get(opts, :policy_authorize_fn, fn _ -> false end)

      Phoenix.Component.assign(
        socket,
        :threadline_policy_enabled,
        policy_enabled_for_socket?(policy_authorize_fn, socket)
      )
    end

    defp policy_enabled_for_socket?(nil, _socket), do: false

    defp policy_enabled_for_socket?(policy_authorize_fn, socket)
         when is_function(policy_authorize_fn, 1) do
      mirror = %{assigns: socket.assigns}

      case policy_authorize_fn.(mirror) do
        :ok -> true
        true -> true
        {:ok, _scope} -> true
        _ -> false
      end
    rescue
      _ -> false
    end

    defp assign_evidence_enabled(socket, opts) do
      evidence_authorize_fn = Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)

      Phoenix.Component.assign(
        socket,
        :threadline_evidence_enabled,
        evidence_enabled_for_socket?(evidence_authorize_fn, socket)
      )
    end

    defp evidence_enabled_for_socket?(nil, _socket), do: false

    defp evidence_enabled_for_socket?(evidence_authorize_fn, socket)
         when is_function(evidence_authorize_fn, 1) do
      mirror = %{assigns: socket.assigns}

      case evidence_authorize_fn.(mirror) do
        :ok -> true
        true -> true
        {:ok, _scope} -> true
        _ -> false
      end
    rescue
      _ -> false
    end
  end
end
