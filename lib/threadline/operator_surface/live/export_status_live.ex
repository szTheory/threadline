if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.ExportStatusLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Governance.ExportJob
    alias Threadline.OperatorSurface.Presentation
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
              <div>
                <h2 class="tl-page__title">Export Status</h2>
                <p class="tl-page__lede">
                  Background exports queued from the audit timeline.
                </p>
              </div>
              <.link href={"#{@base_path}"} class="tl-button tl-button--secondary">View Timeline</.link>
            </header>

            <section class="tl-trust-rail" aria-label="Export workflow">
              <span class="tl-trust-rail__label">Export workflow</span>
              <span class="tl-chip tl-chip--info">Actor-owned jobs</span>
              <span class="tl-chip tl-chip--neutral">Filtered timeline packets</span>
              <a href={"#{@base_path}"} class="tl-button tl-button--compact tl-button--ghost">Start search</a>
            </section>

            <%= if not @has_jobs do %>
              <div class="tl-empty">
                <h3 class="tl-empty__title">No Export Jobs</h3>
                <p class="tl-empty__body">Go to the timeline to queue a background export.</p>
              </div>
            <% else %>
              <section class="tl-job-list" id="export-jobs" phx-update="stream" data-testid="export-jobs">
                <article
                  :for={{dom_id, job} <- @streams.jobs}
                  id={dom_id}
                  class={["tl-job", job_modifier(job.status)]}
                  data-testid="export-job"
                >
                  <div class="tl-job__main">
                    <div class="tl-job__summary">
                      <span class={["tl-chip", Presentation.status_modifier(job.status)]} role={status_role(job)}>
                        <%= Presentation.status_label(job.status) %>
                      </span>
                      <div class="tl-job__title">
                        <strong><%= Presentation.export_summary(job.query_params) %></strong>
                        <span>
                          requested by
                          <%= if path = actor_path(@base_path, job.actor_ref) do %>
                            <a href={path} class="tl-link tl-link--deep"><code><%= actor_label(job.actor_ref) %></code></a>
                          <% else %>
                            <code><%= actor_label(job.actor_ref) %></code>
                          <% end %>
                        </span>
                      </div>
                    </div>

                    <div class="tl-job__actions">
                      <%= cond do %>
                        <% downloadable?(job) -> %>
                          <.link href={"#{@base_path}/exports/download/#{job.id}"} class="tl-button tl-button--primary tl-button--compact">
                            Download
                          </.link>
                        <% job.status in ["pending", "running"] -> %>
                          <span class="tl-hint" role="status">Preparing download</span>
                        <% completed_but_unavailable?(job) -> %>
                          <span class="tl-hint">
                            <%= unavailable_label(job) %>
                          </span>
                        <% true -> %>
                          <span class="tl-hint">No action available</span>
                      <% end %>
                    </div>
                  </div>

                  <dl class="tl-job__meta" aria-label="Export job timestamps">
                    <div>
                      <dt>Started</dt>
                      <dd><.time_label value={job.started_at} empty="Not started" /></dd>
                    </div>
                    <div>
                      <dt>Completed</dt>
                      <dd><.time_label value={job.completed_at} empty="Not completed" /></dd>
                    </div>
                    <div>
                      <dt>Expires</dt>
                      <dd><.time_label value={job.expires_at} empty="No expiration" /></dd>
                    </div>
                  </dl>

                  <div class="tl-param-list" aria-label="Export filters">
                    <%= for {key, value} <- Presentation.query_pairs(job.query_params) do %>
                      <span class="tl-param" title={"#{key}: #{value}"}>
                        <span class="tl-param__key"><%= key %></span>
                        <span class="tl-param__value"><%= Presentation.truncate_middle(value, 42) %></span>
                      </span>
                    <% end %>
                    <span :if={Presentation.query_pairs(job.query_params) == []} class="tl-param tl-param--muted">
                      No filters
                    </span>
                  </div>

                  <div class="tl-job__source">
                    <span class="tl-hint">Source Timeline search</span>
                    <a href={timeline_search_path(@base_path, job.query_params)} class="tl-button tl-button--compact tl-button--secondary">
                      Reopen search
                    </a>
                  </div>

                  <%= if job.error_message do %>
                    <div class="tl-job__note tl-job__note--error" role="alert">
                      <strong>Failed:</strong> <%= job.error_message %>
                    </div>
                  <% end %>
                </article>
              </section>
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

    defp status_role(%{status: "failed"}), do: "alert"
    defp status_role(_job), do: "status"

    attr(:value, :any, required: true)
    attr(:empty, :string, required: true)

    defp time_label(assigns) do
      ~H"""
      <%= if @value do %>
        <time datetime={Presentation.exact_time(@value)} title={Presentation.exact_time(@value)}>
          <%= Presentation.human_time(@value, empty: @empty) %>
        </time>
      <% else %>
        <span class="tl-muted"><%= @empty %></span>
      <% end %>
      """
    end

    defp job_modifier("failed"), do: "tl-job--danger"
    defp job_modifier("running"), do: "tl-job--info"
    defp job_modifier("pending"), do: "tl-job--info"
    defp job_modifier(_), do: nil

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

    defp unavailable_label(%{expires_at: %DateTime{} = expires_at}) do
      if expired?(expires_at), do: "Expired", else: "File unavailable"
    end

    defp unavailable_label(_job), do: "File unavailable"

    defp actor_label(%Threadline.Semantics.ActorRef{type: type, id: id}) when not is_nil(id),
      do: "#{type}/#{id}"

    defp actor_label(%{"type" => type, "id" => id}) when not is_nil(id), do: "#{type}/#{id}"
    defp actor_label(_), do: "unknown actor"

    defp actor_path(base_path, %Threadline.Semantics.ActorRef{type: type, id: id})
         when is_binary(base_path) and not is_nil(id) do
      "#{base_path}/actors/#{URI.encode_www_form(to_string(type))}/#{URI.encode_www_form(to_string(id))}"
    end

    defp actor_path(base_path, %{"type" => type, "id" => id})
         when is_binary(base_path) and not is_nil(id) do
      "#{base_path}/actors/#{URI.encode_www_form(to_string(type))}/#{URI.encode_www_form(to_string(id))}"
    end

    defp actor_path(_base_path, _actor_ref), do: nil

    defp timeline_search_path(base_path, params) when is_map(params) do
      pairs =
        params
        |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
        |> Enum.reject(fn {_key, value} -> value == "" end)

      case URI.encode_query(pairs) do
        "" -> base_path
        query -> "#{base_path}?#{query}"
      end
    end

    defp timeline_search_path(base_path, _params), do: base_path
  end
end
