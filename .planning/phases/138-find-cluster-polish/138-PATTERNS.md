# Phase 138: find-cluster-polish - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/presentation.ex` | utility | transform | `lib/threadline/operator_surface/presentation.ex` | exact |
| `lib/threadline/operator_surface/style.ex` | config/style primitive | transform | `lib/threadline/operator_surface/style.ex` | exact |
| `lib/threadline/operator_surface/script.ex` | utility | event-driven | `lib/threadline/operator_surface/script.ex` | exact |
| `lib/threadline/operator_surface/live/timeline_live.ex` | route/LiveView | request-response + CRUD + streaming | `lib/threadline/operator_surface/live/timeline_live.ex` | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` | route/LiveView | request-response + streaming | `lib/threadline/operator_surface/live/transaction_live.ex` | exact |
| `lib/threadline/operator_surface/live/row_history_component.ex` | component | request-response + CRUD | `lib/threadline/operator_surface/live/row_history_component.ex` | exact |
| `lib/threadline/operator_surface/live/actor_live.ex` | route/LiveView | request-response + streaming | `lib/threadline/operator_surface/live/actor_live.ex` | exact |
| `lib/threadline/operator_surface/live/coverage_live.ex` | route/LiveView | request-response + polling/event-driven | `lib/threadline/operator_surface/live/coverage_live.ex` | exact |
| `test/threadline/operator_surface/presentation_test.exs` | test | transform | `test/threadline/operator_surface/presentation_test.exs` | exact |
| `test/threadline/operator_surface/style_contract_test.exs` | test | transform | `test/threadline/operator_surface/style_contract_test.exs` | exact |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | test | request-response + streaming | `test/threadline/operator_surface/live/timeline_live_test.exs` | exact |
| `test/threadline/operator_surface/transaction_live_test.exs` | test | request-response + streaming | `test/threadline/operator_surface/transaction_live_test.exs` | exact |
| `test/threadline/operator_surface/row_history_component_test.exs` | test | request-response | `test/threadline/operator_surface/row_history_component_test.exs` | exact |
| `test/threadline/operator_surface/live/actor_live_test.exs` | test | request-response + streaming | `test/threadline/operator_surface/live/actor_live_test.exs` | exact |
| `test/threadline/operator_surface/live/coverage_live_test.exs` | test | request-response + event-driven | `test/threadline/operator_surface/live/coverage_live_test.exs` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` | test | browser request-response | `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts` | role-match |

## Pattern Assignments

### `lib/threadline/operator_surface/presentation.ex` (utility, transform)

**Analog:** `lib/threadline/operator_surface/presentation.ex`

**Imports/module pattern** (lines 1-6):
```elixir
defmodule Threadline.OperatorSurface.Presentation do
  @moduledoc false

  @month_names ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

  @spec human_time(DateTime.t() | nil, keyword()) :: String.t()
```

**Pure helper pattern** (lines 58-68):
```elixir
@spec truncate_middle(term(), pos_integer()) :: String.t()
def truncate_middle(value, max_length \\ 34) do
  value = to_string(value || "")

  if String.length(value) <= max_length do
    value
  else
    keep = max(div(max_length - 3, 2), 4)
    String.slice(value, 0, keep) <> "..." <> String.slice(value, -keep, keep)
  end
end
```

**Status/label vocabulary pattern** (lines 70-110):
```elixir
@spec status_modifier(String.t() | atom() | nil) :: String.t()
def status_modifier(status) do
  case normalize_status(status) do
    status when status in ~w(completed covered proven configured config_matches_deployed) ->
      "tl-chip--success"

    status when status in ~w(failed error uncovered unsupported invalid) ->
      "tl-chip--danger"

    status when status in ~w(drift_detected could_not_introspect stale expired) ->
      "tl-chip--warning"

    status when status in ~w(pending running queued processing inferred_posture) ->
      "tl-chip--info"

    _ ->
      "tl-chip--neutral"
  end
end
```

**Secondary-ref pattern** (lines 210-227):
```elixir
@spec secondary_ref(term(), pos_integer()) :: %{visible: String.t(), title: String.t()}
def secondary_ref(value, max_length \\ 34) do
  full = secondary_ref_value(value)

  %{
    visible: truncate_middle(full, max_length),
    title: full
  }
end
```

**Apply to Phase 138:** Add pure helpers here for value tokens, count grammar, coverage remediation labels, and actor transaction summaries. Keep this module DB-free and route-free.

---

### `lib/threadline/operator_surface/live/timeline_live.ex` (route/LiveView, request-response + CRUD + streaming)

**Analog:** `lib/threadline/operator_surface/live/timeline_live.ex`

**Imports/alias pattern** (lines 1-10):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Export
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.Query
```

**URL-state and stream reset pattern** (lines 76-114, 143-173):
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
    ...
    {:noreply, push_patch(socket, to: "#{timeline_path}?#{query_string}", replace: true)}
  else
    socket = assign(socket, :filters_raw, FilterParams.filters_raw_from_params(params))
    ...
    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:form_error, nil)
      |> assign(:unknown_table_attempted, unknown_table_attempted)
      |> assign(:match_count, count)
      |> assign(:filter_query, filter_query)
      |> stream(:changes, page.entries, reset: true)
      |> assign(:cursor, page.next_cursor)
```

**Thin LiveView data-loading pattern** (lines 143-161):
```elixir
count_task =
  Task.async(fn ->
    Export.count_matching(filters, cap: 10_001, repo: socket.assigns.repo)
  end)

page_task =
  Task.async(fn ->
    Query.timeline_page(filters, scope_aware_opts(socket))
  end)

{:ok, %{count: count}} = Task.await(count_task, 8_000)

page =
  page_task
  |> Task.await(8_000)
  |> preload_visible_context(socket.assigns.repo)
```

**Filter/form pattern needing Phase 138 polish** (lines 376-413):
```elixir
<form id="timeline-filters" phx-submit="apply" role="search" class="tl-toolbar__form">
  ...
  <label class="tl-toolbar__field">Actor id
    <input type="text" name="filter[actor_id]" id="filter-actor-id"
           aria-label="actor id"
           value={@filters_raw["actor_id"] || ""}
           disabled={@filters_raw["actor_kind"] == "anonymous"}
           phx-debounce="blur" class="tl-toolbar__control" />
  </label>
  <label class="tl-toolbar__field tl-toolbar__field--wide">Correlation id
    <input type="text" name="filter[correlation_id]" id="filter-correlation-id"
           aria-label="correlation id"
           value={@filters_raw["correlation_id"] || ""}
           maxlength="256" phx-debounce="300" class="tl-toolbar__control" />
    <small class="tl-toolbar__hint">request_id, job_id, or integration token. Up to 256 chars.</small>
  </label>
```

**Timeline row/copy pattern** (lines 474-505):
```elixir
<section class="tl-change-list" id="timeline-rows" phx-update="stream"
         phx-viewport-bottom={@cursor && "next-page"}
         data-testid="operator-timeline">
  <div :for={{dom_id, change} <- @streams.changes} id={dom_id} class={["tl-change", op_row_modifier(change.op)]} data-testid="timeline-row">
    <div class="tl-change__summary">
      <div class="tl-change__meta">
        <span class={["tl-change__op", op_chip_modifier(change.op)]}><%= change.op %></span>
        <span class="tl-change__table"><%= change.table_name %></span>
        <time class="tl-change__time" datetime={Presentation.exact_time(change.captured_at)} title={Presentation.exact_time(change.captured_at)}>
          <%= Presentation.human_time(change.captured_at) %>
        </time>
      </div>
      ...
      <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy" data-tl-copy={correlation_id(change)} aria-label="Copy correlation id">Copy</button>
      ...
      <a href={"#{@base_path}/transactions/#{change.transaction_id}"} class="tl-button tl-button--compact tl-button--secondary" data-testid="transaction-link">Open transaction</a>
```

**Apply to Phase 138:** Keep URL state and streams intact. Demote the journey strip from lines 359-372, move active filter/status/rows earlier, add anonymous actor hint, and replace long visible values with `Presentation.secondary_ref/2` metadata plus copy affordances.

---

### `lib/threadline/operator_surface/live/transaction_live.ex` (route/LiveView, request-response + streaming)

**Analog:** `lib/threadline/operator_surface/live/transaction_live.ex`

**Imports and data-loading pattern** (lines 1-31):
```elixir
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
```

**History route/patch pattern** (lines 35-80):
```elixir
def handle_params(params, uri, socket) do
  uri_parsed = URI.parse(uri)
  base_path =
    case Regex.run(~r/(.*\/transactions\/[^\/]+)/, uri_parsed.path) do
      [_, path] -> path
      _ -> uri_parsed.path
    end

  socket = assign(socket, :base_path, base_path)

  if socket.assigns.live_action == :history do
    table = params["table"]
    record_id = params["record_id"]
    ...
    {:noreply,
     assign(socket,
       show_history: true,
       history_table: table,
       history_record_id: record_id,
       history_as_of: as_of
     )}
```

**Current diff pattern to replace with value tokens** (lines 174-187):
```elixir
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
```

**Copy/truncation pattern needing middle truncation** (lines 115-118, 263-265):
```elixir
<h1 class="tl-transaction__title" title={@bundle.transaction.id}>
  Transaction <code><%= Presentation.short_id(@bundle.transaction.id, 14) %></code>
  <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy" data-tl-copy={@bundle.transaction.id} aria-label="Copy transaction id">Copy</button>
</h1>
...
defp transaction_correlation_id(%{action: %{correlation_id: correlation_id}})
     when is_binary(correlation_id) and correlation_id != "",
     do: Presentation.truncate_middle(correlation_id, 42)
```

**Apply to Phase 138:** Keep local HEEx markup, but call new `Presentation` value-token helpers. INSERT rows must render inserted field values when available; empty diffs get diagnostic `.tl-empty` copy. Replace `short_id/2` for UUID-like refs with middle truncation/full title/copy.

---

### `lib/threadline/operator_surface/live/row_history_component.ex` (component, request-response + CRUD)

**Analog:** `lib/threadline/operator_surface/live/row_history_component.ex`

**Component/update pattern** (lines 1-36):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RowHistoryComponent do
    @moduledoc false
    use Phoenix.LiveComponent

    alias Threadline.OperatorSurface.Presentation

    def update(assigns, socket) do
      schemas = assigns[:threadline_schemas] || %{}

      schema_module =
        Map.get(schemas, assigns.table) || Map.get(schemas, String.to_atom(assigns.table))
      ...
      history = Threadline.history(schema_module, assigns.record_id, opts)
      ...
      snapshot_result =
        Threadline.as_of(schema_module, assigns.record_id, as_of_dt, opts)
```

**As-of patch pattern** (lines 47-60):
```elixir
def handle_event("update-as-of", %{"as_of" => as_of_str}, socket) do
  as_of_str =
    if String.length(as_of_str) == 16, do: as_of_str <> ":00Z", else: as_of_str <> "Z"

  as_of =
    case DateTime.from_iso8601(as_of_str) do
      {:ok, dt, _} -> dt
      _ -> socket.assigns.as_of_dt
    end

  path =
    "#{socket.assigns.base_path}/history/#{socket.assigns.table}/#{socket.assigns.record_id}?as_of=#{URI.encode_www_form(DateTime.to_iso8601(as_of))}"

  {:noreply, push_patch(socket, to: path)}
end
```

**Snapshot rendering pattern to update** (lines 131-172):
```elixir
defp snapshot_result(%{result: {:ok, snapshot}} = assigns) when is_map(snapshot) do
  assigns = assign(assigns, :rows, snapshot_rows(snapshot))

  ~H"""
  <dl class="tl-kv">
    <div :for={{key, value} <- @rows} class="tl-kv__row">
      <dt class="tl-kv__key"><%= key %></dt>
      <dd class="tl-kv__value"><%= value %></dd>
    </div>
  </dl>
  """
end
...
defp snapshot_rows(snapshot) do
  snapshot
  |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
  |> Enum.map(fn {key, value} -> {to_string(key), inspect(value)} end)
end
```

**Apply to Phase 138:** Keep this as a LiveComponent because it already owns a drawer and event target. Use the shared value-token helper for snapshot values; maintain stable key sorting and do not switch snapshots to transaction-style diffs.

---

### `lib/threadline/operator_surface/live/actor_live.ex` (route/LiveView, request-response + streaming)

**Analog:** `lib/threadline/operator_surface/live/actor_live.ex`

**Actor parse/query pattern** (lines 7-31):
```elixir
def mount(%{"kind" => kind, "id" => id}, _session, socket) do
  repo =
    socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

  type =
    try do
      String.to_existing_atom(kind)
    rescue
      ArgumentError -> String.to_atom(kind)
    end

  case Threadline.Semantics.ActorRef.new(type, id) do
    {:ok, actor_ref} ->
      from_time = DateTime.utc_now() |> DateTime.add(-24, :hour)

      page =
        Threadline.actor_history(actor_ref,
          repo: repo,
          from: from_time,
          scope: socket.assigns[:threadline_scope],
```

**Segmented control selected-state pattern** (lines 117-122):
```elixir
<div class="tl-segmented" role="group" aria-label="Actor activity window">
  <button type="button" phx-click="set-window" phx-value-hours="1" aria-pressed={@time_window_hours == 1} class="tl-segmented__item">1h</button>
  <button type="button" phx-click="set-window" phx-value-hours="24" aria-pressed={@time_window_hours == 24} class="tl-segmented__item">24h</button>
  <button type="button" phx-click="set-window" phx-value-hours="168" aria-pressed={@time_window_hours == 168} class="tl-segmented__item">7d</button>
  <button type="button" phx-click="set-window" phx-value-hours="720" aria-pressed={@time_window_hours == 720} class="tl-segmented__item">30d</button>
</div>
```

**Streaming transaction row pattern to enrich** (lines 142-164):
```elixir
<div
  id="transactions-list"
  phx-update="stream"
  phx-viewport-top="prev-page"
  phx-viewport-bottom="next-page"
  class="tl-viewport"
>
  <div :for={{dom_id, tx} <- @streams.transactions} id={dom_id} class="tl-change" data-testid="actor-transaction-row">
    <div class="tl-change__summary">
      <div class="tl-change__meta">
        <time class="tl-change__time" datetime={Presentation.exact_time(tx.occurred_at)} title={Presentation.exact_time(tx.occurred_at)}>
          <%= Presentation.human_time(tx.occurred_at) %>
        </time>
      </div>
      <div class="tl-meta">
        <span>Transaction <code title={tx.id}><%= Presentation.short_id(tx.id, 14) %></code></span>
        <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy" data-tl-copy={tx.id} aria-label="Copy transaction id">Copy</button>
```

**Window reset pattern** (lines 174-194):
```elixir
def handle_event("set-window", %{"hours" => hours_str}, socket) do
  hours = String.to_integer(hours_str)
  from_time = DateTime.utc_now() |> DateTime.add(-hours, :hour)

  page =
    Threadline.actor_history(socket.assigns.actor_ref,
      repo: socket.assigns.repo,
      from: from_time,
      scope: socket.assigns[:threadline_scope],
      scope_query_fn: socket.assigns[:threadline_scope_query_fn],
      surface: :actor_history,
      params: %{actor_ref: socket.assigns.actor_ref, from: from_time}
    )

  {:noreply,
   socket
   |> assign(:time_window_hours, hours)
   |> assign(:from_time, from_time)
   |> assign(:next_cursor, page.next_cursor)
   |> assign(:prev_cursor, page.prev_cursor)
   |> stream(:transactions, page.entries, reset: true)}
end
```

**Apply to Phase 138:** Preserve `actor_history/2` paging and avoid per-row N+1 queries. Add operation/table/change-count summaries through bounded visible-page preload or a local presenter fallback. Keep `Open transaction` as the detail pivot.

---

### `lib/threadline/operator_surface/live/coverage_live.ex` (route/LiveView, request-response + polling/event-driven)

**Analog:** `lib/threadline/operator_surface/live/coverage_live.ex`

**Imports and snapshot assigns pattern** (lines 1-33):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.CoverageLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Coverage.Snapshot
    alias Threadline.OperatorSurface.Unsupported
    ...
    def mount(_params, _session, socket) do
      initial = socket.assigns[:threadline_coverage] || Snapshot.empty(DateTime.utc_now())

      socket =
        socket
        |> assign(:base_path, nil)
        |> assign(:schema_param, "public")
        |> assign(:coverage_for_schema, initial)
        |> assign(:form_error, nil)
```

**Error handling/poll refresh pattern** (lines 67-88, 248-260):
```elixir
def handle_event("refresh", _params, socket) do
  if not socket.assigns[:threadline_coverage_enabled] do
    {:noreply, socket}
  else
    if ref = socket.assigns[:threadline_timer_ref] do
      Process.cancel_timer(ref)
    end

    schema = socket.assigns[:schema_param] || "public"
    socket = fetch_coverage_for_schema(socket, schema)
    ...
    {:noreply, socket}
  end
end
...
try do
  coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
  snapshot = Snapshot.from_coverage(coverage, last_checked_at: now)
  assign(socket, :coverage_for_schema, snapshot)
rescue
  e ->
    message = Exception.message(e)
    Threadline.Telemetry.emit_health_checked_error(message)
    previous = socket.assigns[:coverage_for_schema] || Snapshot.empty(now)
    snapshot = %{previous | error: message, last_checked_at: now}
    assign(socket, :coverage_for_schema, snapshot)
end
```

**Coverage table/remediation pattern to polish** (lines 166-214):
```elixir
<section :if={@coverage_for_schema.uncovered_count > 0} class="tl-remediation" aria-label="Coverage remediation">
  <header class="tl-remediation__header">
    <h3 class="tl-remediation__title">Needs capture before complete timeline answers</h3>
    <span class="tl-chip tl-chip--danger"><%= @coverage_for_schema.uncovered_count %> tables</span>
  </header>
  <div class="tl-remediation__body">
    Missing triggers mean matching Timeline searches can be incomplete for these tables. Add capture before treating investigation results as exhaustive, then return to Timeline and rerun the search.
  </div>
</section>
...
<%= for table <- @coverage_for_schema.tables[:uncovered] do %>
  <tr class="tl-table__row--uncovered">
    <td data-label="TABLE"><code><%= table %></code></td>
    <td data-label="STATUS"><span class="tl-chip tl-chip--danger">Needs capture</span></td>
    <td data-label="SOURCE">missing trigger</td>
    <td data-label="Actions" class="tl-table__actions"><span class="tl-hint">Timeline may be incomplete</span></td>
  </tr>
<% end %>
...
<p class="tl-hint">
  Coverage: <%= @coverage_for_schema.covered_count %> captured, <%= @coverage_for_schema.uncovered_count %> need capture, <%= @coverage_for_schema.expected_uncovered_count %> expected gaps
</p>
```

**Verified remediation command source** (`lib/mix/tasks/threadline.gen.triggers.ex` lines 8-17):
```elixir
## Usage

    mix threadline.gen.triggers --tables users
    mix threadline.gen.triggers --tables users,posts,comments

Each invocation produces one migration file containing `CREATE TRIGGER`
statements for all listed tables. Run `mix ecto.migrate` to apply.

The trigger calls `threadline_capture_changes()`, which must already be
installed via `mix threadline.install`.
```

**Apply to Phase 138:** Move repeated consequence copy to the section callout. Use `Add capture` guidance or copyable CLI snippets in uncovered action cells. Expected gaps should use warning/muted semantic styling and correct singular/plural grammar.

---

### `lib/threadline/operator_surface/style.ex` (config/style primitive, transform)

**Analog:** `lib/threadline/operator_surface/style.ex`

**Segmented active-state pattern** (lines 636-674):
```css
.tl-segmented {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--tl-space-1);
  padding: var(--tl-space-1);
  border: 1px solid var(--tl-color-border);
  border-radius: var(--tl-radius-lg);
  background: var(--tl-color-surface);
}

.tl-segmented__item[aria-pressed="true"] {
  background: var(--tl-color-accent-soft);
  color: var(--tl-color-accent-strong);
  box-shadow: inset 0 0 0 1px var(--tl-color-accent-border), var(--tl-shadow-subtle);
}
```

**Drawer/KV surface pattern** (lines 1868-1921):
```css
.tl-subview {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  z-index: var(--tl-z-subview);
  width: 100vw;
  min-height: 100dvh;
  overflow: auto;
  background: var(--tl-color-bg);
  box-shadow: var(--tl-shadow-raised);
  animation: tl-drawer-in var(--tl-motion-base) var(--tl-ease-standard);
}

.tl-subview__content {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--tl-space-4);
  padding: var(--tl-space-4);
}
```

**Copy affordance pattern** (lines 2005-2059):
```css
.tl-copy {
  position: relative;
  display: inline-flex;
  align-items: center;
  min-height: var(--tl-control-height-chip);
  padding: 0 var(--tl-space-2);
  border: 1px solid var(--tl-color-border);
  border-radius: var(--tl-radius-sm);
  background: transparent;
  color: var(--tl-color-muted);
  font-family: inherit;
  font-size: var(--tl-font-size-xs);
  cursor: pointer;
  transition: var(--tl-transition-fast);
}

.tl-copy.is-copied {
  color: var(--tl-color-signal);
  border-color: var(--tl-color-signal-border);
  animation: tl-copy-pulse var(--tl-motion-base) var(--tl-ease-out);
}
```

**Apply to Phase 138:** Add only narrow `.tl-*` primitives. Keep token-backed, dark-only classes under `.threadline-ui`. Add style-contract assertions for new shared classes such as value tokens, remediation actions, actor summary metadata, and dense Timeline treatment.

---

### `lib/threadline/operator_surface/script.ex` (utility, event-driven)

**Analog:** `lib/threadline/operator_surface/script.ex`

**Dependency-free copy behavior** (lines 1-15, 67-81):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Script do
    @moduledoc """
    Embeds a tiny, dependency-free copy-to-clipboard helper for the operator
    surface. Rendered once per page alongside `Threadline.OperatorSurface.Style.css/1`.

    Self-contained vanilla JS — no npm dependency, no host asset pipeline, and
    no LiveSocket hook registration. It binds a single delegated `click` listener
    (idempotent via a `window.__tlCopyBound` guard, so re-mounts don't double-bind)
    on `[data-tl-copy]` elements: it copies the attribute value to the clipboard
```

```javascript
document.addEventListener("click", function (e) {
  var btn = e.target.closest("[data-tl-copy]");
  if (!btn) return;
  var text = btn.getAttribute("data-tl-copy");
  if (!text) return;
  function flash() {
    btn.classList.add("is-copied");
    window.setTimeout(function () { btn.classList.remove("is-copied"); }, 1200);
  }
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(flash, function () { if (fallbackCopy(text)) flash(); });
  } else if (fallbackCopy(text)) {
    flash();
  }
});
```

**Apply to Phase 138:** Prefer rendering existing `[data-tl-copy]` buttons. Do not add JS hooks or a package.

---

## Test Pattern Assignments

### `test/threadline/operator_surface/presentation_test.exs` (test, transform)

**Analog:** `test/threadline/operator_surface/presentation_test.exs`

**Helper-test pattern** (lines 1-7, 58-77):
```elixir
defmodule Threadline.OperatorSurface.PresentationTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Presentation

  @now ~U[2026-06-04 12:00:00Z]
```

```elixir
describe "secondary refs" do
  test "keeps the full value in title and truncates visible text" do
    value = "actor/user-01-abcdefghijklmnopqrstuvwxyz-0123456789"

    assert %{title: ^value, visible: visible} = Presentation.secondary_ref(value, 24)
    assert visible != value
    assert String.starts_with?(visible, "actor/user")
    assert String.ends_with?(visible, "23456789")
  end
```

**Apply to Phase 138:** Add direct tests for value-token distinctions, count grammar, actor summary labels, and coverage remediation labels before or with LiveView tests.

---

### `test/threadline/operator_surface/style_contract_test.exs` (test, transform)

**Analog:** `test/threadline/operator_surface/style_contract_test.exs`

**CSS contract pattern** (lines 1-24, 37-49):
```elixir
defmodule Threadline.OperatorSurface.StyleContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"

  test "operator surface stays dark-only and token-driven" do
    src = File.read!(@style_path)

    assert String.contains?(src, "color-scheme: dark;")
    refute String.contains?(src, "prefers-color-scheme")
    refute String.contains?(src, "color-scheme: light")
  end
```

```elixir
test "prove cluster primitives stay token-backed and reusable" do
  src = File.read!(@style_path)

  assert String.contains?(src, ".tl-job-group")
  assert String.contains?(src, ".tl-job-group__header")
  assert String.contains?(src, ".tl-secondary-ref")
  assert String.contains?(src, ".tl-target-row")
```

**Apply to Phase 138:** Add a Find-cluster primitive contract test for any new `.tl-value-*`, `.tl-remediation-*`, `.tl-actor-summary`, `.tl-filter-summary`, or dense Timeline classes.

---

### LiveView tests under `test/threadline/operator_surface/`

**Timeline analog:** `test/threadline/operator_surface/live/timeline_live_test.exs`

**Mount/default URL pattern** (lines 281-288, 365-377):
```elixir
defp mount_audit(conn, path \\ "/audit/timeline") do
  case live(conn, path) do
    {:ok, _lv, _html} = ok -> ok
    {:error, {:live_redirect, %{to: redirect_path}}} -> live(conn, redirect_path)
  end
end
...
test "Case 1: First mount with no params defaults to last-24h window in URL", %{conn: conn} do
  assert {:error, {:live_redirect, %{to: redirect_path}}} = live(conn, "/audit/timeline")
  assert redirect_path =~ ~r{^/audit/timeline\?from=.+&to=.+$}

  assert {:ok, _lv, html} = live(conn, redirect_path)
  assert html =~ ~s|name="filter[from]"|
```

**HTML contract pattern** (lines 704-715):
```elixir
test "Case 16: Match-count status line renders with the visible/total count format",
     %{conn: conn} do
  table = "posts_count_status_#{System.unique_integer([:positive])}"
  for _ <- 1..7, do: seed_change!(table: table)

  {:ok, _lv, html} =
    live(conn, "/audit/timeline?from=2020-01-01T00:00&to=2099-01-01T00:00&table=#{table}")

  assert html =~ ~r/\d+ shown · 7 matches · current filter window/
  assert html =~ "tl-status"
end
```

**Transaction analog:** `test/threadline/operator_surface/transaction_live_test.exs`

**Diff data seed pattern** (lines 206-240):
```elixir
test "Case 4: Renders change row with DOM virtualization", %{conn: conn} do
  repo = Threadline.Test.Repo

  txn =
    repo.insert!(
      Threadline.Capture.AuditTransaction.changeset(%{
        txid: :rand.uniform(1_000_000_000),
        occurred_at: DateTime.utc_now()
      })
    )

  _change =
    repo.insert!(
      Threadline.Capture.AuditChange.changeset(%{
        transaction_id: txn.id,
        table_schema: "public",
        table_name: "users",
        table_pk: %{"id" => 1},
        op: "update",
        data_after: %{"id" => 1, "email" => "test@example.com"},
        changed_fields: ["email"],
        changed_from: %{"email" => "old@example.com"},
        captured_at: DateTime.utc_now()
      })
    )
```

**Row-history scoped proof pattern** (lines 324-353):
```elixir
test "scoped transaction history route hides out-of-scope row history", %{conn: conn} do
  support_time = ~U[2026-10-03 12:00:00.000000Z]
  admin_time = DateTime.add(support_time, 60, :second)
  ...
  path =
    "/audit_scoped/transactions/#{support_txn.id}/history/users/row-scoped-live?as_of=#{DateTime.to_iso8601(admin_time)}"

  assert {:ok, _lv, html} = live(conn, path)

  assert html =~ "Row history: users / #{String.slice("row-scoped-live", 0, 14)}"
  assert html =~ "Scoped Alpha"
  refute html =~ "Admin Secret"
end
```

**Actor analog:** `test/threadline/operator_surface/live/actor_live_test.exs`

**Actor stream/window pattern** (lines 162-188):
```elixir
test "Case 4: Renders transactions and deep links to incident drill-down", %{conn: conn} do
  repo = Threadline.Test.Repo

  txn =
    repo.insert!(
      Threadline.Capture.AuditTransaction.changeset(%{
        txid: :rand.uniform(1_000_000_000),
        occurred_at: DateTime.utc_now(),
        actor_ref: %{"type" => "user", "id" => "tx_test"}
      })
    )

  assert {:ok, lv, html} = live(conn, "/audit/actors/user/tx_test")
  assert html =~ "Actor: user / tx_test"
  assert html =~ "phx-viewport-top"
  assert html =~ "phx-viewport-bottom"
  assert html =~ txn.id
  assert html =~ "/audit/transactions/#{txn.id}"

  html_7d = render_click(lv, "set-window", %{"hours" => "168"})
```

**Coverage analog:** `test/threadline/operator_surface/live/coverage_live_test.exs`

**Coverage table/copy assertion pattern** (lines 114-133):
```elixir
test "renders three-bucket coverage table with operator-facing badge labels", %{conn: conn} do
  {:ok, _view, html} = live(conn, "/audit/coverage")

  assert html =~ "Coverage — schema: public"

  assert html =~ "<th>TABLE</th>"
  assert html =~ "<th>STATUS</th>"
  assert html =~ "<th>SOURCE</th>"

  assert html =~ ~r/Coverage: \d+ captured, \d+ need capture, \d+ expected gaps/

  assert html =~ ">Expected gap<"
  assert html =~ "schema_migrations"
  assert html =~ "baseline"
end
```

**Row-history component analog:** `test/threadline/operator_surface/row_history_component_test.exs`

**Component render pattern** (lines 16-30):
```elixir
test "renders error when schema is missing" do
  html =
    render_component(Threadline.OperatorSurface.Live.RowHistoryComponent, %{
      id: "test-history",
      table: "unknown_table",
      record_id: "1",
      base_path: "/audit/transactions/123",
      threadline_schemas: %{},
      repo: Threadline.Test.Repo,
      as_of: nil
    })

  assert html =~ "Row history:"
  assert html =~ "is not mapped to an Ecto schema"
end
```

---

### `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` (test, browser request-response)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts`

**Imports/mobile setup/login pattern** (lines 1-15):
```typescript
import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

test.use({ viewport: { width: 375, height: 812 }, isMobile: true });

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}
```

**Overflow/box helper pattern** (lines 17-31):
```typescript
async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

async function box(locator: Locator) {
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  return rect!;
}
```

**Dense/mobile assertion pattern** (lines 38-68):
```typescript
test("exports dense state keeps readiness hierarchy and ready-only primary action", async ({
  page,
}) => {
  await page.goto("/audit/exports");
  await expect(page.getByText("What's ready to hand off?")).toBeVisible();

  const exportJobs = page.getByTestId("export-jobs");
  ...
  const secondaryRefs = page.locator(".tl-secondary-ref");
  await expect(secondaryRefs.first()).toBeVisible();
  await expect(secondaryRefs.first()).toHaveAttribute("title", /.+/);

  const refBox = await box(secondaryRefs.first());
  expect(refBox.width).toBeLessThanOrEqual(350);
  await expectNoHorizontalOverflow(page);
});
```

**Apply to Phase 138:** Create a Find mobile spec using the same login, viewport, overflow, and bounding-box helpers. Cover Timeline row-first dense state, transaction short-result layout, Actor segmented selected state, and Coverage remediation/copy legibility.

## Shared Patterns

### Presentation Before Markup

**Source:** `lib/threadline/operator_surface/presentation.ex` lines 58-68 and 210-227
**Apply to:** Transaction, Row-history, Timeline, Actor, Coverage, and `presentation_test.exs`

Use pure helpers for derived display decisions. Do not put DB queries, route generation, or LiveView events in `Presentation`.

### URL State and Streams

**Source:** `lib/threadline/operator_surface/live/timeline_live.ex` lines 76-173; `lib/threadline/operator_surface/live/actor_live.ex` lines 174-194
**Apply to:** Timeline and Actor changes

Keep `handle_params/3`, `push_patch`, and `stream(..., reset: true)` as the source of shareable filter/window state.

### Copy Affordances

**Source:** `lib/threadline/operator_surface/script.ex` lines 67-81; `lib/threadline/operator_surface/style.ex` lines 2009-2059
**Apply to:** Long transaction IDs, correlation IDs, actor refs, table names where interactive, and Coverage CLI snippets

Render existing `[data-tl-copy]` buttons with full copy values. Do not add JavaScript dependencies.

### Token-Backed CSS

**Source:** `lib/threadline/operator_surface/style.ex` lines 636-674, 1868-1921, 2009-2059
**Apply to:** all new Phase 138 `.tl-*` primitives

Keep classes scoped under `.threadline-ui`, dark-only, and tied to existing tokens. Add `style_contract_test.exs` checks for any new reusable primitive.

### LiveView Test Harness

**Source:** `test/threadline/operator_surface/transaction_live_test.exs` lines 30-48 and 134-159; `test/threadline/operator_surface/live/coverage_live_test.exs` lines 25-74
**Apply to:** all LiveView tests

Use in-file routers/endpoints, `Phoenix.LiveViewTest`, and direct HTML assertions. Keep tests close to the surface being changed.

## No Analog Found

All target files have close analogs. The new `operator-find-mobile.spec.ts` should copy the Phase 137 Prove mobile Playwright analog.

## Metadata

**Analog search scope:** `lib/threadline/operator_surface`, `test/threadline/operator_surface`, `examples/threadline_phoenix/e2e/tests`, `lib/mix/tasks`
**Files scanned:** 60 operator-surface/test/e2e paths plus targeted Mix task references
**Pattern extraction date:** 2026-06-04
