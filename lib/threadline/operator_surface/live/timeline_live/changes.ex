if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive.Changes do
    @moduledoc false

    use Phoenix.Component

    alias Threadline.OperatorSurface.Live.TimelineLive.Helpers
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI

    attr(:changes, :any, required: true)
    attr(:cursor, :any, default: nil)
    attr(:base_path, :string, required: true)
    attr(:timeline_path, :string, required: true)
    attr(:schemas, :map, default: nil)
    attr(:filters_raw, :map, default: %{})

    def change_list(assigns) do
      ~H"""
      <section class="tl-change-list" id="timeline-rows" phx-update="stream"
               phx-viewport-bottom={@cursor && "next-page"}
               data-testid="operator-timeline">
        <div :for={{dom_id, change} <- @changes} id={dom_id} class={["tl-change", Helpers.op_row_modifier(change.op)]} data-testid="timeline-row">
          <div class="tl-change__summary">
            <div class="tl-change__meta">
              <span class={["tl-change__op", Presentation.operation_modifier(change.op)]}><%= Presentation.operation_label(change.op) %></span>
              <span
                class="tl-change__table tl-secondary-ref"
                title={Helpers.table_ref(change).title}
                data-tl-copy={Helpers.table_ref(change).title}
              >
                <%= Helpers.table_ref(change).visible %>
              </span>
              <span
                :if={Threadline.OperatorSurface.Script.enabled?()}
                class="tl-copy-status"
                data-tl-copy-status
                role="status"
                aria-live="polite"
                aria-atomic="true"
              ></span>
              <time class="tl-change__time" datetime={Presentation.exact_time(change.captured_at)} title={Presentation.exact_time(change.captured_at)}>
                <%= Presentation.human_time(change.captured_at) %>
              </time>
            </div>
            <div class="tl-meta">
              <span>
                Actor
                <%= if Helpers.actor_label(change) != "unknown" do %>
                  <UI.Display.ref value={Helpers.actor_label(change)} kind="actor" copy_label="Copy actor ref" />
                  <a
                    :if={path = Helpers.actor_path(@base_path, change)}
                    href={path}
                    class="tl-link tl-link--deep"
                    title="View actor activity"
                  >
                    <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                    Actor timeline
                  </a>
                <% else %>
                  <code><%= Helpers.actor_label(change) %></code>
                <% end %>
              </span>
              <span :if={Helpers.correlation_id(change)}>
                Correlation
                <UI.Display.ref value={Helpers.correlation_id(change)} kind="correlation" copy_label="Copy correlation id" />
                <a href={Helpers.correlation_path(@timeline_path, Helpers.correlation_id(change))} class="tl-link tl-link--deep" title="View correlated changes in Timeline">
                  <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                  Timeline
                </a>
              </span>
              <span :if={row_id = Helpers.routeable_row_ref(change)}>
                Row
                <UI.Display.ref value={row_id} kind="uuid" copy_label="Copy row id" />
              </span>
            </div>
            <div class="tl-change__actions">
              <a href={"#{@base_path}/transactions/#{change.transaction_id}"} class="tl-button tl-button--compact tl-button--secondary" data-testid="transaction-link">
                <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
                Open transaction
              </a>
              <a
                :if={row_history_path = Helpers.safe_row_history_path(@base_path, change, @schemas, @filters_raw)}
                href={row_history_path}
                class="tl-button tl-button--compact tl-button--secondary"
                data-testid="timeline-row-history-link"
              >
                <Threadline.OperatorSurface.Components.Icon.icon name={:history} class="tl-button__icon" />
                Row history
              </a>
            </div>
          </div>
        </div>
      </section>
      """
    end
  end
end
