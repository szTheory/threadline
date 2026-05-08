# How Threadline works

This is the crash-course guide. Read it when you want the mental model first and the API details second. For the exact seam contracts, keep using the [integration contracts](integration-contracts.md), [operator surface](operator-surface.md), [domain reference](domain-reference.md), and [Phoenix SaaS getting-started guide](getting-started-saas.md).

## The short version

Threadline is embedded audit infrastructure for Phoenix, Ecto, and PostgreSQL apps.

The memorable formula is:

`DB truth` + `app intent` + `operator tooling`

- `DB truth` = trigger-captured `AuditTransaction` + `AuditChange`
- `app intent` = `Threadline.record_action/2`
- `operator tooling` = timelines, actor windows, incident bundles, exports, and the optional `/audit` surface

Threadline is:

- a library you embed into your app
- a read-heavy investigation surface with a small write-side semantic helper
- host-owned on auth, tenancy, and roles

Threadline is not:

- event sourcing
- a remote SaaS
- an auth framework
- a write-capable admin backend

## The flow

The common loop is:

1. A request enters the host app.
2. `Threadline.Plug` attaches request-scoped audit context and the host decides the actor.
3. Your app writes data in a normal database transaction.
4. PostgreSQL triggers capture the physical row changes.
5. `Threadline.record_action/2` records the semantic intent when you want the "who did what and why" layer.
6. Operators inspect the result through the query APIs, Mix tasks, or the mounted `/audit` surface.

That makes Threadline useful in both of these shapes:

```elixir
plug Threadline.Plug, actor_fn: &MyApp.Audit.current_actor/1

{:ok, _action} =
  Threadline.record_action(:post_published,
    repo: MyApp.Repo,
    actor: actor_ref,
    correlation_id: "req_123"
  )
```

## Architecture layers

### 1. Capture substrate

PostgreSQL triggers write the durable audit rows. The core facts are `AuditTransaction` and `AuditChange`; the audit tables are the source of truth for row-level history.

This layer answers:

- What actually changed?
- In which transaction?
- At what time?

It does not answer ownership or policy questions on its own.

### 2. Host-owned seams

Threadline intentionally keeps auth and tenancy on the host side.

- `Threadline.Plug` owns request-path capture context.
- `Threadline.Job` owns serialized job-path context.
- `Threadline.Integrations.*` owns soft-loaded reference adapters.
- `threadline_operator_surface/2` owns the mount boundary for the optional operator UI.

The host decides who the actor is, which request context matters, and whether support access is admin-only or read-only.

### 3. Investigation layer

These are the read APIs most adopters use first:

- `Threadline.history/3` for a row's history
- `Threadline.timeline/2` for an eager slice
- `Threadline.timeline_page/2` for larger windows
- `Threadline.incident_bundle/2` for a single-transaction drill-down
- `Threadline.as_of/4` for point-in-time reconstruction
- `Threadline.export_json/2` for a machine-friendly export

Rule of thumb: use the eager helpers when the window is small enough to read in one shot, and the paged helper when it is not.

### 4. Operator surface

The `/audit` surface is optional and lives in-tree for now. It gives you a host-mounted UI for the same investigation questions as the library APIs and Mix tasks.

That means the library and the UI answer the same questions:

- `timeline` and `/audit`
- `incident_bundle/2` and `mix threadline.incident`
- `export_json/2` and `mix threadline.export`
- `trigger_coverage/1` and `mix threadline.health.coverage`
- policy drift checks and `mix threadline.policy.show`

## Personas and JTBD

| Persona | Job to be done | Primary surface |
|---------|----------------|-----------------|
| App integrator | Add durable audit capture to a Phoenix app without adopting a second platform. | `Threadline.Plug`, `record_action/2`, getting-started docs |
| Support / ops | Answer "what happened?" quickly during a ticket, incident, or customer escalation. | `timeline/2`, `timeline_page/2`, `incident_bundle/2`, `/audit` |
| Security / compliance | Prove coverage, retention, redaction, and drift are behaving honestly. | health tasks, policy viewer, release docs |
| Maintainer / platform engineer | Keep the support matrix honest and avoid accidental auth-model drift. | `guides/upgrade-path.md`, `guides/integration-contracts.md`, planning docs |

The library exists to make those four personas overlap cleanly instead of forcing each one to build a different audit story.

## Public API surface

If you only remember one thing, remember this grouping:

### Write-side

- `Threadline.Plug` for request capture context
- `Threadline.record_action/2` for semantic audit events

### Read-side

- `Threadline.history/3`
- `Threadline.timeline/2`
- `Threadline.timeline_page/2`
- `Threadline.incident_bundle/2`
- `Threadline.as_of/4`
- `Threadline.export_json/2`

### Operator parity

- `mix threadline.incident`
- `mix threadline.export`
- `mix threadline.health.coverage`
- `mix threadline.policy.show`
- `threadline_operator_surface/2`

The read-side APIs are the stable core. The operator surface and Mix tasks are convenience layers on top of the same investigation model.

## Evolution so far

- `0.1.x` established the capture substrate and semantics layer.
- `0.2.x` hardened the query, continuity, and retention story.
- `0.3.x` brought the first serious host-integration seams and example-app path.
- `0.4.x` added the optional operator surface and its first investigation screens.
- `0.5.0` tightened the breadth story: honest support lanes, shared host-owned auth seams, and a clearer optional-in-tree position for the UI.

That evolution matters because the library did not start as a product-console project. It became one as the investigation path matured.

## Natural next work

The next chunks that feel naturally adjacent are:

- retention admin with visible last-purge history and operator feedback
- saved views or bookmarks for repeated investigations
- queued or scheduled exports with a status surface
- broader first-party host adapters beyond the current Sigra reference path
- a `threadline_web` split only if objective extraction triggers show up

Those are the kinds of problems that usually belong in the next milestone once adopters start using the current surface for real.

## Where to go next

- [README](../README.md) for the top-level map
- [Getting started with Phoenix SaaS](getting-started-saas.md) for the install-first path
- [Integration contracts](integration-contracts.md) for the host seams
- [Operator surface](operator-surface.md) for mount, auth, and screens
- [Domain reference](domain-reference.md) for vocabulary and API routing
- [Support lanes and upgrade path](upgrade-path.md) for the support matrix
