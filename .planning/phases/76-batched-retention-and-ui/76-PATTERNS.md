# Phase 76: Batched Retention & UI - Pattern Map

**Mapped:** 2024-05-17 (Current Date)
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/retention/pruner.ex` | worker / task | batch / CRUD | `lib/threadline/retention.ex` | partial match |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | LiveView | request-response | `lib/threadline/operator_surface/live/coverage_live.ex` | exact |

*Note: The `threadline_retention_runs` table schema (`Threadline.Governance.RetentionRun`) and migration already exist from Phase 75 (`lib/threadline/governance/migration.ex`).*

## Pattern Assignments

### `lib/threadline/retention/pruner.ex` (worker, batch process)

**Analog:** `lib/threadline/retention.ex` (Core chunking logic)

**Core Batching Loop Pattern** (lines 80-109 in `retention.ex`):
```elixir
  defp purge_loop(repo, cutoff, batch_size, max_batches, delete_empty?) do
    {total_changes, total_txns, batches} =
      Enum.reduce_while(1..max_batches, {0, 0, 0}, fn idx, {tc, tt, _} ->
        n1 = delete_change_batch(repo, cutoff, batch_size)

        n2 =
          if delete_empty? do
            drain_orphan_batches(repo, batch_size)
          else
            0
          end

        tc = tc + n1
        tt = tt + n2

        Logger.info("threadline retention purge batch",
          deleted_changes: n1,
          deleted_transactions: n2,
          batch: idx,
          total_changes: tc,
          total_transactions: tt
        )

        if n1 == 0 and n2 == 0 do
          {:halt, {tc, tt, idx}}
        else
          {:cont, {tc, tt, idx}}
        end
      end)

    %{deleted_changes: total_changes, deleted_transactions: total_txns, batches_run: batches}
  end
```

**Subquery Deletion Chunking** (lines 111-125):
```elixir
  defp delete_change_batch(repo, cutoff, batch_size) do
    subq =
      from(ac in AuditChange,
        where: ac.captured_at < ^cutoff,
        select: ac.id,
        limit: ^batch_size
      )

    {n, _} =
      repo.delete_all(
        from(ac in AuditChange,
          where: ac.id in subquery(subq)
        )
      )

    n
  end
```
*Note for Pruner: Adapt `purge_loop` to include a `Process.sleep/1` between batches for autovacuum awareness, and wrap it in a function that inserts and updates a `Threadline.Governance.RetentionRun` record to track start/stop/duration and rows deleted.*

---

### `lib/threadline/operator_surface/live/retention_history_live.ex` (LiveView component, request-response)

**Analog:** `lib/threadline/operator_surface/live/coverage_live.ex`

**Mount & Initial State Pattern** (lines 15-28):
```elixir
    def mount(_params, _session, socket) do
      initial =
        socket.assigns[:threadline_coverage] || Snapshot.empty(DateTime.utc_now())

      socket =
        socket
        |> assign(:base_path, nil)
        |> assign(:schema_param, "public")
        |> assign(:coverage_for_schema, initial)
        |> assign(:form_error, nil)

      {:ok, socket}
    end
```

**Auto-Refresh Pattern** (lines 53-69):
```elixir
    def handle_event("refresh", _params, socket) do
      # Cancel pending timer (Pitfall 6 — manual refresh races a tick).
      if ref = socket.assigns[:threadline_timer_ref] do
        Process.cancel_timer(ref)
      end

      # ... fetch new data ...

      # Reschedule using the same interval
      interval =
        socket.assigns[:threadline_coverage_poll_ms] ||
          Application.get_env(:threadline, :coverage_poll_ms, 30_000)

      new_ref = Process.send_after(self(), :threadline_refresh_coverage, interval)
      socket = assign(socket, :threadline_timer_ref, new_ref)

      {:noreply, socket}
    end
```

**UI Layout & Empty State Pattern** (lines 71-125):
```elixir
    def render(assigns) do
      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          ...
        />

        <main class="coverage-page">
          <h2>...</h2>
          
          <p class="filter-hint">
            <a href="#" phx-click="refresh">Refresh</a>
          </p>

          <%= if @empty? do %>
            <div class="empty-state">
              No retention runs found.
            </div>
          <% else %>
            <table class="coverage-table">
              <thead>
                <tr><th>STATUS</th><th>DELETED ROWS</th><th>DURATION</th><th>DATE</th></tr>
              </thead>
              <tbody>
                <!-- ... loop over runs ... -->
              </tbody>
            </table>
          <% end %>
        </main>
      </div>
      """
    end
```

## Shared Patterns

### Database Record Tracking (Schema/CRUD)
**Source:** `lib/threadline/governance/retention_run.ex`
**Apply to:** Pruner tracking logic
```elixir
  schema "threadline_retention_runs" do
    field(:status, :string)
    field(:deleted_count, :integer)
    field(:duration_ms, :integer)
    field(:error_message, :string)
    field(:started_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
```

## Metadata

**Analog search scope:** `lib/threadline/**/*.ex`
**Files scanned:** ~70 files
**Pattern extraction date:** 2024-05-17
