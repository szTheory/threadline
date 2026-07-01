# Phase 185: coverage-and-audit-readiness - Pattern Map

**Mapped:** 2026-06-29
**Files analyzed:** 18
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/live/coverage_live.ex` | LiveView controller/component | request-response, event-driven | `lib/threadline/operator_surface/live/coverage_live.ex` | exact |
| `lib/threadline/operator_surface/coverage/snapshot.ex` | model/utility | transform | `lib/threadline/operator_surface/coverage/snapshot.ex` | exact |
| `lib/threadline/operator_surface/coverage/on_mount.ex` | hook/middleware | event-driven polling | `lib/threadline/operator_surface/coverage/on_mount.ex` | exact |
| `lib/threadline/health/coverage_schemas.ex` | service/utility | request-response, database validation | `lib/threadline/health/coverage_schemas.ex` | exact |
| `lib/threadline/operator_surface/presentation.ex` | presentation utility | transform | `lib/threadline/operator_surface/presentation.ex` | exact |
| `lib/threadline/operator_surface/ui.ex` | private component library | request-response rendering | `lib/threadline/operator_surface/ui.ex` | exact |
| `lib/threadline/operator_surface/style.ex` | style contract/config | render transform | `lib/threadline/operator_surface/style.ex` | exact |
| `test/threadline/operator_surface/live/coverage_live_test.exs` | LiveView test | request-response, event-driven | `test/threadline/operator_surface/live/coverage_live_test.exs` | exact |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` | docs/source contract test | static source contract | `test/threadline/operator_surface/coverage_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface/style_contract_test.exs` | style contract test | static source contract | `test/threadline/operator_surface/style_contract_test.exs` | exact |
| `test/threadline/operator_surface/coverage/on_mount_test.exs` | hook test | event-driven polling | `test/threadline/operator_surface/coverage/on_mount_test.exs` | exact |
| `test/threadline/operator_surface/copy_contract_test.exs` | copy contract test | static/runtime rendering contract | `test/threadline/operator_surface/copy_contract_test.exs` | role-match |
| `test/threadline/operator_surface/coverage_mix_test.exs` | CLI integration test | command request-response | `test/threadline/operator_surface/coverage_mix_test.exs` | role-match |
| `guides/operator-surface.md` | docs | static documentation | `guides/operator-surface.md` | exact |
| `guides/production-checklist.md` | docs | static documentation | `guides/production-checklist.md` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | Playwright test | browser event-driven | `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` | Playwright test | browser event-driven | `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts` | Playwright test | browser request-response | `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts` | role-match |

## Pattern Assignments

### `lib/threadline/operator_surface/live/coverage_live.ex` (LiveView controller/component, request-response + event-driven)

**Analog:** `lib/threadline/operator_surface/live/coverage_live.ex`

**Imports and optional dependency gate** (lines 1-12):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.CoverageLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Coverage.Snapshot
    alias Threadline.OperatorSurface.UI
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.Health.CoverageSchemas
```

**URL-backed schema validation pattern** (lines 38-64):
```elixir
def handle_params(params, uri, socket) do
  uri_parsed = URI.parse(uri)
  base_path = (uri_parsed.path || "") |> String.replace_suffix("/coverage", "")
  socket = assign(socket, :base_path, base_path)

  schema_param = Map.get(params, "schema", "public")

  if socket.assigns[:threadline_coverage_enabled] do
    case validate_schema(socket, schema_param) do
      {:ok, schema} ->
        socket =
          socket
          |> assign(:schema_param, schema)
          |> assign(:available_schemas, available_schemas(socket))
          |> assign(:form_error, nil)
          |> fetch_coverage_for_schema(schema)

        {:noreply, socket}

      {:error, message} ->
        socket =
          socket
          |> assign(:schema_param, schema_param)
          |> assign(:form_error, message)

        {:noreply, socket}
    end
```

**Form submit and refresh events** (lines 70-95):
```elixir
def handle_event("select-schema", %{"schema" => schema}, socket) do
  schema =
    case String.trim(to_string(schema)) do
      "" -> "public"
      value -> value
    end

  {:noreply,
   push_patch(socket,
     to: "#{socket.assigns.base_path}/coverage?#{URI.encode_query(%{"schema" => schema})}"
   )}
end

def handle_event("refresh", _params, socket) do
  if not socket.assigns[:threadline_coverage_enabled] do
    {:noreply, socket}
  else
    if ref = socket.assigns[:threadline_timer_ref] do
      Process.cancel_timer(ref)
    end

    schema = socket.assigns[:schema_param] || "public"
    socket = fetch_coverage_for_schema(socket, schema)
```

**Replace this old multi-block readiness surface** (lines 194-228):
```elixir
<section class="tl-trust-rail" aria-label="Audit readiness">
  <span class="tl-trust-rail__label">Audit readiness</span>
  <%= if @coverage_for_schema.uncovered_count > 0 do %>
    <span class="tl-chip tl-chip--danger"><%= @coverage_for_schema.uncovered_count %> tables need capture</span>
    <span class="tl-hint">Add capture before relying on Timeline answers for this schema.</span>
  <% else %>
    <span class="tl-chip tl-chip--success">All tracked tables covered</span>
    <span class="tl-hint">Timeline can answer from every tracked table in this schema.</span>
  <% end %>
</section>

<section class="tl-summary-grid" aria-label="Coverage summary">
  ...
</section>

<section :if={@coverage_for_schema.uncovered_count > 0} class="tl-remediation" aria-label="Coverage remediation">
  ...
</section>
```

**Keep row-level action pattern** (lines 236-288):
```elixir
<%= for table <- @coverage_for_schema.tables[:uncovered] do %>
  <% remediation = Presentation.coverage_remediation(table, schema: @schema_param) %>
  <tr class="tl-table__row--uncovered">
    <td data-label="TABLE"><code><%= table %></code></td>
    <td data-label="STATUS"><span class="tl-chip tl-chip--danger">Needs capture</span></td>
    <td data-label="SOURCE">missing trigger</td>
    <td data-label="Actions" class="tl-table__actions">
      <div class="tl-coverage-actions">
        <details class="tl-row-action tl-row-action--capture">
          <summary class="tl-row-action__summary">
            <Threadline.OperatorSurface.Components.Icon.icon name={:warning} class="tl-button__icon" />
            <span><%= remediation.label %></span>
          </summary>
          <div class="tl-row-action__body">
            <div :if={remediation.command} class="tl-command-copy">
              <code class="tl-remediation__command"><%= remediation.command %></code>
              <button :if={Threadline.OperatorSurface.Script.enabled?()} type="button" class="tl-copy tl-copy--command" data-tl-copy={remediation.command} aria-label={"Copy #{table} capture command"}>
                Copy
              </button>
            </div>
            <span class="tl-hint tl-row-action__hint"><%= remediation.follow_up %></span>
          </div>
        </details>
      </div>
    </td>
  </tr>
<% end %>
```

**Expected-gap and covered-row actions** (lines 263-285):
```elixir
<%= for table <- @coverage_for_schema.tables[:expected_uncovered] do %>
  <tr class="tl-table__row--expected" title={tooltip_for(table)}>
    <td data-label="TABLE"><code><%= table %></code></td>
    <td data-label="STATUS"><span class="tl-chip tl-chip--warning">Expected gap</span></td>
    <td data-label="SOURCE"><%= source_for(table) %></td>
    <td data-label="Actions" class="tl-table__actions">
      <div class="tl-coverage-actions">
        <span class="tl-hint">Excluded from readiness</span>
      </div>
    </td>
  </tr>
<% end %>
...
<.link navigate={timeline_table_path(@base_path, table, @schema_param)} class="tl-button tl-button--compact tl-button--secondary">
  <Threadline.OperatorSurface.Components.Icon.icon name={:search} class="tl-button__icon" />
  View activity
</.link>
```

**Private function component pattern for the schema control** (lines 305-327):
```elixir
attr(:schema, :string, required: true)
attr(:available_schemas, :list, default: [])

defp schema_form(assigns) do
  ~H"""
  <form phx-submit="select-schema" class="tl-schema-picker" aria-label="Coverage schema">
    <label class="tl-schema-picker__label" for="coverage-schema">Schema</label>
    ...
    <button type="submit" class="tl-button tl-button--secondary">Apply schema</button>
  </form>
  """
end
```

**Stale refresh policy to fix** (lines 339-353):
```elixir
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

**Timeline row-link schema behavior** (lines 383-389):
```elixir
defp timeline_table_path(base_path, table, "public") do
  "#{base_path}/timeline?#{URI.encode_query(%{"table" => table})}"
end

defp timeline_table_path(base_path, table, schema) do
  "#{base_path}/timeline?#{URI.encode_query(%{"table_schema" => schema, "table" => table})}"
end
```

Planner notes:
- Build the consolidated verdict as a private helper/component in this file unless duplication forces a private `UI` primitive.
- Native select should copy the existing `schema_form/1` attr + `~H` pattern, but replace the datalist input with `<select name="schema" id="coverage-schema">`.
- Invalid schema branch must not render stale `@coverage_for_schema` as if it belonged to the rejected URL.
- On refresh failure, preserve the previous `last_checked_at`; set only an error/stale marker.

---

### `lib/threadline/operator_surface/coverage/snapshot.ex` (model/utility, transform)

**Analog:** `lib/threadline/operator_surface/coverage/snapshot.ex`

**Snapshot fields for verdict derivation** (lines 15-20):
```elixir
defstruct covered_count: 0,
          uncovered_count: 0,
          expected_uncovered_count: 0,
          last_checked_at: nil,
          error: nil,
          tables: [covered: [], uncovered: [], expected_uncovered: []]
```

**Coverage result transform** (lines 38-61):
```elixir
def from_coverage(coverage, opts \\ []) when is_list(coverage) do
  last_checked_at = Keyword.get(opts, :last_checked_at, DateTime.utc_now())

  grouped =
    Enum.reduce(coverage, %{covered: [], uncovered: [], expected_uncovered: []}, fn
      {:covered, name}, acc -> Map.update!(acc, :covered, &[name | &1])
      {:uncovered, name}, acc -> Map.update!(acc, :uncovered, &[name | &1])
      {:expected_uncovered, name}, acc -> Map.update!(acc, :expected_uncovered, &[name | &1])
    end)

  tables = [
    covered: Enum.sort(grouped.covered),
    uncovered: Enum.sort(grouped.uncovered),
    expected_uncovered: Enum.sort(grouped.expected_uncovered)
  ]

  %__MODULE__{
    covered_count: length(grouped.covered),
    uncovered_count: length(grouped.uncovered),
    expected_uncovered_count: length(grouped.expected_uncovered),
    last_checked_at: last_checked_at,
    error: nil,
    tables: tables
  }
end
```

Planner notes:
- Use this struct as the verdict data source. Do not add a new readiness struct or storage table.
- Empty state can be derived from the three zero counts.

---

### `lib/threadline/operator_surface/coverage/on_mount.ex` (hook/middleware, event-driven polling)

**Analog:** `lib/threadline/operator_surface/coverage/on_mount.ex`

**Optional LiveView gate and hook imports** (lines 1-47):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Coverage.OnMount do
    @moduledoc """
    `live_session` `on_mount/4` callback that drives polled trigger-coverage
    for every LV in the `:threadline` session.
    """

    import Phoenix.LiveView

    alias Threadline.OperatorSurface.Coverage.Snapshot
```

**Header badge remains public-schema only** (lines 109-119):
```elixir
defp assign_initial_coverage(socket) do
  repo = resolve_repo(socket)
  now = DateTime.utc_now()

  try do
    coverage = Threadline.Health.trigger_coverage(repo: repo, schema: "public")
    snapshot = Snapshot.from_coverage(coverage, last_checked_at: now)

    socket
    |> Phoenix.Component.assign(:threadline_coverage, snapshot)
    |> Phoenix.Component.assign(:threadline_coverage_error, nil)
```

**Last-good-on-failure pattern** (lines 131-149):
```elixir
defp refresh_coverage(socket) do
  repo = resolve_repo(socket)
  now = DateTime.utc_now()

  try do
    coverage = Threadline.Health.trigger_coverage(repo: repo, schema: "public")
    snapshot = Snapshot.from_coverage(coverage, last_checked_at: now)

    socket
    |> Phoenix.Component.assign(:threadline_coverage, snapshot)
    |> Phoenix.Component.assign(:threadline_coverage_error, nil)
  rescue
    e ->
      message = Exception.message(e)
      Threadline.Telemetry.emit_health_checked_error(message)

      # Keep the previous :threadline_coverage assign untouched (last-good).
      # Set the error so the badge can render a "stale" indicator.
      Phoenix.Component.assign(socket, :threadline_coverage_error, message)
  end
end
```

Planner notes:
- Do not conflate shell `@threadline_coverage` with selected-schema `@coverage_for_schema`.
- Copy the last-good behavior into selected-schema refresh semantics in `CoverageLive`.

---

### `lib/threadline/health/coverage_schemas.ex` (service/utility, request-response + database validation)

**Analog:** `lib/threadline/health/coverage_schemas.ex`

**Validation boundary** (lines 1-10):
```elixir
defmodule Threadline.Health.CoverageSchemas do
  @moduledoc """
  Boundary helpers for user-facing trigger-coverage schema selection.

  `Threadline.Health.trigger_coverage/1` deliberately trusts programmatic callers.
  LiveView and Mix-task surfaces use this module before passing user-provided schema
  names into catalog queries.
  """

  @schema_regex ~r/\A[a-z_][a-z0-9_]{0,62}\z/
```

**Parameterized lookup pattern** (lines 27-37):
```elixir
def validate(repo, schema) when is_binary(schema) do
  if schema =~ @schema_regex do
    sql = "SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1"

    case Ecto.Adapters.SQL.query!(repo, sql, [schema]) do
      %{rows: []} -> {:error, "Schema '#{schema}' not found."}
      %{rows: _} -> {:ok, schema}
    end
  else
    {:error, "Schema '#{schema}' not found."}
  end
end
```

**Available schema list** (lines 40-55):
```elixir
@doc """
Lists non-system schemas that contain ordinary tables.
"""
@spec available(module()) :: [String.t()]
def available(repo) do
  sql = """
  SELECT DISTINCT schemaname
  FROM pg_tables
  WHERE schemaname <> 'information_schema'
    AND schemaname NOT LIKE 'pg\\_%' ESCAPE '\\'
  ORDER BY schemaname
  """

  %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [])
  List.flatten(rows)
end
```

Planner notes:
- Keep validation here, not inside `Threadline.Health.trigger_coverage/1`.
- Ensure the select options include `public` and the current valid selected schema even if `available/1` omits them.

---

### `lib/threadline/operator_surface/presentation.ex` (presentation utility, transform)

**Analog:** `lib/threadline/operator_surface/presentation.ex`

**Remediation helper and safety rule** (lines 434-459):
```elixir
@safe_generator_identifier ~r/\A[a-z_][a-z0-9_]{0,62}\z/

@spec coverage_remediation(term(), keyword()) :: %{
        label: String.t(),
        command: String.t() | nil,
        follow_up: String.t()
      }
def coverage_remediation(table_name, opts \\ []) do
  table_name = table_name |> to_string() |> String.trim()
  schema = opts |> Keyword.get(:schema, "public") |> to_string() |> String.trim()

  if schema == "public" and safe_generator_identifier?(table_name) do
    %{
      label: "Add capture",
      command: "mix threadline.gen.triggers --tables #{table_name}",
      follow_up: "Run mix threadline.verify_coverage after applying the migration."
    }
  else
    %{
      label: "Add capture",
      command: nil,
      follow_up:
        "Generate a trigger migration for #{schema}.#{table_name} after confirming the identifier; do not paste an auto-built shell command for this table."
    }
  end
end
```

**CLI command source for verifier schema flag** (`lib/mix/tasks/threadline.verify_coverage.ex` lines 15-31):
```elixir
## Usage

    mix threadline.verify_coverage
    mix threadline.verify_coverage --schema=NAME

By default, this task verifies the `"public"` schema. Pass `--schema=NAME`
to verify a non-`public` schema (e.g. `mix threadline.verify_coverage --schema=tenant_42`).
NAME is validated at the edge (regex + `pg_namespace` lookup); invalid input
exits 1 via `Mix.raise/1`.
```

Planner notes:
- Keep row command generation conservative.
- Public safe identifiers can expose copyable `mix threadline.gen.triggers --tables TABLE`.
- For verdict-level next action, name `mix threadline.verify_coverage --schema=SCHEMA` for non-public schemas and `mix threadline.verify_coverage` for public schema.

---

### `lib/threadline/operator_surface/ui.ex` (private component library, request-response rendering)

**Analog:** `lib/threadline/operator_surface/ui.ex`

**Alert primitive** (lines 107-117):
```elixir
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
```

**Page header contract** (lines 212-253):
```elixir
attr(:title, :string, default: nil)
attr(:id, :string, default: nil)
attr(:variant, :string, default: "heading", values: ~w(heading display))
slot(:heading)
slot(:lede)
slot(:meta)
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
```

**Empty and stale-state primitives** (lines 519-545, 601-607):
```elixir
def empty_state(assigns) do
  ...
  ~H"""
  <div class={["tl-empty", @variant && "tl-empty--#{@variant}", @class]} role={@role} {@rest}>
    <Icon.icon :if={@icon} name={@icon} class="tl-empty__icon" />
    <h3 :if={@title != []} ... class="tl-empty__title">
      <%= render_slot(@title) %>
    </h3>
    <div class="tl-empty__body">
      <%= render_slot(@inner_block) %>
    </div>
    <div :if={@actions != []} class="tl-empty__actions"><%= render_slot(@actions) %></div>
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

**Copy affordance pattern** (lines 390-425):
```elixir
attr(:value, :any, required: true)
attr(:copy_label, :string, required: true, doc: "aria-label specificity (D-07, no default)")

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
```

Planner notes:
- Private helpers in `CoverageLive` should follow the `attr/slot` + `~H` style.
- Use `UI.page_header`, `UI.empty_state`, and `UI.stale_banner` where they fit before adding new primitives.
- Do not add public component API for Phase 185.

---

### `lib/threadline/operator_surface/style.ex` (style contract/config, render transform)

**Analog:** `lib/threadline/operator_surface/style.ex`

**Focus-visible baseline** (lines 368-374):
```css
.threadline-ui button:focus-visible,
.threadline-ui [role="button"]:focus-visible,
.threadline-ui input:focus-visible,
.threadline-ui select:focus-visible,
.threadline-ui a:focus-visible,
.threadline-ui summary:focus-visible {
  box-shadow: var(--tl-focus-ring);
}
```

**Schema picker layout** (lines 969-984):
```css
.tl-schema-picker {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--tl-space-2);
}

.tl-schema-picker__label {
  color: var(--tl-color-muted);
  font-size: var(--tl-font-size-label);
  font-weight: var(--tl-weight-strong);
}

.tl-schema-picker__control {
  width: min(18rem, 100%);
}
```

**Coverage table and row status styles** (lines 2601-2617, 2671-2692):
```css
.tl-table {
  width: 100%;
  border-collapse: collapse;
  background: var(--tl-color-surface-raised);
}

.tl-table-wrap {
  overflow-x: auto;
  border: 1px solid var(--tl-color-border);
  border-radius: var(--tl-radius-lg);
  background: var(--tl-color-surface-raised);
  box-shadow: var(--tl-shadow-subtle);
}

.tl-table-wrap .tl-table {
  min-width: var(--tl-table-min-width);
}

.tl-table__row--uncovered,
.tl-table__row--failed {
  box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-danger);
}

.tl-table__row--expected {
  background: var(--tl-color-surface);
  color: var(--tl-color-muted);
}

.tl-table__row--covered {
  box-shadow: inset var(--tl-status-stripe-width) 0 0 var(--tl-color-success-text);
}
```

**Row remediation and command-copy layout** (lines 2897-3013):
```css
.tl-remediation {
  display: grid;
  gap: var(--tl-space-2);
}

.tl-remediation__command {
  display: inline-flex;
  align-items: center;
  max-width: 100%;
  min-height: var(--tl-control-height-compact);
  padding: var(--tl-space-1) var(--tl-space-2);
  border: 1px solid var(--tl-color-warning-border);
  border-radius: var(--tl-radius-md);
  background: var(--tl-color-warning-bg);
  color: var(--tl-color-warning-text);
  font-family: var(--tl-font-mono);
  font-size: var(--tl-font-size-label);
  line-height: var(--tl-line-label);
  overflow-wrap: anywhere;
}

.tl-coverage-actions {
  display: grid;
  gap: var(--tl-space-2);
  justify-items: start;
  min-width: 0;
  max-width: 100%;
  white-space: normal;
}

.tl-row-action__summary {
  display: inline-flex;
  align-items: center;
  gap: var(--tl-space-2);
  min-height: var(--tl-hit-area);
  width: fit-content;
  padding: var(--tl-space-1) var(--tl-space-3);
  cursor: pointer;
}

.tl-command-copy {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: start;
  gap: var(--tl-space-2);
  min-width: 0;
  max-width: 100%;
}
```

**Old page-level Coverage selectors to retire/replace** (lines 3792-3929):
```css
.tl-trust-rail {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--tl-space-2);
  padding: var(--tl-space-3);
  border: 1px solid var(--tl-color-border);
  border-radius: var(--tl-radius-lg);
  background: var(--tl-color-surface);
}

#tl-main > .tl-trust-rail {
  margin-bottom: var(--tl-space-4);
}

.tl-remediation {
  margin-bottom: var(--tl-space-4);
  border: 1px solid var(--tl-color-border);
  border-radius: var(--tl-radius-lg);
  overflow: hidden;
  background: var(--tl-color-surface-raised);
  box-shadow: var(--tl-shadow-subtle);
}
```

**Desktop coverage table contract** (lines 4339-4360):
```css
.tl-table--coverage {
  table-layout: fixed;
}

.tl-table--coverage th:nth-child(1),
.tl-table--coverage td:nth-child(1) {
  width: 22%;
}

.tl-table--coverage th:nth-child(4),
.tl-table--coverage td:nth-child(4) {
  width: 48%;
}
```

Planner notes:
- New verdict CSS should likely use a `tl-coverage-verdict` class family.
- Keep focus selectors, schema picker wrapping, command-copy wrapping, and table no-overflow rules.
- If `tl-trust-rail`, normal-branch `tl-summary-grid`, or standalone `tl-remediation` CSS is removed/replaced, update style contract tests in the same plan.

---

### `test/threadline/operator_surface/live/coverage_live_test.exs` (LiveView test, request-response + event-driven)

**Analog:** `test/threadline/operator_surface/live/coverage_live_test.exs`

**Test router and mounted surface setup** (lines 25-74):
```elixir
defmodule Threadline.OperatorSurface.CoverageLiveTest.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  require Threadline.OperatorSurface.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout,
      html: {Threadline.OperatorSurface.CoverageLiveTest.Layouts, :root}
    )
  end

  scope "/" do
    pipe_through(:browser)

    Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
      coverage_authorize_fn: &Threadline.OperatorSurface.CoverageLiveTest.Auth.authorize/1
    )
  end
end

defmodule Threadline.OperatorSurface.CoverageLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
```

**Existing success-branch assertions to flip** (lines 115-142, 196-227):
```elixir
test "renders three-bucket coverage table with operator-facing badge labels", %{conn: conn} do
  {:ok, _view, html} = live(conn, "/audit/coverage")

  assert html =~ "Audit coverage"
  assert html =~ "Schema: public"
  assert html =~ ~s|aria-label="Coverage schema"|
  assert html =~ ~s|name="schema"|
  assert html =~ "Apply schema"
  assert html =~ "<th>TABLE</th>"
  assert html =~ "<th>STATUS</th>"
  assert html =~ "<th>SOURCE</th>"
  assert html =~ ">Expected gap<"
  assert html =~ ">Covered<"
  refute html =~ "capture is complete"
  refute html =~ "complete timeline answers"
  refute html =~ "Open timeline"
end

test "success branch renders the header via UI.page_header and drops the command shell (D-12)",
     %{conn: conn} do
  {:ok, _view, html} = live(conn, "/audit/coverage")
  refute html =~ "tl-coverage-command"
  assert html =~ ~s|<header class="tl-page__header">|
  assert html =~ ~s|class="tl-page__title"|
  assert html =~ "Schema: public"
  assert html |> String.split("<h1") |> length() == 2
  assert html =~ ~s|class="tl-card--metric"|
  assert html =~ ~s|class="tl-summary-grid"|
  refute html =~ "complete timeline answers"
end
```

**Row remediation and expected-gap behavior** (lines 144-180):
```elixir
test "uncovered rows render Add capture disclosure with command and verify follow-up",
     %{conn: conn} do
  {:ok, _view, html} = live(conn, "/audit/coverage")

  assert html =~ "Add capture"
  assert html =~ ~s|<details class="tl-row-action tl-row-action--capture">|
  assert html =~ ~s|class="tl-command-copy"|
  assert html =~ "mix threadline.gen.triggers --tables"
  assert html =~ "Run mix threadline.verify_coverage after applying the migration."
  assert html =~ ~s|data-tl-copy="mix threadline.gen.triggers --tables|
end

test "expected-gap rows use expected styling and do not render Add capture", %{conn: conn} do
  {:ok, _view, html} = live(conn, "/audit/coverage")
  expected_row = Regex.run(~r/<tr class="tl-table__row--expected".*?<\/tr>/s, html) |> List.first()
  assert expected_row =~ "Expected gap"
  assert expected_row =~ "tl-chip--warning"
  refute expected_row =~ "Add capture"
end
```

**Refresh and schema URL tests** (lines 256-315):
```elixir
describe "manual refresh" do
  test "Refresh click cancels pending timer and re-fetches", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/audit/coverage")
    new_html = render_click(view, "refresh")
    assert new_html =~ "Audit coverage"
    assert new_html =~ "Schema: public"
  end
end

describe "?schema=NAME validation" do
  test "?schema=public renders coverage normally", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/audit/coverage?schema=public")
    assert html =~ "Audit coverage"
    assert html =~ "Schema: public"
  end

  test "schema picker patches to the selected schema", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/audit/coverage")
    render_submit(view, "select-schema", %{"schema" => "public"})
    assert_patch(view, "/audit/coverage?schema=public")
  end
end
```

**Non-public Timeline link fixture** (lines 317-350):
```elixir
test "non-public schema row activity links include table_schema", %{conn: conn} do
  Ecto.Adapters.SQL.query!(Threadline.Test.Repo, "CREATE SCHEMA IF NOT EXISTS tenant_demo", [])
  Ecto.Adapters.SQL.query!(
    Threadline.Test.Repo,
    "CREATE TABLE IF NOT EXISTS tenant_demo.coverage_link_target (id bigint PRIMARY KEY)",
    []
  )
  Ecto.Adapters.SQL.query!(
    Threadline.Test.Repo,
    Threadline.Capture.TriggerSQL.create_trigger("tenant_demo.coverage_link_target")
  )

  {:ok, _view, html} = live(conn, "/audit/coverage?schema=tenant_demo")

  assert html =~ "Schema: tenant_demo"
  assert html =~ "coverage_link_target"
  assert html =~ "table_schema=tenant_demo"
  assert html =~ "table=coverage_link_target"
end
```

Planner notes:
- Convert old metric/trust assertions into one-verdict assertions.
- Add cases for native `<select>`, invalid-schema recovery to public, empty schema copy, stale last-good timestamp preservation, ready with expected gaps, and no generic Timeline CTA.
- Keep LiveView tests as the primary state lattice.

---

### `test/threadline/operator_surface/coverage_doc_contract_test.exs` (docs/source contract test, static source contract)

**Analog:** `test/threadline/operator_surface/coverage_doc_contract_test.exs`

**Source paths pattern** (lines 17-27):
```elixir
@router_path "lib/threadline/operator_surface/router.ex"
@health_path "lib/threadline/health.ex"
@policy_path "lib/threadline/health/policy.ex"
@coverage_lv_path "lib/threadline/operator_surface/live/coverage_live.ex"
@coverage_schemas_path "lib/threadline/health/coverage_schemas.ex"
@on_mount_path "lib/threadline/operator_surface/coverage/on_mount.ex"
@surface_header_path "lib/threadline/operator_surface/components/surface_header.ex"
@mix_task_path "lib/mix/tasks/threadline.health.coverage.ex"
@verify_task_path "lib/mix/tasks/threadline.verify_coverage.ex"
@row_history_path "lib/threadline/operator_surface/live/row_history_component.ex"
```

**Literal pinning pattern** (lines 81-128):
```elixir
describe "three badge state literals on CoverageLive (D-32d, D-35 #5)" do
  test "coverage_live.ex renders the literal \"Covered\" badge state" do
    src = File.read!(@coverage_lv_path)
    assert String.contains?(src, ">Covered<")
  end

  test "coverage_live.ex renders the literal \"Needs capture\" badge state" do
    src = File.read!(@coverage_lv_path)
    assert String.contains?(src, ">Needs capture<")
  end

  test "coverage_live.ex renders the literal \"Expected gap\" badge state" do
    src = File.read!(@coverage_lv_path)
    assert String.contains?(src, ">Expected gap<")
  end

  test "coverage_live.ex shows Refresh affordance with phx-click=refresh" do
    src = File.read!(@coverage_lv_path)
    assert String.contains?(src, "Refresh")
    assert String.contains?(src, ~s|phx-click="refresh"|)
  end
end
```

**Security/source guard pattern** (lines 206-249):
```elixir
describe "atom-safety refute (Pitfall 11, D-35 #12)" do
  test "coverage_live.ex source does NOT call String.to_atom (atom-leak vector closed)" do
    src = File.read!(@coverage_lv_path)
    refute src =~ ~r/String\.to_atom\b/
  end
end

describe "SQL-injection refute (Pitfall 2, D-35 #13)" do
  test "coverage_live.ex source does NOT contain interpolated nspname = '#" do
    src = File.read!(@coverage_lv_path)
    refute src =~ ~r/nspname = '#/
  end
end
```

**Optional dependency gate contract** (lines 266-280):
```elixir
test "coverage_live.ex first line is the file-scope gate" do
  src = File.read!(@coverage_lv_path)
  first_line = src |> String.split("\n") |> hd()

  assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do"
end

test "on_mount.ex first line is the file-scope gate" do
  src = File.read!(@on_mount_path)
  first_line = src |> String.split("\n") |> hd()

  assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do"
end
```

Planner notes:
- Add source/docs literal pins for "Selected schema readiness", native schema select, invalid-schema recovery, stale last-good warning, row link schema behavior, and verifier command copy.
- Keep source contract tests simple and explicit.

---

### `test/threadline/operator_surface/style_contract_test.exs` (style contract test, static source contract)

**Analog:** `test/threadline/operator_surface/style_contract_test.exs`

**Existing Coverage CSS contract to update** (lines 612-641):
```elixir
assert_selector_contains(base, "#tl-main > .tl-trust-rail", [
  "margin-bottom: var(--tl-space-4);"
])

refute String.contains?(src, "tl-coverage-command"),
       ".tl-coverage-command* CSS must be deleted (D-12 flatten); the command shell is retired"

assert_selector_contains(base, ".tl-summary-grid", [
  "margin-bottom: var(--tl-space-4);"
])

assert_selector_contains(base, ".tl-table--coverage .tl-table__actions", [
  "white-space: normal;"
])

assert_selector_contains(base, ".tl-row-action__summary", [
  "min-height: var(--tl-hit-area);",
  "cursor: pointer;"
])

assert_selector_contains(base, ".tl-command-copy", [
  "grid-template-columns: minmax(0, 1fr) auto;",
  "min-width: 0;"
])
```

**Focus-visible contract** (lines 1132-1158):
```elixir
test "phase 143 focus-visible and non-color status contracts stay locked" do
  src = File.read!(@style_path)

  assert String.contains?(src, "--tl-focus-ring:")

  for selector <- [
        ".threadline-ui button:focus-visible",
        ".threadline-ui [role=\"button\"]:focus-visible",
        ".threadline-ui input:focus-visible",
        ".threadline-ui select:focus-visible",
        ".threadline-ui a:focus-visible",
        ".threadline-ui summary:focus-visible"
      ] do
    assert String.contains?(src, selector), "missing focus-visible selector #{selector}"
  end

  assert String.contains?(focus_block, "box-shadow: var(--tl-focus-ring);")
  refute Regex.match?(~r/\.threadline-ui\s+\*\s*\{[^}]*outline:\s*none/s, src)
end
```

**Large CSS section helper pattern** (lines 1815-1832):
```elixir
defp base_responsive_section(src) do
  src
  |> String.split("@media (min-width: 768px)")
  |> List.first()
end

defp media_section(src, width) do
  src
  |> String.split("@media (min-width: #{width}) {")
  |> Enum.at(1)
  |> String.split(next_media_boundary(width))
  |> List.first()
end
```

Planner notes:
- Replace old `#tl-main > .tl-trust-rail` / normal-branch `.tl-summary-grid` expectations with `tl-coverage-verdict` expectations if those selectors are removed.
- Keep row action, command-copy, table, focus, and responsive helper assertions.

---

### `test/threadline/operator_surface/coverage/on_mount_test.exs` (hook test, event-driven polling)

**Analog:** `test/threadline/operator_surface/coverage/on_mount_test.exs`

**Socket fixture and disabled/enabled branch pattern** (lines 6-42):
```elixir
def mock_socket(assigns \\ %{}) do
  %Phoenix.LiveView.Socket{
    endpoint: MyApp.Endpoint,
    router: MyApp.Router,
    assigns: Map.merge(%{__changed__: %{}}, assigns)
  }
end

describe "on_mount/4" do
  test "returns unmodified socket when threadline_coverage_enabled is false" do
    socket = mock_socket(%{threadline_coverage_enabled: false})

    assert {:cont, returned_socket} = OnMount.on_mount([], %{}, %{}, socket)

    assert returned_socket.assigns.threadline_coverage_enabled == false
    assert returned_socket.assigns.threadline_coverage == nil
    assert returned_socket.assigns.threadline_coverage_error == nil
  end

  test "starts coverage process when threadline_coverage_enabled is true (disconnected socket)" do
    socket = mock_socket(%{threadline_coverage_enabled: true})
    assert {:cont, returned_socket} = OnMount.on_mount([], %{}, %{}, socket)
    assert returned_socket.assigns.threadline_coverage_poll_ms >= 5000
    assert Map.has_key?(returned_socket.assigns, :threadline_coverage)
    refute Map.has_key?(returned_socket.assigns, :threadline_timer_ref)
  end
end
```

Planner notes:
- Keep OnMount tests focused on header public-schema polling and disabled/enabled behavior.
- Selected-schema stale refresh proof belongs in `coverage_live_test.exs`.

---

### `test/threadline/operator_surface/copy_contract_test.exs` (copy contract test, rendering/source contract)

**Analog:** `test/threadline/operator_surface/copy_contract_test.exs`

**Calm/unsafe vocabulary guard** (lines 181-239):
```elixir
test "primary shell and Home copy avoid unsafe vocabulary while keeping allowed contexts documented",
     %{conn: conn} do
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
end

test "primary Timeline copy keeps incident-pressure vocabulary calm and domain-specific",
     %{conn: conn} do
  seed_timeline_change!()
  text = conn |> render_timeline() |> visible_text()

  for unsafe <- [
        "robust",
        "seamless",
        "powerful",
        "SIEM",
        "immutable ledger",
        "compliance suite",
        "event sourcing",
        "raw storage",
        "trigger function",
        "query engine"
      ] do
    refute String.contains?(String.downcase(text), String.downcase(unsafe))
  end
end
```

**Copy-target exactness pattern** (lines 241-258):
```elixir
test "copy affordances bind every visible short ref to the full forensic value" do
  assigns = %{value: @long_correlation_id}

  html =
    rendered_to_string(~H"""
    <UI.ref value={@value} kind="correlation" copy_label="Copy correlation id" />
    """)

  visible =
    Threadline.OperatorSurface.Presentation.ref(@long_correlation_id, kind: :correlation).visible

  copy_targets = extract_copy_targets(html)

  assert visible != @long_correlation_id
  assert html =~ visible
  assert copy_targets != []
  assert Enum.all?(copy_targets, &(&1 == @long_correlation_id))
  refute Enum.member?(copy_targets, visible)
end
```

Planner notes:
- Add remediation copy guards here only if `Presentation.coverage_remediation/2` copy changes beyond CoverageLive rendering assertions.

---

### `test/threadline/operator_surface/coverage_mix_test.exs` (CLI integration test, command request-response)

**Analog:** `test/threadline/operator_surface/coverage_mix_test.exs`

**Schema flag parity test pattern** (lines 147-195):
```elixir
describe "mix threadline.verify_coverage --schema=NAME (additive flag)" do
  test "default behavior (no flag) is unchanged - same as before Phase 66" do
    result =
      try do
        capture_io(fn ->
          Mix.Tasks.Threadline.VerifyCoverage.run([])
        end)
      catch
        :exit, {:shutdown, _} -> :ok
      end

    assert result == :ok or is_binary(result)
  end

  test "--schema=public is byte-equivalent to no-flag default" do
    ...
    if is_binary(out_no_flag) and is_binary(out_with_flag) do
      assert out_no_flag == out_with_flag
    end
  end

  test "--schema=Public fails the regex (uppercase rejected)" do
    assert_raise Mix.Error, ~r/not a valid PostgreSQL identifier/, fn ->
      capture_io(fn ->
        Mix.Tasks.Threadline.VerifyCoverage.run(["--schema=Public"])
      end)
    end
  end
end
```

Planner notes:
- Usually no Phase 185 change needed here. Use as source proof that `--schema=NAME` is a valid command in UI/docs copy.

---

### `guides/operator-surface.md` (docs, static documentation)

**Analog:** `guides/operator-surface.md`

**Coverage docs section to update** (lines 277-311):
```markdown
## Coverage dashboard

The operator surface ships a polled coverage dashboard at `/audit/coverage` that wraps `Threadline.Health.trigger_coverage/1`. Every LV in the surface also renders a small "uncovered count" pill in its header so operators notice drift from any screen.

### Reading the dashboard

The dashboard renders three buckets:

- **covered** - tables that have a Threadline trigger installed.
- **uncovered** - tables that DO NOT have a trigger and are NOT marked expected.
- **expected** - tables intentionally not audited (e.g. `schema_migrations`). The `SOURCE` column shows whether the entry comes from the hardcoded baseline or from your `:expected_uncovered_tables` config.

### Multi-schema adopters

Use the visible **Schema** control on `/audit/coverage` to switch schemas. The
selected schema is still encoded in the URL so the view is shareable:

    /audit/coverage?schema=tenant_42

The schema is validated at the LV edge (regex + `pg_namespace` lookup); invalid
input renders a `Schema 'X' not found.` error. Row-level **View activity** links
carry `table_schema` for non-`public` schemas.
```

**Mix-task parity copy** (lines 336-344):
```markdown
### Mix-task parity

Capture-only adopters who do not mount the surface get the same data via:

    mix threadline.health.coverage
    mix threadline.health.coverage --json
    mix threadline.health.coverage --schema=NAME

The Mix task is a viewer (always exits 0). The CI gate is the existing `mix threadline.verify_coverage` task, which now also accepts `--schema=NAME`.
```

Planner notes:
- Rewrite "dashboard" language toward selected-schema audit readiness while preserving route and task parity.
- Document native schema selection, invalid URL recovery, stale refresh semantics, and public/non-public row links.

---

### `guides/production-checklist.md` (docs, static documentation)

**Analog:** `guides/production-checklist.md`

**Coverage drift checklist copy** (lines 21-31):
```markdown
## Coverage drift visibility

Threadline's strongest production posture comes from making coverage drift impossible to miss. After mounting the operator surface and configuring triggers, verify:

- [ ] **Surface header pill renders on every LV** - visit any operator-surface page and confirm the badge shows either "All covered" (green-muted) or "{N} uncovered" (amber). The badge link goes to `/audit/coverage`.
- [ ] **Coverage dashboard responds at `/audit/coverage`** - the page renders three buckets (covered / uncovered / expected) with a 30-second polling default.
- [ ] **Mix-task parity for capture-only paths** - `mix threadline.health.coverage` prints the same data; `mix threadline.health.coverage --json` for machine consumption.
- [ ] **Adopter-declared expected-uncovered set** - if you use Oban, vendor add-ons, or non-Threadline bookkeeping tables, declare them in `config :threadline, :health, expected_uncovered_tables: [...]`. Run `Threadline.Health.Policy.validate!/1` at boot to fail loudly on typos.
- [ ] **Telemetry alert on failure** - subscribe to `[:threadline, :health, :checked, :error]` so sustained polling failures (e.g. DB connection issues) page someone instead of silently freezing the dashboard at the last-good count.
```

Planner notes:
- Update only if Phase 185 changes operator-surface docs enough that the production checklist would become stale.

---

### `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` (Playwright test, browser event-driven)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`

**Imports, viewport matrix, and overflow helper** (lines 1-45):
```typescript
import { expect, Locator, Page, test } from "@playwright/test";

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

**Old Coverage structure helper to retarget** (lines 184-205):
```typescript
async function expectCoverageSummaryGap(page: Page, expectedPx: number) {
  await expect(
    page.getByRole("region", { name: "Audit readiness" }),
  ).toBeVisible();
  await expect(
    page.getByRole("region", { name: "Coverage summary" }),
  ).toBeVisible();

  const gap = await page.evaluate(() => {
    const rail = document.querySelector("#tl-main > .tl-trust-rail");
    const summary = document.querySelector("#tl-main > .tl-summary-grid");
    if (!rail || !summary) {
      throw new Error("Coverage readiness rail or summary missing");
    }
    return Math.round(
      summary.getBoundingClientRect().top - rail.getBoundingClientRect().bottom,
    );
  });

  expect(gap).toBeGreaterThanOrEqual(expectedPx);
}
```

**Row disclosure and copy-overlap proof** (lines 325-360):
```typescript
async function expectCoverageCaptureDisclosure(page: Page, viewportWidth: number) {
  const firstUncoveredRow = page.locator(".tl-table__row--uncovered").first();
  await expect(firstUncoveredRow).toBeVisible();

  const action = firstUncoveredRow.locator(".tl-row-action").first();
  const summary = action.locator(".tl-row-action__summary");
  await expect(summary).toBeVisible();
  await expect(summary).toContainText("Add capture");
  await summary.click();

  const command = action.locator(".tl-remediation__command");
  const copy = action.locator(".tl-copy--command");
  await expect(command).toBeVisible();
  await expect(copy).toBeVisible();

  const commandBox = await command.boundingBox();
  const copyBox = await copy.boundingBox();
  const overlaps = !(
    commandBox!.x + commandBox!.width <= copyBox!.x ||
    copyBox!.x + copyBox!.width <= commandBox!.x ||
    commandBox!.y + commandBox!.height <= copyBox!.y ||
    copyBox!.y + copyBox!.height <= commandBox!.y
  );

  expect(overlaps).toBe(false);
}
```

**Coverage route assertion to update** (lines 439-446):
```typescript
async function assertCoverage(page: Page, viewportWidth: number) {
  await expect(page.getByRole("heading", { name: /coverage/i })).toBeVisible();
  await expectCoverageSummaryGap(page, 12);
  await expectResponsiveTable(
    page.getByTestId("coverage-table"),
    viewportWidth,
  );
  await expectCoverageCaptureDisclosure(page, viewportWidth);
}
```

**Route matrix behavior** (lines 546-558):
```typescript
test("keeps every operator route usable without root horizontal overflow", async ({
  page,
}) => {
  await login(page);
  const routes = await discoverMatrixRoutes(page);

  for (const route of routes) {
    await test.step(`${viewport.name}: ${route.name}`, async () => {
      await page.goto(route.path);
      await expectOperatorChrome(page);
      await route.assertRoute(page, viewport.width);
      await expectNoHorizontalOverflow(page);
    });
  }
});
```

Planner notes:
- Retarget `expectCoverageSummaryGap` to `getByRole("region", { name: "Selected schema readiness" })` or the exact verdict accessible name.
- Add narrow assertions for visible native schema control, focus visibility, no overflow, and row disclosure layout.
- Do not expand `operator-screenshots.spec.ts` or screenshot baselines for Phase 185.

---

### `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts` (Playwright test, browser event-driven)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts`

**Focused mobile Coverage proof** (lines 103-111):
```typescript
test("coverage mobile shows Add capture remediation without horizontal overflow", async ({
  page,
}) => {
  await page.goto("/audit/coverage");

  await expect(page.getByText("Add capture").first()).toBeVisible();
  await expect(page.getByText("mix threadline.gen.triggers --tables").first()).toBeVisible();

  await expectNoHorizontalOverflow(page);
});
```

Planner notes:
- Extend this only if the narrow mobile proof is clearer here than in the route matrix.
- Keep it user-visible: schema select reachability, verdict visibility, Add capture disclosure, no horizontal overflow.

---

### `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts` (Playwright test, browser request-response)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts`

**Feature-level Coverage assertion** (lines 122-132):
```typescript
test("coverage shows the uncovered audit_events row + header badge", async ({
  page,
}) => {
  await login(page);
  await page.goto("/audit/coverage");
  const table = page.getByTestId("coverage-table");
  await expect(table).toBeVisible();
  const row = table.locator("tr", { hasText: "audit_events" });
  await expect(row).toBeVisible();
  await expect(row.getByText("Needs capture")).toBeVisible();
  await expect(page.getByText(/tables? need audit coverage/)).toBeVisible();
});
```

Planner notes:
- If changed, keep this as a deterministic feature smoke test: row exists, `Needs capture` row state exists, and header badge still exists.
- Do not use it as the full state lattice; LiveView tests should own that.

## Shared Patterns

### URL-Backed Operator State
**Sources:** `coverage_live.ex` lines 38-80, `timeline_live.ex` lines 82-105 and 248-250, `timeline_live_test.exs` lines 451-469  
**Apply to:** `CoverageLive`, `coverage_live_test.exs`

```elixir
# CoverageLive: submit form -> push_patch -> handle_params validates and loads.
def handle_event("select-schema", %{"schema" => schema}, socket) do
  {:noreply,
   push_patch(socket,
     to: "#{socket.assigns.base_path}/coverage?#{URI.encode_query(%{"schema" => schema})}"
   )}
end

# TimelineLive analog: form submit canonicalizes query state.
def handle_event("apply", %{"filter" => raw}, socket) do
  query = build_canonical_query(raw)
  {:noreply, push_patch(socket, to: "#{socket.assigns.timeline_path}?#{query}")}
end
```

### Last-Good Error Handling
**Sources:** `coverage/on_mount.ex` lines 131-149, `ui.ex` lines 601-607, `coverage_live.ex` lines 339-353  
**Apply to:** selected-schema refresh in `CoverageLive`, stale-warning tests

```elixir
rescue
  e ->
    message = Exception.message(e)
    Threadline.Telemetry.emit_health_checked_error(message)

    # Header badge pattern keeps previous coverage untouched.
    Phoenix.Component.assign(socket, :threadline_coverage_error, message)
end
```

### Schema Validation And Injection Safety
**Sources:** `coverage_schemas.ex` lines 27-37, `coverage_doc_contract_test.exs` lines 206-249, `threadline.verify_coverage.ex` lines 85-98  
**Apply to:** `CoverageLive`, docs, CLI/verifier copy

```elixir
if schema =~ @schema_regex do
  sql = "SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1"

  case Ecto.Adapters.SQL.query!(repo, sql, [schema]) do
    %{rows: []} -> {:error, "Schema '#{schema}' not found."}
    %{rows: _} -> {:ok, schema}
  end
else
  {:error, "Schema '#{schema}' not found."}
end
```

### Private Phoenix Function Components
**Sources:** `coverage_live.ex` lines 305-327, `ui.ex` lines 212-253 and 519-545  
**Apply to:** new Coverage verdict helper, schema select helper, any local UI extraction

```elixir
attr(:schema, :string, required: true)
attr(:available_schemas, :list, default: [])

defp schema_form(assigns) do
  ~H"""
  <form phx-submit="select-schema" class="tl-schema-picker" aria-label="Coverage schema">
    ...
  </form>
  """
end
```

### Row-Level Remediation
**Sources:** `presentation.ex` lines 434-459, `coverage_live.ex` lines 236-288, `style.ex` lines 2897-3013  
**Apply to:** uncovered rows, copy controls, mobile Playwright proof

```elixir
if schema == "public" and safe_generator_identifier?(table_name) do
  %{
    label: "Add capture",
    command: "mix threadline.gen.triggers --tables #{table_name}",
    follow_up: "Run mix threadline.verify_coverage after applying the migration."
  }
else
  %{
    label: "Add capture",
    command: nil,
    follow_up:
      "Generate a trigger migration for #{schema}.#{table_name} after confirming the identifier; do not paste an auto-built shell command for this table."
  }
end
```

### Accessibility And Responsive Contracts
**Sources:** `style.ex` lines 368-374, 969-984, 2897-3013; `style_contract_test.exs` lines 1132-1158; Playwright `operator-responsive-mobile-first.spec.ts` lines 39-45 and 325-360  
**Apply to:** schema select, verdict region, details summary, copy controls, table rows

```css
.threadline-ui button:focus-visible,
.threadline-ui input:focus-visible,
.threadline-ui select:focus-visible,
.threadline-ui a:focus-visible,
.threadline-ui summary:focus-visible {
  box-shadow: var(--tl-focus-ring);
}
```

### Docs And Source Contracts
**Sources:** `guides/operator-surface.md` lines 277-344, `coverage_doc_contract_test.exs` lines 17-128  
**Apply to:** operator guide, production checklist, doc contract tests

```elixir
src = File.read!(@coverage_lv_path)
assert String.contains?(src, "Audit coverage")
assert String.contains?(src, "Apply schema")
assert String.contains?(src, ~s|phx-click="refresh"|)
```

## No Analog Found

| File / Surface | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| `tl-coverage-verdict` CSS/helper family inside `CoverageLive` / `style.ex` | component/style | render transform | No exact consolidated selected-schema verdict exists yet. Use partial analogs: `CoverageLive.schema_form/1`, `UI.page_header/1`, old `.tl-trust-rail`, `.tl-card`, row-status chips, and style contract helpers. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface`, `lib/threadline/health`, `lib/mix/tasks`, `test/threadline/operator_surface`, `examples/threadline_phoenix/e2e/tests`, `guides`  
**Files scanned:** 40+ via `rg --files`, targeted `rg`, `wc -l`, and line-numbered reads  
**Project instructions:** no root `AGENTS.md`; nested `examples/threadline_phoenix/AGENTS.md` read for e2e conventions  
**Project skills:** no project-local `.codex/skills` or `.agents/skills` directories found  
**Pattern extraction date:** 2026-06-29
