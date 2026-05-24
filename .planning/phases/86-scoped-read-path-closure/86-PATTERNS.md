# Phase 86: Scoped Read-Path Closure - Pattern Map

**Mapped:** `2024-05-24`
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/query.ex` | query | query | `Threadline.Query.timeline/2` | exact |
| `lib/threadline/operator_surface/live/row_history_component.ex` | component | request-response | `Threadline.OperatorSurface.Live.TimelineLive` | exact |
| `lib/threadline/operator_surface/auth.ex` | middleware | request-response | `assign_exports_enabled/2` in `auth.ex` | exact |
| `lib/threadline/operator_surface/live/coverage_live.ex` | liveview | request-response | `Threadline.OperatorSurface.Auth` (denial handling) | exact |
| `lib/threadline/operator_surface/components/surface_header.ex` | component | UI rendering | conditional logic in templates | exact |
| `lib/threadline/operator_surface/coverage/on_mount.ex` | middleware | background/polling | `Auth.on_mount/4` conditional continues | partial |

## Pattern Assignments

### `lib/threadline/query.ex` (query, database queries)

**Analog:** `Threadline.Query.timeline/2`

**Core Scope Pattern** (lines 684-692):
```elixir
  def timeline(filters \\ [], opts \\ []) do
    validate_timeline_filters!(filters)
    repo = timeline_repo!(filters, opts)

    q =
      filters
      |> timeline_query()
      |> maybe_apply_scope(opts)
```

**Scope Options Pattern** (lines 722-729):
```elixir
  defp transaction_scope_opts(transaction_id, opts) do
    [
      scope: Keyword.get(opts, :scope),
      scope_query_fn: Keyword.get(opts, :scope_query_fn),
      surface: Keyword.get(opts, :surface, :transaction),
      params: %{transaction_id: transaction_id}
    ]
  end
```

---

### `lib/threadline/operator_surface/live/row_history_component.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/timeline_live.ex`

**Options Passing Pattern** (TimelineLive.ex line 430):
```elixir
        repo: socket.assigns[:threadline_repo],
        scope: socket.assigns[:threadline_scope],
        scope_query_fn: socket.assigns[:threadline_scope_query_fn],
```

---

### `lib/threadline/operator_surface/auth.ex` (middleware, request-response)

**Analog:** `assign_exports_enabled/2` in `lib/threadline/operator_surface/auth.ex`

**Auth Opt Extraction and Assignment Pattern** (lines 155-164):
```elixir
    defp assign_exports_enabled(socket, opts) do
      exports_enabled = Keyword.get(opts, :exports, true)
      export_authorize_fn = Keyword.get(opts, :export_authorize_fn)

      Phoenix.Component.assign(
        socket,
        :threadline_exports_enabled,
        exports_enabled_for_socket?(exports_enabled, export_authorize_fn, socket)
      )
    end
```

---

### `lib/threadline/operator_surface/live/coverage_live.ex` (liveview, request-response)

**Analog:** `Threadline.OperatorSurface.Auth.halt_unauthorized/2`

**Denial Halting Pattern** (lines 53-56 in `auth.ex`):
```elixir
    defp halt_unauthorized(socket, result) do
      emit_telemetry(result, socket, nil)
      {:halt, redirect(socket, to: "/")}
    end
```

*(Note: Since `CoverageLive` evaluates at `mount/3`, it can return `{:ok, push_navigate(socket, to: base_path)}` if unauthorized).*

---

### `lib/threadline/operator_surface/components/surface_header.ex` (component, UI rendering)

**Analog:** `surface_header.ex` (conditional rendering)

**Conditional Logic Pattern** (lines 20-30 in `surface_header.ex`):
```elixir
        <%= if @coverage_enabled do %>
          <%= if @coverage && @coverage.uncovered_count > 0 do %>
            <a class="surface-badge surface-badge--warn" href={"#{@base_path}/coverage"}>
              <%= @coverage.uncovered_count %> uncovered
            </a>
          <% else %>
            <a class="surface-badge surface-badge--ok" href={"#{@base_path}/coverage"}>All covered</a>
          <% end %>
        <% end %>
```

---

### `lib/threadline/operator_surface/coverage/on_mount.ex` (middleware, polling)

**Analog:** `Threadline.OperatorSurface.Coverage.OnMount`

**Conditional Skip Pattern** (lines 37-47 in `on_mount.ex`):
```elixir
      socket =
        if connected?(socket) and socket.assigns.threadline_coverage_enabled do
          ref = Process.send_after(self(), :threadline_refresh_coverage, interval)
          # ...
        else
          socket
        end
```

## Shared Patterns

### Access Control Configuration
**Source:** `lib/threadline/operator_surface/router.ex`
**Apply to:** Macro documentation
```elixir
    - `:coverage_authorize_fn` (`(Phoenix.LiveView.Socket.t() -> boolean | :ok | _)`, optional) — explicitly
      gates the Coverage dashboard. Defaults to `fn _ -> false end` (fail-closed).
```

## Metadata

**Analog search scope:** `lib/threadline/query.ex`, `lib/threadline/operator_surface/auth.ex`, `lib/threadline/operator_surface/live/*`
**Files scanned:** 10+
**Pattern extraction date:** 2024-05-24
