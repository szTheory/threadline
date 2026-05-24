# Technology Stack

**Project:** Threadline v1.21 scoped support/operator lane
**Researched:** 2026-05-24

## Recommended Stack

The correct stack choice for Option 2 is mostly **no stack change**. This milestone should productize the existing Phoenix adoption lane, not widen Threadline's infrastructure surface.

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | `~> 1.15` | Language/runtime | Matches the current library baseline and keeps the milestone focused on integration proof, not runtime migration. |
| Phoenix | `~> 1.7` | Router, controller, browser pipeline | The support lane is fundamentally a router/pipeline composition problem. |
| Phoenix LiveView | `~> 1.0` | Mounted operator surface | `live_session` plus `on_mount` is the idiomatic place for per-surface authorization checks. |
| Plug | `~> 1.15` | Request-path auth and export controller boundary | Plug pipelines remain the host-owned authentication and HTTP denial boundary. |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Ecto / Ecto SQL | `~> 3.10` | Query composition and scope narrowing | `scope_query_fn` should keep shaping `Ecto.Query` values, not Threadline-owned policy objects. |
| PostgreSQL | current project baseline | Audit storage/query source | No storage-model change is needed for this milestone. |

### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Existing optional Phoenix surface deps | current `mix.exs` posture | In-tree optional operator surface | Keeps capture-only adopters unaffected and avoids new hard runtime dependencies. |
| Existing export/storage adapters | current project baseline | Export lane posture | Support-lane work should consume the existing export surface, not redesign it. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Phoenix.LiveView.Router.live_session/3` | LiveView `1.1.30` proven in current lock | Group support/admin LiveViews under one mount boundary | Use for the mounted surface; do not rely on it for sibling HTTP export routes. |
| `Phoenix.LiveView.on_mount/1` | LiveView `1.1.30` | Per-mount authorization hook | Use for allow/deny plus opaque scope assignment. |
| `Plug.Conn.halt/1` | Plug `1.19.2` docs current | Export request denial | Use for explicit HTTP `403` termination on denied export requests. |
| `Ecto.Query.dynamic/2` | Ecto `3.14.0` docs current | Host query transforms when scoping becomes more complex | Use only if adopters need composable scope conditions beyond a simple `where`. |

## Recommended Technical Posture

1. **Keep authentication host-owned in Plug pipelines.**
2. **Keep page-entry authorization in `on_mount`.**
3. **Keep row visibility in `scope_query_fn` over `Ecto.Query`.**
4. **Keep export HTTP auth separate from LiveView mount auth.**
5. **Keep new public API surface additive and tiny.**

This is the least-surprise Phoenix shape and matches official guidance that LiveViews begin as regular HTTP requests but still need their own mount-time checks, while regular HTTP routes continue to depend on plugs.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Support authorization model | Host-owned `authorize_fn` + opaque scope | Threadline roles / permissions DSL | Violates the current product thesis and creates a false cross-host abstraction. |
| Row visibility enforcement | `scope_query_fn` transforms over `Ecto.Query` | UI-only hiding or page-specific if/else logic | UI-only checks leak data and duplicate policy across screens. |
| Surface variation | Small boolean/route controls like `exports: false` | Full page-policy matrix in Threadline config | A matrix becomes an authorization framework by another name. |
| Adoption proof | First-party docs + example app + tests | More generic adapters or broader framework work | Does not address the current highest-value adoption gap. |

## Installation

```bash
# Core
mix deps.get

# Optional Phoenix surface proof remains the existing install shape
mix compile
mix test
```

No new required dependencies are recommended for this milestone.

## Sources

- Local repo:
  - `mix.exs`
  - `guides/operator-surface.md`
  - `guides/integration-contracts.md`
  - `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
  - `lib/threadline/operator_surface/auth.ex`
  - `lib/threadline/operator_surface/export_auth_plug.ex`
  - `lib/threadline/operator_surface/scope.ex`
- Official docs:
  - Phoenix LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
  - Phoenix LiveView router: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html
  - Phoenix routing: https://hexdocs.pm/phoenix/routing.html
  - Plug.Conn: https://hexdocs.pm/plug/Plug.Conn.html
  - Ecto.Query: https://hexdocs.pm/ecto/Ecto.Query.html
