# Threadline ↔ Sigra integration

<!-- SIGRA-03-INTEGRATION-GUIDE -->

Use `Threadline.Integrations.Sigra` when your Phoenix host already uses Sigra for request authentication and impersonation.

## Install

Add Sigra to your host application's `mix.exs` as an optional dependency:

```elixir
{:sigra, "~> 0.2", optional: true}
```

This dependency is for hosts; never for the library.

## Plug callback wire-up

Wire `Threadline.Plug` directly with both callbacks in the router pipeline
after your host has established request auth and any proxy-aware IP rewriting:

```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug Threadline.Plug,
    actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
    context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
end
```

`actor_fn` decides who acted. `context_overrides_fn` can add only additive
request metadata when the baseline conn extraction has no value.

`Threadline.Plug` always derives `request_id` from `x-request-id` first and
`correlation_id` from `x-correlation-id` first. The Sigra callback is therefore
supplemental: it fills missing values and never replaces an explicit header or
already-derived actor identity. If the callback returns unknown keys or any
non-map value, `Threadline.Plug` raises `ArgumentError` immediately.

Hosts still own transport normalization. If your deployment needs proxy-aware IP
handling, rewrite `conn.remote_ip` upstream before `Threadline.Plug` runs.

## Behaviors locked by SPEC

1. Impersonation maps to `:admin`. When `current_scope.impersonating_from` is non-nil, `actor_ref_from_conn/1` returns an admin actor and keeps the impersonated user encoded in correlation metadata.
2. API token maps to `:service_account`. When `current_scope.auth_method` is `:api_token` or `:jwt`, `actor_ref_from_conn/1` returns a service account actor using `current_scope.id`.
3. Active organization adds a suffix. When Sigra exposes an active organization, the adapter appends `:org:<id>` to the derived correlation id.
4. Anonymous / Sigra-absent returns `nil`. If the request has no supported Sigra actor shape, `actor_ref_from_conn/1` returns raw `nil`.
5. `x-correlation-id` header always wins. When the header is present, `audit_context_overrides_from_conn/1` returns `%{}` so `Threadline.Plug` preserves the request value instead of replacing it.
6. `x-request-id` and any existing actor identity also stay authoritative. `context_overrides_fn` is additive request metadata only; it is not a second actor path.
7. Plug-only adapter; no telemetry subscription in v1.

## correlation_id formats

- Impersonation: `sigra-imp:<session_id>:user:<imp_user_id>`
- Plain session: `sigra-session:<session_id>`
- API token: `sigra-token:<token_id>`
- Anonymous / Sigra absent: no override / `%{}`

## Soft-dep contract

`Code.ensure_loaded?(Sigra.Session)` is the single soft-dependency gate.

When that check is false:

- `actor_ref_from_conn/1` returns `nil`
- `audit_context_overrides_from_conn/1` returns `%{}`
