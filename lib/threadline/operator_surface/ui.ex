defmodule Threadline.OperatorSurface.UI do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  alias Phoenix.LiveView.JS
  alias Threadline.OperatorSurface.Components.Icon
  alias Threadline.OperatorSurface.Presentation
  alias Threadline.OperatorSurface.Script

  @doc false
  attr(:type, :string, default: "button")
  attr(:class, :any, default: nil)

  attr(:variant, :string,
    default: "secondary",
    values: ~w(primary secondary quiet-primary danger ghost icon)
  )

  attr(:compact, :boolean, default: false)
  attr(:rest, :global, include: ~w(disabled form name value phx-disable-with))
  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "tl-button",
        @variant != "secondary" && "tl-button--#{@variant}",
        @compact && "tl-button--compact",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc false
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(disabled form name value phx-disable-with))
  slot(:inner_block, required: true)

  def icon_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "tl-button",
        "tl-button--icon",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc false
  attr(:navigate, :string, default: nil)
  attr(:patch, :string, default: nil)
  attr(:href, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:variant, :string, default: "deep", values: ~w(back deep))
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def link(assigns) do
    ~H"""
    <Phoenix.Component.link
      navigate={@navigate}
      patch={@patch}
      href={@href}
      class={[
        "tl-link",
        @variant && "tl-link--#{@variant}",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  @doc false
  attr(:variant, :string,
    default: "neutral",
    values: ~w(info warning danger success accent muted neutral)
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span class={["tl-chip", "tl-chip--#{@variant}", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  @doc false
  attr(:variant, :string, default: "info", values: ~w(info warning success error))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def alert(assigns) do
    ~H"""
    <div class={["tl-alert", "tl-alert--#{@variant}", @class]} role="alert" {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc false
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def divider(assigns) do
    ~H"""
    <hr class={["tl-divider", @class]} {@rest} />
    """
  end

  @doc false
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def spinner(assigns) do
    ~H"""
    <svg class={["tl-spinner", @class]} viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" {@rest}>
      <circle cx="12" cy="12" r="10" stroke-opacity="0.25" />
      <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
    </svg>
    """
  end

  @doc false
  attr(:src, :string, required: true)
  attr(:alt, :string, default: "")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def avatar(assigns) do
    ~H"""
    <img src={@src} alt={@alt} class={["tl-avatar", @class]} {@rest} />
    """
  end

  @doc false
  attr(:class, :any, default: nil)

  attr(:variant, :string,
    default: nil,
    values: [nil, "danger", "warning", "success", "info", "signal"]
  )

  attr(:rest, :global)
  slot(:title)
  slot(:meta)
  slot(:actions)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={["tl-card", @variant && "tl-card--#{@variant}", @class]} {@rest}>
      <div :if={@title != [] || @meta != []} class="tl-card__header">
        <h3 :if={@title != []} class="tl-card__title"><%= render_slot(@title) %></h3>
        <div :if={@meta != []} class="tl-card__meta"><%= render_slot(@meta) %></div>
      </div>
      <div class="tl-card__body">
        <%= render_slot(@inner_block) %>
      </div>
      <div :if={@actions != []} class="tl-card__actions"><%= render_slot(@actions) %></div>
    </div>
    """
  end

  @doc false
  attr(:gap, :string, default: "stack", values: ~w(stack section inline tight))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def stack(assigns) do
    ~H"""
    <div class={["tl-stack", "tl-stack--#{@gap}", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc false
  attr(:justify, :string, default: "start", values: ~w(start between end))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def cluster(assigns) do
    ~H"""
    <div class={["tl-cluster", "tl-cluster--#{@justify}", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc false
  attr(:title, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:variant, :string, default: "heading", values: ~w(heading display))

  attr(:breadcrumbs, :list,
    default: [],
    doc: "Ordered location trail; each item is a map %{label: ..., href: nil | binary}"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:heading,
    doc: "Rich heading content rendered inside the single <h1> (overrides title attr)"
  )

  slot(:lede)

  slot(:meta,
    doc: "Optional supporting meta line rendered under the lede (e.g. last-checked time)"
  )

  slot(:actions)
  slot(:inner_block)

  def page_header(assigns) do
    ~H"""
    <header class={["tl-page__header"] ++ if(@variant == "display", do: ["tl-home__hero"], else: []) ++ List.wrap(@class)} {@rest}>
      <.breadcrumb_trail :if={@breadcrumbs != []} crumbs={@breadcrumbs} />
      <div>
        <h1 id={@id} class={if @variant == "display", do: "tl-home__headline", else: "tl-page__title"}>
          <%= if @heading != [], do: render_slot(@heading), else: @title %>
        </h1>
        <p :if={@lede != []} class={if @variant == "display", do: "tl-home__lede", else: "tl-page__lede"}>
          <%= render_slot(@lede) %>
        </p>
        <p :if={@meta != []} class="tl-page__meta"><%= render_slot(@meta) %></p>
        <%= render_slot(@inner_block) %>
      </div>
      <div :if={@actions != []} class="tl-page__actions"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc false
  attr(:crumbs, :list, required: true)

  defp breadcrumb_trail(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class="tl-transaction__breadcrumbs">
      <%= for crumb <- @crumbs do %>
        <%= if crumb[:href] do %>
          <a href={crumb[:href]} class="tl-link tl-link--back"><%= crumb[:label] %></a>
        <% else %>
          <span><%= crumb[:label] %></span>
        <% end %>
      <% end %>
    </nav>
    """
  end

  @doc false
  # De-emphasized, accessible pager over the EXISTING keyset engine (NAV-02 / D-16/17/18).
  # Infinite scroll stays the primary interaction; this gives keyboard/SR users explicit
  # "Older"/"Newer" (time-axis) controls plus an honest end-of-stream signal. No engine
  # change — the controls emit the host page's existing next-page/prev-page events.
  #
  # Contract (locked by pager_test.exs):
  #   * hide-at-zero (D-16): renders NOTHING when match_count == 0 (no tl-pager markup).
  #   * disable-not-hide (D-18): a boundary control stays in the DOM but `disabled`,
  #     never dropped (a Newer/Older control is only omitted when its event is nil,
  #     e.g. Timeline is next-only).
  #   * range caption is a role="status" aria-live="polite" "Showing N of … matching
  #     changes" live region.
  #   * deep-total cap (D-17): match_count >= 10_001 renders "10,000+", never an exact
  #     deep total (mirrors timeline_live format_count/1).
  attr(:shown, :integer, required: true, doc: "Count currently rendered on the page")

  attr(:match_count, :any,
    default: nil,
    doc:
      "Total matching count (integer, capped at 10,000+). nil renders an honest count-free caption for surfaces (e.g. the actor sliding window) that have no cheap real total."
  )

  attr(:has_older, :boolean, default: false, doc: "Whether an older keyset page exists")
  attr(:has_newer, :boolean, default: false, doc: "Whether a newer keyset page exists")

  attr(:older_event, :string,
    default: "next-page",
    doc: "phx-click event for the Older control (older = further back in time = next page)"
  )

  attr(:newer_event, :any,
    default: "prev-page",
    doc: "phx-click event for the Newer control; nil omits the control entirely (next-only pages)"
  )

  attr(:label, :string,
    default: "Timeline pagination",
    doc:
      "aria-label for the pager <nav> landmark; callers on non-timeline surfaces (e.g. the actor page) should pass an accurate label."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def pager(assigns) do
    ~H"""
    <nav
      :if={is_nil(@match_count) or @match_count > 0}
      class={["tl-pager", @class]}
      aria-label={@label}
      {@rest}
    >
      <button
        :if={@newer_event}
        type="button"
        phx-click={@newer_event}
        disabled={!@has_newer}
        class="tl-button tl-button--secondary tl-button--compact tl-pager__control"
      >
        Newer
      </button>
      <span class="tl-pager__range" role="status" aria-live="polite">
        <%= if is_nil(@match_count) do %>
          Showing <%= @shown %> matching changes
        <% else %>
          Showing <%= @shown %> of <%= pager_total(@match_count) %> matching changes
        <% end %>
      </span>
      <button
        :if={@older_event}
        type="button"
        phx-click={@older_event}
        disabled={!@has_older}
        class="tl-button tl-button--secondary tl-button--compact tl-pager__control"
      >
        Older
      </button>
    </nav>
    """
  end

  # Honest range total: at/above the keyset cap (10_001) show "10,000+" (never an exact
  # deep total — mitigates T-175-09); below the cap show the exact integer with separators.
  defp pager_total(count) when is_integer(count) and count >= 10_001, do: "10,000+"

  defp pager_total(count) when is_integer(count) do
    count
    |> Integer.to_string()
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end

  @doc false
  attr(:class, :any, default: nil)

  attr(:status, :string,
    default: nil,
    values: [nil, "danger", "warning", "success", "info", "signal"]
  )

  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:rest, :global)

  def stat_tile(assigns) do
    ~H"""
    <div class={["tl-card--metric", @class]} data-status={@status} {@rest}>
      <div class="tl-card__metric-label"><%= @label %></div>
      <div class="tl-card__metric"><%= @value %></div>
    </div>
    """
  end

  @doc false
  # Forensic copy affordance (DATA-01, D-02/D-06/D-07). The single call-site API that
  # retires the ad-hoc inline copy wirings: renders the truncated value while binding
  # the EXACT complete value to data-tl-copy on BOTH the <code> and the gated copy
  # button — never .title, never .visible. When the delegated copy script is disabled
  # (CSP-strict), the <code> renders the full value for zero-JS select-all.
  attr(:value, :any, required: true)

  attr(:kind, :string,
    default: nil,
    doc: "uuid|correlation|arn|actor|hash|path|email|url|timestamp — drives per-kind truncation"
  )

  attr(:copy_label, :string, required: true, doc: "aria-label specificity (D-07, no default)")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def ref(assigns) do
    kind = Presentation.kind_from_string(assigns.kind)
    r = Presentation.ref(assigns.value, kind: kind)
    assigns = assign(assigns, :r, r)

    ~H"""
    <span class={["tl-ref", @class]} {@rest}>
      <code class="tl-secondary-ref" title={@r.full} data-tl-copy={@r.full}><%= if Script.enabled?(), do: @r.visible, else: @r.full %></code>
      <button
        :if={Script.enabled?()}
        type="button"
        class="tl-copy tl-button tl-button--compact tl-button--secondary"
        data-tl-copy={@r.full}
        aria-label={@copy_label}
      >
        <Icon.icon name={:copy} class="tl-button__icon" />
        Copy
      </button>
    </span>
    """
  end

  @doc false
  # Single-record key/value display (D-08). Lifts the canonical tl-kv <dl> body; the
  # :item slot carries a REQUIRED key attr so callers drop a ref/1 or value span inside
  # the <dd> (path of least resistance for "single record -> <dl>").
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :item, required: true do
    attr(:key, :string, required: true)
  end

  def kv(assigns) do
    ~H"""
    <dl class={["tl-kv", @class]} {@rest}>
      <div :for={item <- @item} class="tl-kv__row">
        <dt class="tl-kv__key"><%= item.key %></dt>
        <dd class="tl-kv__value"><%= render_slot(item) %></dd>
      </div>
    </dl>
    """
  end

  @doc false
  # Responsive data table (D-08/D-09). The :col slot's required label feeds BOTH the
  # <th> AND every <td data-label> from one source (structurally guarantees mobile
  # labels match the header). Supports `rows` OR `stream` (truthy -> phx-update="stream"
  # on <tbody>); row_id sets <tr id=...>; row_status emits the data-status stripe (zero
  # new CSS). NO ARIA role="table"/"row"/"cell" (D-09) — the responsive layout is the
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
  attr(:icon, :atom, default: nil, doc: "Distinct glyph shape (no color alone, D-16)")

  attr(:focus_heading, :boolean,
    default: false,
    doc: "D-15 focus rescue: render the heading as a tabindex=-1 target and move focus on mount"
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
  # Thin variant="error" wrapper (D-15): role=alert, distinct alert glyph, and a
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
  # Loading state (D-13): a structurally distinct named sibling (NOT an empty_state
  # variant). role=status + aria-busy so SR users hear progress; renders the spinner
  # plus a text node that callers may override. Must always resolve to a terminal state.
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def loading_state(assigns) do
    ~H"""
    <div class={["tl-empty", "tl-empty--loading", @class]} role="status" aria-busy="true" {@rest}>
      <.spinner class="tl-empty__spinner" />
      <p class="tl-empty__body">
        <%= if @inner_block != [], do: render_slot(@inner_block), else: "Loading audit changes…" %>
      </p>
    </div>
    """
  end

  @doc false
  # Stale banner (D-13/D-14): a role=status strip rendered ABOVE still-visible last-good
  # data — it PRECEDES, never replaces, and is NOT a clause in any async switch. Reuses
  # the tl-alert--warning shell with a refresh glyph and an as_of timestamp.
  attr(:as_of, :string, default: nil, doc: "Timestamp of the last known good data")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def stale_banner(assigns) do
    ~H"""
    <div class={["tl-alert", "tl-alert--warning", @class]} role="status" {@rest}>
      <Icon.icon name={:refresh} class="tl-alert__icon" />
      Couldn't refresh — showing last known data from <%= @as_of %>. Retry.
    </div>
    """
  end

  @doc false
  # Typed-reason data-state dispatcher (DATA-03, D-13..D-16). Preserves the server's
  # typed reason all the way to the view and maps it to a DISTINCT role + icon SHAPE +
  # heading — the three load-bearing forensic distinctions (permission ≠ no-data ≠
  # unavailable) never collapse to a generic "something went wrong". Each unavailable
  # sub-case states it is NOT a permissions issue.
  attr(:reason, :atom, required: true)
  attr(:as_of, :string, default: nil, doc: "Timestamp for the pruned (retention) sub-case")
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
      <:title>No changes match these filters</:title>
      Clear the filter or widen the time range.
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
      <:title>You don't have access to this audit data</:title>
      This data exists — your account needs <code>audit:read</code>.
    </.empty_state>
    """
  end

  def data_state(%{reason: :source_down} = assigns) do
    ~H"""
    <.empty_state variant="unavailable" role="alert" icon={:cloud_off} class={@class} {@rest}>
      <:title>Audit data is temporarily unavailable</:title>
      This is not a permissions issue. Retry shortly.
    </.empty_state>
    """
  end

  def data_state(%{reason: :redacted} = assigns) do
    ~H"""
    <.empty_state variant="unavailable" role="status" icon={:eye_off} class={@class} {@rest}>
      <:title>This value is withheld by policy</:title>
      This is not a permissions issue. The record exists.
    </.empty_state>
    """
  end

  def data_state(%{reason: :pruned} = assigns) do
    ~H"""
    <.empty_state variant="unavailable" role="status" icon={:archive} class={@class} {@rest}>
      <:title>Removed under retention<%= if @as_of, do: " on #{@as_of}" %></:title>
      This is not a permissions issue. It was pruned by policy.
    </.empty_state>
    """
  end

  def data_state(assigns) do
    ~H"""
    <.error_state class={@class} {@rest}>
      <:title>Could not load this timeline</:title>
      Retry, then check logs.
    </.error_state>
    """
  end

  @doc false
  # Filter/search/sort toolbar (D-06 / RESEARCH Pitfall 6). A `cluster`-style row that
  # carries the cross-child DISABLED coordination: when the data region is loading or
  # in a hard error, the page derives `disabled` from the SAME state assign
  # (`state in [:loading, :error]`, D-06) and passes it here. The container then gets
  # `aria-disabled` + the `is-disabled` class (pointer-events:none + dimming — affordance
  # only). The page MUST ALSO set the HTML `disabled` attribute on the actual controls
  # from that same assign: `pointer-events:none` alone leaves controls keyboard-focusable
  # and SR-activatable (Pitfall 6 — affordance is not enforcement).
  attr(:disabled, :boolean,
    default: false,
    doc: "true while the data region is loading or in a hard error (D-06)"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def toolbar(assigns) do
    ~H"""
    <div
      class={["tl-toolbar", "tl-cluster", @disabled && "is-disabled", @class]}
      role="search"
      aria-disabled={to_string(@disabled)}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc false
  # Detail-page header (D-03). Title + metadata kv + actions cluster, recurring on the
  # transaction / actor / row-history pages. Renders an <h2> (NOT <h1>) — page_header
  # owns the single <h1> per page (D-175-03). Composes the existing kv/1 + cluster
  # rather than re-rolling layout.
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :metadata, doc: "kv rows: <:metadata key=\"...\">value</:metadata>" do
    attr(:key, :string, required: true)
  end

  slot(:actions)

  def detail_header(assigns) do
    ~H"""
    <header class={["tl-detail-header", @class]} {@rest}>
      <div class="tl-detail-header__top">
        <h2 class="tl-detail-header__title"><%= @title %></h2>
        <.cluster :if={@actions != []} justify="end" class="tl-detail-header__actions">
          <%= render_slot(@actions) %>
        </.cluster>
      </div>
      <.kv :if={@metadata != []} class="tl-detail-header__meta">
        <:item :for={m <- @metadata} key={m.key}><%= render_slot(m) %></:item>
      </.kv>
    </header>
    """
  end

  @doc false
  # State-coordinating shell (D-03 / D-06 / D-06c). data_panel COMPOSES the existing
  # named state family (D-176-13) — it does NOT reinvent the taxonomy or the focus
  # logic. The page author still branches the typed server reason (D-06d); the shell
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
  #                       (D-176-16, ASVS V4). NEVER converted to a generic empty.
  #   * as_of present  -> stale_banner rendered ABOVE the region regardless of state
  #                       (coexists with :ok data; never replaces it, D-176-14). Stale
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
    doc: "stale timestamp; presence renders stale_banner ABOVE the region (D-176-14)"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:data, required: true, doc: "the data_table — only rendered in :ok")
  slot(:pager)

  def data_panel(assigns) do
    ~H"""
    <section class={["tl-data-panel", @class]} {@rest}>
      <.stale_banner :if={@as_of} as_of={@as_of} />
      <div class="tl-data-panel__region" data-state={@state}>
        <%= cond do %>
          <% @state == :ok -> %>
            <%= render_slot(@data) %>
          <% @state in [:permission, :unavailable] -> %>
            <.data_state reason={@reason} as_of={@as_of} />
          <% @state == :error -> %>
            <.error_state>
              <:title>Could not load this data</:title>
              Retry, then check logs.
            </.error_state>
          <% @state == :empty -> %>
            <.empty_state role="status">
              <:title>Nothing here yet</:title>
              No audit changes have been recorded.
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

  @doc false
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def code_block(assigns) do
    ~H"""
    <pre class={["tl-code", @class]} {@rest}><code><%= render_slot(@inner_block) %></code></pre>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def modal(assigns) do
    ~H"""
    <div
    id={@id}
    phx-mounted={@show && show_modal(@id)}
    phx-remove={hide_modal(@id)}
    class={["tl-modal-container", if(!@show, do: "hidden")]}
    {@rest}
    >
    <div id={"#{@id}-bg"} class="tl-modal-scrim" aria-hidden="true" />
    <div
      class="tl-modal-wrapper"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={"#{@id}-description"}
      role="dialog"
      aria-modal="true"
      tabindex="0"
    >
      <div
        id={"#{@id}-content"}
        class={["tl-modal", @class]}
        phx-click-away={JS.exec(@on_cancel, "phx-remove") |> hide_modal(@id)}
        phx-window-keydown={JS.exec(@on_cancel, "phx-remove") |> hide_modal(@id)}
        phx-key="escape"
      >
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    </div>
    """
  end

  @doc false
  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(
      to: "##{id}",
      transition: {"tl-fade-in", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-content",
      transition: {"tl-rise-in", "opacity-0 translate-y-4", "opacity-100 translate-y-0"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc false
  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-content",
      transition: {"tl-rise-out", "opacity-100 translate-y-0", "opacity-0 translate-y-4"}
    )
    |> JS.hide(
      to: "##{id}",
      transition: {"tl-fade-out", "opacity-100", "opacity-0"}
    )
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def drawer(assigns) do
    ~H"""
    <div
    id={@id}
    phx-mounted={@show && show_drawer(@id)}
    phx-remove={hide_drawer(@id)}
    class={["tl-drawer-container", if(!@show, do: "hidden")]}
    {@rest}
    >
    <div id={"#{@id}-bg"} class="tl-drawer-scrim" aria-hidden="true" />
    <div
      class="tl-drawer-wrapper"
      role="dialog"
      aria-modal="true"
      tabindex="0"
    >
      <div
        id={"#{@id}-content"}
        class={["tl-drawer", @class]}
        phx-click-away={JS.exec(@on_cancel, "phx-remove") |> hide_drawer(@id)}
        phx-window-keydown={JS.exec(@on_cancel, "phx-remove") |> hide_drawer(@id)}
        phx-key="escape"
      >
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    </div>
    """
  end

  @doc false
  def show_drawer(js \\ %JS{}, id) do
    js
    |> JS.show(
      to: "##{id}",
      transition: {"tl-fade-in", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-content",
      transition: {"tl-slide-in-right", "translate-x-full", "translate-x-0"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc false
  def hide_drawer(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-content",
      transition: {"tl-slide-out-right", "translate-x-0", "translate-x-full"}
    )
    |> JS.hide(
      to: "##{id}",
      transition: {"tl-fade-out", "opacity-100", "opacity-0"}
    )
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:kind, :string, default: "info", values: ~w(info success warning error))
  attr(:title, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def toast(assigns) do
    ~H"""
    <div
    id={@id}
    class={["tl-toast", "tl-toast--#{@kind}", @class]}
    role="alert"
    phx-click-away={hide_toast(@id)}
    phx-window-keydown={hide_toast(@id)}
    phx-key="escape"
    {@rest}
    >
    <div :if={@title} class="tl-toast__title"><%= @title %></div>
    <div class="tl-toast__body">
      <%= render_slot(@inner_block) %>
    </div>
    <button type="button" class="tl-toast__close" aria-label="Close" phx-click={hide_toast(@id)}>
      <span aria-hidden="true">&times;</span>
    </button>
    </div>
    """
  end

  @doc false
  def hide_toast(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}",
      transition: {"tl-fade-out", "opacity-100", "opacity-0"}
    )
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:trigger, required: true)
  slot(:inner_block, required: true)

  def tooltip(assigns) do
    ~H"""
    <div class={["tl-tooltip-wrapper", @class]} {@rest}>
      <div class="tl-tooltip-trigger" aria-describedby={@id}>
        <%= render_slot(@trigger) %>
      </div>
      <div id={@id} role="tooltip" class="tl-tooltip">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:trigger, required: true)
  slot(:inner_block, required: true)

  def popover(assigns) do
    ~H"""
    <div class={["relative", @class]} {@rest}>
      <button
        type="button"
        id={"#{@id}-trigger"}
        aria-expanded="false"
        aria-controls={@id}
        phx-click={JS.toggle(to: "##{@id}") |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-trigger")}
        phx-click-away={JS.hide(to: "##{@id}") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-trigger")}
      >
        <%= render_slot(@trigger) %>
      </button>
      <div id={@id} class="hidden absolute tl-popover" role="dialog" aria-labelledby={"#{@id}-trigger"}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:trigger, required: true)
  slot(:inner_block, required: true)

  def dropdown(assigns) do
    ~H"""
    <div class={["relative", @class]} {@rest}>
      <button
        type="button"
        id={"#{@id}-button"}
        aria-expanded="false"
        aria-haspopup="true"
        phx-click={JS.toggle(to: "##{@id}-menu") |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-button")}
        phx-click-away={JS.hide(to: "##{@id}-menu") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-button")}
      >
        <%= render_slot(@trigger) %>
      </button>
      <div id={"#{@id}-menu"} class="hidden absolute tl-shadow-popover" role="menu" aria-labelledby={"#{@id}-button"}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc false
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :tab, required: true do
    attr(:active, :boolean)
  end

  def tabs(assigns) do
    ~H"""
    <div class={["tl-tabs", @class]} role="tablist" {@rest}>
      <button :for={tab <- @tab} type="button" role="tab" aria-selected={if tab[:active], do: "true", else: "false"} class={["tl-tab", tab[:active] && "tl-tab--active"]}>
        <%= render_slot(tab) %>
      </button>
    </div>
    """
  end

  @doc false
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :segment, required: true do
    attr(:active, :boolean)
  end

  def segmented_control(assigns) do
    ~H"""
    <div class={["tl-segmented-control", @class]} role="group" {@rest}>
      <button :for={seg <- @segment} type="button" aria-pressed={if seg[:active], do: "true", else: "false"} class={["tl-segment", seg[:active] && "tl-segment--active"]}>
        <%= render_slot(seg) %>
      </button>
    </div>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def accordion(assigns) do
    ~H"""
    <div class={["tl-accordion", @class]} {@rest}>
      <h3 class="tl-accordion__header">
        <button
          type="button"
          id={"#{@id}-button"}
          aria-expanded="false"
          aria-controls={"#{@id}-content"}
          class="tl-accordion__trigger"
          phx-click={JS.toggle(to: "##{@id}-content") |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}-button")}
        >
          <%= @title %>
          <span class="tl-accordion__icon" aria-hidden="true"></span>
        </button>
      </h3>
      <div id={"#{@id}-content"} class="hidden tl-accordion__panel" aria-labelledby={"#{@id}-button"}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc false
  attr(:for, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class={["tl-label", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p id={@id} class={["tl-error", @class]} {@rest}>
      <svg class="tl-error-icon" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="10" />
        <line x1="12" y1="8" x2="12" y2="12" />
        <line x1="12" y1="16" x2="12.01" y2="16" />
      </svg>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def help(assigns) do
    ~H"""
    <p id={@id} class={["tl-help", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")
  attr(:class, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:checked, :boolean, default: false)
  attr(:rest, :global)

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign(assigns, :checked, assigns.value == true || assigns.value == "true")

    ~H"""
    <input
      type="checkbox"
      id={@id}
      name={@name}
      value="true"
      checked={@checked}
      class={["tl-checkbox", @class]}
      {@rest}
    />
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <select id={@id} name={@name} class={["tl-control", "tl-control--select", @class]} {@rest}>
      <option :for={{label, value} <- @options} value={value} selected={to_string(value) == to_string(@value)}><%= label %></option>
    </select>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <textarea id={@id} name={@name} class={["tl-control", "tl-control--textarea", @class]} {@rest}><%= @value %></textarea>
    """
  end

  def input(assigns) do
    ~H"""
    <input
      type={@type}
      id={@id}
      name={@name}
      value={@value}
      class={["tl-control", @class]}
      {@rest}
    />
    """
  end

  @doc false
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")
  attr(:label, :string, required: true)
  attr(:errors, :list, default: [])
  attr(:help_text, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:options, :list, default: [])

  attr(:rest, :global,
    include:
      ~w(autocomplete disabled readonly required placeholder phx-debounce step min max checked list maxlength)
  )

  def field(assigns) do
    assigns =
      assigns
      |> assign(:error_id, "#{assigns.id}-error")
      |> assign(:help_id, "#{assigns.id}-help")

    ~H"""
    <div class={["tl-field", @errors != [] && "tl-field--error", @class]}>
      <.label for={@id}><%= @label %></.label>
      
      <% aria_describedby = [
        @help_text && @help_id,
        @errors != [] && @error_id
      ] |> Enum.reject(&is_nil/1) |> Enum.join(" ") %>
      
      <.input
        id={@id}
        name={@name}
        value={@value}
        type={@type}
        options={@options}
        aria-describedby={if aria_describedby != "", do: aria_describedby, else: nil}
        {@rest}
      />
      
      <.error :for={msg <- @errors} id={@error_id}><%= msg %></.error>
      <.help :if={@help_text} id={@help_id}><%= @help_text %></.help>
    </div>
    """
  end

  @doc false
  # errors is a list of {field_id, message} tuples. Each message links to the
  # offending field's error id ("#\#{field_id}-error"). Renders nothing when empty.
  attr(:id, :string, required: true)
  attr(:errors, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:title)

  def error_summary(assigns) do
    ~H"""
    <div
      :if={@errors != []}
      id={@id}
      role="alert"
      aria-labelledby={"#{@id}-title"}
      class={["tl-error", "tl-error-summary", @class]}
      {@rest}
    >
      <h2 id={"#{@id}-title"} class="tl-error-summary__title">
        <%= if @title != [], do: render_slot(@title), else: "There is a problem" %>
      </h2>
      <ul class="tl-error-summary__list">
        <li :for={{field_id, message} <- @errors}>
          <a href={"##{field_id}-error"}><%= message %></a>
        </li>
      </ul>
    </div>
    """
  end

  @doc false
  attr(:legend, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def field_group(assigns) do
    ~H"""
    <fieldset class={["tl-filter-group", @class]} {@rest}>
      <legend class="tl-filter-group__legend"><%= @legend %></legend>
      <%= render_slot(@inner_block) %>
    </fieldset>
    """
  end

  @doc false
  # Native radio group: every option shares @name; the option whose value equals
  # @value is checked; each input has a distinct id and an associated <label>.
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def radio(assigns) do
    ~H"""
    <div class={["tl-radio-group", @class]} role="group" {@rest}>
      <div :for={{label, value} <- @options} class="tl-radio">
        <input
          type="radio"
          id={"#{@name}-#{value}"}
          name={@name}
          value={value}
          checked={to_string(value) == to_string(@value)}
          class="tl-radio__input"
        />
        <label for={"#{@name}-#{value}"} class="tl-radio__label"><%= label %></label>
      </div>
    </div>
    """
  end

  @doc false
  # Native checkbox styled as a switch. Submits without JS; role/aria-checked
  # carry switch semantics for assistive tech.
  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def switch(assigns) do
    assigns = assign(assigns, :checked, assigns.value == true || assigns.value == "true")

    ~H"""
    <input
      type="checkbox"
      role="switch"
      id={@id}
      name={@name}
      value="true"
      checked={@checked}
      aria-checked={if @checked, do: "true", else: "false"}
      class={["tl-checkbox", "tl-switch", @class]}
      {@rest}
    />
    """
  end

  @doc false
  # Combobox: a free-text input (role="combobox") paired with a hidden listbox.
  # Open/close is driven purely by Phoenix.LiveView.JS (ARIA state only, no data
  # fetch, no third-party JS runtime). With JS disabled the input still accepts
  # free text, so the control degrades gracefully and submits like any text field.
  attr(:id, :string, required: true)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def combobox(assigns) do
    ~H"""
    <div class={["tl-combobox", @class]} {@rest}>
      <input
        type="text"
        id={@id}
        name={@name}
        value={@value}
        role="combobox"
        aria-expanded="false"
        aria-controls={"#{@id}-listbox"}
        aria-autocomplete="list"
        autocomplete="off"
        class="tl-control"
        phx-click={
          JS.toggle(to: "##{@id}-listbox")
          |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{@id}")
        }
        phx-click-away={
          JS.hide(to: "##{@id}-listbox")
          |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}")
        }
      />
      <ul id={"#{@id}-listbox"} class="hidden tl-combobox__listbox" role="listbox" aria-label={@name}>
        <li :for={{label, value} <- @options} role="option" data-value={value} class="tl-combobox__option">
          <%= label %>
        </li>
      </ul>
    </div>
    """
  end
end
