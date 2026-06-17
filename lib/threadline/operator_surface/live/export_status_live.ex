if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.ExportStatusLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Governance.ExportJob
    alias Threadline.Evidence.Subject
    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.StorageSchema

    @default_limit 100
    @evidence_context_keys ~w(source subject subject_ref_json mode)

    def mount(_params, _session, socket) do
      if connected?(socket) and socket.assigns[:threadline_exports_enabled] do
        schedule_refresh(socket)
      end

      socket =
        socket
        |> assign(:base_path, nil)
        |> assign(:timeline_export_context, nil)
        |> assign(:evidence_export_context, nil)
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
        |> assign(:timeline_export_context, timeline_export_context(params))
        |> assign(:evidence_export_context, evidence_export_context(params, base_path))
        |> assign(:export_denied_descriptor, Unsupported.export_denied_descriptor(params))

      {:noreply, socket}
    end

    def handle_event(
          "queue_timeline_export_context",
          _params,
          %{assigns: %{threadline_exports_enabled: true}} = socket
        ) do
      case socket.assigns.timeline_export_context do
        %{status: :valid, query_params: query_params} when query_params != %{} ->
          repo = resolve_repo(socket)

          job =
            %ExportJob{
              status: "pending",
              query_params: query_params,
              actor_ref: socket.assigns[:threadline_actor_ref]
            }
            |> repo.insert!(StorageSchema.repo_opts())

          adapter =
            Application.get_env(
              :threadline,
              :export_queue_adapter,
              Threadline.ExportQueue.TaskAdapter
            )

          case adapter.enqueue(job.id) do
            :ok ->
              {:noreply,
               socket
               |> put_flash(:info, "Timeline export context queued.")
               |> push_navigate(to: "#{socket.assigns.base_path}/exports")}

            {:error, reason} ->
              error_message = background_export_error_message(reason)

              job
              |> ExportJob.changeset(%{
                status: "failed",
                error_message: error_message,
                expires_at: terminal_export_expiry()
              })
              |> repo.update!(StorageSchema.repo_opts())

              {:noreply, put_flash(socket, :error, error_message)}
          end

        _ ->
          {:noreply, socket}
      end
    end

    def handle_event("queue_timeline_export_context", _params, socket), do: {:noreply, socket}

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
      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
        <Threadline.OperatorSurface.Style.css />
        <%= if @base_path do %>
          <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          theme={@threadline_theme}
            coverage={@threadline_coverage || %{uncovered_count: 0}}
            base_path={@base_path}
            coverage_enabled={@threadline_coverage_enabled}
            policy_enabled={@threadline_policy_enabled}
            evidence_enabled={@threadline_evidence_enabled}
            exports_enabled={@threadline_exports_enabled}
            current={:exports}
          />
        <% end %>

        <main id="tl-main" class="tl-page" tabindex="-1">
          <%= if @threadline_exports_enabled do %>
            <UI.page_header title="What's ready to hand off?">
              <:lede>
                Download completed Timeline packets, or reopen the source search when an export needs another pass.
              </:lede>
              <:actions>
                <.link navigate={"#{@base_path}/timeline"} class="tl-button tl-button--secondary">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                  Open timeline
                </.link>
              </:actions>
            </UI.page_header>

            <section class="tl-trust-rail" aria-label="Export workflow">
              <span class="tl-trust-rail__label">Export workflow</span>
              <span class="tl-chip tl-chip--info">Actor-owned jobs</span>
              <span class="tl-chip tl-chip--neutral">Filtered timeline packets</span>
              <.link navigate={"#{@base_path}/timeline"} class="tl-button tl-button--compact tl-button--ghost">
                <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                Open timeline
              </.link>
            </section>

            <%= if @timeline_export_context do %>
              <section
                class="tl-job tl-job--info"
                data-testid="timeline-export-context"
                data-earned-flow="EF3"
                data-persona="P3"
                data-jtbd="J6"
              >
                <div class="tl-job__main">
                  <div class="tl-job__summary">
                    <span class="tl-chip tl-chip--info">Timeline export context</span>
                    <div class="tl-job__title">
                      <strong>Exports handoff</strong>
                      <span>Pre-populated from the active Timeline filters.</span>
                    </div>
                  </div>
                  <div class="tl-job__actions">
                    <button
                      :if={@timeline_export_context.status == :valid}
                      type="button"
                      phx-click="queue_timeline_export_context"
                      class="tl-button tl-button--primary tl-button--compact"
                    >
                      <Threadline.OperatorSurface.Components.Icon.icon name={:archive} class="tl-button__icon" />
                      Queue Timeline export
                    </button>
                  </div>
                </div>

                <div :if={@timeline_export_context.status == :valid} class="tl-param-list" aria-label="Timeline export filters">
                  <%= for {key, value} <- @timeline_export_context.pairs do %>
                    <% ref = Presentation.secondary_ref(value, 42) %>
                    <span class="tl-param" title={"#{key}: #{ref.title}"}>
                      <span class="tl-param__key"><%= key %></span>
                      <span class="tl-param__value tl-secondary-ref"><%= ref.visible %></span>
                    </span>
                  <% end %>
                </div>

                <div :if={@timeline_export_context.status == :invalid} class="tl-alert tl-alert--error" role="alert">
                  <strong>Timeline export context could not be applied.</strong>
                  Fix the Timeline filters, then carry them to Exports again.
                  <span><%= @timeline_export_context.error %></span>
                </div>
              </section>
            <% end %>

            <%= if @evidence_export_context do %>
              <section
                class="tl-job tl-job--info"
                data-testid="evidence-export-context"
                data-earned-flow="EF3"
                data-persona="P3"
                data-jtbd="J6"
              >
                <div class="tl-job__main">
                  <div class="tl-job__summary">
                    <span class="tl-chip tl-chip--info">Evidence proof context</span>
                    <div class="tl-job__title">
                      <strong>Proof handoff</strong>
                      <span>Pre-populated from the active Evidence proof view.</span>
                    </div>
                  </div>
                  <div class="tl-job__actions">
                    <.link
                      :if={@evidence_export_context.status == :valid}
                      navigate={@evidence_export_context.evidence_path}
                      class="tl-button tl-button--compact tl-button--secondary"
                    >
                      <Threadline.OperatorSurface.Components.Icon.icon name={:evidence} class="tl-button__icon" />
                      Reopen Evidence proof
                    </.link>
                  </div>
                </div>

                <div :if={@evidence_export_context.status == :valid} class="tl-param-list" aria-label="Evidence proof filters">
                  <%= for {key, value} <- @evidence_export_context.pairs do %>
                    <% ref = Presentation.secondary_ref(value, 42) %>
                    <span class="tl-param" title={"#{key}: #{ref.title}"}>
                      <span class="tl-param__key"><%= key %></span>
                      <span class="tl-param__value tl-secondary-ref"><%= ref.visible %></span>
                    </span>
                  <% end %>
                </div>

                <div :if={@evidence_export_context.status == :invalid} class="tl-alert tl-alert--error" role="alert">
                  <strong>Evidence proof context could not be applied.</strong>
                  Return to Evidence, then carry the proof context to Exports again.
                  <span><%= @evidence_export_context.error %></span>
                </div>
              </section>
            <% end %>

            <%= if not @has_jobs do %>
              <div class="tl-empty">
                <h3 class="tl-empty__title">No export jobs queued</h3>
                <p class="tl-empty__body">Queue an export from Timeline, then return here to download the completed packet or reopen the source search.</p>
                <div class="tl-empty__actions">
                  <.link navigate={"#{@base_path}/timeline"} class="tl-button tl-button--secondary">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
                    Open timeline
                  </.link>
                </div>
              </div>
            <% else %>
              <section id="export-jobs" data-testid="export-jobs">
                <%!-- Honest cap caption (D-20): Exports is recent-only / low-volume, not a keyset pager. N = @default_limit (100). --%>
                <p class="tl-status" role="status" aria-live="polite">
                  Showing latest 100 export jobs (most recent first).
                </p>
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
                              <Threadline.OperatorSurface.Components.Icon.icon name={:download} class="tl-button__icon" />
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
                          <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
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
          |> repo.all(StorageSchema.repo_opts())
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

    defp timeline_export_context(params) when is_map(params) do
      if Map.get(params, "source") == "evidence" do
        nil
      else
        timeline_filter_context(params)
      end
    end

    defp timeline_filter_context(params) do
      raw = FilterParams.filters_raw_from_params(params)

      if FilterParams.canonical_query(raw) == "" do
        nil
      else
        case FilterParams.parse(params) do
          {:ok, filters} ->
            case safe_validate(filters) do
              :ok ->
                query_params = canonical_query_params(raw)

                %{
                  status: :valid,
                  query_params: query_params,
                  pairs: Presentation.query_pairs(query_params)
                }

              {:error, message} ->
                %{status: :invalid, error: message}
            end

          {:error, message} ->
            %{status: :invalid, error: message}
        end
      end
    end

    defp evidence_export_context(%{"source" => "evidence"} = params, base_path) do
      case parse_evidence_context(params) do
        {:ok, context} ->
          %{
            status: :valid,
            pairs: evidence_context_pairs(context),
            evidence_path: evidence_context_path(base_path, context)
          }

        {:error, message} ->
          %{status: :invalid, error: message}
      end
    end

    defp evidence_export_context(_params, _base_path), do: nil

    defp parse_evidence_context(params) do
      with :ok <- validate_evidence_context_keys(params),
           {:ok, subject} <- parse_evidence_subject(Map.get(params, "subject")),
           {:ok, subject_ref} <- parse_evidence_subject_ref(Map.get(params, "subject_ref_json")),
           {:ok, mode} <- parse_evidence_mode(Map.get(params, "mode", "latest")),
           :ok <- validate_evidence_context_shape(subject, subject_ref, mode) do
        {:ok, %{subject: subject, subject_ref: subject_ref, mode: mode}}
      end
    end

    defp validate_evidence_context_keys(params) do
      case Enum.reject(Map.keys(params), &(&1 in @evidence_context_keys)) do
        [] ->
          :ok

        [key | _rest] ->
          {:error, "Unsupported Evidence proof context parameter: #{key}."}
      end
    end

    defp parse_evidence_subject(nil), do: {:ok, nil}
    defp parse_evidence_subject(""), do: {:ok, nil}

    defp parse_evidence_subject(subject) do
      case Subject.validate(subject) do
        :ok ->
          {:ok, subject}

        {:error, {:unsupported_subject, value}} ->
          {:error, "Unsupported evidence subject: #{inspect(value)}"}
      end
    end

    defp parse_evidence_subject_ref(nil), do: {:ok, nil}
    defp parse_evidence_subject_ref(""), do: {:ok, nil}

    defp parse_evidence_subject_ref(payload) do
      case Jason.decode(payload) do
        {:ok, value} when is_map(value) -> {:ok, value}
        {:ok, _other} -> {:error, "subject_ref_json must decode to a JSON object."}
        {:error, error} -> {:error, "Invalid subject_ref_json: #{Exception.message(error)}"}
      end
    end

    defp parse_evidence_mode("latest"), do: {:ok, :latest}
    defp parse_evidence_mode("history"), do: {:ok, :history}
    defp parse_evidence_mode(mode), do: {:error, "Unsupported evidence mode: #{inspect(mode)}"}

    defp validate_evidence_context_shape(nil, nil, :latest), do: :ok
    defp validate_evidence_context_shape(subject, nil, :latest) when is_binary(subject), do: :ok

    defp validate_evidence_context_shape(subject, subject_ref, :latest)
         when is_binary(subject) and is_map(subject_ref),
         do: :ok

    defp validate_evidence_context_shape(subject, subject_ref, :history)
         when is_binary(subject) and is_map(subject_ref),
         do: :ok

    defp validate_evidence_context_shape(nil, subject_ref, _mode) when is_map(subject_ref) do
      {:error, "subject_ref_json requires a subject filter."}
    end

    defp validate_evidence_context_shape(subject, nil, :history) when is_binary(subject) do
      {:error, "History drill-down requires subject_ref_json."}
    end

    defp validate_evidence_context_shape(nil, nil, :history) do
      {:error, "History drill-down requires a subject filter."}
    end

    defp evidence_context_pairs(%{subject: subject, subject_ref: subject_ref, mode: mode}) do
      []
      |> maybe_append_pair("subject", subject)
      |> maybe_append_pair("mode", Atom.to_string(mode))
      |> maybe_append_pair("subject_ref_json", encode_subject_ref(subject_ref))
    end

    defp maybe_append_pair(pairs, _key, nil), do: pairs
    defp maybe_append_pair(pairs, _key, ""), do: pairs
    defp maybe_append_pair(pairs, key, value), do: pairs ++ [{key, value}]

    defp encode_subject_ref(nil), do: nil
    defp encode_subject_ref(subject_ref), do: Jason.encode!(subject_ref)

    defp evidence_context_path(base_path, %{
           subject: subject,
           subject_ref: subject_ref,
           mode: mode
         }) do
      params =
        %{}
        |> maybe_put("subject", subject)
        |> maybe_put("subject_ref_json", encode_subject_ref(subject_ref))
        |> maybe_put_mode(mode)

      case URI.encode_query(params) do
        "" -> "#{base_path}/evidence"
        query -> "#{base_path}/evidence?#{query}"
      end
    end

    defp maybe_put(params, _key, nil), do: params
    defp maybe_put(params, _key, ""), do: params
    defp maybe_put(params, key, value), do: Map.put(params, key, value)

    defp maybe_put_mode(params, :history), do: Map.put(params, "mode", "history")
    defp maybe_put_mode(params, _mode), do: params

    defp canonical_query_params(raw) do
      raw
      |> FilterParams.canonical_query()
      |> URI.decode_query()
    end

    defp safe_validate(filters) do
      try do
        Threadline.Query.validate_timeline_filters!(filters)
        :ok
      rescue
        e in ArgumentError -> {:error, e.message}
      end
    end

    defp background_export_error_message(:supervisor_not_started) do
      "Background export could not start because the built-in export runtime is unavailable."
    end

    defp background_export_error_message(reason) do
      "Background export could not start: #{inspect(reason)}."
    end

    defp terminal_export_expiry do
      retention_ttl_hours =
        Application.get_env(:threadline, :exports, [])
        |> Keyword.get(:retention_ttl_hours, 24 * 7)

      DateTime.utc_now()
      |> DateTime.truncate(:microsecond)
      |> DateTime.add(retention_ttl_hours * 60 * 60, :second)
    end
  end
end
