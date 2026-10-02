# Telemetry

Threadline emits `:telemetry` events for every capture, health, export,
retention, and operator-surface milestone it drives internally. No event
carries row values, actor identifiers, correlation ids, or free-text reasons —
measurements and metadata stay limited to counts, durations, outcome atoms,
and structural facts such as which keys a scope map used. Attach your own
handlers to build metrics, alerts, and dashboards on top of this contract.

## Events

| Event | Measurements | Metadata | When emitted |
|---|---|---|---|
| `[:threadline, :transaction, :committed]` | `table_count` | — | an AuditTransaction is committed |
| `[:threadline, :action, :recorded]` | `status` | — | Threadline.record_action/2 completes, whether it succeeds or fails |
| `[:threadline, :health, :checked]` | `covered`, `expected_uncovered`, `uncovered` | — | Threadline.Health.trigger_coverage/1 returns |
| `[:threadline, :health, :checked, :error]` | — | `exception` | a polled coverage check raises |
| `[:threadline, :health, :findings_checked]` | `errors`, `warnings` | — | Threadline.Health.trigger_findings/1 returns |
| `[:threadline, :operator_surface, :authorize]` | `result` | `path`, `scope_keys` | an operator-surface mount or request is authorized, denied, or errors |
| `[:threadline, :operator_surface, :export_authorize]` | `count`, `result` | — | an export-specific authorization check raises |
| `[:threadline, :operator_surface, :actor_ref_mismatch]` | `count` | — | the session actor and the scope-derived actor disagree |
| `[:threadline, :export, :completed]` | `duration`, `row_count` | `format`, `truncated` | an export (eager CSV/JSON, the async orchestrator job, or the chunked operator-surface download) finishes successfully |
| `[:threadline, :export, :failed]` | `duration`, `row_count` | `format`, `error_kind`, `exception` | an export (eager CSV/JSON, the async orchestrator job, or the chunked operator-surface download) fails |
| `[:threadline, :retention, :purge, :start]` | `monotonic_time`, `system_time` | `dry_run`, `telemetry_span_context` | after purge/1's input checks pass, when the purge work begins |
| `[:threadline, :retention, :purge, :stop]` | `batches_run`, `deleted_changes`, `deleted_transactions`, `duration`, `monotonic_time` | `dry_run`, `telemetry_span_context` | when the run or preview returns |
| `[:threadline, :retention, :purge, :exception]` | `duration`, `monotonic_time` | `dry_run`, `kind`, `reason`, `stacktrace`, `telemetry_span_context` | when the database raises mid-run |
| `[:threadline, :retention, :batch_purged]` | `deleted_changes`, `deleted_transactions`, `duration` | — | after a purge_loop step's change delete_all and full orphan drain both return, once per step including the terminating empty one |

## Attaching handlers

Attach one handler per family (or `:telemetry.attach_many/4` across the
whole family) with a module-function capture, not an anonymous function —
anonymous functions cannot be hot-code upgraded and are harder to detach
individually in tests.

**Capture** — transaction commits and recorded actions:

```elixir
:telemetry.attach_many(
  "my-app-capture",
  [
    [:threadline, :transaction, :committed],
    [:threadline, :action, :recorded]
  ],
  &MyApp.Instrumentation.handle_capture_event/4,
  nil
)
```

**Health**:

```elixir
:telemetry.attach_many(
  "my-app-health",
  [
    [:threadline, :health, :checked],
    [:threadline, :health, :checked, :error],
    [:threadline, :health, :findings_checked]
  ],
  &MyApp.Instrumentation.handle_health_event/4,
  nil
)
```

**Export** — `[:threadline, :export, :completed]` and `[:threadline, :export,
:failed]` fire once per logical export, from `Threadline.Export.to_csv_iodata/2`,
`to_json_document/2`, the async `Threadline.Export.Orchestrator` job, and the
chunked operator-surface download. If your host builds its own export flow on
top of the lower-level stream primitives instead of these four entry points,
your code owns emitting its own completion/failure events for that unit of
work — Threadline does not emit on your behalf there.

```elixir
:telemetry.attach_many(
  "my-app-export",
  [
    [:threadline, :export, :completed],
    [:threadline, :export, :failed]
  ],
  &MyApp.Instrumentation.handle_export_event/4,
  nil
)
```

**Retention** — the purge span (`:start` / `:stop` / `:exception`) plus the
per-batch event:

```elixir
:telemetry.attach_many(
  "my-app-retention",
  [
    [:threadline, :retention, :purge, :start],
    [:threadline, :retention, :purge, :stop],
    [:threadline, :retention, :purge, :exception],
    [:threadline, :retention, :batch_purged]
  ],
  &MyApp.Instrumentation.handle_retention_event/4,
  nil
)
```

A disabled or misconfigured `Threadline.Retention.purge/1` call emits none of
these — the span opens only after policy resolution and the disabled check
both pass, so there is nothing to subscribe to until a purge actually runs.
`[:threadline, :retention, :purge, :exception]` means PostgreSQL raised
mid-run; its `reason`/`stacktrace` metadata is forwarded for incident
diagnosis only — see [Keep row data out of your
handlers](#keep-row-data-out-of-your-handlers) before logging it anywhere
durable. Each `[:threadline, :retention, :batch_purged]` event fires before
the outer caller's own transaction (if any) commits, so a handler that reads
its own database inside the handler can observe a batch that is not yet
externally visible. A dry run's `[:threadline, :retention, :purge, :stop]`
counts are a preview estimate, not a result — for the row totals an
actually-completed purge deleted, sum `deleted_changes`/`deleted_transactions`
from the `batch_purged` events instead.

**Operator surface** — authorization outcomes and the actor-mismatch counter:

```elixir
:telemetry.attach_many(
  "my-app-operator-surface",
  [
    [:threadline, :operator_surface, :authorize],
    [:threadline, :operator_surface, :export_authorize],
    [:threadline, :operator_surface, :actor_ref_mismatch]
  ],
  &MyApp.Instrumentation.handle_operator_surface_event/4,
  nil
)
```

`[:threadline, :operator_surface, :actor_ref_mismatch]` is a pure incidence
counter (`%{count: 1}`, no metadata) — it tells you a mismatch happened, not
which actor or scope. `result` on `authorize`/`export_authorize` and `status`
on `[:threadline, :action, :recorded]` are atom-valued measurements
(`:granted` / `:denied` / `:error`, or `:ok` / `:error`), not strings — match
on the atom, not on a string you format yourself.

## Metrics with telemetry_metrics

The example below is adopter code — Threadline never adds the
`telemetry_metrics` dependency itself. Durations (`duration`,
`monotonic_time`) are native time units; declare `unit: {:native,
:millisecond}` so your metrics backend renders milliseconds instead of raw
VM-native units.

```elixir
[
  Telemetry.Metrics.summary("threadline.export.completed.duration",
    event_name: [:threadline, :export, :completed],
    measurement: :duration,
    unit: {:native, :millisecond}
  ),
  Telemetry.Metrics.counter("threadline.export.failed.count",
    event_name: [:threadline, :export, :failed],
    tags: [:error_kind]
  ),
  Telemetry.Metrics.summary("threadline.retention.purge.duration",
    event_name: [:threadline, :retention, :purge, :stop],
    measurement: :duration,
    unit: {:native, :millisecond},
    tags: [:dry_run]
  ),
  Telemetry.Metrics.counter("threadline.retention.batch_purged.count",
    event_name: [:threadline, :retention, :batch_purged]
  )
]
```

## Handlers must not raise

`:telemetry` isolates one failing handler from the event it was attached to,
not from your application's stability guarantees — a raising handler is
caught, logged, and **detached from every event in the `attach_many` call
that registered it**, not only the one that raised. `[:telemetry, :handler,
:failure]` fires when this happens, naming the failed handler's id. Attach a
separate handler to that event if you want to alert when one of your own
handlers goes dark:

```elixir
:telemetry.attach(
  "my-app-handler-failure-alert",
  [:telemetry, :handler, :failure],
  &MyApp.Instrumentation.handle_handler_failure/4,
  nil
)
```

A raising handler never changes Threadline's own result: export, purge, and
every other Threadline operation returns its normal value regardless of
whether your handler crashed while observing it.

## Cardinality

Never tag a metric on an id-shaped value — `table_pk`, a correlation id, an
actor identifier, or any other high-cardinality value turns a bounded set of
time series into an unbounded one. `scope_keys` on
`[:threadline, :operator_surface, :authorize]` is the **keys** of your
host-returned scope map, not its values; if your host happens to use
identity-shaped values as map keys (unusual, but not forbidden), tagging on
`scope_keys` would reintroduce the same cardinality problem through the back
door. Tag on `format`, `error_kind`, `dry_run`, or other low-cardinality
enums instead.

## Keep row data out of your handlers

Threadline's own events never carry row values, actor identifiers,
correlation ids, or free-text reasons — that boundary is enforced in this
module and proven by a dedicated property test. A handler you write can still
reopen that leak: never log an event's `:params` (repo-query telemetry
carries plaintext bind values — see [Observing Threadline's
queries](#observing-threadlines-queries) below) or a purge-exception's
`reason`/`stacktrace` verbatim to a sink your audit boundary does not cover,
and never attach row data of your own onto a Threadline event's measurements
or metadata before forwarding it downstream.

## Next steps

- [Return to the mounted operator workflow](operator-surface.md).
- [Wire telemetry alerts into your go-live checklist](production-checklist.md).
