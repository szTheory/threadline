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

## Next steps

- [Return to the mounted operator workflow](operator-surface.md).
- [Wire telemetry alerts into your go-live checklist](production-checklist.md).
