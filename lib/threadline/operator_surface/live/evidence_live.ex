if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.EvidenceLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Threadline.Evidence
    alias Threadline.Evidence.Proof
    alias Threadline.Evidence.Subject
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Unsupported

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:base_path, nil)
       |> assign(:request, %{subject: nil, subject_ref: nil, mode: :latest})
       |> assign(:groups, [])
       |> assign(:form_error, nil)}
    end

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      base_path = (uri_parsed.path || "") |> String.replace_suffix("/evidence", "")
      socket = assign(socket, :base_path, base_path)

      if socket.assigns[:threadline_evidence_enabled] do
        case parse_request(params) do
          {:ok, request} ->
            records = fetch_records(request, resolve_repo(socket))

            {:noreply,
             socket
             |> assign(:request, request)
             |> assign(:groups, build_groups(records))
             |> assign(:form_error, nil)}

          {:error, message} ->
            {:noreply,
             socket
             |> assign(:request, %{subject: nil, subject_ref: nil, mode: :latest})
             |> assign(:groups, [])
             |> assign(:form_error, message)}
        end
      else
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
            error={@threadline_coverage_error}
            coverage_enabled={@threadline_coverage_enabled}
            policy_enabled={@threadline_policy_enabled}
            evidence_enabled={@threadline_evidence_enabled}
            exports_enabled={@threadline_exports_enabled}
            current={:evidence}
          />
        <% end %>

        <main class="tl-page">
          <%= if @threadline_evidence_enabled do %>
            <header class="tl-page__header">
              <div>
                <h2 class="tl-page__title">What can Threadline prove right now?</h2>
                <p class="tl-page__lede">
                <%= if @request.mode == :history do %>
                  Viewing append-only history for one evidence subject reference.
                <% else %>
                  Latest is a projection over append-only evidence history, not a mutable state record.
                <% end %>
                </p>
              </div>
            </header>

            <section class="tl-trust-rail" aria-label="Evidence proof flow">
              <span class="tl-trust-rail__label">Proof chain</span>
              <span class="tl-chip tl-chip--success">Append-only history</span>
              <span class="tl-chip tl-chip--info">Latest projection</span>
              <a :if={@threadline_coverage_enabled and @base_path} href={"#{@base_path}/coverage"} class="tl-button tl-button--compact tl-button--secondary">Coverage</a>
              <a :if={@threadline_policy_enabled and @base_path} href={"#{@base_path}/policy/redaction"} class="tl-button tl-button--compact tl-button--secondary">Redaction</a>
              <a :if={@threadline_policy_enabled and @base_path} href={"#{@base_path}/policy/retention"} class="tl-button tl-button--compact tl-button--secondary">Retention</a>
            </section>

            <nav class="tl-nav" aria-label="Evidence navigation">
              <.link patch={overview_path(@base_path)} class="tl-button tl-button--secondary">Overview</.link>
              <.link :if={@request.subject} patch={subject_path(@base_path, @request.subject)} class="tl-button tl-button--ghost">
                Back to latest for <%= @request.subject %>
              </.link>
            </nav>

            <%= if @form_error do %>
              <div class="tl-alert tl-alert--error" role="alert"><%= @form_error %></div>
            <% else %>
              <%= if @groups == [] do %>
                <div class="tl-empty">
                  <h3 class="tl-empty__title">No evidence records yet</h3>
                  <p class="tl-empty__body">
                    Threadline has not recorded evidence for this selection yet. Use
                    <code>mix threadline.evidence.show</code> or the <code>Threadline.Evidence</code>
                    API to confirm the current proof state, then narrow by subject or date if
                    needed.
                  </p>
                </div>
              <% else %>
                <section :for={group <- @groups} class="tl-section">
                  <header class="tl-section__header">
                    <h3 class="tl-section__title"><%= group.title %></h3>
                  </header>

                  <div class="tl-record-list" data-testid="evidence-table">
                    <article :for={row <- group.rows} class={["tl-record-card", record_modifier(row.verdict_status)]}>
                      <div class="tl-record-card__main">
                        <h4 class="tl-record-card__title">
                          <span class={["tl-chip", Presentation.status_modifier(row.verdict_status)]}>
                            <%= Presentation.status_label(row.verdict_status) %>
                          </span>
                          <span><%= Presentation.status_label(row.summary_status) %></span>
                        </h4>
                        <div class="tl-record-card__ref"><%= row.subject_ref_json %></div>
                        <div class="tl-record-card__meta">
                          <span class="tl-evidence__meta"><%= row.subject %></span>
                          <time class="tl-table__date" datetime={Presentation.exact_time(row.recorded_at)} title={Presentation.exact_time(row.recorded_at)}>
                            <%= Presentation.human_time(row.recorded_at) %>
                          </time>
                        </div>
                      </div>
                      <div class="tl-record-card__actions">
                        <.link
                          :if={show_subject_link?(@request)}
                          patch={subject_path(@base_path, row.subject)}
                          class="tl-button tl-button--compact tl-button--secondary"
                        >
                          Filter to subject
                        </.link>
                        <.link
                          :if={show_history_link?(@request)}
                          patch={history_path(@base_path, row.subject, row.subject_ref_json)}
                          class="tl-button tl-button--compact tl-button--secondary"
                        >
                          Open proof history
                        </.link>
                        <%= if action = support_action(@base_path, row.subject) do %>
                          <a href={action.path} class="tl-button tl-button--compact tl-button--ghost"><%= action.label %></a>
                        <% end %>
                      </div>
                    </article>
                  </div>
                </section>
              <% end %>
            <% end %>
          <% else %>
            <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
              descriptor={Unsupported.descriptor(:evidence_unavailable)}
              base_path={@base_path}
            />
          <% end %>
        </main>
      </div>
      """
    end

    defp parse_request(params) do
      with {:ok, subject} <- parse_subject(Map.get(params, "subject")),
           {:ok, subject_ref} <- parse_subject_ref(Map.get(params, "subject_ref_json")),
           {:ok, mode} <- parse_mode(Map.get(params, "mode", "latest")),
           :ok <- validate_request_shape(subject, subject_ref, mode) do
        {:ok, %{subject: subject, subject_ref: subject_ref, mode: mode}}
      end
    end

    defp parse_subject(nil), do: {:ok, nil}
    defp parse_subject(""), do: {:ok, nil}

    defp parse_subject(subject) do
      case Subject.validate(subject) do
        :ok ->
          {:ok, subject}

        {:error, {:unsupported_subject, value}} ->
          {:error, "Unsupported evidence subject: #{inspect(value)}"}
      end
    end

    defp parse_subject_ref(nil), do: {:ok, nil}
    defp parse_subject_ref(""), do: {:ok, nil}

    defp parse_subject_ref(payload) do
      case Jason.decode(payload) do
        {:ok, value} when is_map(value) -> {:ok, value}
        {:ok, _other} -> {:error, "subject_ref_json must decode to a JSON object."}
        {:error, error} -> {:error, "Invalid subject_ref_json: #{Exception.message(error)}"}
      end
    end

    defp parse_mode("latest"), do: {:ok, :latest}
    defp parse_mode("history"), do: {:ok, :history}
    defp parse_mode(mode), do: {:error, "Unsupported evidence mode: #{inspect(mode)}"}

    defp validate_request_shape(nil, nil, :latest), do: :ok
    defp validate_request_shape(subject, nil, :latest) when is_binary(subject), do: :ok

    defp validate_request_shape(subject, subject_ref, :latest)
         when is_binary(subject) and is_map(subject_ref),
         do: :ok

    defp validate_request_shape(subject, subject_ref, :history)
         when is_binary(subject) and is_map(subject_ref),
         do: :ok

    defp validate_request_shape(nil, subject_ref, _mode) when is_map(subject_ref) do
      {:error, "subject_ref_json requires a subject filter."}
    end

    defp validate_request_shape(subject, nil, :history) when is_binary(subject) do
      {:error, "History drill-down requires subject_ref_json."}
    end

    defp validate_request_shape(nil, nil, :history) do
      {:error, "History drill-down requires a subject filter."}
    end

    defp fetch_records(%{subject: nil, subject_ref: nil, mode: :latest}, repo) do
      Evidence.list_overview([], repo: repo)
    end

    defp fetch_records(%{subject: subject, subject_ref: nil, mode: :latest}, repo) do
      Evidence.list_latest_subject_refs(subject, repo: repo)
    end

    defp fetch_records(%{subject: subject, subject_ref: subject_ref, mode: :latest}, repo) do
      case Evidence.get_latest_subject_ref(subject, subject_ref, repo: repo) do
        nil -> []
        record -> [record]
      end
    end

    defp fetch_records(%{subject: subject, subject_ref: subject_ref, mode: :history}, repo) do
      Evidence.list_subject_ref_history(subject, subject_ref, repo: repo)
    end

    defp build_groups(records) do
      records
      |> Enum.map(&build_row/1)
      |> Enum.group_by(& &1.subject)
      |> Enum.sort_by(fn {subject, _rows} -> subject end)
      |> Enum.map(fn {subject, rows} ->
        %{title: subject, rows: rows}
      end)
    end

    defp build_row(record) do
      presented = Proof.present_record(record)

      %{
        id: record.id,
        subject: presented.subject,
        subject_ref_json: Jason.encode!(presented.subject_ref),
        summary_status: presented.summary_status,
        recorded_at: record.recorded_at,
        verdict_status: presented.verdict_status
      }
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first() || Threadline.Repo
    end

    defp show_subject_link?(%{subject: nil, mode: :latest}), do: true
    defp show_subject_link?(_request), do: false

    defp show_history_link?(%{mode: :latest}), do: true
    defp show_history_link?(_request), do: false

    defp record_modifier(status) do
      case Presentation.status_modifier(status) do
        "tl-chip--success" -> "tl-record-card--success"
        "tl-chip--warning" -> "tl-record-card--warning"
        "tl-chip--danger" -> "tl-record-card--danger"
        "tl-chip--info" -> "tl-record-card--info"
        _ -> nil
      end
    end

    defp support_action(base_path, "retention_run") when is_binary(base_path),
      do: %{path: "#{base_path}/policy/retention", label: "Retention"}

    defp support_action(base_path, "redaction_policy") when is_binary(base_path),
      do: %{path: "#{base_path}/policy/redaction", label: "Redaction"}

    defp support_action(base_path, "trigger_coverage") when is_binary(base_path),
      do: %{path: "#{base_path}/coverage", label: "Coverage"}

    defp support_action(base_path, "export_job") when is_binary(base_path),
      do: %{path: "#{base_path}/exports", label: "Exports"}

    defp support_action(_base_path, _subject), do: nil

    defp overview_path(base_path), do: "#{base_path}/evidence"
    defp subject_path(base_path, subject), do: "#{base_path}/evidence?subject=#{subject}"

    defp history_path(base_path, subject, subject_ref_json) do
      "#{base_path}/evidence?" <>
        URI.encode_query(%{
          "subject" => subject,
          "subject_ref_json" => subject_ref_json,
          "mode" => "history"
        })
    end
  end
end
