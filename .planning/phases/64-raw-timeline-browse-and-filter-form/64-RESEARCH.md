# Phase 64: Raw Timeline Browse & Filter Form - Research

**Researched:** 2026-05-06
**Domain:** Phoenix LiveView form-with-URL-state + `Phoenix.LiveView.Stream` infinite scroll under the existing `threadline_operator_surface` mount
**Confidence:** HIGH

## Summary

Phase 64 ships a single new LiveView (`Threadline.OperatorSurface.Live.TimelineLive`) under the existing `threadline_operator_surface` mount macro. CONTEXT.md is exhaustive: 14 locked decisions cover route, filter form interaction, every input shape, pagination, and the canonical URL contract. The implementation surface is small (one new LiveView file, one new live route line, two existing-LiveView header edits, CSS extensions, two new test files), but four landmines deserve explicit naming in plans because none are obvious from CONTEXT alone:

1. The `phx-viewport-bottom` + `stream(reset: true)` interaction had documented races (Phoenix LiveView issues #2895 / #2994) that were resolved in **v1.0.0** — `threadline` declares `phoenix_live_view ~> 1.0`, so we are above the fix line. **Plans should still encode the correct ordering** (clear cursor *before* `stream(reset: true)`; do not service `next-page` while no cursor is set) so a future LV-version regression is caught at the unit-test layer.
2. `<input type="datetime-local">` submits a **naive** `YYYY-MM-DDTHH:mm` string — no timezone marker. The existing v1.17 `RowHistoryComponent` already handles this exact normalization (lib/threadline/operator_surface/live/row_history_component.ex:39-50): pad to `:00Z` and parse with `DateTime.from_iso8601/1`. **Plans MUST reuse that normalization shape verbatim** — inventing a parallel one is the highest-risk freelance opportunity in this phase, and the BROWSE-04 doc-contract test won't catch a wrong-timezone rendering.
3. `push_patch` with `replace: false` (the default) inflates browser history one entry per Apply click. CONTEXT.md D-04 already locks "explicit Apply submit, no `phx-change`-driven URL patches on every keystroke" — that decision *is* the mitigation. Plans must not silently introduce a `phx-change` driven `push_patch` for any field; it would corrupt BROWSE-03's "browser back/forward navigates filter history" semantics.
4. The `:authorize_fn`-returned scope is set on socket assigns by `Threadline.OperatorSurface.Auth.on_mount/4` as `:threadline_scope` (lib/threadline/operator_surface/auth.ex:31, 35), but **no existing v1.17 LiveView actually threads it into queries**. BROWSE-01 explicitly requires `TimelineLive` to thread it into `Threadline.Query.timeline_page/2` per the v1.17 auth contract. This is a small but real divergence from the visible v1.17 code precedent, and plans must encode it as a verifiable acceptance criterion (otherwise the "auth contract still applies" success criterion is silently weakened).

**Primary recommendation:** Implement `TimelineLive` as a near-clone of `ActorLive` (the closest analog: same cursor-in-assigns shape, same `stream(reset: true)` filter-change pattern, same `phx-viewport-bottom`), with the form/datalist/datetime-normalization patterns lifted verbatim from `RowHistoryComponent`. Reuse `validate_timeline_filters!/1` end-to-end and never construct a parallel filter dialect. Wire scope threading through a single helper (`scope_aware_filters/2`) that prepends `repo:` and any future scope-derived predicates so Phase 65's controller can call the same helper without re-deriving anything.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Filter input rendering, ARIA labels, datalist options | **Frontend Server (LiveView render)** | — | Native HTML widgets only; no client JS framework. |
| Filter form submit → URL → `handle_params/3` round-trip | **Frontend Server (LiveView server)** | — | URL-as-state is the entire BROWSE-03 contract; lives in the same process the form submits to. |
| Datetime-local naive-string → UTC `DateTime` normalization | **Frontend Server (LiveView server)** | — | Browser submits naive local strings (no tz); server is the only place the canonical contract is known. |
| Filter validation (`validate_timeline_filters!/1`) | **Capture/Semantics layer (lib)** | — | Single source of truth shared with API + `mix threadline.export` + Phase 65 controller. UI only consumes it. |
| Keyset pagination + `(captured_at, id)` cursor | **Capture/Semantics layer (lib)** | LiveView server (consumes) | Already implemented in `Threadline.Query.timeline_page/2`; LV holds the cursor in socket assigns and never invents its own. |
| Trigger-coverage lookup for `<datalist>` | **Operations layer (`Threadline.Health`)** | LiveView server (consumes) | LV calls `trigger_coverage/1` once at mount; filters to `:covered` only. |
| Auth scope threading | **Operator surface (Auth on_mount)** | LiveView server + lib query | Auth populates `:threadline_scope`; LV passes it into `timeline_page/2` opts. Read-only ceiling holds. |
| CSS isolation | **Operator surface (Style module)** | — | Existing `.threadline-ui` namespace + CSS variables. Extend, never replace. |
| ASCII tombstone safety (stale URLs round-trip cleanly) | **Frontend Server (LiveView server)** | — | URL contains filter state only — never a cursor — so retention purges produce a clean empty state. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix.LiveView | `~> 1.0` (project mix.exs) | Server-rendered LiveView with patch navigation | Already a declared optional dep; v1.0 closed the documented stream-reset-on-filter races. [VERIFIED: lib/mix.exs lines 53-57; phoenix_live_view CHANGELOG v1.0.0] |
| Phoenix.LiveView.Stream | bundled with LV 1.0 | Incremental row rendering for infinite scroll | Already used by `TransactionLive` and `ActorLive`; idiomatic for this exact use case. [CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4] |
| Phoenix.Component | bundled with phoenix_live_view | HEEx + assign helpers | Already used by every operator-surface module. [VERIFIED: lib/threadline/operator_surface/style.ex line 7] |
| Phoenix.LiveView.Router (`live/3`, `live_session/3`) | bundled with phoenix_live_view | Route registration inside `live_session :threadline` | Already imported by the surface router macro. [VERIFIED: lib/threadline/operator_surface/router.ex line 38] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Threadline.Query.validate_timeline_filters!/1` | n/a | Filter allowlist + correlation-id rules | Wrap in `try/rescue ArgumentError` to render inline form errors. **Single source of truth.** [VERIFIED: lib/threadline/query.ex:130-155] |
| `Threadline.Query.timeline_page/2` | n/a | Keyset paging contract | Call with `page_size: 50, cursor: …, repo: …`. [VERIFIED: lib/threadline/query.ex:282-318] |
| `Threadline.Health.trigger_coverage/1` | n/a | Datalist source | Call **once at mount** (it executes 2 raw SQL queries — see "Pitfalls"); filter `{:covered, name}` tuples only. [VERIFIED: lib/threadline/health.ex:29] |
| `Threadline.Semantics.ActorRef.new/2` | n/a | UI kind+id → struct | `:anonymous` is the only kind that accepts `nil` id. Returns `{:ok, ref}` / `{:error, :unknown_actor_type}` / `{:error, :missing_actor_id}`. [VERIFIED: lib/threadline/semantics/actor_ref.ex:35-52] |
| `Phoenix.LiveView.push_patch/2` | bundled | URL update without remount | One call per Apply submit. Default `replace: false` is correct for back/forward filter history. [CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#push_patch/2] |
| `URI.encode_query/1` | stdlib | Build canonical query string | After scrubbing empty params, encode in deterministic key order. [ASSUMED — empty-string scrub belongs to TimelineLive, not lib] |
| `DateTime.from_iso8601/1` | stdlib | Naive-local → UTC normalization | Reuse the `RowHistoryComponent` shape: pad `YYYY-MM-DDTHH:mm` to `…:00Z`, parse, take the `DateTime` from `{:ok, dt, _offset}`. [VERIFIED: lib/threadline/operator_surface/live/row_history_component.ex:39-50] |
| `LazyHTML` (test only) | `~> 0.1.0` | DOM assertions in LiveViewTest | Already a test dep. [VERIFIED: lib/mix.exs line 65] |
| `Phoenix.LiveViewTest` (`live/2`, `render_submit/2`, `element/2`) | bundled | LV integration tests | Pattern mirrors `actor_live_test.exs` setup. [VERIFIED: test/threadline/operator_surface/live/actor_live_test.exs lines 60-138] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `<input list>` + `<datalist>` (D-06) | `live_select` (Hex pkg) or custom `phx-hook` typeahead | New dep, JS, breaks the "no client framework, zero JS" constraint; CONTEXT.md D-06 locked native datalist for accessibility + zero-JS reasons. **Do not revisit in this phase.** |
| `phx-change` URL patches per keystroke | Explicit `phx-submit` (D-04) | Per-keystroke patches inflate history (one entry per character); break BROWSE-03 back/forward semantics. CONTEXT.md D-04 locks `phx-submit`. |
| Cursor in URL | Cursor in socket assigns (D-11) | URL cursor breaks tombstone safety: a 6-month-old pasted URL hits a purged cursor row and gets stuck on empty. CONTEXT.md D-11/D-13 locks assigns-only. |
| Custom UTC datepicker / `phx-hook` for tz conversion | Native `<input type="datetime-local">` + server-side `:00Z` pad (D-09) | Adds JS surface, breaks zero-JS posture, doesn't change correctness in the common-case (operator running on a workstation in the same tz as the audit window they care about). The existing `RowHistoryComponent` precedent is normative. |
| Per-pill chip remove UI | Single "Clear all" link (D-05) | Threadline has fixed structured keys, not a DSL — chips would be ceremony without payload. CONTEXT.md D-05 locks single-link clear. |

**Installation:** No new deps. Phase 64 lands in the existing `phoenix_live_view ~> 1.0` optional-dep envelope. `mix verify.compile_no_optional` MUST stay green — every new `.ex` file in `lib/threadline/operator_surface/live/` MUST be wrapped in `if Code.ensure_loaded?(Phoenix.LiveView) do … end` at file scope.

**Version verification:** `phoenix_live_view ~> 1.0` is the declared range (mix.exs line 54). The two known stream-reset-on-filter bugs (#2895, #2969-fixed; #2994 reproduction-on-main as of Jan 2024) are addressed in v1.0.0 per the upstream changelog. [VERIFIED: lib/mix.exs:54; CITED: github.com/phoenixframework/phoenix_live_view CHANGELOG v1.0.0 — "Fix attributes of existing stream items not being updated on reset", "Fix nested LiveView within streams becoming empty when reset"]

## Architecture Patterns

### System Architecture Diagram

```
                            ┌──────────────────────────────────────┐
   Operator browser   ───►  │ GET /audit?from=…&to=…&table=…&…     │  (URL is shareable; paste into Slack)
                            └────────────┬─────────────────────────┘
                                         │
                                         ▼
                            ┌──────────────────────────────────────┐
                            │ Phoenix Router                       │
                            │  pipe_through :admin_browser         │
                            │  threadline_operator_surface "/audit"│
                            │    live "/" TimelineLive, :index     │  (NEW route — added inside live_session :threadline)
                            └────────────┬─────────────────────────┘
                                         │
                                         ▼
                            ┌──────────────────────────────────────┐
                            │ Threadline.OperatorSurface.Auth      │
                            │   on_mount/4                         │
                            │   • :authorize_fn.(socket)           │
                            │   • assigns ← :threadline_scope      │  ◄── BROWSE-01: must be threaded into queries
                            │   • assigns ← :threadline_repo       │
                            └────────────┬─────────────────────────┘
                                         │
                                         ▼
   ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
   │ TimelineLive                                                                                │
   │                                                                                             │
   │  mount/3 ── Health.trigger_coverage/1 ─► assign :audited_tables (covered only)              │
   │                                                                                             │
   │  handle_params/3                                                                            │
   │    • parse params into a filter keyword (raw strings)                                       │
   │    • normalize datetime-locals to UTC DateTime (pad ":00Z", DateTime.from_iso8601/1)        │
   │    • collapse actor_kind + actor_id ─► ActorRef.new/2 ─► :actor_ref keyword                 │
   │    • try/rescue ArgumentError around validate_timeline_filters!/1                           │
   │    • on success: clear cursor, stream(reset: true) page.entries                             │
   │    • on validation error: assign :form_error, do not query                                  │
   │                                                                                             │
   │  render/3                                                                                   │
   │    <div class="threadline-ui"> + Style.css                                                  │
   │      <header class="timeline-toolbar"> ← Inline back-link added on TransactionLive/ActorLive│
   │        <form id="timeline-filters" phx-submit="apply" role="search">                        │
   │          datetime-local × 2  +  table input+datalist  +                                     │
   │          actor_kind select  +  actor_id text  +  correlation_id text                        │
   │          [Clear all link]  [Apply button]            ◄── Phase 65 will append [CSV] [JSON]  │
   │        </form>                                                                              │
   │      </header>                                                                              │
   │      <div phx-update="stream" phx-viewport-bottom="next-page" class="viewport-container">   │
   │        <div :for={{dom_id, change} <- @streams.changes} id={dom_id}>…</div>                 │
   │      </div>                                                                                 │
   │      empty-state if streams empty                                                           │
   │      hint if @unknown_table_attempted (e.g. "no audited table named X — known: posts, …")   │
   │                                                                                             │
   │  handle_event "apply"  ─► encode params (scrub empty) ─► push_patch(to: "/audit?…")         │
   │  handle_event "next-page" if next_cursor ─► timeline_page(after: cursor) ─► stream(at: -1)  │
   └─────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
                            ┌──────────────────────────────────────┐
                            │ Threadline.Query.timeline_page/2     │  ◄── lib/threadline/query.ex:282-318
                            │   • validates filters (allowlist)    │
                            │   • returns %TimelinePage{           │
                            │       entries, next_cursor}          │
                            └────────────┬─────────────────────────┘
                                         │
                                         ▼
                            PostgreSQL (audit_changes ⋈ audit_transactions ⋈ audit_actions?)
```

### Recommended Project Structure
```
lib/threadline/operator_surface/
├── router.ex                         # MODIFY: add `live("/", TimelineLive, :index)` to live_session :threadline block (1 line)
├── auth.ex                           # NO CHANGE
├── style.ex                          # MODIFY: extend with .timeline-toolbar, .filter-form, .filter-error, .filter-hint, .button-cluster, .clear-link rules
└── live/
    ├── transaction_live.ex           # MODIFY: add inline `← Timeline` back-link in transaction-header (1-2 lines in render/2)
    ├── actor_live.ex                 # MODIFY: add inline `← Timeline` back-link in actor-header (1-2 lines in render/2)
    ├── row_history_component.ex      # NO CHANGE
    └── timeline_live.ex              # NEW: mount + handle_params + handle_event + render

test/threadline/operator_surface/
├── timeline_browse_doc_contract_test.exs  # NEW: BROWSE-04 — route literal, ARIA labels, filter key parity
└── live/
    └── timeline_live_test.exs        # NEW: mount + filter-apply + URL round-trip + datetime-tz norm + stream-reset + scope thread
```

### Pattern 1: File-scope `Code.ensure_loaded?` gating (Sentry idiom)

**What:** Wrap the entire LiveView module in a top-level conditional so it does not exist when `Phoenix.LiveView` is absent.
**When to use:** Every new file under `lib/threadline/operator_surface/`. Enforced by `mix verify.compile_no_optional` in CI.
**Example:**
```elixir
# Source: lib/threadline/operator_surface/live/transaction_live.ex line 1; lib/threadline/operator_surface/live/actor_live.ex line 1; lib/threadline/operator_surface/router.ex line 1
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    use Phoenix.LiveView
    # …
  end
end
```

### Pattern 2: Repo + scope resolution at mount

**What:** Pull the repo from socket assigns (set by `Auth.on_mount/4`) with an Application-config fallback, and read the auth-derived scope.
**When to use:** Top of `mount/3`.
**Example:**
```elixir
# Source: lib/threadline/operator_surface/live/transaction_live.ex lines 6-7; lib/threadline/operator_surface/live/actor_live.ex lines 6-7
def mount(_params, _session, socket) do
  repo =
    socket.assigns[:threadline_repo] ||
      Application.get_env(:threadline, :ecto_repos) |> hd()

  scope = socket.assigns[:threadline_scope]  # may be nil if :authorize_fn returned :ok | true

  audited_tables =
    repo
    |> Threadline.Health.trigger_coverage()
    |> Enum.flat_map(fn
      {:covered, name} -> [name]
      {:uncovered, _}  -> []
    end)
    |> Enum.sort()

  {:ok,
   socket
   |> assign(:repo, repo)
   |> assign(:scope, scope)
   |> assign(:audited_tables, audited_tables)
   |> assign(:cursor, nil)
   |> stream_configure(:changes, dom_id: fn change -> "change-#{change.id}" end)
   |> stream(:changes, [])}  # filled in handle_params/3
end
```

### Pattern 3: Datetime-local naive string → UTC DateTime normalization

**What:** Browser submits `"2026-05-06T14:30"` (no seconds, no tz). Pad to `"2026-05-06T14:30:00Z"` and parse.
**When to use:** Every parse of `from` / `to` URL params. **Reuse the existing v1.17 shape verbatim.**
**Example:**
```elixir
# Source: lib/threadline/operator_surface/live/row_history_component.ex lines 39-47 (adapted)
defp parse_datetime_local(nil), do: {:ok, nil}
defp parse_datetime_local(""),  do: {:ok, nil}

defp parse_datetime_local(str) when is_binary(str) do
  padded = if String.length(str) == 16, do: str <> ":00Z", else: str <> "Z"

  case DateTime.from_iso8601(padded) do
    {:ok, dt, _offset} -> {:ok, dt}
    _ -> {:error, :invalid_datetime}
  end
end
```

> **Open caveat:** The existing component implicitly treats the naive string as **UTC** (it pads `Z`, not the operator's local offset). This is consistent across the codebase but does mean an operator in PST who types "14:30" gets a UTC interpretation, not "14:30 PST". For an internal operator surface this is the established convention; do not change it in this phase. If product feedback ever surfaces real confusion, address it as its own phase. [ASSUMED: documented intent — see `Threadline.OperatorSurface.Live.RowHistoryComponent` line 41-50; the naive-local convention is not commented in code]

### Pattern 4: `phx-viewport-bottom` infinite scroll over `Phoenix.LiveView.Stream`

**What:** Mount streams the first page; viewport-bottom fires `next-page`; the handler appends with `at: -1`; on filter change the handler does `stream(reset: true)` and clears the cursor.
**When to use:** The whole timeline list rendering.
**Example:**
```heex
<!-- Source: lib/threadline/operator_surface/live/transaction_live.ex lines 90-95 (adapted); lib/threadline/operator_surface/live/actor_live.ex lines 80-86 (adapted) -->
<div
  id="timeline-list"
  phx-update="stream"
  phx-viewport-bottom={@cursor && JS.push("next-page", page_loading: true)}
  class="viewport-container"
>
  <div :for={{dom_id, change} <- @streams.changes} id={dom_id} class="change-row">
    …
  </div>
</div>
```

```elixir
# Source: lib/threadline/operator_surface/live/actor_live.ex lines 101-138 (adapted for timeline)
def handle_event("next-page", _, socket) do
  if socket.assigns.cursor do
    page =
      Threadline.Query.timeline_page(
        socket.assigns.filters,
        repo: socket.assigns.repo,
        page_size: 50,
        cursor: socket.assigns.cursor
      )

    {:noreply,
     socket
     |> assign(:cursor, page.next_cursor)
     |> stream(:changes, page.entries, at: -1)}
  else
    {:noreply, socket}
  end
end
```

> **Conditional binding is load-bearing.** The `@cursor && JS.push(…)` guard prevents `next-page` from firing once the last page is reached. The Phoenix LiveView upstream pattern (`@end_of_timeline?` check in the canonical example) is identical in spirit. [CITED: github.com/phoenixframework/phoenix_live_view/blob/main/guides/client/bindings.md — "UI for Infinite Scrolling List" example]

### Pattern 5: URL-as-state via `push_patch` from `phx-submit`

**What:** Apply submit collects form params, scrubs empties, and `push_patch`es to the canonical URL; `handle_params/3` parses, validates, queries, and resets the stream.
**When to use:** The Apply button. **NOT** for `phx-change` — that would re-introduce the per-keystroke history-inflation problem.
**Example:**
```elixir
def handle_event("apply", %{"filter" => raw}, socket) do
  query = build_canonical_query(raw)  # scrubs empties; collapses anonymous; deterministic key order
  {:noreply, push_patch(socket, to: "#{socket.assigns.base_path}?#{query}")}
end

def handle_event("apply", _params, socket) do
  # Defensive: phx-submit fired without a "filter" key (e.g., malformed manual POST)
  {:noreply, push_patch(socket, to: socket.assigns.base_path)}
end

def handle_params(params, _uri, socket) do
  with {:ok, raw}     <- normalize_params(params),                # datetime-local pad, atom keys
       {:ok, filters} <- collapse_actor_ref(raw),                 # actor_kind + actor_id → :actor_ref
       :ok            <- safe_validate(filters) do                # try/rescue ArgumentError
    page =
      Threadline.Query.timeline_page(filters,
        repo: socket.assigns.repo,
        page_size: 50
      )

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:cursor, page.next_cursor)
     |> assign(:form_error, nil)
     |> stream(:changes, page.entries, reset: true)}
  else
    {:error, message} ->
      {:noreply,
       socket
       |> assign(:form_error, message)
       |> stream(:changes, [], reset: true)}
  end
end
```

> **`replace: false` is the correct default.** Each Apply produces one history entry → browser back/forward navigates filter history (BROWSE-03). [CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#push_patch/2 — "the flag to replace the current history or push a new state. Defaults `false`"]

### Pattern 6: Anonymous actor_kind disabling

**What:** When `actor_kind=anonymous`, the `actor_id` input must visually disable AND the submitted value must be ignored server-side (defense in depth — never trust the client).
**When to use:** Render-time disabling for affordance; server-side stripping for correctness.
**Example:**
```heex
<input
  type="text"
  name="filter[actor_id]"
  id="filter-actor-id"
  aria-label="actor id"
  value={@filters[:actor_id_raw] || ""}
  disabled={@filters[:actor_kind_raw] == "anonymous"}
  phx-debounce="blur"
/>
```

```elixir
defp collapse_actor_ref(%{actor_kind: "anonymous"} = raw) do
  {:ok, raw |> Map.delete(:actor_id) |> Map.put(:actor_ref, %ActorRef{type: :anonymous, id: nil})}
end

defp collapse_actor_ref(%{actor_kind: kind, actor_id: id}) when is_binary(kind) and kind != "" do
  case ActorRef.new(String.to_existing_atom(kind), id) do
    {:ok, ref}                       -> {:ok, %{actor_ref: ref}}
    {:error, :missing_actor_id}      -> {:error, "actor id is required for non-anonymous actors"}
    {:error, :unknown_actor_type}    -> {:error, "unknown actor kind: #{inspect(kind)}"}
  end
rescue
  ArgumentError -> {:error, "unknown actor kind: #{inspect(kind)}"}
end

defp collapse_actor_ref(raw), do: {:ok, raw}  # no actor filter
```

> Use `String.to_existing_atom/1` (not `String.to_atom/1`) to avoid an attacker-induced atom-table leak via crafted `actor_kind` URL params. The fixed enum (`user`, `admin`, `service_account`, `job`, `system`, `anonymous`) is already loaded by the time the LV mounts because `Threadline.Semantics.ActorRef` is compiled. The existing `ActorLive` uses an unsafe fallback (lib/threadline/operator_surface/live/actor_live.ex lines 10-14: `try String.to_existing_atom rescue ArgumentError -> String.to_atom`) — **do not copy that fallback** in `TimelineLive`; `ActorLive`'s URL is a path param that already passes through the router, while `TimelineLive`'s comes from query strings that are operator-controlled but adversary-reachable on a misconfigured deployment.

### Pattern 7: Doc-contract test (BROWSE-04)

**What:** A pure `ExUnit.Case, async: true` test that reads a literal file (e.g. router.ex source, or live module source) and asserts string presence — same shape as `OperatorSurfaceDocContractTest`.
**When to use:** Lock the route literal, the form ARIA labels, and the filter key list against `Threadline.Query`'s `@allowed_timeline_filter_keys`.
**Example:**
```elixir
# Source: test/threadline/operator_surface_doc_contract_test.exs (adapted)
defmodule Threadline.OperatorSurface.TimelineBrowseDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "router declares the timeline browse live route at the surface root" do
    router_src = File.read!("lib/threadline/operator_surface/router.ex")
    assert router_src =~ ~s|live("/", TimelineLive, :index)|
  end

  test "timeline live form exposes ARIA labels for every filter input" do
    live_src = File.read!("lib/threadline/operator_surface/live/timeline_live.ex")

    for label <- ~w(from to table actor_kind actor_id correlation_id) do
      assert live_src =~ ~s|aria-label="#{aria_label_for(label)}"|,
             "missing ARIA label for filter #{label}"
    end
  end

  test "filter form key list matches Threadline.Query allowlist exactly" do
    # @allowed_timeline_filter_keys lives at lib/threadline/query.ex line 36
    # In the LV, the canonical-query builder enumerates the same keys.
    expected = ~w(from to table actor_kind actor_id correlation_id)
    live_src = File.read!("lib/threadline/operator_surface/live/timeline_live.ex")

    for key <- expected do
      assert live_src =~ ~s|name="filter[#{key}]"|
    end

    # Belt + braces: assert no extra "filter[…]" name appears.
    name_pattern = ~r/name="filter\[(\w+)\]"/
    found = Regex.scan(name_pattern, live_src) |> Enum.map(fn [_, k] -> k end) |> Enum.uniq() |> Enum.sort()
    assert found == Enum.sort(expected),
           "filter form keys diverged from API allowlist. Found: #{inspect(found)}, expected: #{inspect(expected)}"
  end
end
```

> The third test is the load-bearing one — it would catch a future hand-roll `name="filter[user_id]"` that drifts away from the API allowlist. Without it, BROWSE-04's "any future divergence between UI and API filter keys fails CI" guarantee is hollow.

### Anti-Patterns to Avoid

- **`phx-change` → `push_patch` per keystroke.** Inflates history, breaks BROWSE-03 back/forward, regresses CONTEXT.md D-04. CONTEXT.md is explicit: explicit Apply only.
- **`String.to_atom/1` on URL-supplied `actor_kind`.** Leaks the BEAM atom table. Use `String.to_existing_atom/1`; on `ArgumentError`, render the unknown-kind hint.
- **Storing the cursor in the URL.** Breaks tombstone safety (CONTEXT.md D-13). Cursor lives in socket assigns only.
- **Calling `Threadline.Health.trigger_coverage/1` on every `handle_params/3`.** It runs two raw SQL queries (`pg_tables` + `pg_trigger`). Cache once at `mount/3` (CONTEXT.md D-06 implicitly requires this; the static datalist is fine across the LV's lifetime). See "Pitfalls / Datalist staleness."
- **Inventing a parallel filter dialect for the UI.** CONTEXT.md D-10 + BROWSE-02 + BROWSE-04 are clear: reuse `validate_timeline_filters!/1` verbatim. Adding a UI-only translator (e.g. mapping `"date_from"` → `:from`) silently splits the filter vocabulary that Phase 65's controller will re-validate against.
- **Tailwind utility classes / new CSS frameworks.** CSS isolation lives in `Threadline.OperatorSurface.Style.css/1`. Extend the existing CSS-variable theme; do not introduce class names outside `.threadline-ui …`.
- **Threading the auth scope into `:repo` only.** The scope is more than the repo — it's the `:authorize_fn` return. If/when scope-derived predicates exist (e.g. tenant filter), they must thread into `timeline_page/2` opts. For Phase 64, document the threading contract (`scope_aware_filters/2` helper) even if it's a passthrough today, so Phase 65's controller can reuse the helper.
- **Including `actor_id` in the URL when `actor_kind=anonymous`.** Strip it on submit and on `handle_params/3` re-parse. Otherwise stale URLs round-trip with a confusing-but-ignored `actor_id=42` param.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Filter validation / allowlist | A UI-side dialect or Ecto changeset for filters | `Threadline.Query.validate_timeline_filters!/1` (lib/threadline/query.ex:130-155) | Single source of truth; exact keys (`from`, `to`, `table`, `actor_ref`, `correlation_id`); reused by API + export + Phase 65 controller. |
| Correlation-id format rules | `pattern=…` regex on `<input>` | `Threadline.Query.validate_correlation_id_filter!/1` (lib/threadline/query.ex:174-198) | Lib intentionally leaves format adopter-defined. Just enforce ≤256 bytes, non-empty after trim — already in the validator. |
| Keyset pagination | Custom offset/limit query | `Threadline.Query.timeline_page/2` with `page_size: 50` (lib/threadline/query.ex:282-318) | The `(captured_at, id)` keyset is the project-canonical paging contract since v1.16 Phase 53; offset is pathological at audit-data scale. |
| Actor kind enum | Hand-listed `~w(user admin …)` | `Threadline.Semantics.ActorRef` (the kinds are derived from the constructor's pattern matches) | The enum is normative in the lib. Use the lib's accept/reject as the source of truth. |
| Datalist source | `~w(users posts comments)` literal | `Threadline.Health.trigger_coverage(repo: …)` filtered to `:covered` | Stays correct as adopters add tables; also keeps the read-only-ceiling promise (uncovered tables never leak into the form). |
| Datetime-local normalization | A new helper module | Inline `parse_datetime_local/1` modeled on `RowHistoryComponent` lines 39-50 | Established precedent; one place to fix later if the convention changes. |
| Stream rendering / DOM ids | `Enum.map` rendering with manual ids | `stream_configure/3` + `stream/4` + `phx-update="stream"` | Already used by `TransactionLive` and `ActorLive`; idiomatic for incremental render. |
| URL composition | Hand-rolled string interpolation | `URI.encode_query/1` over an enum-sorted list | Round-trip stable, deterministic key order, paste-friendly. |

**Key insight:** Phase 64's discipline is *additive parity*, not creative invention. Every lib function it needs already exists. The only genuine new code is glue: the LV's `handle_params/3`, `handle_event/3`, `render/3`, and the CSS extensions for the toolbar/form.

## Common Pitfalls

### Pitfall 1: `stream(reset: true)` race with in-flight `next-page` (resolved upstream)

**What goes wrong:** Operator scrolls to the bottom triggering `phx-viewport-bottom="next-page"`; *during* the LiveView's round-trip to fetch and append, the operator clicks Apply with new filters; the in-flight `next-page` payload arrives after the `stream(reset: true)`, polluting the new filter's list with stale rows from the old filter.
**Why it happens:** The viewport-bottom event is async; the server has no per-event correlation id; `stream(reset: true)` clears the client list but a subsequently-arriving `at: -1` insert from the old filter's query lands on the cleared list.
**How to avoid:** Both halves of the mitigation:
  1. **Clear `:cursor` *before* calling `stream(reset: true)`** in `handle_params/3` so the next `next-page` event sees `cursor == nil` and is a no-op (the existing `ActorLive` line 121 guard `if socket.assigns.next_cursor do …` is the canonical shape).
  2. **Phoenix LiveView ≥ 1.0 fixes** the underlying stream-reset rendering bugs (issues #2895, #2994). `threadline` declares `~> 1.0`, so we are above the fix line.
**Warning signs:** Test scenario: apply a filter, scroll to bottom (no-op because cursor is nil after the second-to-last page), apply a different filter, scroll → assert no rows from the first filter appear. The `actor_live_test.exs` "Case 4" pattern demonstrates the test shape.

### Pitfall 2: Datetime-local naive string → wrong UTC

**What goes wrong:** Browser submits `"2026-05-06T14:30"`. A hand-rolled parser does `DateTime.from_iso8601(value)` and gets `{:error, :missing_offset}`. The plan-author "fixes" it by appending the operator's local offset, accidentally inverting the convention used by the rest of the codebase.
**Why it happens:** ISO8601 requires an offset; HTML's `datetime-local` deliberately omits it. Every team that hits this for the first time picks a slightly-different fix.
**How to avoid:** Use the existing `RowHistoryComponent` shape verbatim: pad to 16 chars + `:00Z`, parse, take the `DateTime`. **Do not add timezone-detection logic.** Threadline's audit data is captured as `DateTime` (UTC); the operator's filter window is most usefully expressed in UTC; the "naive string read as UTC" convention is consistent with the rest of the surface and the underlying data.
**Warning signs:** Any hand-rolled `DateTime.from_naive/2` call with a non-`"Etc/UTC"` argument. Any new helper module for "tz-aware datetime-local". Any `phx-hook` that does client-side tz conversion.

### Pitfall 3: History-entry inflation on per-keystroke patches

**What goes wrong:** A future plan-author "improves UX" by adding `phx-change="filter-changed"` on text inputs and calling `push_patch` on every change. After typing "req_abc123" into the correlation-id field the operator now has 11 history entries — back-button works ten times before reaching the previous filter set.
**Why it happens:** It looks helpful. CONTEXT.md D-04's prohibition is easy to forget once decision context is lost.
**How to avoid:** Encode the prohibition as a verifiable test: `timeline_browse_doc_contract_test.exs` should grep the LV source for `phx-change` and assert it appears **zero** times on the filter form (or only on inert UI like the `actor_kind` select if a UI-only `phx-change` is genuinely needed for the disable-actor-id-on-anonymous toggle — and even then it must NOT call `push_patch`). Also: every text input should have `phx-debounce="blur"` (CONTEXT.md D-04) as a defensive layer.
**Warning signs:** Browser back-button doesn't reach the prior filter set in one click. CONTEXT.md D-04 explicitly: "One submit = one `push_patch` = one history entry."

### Pitfall 4: Datalist staleness across mount

**What goes wrong:** Operator opens the timeline at 9 AM. At 10 AM an adopter runs `mix threadline.gen.triggers` and adds the `orders` table. At 10:15 the operator (still on the same LV session) types "ord" — the datalist autocomplete doesn't suggest `orders` because `audited_tables` was cached at mount.
**Why it happens:** `Threadline.Health.trigger_coverage/1` runs two raw SQL queries (`pg_tables` + `pg_trigger`). Calling it on every render or every `handle_params/3` is wasteful; calling it once at mount/3 is fast but stale across long-lived sessions.
**How to avoid:** Mount-time cache is correct for v1.18. Document the staleness limit in a comment near the call site: "Datalist refreshed at mount; long-lived sessions may not see newly-audited tables until the next page load. Operators rarely keep this surface open across `gen.triggers` runs." If real adopter feedback ever surfaces, Phase 66 (Coverage Dashboard) will share a polled cache that this LV can subscribe to via the `:health_checked` telemetry signal.
**Warning signs:** A test that fakes mid-session schema changes and asserts the datalist updates. (Don't add this test — it would lock in a behavior we don't want yet.)

### Pitfall 5: Auth scope quietly dropped

**What goes wrong:** `Auth.on_mount/4` populates `:threadline_scope`, but `TimelineLive` reads `socket.assigns[:threadline_repo]` and forgets `:threadline_scope`. Today this is invisible because no host actually returns a scope-restricted repo, but the v1.17 contract (`{:ok, scope}` return = scope is threaded into investigation queries) is silently violated.
**Why it happens:** The existing `TransactionLive` and `ActorLive` don't visibly thread it (`grep threadline_scope lib/` returns only auth.ex), so the implicit precedent is "ignore it."
**How to avoid:** Centralize scope threading in a small helper at the top of `TimelineLive`:
```elixir
defp scope_aware_opts(socket) do
  base = [repo: socket.assigns.repo, page_size: 50]
  case socket.assigns.scope do
    nil   -> base
    scope -> Keyword.merge(base, scope_to_query_opts(scope))  # passthrough today; extension point for v1.19+
  end
end

# For Phase 64, scope_to_query_opts/1 may simply return [] — document it.
defp scope_to_query_opts(_scope), do: []
```
And **add a unit test** that asserts the helper is called on every query path. This makes Phase 65's controller able to reuse `scope_aware_opts/1` with no surprises.
**Warning signs:** No test asserts scope flow. `:threadline_scope` does not appear anywhere in `timeline_live.ex` source.

### Pitfall 6: Stream `dom_id` collisions on filter change

**What goes wrong:** `stream_configure(:changes, dom_id: fn ch -> "change-#{ch.id}" end)` works fine across pagination — every `audit_changes.id` is a UUID, so DOM ids are unique within a filter window. But if the filter is broadened and a row that was already rendered re-appears, `stream(reset: true)` is the correct mechanic and dom_ids continue to be unique. The pitfall is using a non-id field (e.g. `change-#{ch.captured_at}`) where collisions are possible.
**How to avoid:** Use `change.id` only — same as `TransactionLive` line 19.
**Warning signs:** A `dom_id` function that combines fields ("change-{tx_id}-{seq}").

### Pitfall 7: `mix verify.compile_no_optional` regression

**What goes wrong:** Plan-author adds `alias Phoenix.LiveView.JS` at the top of a new helper file outside the `if Code.ensure_loaded?(Phoenix.LiveView)` block. When optional deps are dropped, the alias resolves to a missing module and compilation fails.
**Why it happens:** Aliases / imports / `use` directives at file scope — not inside the conditional block — escape the gate.
**How to avoid:** **Every new file** under `lib/threadline/operator_surface/` MUST start with `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule … end end`. Verified by `mix verify.compile_no_optional` in CI; verified at the unit-test layer by the existing `gating_test.exs` shape (consider extending it to assert `TimelineLive` is conditionally loaded too).
**Warning signs:** Any `alias Phoenix.…` or `import Phoenix.…` outside the `if` block. Any `use Phoenix.LiveView` line that isn't immediately under `defmodule … do` inside the conditional.

## Code Examples

### Building a canonical query string from form params (scrub empties; deterministic key order)
```elixir
@filter_keys ~w(from to table actor_kind actor_id correlation_id)

defp build_canonical_query(%{} = raw) do
  raw
  |> normalize_anonymous()  # if actor_kind=anonymous, drop actor_id
  |> Enum.map(fn {k, v} -> {k, v} end)
  |> Enum.filter(fn {k, v} -> k in @filter_keys and is_binary(v) and v != "" end)
  |> Enum.sort_by(fn {k, _v} -> Enum.find_index(@filter_keys, &(&1 == k)) end)
  |> URI.encode_query()
end

defp normalize_anonymous(%{"actor_kind" => "anonymous"} = raw) do
  Map.delete(raw, "actor_id")
end

defp normalize_anonymous(raw), do: raw
```

> Sort keys in the canonical order before `URI.encode_query` so that pasting the URL into Slack and pasting it back yields a byte-identical URL — important for the BROWSE-04 doc-contract guarantee.

### Defensive empty-state and unknown-table hint
```heex
<%= cond do %>
  <% @form_error -> %>
    <div class="filter-error" role="alert"><%= @form_error %></div>

  <% Enum.empty?(@streams.changes.inserts) and @unknown_table_attempted -> %>
    <div class="empty-state filter-hint">
      <p>No audited table named <%= inspect(@filters[:table]) %>.</p>
      <p>Known: <%= Enum.join(@audited_tables, ", ") %></p>
    </div>

  <% Enum.empty?(@streams.changes.inserts) -> %>
    <div class="empty-state">
      <p>No changes match these filters in the selected window.</p>
    </div>

  <% true -> %>
    <!-- stream container renders -->
<% end %>
```

> Source for empty-state pattern: `TransactionLive` line 78-80, `ActorLive` line 73-77.

## Runtime State Inventory

> Phase 64 is greenfield UI on top of established APIs — no rename / refactor / migration. **Section omitted by design.**

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| LiveView 0.20 stream-reset bugs (#2895, #2994) | LV 1.0+ resolves render races on `stream(reset: true)` | LV 1.0.0 (2024-11) | Threadline declares `~> 1.0`; we are above the fix line. Plans should still test the filter-change-during-viewport-bottom flow as a regression guard. |
| `live_redirect` / `live_patch` macro forms | `<.link patch={...}>` and `push_patch/2` | LV 0.18 → 1.0 | Use the function-based form. CONTEXT.md uses both names interchangeably; the modern call site is `<.link patch=…>` for templates and `push_patch/2` for socket handlers. |
| Manual `Enum.map` over a list assign + `phx-update="append"` | `Phoenix.LiveView.Stream` + `phx-update="stream"` | LV 0.18 (2023) | Streams are GA, idiomatic, and already used by sibling LVs. |
| Per-keystroke `phx-change` URL patches | Explicit Apply with `phx-submit` (Sentry-Elixir / Oban Web shape) | n/a (always-true UX advice for filter-heavy forms) | Avoids history-entry inflation; better with structured-key forms vs autocomplete-DSL forms. |

**Deprecated/outdated:**
- The `live_patch` macro (`live_patch "Apply", to: …`) — superseded by `<.link patch={…}>`. Use the function form. [CITED: hexdocs.pm/phoenix_live_view/live-navigation.html]
- LiveView 0.20.x stream-reset semantics — fixed in 1.0+. [CITED: phoenix_live_view CHANGELOG v1.0.0]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Datetime-local strings should be interpreted as UTC (not the operator's local timezone), matching the existing `RowHistoryComponent` precedent. | Pattern 3, Pitfall 2 | LOW — the precedent is established and consistent with audit data being UTC. If product feedback ever surfaces tz confusion, address it as its own phase. |
| A2 | Mount-time caching of `audited_tables` is acceptable for v1.18 (operators rarely keep the surface open across `gen.triggers` runs). | Pitfall 4 | LOW — Phase 66 will introduce a polled coverage source that can be subscribed to later. |
| A3 | `String.to_existing_atom/1` is safe for `actor_kind` URL params because `Threadline.Semantics.ActorRef` is loaded before `TimelineLive` mounts (BEAM dispatch order, plus the `use Ecto.ParameterizedType` triggers atom registration at compile time). | Pattern 6 | LOW — verifiable by an `iex -S mix` smoke check, and the worst-case failure (`ArgumentError`) is the same code path as "unknown actor kind." |
| A4 | `URI.encode_query/1` on a sorted keyword list produces a byte-stable, paste-friendly URL across Elixir/OTP versions in the supported range. | Code Examples | LOW — it's stdlib and stable; the deterministic ordering is enforced by our `Enum.sort_by` step, not by `URI.encode_query` itself. |
| A5 | The `:threadline_scope` assign may be `nil` (when `:authorize_fn` returns `:ok` or `true`) and `TimelineLive` should treat that as "no scope restrictions." | Pitfall 5, Pattern 2 | LOW — confirmed by `auth.ex` lines 21-27 (`:ok` → no `assign` for scope) and the `auth_test.exs` test scope. |
| A6 | Phase 65's controller will call into the same `scope_aware_opts/1` helper Phase 64 ships, so the auth scope contract is end-to-end consistent. | Don't Hand-Roll, Pitfall 5 | MEDIUM — depends on Phase 65's plan accepting this contract. Worth raising in `/gsd-discuss-phase 65` if not already implicit. |

## Open Questions

1. **Should `TimelineLive`'s back-link to `TransactionLive` be a literal anchor or a `<.link navigate={…}>` so it's a full LV remount?**
   - What we know: CONTEXT.md D-02 says "small inline `← Timeline` back-link" but only specifies the *placement* (TransactionLive / ActorLive headers), not the *direction*. The TimelineLive header itself doesn't need a back-link to anywhere (it's the surface root).
   - What's unclear: Should clicking a row in TimelineLive go to TransactionLive via `<.link patch=…>` (no remount, faster) or `<.link navigate=…>` (remount, simpler state management)?
   - Recommendation: `<.link navigate=…>` — TimelineLive and TransactionLive have different mount-time data (timeline cursor vs incident bundle), so a remount is the cleaner mental model. Existing `ActorLive` line 90 uses an `<a href=…>` to TransactionLive, which is functionally equivalent to `navigate`.

2. **Should the form expose a `name="filter[…]"` shape, or use `<.form for={@form}>` with a Phoenix.HTML.Form struct?**
   - What we know: The existing `RowHistoryComponent` uses raw `<form phx-change="…">` with bare `<input name="as_of">`. CONTEXT.md does not specify form-struct vs raw.
   - What's unclear: Phase 65's controller will accept the same query params as the LV — they need to be compatible whatever the form shape.
   - Recommendation: Raw `<form phx-submit="apply">` with `<input name="filter[from]">` etc. The "filter[…]" prefix gives the handler a tidy `%{"filter" => raw}` shape and keeps the form compatible with Phase 65's controller (which will accept the same nested params). No `Ecto.Changeset` needed because the lib is the validator.

3. **What's the correct ARIA shape for the disabled `actor_id` input when `actor_kind=anonymous`?**
   - What we know: The HTML `disabled` attribute removes the input from form submission and the tab order, but screen readers may not announce *why*.
   - What's unclear: Should we add `aria-describedby="actor-id-disabled-hint"` pointing at a hidden `<small>` that says "Disabled because actor kind is anonymous"?
   - Recommendation: Yes — the BROWSE-04 doc-contract test should pin both the `aria-label` and the `aria-describedby` literals. Plan-author picks the exact text; the test asserts it.

4. **Should the LV surface a "Refresh" button or rely on `live_patch` re-submit / browser refresh?**
   - What we know: CONTEXT.md doesn't specify. Auto-refresh is explicitly deferred (CONTEXT.md "Deferred Ideas").
   - What's unclear: A "Refresh" button is technically a re-submit of the current filter set.
   - Recommendation: No explicit Refresh button in Phase 64. The Apply button itself with the current form values is the refresh affordance. Adding a Refresh button is creep into deferred-auto-refresh territory.

## Environment Availability

> Phase 64 is a code-only phase under existing optional deps. No new external services.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `phoenix_live_view` (declared optional) | TimelineLive itself | ✓ in test/dev when adopters install it | `~> 1.0` | File-scope `Code.ensure_loaded?` gate keeps capture-only adopter compiles green. |
| `phoenix_html` (declared optional) | HEEx templates | ✓ when LV is present | `~> 4.0` | Same gate. |
| PostgreSQL with `audit_changes` / `audit_transactions` triggers | All timeline queries | n/a (data plane, not a build dep) | n/a | Empty-state copy already covers the no-data case. |
| `lazy_html` (test only) | LiveViewTest assertions | ✓ test dep | `~> 0.1.0` | n/a. |

**Missing dependencies with no fallback:** None — Phase 64 is fully covered by deps shipped in v1.17.

**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir 1.15+) |
| Config file | `config/test.exs` (Postgres + `Threadline.Test.Repo`) — established by v1.17 |
| Quick run command | `mix test test/threadline/operator_surface/live/timeline_live_test.exs --warnings-as-errors` |
| Full suite command | `mix verify.test` (alias for `mix test`) |
| LV-absent compile | `mix verify.compile_no_optional` |
| Full CI | `mix ci.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BROWSE-01 | TimelineLive mounts under `threadline_operator_surface`; auth contract still applies; LV-absent compile green | unit (mount) + LV-absent compile | `mix test test/threadline/operator_surface/live/timeline_live_test.exs:test_mount` ; `mix verify.compile_no_optional` | ❌ Wave 0 |
| BROWSE-01 | `:threadline_scope` is read by mount and threaded into queries (passthrough today) | unit | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t scope` | ❌ Wave 0 |
| BROWSE-02 | All five filter keys (`from`, `to`, `table`, `actor_kind`+`actor_id`, `correlation_id`) round-trip through the form and validate via `validate_timeline_filters!/1` | integration (LiveViewTest) | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t filter_parity` | ❌ Wave 0 |
| BROWSE-02 | Unknown filter key (e.g. `?foo=bar`) is dropped in the canonical builder; `validate_timeline_filters!/1` is the source of truth | unit | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t allowlist_drop` | ❌ Wave 0 |
| BROWSE-02 | `actor_kind=anonymous` strips `actor_id` on submit and on re-parse; `ActorRef.new(:anonymous, nil)` is constructed | unit | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t anonymous` | ❌ Wave 0 |
| BROWSE-02 | Correlation id >256 bytes triggers `:form_error` with the lib's literal message | unit (rescue path) | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t correlation_id_too_long` | ❌ Wave 0 |
| BROWSE-03 | Pasting a URL into a fresh session reproduces the result set | integration | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t url_round_trip` | ❌ Wave 0 |
| BROWSE-03 | Apply submits one `push_patch` ≠ one history entry per Apply (verifiable by counting `handle_params` invocations under repeated submits) | property | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t history_entry_property` | ❌ Wave 0 |
| BROWSE-03 | First mount with no params defaults to "last 24h" window (server-side default) | unit (mount) | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t default_window` | ❌ Wave 0 |
| BROWSE-03 | `<input type="datetime-local">` and `<select>` are present and named correctly (no custom widgets, no `<input type="text">` for dates) | doc-contract / regex | `mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs -t native_widgets` | ❌ Wave 0 |
| BROWSE-03 | Datetime-local values pad-to-`:00Z` and parse via `DateTime.from_iso8601/1` (UTC convention) | unit | `mix test test/threadline/operator_surface/live/timeline_live_test.exs -t datetime_normalization` | ❌ Wave 0 |
| BROWSE-04 | Route literal `live("/", TimelineLive, :index)` exists in router source | doc-contract | `mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs -t route_literal` | ❌ Wave 0 |
| BROWSE-04 | All ARIA labels (`from`, `to`, `table`, `actor kind`, `actor id`, `correlation id`) present in LV source | doc-contract | `mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs -t aria_labels` | ❌ Wave 0 |
| BROWSE-04 | LV form key list matches `Threadline.Query.@allowed_timeline_filter_keys` | doc-contract | `mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs -t filter_key_parity` | ❌ Wave 0 |
| BROWSE-04 | LV file is wrapped in `if Code.ensure_loaded?(Phoenix.LiveView) do … end` | doc-contract | `mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs -t code_ensure_loaded_gate` | ❌ Wave 0 |
| (CI invariant) | `mix verify.compile_no_optional` stays green | LV-absent compile | `mix verify.compile_no_optional` | ✅ exists |
| (CI invariant) | `mix ci.all` stays green (`verify.format`, `verify.credo`, `compile --warnings-as-errors`, `verify.test`, `verify.threadline`, `verify.example`, `verify.doc_contract`) | full CI | `mix ci.all` | ✅ exists |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs --warnings-as-errors` (focused, fast).
- **Per wave merge:** `mix verify.test && mix verify.compile_no_optional` (full LV-present + LV-absent).
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/threadline/operator_surface/live/timeline_live_test.exs` — mount + filter-apply + URL round-trip + datetime-tz normalization + stream-reset + scope thread (covers BROWSE-01..03 verifiable behaviors). Mirror the setup shape of `actor_live_test.exs` (Layouts + Router + Endpoint + LiveViewTest setup). The test router scope MUST mount `threadline_operator_surface("/audit")` so the new `live("/", TimelineLive, :index)` route resolves at `/audit`.
- [ ] `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` — locks route literal, ARIA labels, filter-key parity, datetime-local widget presence, file-scope gating presence (covers BROWSE-04 + the CI-invariant guard).
- [ ] (Optional) Extend `test/threadline/operator_surface/gating_test.exs` to assert `Threadline.OperatorSurface.Live.TimelineLive` follows the same conditional-load pattern as `Auth` and `Router`. Cheap.

*(No framework install needed — ExUnit, Phoenix.LiveViewTest, and LazyHTML are all already declared.)*

### Goal-Backward Verification Checklist (mapped to ROADMAP success criteria)

| Roadmap Success Criterion | How tests prove it |
|--------------------------|---------------------|
| 1. Visiting the route renders a paged audit timeline; auth contract applies; LV-absent compile is green | `timeline_live_test.exs` mount tests + `gating_test.exs` extension + `mix verify.compile_no_optional` |
| 2. Form accepts all five `Threadline.Query.timeline/2` keys via `validate_timeline_filters!/1` | `timeline_live_test.exs` filter-parity tests + doc-contract filter-key-parity test |
| 3. Filter set is URL-as-state via `live_patch`; URL alone reproduces results; back/forward navigates filter history; first mount defaults to last 24h; native datetime-local + select | `timeline_live_test.exs` URL round-trip + history-entry property + default-window + datetime-normalization tests; doc-contract native-widgets test |
| 4. Doc-contract test locks route literal, ARIA labels, filter key list | `timeline_browse_doc_contract_test.exs` (route_literal, aria_labels, filter_key_parity tests) |

## Security Domain

> `security_enforcement` defaults enabled per project policy; included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Host-owned via `Threadline.OperatorSurface.Router` macro's compile-time fail-closed check + `:authorize_fn` callback (lib/threadline/operator_surface/router.ex:30-36). No new auth surface in Phase 64. |
| V3 Session Management | yes (passthrough) | Host's session/cookie config (`Plug.Session`); LV reuses the existing `live_session :threadline` (lib/threadline/operator_surface/router.ex:40). No new session state in Phase 64. |
| V4 Access Control | yes | `:threadline_scope` from `:authorize_fn` is threaded into `Threadline.Query.timeline_page/2` opts via `scope_aware_opts/1` helper. Read-only ceiling: no mutations, no policy edits, no exports buttons (deferred to Phase 65). |
| V5 Input Validation | yes | `Threadline.Query.validate_timeline_filters!/1` (allowlisted keys; raises on unknown). `Threadline.Query.validate_correlation_id_filter!/1` (≤256 bytes, non-empty after trim). UI wraps in `try/rescue ArgumentError`. |
| V6 Cryptography | n/a | No crypto surface. |
| V7 Error Handling | yes | `try/rescue ArgumentError` around the validator → render `:form_error`; never leak Ecto stack traces to operators. |
| V8 Data Protection | yes (read path) | The `<datalist>` is filtered to **covered** tables only — never expose uncovered table names that could be a discovery vector for data the host hasn't audited. CONTEXT.md D-06 locks this. |
| V13 API & Web Service | n/a | No new API; LV consumes existing lib API. |

### Known Threat Patterns for {Phoenix LiveView + URL-as-state filter form}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom-table exhaustion via `?actor_kind=evil_string_1` (cycled) | DoS | `String.to_existing_atom/1` — never `String.to_atom/1` on user input. (Pattern 6) |
| Cross-site script injection via reflected filter values in error/hint copy | XSS | HEEx auto-escapes `<%= @form_error %>` and `<%= inspect(@filters[:table]) %>`. **Do not** use `raw/1` or `Phoenix.HTML.raw/1` on filter values. |
| URL parameter pollution / unknown keys silently accepted | Tampering | `validate_timeline_filters!/1` raises `ArgumentError` on unknown keys; UI catches and renders an error. The canonical-query builder also drops anything not in `@filter_keys`. |
| Information disclosure via uncovered-table autocomplete | Information Disclosure | Datalist is sourced from `{:covered, name}` tuples only. Uncovered names live behind Phase 66's `/audit/coverage` viewer with the same auth gate. |
| Stale URL with purged cursor → "stuck on empty" silent failure | DoS / poor UX | URL contains filter state only — never cursor. CONTEXT.md D-13 (tombstone safety). Stale URL just re-resolves from "now" backwards through the filter window. |
| Session hijack replay across operator changes | Spoofing | Out of Phase 64 scope — host-owned session. |
| Read-only ceiling violation (e.g. accidentally adding a "Purge" button) | Tampering | CONTEXT.md "Deferred Ideas" + the doc-contract test asserting the form has no `phx-click="purge"`-style handlers. (Optional belt-and-braces.) |

## Project Constraints (from CLAUDE.md)

- **Hex package name:** `threadline`. Module namespace under `Threadline.*`.
- **Three-layer architecture must not be conflated:** Phase 64 lives in the **exploration/operations layer** (timelines, filters, viewers). It must not introduce capture or semantics changes; it consumes both via `Threadline.Query` and `Threadline.Semantics.ActorRef`.
- **Domain language:** Use `AuditChange`, `AuditTransaction`, `AuditAction`, `ActorRef`, `Correlation` consistently in code, docs, and APIs. The browse LV surfaces `AuditChange` rows (not `AuditTransaction` rows).
- **Verification entrypoints (canonical):** `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all`. Plans should cite these verbatim.
- **Honest default tests:** New tests run as part of `mix test` by default; do not put them behind a `@tag :skip` or `excludes:` in `test/test_helper.exs`.
- **Stable CI job IDs:** Phase 64 does not require new GH Actions jobs; the existing `verify-compile-no-optional` job covers the LV-absent compile check.
- **Doc contract tests:** README, guides, example app README stay aligned via test assertions. The new `timeline_browse_doc_contract_test.exs` extends this convention.
- **`mix verify.compile_no_optional` MUST stay green.** Every new file under `lib/threadline/operator_surface/` MUST be wrapped in `if Code.ensure_loaded?(Phoenix.LiveView) do … end` at file scope.
- **Capture mechanism is TBD; do not assume Carbonite.** Phase 64 doesn't touch capture; this constraint is preserved by scoping the work to the exploration layer.
- **Not a SIEM, not event sourcing, not a pgAudit replacement, not a data warehouse.** Phase 64's read-only ceiling and "no saved views" decisions reinforce this — keep the surface a thin window, not a query builder.
- **GSD invariant:** Use **positional** args for `gsd-sdk query state.begin-phase` (`phase`, `slug`, `plan_count`). Phase 20 doc captures the workaround, but Phase 64 will follow the same hygiene.

## Phase Forward-Compat Constraints (for Phase 65)

Phase 65 (Exports UI Parity) re-validates filter params against the same `validate_timeline_filters!/1` literal Phase 64 ships, and renders `[Download CSV]` / `[Download JSON]` buttons in the same `[Clear all] [Apply]` action cluster. Phase 64 must:

| Must lock for Phase 65 | Must NOT preempt for Phase 65 |
|-----------------------|-------------------------------|
| Canonical URL contract verbatim (the `<canonical_url_contract>` block in CONTEXT.md). Phase 65's controller will accept the identical query string. | CSV-specific assumptions in the form (no escape-character toggles, no header-row checkbox). |
| The `name="filter[…]"` form shape — Phase 65's controller params must collapse identically. | A "what file format will I get" toggle baked into the filter form (Phase 65 will own this). |
| `scope_aware_opts/1` helper signature — Phase 65 reuses it from a controller. | Pre-flight count/preview UI affordances (Phase 65 owns `count_matching/2`). |
| The `try/rescue ArgumentError` validation idiom — Phase 65's controller wraps the same. | A `:row_cap` URL knob (Phase 65 owns the iodata-vs-chunked threshold). |
| Stable form `id="timeline-filters"` for focus preservation across patches. | A `download` query param (Phase 65 will use a separate route, not a form param). |
| The `[Clear all] [Apply]` cluster on the right — Phase 65 *appends* `[Download CSV] [Download JSON]` to the same cluster (CONTEXT.md D-03). | Hard-coded button widths or a flex layout that breaks when two more buttons land. |

## Sources

### Primary (HIGH confidence)
- `lib/threadline/query.ex` (lines 36, 130-198, 282-318) — the canonical filter validator and pager. **Source-of-truth.**
- `lib/threadline/semantics/actor_ref.ex` (lines 1-91) — the canonical actor enum + constructor.
- `lib/threadline/health.ex` (lines 29-72) — the datalist source.
- `lib/threadline/operator_surface/router.ex` (lines 1-50) — the mount macro to extend.
- `lib/threadline/operator_surface/auth.ex` (lines 1-64) — `:threadline_scope` and `:threadline_repo` setup.
- `lib/threadline/operator_surface/live/transaction_live.ex` (lines 1-148) — `phx-viewport-bottom` + stream + push_patch precedent.
- `lib/threadline/operator_surface/live/actor_live.ex` (lines 1-156) — closest analog: cursor-in-assigns + `set-window` event + filter-change reset.
- `lib/threadline/operator_surface/live/row_history_component.ex` (lines 39-50) — datetime-local normalization precedent (load-bearing for Pattern 3).
- `lib/threadline/operator_surface/style.ex` (lines 1-128) — CSS namespace + variables to extend.
- `test/threadline/operator_surface_doc_contract_test.exs` — doc-contract test shape to mirror.
- `test/threadline/operator_surface/live/actor_live_test.exs` (lines 1-138) — LiveViewTest harness shape (Layouts + Router + Endpoint).
- `test/threadline/operator_surface/router_test.exs` — router macro CompileError pattern.
- `test/threadline/operator_surface/gating_test.exs` — file-scope-gating test shape.
- `lib/mix.exs` (lines 53-89) — verify aliases, optional deps, `verify.compile_no_optional`.
- `Phoenix.LiveView` Context7 ID `/phoenixframework/phoenix_live_view` — official docs for `push_patch/2`, `stream/4`, `phx-viewport-bottom`, `phx-debounce`. ([hexdocs.pm/phoenix_live_view](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html))
- `Phoenix.LiveView` bindings guide — debounce semantics + viewport conditional binding pattern. ([hexdocs.pm/phoenix_live_view/bindings.html](https://hexdocs.pm/phoenix_live_view/bindings.html))
- `Phoenix.LiveView` live-navigation guide — patch vs navigate semantics, `replace` flag. ([hexdocs.pm/phoenix_live_view/live-navigation.html](https://hexdocs.pm/phoenix_live_view/live-navigation.html))

### Secondary (MEDIUM confidence)
- Fly.io blog — *Persistent forms with your URL on LiveView*: confirms the `phx-submit` → `push_patch` → `handle_params` shape; explicit empty-string scrub guidance. ([fly.io/phoenix-files/persistent-forms-with-your-url-on-liveview/](https://fly.io/phoenix-files/persistent-forms-with-your-url-on-liveview/))
- Phoenix LiveView CHANGELOG v1.0.0 — confirms stream-reset-on-filter-change render races resolved in v1.0. ([github.com/phoenixframework/phoenix_live_view CHANGELOG](https://github.com/phoenixframework/phoenix_live_view/blob/v1.0.0/CHANGELOG.md))
- MDN `<input type="datetime-local">` reference — confirms naive (no-timezone) submission format. ([developer.mozilla.org](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/datetime-local))

### Tertiary (LOW confidence — flagged for validation)
- GitHub issues [#2895](https://github.com/phoenixframework/phoenix_live_view/issues/2895) and [#2994](https://github.com/phoenixframework/phoenix_live_view/issues/2994) — historical context for stream-reset bugs; reading the comment threads to confirm full closure on the v1.0 line is recommended if the planner has time, but not required (unit tests at the right ordering will catch regressions either way).

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — every library and helper is already in the codebase or in the project's mix.exs at known versions.
- Architecture: **HIGH** — patterns are lifted directly from v1.17 sibling LVs with verified line numbers; no new architectural shape.
- Pitfalls: **HIGH** — the four named landmines are sourced from upstream issues, official docs, and observable codebase divergence (auth scope threading); each has a code-level mitigation.
- Validation Architecture: **HIGH** — every requirement has at least one named test path; the test harness shape is borrowed verbatim from `actor_live_test.exs`.
- Forward-compat to Phase 65: **MEDIUM** — depends on Phase 65 honoring the `scope_aware_opts/1` and form-shape contracts; raise in `/gsd-discuss-phase 65` if at risk.

**Research date:** 2026-05-06
**Valid until:** 2026-06-06 (Phoenix LiveView is on a stable 1.x line; no impending breakage in the supported range. Re-check if `phoenix_live_view` cuts a 1.2 with stream-reset semantic changes, or if Phase 65 begins planning > 30d from now.)

## RESEARCH COMPLETE
