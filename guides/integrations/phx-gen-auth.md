# Threadline ↔ phx.gen.auth integration

<!-- PHX-GEN-AUTH-03-INTEGRATION-GUIDE -->

This guide documents Threadline's current `phx-gen-auth-reference` lane: a maintained composition path for Phoenix hosts using `mix phx.gen.auth` (or equivalent generated session auth). It is a reference claim, not a blanket support promise for arbitrary generator versions, role fields, or non-Phoenix auth. This lane is narrower than generic `phoenix-surface` integration and is not Sigra-compatible.

## Prerequisites

- Your host already ran `mix phx.gen.auth` (or equivalent generated session auth).
- Threadline does not add an auth Hex dependency; capture uses `Threadline.Plug` callbacks only.
- The host owns user schema, session tables, and pipeline plugs.

## Plug callback wire-up

Wire `Threadline.Plug` after session and scope assigns exist; see `guides/integration-contracts.md`.

**Plug order (hard requirement):**

- `plug :fetch_session`
- `plug :fetch_current_scope` (or host equivalent from generated `UserAuth`)
- `plug Threadline.Plug, ...` on pipelines with audited writes

Host module `MyApp.AuditActor`:

```elixir
defmodule MyApp.AuditActor do
  alias Threadline.Semantics.ActorRef
  def actor_ref_from_conn(conn) do
    case conn.assigns[:current_scope] do
      %{user: %{id: id}} -> ActorRef.new(:user, to_string(id))
      _ -> nil
    end
  end
  def audit_context_overrides_from_conn(_conn), do: %{}
end
```

Router pipeline:

```elixir
pipeline :browser do
  plug :fetch_session
  plug :fetch_current_scope
  plug Threadline.Plug,
    actor_fn: &MyApp.AuditActor.actor_ref_from_conn/1,
    context_overrides_fn: &MyApp.AuditActor.audit_context_overrides_from_conn/1
end
```

- **Phoenix 1.7 legacy:** if only `current_user` exists, fall back inside `actor_fn` with a short `case conn.assigns[:current_user]` branch — scope-first, not dual-primary.

`Threadline.Plug` derives `request_id` from `x-request-id` first and `correlation_id` from `x-correlation-id` first. `context_overrides_fn` is additive fill-only; unknown override keys raise `ArgumentError`.

## Surface and export auth stay host-owned

Capture uses `actor_fn`; operator UI uses host-owned `authorize_fn`:

```elixir
threadline_operator_surface "/audit",
  authorize_fn: fn
    %{assigns: %{current_user: %{role: "admin"}}} -> :ok
    _ -> {:error, :unauthorized}
  end
```

Use `is_admin` instead of `role` if that matches your schema. See `guides/operator-surface.md` for `export_authorize_fn`, evidence, coverage, and policy callbacks. LiveView `on_mount` does not secure export HTTP routes; export uses `export_authorize_fn` or falls back to `authorize_fn` with `%{assigns: conn.assigns}`.

## Reference semantics

1. Scope-shaped `user.id` → `:user` actor via `actor_fn`.
2. Logged-out scope → `nil` actor.
3. 1-arity `authorize_fn` allows admins and denies others.
4. `x-request-id` header wins over conn-derived request id.
5. `x-correlation-id` header wins; overrides are additive only.
6. Unknown override keys raise `ArgumentError`.

## Optional correlation strategy

Default `context_overrides_fn` returns `%{}`; headers win. Optionally propagate W3C `traceparent`, BFF-set `x-correlation-id`, or business ids via `Threadline.Audit.transaction/3`. Strict timeline `:correlation_id` filters need `:action` / `Audit.transaction/3` — plug context alone is insufficient.

## Non-goals

- Threadline does not run `mix phx.gen.auth`.
- Threadline does not own user tables or sessions.
- Threadline does not secure routes without host `require_authenticated_user` / pipeline plugs.

## Lane and proof

Maintained composition path: this guide. Root CI proof: `test/threadline/integrations/phx_gen_auth_integration_test.exs` (`mix verify.test`). This is not a second example application. Reference semantics items 4–6 are covered by `test/threadline/plug_test.exs`.
