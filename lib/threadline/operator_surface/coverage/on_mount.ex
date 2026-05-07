if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Coverage.OnMount do
    @moduledoc """
    `live_session` `on_mount/4` callback that drives polled trigger-coverage
    for every LV in the `:threadline` session.

    ## Mount order

    MUST run AFTER `Threadline.OperatorSurface.Auth` in the `on_mount:` list,
    because Auth populates `:threadline_repo` from opts (Pitfall 7). The
    canonical mount in `router.ex` is:

        live_session :threadline,
          on_mount: [
            {Threadline.OperatorSurface.Auth, opts},
            {Threadline.OperatorSurface.Coverage.OnMount, opts}
          ]

    ## Polling

    Default 30_000 ms; configure via `config :threadline, :coverage_poll_ms`
    (global) or socket assign `:threadline_coverage_poll_ms` (per-mount).
    Floor 5_000 ms — raises `ArgumentError` at mount below that. The Application
    env is the test seam (Pitfall 13): tests set a low interval to avoid
    scheduling flakiness.

    ## Error policy

    On poll failure: keep the previous `:threadline_coverage` assign, set
    `:threadline_coverage_error` to the exception message, emit
    `[:threadline, :health, :checked, :error]` via `Threadline.Telemetry`,
    and ALWAYS reschedule (Pitfall 4 — a transient DB blip must not freeze
    the count). The "always reschedule" guarantee is enforced unconditionally
    after the try/rescue block.

    ## PubSub forward-compat (D-30d)

    Out of v1.18 scope. If real adopter pain emerges at v1.19+ scale, a
    runtime opt-in `config :threadline, :coverage_source, {:pubsub, MyApp.PubSub}`
    will let this hook become a no-op while a single-source GenServer
    broadcasts via `Phoenix.PubSub`. Documented here only for forward-compat
    navigation.
    """

    import Phoenix.LiveView

    alias Threadline.OperatorSurface.Coverage.Snapshot

    @default_interval 30_000
    @floor_interval 5_000

    def on_mount(_opts, _params, _session, socket) do
      interval = poll_interval!(socket)

      socket =
        socket
        |> Phoenix.Component.assign(:threadline_coverage_poll_ms, interval)
        |> assign_initial_coverage()

      socket =
        if connected?(socket) do
          ref = Process.send_after(self(), :threadline_refresh_coverage, interval)

          # Doc-contract grep depends on the literal
          # `attach_hook(:threadline_coverage_refresh, :handle_info` substring
          # appearing on a single line — keep the args on one row.
          socket
          |> Phoenix.Component.assign(:threadline_timer_ref, ref)
          |> attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)
        else
          socket
        end

      {:cont, socket}
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
          Threadline.Telemetry.emit_health_checked_error(message)

          socket
          |> Phoenix.Component.assign(:threadline_coverage, Snapshot.empty(now))
          |> Phoenix.Component.assign(:threadline_coverage_error, message)
      end
    end

    defp refresh_coverage(socket) do
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
          Threadline.Telemetry.emit_health_checked_error(message)

          # Keep the previous :threadline_coverage assign untouched (last-good).
          # Set the error so the badge can render a "stale" indicator.
          Phoenix.Component.assign(socket, :threadline_coverage_error, message)
      end
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first()
    end
  end
end
