# Integration Contracts

Threadline exposes a small set of concrete integration seams. This guide is the
canonical breadth contract for those seams.

The contract is intentionally code-shaped:

- `Threadline.Plug` owns request-path capture context.
- `Threadline.Job` owns serialized job-path context.
- `Threadline.Integrations.*` owns soft-loaded reference adapters.
- `threadline_operator_surface/2` owns the operator-surface mount boundary, with
  `authorize_fn` and optional `export_authorize_fn` covering the LiveView and
  HTTP export faces.

Threadline does not introduce a separate adapter behaviour or umbrella protocol
here. These are the existing supported seams.

## Request path via `Threadline.Plug`

`Threadline.Plug` attaches `%Threadline.Semantics.AuditContext{}` to
`conn.assigns[:audit_context]`.

```elixir
plug Threadline.Plug,
  actor_fn: &MyApp.Audit.actor_ref_from_conn/1,
  context_overrides_fn: &MyApp.Audit.audit_context_overrides/1
```

The request-path contract is:

- `actor_fn` is the only actor-authority callback. It decides
  `audit_context.actor_ref` and may return an `ActorRef` or `nil`.
- `context_overrides_fn` is additive-only. It may return a map containing only
  `:request_id` and `:correlation_id`.
- `Threadline.Plug` extracts `request_id`, `correlation_id`, and `remote_ip`
  first, then fills only missing `request_id` / `correlation_id` fields from
  `context_overrides_fn`.
- Unknown override keys and non-map returns fail closed with `ArgumentError`.
- Proxy-aware IP normalization stays host-owned. Normalize `conn.remote_ip`
  before `Threadline.Plug` runs if your deployment needs it.

This seam does not provide a second actor channel. Additive metadata cannot
replace actor identity or `remote_ip`.

Capture-only adopters can stop here. `Threadline.Plug` plus the core APIs are
the strongest supported lane, and `mix verify.compile_no_optional` proves that
surface without optional Phoenix UI dependencies.

## Job path via `Threadline.Job`

`Threadline.Job` keeps background-job propagation explicit and serializable. It
is not a callback mini-framework and does not couple Threadline to any
particular job runner.

```elixir
args = %{
  "actor_ref" => Threadline.Semantics.ActorRef.to_map(actor_ref),
  "correlation_id" => correlation_id,
  "job_id" => job.id
}

with {:ok, actor_ref} <- Threadline.Job.actor_ref_from_args(args) do
  opts = Threadline.Job.context_opts(args)
  Threadline.record_action(:member_synced, [actor: actor_ref, repo: Repo] ++ opts)
end
```

The job-path contract is:

- `"actor_ref"` stores `Threadline.Semantics.ActorRef.to_map/1` output.
- `Threadline.Job.actor_ref_from_args/1` reads that serialized map back into an
  `ActorRef`.
- `Threadline.Job.context_opts/2` extracts stable context keys from the args
  map, currently `"correlation_id"` and `"job_id"`.
- Any broader worker-framework integration belongs in an adapter module if the
  pattern repeats; it is not standardized in core today.

## Audited write path via `Threadline.Audit`

`Threadline.Audit.transaction/3` is the recommended helper for domain writes that need
capture and optional semantic action linkage in one database transaction.

`Threadline.Plug` and `Threadline.Job` remain edge context producers — call the helper
from Phoenix context modules (or workers) after resolving `%Threadline.Semantics.AuditContext{}`
and `%Threadline.Semantics.ActorRef{}`.

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    audit_context: audit_context,
    action: :post_created_via_api,
    transaction_meta: %{"organization_id" => org_id}
  ],
  fn ->
    Repo.insert!(Post.changeset(%Post{}, attrs))
  end
)
```

Contract bullets:

- **`:action` present → correlation-ready** — the helper calls `Threadline.record_action/2`
  and links `audit_transactions.action_id` so strict `:correlation_id` filters on
  `Threadline.timeline/2` match.
- **`:action` absent → capture-only** — row capture and `actor_ref` on
  `audit_transactions` still work; strict `:correlation_id` timeline/export filters
  **will not match** (document this at code review).
- **`actor_ref` required** unless `allow_missing_actor: true` on capture-only paths
  (non-recommended for multi-tenant SaaS).
- **Callback must not** call `set_config` for `threadline.actor_ref`, `Threadline.record_action/2`,
  or nested `Repo.transaction/1` — the helper owns GUC, action recording, and linkage.

## Reference integrations via `Threadline.Integrations.*`

`Threadline.Integrations.*` modules are reference adapters. They translate host
or framework state into the existing Threadline-native seams above.

`Threadline.Integrations.Sigra` is the current model:

- soft dependency gating stays inside the integration module via
  `Code.ensure_loaded?`
- absent host dependencies return neutral defaults rather than forcing hard
  coupling into core
- helpers stay direct and composable, such as `actor_ref_from_conn/1`,
  `audit_context_overrides_from_conn/1`, and `actor_fn/0`

```elixir
plug Threadline.Plug,
  actor_fn: Threadline.Integrations.Sigra.actor_fn(),
  context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
```

These modules are reference adapters, not framework ownership claims. A
`Threadline.Integrations.*` module should adapt host state into `Threadline.Plug`
or `Threadline.Job`; it should not redefine those contracts.

## Operator-surface composition via `authorize_fn` and `export_authorize_fn`

The operator surface is one breadth contract with two transport faces:

- LiveView mount/auth via `authorize_fn`
- scoped investigation queries via optional `scope_query_fn`
- mounted evidence access via optional `evidence_authorize_fn`
- HTTP export auth via optional `export_authorize_fn`

The host still owns authentication and authorization semantics. Threadline
standardizes where those hooks plug in; it does not define who the user is,
which roles exist, or how tenancy is modeled.

That same boundary applies to the evidence plane. Threadline may persist
evidence about its own governance and support-scope posture, but it does not
introduce a Threadline-owned RBAC system, tenancy DSL, approval workflow,
legal-hold flow, or vendor-reporting suite.

When a host returns `{:ok, scope}` from `authorize_fn`, keep that scope
host-owned and pair it with `scope_query_fn` if you want mounted reads to narrow
by tenant, organization, or another local concept. `scope_query_fn` is the
query seam for timeline, actor, transaction, export, or any future surface your
host explicitly proves. Threadline carries the scope through; it does not
invent a policy DSL around it.

Apply that same host-owned rule to `evidence_authorize_fn`: it gates the mounted
evidence capability, but it does not define a Threadline role model, tenant
policy, or blanket permission vocabulary.

### Secure-by-default mount boundary

`threadline_operator_surface/2` is the supported mount boundary. It requires one
of these conditions at compile time:

- mount inside a router scope that already has `pipe_through`
- provide `:authorize_fn`
- explicitly acknowledge unauthenticated mounting

Anything outside that boundary is outside the supported surface story.

When that mount also receives `actor_fn`, the standard route path
auto-installs `Threadline.OperatorSurface.SessionPlug` before the LiveView
routes. That keeps actor-owned saved views and similar UI features on the same
`ActorRef` contract as request-path capture without extra adopter wiring.

### Shared authorization vocabulary

`authorize_fn` is the canonical operator-surface callback. It is invoked
directly as a 1-arity function. The recommended callback shape is one shared
host-owned function that accepts `%{assigns: assigns}` so it can authorize both
the LiveView socket and the export fallback mirror without transport-specific
function heads.

```elixir
threadline_operator_surface "/audit",
  repo: MyApp.Repo,
  authorize_fn: &MyApp.Audit.authorize_operator/1,
  scope_query_fn: &MyApp.Audit.scope_operator_query/3
```

```elixir
def authorize_operator(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{role: :admin} ->
      :ok

    %{role: :support, organization_id: org_id} ->
      {:ok, %{access: :support_read_only, organization_id: org_id}}

    _ ->
      {:error, :unauthorized}
  end
end
```

`Threadline.OperatorSurface.Auth` treats these results as the public contract:

- `:ok` or `true` grants access
- `{:ok, scope}` grants access and stores `scope` in `:threadline_scope`
- any other result denies access
- raised errors deny access

That `scope` is opaque and host-owned. Threadline carries it as data; it does
not define a role enum, permissions DSL, tenancy DSL, or page-level
authorization language around it.

If both session actor data and a scope fallback actor are present, session actor
wins. Scope fallback stays compatibility-only, and mismatches emit observable
telemetry rather than silently replacing the session-owned actor identity. In
other words: session actor wins, scope fallback does not silently override it.

`export_authorize_fn` is optional and should stay an advanced override. When
present, it is called with `conn` directly for export requests:

```elixir
threadline_operator_surface "/audit",
  repo: MyApp.Repo,
  authorize_fn: &MyApp.Audit.authorize_operator/1,
  export_authorize_fn: &MyApp.Audit.authorize_operator_export/1
```

When `export_authorize_fn` is absent, export auth deliberately falls back to
`authorize_fn` through a synthetic mirror:

```elixir
mirror = %{assigns: conn.assigns}
authorize_fn.(mirror)
```

That fallback is part of the public contract. If you want one host-owned
authorization function to cover both transport faces, write it against
`%{assigns: assigns}` rather than LiveView-only helpers. If you need a stricter
export posture than the mounted surface, provide `export_authorize_fn` as a
deliberate override rather than teaching two primary authorization vocabularies.

Both transport faces share the same telemetry event
`[:threadline, :operator_surface, :authorize]`, the same granted/denied/error
result vocabulary, and the same `:threadline_scope` assign semantics.

For background exports, keep one actor-owned Threadline download route keyed by
the export job ID. Local storage resolves to `send_file` behind that boundary;
adapter-backed storage resolves `download_url/2` only after authorization. This
preserves one operator action while letting the host keep ownership of Oban
supervision and external storage infrastructure.

## Canonical references

- Request path and additive override validation: `lib/threadline/plug.ex`
- Job-path serialized context helpers: `lib/threadline/job.ex`
- Soft-loaded reference adapter model: `lib/threadline/integrations/sigra.ex`
- Secure operator-surface mount boundary: `lib/threadline/operator_surface/router.ex`
- LiveView auth hook: `lib/threadline/operator_surface/auth.ex`
- HTTP export auth parity and fallback mirror: `lib/threadline/operator_surface/export_auth_plug.ex`

Use this guide when you need the host/framework breadth contract. Use
`guides/operator-surface.md` for the screen-level mount walkthrough and
`guides/integrations/sigra.md` for the current first-party reference adapter.
