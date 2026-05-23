# Phase 78: Async Exports & UI - Pattern Map

**Mapped:** 2024-05-23
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/export/worker.ex` | service | batch | `lib/threadline/operator_surface/controllers/export_controller.ex` | role-match |
| `lib/threadline/export_queue/task_supervisor.ex` | service | event-driven | `lib/threadline/storage/local.ex` | role-match |
| `lib/threadline/operator_surface/live/export_jobs_live.ex` | component | request-response | `lib/threadline/operator_surface/live/retention_history_live.ex` | exact |
| `lib/threadline/export/cleanup_task.ex` | service | batch | `lib/threadline/retention/pruner.ex` | exact |

## Pattern Assignments

### `lib/threadline/export/worker.ex` (service, batch)

**Analog:** `lib/threadline/operator_surface/controllers/export_controller.ex`

**Streaming Pattern** (lines 128-138):
```elixir
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
```
*Note: In the background worker, `Enum.reduce_while` and `Plug.Conn.chunk` will be replaced with `Stream.into(File.stream!(path))` or writing chunks to local storage via `Threadline.Storage`.*

---

### `lib/threadline/export_queue/task_supervisor.ex` (service, event-driven)

**Analog:** `lib/threadline/storage/local.ex`

**Behaviour Implementation Pattern** (lines 12-23):
```elixir
  @behaviour Threadline.Storage

  @impl true
  def put(content, opts \\ []) do
    file_id = Keyword.get_lazy(opts, :file_id, fn -> Ecto.UUID.generate() <> ".csv" end)
    path = local_path(file_id)

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, content) do
      {:ok, file_id}
    end
  end
```
*Note: Implements the `Threadline.ExportQueue` behaviour with `@impl true` and returns standardized `{:ok, ...}` or `{:error, ...}` tuples.*

---

### `lib/threadline/operator_surface/live/export_jobs_live.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/retention_history_live.ex`

**LiveView Layout & Mount Pattern** (lines 48-61):
```elixir
    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <%= if @base_path do %>
          <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
            coverage={@threadline_coverage || %{uncovered_count: 0}}
            base_path={@base_path}
          />
        <% end %>

        <main class="retention-history-page">
          <header class="page-header">
            <h2>Retention History</h2>
```

**Real-time Refresh Pattern** (lines 34-45):
```elixir
    def handle_info(:refresh, socket) do
      schedule_refresh(socket)

      runs = fetch_runs(socket)

      socket =
        Enum.reduce(runs, socket, fn run, acc_socket ->
          stream_insert(acc_socket, :runs, run)
        end)
        |> assign(:has_runs, length(runs) > 0)

      {:noreply, socket}
    end
```

**Schedule Polling Pattern** (lines 93-99):
```elixir
    defp schedule_refresh(socket) do
      interval =
        socket.assigns[:threadline_retention_poll_ms] ||
          Application.get_env(:threadline, :retention_poll_ms, 5_000)

      Process.send_after(self(), :refresh, interval)
    end
```

---

### `lib/threadline/export/cleanup_task.ex` (service, batch)

**Analog:** `lib/threadline/retention/pruner.ex`

**Background Lock & Execute Pattern** (lines 61-75):
```elixir
  @impl true
  def handle_info(:run_purge, state) do
    %{repo: repo, interval_ms: interval_ms, sleep_ms: sleep_ms} = state

    repo.checkout(fn ->
      if acquire_lock(repo) do
        try do
          Threadline.Retention.purge(repo: repo, sleep_ms: sleep_ms)
        after
          release_lock(repo)
        end
      else
        Logger.debug("threadline_retention_pruner lock held elsewhere, skipping purge")
      end
    end)

    schedule_next(interval_ms)
    {:noreply, state}
  end
```

## Shared Patterns

### Configuration and Repository Injection
**Source:** `lib/threadline/retention/pruner.ex`
**Apply to:** `CleanupTask` and `Worker`
```elixir
    repo = Keyword.fetch!(opts, :repo)
```

## Metadata

**Analog search scope:** `lib/threadline/`
**Files scanned:** 56
**Pattern extraction date:** 2024-05-23
