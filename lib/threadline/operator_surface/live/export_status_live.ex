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
        |> assign_jobs(fetch_jobs(socket))

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

        socket = assign_jobs(socket, fetch_jobs(socket))

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

        <main id="tl-main" class="tl-page">
          <%= if @threadline_exports_enabled do %>
            <header class="tl-page__header">
              <div>
                <h1 class="tl-page__title">What's ready to hand off?</h1>
                <p class="tl-page__lede">
                  Download completed Timeline packets, or reopen the source search when an export needs another pass.
                </p>
              </div>
              <.link navigate={"#{@base_path}/timeline"} class="tl-button tl-button--secondary">Open timeline</.link>
            </header>

            <section class="tl-trust-rail" aria-label="Export workflow">
              <span class="tl-trust-rail__label">Export workflow</span>
              <span class="tl-chip tl-chip--info">Actor-owned jobs</span>
              <span class="tl-chip tl-chip--neutral">Filtered timeline packets</span>
              <.link navigate={"#{@base_path}/timeline"} class="tl-button tl-button--compact tl-button--ghost">Open timeline</.link>
            </section>

            <%= if not @has_jobs do %>
              <div class="tl-empty">
                <h3 class="tl-empty__title">No export jobs queued</h3>
                <p class="tl-empty__body">Queue an export from Timeline, then return here to download the completed packet or reopen the source search.</p>
                <div class="tl-empty__actions">
                  <.link navigate={"#{@base_path}/timeline"} class="tl-button tl-button--secondary">Open timeline</.link>
                </div>
              </div>
            <% else %>
              <section id="export-jobs" data-testid="export-jobs">
                <section :for={group <- @job_groups} class="tl-job-group" data-testid="export-readiness-group">
                  <header class="tl-job-group__header">
                    <h2 class="tl-job-group__title"><%= group.title %></h2>
                    <span><%= length(group.jobs) %> <%= if length(group.jobs) == 1, do: "job", else: "jobs" %></span>
                  </header>

                  <div class="tl-job-list">
                    <article
                      :for={job <- group.jobs}
                      id={"export-job-#{job.id}"}
                      class={["tl-job", job_modifier(job)]}
                      data-testid="export-job"
                    >
                      <div class="tl-job__main">
                        <div class="tl-job__summary">
                          <span class={["tl-chip", Presentation.status_modifier(job.status)]} role={status_role(job)}>
                            <%= Presentation.status_label(job.status) %>
                          </span>
                          <div class="tl-job__title">
                            <strong><%= Presentation.export_summary(job.query_params) %></strong>
                            <% actor = Presentation.secondary_ref(job.actor_ref, 34) %>
                            <span>
                              requested by
                              <%= if path = actor_path(@base_path, job.actor_ref) do %>
                                <a href={path} class="tl-link tl-link--deep tl-secondary-ref" title={actor.title}><%= actor.visible %></a>
                              <% else %>
                                <code class="tl-secondary-ref" title={actor.title}><%= actor.visible %></code>
                              <% end %>
                            </span>
                          </div>
                        </div>

                        <div class="tl-job__actions">
                          <%= if Presentation.export_downloadable?(job) do %>
                            <.link href={"#{@base_path}/exports/download/#{job.id}"} class="tl-button tl-button--primary tl-button--compact">
                              Download export
                            </.link>
                          <% else %>
                            <span class="tl-hint" role="status"><%= Presentation.export_action_label(job) %></span>
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
                          <% ref = Presentation.secondary_ref(value, 42) %>
                          <span class="tl-param" title={"#{key}: #{ref.title}"}>
                            <span class="tl-param__key"><%= key %></span>
                            <span class="tl-param__value tl-secondary-ref"><%= ref.visible %></span>
                          </span>
                        <% end %>
                        <span :if={Presentation.query_pairs(job.query_params) == []} class="tl-param tl-param--muted">
                          No filters
                        </span>
                      </div>

                      <div :if={Presentation.query_pairs(job.query_params) != []} class="tl-job__source">
                        <span class="tl-hint">Source Timeline search</span>
                        <a href={timeline_search_path(@base_path, job.query_params)} class="tl-button tl-button--compact tl-button--secondary">
                          Reopen source search
                        </a>
                      </div>

                      <%= if job.status == "failed" do %>
                        <div class="tl-alert tl-alert--error" role="alert">
                          <strong>Export failed.</strong>
                          Reopen the source search, adjust filters if needed, and queue a new export.
                          <span :if={job.error_message}><%= job.error_message %></span>
                        </div>
                      <% end %>
                    </article>
                  </div>
                </section>
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

    defp assign_jobs(socket, jobs) do
      socket
      |> assign(:jobs, jobs)
      |> assign(:job_groups, group_jobs(jobs))
      |> assign(:has_jobs, length(jobs) > 0)
    end

    defp group_jobs(jobs) do
      jobs
      |> Enum.sort_by(fn job ->
        {Presentation.export_readiness_rank(job), -job_time(job)}
      end)
      |> Enum.group_by(&Presentation.export_readiness/1)
      |> then(fn grouped ->
        for bucket <- [:ready, :preparing, :needs_attention, :unavailable],
            jobs = Map.get(grouped, bucket, []),
            jobs != [] do
          %{title: Presentation.export_readiness_title(List.first(jobs)), jobs: jobs}
        end
      end)
    end

    defp job_time(job) do
      (job.inserted_at || job.started_at || job.completed_at || DateTime.from_unix!(0))
      |> DateTime.to_unix()
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

    defp job_modifier(job) do
      case Presentation.export_readiness(job) do
        :ready -> "tl-job--success"
        :preparing -> "tl-job--info"
        :needs_attention -> "tl-job--danger"
        :unavailable -> nil
      end
    end

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
        "" -> "#{base_path}/timeline"
        query -> "#{base_path}/timeline?#{query}"
      end
    end

    defp timeline_search_path(base_path, _params), do: base_path
  end
end
