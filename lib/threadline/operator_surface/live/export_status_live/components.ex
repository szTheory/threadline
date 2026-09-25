if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.ExportStatusLive.Components do
    @moduledoc false

    # The export job list for the Exports page, with the display helpers that only
    # this markup reads.

    use Phoenix.Component

    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI

    attr(:jobs_count, :integer, required: true)
    attr(:default_limit, :integer, required: true)
    attr(:job_groups, :list, required: true)
    attr(:base_path, :string, default: nil)

    def job_history(assigns) do
      ~H"""
              <section id="export-jobs" data-testid="export-jobs">
                <%!-- Export history is intentionally recent-only rather than keyset-paginated.
                      Report the actual rendered count without overstating a short table;
                      when the cap is reached, use @default_limit instead of a literal. --%>
                <p class="tl-status" role="status" aria-live="polite">
                  <%= if @jobs_count >= @default_limit do %>
                    Showing the most recent <%= @default_limit %> export jobs (newest first).
                  <% else %>
                    Showing the most recent <%= @jobs_count %> <%= if @jobs_count == 1, do: "export job", else: "export jobs" %> (newest first).
                  <% end %>
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
                            <span>
                              requested by
                              <UI.Display.ref value={job.actor_ref} kind="actor" copy_label="Copy actor ref" />
                              <a :if={path = actor_path(@base_path, job.actor_ref)} href={path} class="tl-link tl-link--deep" title="Open actor activity">
                                <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                                Actor
                              </a>
                            </span>
                          </div>
                        </div>

                        <div class="tl-job__actions">
                          <%= if Presentation.export_downloadable?(job) do %>
                            <.link
                              {download_link_attrs(%{base_path: @base_path, job: job})}
                            >
                              <Threadline.OperatorSurface.Components.Icon.icon name={:download} class="tl-button__icon" />
                              Download export
                            </.link>
                          <% else %>
                            <span class="tl-hint" role="status"><%= Presentation.export_status_label(job) %></span>
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

                      <UI.Display.kv :if={Presentation.query_pairs(job.query_params) != []} aria-label="Export filters">
                        <:item :for={{key, value} <- Presentation.query_pairs(job.query_params)} key={key}>
                          <UI.Display.ref value={value} copy_label={"Copy #{key} filter"} />
                        </:item>
                      </UI.Display.kv>
                      <p :if={Presentation.query_pairs(job.query_params) == []} class="tl-param tl-param--muted">
                        No filters
                      </p>

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
      """
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

    defp download_link_attrs(%{base_path: base_path, job: job}) do
      [
        href: "#{base_path}/exports/download/#{job.id}",
        class: "tl-button tl-button--primary tl-button--compact"
      ]
    end
  end
end
