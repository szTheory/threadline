if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TransactionLive do
    use Phoenix.LiveView

    alias Threadline.OperatorSurface.Presentation

    def mount(%{"id" => id}, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      case Threadline.incident_bundle(id,
             repo: repo,
             preload: :action,
             scope: socket.assigns[:threadline_scope],
             scope_query_fn: socket.assigns[:threadline_scope_query_fn],
             surface: :transaction,
             params: %{transaction_id: id}
           ) do
        {:error, :not_found} ->
          {:ok, assign(socket, :not_found, true)}

        {:ok, bundle} ->
          {:ok,
           socket
           |> assign(:threadline_repo, repo)
           |> assign(:not_found, false)
           |> assign(:bundle, bundle)
           |> stream_configure(:changes,
             dom_id: fn change -> "change-#{change.change_diff["id"]}" end
           )
           |> stream(:changes, bundle.changes)}
      end
    end

    def handle_params(params, uri, socket) do
      uri_parsed = URI.parse(uri)
      # Extract base path up to /transactions/:id
      base_path =
        case Regex.run(~r/(.*\/transactions\/[^\/]+)/, uri_parsed.path) do
          [_, path] -> path
          _ -> uri_parsed.path
        end

      socket = assign(socket, :base_path, base_path)

      if socket.assigns.live_action == :history do
        table = params["table"]
        record_id = params["record_id"]

        as_of =
          case params["as_of"] do
            nil ->
              nil

            "" ->
              nil

            str ->
              case DateTime.from_iso8601(str) do
                {:ok, dt, _offset} -> dt
                _ -> nil
              end
          end

        {:noreply,
         assign(socket,
           show_history: true,
           history_table: table,
           history_record_id: record_id,
           history_as_of: as_of
         )}
      else
        {:noreply,
         assign(socket,
           show_history: false,
           history_table: nil,
           history_record_id: nil,
           history_as_of: nil
         )}
      end
    end

    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <Threadline.OperatorSurface.Script.js />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          coverage={@threadline_coverage}
          base_path={surface_root(@base_path)}
          error={@threadline_coverage_error}
          coverage_enabled={@threadline_coverage_enabled}
          policy_enabled={@threadline_policy_enabled}
          evidence_enabled={@threadline_evidence_enabled}
          exports_enabled={@threadline_exports_enabled}
          current={:timeline}
        />
        <main id="tl-main">
        <%= if @not_found do %>
          <div class="tl-empty tl-empty--error">
            <h3 class="tl-empty__title">Transaction not found</h3>
            <p class="tl-empty__body">Transaction Not Found - The requested transaction ID does not exist or has been purged by the retention policy.</p>
            <div class="tl-empty__actions">
              <.link navigate={"#{surface_root(@base_path)}/timeline"} class="tl-button tl-button--secondary">← Timeline</.link>
            </div>
          </div>
        <% else %>
          <div class="tl-transaction">
            <nav class="tl-transaction__breadcrumbs" aria-label="Investigation path">
              <a href={"#{surface_root(@base_path)}/timeline"} class="tl-link tl-link--back">← Timeline</a>
              <span>Transaction</span>
            </nav>
            <div class="tl-page__header">
              <div>
                <h1 class="tl-transaction__title" title={@bundle.transaction.id}>
                  Transaction <code><%= Presentation.short_id(@bundle.transaction.id, 14) %></code>
                  <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy" data-tl-copy={@bundle.transaction.id} aria-label="Copy transaction id">Copy</button>
                </h1>
                <p class="tl-page__lede">Changes captured together in one database transaction. Open row history when you need the record state before or after this moment.</p>
              </div>
              <div class="tl-param-list" aria-label="Transaction context">
                <span class="tl-param">
                  <span class="tl-param__key">Actor</span>
                  <span class="tl-param__value">
                    <%= if path = transaction_actor_path(surface_root(@base_path), @bundle.transaction) do %>
                      <a href={path} class="tl-link tl-link--deep"><%= transaction_actor_label(@bundle.transaction) %></a>
                    <% else %>
                      <%= transaction_actor_label(@bundle.transaction) %>
                    <% end %>
                  </span>
                </span>
                <span :if={transaction_correlation_id(@bundle.transaction)} class="tl-param">
                  <span class="tl-param__key">Correlation</span>
                  <span class="tl-param__value">
                    <a href={timeline_correlation_path(surface_root(@base_path), transaction_correlation_id_raw(@bundle.transaction))} class="tl-link tl-link--deep">
                      <%= transaction_correlation_id(@bundle.transaction) %>
                    </a>
                  </span>
                </span>
              </div>
            </div>
          </div>
          <%= if Enum.empty?(@bundle.changes) do %>
            <div class="tl-empty">
              <h3 class="tl-empty__title">No changes recorded</h3>
              <p class="tl-empty__body">Threadline found the transaction context, but no row-level changes were captured for it.</p>
            </div>
          <% else %>
            <div
              id="changes-list"
              phx-update="stream"
              phx-viewport-top="prev-page"
              phx-viewport-bottom="next-page"
              class="tl-viewport"
            >
              <div :for={{dom_id, change} <- @streams.changes} id={dom_id} class="tl-change" data-testid="transaction-change-row">
                <div class="tl-change__summary">
                  <div class="tl-change__meta">
                    <span class={["tl-change__op", op_chip_modifier(change.change_diff["op"])]}><%= change.change_diff["op"] %></span>
                    <span class="tl-change__table"><%= change.change_diff["table_name"] %></span>
                    <time class="tl-change__time" datetime={change.change_diff["captured_at"]} title={change.change_diff["captured_at"]}>
                      <%= change_time(change.change_diff["captured_at"]) %>
                    </time>
                  </div>
                  <div class="tl-meta">
                    <span>PK <code><%= pk_label(change.change_diff["table_pk"]) %></code></span>
                  </div>
                  <div class="tl-change__actions">
                    <.link patch={"#{@base_path}/history/#{change.change_diff["table_name"]}/#{change.change_diff["table_pk"] |> Map.values() |> List.first()}?as_of=#{change.change_diff["captured_at"]}"} class="tl-button tl-button--compact tl-button--secondary" title="Open row history" data-testid="row-history-link">
                      Open row history
                    </.link>
                  </div>
                </div>
                <div class="tl-change__fields">
                  <%= for field <- change.change_diff["field_changes"] do %>
                    <div class="tl-change__field">
                      <span class="tl-change__field-name"><%= field["name"] %></span>:
                      <%= if Map.has_key?(field, "before") do %>
                        <span class="tl-change__before"><%= inspect(field["before"]) %></span> ->
                      <% end %>
                      <%= if Map.has_key?(field, "prior_state") do %>
                        <span class="tl-change__omitted">(omitted)</span> ->
                      <% end %>
                      <span class="tl-change__after"><%= inspect(field["after"]) %></span>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
        <%= if @show_history do %>
          <.live_component
            module={Threadline.OperatorSurface.Live.RowHistoryComponent}
            id="row-history"
            table={@history_table}
            record_id={@history_record_id}
            as_of={@history_as_of}
            base_path={@base_path}
            threadline_schemas={@threadline_schemas}
            repo={@threadline_repo}
            scope={@threadline_scope}
            scope_query_fn={@threadline_scope_query_fn}
          />
        <% end %>
        </main>
      </div>
      """
    end

    def handle_event("prev-page", _, socket) do
      {:noreply, socket}
    end

    def handle_event("next-page", _, socket) do
      {:noreply, socket}
    end

    # `@base_path` is the request path including `/transactions/:id` for
    # in-LV navigation (history sub-route). The surface header needs the
    # operator surface mount root (e.g. `/audit`) so the coverage badge
    # links to `/audit/coverage`, not `/audit/transactions/:id/coverage`.
    # Strip the `/transactions/...` suffix to recover the mount root.
    # (Rule 1 auto-fix during Plan 66-04 Task 1 — surface header invocation
    # produced wrong href without this transformation.)
    defp surface_root(path) when is_binary(path) do
      case Regex.run(~r/^(.*)\/transactions\//, path) do
        [_, root] -> root
        _ -> path
      end
    end

    defp surface_root(_), do: nil

    defp pk_label(pk) when is_map(pk) do
      pk
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join(", ")
    end

    defp pk_label(pk), do: inspect(pk)

    defp transaction_actor_label(%{actor_ref: %{type: type, id: id}}) when not is_nil(id),
      do: "#{type}/#{Presentation.truncate_middle(id, 28)}"

    defp transaction_actor_label(%{actor_ref: %{"type" => type, "id" => id}}) when not is_nil(id),
      do: "#{type}/#{Presentation.truncate_middle(id, 28)}"

    defp transaction_actor_label(_), do: "unknown"

    defp transaction_actor_path(base_path, %{actor_ref: %{type: type, id: id}})
         when is_binary(base_path) and not is_nil(id),
         do:
           "#{base_path}/actors/#{URI.encode_www_form(to_string(type))}/#{URI.encode_www_form(to_string(id))}"

    defp transaction_actor_path(base_path, %{actor_ref: %{"type" => type, "id" => id}})
         when is_binary(base_path) and not is_nil(id),
         do:
           "#{base_path}/actors/#{URI.encode_www_form(to_string(type))}/#{URI.encode_www_form(to_string(id))}"

    defp transaction_actor_path(_base_path, _transaction), do: nil

    defp transaction_correlation_id(%{action: %{correlation_id: correlation_id}})
         when is_binary(correlation_id) and correlation_id != "",
         do: Presentation.truncate_middle(correlation_id, 42)

    defp transaction_correlation_id(_), do: nil

    defp transaction_correlation_id_raw(%{action: %{correlation_id: correlation_id}})
         when is_binary(correlation_id) and correlation_id != "",
         do: correlation_id

    defp transaction_correlation_id_raw(_), do: nil

    defp timeline_correlation_path(base_path, correlation_id) when is_binary(correlation_id) do
      "#{base_path}/timeline?#{URI.encode_query(%{"correlation_id" => correlation_id})}"
    end

    defp timeline_correlation_path(base_path, _correlation_id), do: base_path

    defp op_chip_modifier(op) do
      case op |> to_string() |> String.downcase() do
        "insert" -> "tl-change__op--insert"
        "update" -> "tl-change__op--update"
        "delete" -> "tl-change__op--delete"
        _ -> nil
      end
    end

    defp change_time(value) when is_binary(value) do
      case DateTime.from_iso8601(value) do
        {:ok, dt, _offset} -> Presentation.human_time(dt)
        _ -> value
      end
    end

    defp change_time(%DateTime{} = value), do: Presentation.human_time(value)
    defp change_time(value), do: inspect(value)
  end
end
