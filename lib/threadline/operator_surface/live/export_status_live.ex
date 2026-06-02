if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.ExportStatusLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Governance.ExportJob
    alias Threadline.OperatorSurface.Unsupported

    @default_limit 100

    def mount(_params, _session, socket) do
      if connected?(socket) and socket.assigns[:threadline_exports_enabled] do
        schedule_refresh(socket)
      end

      socket =
        socket
        |> assign(:base_path, nil)
        |> assign(:export_denied_descriptor, Unsupported.export_denied_descriptor())
        |> stream(:jobs, fetch_jobs(socket))
        |> assign(:has_jobs, has_jobs?(socket))

      {:ok, socket}
    end

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/exports", "")

      socket =
        socket
        |> assign(:base_path, base_path)
        |> assign(:export_denied_descriptor, Unsupported.export_denied_descriptor(params))

      {:noreply, socket}
    end

    def handle_info(:refresh, socket) do
      if not socket.assigns[:threadline_exports_enabled] do
        {:noreply, socket}
      else
        schedule_refresh(socket)

        jobs = fetch_jobs(socket)

        socket =
          Enum.reduce(jobs, socket, fn job, acc_socket ->
            stream_insert(acc_socket, :jobs, job)
          end)
          |> assign(:has_jobs, length(jobs) > 0)

        {:noreply, socket}
      end
    end

    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <%= if @base_path do %>
          <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
            coverage={@threadline_coverage || %{uncovered_count: 0}}
            base_path={@base_path}
            coverage_enabled={@threadline_coverage_enabled}
            policy_enabled={@threadline_policy_enabled}
            evidence_enabled={@threadline_evidence_enabled}
            exports_enabled={@threadline_exports_enabled}
            current={:exports}
          />
        <% end %>

        <main class="tl-page">
          <%= if @threadline_exports_enabled do %>
            <header class="tl-page__header">
              <h2 class="tl-page__title">Export Status</h2>
              <.link href={"#{@base_path}"} class="tl-button tl-button--secondary">Back to Timeline</.link>
            </header>

            <%= if not @has_jobs do %>
              <div class="tl-empty">
                <h3 class="tl-empty__title">No Export Jobs</h3>
                <p class="tl-empty__body">Go to the timeline to queue a background export.</p>
              </div>
            <% else %>
              <div class="tl-table-wrap" data-testid="export-jobs-table">
                <table class="tl-table tl-table--jobs">
                  <thead>
                    <tr>
                      <th>Status</th>
                      <th>Filters</th>
                      <th>Started At</th>
                      <th>Completed At</th>
                      <th>Expires At</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody id="export-jobs" phx-update="stream" data-testid="export-jobs">
                    <tr :for={{dom_id, job} <- @streams.jobs} id={dom_id} class={"tl-table__row--" <> job.status}>
                      <td>
                        <span class={["tl-chip", export_status_modifier(job.status)]} role={status_role(job)}>
                          <%= job.status %>
                        </span>
                        <%= if job.error_message do %>
                          <div class="tl-alert tl-alert--error" role="alert"><%= job.error_message %></div>
                        <% end %>
                      </td>
                      <td class="tl-table__code">
                        <code><%= encode_query(job.query_params) %></code>
                      </td>
                      <td class="tl-table__date"><%= format_date(job.started_at) %></td>
                      <td class="tl-table__date"><%= format_date(job.completed_at) %></td>
                      <td class="tl-table__date"><%= format_date(job.expires_at) %></td>
                      <td>
                        <%= cond do %>
                          <% downloadable?(job) -> %>
                            <.link href={"#{@base_path}/exports/download/#{job.id}"} class="tl-link tl-link--deep">
                              Download Export
                            </.link>
                          <% job.status in ["pending", "running"] -> %>
                            <span class="tl-hint" role="status">Preparing download</span>
                          <% completed_but_unavailable?(job) -> %>
                            <span class="tl-hint">
                              This export isn't available to download right now.
                            </span>
                          <% true -> %>
                            <span>-</span>
                        <% end %>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            <% end %>
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={@export_denied_descriptor}
              base_path={@base_path}
            />
          <% end %>
        </main>
      </div>
      """
    end

    defp fetch_jobs(socket) do
      if not socket.assigns[:threadline_exports_enabled] do
        []
      else
        repo = resolve_repo(socket)
        actor_ref = socket.assigns[:threadline_actor_ref]

        if actor_ref do
          from(j in ExportJob,
            where: j.actor_ref == ^actor_ref,
            order_by: [desc: j.inserted_at],
            limit: @default_limit
          )
          |> repo.all()
        else
          []
        end
      end
    end

    defp has_jobs?(socket) do
      if not socket.assigns[:threadline_exports_enabled] do
        false
      else
        repo = resolve_repo(socket)
        actor_ref = socket.assigns[:threadline_actor_ref]

        if actor_ref do
          repo.exists?(from(j in ExportJob, where: j.actor_ref == ^actor_ref))
        else
          false
        end
      end
    end

    defp schedule_refresh(socket) do
      interval =
        socket.assigns[:threadline_export_status_poll_ms] ||
          Application.get_env(:threadline, :export_status_poll_ms, 5_000)

      Process.send_after(self(), :refresh, interval)
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first() || Threadline.Repo
    end

    defp format_date(nil), do: "-"

    defp format_date(%DateTime{} = dt) do
      DateTime.to_string(dt) |> String.replace("Z", " UTC")
    end

    defp status_role(%{status: "failed"}), do: "alert"
    defp status_role(_job), do: "status"

    defp export_status_modifier("completed"), do: "tl-chip--success"
    defp export_status_modifier("failed"), do: "tl-chip--danger"

    defp export_status_modifier(status) when status in ["pending", "running"],
      do: "tl-chip--accent"

    defp export_status_modifier(_status), do: "tl-chip--muted"

    defp downloadable?(job) do
      job.status == "completed" and is_binary(job.file_path) and not expired?(job.expires_at)
    end

    defp completed_but_unavailable?(job) do
      job.status == "completed" and not downloadable?(job)
    end

    defp expired?(%DateTime{} = expires_at) do
      DateTime.compare(expires_at, DateTime.utc_now()) != :gt
    end

    defp expired?(_expires_at), do: false

    defp encode_query(params) when is_map(params) do
      URI.encode_query(params)
    end

    defp encode_query(_), do: ""
  end
end
