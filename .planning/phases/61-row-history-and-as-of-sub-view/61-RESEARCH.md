# Phase 61: Row History and As-Of Sub-View - Research

**Researched:** 2024-05-30
**Domain:** Phoenix LiveView Routing, Component Architecture, Threadline Query APIs
**Confidence:** HIGH

## Summary

The goal of this phase is to render a sub-view within `TransactionLive` that displays the complete change history and an "as-of" snapshot for a specific row. This view is triggered by interacting with a change row in the incident drill-down screen. It leverages a slide-over `LiveComponent` driven by URL routing so that the operator can easily share deep-links to exact snapshots. 

**Primary recommendation:** Add the `:history` live action to the `threadline_operator_surface` macro, update `TransactionLive` to handle the new `handle_params` pattern to extract URL parameters, and construct `RowHistoryComponent` to own its data fetching. Crucially, a new schema mapping configuration must be introduced to resolve URL table names to Ecto schema modules required by Threadline query APIs.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| URL Routing | Frontend Server | — | `TransactionLive` handles URL parsing and `handle_params` to dictate state. |
| Component State | Frontend Server | — | `RowHistoryComponent` fetches its own data (`update/2`) using `Threadline` functions, preventing bloat in the parent LiveView. |
| Data Fetching | API / Backend | Database | `Threadline.history/3` and `Threadline.as_of/4` perform the Ecto queries against the audit schema. |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. **Routing & Rendering Architecture: Patched URL Sub-view (`live_action` / `live_patch`)**
   - **Decision:** The sub-view is implemented as a slide-over `LiveComponent` rendered over the existing `TransactionLive` screen. It uses a new `live_action` (e.g. `:history`) via `live_patch`.
   - **Rationale:** This pattern is deeply idiomatic for observability tools (like Datadog, Sentry, or GitHub Blame). It allows operators to copy and share exact, deep-linked URLs during an incident without losing the broader parent transaction context. It avoids the "unshareable modal" footgun while skipping the disruptive full-page navigation of a distinct route.
   - **Mechanism:** The URL pattern should be `/transactions/:id/history/:table/:record_id?as_of=...` routed to `TransactionLive` with a `:history` action.

2. **The "As-of" Snapshot UX: Click-to-Scrub Timeline**
   - **Decision:** The primary "timestamp picker" is the history list itself. Clicking any row in the change history immediately updates the URL `?as_of=<captured_at>` (via `push_patch`), and the adjacent "As-of Snapshot" panel updates to show the full state of the record at that exact moment.
   - **Rationale:** This click-to-scrub pattern is vastly superior for incident forensics compared to typing in raw timestamps. We will still include a fallback `datetime-local` HTML input for manual entry, but the primary UX relies on the row timeline acting as the picker.

3. **Component Data Boundary: Component Fetches via `update/2`**
   - **Decision:** The `LiveComponent` (`RowHistoryComponent`) owns its own data fetching.
   - **Rationale:** The parent `TransactionLive` extracts `table_name`, `record_id`, and `as_of` from the URL parameters (`handle_params`) and passes them down. This perfectly encapsulates the `Threadline.history/3` and `Threadline.as_of/4` calls, preventing `TransactionLive` from bloating with domain queries that are completely irrelevant when the slide-over is closed.

### the agent's Discretion
[None explicitly marked]

### Deferred Ideas (OUT OF SCOPE)
[None explicitly marked]
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ~> 0.20 | Sub-view navigation | Existing Phase 59 stack; idiomatic approach for slide-over modals via `live_patch` |

## Architecture Patterns

### System Architecture Diagram

```text
Browser User Click
       │
       ▼
[URL: /transactions/:id/history/:table/:record_id?as_of=timestamp]
       │
       ▼
TransactionLive (handle_params/3)
       │
       ├──> Parses URL Params -> Updates socket assigns (table, record_id, as_of)
       │
       ▼
[Renders Sub-view Template Condition]
       │
       ▼
RowHistoryComponent (update/2)
       │
       ├──> Calls Threadline.history(schema_module, record_id)
       ├──> Calls Threadline.as_of(schema_module, record_id, as_of_datetime)
       │
       ▼
Ecto.Repo -> Database
```

### Pattern 1: URL-Driven LiveComponent via handle_params
**What:** The parent LiveView parses the URL in `handle_params`, sets properties in `assigns`, and conditionally renders a `LiveComponent`.
**When to use:** For shareable deep links (like a slide-over or modal) without losing the background parent context.
**Example:**
```elixir
def handle_params(params, _uri, socket) do
  case socket.assigns.live_action do
    :show ->
      {:noreply, assign(socket, show_history: false)}
    :history ->
      table = params["table"]
      record_id = params["record_id"]
      as_of = params["as_of"] # parse to datetime if present
      {:noreply, assign(socket, show_history: true, history_table: table, history_record_id: record_id, history_as_of: as_of)}
  end
end
```

### Pattern 2: Component-Owned Data Fetching
**What:** Pass basic identifiers down to the `LiveComponent`. The component uses its lifecycle `update/2` to run heavy database queries.
**When to use:** When the data is heavy or purely isolated to a transient UI piece (like a history slider panel).
**Example:**
```elixir
def update(assigns, socket) do
  history = Threadline.history(assigns.schema_module, assigns.record_id, repo: assigns.repo)
  snapshot = Threadline.as_of(assigns.schema_module, assigns.record_id, assigns.as_of_dt, repo: assigns.repo)
  
  {:ok, assign(socket, assigns |> Map.merge(%{history: history, snapshot: snapshot}))}
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Modal state management | `phx-click` toggling a boolean `show_modal` | `live_patch` to a new `:history` action | Modals must be shareable via URL copy/paste during an incident. State lost on refresh is an anti-pattern. |
| Row history fetching | Custom Ecto queries filtering by JSONB fields | `Threadline.history/3` | `Threadline.Query` handles the complex JSONB PK containment, strict `table_name` binding, and proper sorting mechanics internally. |
| Time travel queries | Custom `where captured_at <= ?` | `Threadline.as_of/4` | Handles "deleted" states, struct casting via Ecto metadata, and proper snapshot ordering. |

## Common Pitfalls

### Pitfall 1: URL String IDs vs Schema Primary Keys
**What goes wrong:** The URL string `:record_id` cannot be blindly matched against `table_pk` because `Threadline.history/3` uses the Ecto schema's primary key type (which could be UUID, integer, etc.).
**Why it happens:** The URL only has a string, but the API requires a schema module to resolve `__schema__(:primary_key)` and construct the proper database types for queries.
**How to avoid:** A mapping between `table_name` and the `schema_module` must be introduced to the system so `Threadline` can cast the ID string and accurately fetch records.

### Pitfall 2: `as_of` DateTime Parsing
**What goes wrong:** `push_patch` places `as_of` in the URL as a string. `Threadline.as_of/4` strictly requires a `%DateTime{}` struct.
**How to avoid:** Safely parse the URL parameter `as_of` using `DateTime.from_iso8601/1` before passing it to `Threadline.as_of/4`. Handle the `{:error, _}` gracefully (fallback to the latest timestamp or handle cleanly).

## Code Examples

### Rendering the Sub-view in TransactionLive
```elixir
<%= if @live_action == :history do %>
  <.live_component 
    module={Threadline.OperatorSurface.Live.RowHistoryComponent}
    id="row-history-slider"
    transaction_id={@bundle.transaction.id}
    table={@history_table}
    record_id={@history_record_id}
    as_of={@history_as_of}
    repo={@threadline_repo}
    schema_module={resolve_schema(@threadline_schemas, @history_table)}
  />
<% end %>
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Threadline Operator Surface currently lacks a mechanism to map a string `table_name` to an Ecto `schema_module`. It is assumed that passing a `:schemas` mapping (e.g., `schemas: %{"users" => MyApp.User}`) via the `threadline_operator_surface` macro is the correct resolution path. | Open Questions | If incorrect, the sub-view component won't be able to invoke `Threadline.history/3` and the feature implementation will fail due to a lack of schema metadata. |

## Open Questions (RESOLVED)

1. **How to resolve `schema_module` from `:table` in the URL?**
   - What we know: `Threadline.history/3` and `Threadline.as_of/4` explicitly require a `schema_module` to work, but the URL only exposes `:table`. There is currently no global schema registry.
   - What's unclear: How the `LiveComponent` or `TransactionLive` resolves `"users"` to `MyApp.User`.
   - Recommendation: Introduce a `:schemas` mapping configuration to the `threadline_operator_surface` macro. Pass it down via `Threadline.OperatorSurface.Auth` to `socket.assigns[:threadline_schemas]`. The `RowHistoryComponent` can look up the module using `assigns.table`. If not configured, render a graceful "Schema not configured" empty-state.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/operator_surface/transaction_live_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Mounts on `:history` live action and parses URL | unit | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ✅ Wave 0 |
| REQ-02 | `RowHistoryComponent` fetches and displays history | unit | `mix test test/threadline/operator_surface/row_history_component_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/operator_surface/transaction_live_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/threadline/operator_surface/row_history_component_test.exs` — necessary to cover the new slide-over component.

## Sources

### Primary (HIGH confidence)
- `/lib/threadline/operator_surface/router.ex` - Verified macro usage for `TransactionLive` `:show` mount points.
- `/lib/threadline/operator_surface/live/transaction_live.ex` - Verified current `mount/3` and `render/1` param handling mechanisms.
- `/lib/threadline/query.ex` - Verified function signatures for `history/3` and `as_of/4` explicitly requiring `schema_module`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows Phoenix LiveView standards.
- Architecture: HIGH - Component `update/2` and `live_action` URL-patching are canonical.
- Pitfalls: HIGH - The schema resolution gap is a hard factual constraint of the existing Threadline Core API.

**Research date:** 2024-05-30
**Valid until:** Stable
