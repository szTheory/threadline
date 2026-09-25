if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Threadline.OperatorSurface.UI.Display do
    @moduledoc false
    use Phoenix.Component
    alias Threadline.OperatorSurface.Components.Icon
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Script

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
    # Forensic copy affordance. The single call-site API that
    # retires the ad-hoc inline copy wirings: renders the truncated value while binding
    # the EXACT complete value to data-tl-copy on BOTH the <code> and the gated copy
    # button — never .title, never .visible. When the delegated copy script is disabled
    # (CSP-strict), the <code> renders the full value for zero-JS select-all.
    attr(:value, :any, required: true)

    attr(:kind, :string,
      default: nil,
      doc: "uuid|correlation|arn|actor|hash|path|email|url|timestamp — drives per-kind truncation"
    )

    attr(:copy_label, :string, required: true, doc: "Specific aria-label; no default")
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
    # Single-record key/value display. Lifts the canonical tl-kv <dl> body; the
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
    attr(:class, :any, default: nil)
    attr(:rest, :global)
    slot(:inner_block, required: true)

    def code_block(assigns) do
      ~H"""
      <pre class={["tl-code", @class]} {@rest}><code><%= render_slot(@inner_block) %></code></pre>
      """
    end
  end
end
