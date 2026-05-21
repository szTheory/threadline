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

## The SaaS Builder's JTBD Map

If you are dropping Threadline into your SaaS, you are hiring it to do four very specific jobs.

### Job 1: The "Silent Witness" (Compliance & Baseline)
* **The Scenario:** A SOC2 auditor wants proof of data lineage, or a customer is screaming, "I never deleted that invoice!" You need to know that no matter what happens, the truth is recorded.
* **The Flow:** You run `mix threadline.gen.triggers` to attach PostgreSQL triggers to your tables. You don't touch your Elixir contexts. Even if a junior dev opens an `iex` shell and runs `MyApp.Repo.delete_all()`, the triggers catch it.
* **The JTBD:** *"Give me an airtight, DB-level audit trail without forcing me to rewrite my application code to use special `audit_insert` functions."*

### Job 2: The "Who Did This?" (Attribution & Intent)
* **The Scenario:** A database trigger only knows that the `postgres` database user modified a row. That’s useless for a SaaS. You need to know that `user_id: 42` did it via the `/billing/refund` endpoint.
* **The Flow:** You drop `plug Threadline.Plug` into your router. You configure it to pull the current user from the session. Now, every physical database change is automatically tagged with that human actor. If you want to get fancy, you call `Threadline.record_action(:refund_issued)` in your business logic. 
* **The JTBD:** *"Bridge the gap between physical database mutations and human application semantics so the logs actually make sense."*

### Job 3: The "3 AM Support Ticket" (Investigation & Ops UI)
* **The Scenario:** A customer writes into Zendesk: "My dashboard looks weird since yesterday." Your ops team needs to figure out what state changed without bugging an engineer to write custom SQL.
* **The Flow:** You mount the `/audit` LiveView dashboard in your host app. Support staff log in (using your app's existing auth). They filter the timeline by the customer's `actor_id` or the specific `record_id` and get a visual diff of exactly what fields changed, when, and by whom.
* **The JTBD:** *"Give my support and ops team a safe, read-only window into historical data state so they can unblock customers autonomously."*

### Job 4: The "Data Handoff" (Egress & Reporting)
* **The Scenario:** Legal needs a CSV of every permission change in the `Enterprise` workspace over the last 30 days.
* **The Flow:** Your ops team uses the filter form on the LiveView timeline, hits "Export", and downloads the results. Alternatively, you run `mix threadline.export` in your deployment console.
* **The JTBD:** *"Get the data out of the system in a standard, machine-readable format quickly and safely."*

The library exists to make those personas overlap cleanly instead of forcing each one to build a different audit story.

## The Delta to "Done" (Future Roadmap)

While the read/write core is established, we are targeting four major scale capabilities for future milestones (v1.20+):

- **"Don't OOM My Database" (Lifecycle & Pruning):** Let adopters safely prune old audit logs without locking the production DB or writing manual, autovacuum-aware batching scripts.
- **"The Massive Egress" (Async Scale Adapters):** Let operators export massive datasets (millions of rows) in the background via Oban and stream them safely to local disk or S3.
- **"The Daily Driver" (Operator Ergonomics):** Let ops teams save, name, and share their frequent queries so they don't have to rebuild them.
- **"The Enterprise Firehose" (Streaming / SIEM):** Provide a clean hook to stream captured events out to an external data sink (like Datadog/Splunk) in near-real-time.

## The Line of Diminishing Returns

A great library knows what it *isn't*. Threadline hits the point of diminishing returns—and starts turning into bloated software—if we cross these lines:

1. **Becoming a SIEM:** We are embedded infrastructure. We provide the facts. We will not build anomaly detection ML, chart builders, or pie-graph dashboards.
2. **Owning Auth/RBAC:** Threadline relies on the host app to say "this user is an admin." We will not build user tables or role-permission matrices.
3. **UI-Based Policy Mutation:** Security rules (like "don't log the `passwords` table" or "redact the `ssn` column") must live in code/config. We will not build a UI toggle to turn off logging, as that creates a vector for a rogue admin to disable logging, do something bad, and turn it back on.

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
