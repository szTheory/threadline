# Threadline ↔ Sigra integration

<!-- SIGRA-03-INTEGRATION-GUIDE -->

Use `Threadline.Integrations.Sigra` when your Phoenix host already uses Sigra for request authentication and impersonation.

This guide documents Threadline's current `sigra-reference` lane: a maintained
first-party reference path for a Phoenix host that already owns Sigra. It is a
reference claim, not a blanket support promise for arbitrary Sigra versions,
arbitrary auth layouts, or non-Phoenix hosts.

## Install

Add Sigra to your host application's `mix.exs` as an optional dependency:

```elixir
{:sigra, "~> 0.2", optional: true}
```

This dependency is for hosts; never for the library.

In this lane, Sigra stays host-owned and soft-loaded. The root `threadline`
library keeps Sigra out of its dependency graph, while the reference path is
proven through the current example app, docs, and focused repo verification.
That host dependency shape is not a blanket support promise for every Sigra
`0.2.x` host.

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

This remains a direct callback pair, not a second adapter layer: the host wires
Sigra state into `Threadline.Plug`, and Threadline keeps the additive-only
request metadata contract intact.

Sigra covers request capture only. It does not secure `/audit`, export routes,
tenancy, roles, or policy admin for you.

## Surface and export auth stay host-owned

The auth split is intentional:

- request capture auth belongs in `actor_fn` plus `context_overrides_fn`
- LiveView surface auth belongs in `authorize_fn`
- export HTTP auth belongs in `export_authorize_fn`, or it falls back to `authorize_fn` with a synthetic `%{assigns: conn.assigns}` mirror

Keep your browser/admin boundary in front of `/audit`, then let
`authorize_fn` fail closed inside the mounted surface. Keep export routes behind
the same host-owned posture. Sigra does not become the auth story for the
operator surface or exports.

The canonical operator-surface callback shape is one shared `%{assigns: assigns}`
function. Keep it host-owned, let it return `:ok` or `{:ok, scope}`, and treat
that scope as opaque host data. For a support-read-only lane, reuse the same
`/audit` tree, return a host-owned scope such as
`%{access: :support_read_only, organization_id: "org_123"}`, and default to
`exports: false`. Do not treat Sigra as a page-level authorization DSL or a
Threadline-owned roles system.

## Behaviors locked by SPEC

1. Impersonation maps to `:admin`. When `current_scope.impersonating_from` is non-nil, `actor_ref_from_conn/1` returns an admin actor and keeps the impersonated user encoded in correlation metadata.
2. API token maps to `:service_account`. When `current_scope.auth_method` is `:api_token` or `:jwt`, `actor_ref_from_conn/1` returns a service account actor using `current_scope.id`.
3. Active organization adds a suffix. When Sigra exposes an active organization, the adapter appends `:org:<id>` to the derived correlation id.
4. Anonymous / Sigra-absent returns `nil`. If the request has no supported Sigra actor shape, `actor_ref_from_conn/1` returns raw `nil`.
5. `x-correlation-id` header always wins. When the header is present, `audit_context_overrides_from_conn/1` returns `%{}` so `Threadline.Plug` preserves the request value instead of replacing it.
6. `x-request-id` and any existing actor identity also stay authoritative. `context_overrides_fn` is additive request metadata only; it is not a second actor path.
7. Plug-only adapter; no telemetry subscription in v1.

These behaviors are the supported reference semantics for the current guide and
example app. They are not a statement that every Sigra-backed Phoenix host or
every future Sigra release is automatically covered by Threadline.

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

That soft-dep contract is part of the `sigra-reference` lane. The host owns
whether Sigra is present; Threadline only adapts that state when the dependency
is loaded.
