if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Coverage.OnMount do
    @moduledoc false

    import Phoenix.LiveView

    alias Threadline.Health.CoverageSchemas
    alias Threadline.OperatorSurface.Coverage.Snapshot

    @default_interval 30_000
    @floor_interval 5_000

    def on_mount(_opts, _params, _session, socket) do
      if Map.get(socket.assigns, :threadline_coverage_enabled, false) do
        interval = poll_interval!(socket)

        socket =
          socket
          |> Phoenix.Component.assign(:threadline_coverage_poll_ms, interval)
          |> assign_initial_coverage()

        socket =
          if connected?(socket) do
            ref = Process.send_after(self(), :threadline_refresh_coverage, interval)

            # The coverage contract depends on the literal
            # `attach_hook(:threadline_coverage_refresh, :handle_info` substring
            # appearing on a single line — keep the args on one row.
            socket
            |> Phoenix.Component.assign(:threadline_timer_ref, ref)
            |> attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)
          else
            socket
          end

        {:cont, socket}
      else
        socket =
          socket
          |> Phoenix.Component.assign(:threadline_coverage, nil)
          |> Phoenix.Component.assign(:threadline_coverage_error, nil)

        {:cont, socket}
      end
    end

    defp handle_refresh(:threadline_refresh_coverage, socket) do
      socket = refresh_coverage(socket)
      interval = socket.assigns[:threadline_coverage_poll_ms] || @default_interval
      ref = Process.send_after(self(), :threadline_refresh_coverage, interval)
      socket = Phoenix.Component.assign(socket, :threadline_timer_ref, ref)
      {:halt, socket}
    end

    defp handle_refresh(_other, socket), do: {:cont, socket}

    defp poll_interval!(socket) do
      interval =
        socket.assigns[:threadline_coverage_poll_ms] ||
          Application.get_env(:threadline, :coverage_poll_ms, @default_interval)

      if interval < @floor_interval do
        raise ArgumentError,
              "coverage poll interval must be >= #{@floor_interval} ms; below this, the two pg_* queries become a noisy neighbor on busy schemas (got #{interval})"
      end

      interval
    end

    defp assign_initial_coverage(socket) do
      repo = resolve_repo(socket)
      now = DateTime.utc_now()

      try do
        coverage = Threadline.Health.trigger_coverage(repo: repo, schema: "public")
        snapshot = Snapshot.from_coverage(coverage, last_checked_at: now)

        socket
        |> Phoenix.Component.assign(:threadline_coverage, snapshot)
        |> Phoenix.Component.assign(:threadline_coverage_error, nil)
      rescue
        e ->
          message = Exception.message(e)
          Threadline.Telemetry.emit_health_checked_error(e)

          socket
          |> Phoenix.Component.assign(:threadline_coverage, %{
            Snapshot.empty(nil)
            | error: message
          })
          |> Phoenix.Component.assign(:threadline_coverage_error, message)
      end
    end

    defp refresh_coverage(socket) do
      repo = resolve_repo(socket)
      now = DateTime.utc_now()
      schema = socket.assigns[:coverage_for_schema_name] || "public"

      try do
        schema = validate_selected_schema!(repo, schema)

        coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
        snapshot = Snapshot.from_coverage(coverage, last_checked_at: now)

        socket
        |> Phoenix.Component.assign(:threadline_coverage, snapshot)
        |> Phoenix.Component.assign(:threadline_coverage_error, nil)
        |> assign_selected_coverage(schema, snapshot)
      rescue
        e ->
          message = Exception.message(e)
          Threadline.Telemetry.emit_health_checked_error(e)

          snapshot = failed_snapshot(socket, schema, message)

          socket
          |> Phoenix.Component.assign(:threadline_coverage, snapshot)
          |> Phoenix.Component.assign(:threadline_coverage_error, message)
          |> assign_selected_coverage(schema, snapshot)
      end
    end

    defp assign_selected_coverage(socket, schema, snapshot) do
      if socket.assigns[:coverage_for_schema_name] == schema do
        Phoenix.Component.assign(socket, :coverage_for_schema, snapshot)
      else
        socket
      end
    end

    defp validate_selected_schema!(_repo, "public"), do: "public"

    defp validate_selected_schema!(repo, schema) do
      case CoverageSchemas.validate(repo, schema) do
        {:ok, validated_schema} -> validated_schema
        {:error, message} -> raise ArgumentError, message
      end
    end

    defp failed_snapshot(socket, schema, message) do
      case {socket.assigns[:coverage_for_schema_name], socket.assigns[:coverage_for_schema]} do
        {^schema, %Snapshot{last_checked_at: %DateTime{} = _last_checked_at} = last_good} ->
          %{last_good | error: message}

        _ ->
          case socket.assigns[:threadline_coverage] do
            %Snapshot{last_checked_at: %DateTime{} = _last_checked_at} = last_good ->
              %{last_good | error: message}

            _ ->
              %{Snapshot.empty(nil) | error: message}
          end
      end
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first()
    end
  end
end
