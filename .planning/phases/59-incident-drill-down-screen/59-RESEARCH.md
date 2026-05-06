# Phase 59: Incident Drill-down Screen - Research

**Researched:** 2024-05-20
**Domain:** Phoenix LiveView, DOM Virtualization, Scoped CSS
**Confidence:** HIGH

## Summary

This phase implements a URL-addressable LiveView screen at `/audit/transactions/:id` to visualize `Threadline.incident_bundle/2`. The screen provides a stable deep-link for operators to inspect the context (actor, intent) and row-level changes (using the precomputed `change_diff` included in the bundle) of a specific transaction. 

Because transactions can be massive, the UI requires DOM virtualization using Phoenix LiveView Streams and `phx-viewport`. Additionally, to guarantee a resilient and polished UI without polluting or depending on the host application's CSS (like `core_components.ex`), the implementation will use custom scoped CSS within the `.threadline-ui` namespace.

**Primary recommendation:** Implement a dedicated LiveView (e.g., `Threadline.OperatorSurface.TransactionLive`) mounted via the `Threadline.OperatorSurface.Router` macro, use `stream/3` to manage the collection of changes, and inject a localized CSS bundle prefixed with `.threadline-ui`.

<user_constraints>
## User Constraints (from DECISIONS.md)

### Locked Decisions

## 1. Operator Surface Styling
**Decision:** Custom, Scoped CSS (`.threadline-ui` namespace)

**Rationale:**
To provide a resilient, out-of-the-box UI that honors the principle of least surprise, Threadline will bundle its own isolated, scoped CSS. This avoids the major footgun of relying on the host's `core_components.ex` (which adopters frequently modify or remove) and bypasses the developer-hostile ergonomics of inline styles. This approach mirrors successful Elixir libraries like Phoenix LiveDashboard and Oban Web, guaranteeing a polished UI without polluting the host's CSS namespace. We will expose CSS variables for basic theming rather than expecting structural overrides.

## 2. Pagination for Massive Transactions
**Decision:** DOM Virtualization (LiveView Streams + `phx-viewport`)

**Rationale:**
An "Incident Drill-down" screen requires continuous timeline traversal to preserve investigative context. Traditional offset pagination breaks this flow. By using Phoenix 1.1.1+ native `stream/3` combined with `phx-viewport-top` and `phx-viewport-bottom` limits, we achieve the continuous-scroll UX standard established by Datadog/Sentry while maintaining a strictly bounded DOM footprint. This prevents browser lockups or excessive server memory usage on massive transactions while keeping the developer experience seamless.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Incident drill-down LiveView at `/audit/transactions/:id` renders `Threadline.incident_bundle/2` — actor and request-context header, ordered changes with `Threadline.change_diff/2` per row, URL-addressable for log/ticket deep-links, and an explicit not-found state. | LiveView `mount/3` pattern match on `{:ok, bundle}` vs `{:error, :not_found}` from `incident_bundle/2`. The `IncidentChange` struct in the bundle already exposes the precomputed `.change_diff`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| URL Routing & Parameter Extraction | Frontend Server (LiveView) | — | Handled by Phoenix Router macro and `mount/3` capturing the `:id`. |
| Bundle Fetching | API / Backend (Threadline) | — | Delegated to existing `Threadline.incident_bundle/2`. |
| DOM Virtualization | Browser / Client | Frontend Server (LiveView) | `phx-viewport` coordinates client-side DOM culling with server-side `stream/3`. |
| Scoped Styling | Browser / Client | — | Injected `<style>` block or dedicated endpoint scoped to `.threadline-ui` namespace. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | `~> 1.0` | Interactive UI | Required for `stream/3` and `phx-viewport` virtualization features (introduced in >= 0.20). Verified in `mix.exs`. |
| Phoenix HTML | `~> 4.0` | Rendering | Standard companion for LiveView HEEx templates. |

## Architecture Patterns

### Recommended Project Structure
```
lib/threadline/operator_surface/
├── auth.ex                 # Existing
├── router.ex               # Existing
└── transaction_live.ex     # NEW: The LiveView for drill-down
```

### Pattern 1: URL-Addressable Bundle Fetching & Streams
**What:** Utilizing LiveView's `mount/3` to fetch the transaction and stream its changes.
**When to use:** Whenever rendering an unknown or potentially massive collection tied to a URL parameter.
**Example:**
```elixir
def mount(%{"id" => id}, _session, socket) do
  case Threadline.incident_bundle(id) do
    {:ok, bundle} ->
      {:ok,
       socket
       |> assign(:bundle, bundle)
       |> stream(:changes, bundle.changes)}
       
    {:error, :not_found} ->
      {:ok, assign(socket, :not_found, true)}
  end
end
```

### Pattern 2: `phx-viewport` Continuous Scroll
**What:** Bounding the DOM size to prevent browser crashes on massive audit transactions.
**When to use:** Rendering the timeline of `IncidentChange` items.
**Example:**
```elixir
<div class="threadline-ui">
  <!-- Header / Actor Context -->
  <div id="changes-viewport" style="max-height: 80vh; overflow-y: auto;" phx-viewport-top="prev-page" phx-viewport-bottom="next-page">
    <ul id="changes" phx-update="stream">
      <li :for={{dom_id, change} <- @streams.changes} id={dom_id}>
        <!-- Render change.change_diff -->
      </li>
    </ul>
  </div>
</div>
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Infinite Scroll | Manual offset/limit buttons | `stream/3` with `phx-viewport` | Prevents DOM bloating and browser lockups on 10,000+ row transactions. |
| UI Components | Complex dependencies on host app's `core_components.ex` | Self-contained HTML with `.threadline-ui` scoped CSS | Ensures the LiveView renders correctly regardless of the host application's tailwind/CSS configuration. |
| Diff calculation | Calling `Threadline.change_diff/2` manually in HEEx | Use `change.change_diff` | `incident_bundle/2` already packages diffs on the `IncidentChange` struct, avoiding redundant recalculations. |

## Common Pitfalls

### Pitfall 1: Assuming `core_components` exists
**What goes wrong:** The view crashes or renders as unstyled text because it attempts to use `<.table>`, `<.header>`, or `<.modal>` which may be altered or deleted by the integrating team.
**How to avoid:** Build raw HEEx elements (`<div>`, `<table>`, `<ul>`) explicitly styled using custom CSS classes within the `.threadline-ui` namespace.

### Pitfall 2: Silent Failures on Missing Transactions
**What goes wrong:** A log deep-links to `/audit/transactions/123` but the row is purged or invalid. The screen either crashes or renders an empty UI implying 0 changes.
**How to avoid:** Explicitly match `{:error, :not_found}` from `incident_bundle/2` and render a distinct "Transaction Not Found" state.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `phoenix_live_view` | The UI module | ✓ | `~> 1.0` | Gated module via `Code.ensure_loaded?`. |

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
| UI-01 | Renders valid bundle and changes | unit (live) | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ❌ |
| UI-01 | Renders not-found state | unit (live) | `mix test test/threadline/operator_surface/transaction_live_test.exs` | ❌ |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | Relies on `Threadline.OperatorSurface.Auth.on_mount/4` which enforces host-provided `:authorize_fn` constraints. |
| V5 Input Validation | yes | `incident_bundle/2` safely parameterizes UUID lookup. |

### Known Threat Patterns for Phoenix LiveView

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure Direct Object Reference (IDOR) | Elevation of Privilege | Ensure the parent `Router` and `on_mount` lifecycle strictly gates access to the route based on the host's `pipe_through`. |

## Sources

### Primary (HIGH confidence)
- `mix.exs` - Verified `phoenix_live_view` version (`~> 1.0`).
- `lib/threadline/investigation.ex` - Verified `incident_bundle/2` contract and `IncidentChange` struct shape.
- `.planning/phases/59-incident-drill-down-screen/DECISIONS.md` - Verified explicit constraints for CSS scoping and `phx-viewport` DOM virtualization.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly aligned with Phoenix 1.7+ / LiveView 0.20+ features.
- Architecture: HIGH - Mapped exactly to library boundaries.
- Pitfalls: HIGH - Addresses known issues with Elixir OSS UI components.

**Research date:** 2024-05-20
**Valid until:** 6 months