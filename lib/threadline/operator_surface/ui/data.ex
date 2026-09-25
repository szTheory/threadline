if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Threadline.OperatorSurface.UI.Data do
    @moduledoc false
    use Phoenix.Component
    alias Phoenix.LiveView.JS
    alias Threadline.OperatorSurface.Components.Icon
    alias Threadline.OperatorSurface.UI.Display

    @doc false
    # Responsive data table. The :col slot's required label feeds both the
    # <th> AND every <td data-label> from one source (structurally guarantees mobile
    # labels match the header). Supports `rows` OR `stream` (truthy -> phx-update="stream"
    # on <tbody>); row_id sets <tr id=...>; row_status emits the data-status stripe (zero
    # new CSS). Do not add ARIA role="table"/"row"/"cell"; the native table is the
    # accessibility surface, not synthetic table roles.
    attr(:rows, :list, default: nil)
    attr(:stream, :any, default: nil)
    attr(:row_id, :any, default: nil, doc: "Fn returning a DOM id for the <tr>")

    attr(:row_status, :any,
      default: nil,
      doc: "Fn returning a status string for the data-status stripe"
    )

    attr(:tbody_id, :string, default: nil)
    attr(:class, :any, default: nil)
    attr(:rest, :global)

    slot :col, required: true do
      attr(:label, :string, required: true)
    end

    slot(:action)

    def data_table(assigns) do
      assigns = assign_new(assigns, :data_rows, fn -> assigns.stream || assigns.rows || [] end)

      ~H"""
      <table class={["tl-table", "tl-table--responsive", @class]} {@rest}>
        <thead>
          <tr>
            <th :for={col <- @col}><%= col.label %></th>
            <th :if={@action != []} class="tl-table__actions"></th>
          </tr>
        </thead>
        <tbody id={@tbody_id} phx-update={@stream && "stream"}>
          <tr :for={row <- @data_rows} id={@row_id && @row_id.(row)} data-status={@row_status && @row_status.(row)}>
            <td :for={col <- @col} data-label={col.label}><%= render_slot(col, row) %></td>
            <td :if={@action != []} class="tl-table__actions"><%= render_slot(@action, row) %></td>
          </tr>
        </tbody>
      </table>
      """
    end

    @doc false
    attr(:class, :any, default: nil)

    attr(:variant, :string,
      default: nil,
      values: [nil, "error", "never", "unsupported", "no_data", "permission", "unavailable"]
    )

    attr(:role, :string, default: nil, doc: "ARIA live role: status (default) or alert")
    attr(:icon, :atom, default: nil, doc: "Distinct glyph shape; never color alone")

    attr(:focus_heading, :boolean,
      default: false,
      doc: "Render the heading as a tabindex=-1 target and move focus on mount"
    )

    attr(:heading_id, :string, default: nil)
    attr(:rest, :global)
    slot(:title)
    slot(:actions)
    slot(:inner_block, required: true)

    def empty_state(assigns) do
      assigns =
        assign_new(assigns, :resolved_heading_id, fn ->
          if assigns.focus_heading do
            assigns.heading_id || "tl-empty-heading-#{System.unique_integer([:positive])}"
          end
        end)

      ~H"""
      <div class={["tl-empty", @variant && "tl-empty--#{@variant}", @class]} role={@role} {@rest}>
        <Icon.icon :if={@icon} name={@icon} class="tl-empty__icon" />
        <h3
          :if={@title != []}
          id={@resolved_heading_id}
          class="tl-empty__title"
          tabindex={@focus_heading && "-1"}
          phx-mounted={@focus_heading && JS.focus(to: "##{@resolved_heading_id}")}
        >
          <%= render_slot(@title) %>
        </h3>
        <div class="tl-empty__body">
          <%= render_slot(@inner_block) %>
        </div>
        <div :if={@actions != []} class="tl-empty__actions"><%= render_slot(@actions) %></div>
      </div>
      """
    end

    @doc false
    # Thin variant="error" wrapper: role=alert, distinct alert glyph, and a
    # tabindex=-1 heading that takes focus on mount (focus rescue).
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:title)
    slot(:actions)
    slot(:inner_block, required: true)

    def error_state(assigns) do
      ~H"""
      <.empty_state
        variant="error"
        role="alert"
        icon={:warning}
        focus_heading
        class={@class}
        {@rest}
      >
        <:title :if={@title != []}><%= render_slot(@title) %></:title>
        <%= render_slot(@inner_block) %>
        <:actions :if={@actions != []}><%= render_slot(@actions) %></:actions>
      </.empty_state>
      """
    end

    @doc false
    # Loading state: a structurally distinct named sibling (not an empty_state
    # variant). role=status + aria-busy so SR users hear progress; renders the spinner
    # plus a text node that callers may override. Must always resolve to a terminal state.
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:inner_block)

    def loading_state(assigns) do
      ~H"""
      <div class={["tl-empty", "tl-empty--loading", @class]} role="status" aria-busy="true" {@rest}>
        <Display.spinner class="tl-empty__spinner" />
        <p class="tl-empty__body">
          <%= if @inner_block != [], do: render_slot(@inner_block), else: "Loading audit changes…" %>
        </p>
      </div>
      """
    end

    @doc false
    # Stale banner: a role=status strip rendered above still-visible last-good
    # data. It precedes, never replaces, and is not a clause in any async switch. Reuses
    # the tl-alert--warning shell with a refresh glyph and an as_of timestamp.
    attr(:as_of, :string, default: nil, doc: "Timestamp of the last known good data")
    attr(:object_label, :string, default: "audit data", doc: "Object shown from last-good data")
    attr(:class, :any, default: nil)
    attr(:rest, :global)

    def stale_banner(assigns) do
      ~H"""
      <div class={["tl-alert", "tl-alert--warning", @class]} role="status" {@rest}>
        <Icon.icon name={:refresh} class="tl-alert__icon" />
        Could not refresh - showing last known <%= @object_label %> from <%= @as_of || "the last successful refresh" %>. Retry.
      </div>
      """
    end

    @doc false
    # Typed-reason data-state dispatcher. Preserves the server's typed reason all the way
    # to the view and maps it to a distinct role, icon shape, and
    # heading — the three load-bearing forensic distinctions (permission ≠ no-data ≠
    # unavailable) never collapse to a generic "something went wrong". Each unavailable
    # sub-case states it is NOT a permissions issue.
    attr(:reason, :atom, required: true)
    attr(:as_of, :string, default: nil, doc: "Timestamp for the pruned (retention) sub-case")

    attr(:capability, :string,
      default: "audit:read",
      doc: "Required capability for permission states"
    )

    attr(:logs_label, :string,
      default: "operator logs",
      doc: "Where operators should check after retrying unavailable data"
    )

    attr(:class, :any, default: nil)
    attr(:rest, :global)

    def data_state(%{reason: :loading} = assigns) do
      ~H"""
      <.loading_state class={@class} {@rest} />
      """
    end

    def data_state(%{reason: :no_data} = assigns) do
      ~H"""
      <.empty_state variant="no_data" role="status" icon={:funnel} class={@class} {@rest}>
        <:title>No audit changes match these filters</:title>
        Clear a filter or widen the time range.
      </.empty_state>
      """
    end

    def data_state(%{reason: :unauthorized} = assigns) do
      ~H"""
      <.empty_state
        variant="permission"
        role="alert"
        icon={:lock}
        focus_heading
        class={@class}
        {@rest}
      >
        <:title>You do not have access to this audit data</:title>
        The audit data exists; your account needs <code><%= @capability %></code>.
      </.empty_state>
      """
    end

    def data_state(%{reason: :source_down} = assigns) do
      ~H"""
      <.empty_state variant="unavailable" role="alert" icon={:cloud_off} class={@class} {@rest}>
        <:title>Audit data is temporarily unavailable</:title>
        This is not a permissions issue. Retry, then check <%= @logs_label %>.
      </.empty_state>
      """
    end

    def data_state(%{reason: :redacted} = assigns) do
      ~H"""
      <.empty_state variant="unavailable" role="status" icon={:eye_off} class={@class} {@rest}>
        <:title>Value redacted by policy</:title>
        This value exists but is withheld. This is not a permissions issue. Check the redaction policy before relying on this view.
      </.empty_state>
      """
    end

    def data_state(%{reason: :pruned} = assigns) do
      ~H"""
      <.empty_state variant="unavailable" role="status" icon={:archive} class={@class} {@rest}>
        <:title>Audit data pruned under retention<%= if @as_of, do: " on #{@as_of}" %></:title>
        This audit data was permanently deleted under retention. This is not a permissions issue. Check the retention window before relying on this view.
      </.empty_state>
      """
    end

    def data_state(assigns) do
      ~H"""
      <.error_state class={@class} {@rest}>
        <:title>Could not load audit data</:title>
        Retry, then check logs.
      </.error_state>
      """
    end

    @doc false
    # State-coordinating shell. data_panel composes the existing named state family; it
    # does not reinvent the taxonomy or the focus logic. The page author still branches
    # the typed server reason; the shell
    # only decides which region shows and where the pager/stale-banner sit.
    #
    # Coordination rules (locked):
    #   * :ok            -> render the :data slot; pager rendered.
    #   * :loading       -> loading_state (role=status); :data + pager suppressed.
    #   * :empty         -> empty_state (first-run); :data + pager suppressed.
    #   * :no_data       -> data_state(:no_data) (filters active); suppressed.
    #   * :error         -> error_state (focus rescue heading); suppressed.
    #   * :permission /
    #     :unavailable   -> data_state(@reason) COLLAPSES the body to one message,
    #                       preserving the distinct icon shape + heading + focus rescue
    #                       and is never converted to a generic empty.
    #   * as_of present  -> stale_banner rendered ABOVE the region regardless of state
    #                       (coexists with :ok data and never replaces it). Stale
    #                       is NOT a clause in the region cond.
    # Focus-move on error/permission/unavailable is delegated to the state family (the
    # rendered tabindex=-1 heading / phx-mounted JS.focus the family already emits).
    attr(:state, :atom,
      default: :ok,
      doc: "ok | loading | empty | no_data | error | permission | unavailable"
    )

    attr(:reason, :atom,
      default: nil,
      doc: "typed reason passed straight to data_state/1 for permission/unavailable/no_data"
    )

    attr(:as_of, :string,
      default: nil,
      doc: "stale timestamp; presence renders stale_banner above the region"
    )

    attr(:id, :string,
      default: nil,
      doc:
        "optional base id; when set the region is state-keyed (`{id}-region-{state}`) so an " <>
          "in-place state swap replays the cross-fade"
    )

    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:data, required: true, doc: "the data_table — only rendered in :ok")
    slot(:pager)

    def data_panel(assigns) do
      if assigns.state in [:permission, :unavailable] and is_nil(assigns.reason) do
        # Fail loudly: a missing reason would otherwise fall through data_state/1 to the
        # generic error, silently erasing the permission/unavailable forensic distinction
        # this shell promises never to collapse.
        raise ArgumentError,
              "data_panel state=#{inspect(assigns.state)} requires a typed :reason " <>
                "(e.g. :unauthorized, :source_down, :redacted, :pruned)"
      end

      ~H"""
      <section class={["tl-data-panel", @class]} {@rest}>
        <.stale_banner :if={@as_of} as_of={@as_of} />
        <div
          class="tl-data-panel__region"
          id={@id && "#{@id}-region-#{@state}"}
          data-state={@state}
        >
          <%= cond do %>
            <% @state == :ok -> %>
              <%= render_slot(@data) %>
            <% @state in [:permission, :unavailable] -> %>
              <.data_state reason={@reason} as_of={@as_of} />
            <% @state == :error -> %>
              <.error_state>
                <:title>Could not load audit data</:title>
                Retry, then check logs.
              </.error_state>
            <% @state == :empty -> %>
              <.empty_state role="status">
                <:title>No audit changes yet</:title>
                Audit changes appear after captured database transactions.
              </.empty_state>
            <% @state == :no_data -> %>
              <.data_state reason={:no_data} />
            <% true -> %>
              <.loading_state />
          <% end %>
        </div>
        <div :if={@pager != [] and @state == :ok} class="tl-data-panel__pager">
          <%= render_slot(@pager) %>
        </div>
      </section>
      """
    end
  end
end
