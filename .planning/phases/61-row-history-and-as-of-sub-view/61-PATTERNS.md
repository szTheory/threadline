# Phase 61: Row History and As-Of Sub-View - Pattern Map

**Mapped:** 2024-06-05
**Files analyzed:** 3
**Analogs found:** 2 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/router.ex` | route | request-response | `lib/threadline/operator_surface/router.ex` | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` | controller | request-response | `lib/threadline/operator_surface/live/transaction_live.ex` | exact |
| `lib/threadline/operator_surface/live/row_history_component.ex` | component | request-response | `lib/threadline/operator_surface/live/transaction_live.ex` | partial |

## Pattern Assignments

### `lib/threadline/operator_surface/router.ex` (route, request-response)

**Analog:** `lib/threadline/operator_surface/router.ex`

**Live routing pattern** (lines 38-42):
```elixir
        live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
          scope unquote(path), alias: Threadline.OperatorSurface.Live do
            live "/transactions/:id", TransactionLive, :show
            live "/actors/:kind/:id", ActorLive, :show
          end
        end
```
*(Planner note: Add the new sub-view route here inside the `scope` block using the `:history` action.)*

---

### `lib/threadline/operator_surface/live/transaction_live.ex` (controller, request-response)

**Analog:** `lib/threadline/operator_surface/live/transaction_live.ex`

**Module gating and structure pattern** (lines 1-8):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TransactionLive do
    use Phoenix.LiveView

    def mount(%{"id" => id}, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()
```
*(Planner note: Add a `handle_params/3` callback to process the `:history` action and pass URL parameters (`table_name`, `record_id`, `as_of`) to assigns.)*

**Rendering structure pattern** (lines 26-29):
```elixir
    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
```
*(Planner note: conditionally render the slide-over `RowHistoryComponent` inside this wrapper when `@live_action == :history`)*

---

### `lib/threadline/operator_surface/live/row_history_component.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/transaction_live.ex` (Structural only)

**Module gating pattern** (lines 1-3):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.RowHistoryComponent do
    use Phoenix.LiveComponent
```

**Data Fetching / Repo Selection approach** (Inferred from TransactionLive's mount, lines 6-10):
```elixir
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      case Threadline.incident_bundle(id, repo: repo, preload: :action) do
```
*(Planner note: The Component should implement `update/2` to extract `repo`, `:table`, `:record_id`, and `:as_of` from assigns, and fetch data using `Threadline.history/3` and `Threadline.as_of/4` instead of `incident_bundle/2`.)*

---

## Shared Patterns

### Module Gating (Phase 57 Contract)
**Source:** `lib/threadline/operator_surface/live/transaction_live.ex`
**Apply to:** `RowHistoryComponent`
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  # module definition
end
```

### CSS Sandbox
**Source:** `lib/threadline/operator_surface/live/transaction_live.ex`
**Apply to:** `TransactionLive` & `RowHistoryComponent` UI elements
Components must wrap their HTML inside or be part of elements leveraging `.threadline-ui` namespace and not introduce global CSS resets.

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/threadline/operator_surface/live/row_history_component.ex` | component | request-response | No other `LiveComponent` exists in the operator surface yet. The planner should refer to standard Phoenix `LiveComponent` patterns. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/**/*.ex`
**Files scanned:** 5
**Pattern extraction date:** 2024-06-05