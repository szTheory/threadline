# Threadline ↔ phx.gen.auth integration

<!-- PHX-GEN-AUTH-03-INTEGRATION-GUIDE -->

This guide documents Threadline's current `phx-gen-auth-reference` lane: a maintained
composition path for Phoenix hosts using `mix phx.gen.auth` (or equivalent generated
session auth). It is a reference claim, not a blanket support promise for arbitrary
generator versions, role fields, or non-Phoenix auth. This lane is narrower than
generic `phoenix-surface` integration and is not Sigra-compatible.

## Prerequisites

- Your host already ran `mix phx.gen.auth` (or equivalent generated session auth).
- Threadline does not add an auth Hex dependency; capture uses `Threadline.Plug` callbacks only.
- The host owns user schema, session tables, and pipeline plugs.

## Plug callback wire-up

Wire `Threadline.Plug` after session and scope assigns exist on any pipeline with
audited writes. See `guides/integration-contracts.md` for the full callback contract.

**Plug order (hard requirement):**

- `plug :fetch_session`
- `plug :fetch_current_scope` (or your host equivalent from generated `UserAuth`)
- `plug Threadline.Plug, ...` on pipelines that perform audited writes

Copy a host-owned module (conventional name `MyApp.AuditActor`) into your app:

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

Then wire it in the router pipeline:

```elixir
pipeline :browser do
  plug :fetch_session
  plug :fetch_current_scope
  plug Threadline.Plug,
    actor_fn: &MyApp.AuditActor.actor_ref_from_conn/1,
    context_overrides_fn: &MyApp.AuditActor.audit_context_overrides_from_conn/1
end
```

- **Phoenix 1.7 legacy:** if only `current_user` exists, fall back inside `actor_fn`
  with a short `case conn.assigns[:current_user]` branch — scope-first, not dual-primary.

`Threadline.Plug` derives `request_id` from `x-request-id` first and
`correlation_id` from `x-correlation-id` first. `context_overrides_fn` is additive
fill-only; unknown override keys raise `ArgumentError`.
