# Phase 60: Actor Window Screen - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/live/actor_live.ex` | component | request-response | `lib/threadline/operator_surface/live/transaction_live.ex` | exact |
| `lib/threadline/query.ex` | query | CRUD | `lib/threadline/query.ex` | exact |

## Pattern Assignments

### `lib/threadline/operator_surface/live/actor_live.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/transaction_live.ex`

**LiveView Mount and Core Setup pattern** (lines 4-20):
```elixir
    def mount(%{"id" => id}, _session, socket) do
      repo =
        socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

      case Threadline.incident_bundle(id, repo: repo, preload: :action) do
        {:error, :not_found} ->
          {:ok, assign(socket, :not_found, true)}

        {:ok, bundle} ->
          {:ok,
           socket
           |> assign(:not_found, false)
           |> assign(:bundle, bundle)
           |> stream_configure(:changes,
             dom_id: fn change -> "change-#{change.change_diff["id"]}" end
           )
           |> stream(:changes, bundle.changes)}
      end
    end
```

**Empty State UX pattern** (lines 37-41):
```elixir
          <%= if Enum.empty?(@bundle.changes) do %>
            <div class="empty-state">
              <p>No Changes Recorded</p>
            </div>
          <% else %>
```

**Infinite Scroll LiveView Streams pattern** (lines 42-50):
```elixir
            <div
              id="changes-list"
              phx-update="stream"
              phx-viewport-top="prev-page"
              phx-viewport-bottom="next-page"
              class="viewport-container"
            >
              <div :for={{dom_id, change} <- @streams.changes} id={dom_id} class="change-row">
```

---

### `lib/threadline/query.ex` (query, CRUD)

**Analog:** `lib/threadline/query.ex`

**Keyset Pagination Core pattern** (`timeline_page/2`, lines 291-320):
```elixir
  @spec timeline_page(keyword(), keyword()) :: TimelinePage.t()
  def timeline_page(filters \\ [], opts \\ []) when is_list(filters) and is_list(opts) do
    # ...
    q =
      filters
      |> timeline_query()
      |> maybe_after_timeline_cursor(cursor)
      |> limit(^page_size)

    # ...
    entries = repo.all(q)

    %TimelinePage{
      entries: entries,
      next_cursor: timeline_page_next_cursor(entries, page_size)
    }
  end
```

**Cursor filtering pattern via Fragment** (`maybe_after_timeline_cursor/2`, lines 550-564):
*(Note: For actor history operating on `AuditTransaction`, you will substitute `captured_at` with `occurred_at`)*
```elixir
  def maybe_after_timeline_cursor(query, nil), do: query

  def maybe_after_timeline_cursor(query, %{captured_at: %DateTime{} = captured_at, id: id}) do
    where(
      query,
      [ac],
      fragment(
        "(?, ?) < (?, ?)",
        ac.captured_at,
        ac.id,
        ^captured_at,
        type(^id, :binary_id)
      )
    )
  end
```

**Time Window filtering pattern** (`filter_by_from/2` and `filter_by_to/2`, lines 631-640):
```elixir
  defp filter_by_from(query, nil), do: query

  defp filter_by_from(query, %DateTime{} = from) do
    where(query, [ac], ac.captured_at >= ^from)
  end

  defp filter_by_to(query, nil), do: query

  defp filter_by_to(query, %DateTime{} = to) do
    where(query, [ac], ac.captured_at <= ^to)
  end
```

---

## Shared Patterns

### Pagination Constants & Structs
**Source:** `lib/threadline/query.ex` (and `lib/threadline/query/timeline_page.ex` if it exists)
**Apply to:** `Threadline.actor_history/2` modifications
The keyset pagination struct returning `entries` and `next_cursor` alongside explicit limit enforcement.

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File/Component | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| Time-Window Picker UI | component | request-response | No time/date picker UI component exists yet in the current codebase. Use established Datadog/Stripe patterns. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/live/**/*.ex`, `lib/threadline/query.ex`
**Files scanned:** 2 key files read fully
**Pattern extraction date:** 2024-05-24