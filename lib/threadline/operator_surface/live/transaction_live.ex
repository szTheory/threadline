if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TransactionLive do
    use Phoenix.LiveView

    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI

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
      <UI.shell
        theme={@threadline_theme}
        coverage={@threadline_coverage}
        base_path={surface_root(@base_path)}
        error={@threadline_coverage_error}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:timeline}
        script
        main_class="tl-page tl-container"
      >
        <%= if @not_found do %>
          <div class="tl-empty tl-empty--error">
            <h3 class="tl-empty__title">Transaction not found</h3>
            <p class="tl-empty__body">Transaction Not Found - The requested transaction ID does not exist or has been purged by the retention policy.</p>
            <div class="tl-empty__actions">
              <.link navigate={"#{surface_root(@base_path)}/timeline"} class="tl-button tl-button--secondary">
                <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_left} class="tl-button__icon" />
                Timeline
              </.link>
            </div>
          </div>
        <% else %>
          <div class="tl-transaction tl-short-content">
            <% transaction_ref = Presentation.secondary_ref(@bundle.transaction.id, 30) %>
            <UI.page_header breadcrumbs={[
              %{label: "Timeline", href: "#{surface_root(@base_path)}/timeline"},
              %{label: "Transaction #{transaction_ref.visible}"}
            ]}>
              <:heading>
                Transaction <UI.ref value={@bundle.transaction.id} kind="uuid" copy_label="Copy transaction id" />
              </:heading>
              <:lede>Changes captured together in one database transaction. Open row history when you need the record state before or after this moment.</:lede>
              <UI.kv aria-label="Transaction context">
                <:item key="Actor">
                  <%= if path = transaction_actor_path(surface_root(@base_path), @bundle.transaction) do %>
                    <a href={path} class="tl-link tl-link--deep"><%= transaction_actor_label(@bundle.transaction) %></a>
                  <% else %>
                    <%= transaction_actor_label(@bundle.transaction) %>
                  <% end %>
                </:item>
                <:item :if={transaction_correlation_id(@bundle.transaction)} key="Correlation">
                  <% correlation_id = transaction_correlation_value(@bundle.transaction) %>
                  <UI.ref value={correlation_id} kind="correlation" copy_label="Copy correlation id" />
                  <a href={timeline_correlation_path(surface_root(@base_path), correlation_id)} class="tl-link tl-link--deep" title="View correlated changes in Timeline">
                    <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                    Timeline
                  </a>
                </:item>
              </UI.kv>
            </UI.page_header>
          </div>
          <%= if Enum.empty?(@bundle.changes) do %>
            <div class="tl-empty">
              <h3 class="tl-empty__title">No row-level changes recorded</h3>
              <p class="tl-empty__body">Threadline found the transaction, but no row-level field changes were captured for it. Check capture coverage for this table, then return to Timeline.</p>
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
                    <span class={["tl-change__op", Presentation.operation_modifier(change.change_diff["op"])]}><%= Presentation.operation_label(change.change_diff["op"]) %></span>
                    <span class="tl-change__table"><%= change.change_diff["table_name"] %></span>
                    <time class="tl-change__time" datetime={change_datetime(change.change_diff["captured_at"])} title={change_datetime(change.change_diff["captured_at"])}>
                      <%= change_time(change.change_diff["captured_at"]) %>
                    </time>
                  </div>
                  <div class="tl-meta">
                    <span>PK <code><%= pk_label(change.change_diff["table_pk"]) %></code></span>
                  </div>
                  <div class="tl-change__actions">
                    <.link patch={change_history_path(@base_path, change)} class="tl-button tl-button--compact tl-button--secondary" title="Open row history" data-testid="row-history-link">
                      <Threadline.OperatorSurface.Components.Icon.icon name={:history} class="tl-button__icon" />
                      Open row history
                    </.link>
                  </div>
                </div>
                <div class="tl-change__fields tl-diff">
                  <%= if normalized_fields(change) == [] do %>
                    <div class="tl-empty">
                      <h3 class="tl-empty__title">No row-level changes recorded</h3>
                      <p class="tl-empty__body">Threadline found the transaction, but no row-level field changes were captured for it. Check capture coverage for this table, then return to Timeline.</p>
                    </div>
                  <% else %>
                    <%= for field <- normalized_fields(change) do %>
                      <div class="tl-change__field tl-diff__row">
                        <span class="tl-change__field-name"><%= field["name"] %></span>
                        <%= if has_before_axis?(field) do %>
                          <% before = Presentation.change_value_token(field, :before) %>
                          <span class="tl-diff__cell">
                            <span class={["tl-value", before.modifier]} title={Map.get(before, :title)}><%= before.text %></span>
                            <button :if={diff_full(before) && Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy tl-button tl-button--compact tl-button--secondary" data-tl-copy={diff_full(before)} aria-label={"Copy #{field["name"]} before value"}>
                              <Threadline.OperatorSurface.Components.Icon.icon name={:copy} class="tl-button__icon" />
                              Copy
                            </button>
                          </span>
                          <span class="tl-diff__arrow">-&gt;</span>
                        <% end %>
                        <% after_token = Presentation.change_value_token(field, :after) %>
                        <span class="tl-diff__cell">
                          <span class={["tl-value", after_token.modifier]} title={Map.get(after_token, :title)}><%= after_token.text %></span>
                          <button :if={diff_full(after_token) && Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy tl-button tl-button--compact tl-button--secondary" data-tl-copy={diff_full(after_token)} aria-label={"Copy #{field["name"]} after value"}>
                            <Threadline.OperatorSurface.Components.Icon.icon name={:copy} class="tl-button__icon" />
                            Copy
                          </button>
                        </span>
                      </div>
                    <% end %>
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
            close_path={@base_path}
            history_path={history_path(@base_path, @history_table, @history_record_id)}
            threadline_schemas={@threadline_schemas}
            repo={@threadline_repo}
            scope={@threadline_scope}
            scope_query_fn={@threadline_scope_query_fn}
          />
        <% end %>
      </UI.shell>
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
         do: Presentation.secondary_ref(correlation_id, 42).visible

    defp transaction_correlation_id(_), do: nil

    # The EXACT full correlation id (never truncated) — UI.ref/1 handles the
    # per-kind visible truncation while binding this full value to data-tl-copy.
    defp transaction_correlation_value(%{action: %{correlation_id: correlation_id}})
         when is_binary(correlation_id) and correlation_id != "",
         do: correlation_id

    defp transaction_correlation_value(_), do: nil

    # The full diff value for the gated copy affordance: value_token/1 keeps the
    # complete value in :title when it truncates; when it does not truncate the
    # rendered text IS the full value. Sentinel placeholders (omitted/absent/null)
    # have no copyable value.
    defp diff_full(%{title: title}) when is_binary(title), do: title

    defp diff_full(%{text: text, modifier: modifier}) do
      if modifier in ["tl-value--omitted", "tl-value--absent", "tl-value--null"] do
        nil
      else
        text
      end
    end

    defp diff_full(_), do: nil

    defp timeline_correlation_path(base_path, correlation_id) when is_binary(correlation_id) do
      "#{base_path}/timeline?#{URI.encode_query(%{"correlation_id" => correlation_id})}"
    end

    defp timeline_correlation_path(base_path, _correlation_id), do: base_path

    defp history_path(base_path, table, record_id) do
      "#{base_path}/history/#{encode_segment(table)}/#{encode_segment(record_id)}"
    end

    defp encode_segment(value), do: URI.encode(to_string(value), &URI.char_unreserved?/1)

    defp change_history_path(base_path, change) do
      table = change.change_diff["table_name"]
      record_id = change.change_diff["table_pk"] |> Map.values() |> List.first()
      captured_at = change.change_diff["captured_at"]

      "#{history_path(base_path, table, record_id)}?as_of=#{captured_at}"
    end

    defp change_time(value) when is_binary(value) do
      case DateTime.from_iso8601(value) do
        {:ok, dt, _offset} -> Presentation.human_time(dt)
        _ -> value
      end
    end

    defp change_time(%DateTime{} = value), do: Presentation.human_time(value)
    defp change_time(value), do: inspect(value)

    # UTC-explicit ISO timestamp for the semantic <time datetime=…> attribute (D-22).
    defp change_datetime(value) when is_binary(value) do
      case DateTime.from_iso8601(value) do
        {:ok, dt, _offset} -> Presentation.exact_time(dt)
        _ -> value
      end
    end

    defp change_datetime(%DateTime{} = value), do: Presentation.exact_time(value)
    defp change_datetime(value), do: to_string(value)

    defp normalized_fields(%{change_diff: %{} = diff}), do: normalized_fields(diff)

    defp normalized_fields(%{} = diff) do
      fields = Map.get(diff, "field_changes", [])

      cond do
        is_list(fields) and fields != [] ->
          fields

        Map.get(diff, "op") == "INSERT" and is_map(Map.get(diff, "data_after")) ->
          diff
          |> Map.fetch!("data_after")
          |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
          |> Enum.map(fn {key, value} ->
            %{"name" => to_string(key), "after" => value}
          end)

        true ->
          []
      end
    end

    defp has_before_axis?(field) when is_map(field) do
      Map.has_key?(field, "before") or Map.has_key?(field, :before) or
        Map.has_key?(field, "prior_state") or Map.has_key?(field, :prior_state)
    end
  end
end
