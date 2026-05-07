# Phase 64: Raw Timeline Browse & Filter Form - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 7 (3 NEW, 4 EXTEND)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/live/timeline_live.ex` | LiveView (mount + handle_params + handle_event + render) | request-response + URL-as-state + streamed read | `lib/threadline/operator_surface/live/actor_live.ex` | role-match + flow-match (cursor-in-assigns + viewport-bottom + stream reset). Diverges on auth-scope threading and URL-as-state. |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | LiveView integration test | request-response | `test/threadline/operator_surface/live/actor_live_test.exs` | exact (same Layouts + Router + Endpoint + ConnTest harness) |
| `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` | Doc-contract test (read source files, assert string presence) | file-I/O | `test/threadline/operator_surface_doc_contract_test.exs` | exact role-match (pure ExUnit `File.read!` + `assert =~`); needs supplemental shape from `test/threadline/exploration_routing_doc_contract_test.exs` (live route literal asserts). |
| `lib/threadline/operator_surface/router.ex` | Plug+LV router macro | n/a (compile-time) | itself (line 40-46 — `live_session :threadline` block) | exact (1-line surgical insertion inside the existing block) |
| `lib/threadline/operator_surface/style.ex` | CSS module (HEEx `<style>` rendering) | static render | itself (line 33-123 — `.threadline-ui` namespaced rules + CSS variables) | exact (extend the existing `~H` block; no new module) |
| `lib/threadline/operator_surface/live/transaction_live.ex` | LiveView header back-link insertion | static render | itself (line 82 — `<div class="transaction-header">`) | exact (1-2 line edit inside existing render/1) |
| `lib/threadline/operator_surface/live/actor_live.ex` | LiveView header back-link insertion | static render | itself (line 59 — `<div class="actor-header">`) | exact (1-2 line edit inside existing render/1) |

## Pattern Assignments

### `lib/threadline/operator_surface/live/timeline_live.ex` (NEW, LiveView, request-response + URL-as-state)

**Primary analog:** `lib/threadline/operator_surface/live/actor_live.ex` — closest cursor-in-assigns + viewport-bottom + filter-change `stream(reset: true)` precedent in the codebase.
**Supporting analog:** `lib/threadline/operator_surface/live/row_history_component.ex` — datetime-local normalization shape (lines 39-50).
**Supporting analog:** `lib/threadline/operator_surface/live/transaction_live.ex` — `handle_params/3` + `push_patch` + URL parsing precedent (lines 25-71).

#### File-scope `Code.ensure_loaded?` gating (Sentry idiom)

Lift verbatim. Every new operator-surface file MUST start with this wrapper or `mix verify.compile_no_optional` regresses.

```elixir
# Source: lib/threadline/operator_surface/live/actor_live.ex:1-3,155-156
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.ActorLive do
    use Phoenix.LiveView
    # …
  end
end
```

> Same shape applies in `transaction_live.ex:1-3,148`, `row_history_component.ex:1-4,104-105`, `router.ex:1-2,49-50`, `auth.ex:1-2,63-64`, `style.ex:1-2,127-128`.

#### Repo + scope resolution at mount

Lift the repo-resolution shape verbatim from `actor_live.ex:6-7`. **Add** scope read from `:threadline_scope` (set by `Auth.on_mount/4` at `auth.ex:31, 35` — neither sibling LV currently reads it).

```elixir
# Source: lib/threadline/operator_surface/live/actor_live.ex:5-7 (repo line lifted verbatim);
#         lib/threadline/operator_surface/live/transaction_live.ex:5-7 (identical).
def mount(_params, _session, socket) do
  repo =
    socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()
  # …
end
```

```elixir
# Source: lib/threadline/operator_surface/auth.ex:29-35 (where :threadline_scope is set)
{:ok, scope} when is_map(scope) ->
  emit_telemetry(:granted, socket, scope)
  {:cont, Phoenix.Component.assign(socket, :threadline_scope, scope)}

{:ok, scope} ->
  emit_telemetry(:granted, socket, nil)
  {:cont, Phoenix.Component.assign(socket, :threadline_scope, scope)}
```

> `:threadline_scope` may be **absent** when `:authorize_fn` returns `:ok` or `true` (auth.ex:21-27 do not assign it). Read with `socket.assigns[:threadline_scope]` (bracket form) — never `socket.assigns.threadline_scope` (dot form raises `KeyError` on the absent case).

#### Datalist source — call once at mount, filter to `:covered`

```elixir
# Source: lib/threadline/health.ex:29-53 (caller-side shape; LV side follows)
audited_tables =
  Threadline.Health.trigger_coverage(repo: repo)
  |> Enum.flat_map(fn
    {:covered, name} -> [name]
    {:uncovered, _}  -> []
  end)
  |> Enum.sort()
```

> `trigger_coverage/1` runs **two raw SQL queries** (`pg_tables` + `pg_trigger` — health.ex:55-71). Cache once at mount; never call from `handle_params/3`. CONTEXT.md D-06 implicitly requires this.

#### `phx-viewport-bottom` + stream pattern (HEEx)

```heex
<!-- Source: lib/threadline/operator_surface/live/actor_live.ex:80-86 (closest match);
     lib/threadline/operator_surface/live/transaction_live.ex:90-95 (identical structure). -->
<div
  id="transactions-list"
  phx-update="stream"
  phx-viewport-top="prev-page"
  phx-viewport-bottom="next-page"
  class="viewport-container"
>
  <div :for={{dom_id, tx} <- @streams.transactions} id={dom_id} class="transaction-row">
    …
  </div>
</div>
```

> The new LV adapts to `id="timeline-list"`, `phx-update="stream"`, `phx-viewport-bottom={@cursor && JS.push("next-page", page_loading: true)}` (RESEARCH Pattern 4), `:for={{dom_id, change} <- @streams.changes}`. Uses `change.id` for `dom_id` (per `transaction_live.ex:19` — `dom_id: fn change -> "change-#{change.change_diff["id"]}" end`; new LV uses `"change-#{change.id}"` because timeline rows are full `%AuditChange{}` structs, not stored-diff shapes).

#### Cursor-in-assigns + filter-change `stream(reset: true)` pattern

Lift the structure of `set-window` (which already does filter-change reset) — the new LV's `handle_params/3` does the same job but driven by URL params instead of a click event.

```elixir
# Source: lib/threadline/operator_surface/live/actor_live.ex:101-118 (set-window — closest precedent
# for "filter changed → reset stream → clear cursor")
def handle_event("set-window", %{"hours" => hours_str}, socket) do
  hours = String.to_integer(hours_str)
  from_time = DateTime.utc_now() |> DateTime.add(-hours, :hour)

  page =
    Threadline.actor_history(socket.assigns.actor_ref,
      repo: socket.assigns.repo,
      from: from_time
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

```elixir
# Source: lib/threadline/operator_surface/live/actor_live.ex:120-136 (next-page — cursor guard pattern)
def handle_event("next-page", _, socket) do
  if socket.assigns.next_cursor do
    page =
      Threadline.actor_history(socket.assigns.actor_ref,
        repo: socket.assigns.repo,
        from: socket.assigns.from_time,
        after: socket.assigns.next_cursor
      )

    {:noreply,
     socket
     |> assign(:next_cursor, page.next_cursor)
     |> stream(:transactions, page.entries, at: -1)}
  else
    {:noreply, socket}
  end
end
```

> **Load-bearing detail (RESEARCH Pitfall 1):** the `if socket.assigns.next_cursor do` guard at line 121 *plus* the conditional `phx-viewport-bottom={@cursor && …}` together prevent the in-flight `next-page` × `stream(reset: true)` race. The new LV must clear `:cursor` to `nil` **before** calling `stream(:changes, page.entries, reset: true)` in `handle_params/3`.

#### `handle_params/3` + URL parsing (URL-as-state)

```elixir
# Source: lib/threadline/operator_surface/live/transaction_live.ex:25-71 (closest handle_params/3 precedent;
# also demonstrates :as_of datetime parsing — but with a different normalization than what TimelineLive needs)
def handle_params(params, uri, socket) do
  uri_parsed = URI.parse(uri)
  # Extract base path up to /transactions/:id
  base_path =
    case Regex.run(~r/(.*\/transactions\/[^\/]+)/, uri_parsed.path) do
      [_, path] -> path
      _ -> uri_parsed.path
    end

  socket = assign(socket, :base_path, base_path)
  # …
end
```

> **DIVERGENCE — do not copy this `as_of` parser literally.** `transaction_live.ex:40-53` parses `params["as_of"]` *without* the `:00Z` pad — it works there only because the URL is server-emitted as a full ISO8601 with offset. `TimelineLive`'s `from`/`to` come from the browser's `<input type="datetime-local">`, which submits naive `YYYY-MM-DDTHH:mm` (no seconds, no offset). Use the `RowHistoryComponent` shape below.

#### Datetime-local naive-string → UTC `DateTime` normalization (load-bearing)

Lift verbatim. This is the project's normative convention; do not invent a parallel.

```elixir
# Source: lib/threadline/operator_surface/live/row_history_component.ex:39-47
def handle_event("update-as-of", %{"as_of" => as_of_str}, socket) do
  as_of_str =
    if String.length(as_of_str) == 16, do: as_of_str <> ":00Z", else: as_of_str <> "Z"

  as_of =
    case DateTime.from_iso8601(as_of_str) do
      {:ok, dt, _} -> dt
      _ -> socket.assigns.as_of_dt
    end
  # …
```

> The pad rule: 16-char input (`"2026-05-06T14:30"`) → append `":00Z"`; otherwise append `"Z"`. Adapt to `parse_datetime_local/1` returning `{:ok, dt}` / `{:ok, nil}` (for `nil`/`""`) / `{:error, :invalid_datetime}` per RESEARCH Pattern 3.

#### `push_patch` from `phx-submit` (URL-as-state)

```elixir
# Source: lib/threadline/operator_surface/live/row_history_component.ex:49-52
path =
  "#{socket.assigns.base_path}/history/#{socket.assigns.table}/#{socket.assigns.record_id}?as_of=#{URI.encode_www_form(DateTime.to_iso8601(as_of))}"

{:noreply, push_patch(socket, to: path)}
```

> The new LV builds `to: "#{base_path}?#{URI.encode_query(sorted_pairs)}"` instead — RESEARCH "Code Examples" `build_canonical_query/1`. Default `replace: false` is correct (CONTEXT D-04: one Apply = one history entry).

#### Empty-state markup

```heex
<!-- Source: lib/threadline/operator_surface/live/transaction_live.ex:77-80 -->
<%= if @not_found do %>
  <div class="empty-state">
    <p>Transaction Not Found - The requested transaction ID does not exist or has been purged by the retention policy.</p>
  </div>
```

```heex
<!-- Source: lib/threadline/operator_surface/live/actor_live.ex:75-78 -->
<%= if @has_ever_acted and Enum.empty?(@streams.transactions.inserts) do %>
  <div class="empty-state">
    <p>No events found in the selected time window.</p>
  </div>
```

> The new LV adopts the `Enum.empty?(@streams.changes.inserts)` test from `actor_live.ex:75` and adds the unknown-table hint variant (RESEARCH "Code Examples" — defensive empty-state with `cond do` covering `@form_error`, unknown-table, and generic-empty cases).

#### `<div class="threadline-ui">` + `<Style.css />` opening

```heex
<!-- Source: lib/threadline/operator_surface/live/actor_live.ex:51-53 -->
~H"""
<div class="threadline-ui">
  <Threadline.OperatorSurface.Style.css />
  …
"""
```

> Mandatory opening for every operator-surface LV. CONTEXT.md "Established Patterns" calls this out explicitly; CSS isolation depends on it.

#### Auth scope threading (DIVERGENCE — new requirement)

The two existing LVs **do not** thread `:threadline_scope` into queries. `actor_live.ex` and `transaction_live.ex` both pass only `repo: repo` to lib calls. RESEARCH Pitfall 5 names this the highest-impact divergence:

```elixir
# NEW pattern, no analog — encode in TimelineLive per CONTEXT D-10 + BROWSE-01:
defp scope_aware_opts(socket) do
  base = [repo: socket.assigns.repo, page_size: 50]
  case socket.assigns[:threadline_scope] do
    nil   -> base
    scope -> Keyword.merge(base, scope_to_query_opts(scope))
  end
end

defp scope_to_query_opts(_scope), do: []  # passthrough today; extension point for v1.19+
```

> Phase 65 will reuse this helper from a controller (RESEARCH "Phase Forward-Compat Constraints"). Add a unit test asserting the scope path is exercised on every query (RESEARCH Wave 0 Gap).

---

### `test/threadline/operator_surface/live/timeline_live_test.exs` (NEW, LV integration test)

**Analog:** `test/threadline/operator_surface/live/actor_live_test.exs` — exact harness shape match.

#### Test harness (Layouts + Router + Endpoint + setup_all)

Lift the entire harness verbatim, renaming the test-namespaced modules from `ActorLiveTest` to `TimelineLiveTest`.

```elixir
# Source: test/threadline/operator_surface/live/actor_live_test.exs:1-79
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.ActorLiveTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Test</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end

    def render("500.html", assigns) do
      ~H"""
      Error 500: <%= inspect(assigns.reason) %>
      """
    end
  end

  defmodule Threadline.OperatorSurface.ActorLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.ActorLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.ActorLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.ActorLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.Live.ActorLiveTest do
    use ExUnit.Case, async: true
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.ActorLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.ActorLiveTest.Endpoint,
        secret_key_base: "x" |> String.duplicate(64),
        live_view: [signing_salt: "x" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.ActorLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end
    # …
```

> The test router scope must mount `threadline_operator_surface("/audit")` (line 38 above) so the new `live("/", TimelineLive, :index)` route resolves at `/audit`. RESEARCH Wave 0 Gap names this explicitly.

#### Test cases (LiveViewTest patterns)

```elixir
# Source: test/threadline/operator_surface/live/actor_live_test.exs:111-137 (Case 4 — the closest match
# to TimelineLive's "render rows + pagination + filter-reset" shape)
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

  # Test time window change
  html_7d = render_click(lv, "set-window", %{"hours" => "168"})
  assert html_7d =~ "active"

  # Verify dummy event handlers for pagination
  render_hook(lv, "prev-page", %{})
  render_hook(lv, "next-page", %{})
end
```

> Adapt: `render_submit(form_element, %{"filter" => raw_params})` instead of `render_click`; assert URL changes via `assert_patch(lv, expected_url)`; assert `html =~ "phx-viewport-bottom"`; cover BROWSE-02 filter-parity, BROWSE-03 URL round-trip + history-entry property + datetime-tz normalization + default-window, and the BROWSE-01 scope-thread test (RESEARCH Phase Requirements → Test Map). Use `live(conn, "/audit?from=…&to=…&table=…")` to assert pasted URLs reproduce the result set.

---

### `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` (NEW, doc-contract test, file-I/O)

**Analog:** `test/threadline/operator_surface_doc_contract_test.exs` — exact role-match (read source files; assert string presence with `=~` / `String.contains?`).

```elixir
# Source: test/threadline/operator_surface_doc_contract_test.exs:1-31 (entire file)
defmodule Threadline.OperatorSurfaceDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "README declares the operator surface mount macro" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "threadline_operator_surface")
  end

  test "README documents fail-closed posture and links guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "fail-closed")
    assert String.contains?(readme, "guides/operator-surface.md")
  end

  test "operator surface guide declares route literals" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "/audit/transactions/:id")
    assert String.contains?(guide, "/audit/actors/:kind/:id")
    assert String.contains?(guide, "/audit/rows/:table/:pk")
  end

  test "operator surface guide details fail-closed security and auth options" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "fail-closed")
    assert String.contains?(guide, ":authorize_fn")
    assert String.contains?(guide, ":adopter_acknowledges_unauthenticated: true")
  end
end
```

> Adapt to assert against `lib/threadline/operator_surface/router.ex` (route literal `live("/", TimelineLive, :index)`), `lib/threadline/operator_surface/live/timeline_live.ex` (ARIA labels, filter key parity, file-scope `Code.ensure_loaded?` gate, native datetime-local widget presence), and `lib/threadline/query.ex:36` (filter-key allowlist parity). RESEARCH Pattern 7 + Wave 0 Gap names the four assertion bodies (`route_literal`, `aria_labels`, `filter_key_parity`, `code_ensure_loaded_gate`, `native_widgets`).

> The third test (filter_key_parity) is the load-bearing one — RESEARCH Pattern 7: "without it, BROWSE-04's 'any future divergence between UI and API filter keys fails CI' guarantee is hollow."

---

### `lib/threadline/operator_surface/router.ex` (EXTEND, 1-line surgical edit)

**Analog:** itself, lines 40-46 — the existing `live_session :threadline` block.

```elixir
# Source: lib/threadline/operator_surface/router.ex:40-46
live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
  scope unquote(path), alias: Threadline.OperatorSurface.Live do
    live("/transactions/:id", TransactionLive, :show)
    live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
    live("/actors/:kind/:id", ActorLive, :show)
  end
end
```

> Insertion point: a single `live("/", TimelineLive, :index)` line **inside** the `scope` block. Convention: place it at the top of the route list (it is the surface root). The file-scope `Code.ensure_loaded?(Phoenix.LiveView)` wrapper at lines 1, 49-50 is preserved automatically.

---

### `lib/threadline/operator_surface/style.ex` (EXTEND, ~H block extension)

**Analog:** itself, lines 33-123 — `.threadline-ui` namespaced rules using CSS variables declared at lines 12-26.

```elixir
# Source: lib/threadline/operator_surface/style.ex:43-69 (existing namespaced block — extend in same shape)
.threadline-ui .transaction-header {
  padding: var(--tl-spacing-md);
  border-bottom: 1px solid var(--tl-color-secondary);
  margin-bottom: var(--tl-spacing-md);
}

.threadline-ui .transaction-header h2 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.threadline-ui .viewport-container {
  max-height: 600px;
  overflow-y: auto;
  border: 1px solid var(--tl-color-secondary);
  border-radius: 6px;
}

.threadline-ui .change-row {
  padding: var(--tl-spacing-md);
  border-bottom: 1px solid var(--tl-color-secondary);
}
```

> Add — but do NOT replace — rules for `.timeline-toolbar`, `.filter-form`, `.filter-error`, `.filter-hint`, `.button-cluster`, `.clear-link` per RESEARCH "Recommended Project Structure." Use existing CSS variables (`--tl-spacing-*`, `--tl-color-*`, `--tl-font-*`, lines 13-26); add new variables only if existing ones are insufficient. **No Tailwind utility classes; no new top-level selectors outside `.threadline-ui …`** (RESEARCH Anti-Patterns).

---

### `lib/threadline/operator_surface/live/transaction_live.ex` (EXTEND, 1-2 line back-link)

**Analog:** itself, line 82 — the existing `<div class="transaction-header">` markup block.

```heex
<!-- Source: lib/threadline/operator_surface/live/transaction_live.ex:82-84 -->
<div class="transaction-header">
  <h2>Transaction: <%= @bundle.transaction.id %></h2>
</div>
```

> Insert a `<.link navigate={…}>← Timeline</.link>` (or equivalent — see RESEARCH Open Question 1) inside this block, above or alongside the `<h2>`. CONTEXT D-02 says "small inline" — no new layout component, no nav-bar abstraction. The base path is the surface mount path (e.g. `/audit`); the LV does not own the literal — the link must use a relative path or pull from existing `@base_path` assigns. (`@base_path` is computed in `handle_params/3` at line 28-32 — it ends with `/transactions/:id`, so the timeline root is `String.replace(@base_path, ~r{/transactions/[^/]+$}, "")` or — preferred — pass it down explicitly.)

---

### `lib/threadline/operator_surface/live/actor_live.ex` (EXTEND, 1-2 line back-link)

**Analog:** itself, line 59 — the existing `<div class="actor-header">` markup block.

```heex
<!-- Source: lib/threadline/operator_surface/live/actor_live.ex:59-68 -->
<div class="actor-header">
  <h2>Actor: <%= @actor_ref.type %> / <%= @actor_ref.id %></h2>
  <div class="time-picker">
    Showing last
    <a href="#" phx-click="set-window" phx-value-hours="1" class={if @time_window_hours == 1, do: "active", else: ""}>1h</a>
    <a href="#" phx-click="set-window" phx-value-hours="24" class={if @time_window_hours == 24, do: "active", else: ""}>24h</a>
    <a href="#" phx-click="set-window" phx-value-hours="168" class={if @time_window_hours == 168, do: "active", else: ""}>7d</a>
    <a href="#" phx-click="set-window" phx-value-hours="720" class={if @time_window_hours == 720, do: "active", else: ""}>30d</a>
  </div>
</div>
```

> Insert a `<.link navigate={…}>← Timeline</.link>` inside this block, above or alongside the `<h2>`. `ActorLive` has no `@base_path` assign today — either add one in `mount/3` or use a hard literal scoped through a passed-in option. RESEARCH Open Question 1 lists this as resolved (`<.link navigate=…>` is the recommendation; existing `actor_live.ex:90` uses `<a href=…>` to TransactionLive which is functionally equivalent).

---

## Shared Patterns

### File-scope `Code.ensure_loaded?` gating
**Source:** every existing module under `lib/threadline/operator_surface/` (router.ex:1, auth.ex:1, style.ex:1, live/actor_live.ex:1, live/transaction_live.ex:1, live/row_history_component.ex:1)
**Apply to:** `lib/threadline/operator_surface/live/timeline_live.ex` (mandatory).
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    use Phoenix.LiveView
    # …
  end
end
```
> Enforced by `mix verify.compile_no_optional` in CI. The doc-contract test should add a `code_ensure_loaded_gate` assertion for belt-and-braces (RESEARCH Wave 0 Gap).

### Repo resolution at mount
**Source:** `lib/threadline/operator_surface/live/transaction_live.ex:6-7`, `lib/threadline/operator_surface/live/actor_live.ex:6-7` (identical)
**Apply to:** `mount/3` of `TimelineLive`.
```elixir
repo =
  socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()
```

### CSS isolation — open every render with `<div class="threadline-ui">`
**Source:** `lib/threadline/operator_surface/live/transaction_live.ex:75-76`, `lib/threadline/operator_surface/live/actor_live.ex:52-53`, `lib/threadline/operator_surface/live/row_history_component.ex:57`
**Apply to:** `render/1` of `TimelineLive`.
```heex
~H"""
<div class="threadline-ui">
  <Threadline.OperatorSurface.Style.css />
  …
"""
```

### Validation reuse — `Threadline.Query.validate_timeline_filters!/1` as single source of truth
**Source:** `lib/threadline/query.ex:130-155` + `lib/threadline/query.ex:174-198` (correlation-id rules)
**Apply to:** `handle_params/3` of `TimelineLive` (wrapped in `try/rescue ArgumentError`).
```elixir
def validate_timeline_filters!(filters) when is_list(filters) do
  for {key, value} <- filters do
    cond do
      key not in @allowed_timeline_filter_keys ->
        raise ArgumentError,
              "unknown timeline filter key #{inspect(key)}. Allowed: :repo, :table, :actor_ref, :from, :to, :correlation_id. " <>
                "See `Threadline.Query` and `Threadline.Export`."
      key == :correlation_id ->
        validate_correlation_id_filter!(value)
      true ->
        :ok
    end
  end
  :ok
end
```
> CONTEXT D-10 + RESEARCH Anti-Patterns: never invent a parallel UI-only filter dialect. The `try/rescue ArgumentError` idiom must be reused by Phase 65's controller verbatim (RESEARCH Phase Forward-Compat).

### Filter-key allowlist literal — must round-trip with form `name="filter[…]"` inputs
**Source:** `lib/threadline/query.ex:36`
```elixir
@allowed_timeline_filter_keys ~w(repo table actor_ref from to correlation_id)a
```
> The form keys are `from to table actor_kind actor_id correlation_id` — note the `actor_ref` lib key is **collapsed from** the two URL keys `actor_kind` + `actor_id` (CONTEXT D-07). The doc-contract test asserts the form-key list and the lib allowlist agree once `actor_kind` + `actor_id` collapse to `:actor_ref`.

### ActorRef construction from form params
**Source:** `lib/threadline/semantics/actor_ref.ex:35-52`
```elixir
def new(type, id \\ nil)

def new(type, _id) when type not in @types do
  {:error, :unknown_actor_type}
end

def new(:anonymous, _id) do
  {:ok, %__MODULE__{type: :anonymous, id: nil}}
end

def new(type, id) when id in [nil, ""] do
  _ = type
  {:error, :missing_actor_id}
end

def new(type, id) when is_binary(id) do
  {:ok, %__MODULE__{type: type, id: id}}
end
```
> The fixed enum: `~w(user admin service_account job system anonymous)a` (line 24). `:anonymous` is the only kind that accepts `nil`/`""` id. Form must offer `:anonymous` as a kind, must strip `actor_id` when `actor_kind=anonymous`, and must defend with `String.to_existing_atom/1` (NOT `String.to_atom/1` — see Footguns).

### Test harness shape (Layouts + Router + Endpoint + setup_all)
**Source:** `test/threadline/operator_surface/live/actor_live_test.exs:1-79`
**Apply to:** `test/threadline/operator_surface/live/timeline_live_test.exs`.
> Test router scope MUST mount `threadline_operator_surface("/audit")` so the new `live("/", TimelineLive, :index)` route resolves at `/audit`.

---

## Footguns (anti-patterns observed in analogs — DO NOT COPY)

### F-1: `String.to_atom/1` fallback on URL-supplied actor kind
**Source of bad pattern:** `lib/threadline/operator_surface/live/actor_live.ex:9-14`
```elixir
type =
  try do
    String.to_existing_atom(kind)
  rescue
    ArgumentError -> String.to_atom(kind)
  end
```
> **DO NOT COPY.** RESEARCH Pattern 6 + Anti-Patterns + Security Domain: this leaks the BEAM atom table on adversary-reachable URL params. `TimelineLive`'s `actor_kind` comes from a query string (operator-controlled but adversary-reachable on a misconfigured deployment), unlike `ActorLive`'s path param which is router-validated. Use `String.to_existing_atom/1` only; on `ArgumentError`, render the unknown-kind hint:
> ```elixir
> case String.to_existing_atom(kind) do
>   atom -> ActorRef.new(atom, id)
> rescue
>   ArgumentError -> {:error, "unknown actor kind: #{inspect(kind)}"}
> end
> ```
> The fixed enum (`user`, `admin`, `service_account`, `job`, `system`, `anonymous`) is loaded by the time the LV mounts because `Threadline.Semantics.ActorRef` is compiled (Assumption A3).

### F-2: Naive `DateTime.from_iso8601/1` without `:00Z` pad
**Source of bad pattern:** `lib/threadline/operator_surface/live/transaction_live.ex:40-53`
```elixir
as_of =
  case params["as_of"] do
    nil -> nil
    "" -> nil
    str ->
      case DateTime.from_iso8601(str) do
        {:ok, dt, _offset} -> dt
        _ -> nil
      end
  end
```
> **DO NOT COPY for `from`/`to`.** This works in `transaction_live.ex` only because `as_of` is server-emitted as a full ISO8601 with offset (see `transaction_live.ex:102` — `as_of=#{change.change_diff["captured_at"]}`). `TimelineLive`'s `from`/`to` come from the browser's `<input type="datetime-local">`, which submits naive `YYYY-MM-DDTHH:mm` (no offset). Use the `RowHistoryComponent` shape (`row_history_component.ex:39-47`) — pad to `:00Z`, then parse. RESEARCH Pitfall 2 names this the highest freelance-risk in the phase.

### F-3: Dummy / no-op `next-page` handlers
**Source of bad pattern:** `lib/threadline/operator_surface/live/transaction_live.ex:140-146`
```elixir
def handle_event("prev-page", _, socket) do
  {:noreply, socket}
end

def handle_event("next-page", _, socket) do
  {:noreply, socket}
end
```
> **DO NOT COPY.** `TransactionLive` shows a single bundle, so paging is a no-op there. `TimelineLive` is paginated; its `next-page` handler must call `Threadline.Query.timeline_page/2` with the cursor. The `actor_live.ex:120-136` shape is correct.

### F-4: Cursor passed positionally instead of by named opt
**Source of OK pattern but easy regression:** `actor_live.ex:120-136` uses `:after`/`:before` — these are correct for `Threadline.actor_history/2`. `Threadline.Query.timeline_page/2` (the lib call `TimelineLive` uses) takes `:cursor` (per `query.ex:288, 298` — `cursor: validate_timeline_cursor!(Keyword.get(opts, :cursor))`). Two different APIs; do not blindly carry over `:after`.
```elixir
# WRONG (carried from actor_live.ex):
Threadline.Query.timeline_page(filters, repo: …, after: socket.assigns.cursor)

# RIGHT (per query.ex:282-318):
Threadline.Query.timeline_page(filters, repo: …, page_size: 50, cursor: socket.assigns.cursor)
```

### F-5: Calling `Threadline.Health.trigger_coverage/1` per `handle_params/3`
**Source:** Not observed in any analog; `actor_live.ex` does not call coverage. Flag preemptively because a plan-author might "freshen" the datalist on every Apply.
> **DO NOT introduce.** `trigger_coverage/1` runs two raw SQL queries (`health.ex:55-71`). Cache once in `mount/3`. RESEARCH Pitfall 4 — mount-time cache is correct for v1.18; document the staleness limit in a code comment.

### F-6: `phx-change` driving `push_patch` per keystroke
**Source:** Not observed in any analog. `row_history_component.ex:69` uses `phx-change="update-as-of"` but it's a single-field datetime-local form, not a multi-field filter form, and the `push_patch` is fired after a single change — not per keystroke.
> **DO NOT introduce on the filter form.** CONTEXT D-04 + RESEARCH Anti-Patterns: explicit Apply only. `phx-change` is acceptable on the `actor_kind` `<select>` ONLY if it's UI-only (toggling the `actor_id` `disabled` state) and does NOT call `push_patch`. The doc-contract test should grep the LV source for `phx-change` and assert it does not appear paired with `push_patch` (RESEARCH Pitfall 3).

### F-7: Storing the cursor in the URL
**Source:** Not observed. Flag preemptively.
> **DO NOT introduce.** CONTEXT D-13 (tombstone safety): URL contains filter state only. A 6-month-old pasted URL re-resolves from "now" backward through the filter window; if the cursor were in the URL, retention purges would silently produce a stuck-empty result.

### F-8: Tailwind / utility classes / new top-level CSS selectors
**Source:** Not observed. The codebase is consistently `.threadline-ui` namespaced.
> **DO NOT introduce.** RESEARCH Anti-Patterns: extend `Threadline.OperatorSurface.Style.css/1`; do not introduce class names outside `.threadline-ui …`.

### F-9: `socket.assigns.threadline_scope` (dot form) when scope may be absent
**Source:** Not observed (no LV reads scope today). Flag preemptively.
> **DO NOT use dot access.** `auth.ex:21-27` does NOT assign `:threadline_scope` when `:authorize_fn` returns `:ok` or `true`. Use `socket.assigns[:threadline_scope]` (bracket form) — returns `nil` for the absent case (Assumption A5).

---

## Differences from analogs (planner must call out in plan tasks)

| Aspect | ActorLive (analog) | TransactionLive (analog) | TimelineLive (new) — DIFFERENCE |
|--------|--------------------|--------------------------|---------------------------------|
| Scope threading | Reads `:threadline_repo` only; ignores `:threadline_scope` | Same | **Reads `:threadline_scope` AND threads it through `scope_aware_opts/1` helper into every `Threadline.Query.timeline_page/2` call (BROWSE-01).** No precedent in analogs. |
| Filter source | URL path params (`/actors/:kind/:id`) | URL path + sub-route (`:as_of` query param) | **URL query params via `<form phx-submit="apply"> + push_patch`. URL-as-state is the entire BROWSE-03 contract.** Closest precedent: `row_history_component.ex:39-52` (datetime-local + push_patch), but for a single field. |
| Cursor key in lib API | `:after` / `:before` (`Threadline.actor_history/2`) | n/a (single bundle) | **`:cursor` (`Threadline.Query.timeline_page/2`).** Different opt name; F-4 above. |
| Page size | Lib default | n/a | **Explicit `page_size: 50` at every call site** (CONTEXT D-12). Lib default is 1000 for API/export callers. |
| Datetime parse | n/a | `from_iso8601` without `:00Z` pad (server-emitted full ISO8601) | **Pad to `:00Z` first, then parse** (browser emits naive `datetime-local`). Use the `row_history_component.ex:39-47` shape, NOT the `transaction_live.ex:40-53` shape (F-2 above). |
| Atom conversion | `String.to_existing_atom` then `String.to_atom` fallback (UNSAFE — F-1) | n/a | **`String.to_existing_atom/1` only; ArgumentError → render unknown-kind hint.** F-1 above. |
| Default time window | "last 24h" applied at mount | n/a (not time-windowed in this LV) | **"last 24h" applied server-side when no `from`/`to` URL params (CONTEXT D-11 / "Default time window").** No URL roundtrip for the default. |
| `next-page` semantics | Real (calls `actor_history` with `after:`) | Dummy `{:noreply, socket}` (F-3) | **Real (calls `Threadline.Query.timeline_page/2` with `cursor:`).** Adopt the `actor_live.ex:120-136` shape, NOT the `transaction_live.ex:140-146` shape. |
| Datalist source | None (`ActorRef` is path-param-driven) | None | **`Threadline.Health.trigger_coverage/1` filtered to `:covered` only, cached at mount** (CONTEXT D-06). New surface, no precedent in analogs. |
| Form shape | `phx-click` event handlers on inline `<a>` tags | `phx-change="update-as-of"` (single-field) | **`<form id="timeline-filters" phx-submit="apply" role="search">` with `name="filter[…]"` inputs.** New surface; closest precedent is `row_history_component.ex:69-72`. |

---

## No Analog Found

No file in scope is "no analog" — every NEW or EXTENDED file has at least a role-match precedent in the codebase. The closest-to-orphan pattern is the **scope-threading helper** (`scope_aware_opts/1` + `scope_to_query_opts/1`), which has no LV-side precedent because no v1.17 LV reads `:threadline_scope` today. The planner should treat this as a "new but small" pattern, with the auth-side source-of-truth at `auth.ex:29-35` and the helper signature locked for Phase 65 reuse.

---

## Metadata

**Analog search scope:**
- `/Users/jon/projects/threadline/lib/threadline/operator_surface/` (entire subtree — 6 files)
- `/Users/jon/projects/threadline/test/threadline/operator_surface/` (entire subtree — 5 files + `live/actor_live_test.exs`)
- `/Users/jon/projects/threadline/test/threadline/operator_surface_doc_contract_test.exs` (root-level doc-contract analog)
- `/Users/jon/projects/threadline/lib/threadline/query.ex` (filter validator + pager — lib-side source-of-truth)
- `/Users/jon/projects/threadline/lib/threadline/health.ex` (datalist source)
- `/Users/jon/projects/threadline/lib/threadline/semantics/actor_ref.ex` (actor enum + constructor)

**Files scanned:** ~14 source/test files; ~7 lib reference files.
**Pattern extraction date:** 2026-05-06
**Phoenix LiveView version assumed:** `~> 1.0` (per `mix.exs:54`, RESEARCH §"Standard Stack").

## PATTERN MAPPING COMPLETE
