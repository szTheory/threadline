# Phase 184: Timeline investigation flow - Pattern Map

**Mapped:** 2026-06-28
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/live/timeline_live.ex` | liveview/controller | request-response, event-driven, streaming | `lib/threadline/operator_surface/live/timeline_live.ex` | exact |
| `lib/threadline/operator_surface/ui.ex` | component | request-response, transform | `lib/threadline/operator_surface/ui.ex` | exact |
| `lib/threadline/operator_surface/presentation.ex` | utility | transform | `lib/threadline/operator_surface/presentation.ex` | exact |
| `lib/threadline/operator_surface/style.ex` | config/style | responsive transform, event-driven states | `lib/threadline/operator_surface/style.ex` | exact |
| `lib/threadline/operator_surface/exports/filter_params.ex` | utility | request-response, transform | `lib/threadline/operator_surface/exports/filter_params.ex` | exact |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | test | request-response, event-driven | `test/threadline/operator_surface/live/timeline_live_test.exs` | exact |
| `test/threadline/operator_surface/exports/filter_params_test.exs` | test | transform | `test/threadline/operator_surface/exports/filter_params_test.exs` | exact |
| `test/threadline/operator_surface/presentation_test.exs` | test | transform | `test/threadline/operator_surface/presentation_test.exs` | exact |
| `test/threadline/operator_surface/copy_contract_test.exs` | test | transform, request-response | `test/threadline/operator_surface/copy_contract_test.exs` | exact |
| `test/threadline/operator_surface/style_contract_test.exs` | test | source contract, transform | `test/threadline/operator_surface/style_contract_test.exs` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | test | browser request-response | `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` | test | browser event-driven, accessibility | `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | test | browser request-response, handoff | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` | test | browser request-response, mobile | `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | test | browser event-driven, motion | `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` (possible new narrow spec) | test | browser request-response, mobile/desktop proof | `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | role-match |

## Pattern Assignments

### `lib/threadline/operator_surface/live/timeline_live.ex` (liveview/controller, request-response + event-driven + streaming)

**Analog:** `lib/threadline/operator_surface/live/timeline_live.ex`

**Imports and optional-dependency pattern** (lines 1-13):

```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView
    import Ecto.Query

    alias Phoenix.LiveView.JS
    alias Threadline.Export
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.Query
    alias Threadline.StorageSchema
    alias Threadline.OperatorSurface.UI
```

**Mount assigns and stream setup** (lines 22-75):

```elixir
def mount(_params, _session, socket) do
  repo =
    socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

  scope = socket.assigns[:threadline_scope]
  actor_ref = socket.assigns[:threadline_actor_ref]

  saved_views =
    if actor_ref do
      repo.all(
        from(v in Threadline.Governance.SavedView,
          where: v.actor_ref == ^actor_ref,
          order_by: [desc: v.inserted_at]
        ),
        StorageSchema.repo_opts()
      )
    else
      []
    end

  socket =
    socket
    |> stream_configure(:changes, dom_id: fn change -> "change-#{change.id}" end)
    |> stream(:changes, [])
    |> assign(:repo, repo)
    |> assign(:scope, scope)
    |> assign(:saved_views, saved_views)
```

**URL-as-state and parser boundary** (lines 82-125, 140-188):

```elixir
def handle_params(params, uri, socket) do
  uri_parsed = URI.parse(uri)
  timeline_path = uri_parsed.path
  base_path = (timeline_path || "") |> String.replace_suffix("/timeline", "")

  socket =
    socket
    |> assign(:base_path, base_path)
    |> assign(:timeline_path, timeline_path)

  if params == %{} do
    from = DateTime.utc_now() |> DateTime.add(-@default_window_hours * 3600, :second)
    to = DateTime.utc_now()

    query_string =
      URI.encode_query([
        {"from", DateTime.to_iso8601(from) |> String.slice(0..15)},
        {"to", DateTime.to_iso8601(to) |> String.slice(0..15)}
      ])

    {:noreply, push_patch(socket, to: "#{timeline_path}?#{query_string}", replace: true)}
  else
    socket = assign(socket, :filters_raw, FilterParams.filters_raw_from_params(params))

    case FilterParams.parse(params) do
      {:error, message} ->
        ...

      {:ok, filters} ->
        case safe_validate(filters) do
          :ok ->
            count_task = Task.async(fn ->
              Export.count_matching(filters, count_opts(socket, 10_001))
            end)

            page_task = Task.async(fn ->
              Query.timeline_page(filters, scope_aware_opts(socket))
            end)

            {:ok, %{count: count}} = Task.await(count_task, 8_000)
            page = page_task |> Task.await(8_000) |> preload_visible_context(socket.assigns.repo)

            socket =
              socket
              |> assign(:filters, filters)
              |> assign(:form_error, nil)
              |> assign(:match_count, count)
              |> assign(:shown_count, length(page.entries))
              |> stream(:changes, page.entries, reset: true)
              |> assign(:cursor, page.next_cursor)

            {:noreply, socket}
        end
    end
  end
end
```

**Batch Apply and saved-view patch pattern** (lines 221-247):

```elixir
def handle_event("apply-view", %{"id" => id}, socket) do
  case Enum.find(socket.assigns.saved_views, &(&1.id == id)) do
    nil ->
      {:noreply, socket}

    view ->
      query = build_canonical_query(view.filters)
      {:noreply, push_patch(socket, to: "#{socket.assigns.timeline_path}?#{query}")}
  end
end

def handle_event("apply", %{"filter" => raw}, socket) do
  query = build_canonical_query(raw)
  {:noreply, push_patch(socket, to: "#{socket.assigns.timeline_path}?#{query}")}
end
```

**Background export event boundary** (lines 253-300):

```elixir
def handle_event("request_background_export", _params, %{assigns: %{threadline_exports_enabled: true}} = socket) do
  repo = scope_aware_opts(socket)[:repo] || default_repo()

  job = %Threadline.Governance.ExportJob{
    status: "pending",
    query_params: Map.new(socket.assigns.filters, fn {k, v} -> {to_string(k), v} end),
    actor_ref: socket.assigns[:threadline_actor_ref]
  }

  job = repo.insert!(job, StorageSchema.repo_opts())
  adapter = Application.get_env(:threadline, :export_queue_adapter, Threadline.ExportQueue.TaskAdapter)

  case adapter.enqueue(job.id) do
    :ok ->
      {:noreply,
       socket
       |> put_flash(:info, "Background export requested. View progress on the Export Status page.")
       |> push_navigate(to: "#{socket.assigns.base_path}/exports")}

    {:error, reason} ->
      error_message = background_export_error_message(reason)
      ...
      {:noreply, put_flash(socket, :error, error_message)}
  end
end
```

**Row-first scan and pivot pattern** (lines 384-421):

```elixir
<section class="tl-change-list" id="timeline-rows" phx-update="stream"
         phx-viewport-bottom={@cursor && "next-page"}
         data-testid="operator-timeline">
  <div :for={{dom_id, change} <- @streams.changes} id={dom_id} class={["tl-change", op_row_modifier(change.op)]} data-testid="timeline-row">
    <div class="tl-change__summary">
      <div class="tl-change__meta">
        <span class={["tl-change__op", Presentation.operation_modifier(change.op)]}><%= Presentation.operation_label(change.op) %></span>
        <span class="tl-change__table tl-secondary-ref" title={table_ref(change).title}>
          <%= table_ref(change).visible %>
        </span>
        <time class="tl-change__time" datetime={Presentation.exact_time(change.captured_at)} title={Presentation.exact_time(change.captured_at)}>
          <%= Presentation.human_time(change.captured_at) %>
        </time>
      </div>
      <div class="tl-meta">
        <span>
          Actor
          <%= if path = actor_path(@base_path, change) do %>
            <a href={path} class="tl-link tl-link--deep"><code><%= actor_label(change) %></code></a>
          <% else %>
            <code><%= actor_label(change) %></code>
          <% end %>
        </span>
        <span :if={correlation_id(change)}>
          Correlation
          <UI.ref value={correlation_id(change)} kind="correlation" copy_label="Copy correlation id" />
          <a href={correlation_path(@timeline_path, correlation_id(change))} class="tl-link tl-link--deep" title="View correlated changes in Timeline">
            <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
            Timeline
          </a>
        </span>
      </div>
      <div class="tl-change__actions">
        <a href={"#{@base_path}/transactions/#{change.transaction_id}"} class="tl-button tl-button--compact tl-button--secondary" data-testid="transaction-link">
          <Threadline.OperatorSurface.Components.Icon.icon name={:arrow_right} class="tl-button__icon" />
          Open transaction
        </a>
      </div>
```

**Command surface pattern** (lines 475-580):

```elixir
<section class="tl-toolbar tl-timeline-command" aria-labelledby="timeline-command-title">
  <div class="tl-timeline-command__summary">
    <div class="tl-timeline-command__heading">
      <h1 id="timeline-command-title" class="tl-timeline-command__title">
        Investigate audit activity
      </h1>
      <p class="tl-timeline-command__lede">
        Start with a time window, table, or correlation id. Add actor and schema filters only when the investigation needs them.
      </p>
    </div>

    <div class="tl-timeline-command__facts" aria-label="Current investigation summary">
      ...
    </div>
  </div>

  <form id="timeline-filters" phx-submit="apply" role="search" class="tl-toolbar__form">
    <UI.field_group legend="Search" class="tl-filter-group--primary">
      <div class="tl-filter-grid tl-filter-grid--primary">
        <UI.field id="filter-from" type="datetime-local" name="filter[from]" label="From" value={@filters_raw["from"] || ""} />
        <UI.field id="filter-to" type="datetime-local" name="filter[to]" label="To" value={@filters_raw["to"] || ""} />
        <UI.field id="filter-table" type="text" name="filter[table]" label="Table" value={@filters_raw["table"] || ""} list="audited-tables" />
        <UI.field id="filter-correlation-id" type="text" name="filter[correlation_id]" label="Correlation id" value={@filters_raw["correlation_id"] || ""} maxlength="256" />
        <div class="tl-toolbar__actions tl-filter-actions">
          <button type="button" aria-haspopup="dialog" aria-controls="timeline-filters-drawer" phx-click={JS.push_focus() |> UI.show_drawer("timeline-filters-drawer")}>
            Filters
          </button>
          <.link patch={@timeline_path} class="tl-button tl-button--ghost">Reset to last 24h</.link>
          <button type="submit" class="tl-button tl-button--primary">Apply</button>
        </div>
      </div>
    </UI.field_group>
  </form>
```

**Drawer utility and handoff pattern** (lines 610-803):

```elixir
<UI.drawer
  id="timeline-filters-drawer"
  class="tl-timeline-drawer"
  phx-window-keydown={UI.hide_drawer("timeline-filters-drawer")}
  phx-key="Escape"
>
  <div class="tl-timeline-drawer__header">
    <h2 id="timeline-filters-drawer-title" class="tl-modal__title">
      Filters and handoff
    </h2>
    <button type="button" phx-click={UI.hide_drawer("timeline-filters-drawer")} data-tl-initial-focus>
      Close
    </button>
  </div>

  <section class="tl-timeline-drawer__section" aria-labelledby="timeline-advanced-filters-title">
    <div class="tl-filter-grid tl-filter-grid--advanced">
      <UI.field id="filter-table-schema" name="filter[table_schema]" label="Schema" form="timeline-filters" />
      <UI.field id="filter-actor-kind" type="select" name="filter[actor_kind]" label="Actor kind" form="timeline-filters" />
      <UI.field id="filter-actor-id" name="filter[actor_id]" label="Actor id" form="timeline-filters" />
    </div>
  </section>

  <section :if={@exports_enabled} class="tl-utility-group" aria-label="Export actions">
    <button phx-click="request_background_export" type="button" class="tl-button tl-button--quiet-primary">Queue export</button>
    <.link navigate={"#{@base_path}/exports?#{@filter_query}"} data-earned-flow="EF3">Carry to Exports</.link>
    <.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"} download>CSV</.link>
    <.link href={"#{@base_path}/exports/changes.json?#{@filter_query}"} download>JSON</.link>
    <.link href={"#{@base_path}/exports/changes.ndjson?#{@filter_query}"} download>NDJSON</.link>
  </section>

  <section :if={@actor_ref} class="tl-utility-group tl-utility-group--views" aria-label="Saved views">
    <form id="save-view-form" phx-submit="save-view" class="tl-saved-view-form">
      ...
    </form>
  </section>
</UI.drawer>
```

**State and copy pattern** (lines 360-380, 433-447, 1031-1099):

```elixir
<%= if @form_error do %>
  <div class="tl-alert tl-alert--error" role="alert">
    <%= invalid_filter_message(@form_error) %>
  </div>
<% end %>

<%= if Enum.empty?(@streams.changes.inserts) and @unknown_table_attempted do %>
  <div class="tl-alert tl-alert--info" role="status">
    <%= unknown_table_message(@filters_raw["table"], @audited_tables) %>
  </div>
<% end %>

<UI.empty_state :if={@cursor == nil and Enum.empty?(@streams.changes.inserts)} role="status" icon={timeline_empty_icon(@filters_raw)}>
  <:title><%= empty_title(@future_window_empty) %></:title>
  <%= empty_body(@future_window_empty) %>
  <:actions>
    <.link patch={@timeline_path} class="tl-button tl-button--secondary">Clear filters</.link>
  </:actions>
</UI.empty_state>

defp invalid_filter_message(message) do
  target = invalid_filter_target(message)
  "Timeline filters could not be applied. Fix the #{target} filter, then apply filters again. #{message}"
end
```

### `lib/threadline/operator_surface/ui.ex` (component, request-response + transform)

**Analog:** `lib/threadline/operator_surface/ui.ex`

**Field and field group pattern** (lines 1497-1574):

```elixir
def field(assigns) do
  assigns =
    assigns
    |> assign(:error_id, "#{assigns.id}-error")
    |> assign(:help_id, "#{assigns.id}-help")

  ~H"""
  <div class={["tl-field", @errors != [] && "tl-field--error", @class]}>
    <.label for={@id}><%= @label %></.label>
    <% aria_describedby = [@help_text && @help_id, @errors != [] && @error_id] |> Enum.reject(&is_nil/1) |> Enum.join(" ") %>
    <.input id={@id} name={@name} value={@value} type={@type} options={@options} aria-describedby={if aria_describedby != "", do: aria_describedby, else: nil} {@rest} />
    <.error :for={msg <- @errors} id={@error_id}><%= msg %></.error>
    <.help :if={@help_text} id={@help_id}><%= @help_text %></.help>
  </div>
  """
end

def field_group(assigns) do
  ~H"""
  <fieldset class={["tl-filter-group", @class]} {@rest}>
    <legend class="tl-filter-group__legend"><%= @legend %></legend>
    <%= render_slot(@inner_block) %>
  </fieldset>
  """
end
```

**Copy/ref pattern** (lines 389-425):

```elixir
# ... renders the truncated value while binding the EXACT complete value to data-tl-copy
attr(:value, :any, required: true)
attr(:kind, :string, default: nil)
attr(:copy_label, :string, required: true, doc: "aria-label specificity (D-07, no default)")

def ref(assigns) do
  kind = Presentation.kind_from_string(assigns.kind)
  r = Presentation.ref(assigns.value, kind: kind)
  assigns = assign(assigns, :r, r)

  ~H"""
  <span class={["tl-ref", @class]} {@rest}>
    <code class="tl-secondary-ref" title={@r.full} data-tl-copy={@r.full}><%= if Script.enabled?(), do: @r.visible, else: @r.full %></code>
    <button :if={Script.enabled?()} type="button" class="tl-copy tl-button tl-button--compact tl-button--secondary" data-tl-copy={@r.full} aria-label={@copy_label}>
      <Icon.icon name={:copy} class="tl-button__icon" />
      Copy
    </button>
  </span>
  """
end
```

**Pager pattern** (lines 321-354):

```elixir
<nav :if={is_nil(@match_count) or @match_count > 0} class={["tl-pager", @class]} aria-label={@label} {@rest}>
  <button :if={@newer_event} type="button" phx-click={@newer_event} disabled={!@has_newer} class="tl-button tl-button--secondary tl-button--compact tl-pager__control">
    Newer
  </button>
  <span class="tl-pager__range" role="status" aria-live="polite">
    <%= if is_nil(@match_count) do %>
      Showing <%= @shown %> matching changes
    <% else %>
      Showing <%= @shown %> of <%= pager_total(@match_count) %> matching changes
    <% end %>
  </span>
  <button :if={@older_event} type="button" phx-click={@older_event} disabled={!@has_older} class="tl-button tl-button--secondary tl-button--compact tl-pager__control">
    Older
  </button>
</nav>
```

**Drawer focus/escape/return pattern** (lines 954-1024):

```elixir
def drawer(assigns) do
  ~H"""
  <div id={@id} phx-mounted={@show && show_drawer(@id)} phx-remove={hide_drawer(@id)} class={["tl-drawer-container", if(!@show, do: "hidden")]} {@rest}>
    <div id={"#{@id}-bg"} class="tl-drawer-scrim" aria-hidden="true" phx-click={JS.exec(@on_cancel, "phx-remove") |> hide_drawer(@id)} />
    <div class="tl-drawer-wrapper" role="dialog" aria-modal="true" aria-labelledby={"#{@id}-title"} aria-describedby={"#{@id}-description"} tabindex="0">
      <div id={"#{@id}-content"} class={["tl-drawer", @class]} phx-click-away={JS.exec(@on_cancel, "phx-remove") |> hide_drawer(@id)} phx-window-keydown={JS.exec(@on_cancel, "phx-remove") |> hide_drawer(@id)} phx-key="escape">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
  </div>
  """
end

def show_drawer(js \\ %JS{}, id) do
  js
  |> JS.show(to: "##{id}", time: 180, transition: {"tl-fade-in", "opacity-0", "opacity-100"})
  |> JS.show(to: "##{id}-content", time: 180, transition: {"tl-slide-in-right", "translate-x-full", "translate-x-0"})
  |> JS.add_class("overflow-hidden", to: "body")
  |> JS.focus_first(to: "##{id}-content")
  |> JS.focus(to: "##{id} [data-tl-initial-focus]")
end
```

**State primitives** (lines 519-607):

```elixir
def empty_state(assigns) do
  ~H"""
  <div class={["tl-empty", @variant && "tl-empty--#{@variant}", @class]} role={@role} {@rest}>
    <Icon.icon :if={@icon} name={@icon} class="tl-empty__icon" />
    <h3 :if={@title != []} id={@resolved_heading_id} class="tl-empty__title" tabindex={@focus_heading && "-1"} phx-mounted={@focus_heading && JS.focus(to: "##{@resolved_heading_id}")}>
      <%= render_slot(@title) %>
    </h3>
    <div class="tl-empty__body"><%= render_slot(@inner_block) %></div>
    <div :if={@actions != []} class="tl-empty__actions"><%= render_slot(@actions) %></div>
  </div>
  """
end

def loading_state(assigns) do
  ~H"""
  <div class={["tl-empty", "tl-empty--loading", @class]} role="status" aria-busy="true" {@rest}>
    <.spinner class="tl-empty__spinner" />
    <p class="tl-empty__body"><%= if @inner_block != [], do: render_slot(@inner_block), else: "Loading audit changes..." %></p>
  </div>
  """
end

def stale_banner(assigns) do
  ~H"""
  <div class={["tl-alert", "tl-alert--warning", @class]} role="status" {@rest}>
    <Icon.icon name={:refresh} class="tl-alert__icon" />
    Could not refresh - showing last known <%= @object_label %> from <%= @as_of || "the last successful refresh" %>. Retry.
  </div>
  """
end
```

### `lib/threadline/operator_surface/exports/filter_params.ex` (utility, request-response + transform)

**Analog:** `lib/threadline/operator_surface/exports/filter_params.ex`

**Single parser and atom-safety contract** (lines 1-30, 45-53):

```elixir
defmodule Threadline.OperatorSurface.Exports.FilterParams do
  @moduledoc """
  Parses a string-keyed URL params map into a keyword list ready for
  `Threadline.Query.validate_timeline_filters!/1`.

  Used by both `Threadline.OperatorSurface.Live.TimelineLive` (LV-side) and
  `Threadline.OperatorSurface.Controllers.ExportController` (HTTP-side) so
  the two surfaces share one parser...

  ## Allowed URL keys

      from, to, table_schema, table, actor_kind, actor_id, correlation_id

  ## Atom safety

  `actor_kind` is converted to an atom via `String.to_existing_atom/1` - never
  via the unsafe variant that creates fresh atoms from arbitrary strings.
  """

  @filter_key_atoms %{
    "from" => :from,
    "to" => :to,
    "table_schema" => :table_schema,
    "table" => :table,
    "actor_kind" => :actor_kind,
    "actor_id" => :actor_id,
    "correlation_id" => :correlation_id
  }
```

**Parse, raw hydration, and canonical query pattern** (lines 64-114):

```elixir
def parse(params) when is_map(params) do
  with normalized <- normalize_params(params),
       {:ok, with_datetimes} <- parse_datetimes(normalized),
       {:ok, with_actor_ref} <- collapse_actor_ref(with_datetimes) do
    {:ok, with_actor_ref}
  end
end

def filters_raw_from_params(params) when is_map(params) do
  raw = %{
    "from" => params["from"] || "",
    "to" => params["to"] || "",
    "table_schema" => params["table_schema"] || "",
    "table" => params["table"] || "",
    "actor_kind" => params["actor_kind"] || "",
    "actor_id" => params["actor_id"] || "",
    "correlation_id" => params["correlation_id"] || ""
  }

  case raw["actor_kind"] do
    "anonymous" -> Map.put(raw, "actor_id", "")
    _ -> raw
  end
end

@canonical_key_order ~w(from to table_schema table actor_kind actor_id correlation_id)

def canonical_query(%{} = raw) do
  raw
  |> normalize_anonymous()
  |> Enum.filter(fn {k, v} -> k in @canonical_key_order and is_binary(v) and v != "" end)
  |> Enum.sort_by(fn {k, _v} -> Enum.find_index(@canonical_key_order, &(&1 == k)) end)
  |> URI.encode_query()
end
```

**Actor collapse and safe atom conversion** (lines 170-218):

```elixir
defp collapse_actor_ref(filters) do
  actor_kind = Keyword.get(filters, :actor_kind)
  actor_id = Keyword.get(filters, :actor_id)

  filters_without_actor_params =
    filters
    |> Keyword.delete(:actor_kind)
    |> Keyword.delete(:actor_id)

  cond do
    actor_kind == "anonymous" ->
      actor_ref = %ActorRef{type: :anonymous, id: nil}
      {:ok, Keyword.put(filters_without_actor_params, :actor_ref, actor_ref)}

    is_binary(actor_kind) and actor_kind != "" and is_binary(actor_id) and actor_id != "" ->
      case safe_actor_kind(actor_kind) do
        {:ok, kind_atom} ->
          case ActorRef.new(kind_atom, actor_id) do
            {:ok, actor_ref} -> {:ok, Keyword.put(filters_without_actor_params, :actor_ref, actor_ref)}
            {:error, :unknown_actor_type} -> {:error, "unknown actor kind: " <> inspect(actor_kind)}
            {:error, :missing_actor_id} -> {:error, "actor id is required for non-anonymous actors"}
          end
        {:error, :unknown_actor_type} ->
          {:error, "unknown actor kind: " <> inspect(actor_kind)}
      end
    true ->
      {:ok, filters_without_actor_params}
  end
end

defp safe_actor_kind(kind) when is_binary(kind) do
  try do
    {:ok, String.to_existing_atom(kind)}
  rescue
    ArgumentError -> {:error, :unknown_actor_type}
  end
end
```

### `lib/threadline/operator_surface/presentation.ex` (utility, transform)

**Analog:** `lib/threadline/operator_surface/presentation.ex`

**Time and exact timestamp pattern** (lines 6-31):

```elixir
def human_time(value, opts \\ [])
def human_time(nil, opts), do: Keyword.get(opts, :empty, "Not recorded")

def human_time(%DateTime{} = dt, opts) do
  now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
  dt = DateTime.shift_zone!(dt, "Etc/UTC")
  ...
  "#{date_label}, #{clock(dt)} UTC"
end

def exact_time(nil), do: ""
def exact_time(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
```

**Full-value ref and truncation pattern** (lines 58-130):

```elixir
def truncate_middle(value, max_length \\ 34, opts \\ []) do
  value = to_string(value || "")

  if String.length(value) <= max_length do
    value
  else
    default_keep = max(div(max_length - 3, 2), 4)
    tail_min = Keyword.get(opts, :tail_min)
    tail = if tail_min, do: max(default_keep, tail_min), else: default_keep
    head = default_keep
    String.slice(value, 0, head) <> "..." <> String.slice(value, -tail, tail)
  end
end

@ref_kinds [:uuid, :correlation, :arn, :actor, :hash, :path, :email, :url, :timestamp]

def ref(value, opts \\ []) do
  full = secondary_ref_value(value)

  %{
    visible: truncate_for(full, opts),
    title: full,
    full: full
  }
end
```

**Operation and export-summary pattern** (lines 232-276, 601-607):

```elixir
def operation_modifier(operation) do
  case normalize_operation(operation) do
    "insert" -> "tl-change__op--insert"
    "update" -> "tl-change__op--update"
    "delete" -> "tl-change__op--delete"
    _ -> ""
  end
end

def operation_label(operation) do
  case normalize_operation(operation) do
    nil -> "UNKNOWN"
    "" -> "UNKNOWN"
    operation -> String.upcase(operation)
  end
end

def query_pairs(params) when is_map(params) do
  params
  |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
  |> Enum.reject(fn {_key, value} -> value == "" end)
  |> Enum.sort_by(fn {key, _value} -> filter_rank(key) end)
end

defp filter_rank("table"), do: {0, "table"}
defp filter_rank("correlation_id"), do: {1, "correlation_id"}
defp filter_rank("actor_kind"), do: {2, "actor_kind"}
defp filter_rank("actor_id"), do: {3, "actor_id"}
defp filter_rank("from"), do: {4, "from"}
defp filter_rank("to"), do: {5, "to"}
```

### `lib/threadline/operator_surface/style.ex` (config/style, responsive transform)

**Analog:** `lib/threadline/operator_surface/style.ex`

**Timeline command and filter grid base pattern** (lines 1116-1239, 1260-1325):

```css
.tl-timeline-command {
  gap: var(--tl-space-2);
  margin-bottom: var(--tl-space-4);
}

.tl-timeline-command__summary {
  display: grid;
  gap: var(--tl-space-2);
  align-items: start;
}

.tl-timeline-command__facts {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--tl-space-2);
  min-width: 0;
}

.tl-filter-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--tl-space-3);
  align-items: start;
  min-width: 0;
}

.tl-toolbar__control,
.tl-control {
  min-height: var(--tl-control-height);
  padding: var(--tl-space-2) var(--tl-space-3);
  border: 1px solid var(--tl-color-border-strong);
  border-radius: var(--tl-radius-md);
  background: var(--tl-color-surface-raised);
  color: var(--tl-color-text);
}

.tl-timeline-command .tl-filter-actions {
  padding-top: 0;
}
```

**Drawer and utility layout pattern** (lines 1412-1458, 3438-3488):

```css
.tl-timeline-command__utilities {
  display: grid;
  gap: var(--tl-space-3);
  padding-top: var(--tl-space-3);
  border-top: 1px solid var(--tl-color-border);
}

.tl-timeline-drawer {
  display: grid;
  align-content: start;
  gap: var(--tl-space-4);
}

.tl-timeline-drawer__header {
  display: flex;
  flex-wrap: wrap;
  align-items: start;
  justify-content: space-between;
  gap: var(--tl-space-3);
  padding-bottom: var(--tl-space-3);
  border-bottom: 1px solid var(--tl-color-border);
}

.tl-modal-container,
.tl-drawer-container {
  position: fixed;
  inset: 0;
  z-index: var(--tl-z-subview);
}

.tl-drawer {
  position: relative;
  width: min(var(--tl-drawer-width), 100vw);
  height: 100%;
  overflow: auto;
  padding: var(--tl-space-5);
  background: var(--tl-color-surface-raised);
}
```

**Pager and count-copy style pattern** (lines 2099-2124):

```css
.tl-pager {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--tl-space-2);
  padding: var(--tl-space-3) 0 0;
}

.tl-pager__range {
  color: var(--tl-color-muted);
  font-size: var(--tl-font-size-label);
  line-height: var(--tl-line-label);
  font-variant-numeric: tabular-nums;
}

.tl-pager__control[disabled],
.threadline-ui button.tl-pager__control[disabled] {
  color: var(--tl-color-muted);
  opacity: 0.55;
  cursor: not-allowed;
}
```

**Responsive enhancement pattern** (lines 4110-4188):

```css
@media (min-width: 768px) {
  .tl-timeline-command__facts {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .tl-filter-grid--primary {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (min-width: 1280px) {
  .tl-toolbar.tl-timeline-command {
    position: static;
    padding: var(--tl-space-3);
  }

  .tl-timeline-command__summary {
    grid-template-columns: minmax(240px, .85fr) minmax(0, 1.15fr);
    align-items: center;
  }

  .tl-filter-grid--primary {
    grid-template-columns: minmax(178px, .8fr) minmax(178px, .8fr) minmax(180px, 1fr) minmax(240px, 1.3fr);
  }

  .tl-toolbar__actions {
    grid-column: 1 / -1;
    justify-content: flex-end;
  }
}
```

**Motion and copy contract pattern** (lines 3577-3652, 4356-4381):

```css
/* The high-traffic timeline stream is deliberately NOT animated. */
#retention-runs > tr {
  animation: tl-rise-in var(--tl-motion-base) var(--tl-ease-out) both;
}

.tl-subview__timeline > * {
  animation: tl-rise-in var(--tl-motion-base) var(--tl-ease-out) both;
}

.tl-record-list > .tl-record-card,
#transactions-list > .tl-change {
  animation: tl-fade-in var(--tl-motion-base) var(--tl-ease-out) both;
}

.tl-copy {
  position: relative;
  display: inline-flex;
  align-items: center;
  min-height: var(--tl-control-height-chip);
  padding: 0 var(--tl-space-2);
  border: 1px solid var(--tl-color-border);
  border-radius: var(--tl-radius-sm);
}

@media (prefers-reduced-motion: reduce) {
  .threadline-ui *,
  .threadline-ui *::before,
  .threadline-ui *::after,
  .tl-policy__row::details-content {
    transition-duration: 1ms !important;
    animation-duration: 1ms !important;
    animation-delay: 0ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto !important;
  }
}
```

### `test/threadline/operator_surface/live/timeline_live_test.exs` (test, request-response + event-driven)

**Analog:** `test/threadline/operator_surface/live/timeline_live_test.exs`

**Default redirect and all filter keys** (lines 380-392):

```elixir
assert {:error, {:live_redirect, %{to: redirect_path}}} = live(conn, "/audit/timeline")
assert redirect_path =~ ~r{^/audit/timeline\?from=.+&to=.+$}

assert {:ok, _lv, html} = live(conn, redirect_path)
assert html =~ ~s|name="filter[from]"|
assert html =~ ~s|name="filter[to]"|
assert html =~ ~s|name="filter[table_schema]"|
assert html =~ ~s|name="filter[table]"|
assert html =~ ~s|name="filter[actor_kind]"|
assert html =~ ~s|name="filter[actor_id]"|
assert html =~ ~s|name="filter[correlation_id]"|
```

**Batch apply and canonical URL assertion** (lines 399-420):

```elixir
html =
  lv
  |> form("#timeline-filters",
    filter: %{
      from: "2026-05-01T00:00",
      to: "2026-05-06T23:59",
      table: "posts",
      actor_kind: "user",
      actor_id: "42",
      correlation_id: "req_abc123"
    }
  )
  |> render_submit()

patched_path = assert_patch(lv)

assert patched_path =~
         ~r{/audit/timeline\?from=2026-05-01T00%3A00&to=2026-05-06T23%3A59&table=posts&actor_kind=user&actor_id=42&correlation_id=req_abc123}
```

**Invalid and unknown filter copy pattern** (lines 490-520):

```elixir
long_id = String.duplicate("a", 257)
assert {:ok, _lv, html} = live(conn, "/audit/timeline?correlation_id=#{long_id}")

assert html =~
         "Timeline filters could not be applied. Fix the correlation id filter, then apply filters again."

assert html =~ "256 UTF-8 bytes"

assert {:ok, _lv, html} = live(conn, "/audit/timeline?table=does_not_exist_xyz")

assert html =~
         "Table filter `does_not_exist_xyz` is not audited. Select an audited table or clear the table filter."
```

**Command/drawer source contract** (lines 773-803):

```elixir
assert html =~ ~s|class="tl-toolbar tl-timeline-command"|
assert html =~ ~s|aria-controls="timeline-filters-drawer"|
assert html =~ ~s|id="timeline-filters-drawer"|
assert html =~ ~s|phx-window-keydown=|
assert html =~ ~s|phx-key="Escape"|
assert html =~ "Window: 24h"
assert html =~ "2026-06-06 20:07 UTC to 2026-06-07 20:07 UTC"
assert html =~ "Reset to last 24h"
refute html =~ ~s|class="tl-filter-disclosure"|

assert html =~ "3 active"
assert html =~ ~s|form="timeline-filters"|
assert html =~ "schema: public"
assert html =~ "actor kind: user"
assert html =~ "actor id: 42"
```

**Empty state, row order, and long ref copy pattern** (lines 847-947):

```elixir
assert html =~ "No captured changes match this window"
assert html =~
         "Widen the time range, or clear the table filter to search every audited table. Scoped views only show records you are authorized to see."

assert html =~ "No captured changes in this time window"
assert html =~
         "This window has no matching changes, but Threadline has audit data outside it. Move the window back toward recent activity or clear filters."

assert html =~ ~s|class="tl-filter-summary"|
assert html =~ ~s|data-testid="timeline-row"|
assert html =~ ~s|class="tl-journey--legend"|

assert form_index < summary_index
assert summary_index < row_index
assert row_index < utilities_index
assert row_index < legend_index

assert html =~ ~s|title="#{correlation_id}"|
assert html =~ correlation_ref.visible
assert html =~ ~s|data-tl-copy="#{correlation_id}"|
assert html =~ ~s|aria-label="Copy correlation id"|
```

**Export queue and denied-affordance tests** (lines 1174-1303):

```elixir
Application.put_env(:threadline, :export_queue_adapter, Threadline.OperatorSurface.TimelineLiveTest.SuccessfulQueueAdapter)

lv |> element("button", "Queue export") |> render_click()
assert_redirect(lv, "/audit_scoped/exports")

jobs = Threadline.Test.Repo.all(Threadline.Governance.ExportJob)
job = hd(jobs -- initial_jobs)
assert job.status == "pending"
assert job.query_params["table"] == "support_posts"
assert job.actor_ref.type == :user
assert job.actor_ref.id == "op1"

_html = lv |> element("button", "Queue export") |> render_click()
[job] = Threadline.Test.Repo.all(Threadline.Governance.ExportJob)
assert job.status == "failed"
assert job.error_message =~ "built-in export runtime is unavailable"
assert render(lv) =~ "Queue export"
assert render(lv) =~ "support_posts"

refute html =~ "Queue export"
refute html =~ ">CSV<"
refute html =~ ">JSON<"
refute html =~ ">NDJSON<"
refute html =~ "Carry to Exports"

render_click(lv, "request_background_export", %{})
assert Threadline.Test.Repo.all(Threadline.Governance.ExportJob) == []
```

### `test/threadline/operator_surface/exports/filter_params_test.exs` (test, transform)

**Analog:** `test/threadline/operator_surface/exports/filter_params_test.exs`

**Parser edge cases** (lines 13-76):

```elixir
assert {:ok, filters} = FilterParams.parse(%{"foo" => "bar", "table" => "posts"})
assert filters == [table: "posts"]

assert FilterParams.parse(%{"from" => "", "to" => ""}) == {:ok, []}

assert {:ok, filters} = FilterParams.parse(%{"from" => "2026-05-06T12:00"})
assert {:from, %DateTime{year: 2026, month: 5, day: 6, hour: 12, minute: 0, second: 0}} =
         List.keyfind(filters, :from, 0)

assert FilterParams.parse(%{"from" => "not-a-date"}) ==
         {:error, "invalid datetime: not-a-date"}

assert {:ok, filters} = FilterParams.parse(%{"actor_kind" => "anonymous", "actor_id" => "ignored"})
assert {:actor_ref, %ActorRef{type: :anonymous, id: nil}} = List.keyfind(filters, :actor_ref, 0)

assert {:ok, filters} = FilterParams.parse(%{"correlation_id" => "abc-123"})
assert filters == [correlation_id: "abc-123"]
```

**Raw hydration and atom-safety tests** (lines 89-119):

```elixir
assert FilterParams.filters_raw_from_params(%{"from" => "2026-05-06T12:00"}) == %{
         "from" => "2026-05-06T12:00",
         "to" => "",
         "table_schema" => "",
         "table" => "",
         "actor_kind" => "",
         "actor_id" => "",
         "correlation_id" => ""
       }

raw = FilterParams.filters_raw_from_params(%{"actor_kind" => "anonymous", "actor_id" => "ignored"})
assert raw["actor_kind"] == "anonymous"
assert raw["actor_id"] == ""

src = File.read!("lib/threadline/operator_surface/exports/filter_params.ex")
assert src =~ "String.to_existing_atom"
refute src =~ ~r/String\.to_atom\b/
```

### `test/threadline/operator_surface/presentation_test.exs` (test, transform)

**Analog:** `test/threadline/operator_surface/presentation_test.exs`

**Operation and ref tests** (lines 11-41, 91-180):

```elixir
assert Presentation.operation_modifier("INSERT") == "tl-change__op--insert"
assert Presentation.operation_modifier(:insert) == "tl-change__op--insert"
assert Presentation.operation_modifier(nil) == ""
assert Presentation.operation_modifier(unknown) == ""
assert Presentation.operation_label("insert") == "INSERT"
assert Presentation.operation_label(:update) == "UPDATE"
assert Presentation.operation_label(nil) == "UNKNOWN"

assert %{title: ^value, visible: visible} = Presentation.secondary_ref(value, 24)
assert visible != value
assert String.ends_with?(visible, "23456789")

result = Presentation.truncate_middle(value, 34, tail_min: 8)
assert String.ends_with?(result, String.slice(value, -8, 8))

ref = Presentation.ref(value, kind: :actor)
assert ref.full == value
assert ref.title == ref.full
assert ref.visible != value
```

### `test/threadline/operator_surface/copy_contract_test.exs` (test, transform + request-response)

**Analog:** `test/threadline/operator_surface/copy_contract_test.exs`

**Copy vocabulary and full-value copy pattern** (lines 181-223):

```elixir
text =
  [render_shell(), render_home(conn)]
  |> Enum.map(&visible_text/1)
  |> Enum.join("\n")

refute text =~ "!"

for leak <- @title_case_state_leaks do
  refute text =~ leak
end

for model <- @camel_case_model_names do
  refute text =~ model
end

refute text =~ ~r/\b(Prove|proofs?|Proof)\b/

html =
  rendered_to_string(~H"""
  <UI.ref value={@value} kind="correlation" copy_label="Copy correlation id" />
  """)

visible = Threadline.OperatorSurface.Presentation.ref(@long_correlation_id, kind: :correlation).visible
copy_targets = extract_copy_targets(html)

assert visible != @long_correlation_id
assert html =~ visible
assert copy_targets != []
assert Enum.all?(copy_targets, &(&1 == @long_correlation_id))
refute Enum.member?(copy_targets, visible)
```

### `test/threadline/operator_surface/style_contract_test.exs` (test, source contract)

**Analog:** `test/threadline/operator_surface/style_contract_test.exs`

**Responsive and no-overflow source checks** (lines 601-732):

```elixir
assert_selector_contains(base, ".tl-filter-grid", [
  "display: grid;",
  "grid-template-columns: 1fr;",
  "align-items: start;"
])

for selector <- [".tl-secondary-ref", ".tl-value", ".tl-param", ".tl-record-card__ref", ".tl-kv__row"] do
  assert Regex.match?(
           selector_block_pattern(selector, ~r/min-width:\s*0;|overflow-wrap:\s*anywhere;/),
           base
         )
end

refute Regex.match?(~r/(?:body|html|\.threadline-ui)\s*\{[^}]*overflow-x:\s*hidden;/s, src)

assert_selector_contains(tablet, ".tl-timeline-command__facts", [
  "grid-template-columns: repeat(3, minmax(0, 1fr));"
])

assert_selector_contains(desktop, ".tl-filter-grid--primary", [
  "grid-template-columns: minmax(178px, .8fr) minmax(178px, .8fr) minmax(180px, 1fr) minmax(240px, 1.3fr);"
])

assert_selector_contains(desktop, ".tl-toolbar.tl-timeline-command", [
  "position: static;",
  "padding: var(--tl-space-3);"
])
```

**Timeline row motion prohibition** (lines 515-530):

```elixir
timeline_row = selector_block!(src, ".tl-change")

refute String.contains?(timeline_row, "animation:"),
       "the high-frequency timeline row primitive must not animate on stream updates"

for forbidden_pattern <- [
      ~r/#timeline-rows\s*>\s*\.tl-change[^}]*animation\s*:/s,
      ~r/#changes-list\s*>\s*\.tl-change[^}]*animation\s*:/s,
      ~r/\.tl-change-list\s*>\s*\.tl-change[^}]*animation\s*:/s,
      ~r/\.tl-table--actionable\s+tbody\s+tr[^}]*animation\s*:/s
    ] do
  refute Regex.match?(forbidden_pattern, src),
         "high-frequency row/list/table selectors must stay still"
end
```

**Token spacing check for Timeline facts** (lines 1640-1655):

```elixir
timeline_fact = selector_block!(src, ".tl-timeline-fact")

gap_decl =
  case Regex.run(~r/gap:\s*([^;]+);/, timeline_fact) do
    [_, value] -> String.trim(value)
    _ -> flunk(".tl-timeline-fact must declare a gap")
  end

assert String.contains?(gap_decl, "var(--tl-space-"),
       ".tl-timeline-fact gap must resolve through the --tl-space-* scale")
```

### `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` (test, browser request-response)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`

**Viewport matrix and no-overflow helper** (lines 7-46):

```typescript
const viewports = [
  { name: "phone", width: 375, height: 812, isMobile: true },
  { name: "tablet", width: 768, height: 900, isMobile: false },
  { name: "desktop-1024", width: 1024, height: 900, isMobile: false },
  { name: "desktop", width: 1280, height: 900, isMobile: false },
];

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}
```

**Timeline command and rows-first proof** (lines 103-145):

```typescript
async function expectTimelineIntroFlow(page: Page) {
  const mainToolbar = page.locator("#tl-main > .tl-toolbar");
  await expect(mainToolbar).toHaveCount(1);
  await expect(page.locator("#tl-main #timeline-filters")).toHaveCount(1);
  await expect(page.locator("#tl-main > .tl-timeline-command")).toHaveCount(1);
  ...
}

async function expectTimelineRowsFirstViewport(page: Page) {
  const firstRow = page.getByTestId("timeline-row").first();
  await expect(firstRow).toBeVisible();
  await expect(firstRow.getByTestId("transaction-link")).toBeVisible();

  const metrics = await page.evaluate(() => {
    const command = document.querySelector(".tl-timeline-command");
    const firstRow = document.querySelector('[data-testid="timeline-row"]');
    const rowAction = firstRow?.querySelector('[data-testid="transaction-link"]');
    ...
  });
```

**Drawer Escape/focus return and route matrix** (lines 518-535, 539-601):

```typescript
await page.goto(
  "/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00",
);
await expectTimelineIntroFlow(page);
await expectTimelineRowsFirstViewport(page);
const filtersButton = page.getByRole("button", { name: /Filters/ });
await filtersButton.click();
const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
await expect(drawer).toBeVisible();
await expect(drawer.getByLabel("Schema")).toBeVisible();
await page.keyboard.press("Escape");
await expect(drawer).toBeHidden();
await expect(filtersButton).toBeFocused();
await expectNoHorizontalOverflow(page);

for (const viewport of viewports) {
  test.describe(`operator responsive matrix: ${viewport.name}`, () => {
    test.use({ viewport: { width: viewport.width, height: viewport.height }, isMobile: viewport.isMobile });
    ...
    await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
    await expect(page.locator("#filter-table")).toHaveValue(rowTable);
    await expect(page.getByTestId("timeline-row").first()).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });
}
```

### `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` (possible new test, browser request-response)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`

Use this new-file name only if widening `operator-responsive-mobile-first.spec.ts` makes the shared matrix too broad. Copy the login helper, `expectNoHorizontalOverflow`, `expectTimelineIntroFlow`, and drawer focus-return pattern from `operator-responsive-mobile-first.spec.ts` lines 30-46, 103-145, and 518-535. Add only Phase-184-specific viewports that are missing from the shared matrix: 320 and 1440 px.

```typescript
test.use({ viewport: { width: 320, height: 812 }, isMobile: true });
await page.goto("/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00");
await expectTimelineIntroFlow(page);
await expectTimelineRowsFirstViewport(page);
await expectNoHorizontalOverflow(page);
```

### `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` (test, browser event-driven + accessibility)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`

**Open drawer helper and named controls pattern** (lines 195-202, 347-421):

```typescript
const drawer = page.locator("#timeline-filters-drawer");
if ((await drawer.count()) === 0 || (await drawer.isVisible())) {
  return;
}

await page.getByRole("button", { name: "Filters" }).first().click();
await expect(drawer).toBeVisible();

await page.goto("/audit/timeline");

for (const label of ["From", "To", "Table", "Correlation id"]) {
  await expect(page.getByLabel(label, { exact: true })).toBeVisible();
}

const workflowLine = page.getByText(
  "Filter the timeline, open transactions or row history, then export the current view when you need a handoff.",
);
await expect(workflowLine).toBeVisible();

const correlationFilter = page.getByLabel("Correlation id", { exact: true }).filter({ visible: true }).first();
await correlationFilter.focus();
await expectNonObscuredFocused(correlationFilter, page);

await openTimelineAdvancedFilters(page);
for (const label of ["Actor kind", "Actor id"]) {
  await expect(page.getByLabel(label, { exact: true }).filter({ visible: true })).toBeVisible();
}
```

### `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` (test, browser request-response + handoff)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`

**Timeline-to-Exports context pattern** (lines 149-180):

```typescript
await page.goto(
  `/audit/timeline?table=${encodeURIComponent(rowTable)}&correlation_id=${encodeURIComponent(closeCorrelation)}`,
);

await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);

const carry = page
  .locator('[data-earned-flow="EF3"]')
  .filter({ hasText: "Carry to Exports" })
  .first();
await expectEarnedFlow(carry, "EF3");
await carry.click();

await expectPath(page, "/audit/exports");
const url = new URL(page.url());
expect(url.searchParams.get("table")).toBe(rowTable);
expect(url.searchParams.get("correlation_id")).toBe(closeCorrelation);

const context = page.getByTestId("timeline-export-context");
await expect(context.locator("dd", { hasText: rowTable }).locator(".tl-secondary-ref")).toHaveAttribute("data-tl-copy", rowTable);
await expect(context.locator("dd", { hasText: closeCorrelation }).locator(".tl-secondary-ref")).toHaveAttribute("data-tl-copy", closeCorrelation);
```

### `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` (test, browser request-response + mobile)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts`

**Mobile row-first and row-history proof** (lines 39-99):

```typescript
await page.goto("/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00");

const filterSummary = page.locator(".tl-filter-summary");
const timeline = page.getByTestId("operator-timeline");
const firstRow = page.getByTestId("timeline-row").first();
const journeyLegend = page.locator(".tl-journey--legend");

await expect(filterSummary).toBeVisible();
await expect(timeline).toBeVisible();
await expect(firstRow).toBeVisible();
await expect(journeyLegend).toBeVisible();

const rowBox = await box(firstRow);
const legendBox = await box(journeyLegend);
expect(rowBox.y).toBeLessThan(legendBox.y);

await page.getByTestId("transaction-link").first().click();
await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);
const copy = page.locator(".tl-copy").first();
await expect(copy).toBeVisible();
await expect(copy).toBeEnabled();

await page.getByTestId("transaction-change-row").filter({ hasText: "ticket_replies" }).getByTestId("row-history-link").first().click();
const drawer = page.getByTestId("row-history-drawer");
await expect(drawer).toBeVisible();
await expect(drawer.getByText("Row history:")).toBeVisible();
await expectNoHorizontalOverflow(page);
```

### `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` (test, browser event-driven + motion)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts`

**Computed style and reduced-motion pattern** (lines 64-75, 301-309):

```typescript
async function readComputedStyle(locator: Locator, pseudoElement?: string): Promise<StyleSnapshot> {
  return locator.evaluate(
    (element, pseudo) => {
      const style = getComputedStyle(element, pseudo || undefined);

      return {
        animationName: style.animationName,
        animationDuration: style.animationDuration,
        animationDelay: style.animationDelay,
        boxShadow: style.boxShadow,
        cursor: style.cursor,
        opacity: style.opacity,
```

```typescript
test("row-history drawer enters without off-screen reduced-motion transform", async ({ page }) => {
  const ticketReplyRecordId = await discoverTicketReplyRecordId(page);
  await page.goto(`/audit/rows/${rowTable}/${ticketReplyRecordId}`);

  const drawerStyle = await computedStyle(page.getByTestId("row-history-drawer"));
  expect(drawerStyle.animationName).toBe("none");
  expectIdentityOrNone(drawerStyle.transform);
});
```

## Shared Patterns

### Authentication And Export Authorization

**Source:** `lib/threadline/operator_surface/export_auth_plug.ex`

**Apply to:** Timeline export affordance visibility, direct download links, background export events, and any export handoff tests. LiveView visibility is not authorization.

```elixir
def call(conn, opts) do
  authorize_fn = Keyword.get(opts, :authorize_fn, fn _ -> true end)
  export_authorize_fn = Keyword.get(opts, :export_authorize_fn)
  scope_query_fn = Keyword.get(opts, :scope_query_fn)
  repo = Keyword.get(opts, :repo)

  conn = assign(conn, :threadline_repo, repo)
  conn = assign(conn, :threadline_scope_query_fn, scope_query_fn)

  authorizer =
    case export_authorize_fn do
      fun when is_function(fun, 1) -> fn -> fun.(conn) end
      nil -> fn ->
        mirror = %{assigns: conn.assigns}
        authorize_fn.(mirror)
      end
    end

  try do
    case authorizer.() do
      :ok -> conn
      true -> conn
      {:ok, scope} -> assign(conn, :threadline_scope, scope)
      _ -> halt_unauthorized(conn, :denied)
    end
  rescue
    _ -> halt_unauthorized(conn, :error)
  end
end

defp halt_unauthorized(conn, result) do
  emit_telemetry(result, conn, nil)

  conn
  |> put_resp_content_type("text/plain")
  |> send_resp(403, "forbidden")
  |> halt()
end
```

### Direct Download Controller Boundary

**Source:** `lib/threadline/operator_surface/controllers/export_controller.ex`

**Apply to:** Direct CSV/JSON/NDJSON links rendered by Timeline and any tests asserting filter parity. Do not move HTTP file response behavior into LiveView.

```elixir
def csv(conn, params), do: dispatch(conn, params, :csv)
def json(conn, params), do: dispatch(conn, params, :json)
def ndjson(conn, params), do: dispatch(conn, params, :ndjson)

defp dispatch(conn, params, format) do
  with {:ok, filters} <- FilterParams.parse(params),
       :ok <- safe_validate(filters) do
    repo = conn.assigns[:threadline_repo] || default_repo()
    filters = Keyword.put(filters, :repo, repo)

    scope_opts = [
      scope: conn.assigns[:threadline_scope],
      scope_query_fn: conn.assigns[:threadline_scope_query_fn],
      surface: :export,
      params: %{filters: filters}
    ]

    {:ok, %{count: count}} =
      Export.count_matching(filters, Keyword.merge([cap: @max_rows + 1], scope_opts))

    conn = put_export_headers(conn, format)

    if count <= @sync_threshold do
      send_iodata(conn, filters, format, scope_opts)
    else
      send_chunked_stream(conn, filters, format, scope_opts)
    end
  else
    {:error, message} ->
      ...
  end
end
```

**Streaming and headers** (lines 234-259, 336-364):

```elixir
defp send_chunked_stream(conn, filters, format, scope_opts) do
  conn = send_chunked(conn, 200)
  conn = emit_prefix(conn, format)

  {conn, _} =
    filters
    |> Export.stream_export_rows(Keyword.merge([page_size: @stream_page_size], scope_opts))
    |> Stream.take(@max_rows)
    |> Stream.chunk_every(@chunk_batch_size)
    |> Enum.reduce_while({conn, _first_batch? = true}, fn rows, {conn, first_batch?} ->
      batch_iodata = format_batch(rows, format, first_batch?)

      case Plug.Conn.chunk(conn, batch_iodata) do
        {:ok, conn} -> {:cont, {conn, false}}
        {:error, :closed} -> {:halt, {conn, false}}
        {:error, _other} -> {:halt, {conn, false}}
      end
    end)

  emit_suffix(conn, format)
end

defp put_export_headers(conn, content_type, ext) do
  filename = Filename.for(ext, DateTime.utc_now())
  disposition = ~s|attachment; filename="#{filename}"; filename*=UTF-8''#{filename}|

  conn
  |> put_resp_header("content-type", content_type)
  |> put_resp_header("content-disposition", disposition)
  |> put_resp_header("cache-control", "no-store")
end

defp safe_validate(filters) do
  try do
    Threadline.Query.validate_timeline_filters!(filters)
    :ok
  rescue
    e in ArgumentError -> {:error, e.message}
  end
end
```

### Route And Test-ID Stability

**Source:** `lib/threadline/operator_surface/live/timeline_live.ex`

**Apply to:** All Timeline markup/test changes.

Keep existing paths and test IDs stable: `/audit/timeline`, `/audit/transactions/:id`, `/audit/rows/:table/:id`, `/audit/actors/:kind/:id`, `/audit/exports`, `operator-timeline`, `timeline-row`, `transaction-link`, and `timeline-filters`.

### Browser Verification Shape

**Source:** `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`

**Apply to:** Responsive, drawer, keyboard, route-transition, and overflow proof.

Use role/test-id locators and `expectNoHorizontalOverflow`. Add 320 and 1440 coverage either by extending the viewport array or by creating the narrow Phase-184 spec listed above.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | Existing Timeline, UI, parser, style, ExUnit, and Playwright analogs cover the planned work. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface`, `test/threadline/operator_surface`, `examples/threadline_phoenix/e2e/tests`

**Files scanned:** 23 candidate source/test files, including Timeline LiveView, private UI, parser, presentation, style, export controller/auth, ExUnit contracts, and Playwright specs.

**Project instructions read:** `CLAUDE.md`; no root `AGENTS.md` found. `examples/threadline_phoenix/AGENTS.md` was read before extracting example-app E2E patterns.

**Project-local skills:** No `.codex/skills` or `.agents/skills` entries found in this repository.

**Pattern extraction date:** 2026-06-28
