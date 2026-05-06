# Phase 59: Architectural Decisions

*Based on deep research by advisor subagents during the Discuss Phase.*

## 1. Operator Surface Styling
**Decision:** Custom, Scoped CSS (`.threadline-ui` namespace)

**Rationale:**
To provide a resilient, out-of-the-box UI that honors the principle of least surprise, Threadline will bundle its own isolated, scoped CSS. This avoids the major footgun of relying on the host's `core_components.ex` (which adopters frequently modify or remove) and bypasses the developer-hostile ergonomics of inline styles. This approach mirrors successful Elixir libraries like Phoenix LiveDashboard and Oban Web, guaranteeing a polished UI without polluting the host's CSS namespace. We will expose CSS variables for basic theming rather than expecting structural overrides.

## 2. Pagination for Massive Transactions
**Decision:** DOM Virtualization (LiveView Streams + `phx-viewport`)

**Rationale:**
An "Incident Drill-down" screen requires continuous timeline traversal to preserve investigative context. Traditional offset pagination breaks this flow. By using Phoenix 1.1.1+ native `stream/3` combined with `phx-viewport-top` and `phx-viewport-bottom` limits, we achieve the continuous-scroll UX standard established by Datadog/Sentry while maintaining a strictly bounded DOM footprint. This prevents browser lockups or excessive server memory usage on massive transactions while keeping the developer experience seamless.