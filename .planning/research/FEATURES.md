# Feature Landscape

**Domain:** Audit Logging / Operator UI Governance
**Researched:** 2026-05-08 (v1.20 - Scale and Governance Depth)
**Overall Confidence:** HIGH

## Table Stakes

Features users expect in an enterprise-grade investigation and governance UI. Missing = product feels like a toy for production environments.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Retention UI** | Need to prove to compliance that data is actually deleted. | Medium | Requires `threadline_retention_runs` table to track start/stop/deleted-count. |
| **Queued Exports** | Exporting 10M rows to CSV takes minutes; HTTP timeouts will kill synchronous requests. | High | Requires job tracking (`threadline_export_jobs`), async execution, and download URI management. |
| **Saved Views** | Operators run the same query (e.g., "All failed logins for Tenant A") repeatedly. Re-typing filters is poor UX. | Low | Simple Ecto schema storing JSON filter state, scoped by `actor_id`. |
| **Drift-Aware Exports** | A user queues an export with a specific schema. 10 minutes later it runs, but the schema changed. | Medium | Use the same schema-freezing mechanics introduced in v1.18 to ensure exports respect point-in-time constraints. |

## Differentiators

Features that set Threadline apart from generic UI generators or simple Ecto plugins.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Pluggable Storage** | "Works on 1 node, scales to 100." Adopters can use Local disk out of the box, or S3 via adapter. | Medium | Define `Threadline.Storage` behaviour. |
| **Host-Owned Actor Scoping** | Saved Views belong to the operator who made them, but without forcing a User schema dependency. | Low | Deriving owner from the `actor_fn` keeps the auth boundary clean. |
| **Autovacuum-Aware Pruning** | Built-in retention doesn't lock the DB; it batches and sleeps. | Medium | Differentiates from naïve `delete_all` scripts that most devs write and abandon. |

## Anti-Features

Features to explicitly NOT build in v1.20.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Enforced Oban Dependency** | Forces adopters to run Oban workers, create Oban tables, and learn Oban just to use Threadline. | Use `Task.Supervisor` + Ecto state for a built-in queue, offer Oban adapter for those who want it. |
| **Native Postgres Partitioning** | Requires composite primary keys and massive DB surgery for existing installations. | Use batched Ecto deletes for standard retention. Leave Partitioning to the host's DB team if they truly need it. |
| **Threadline-Owned User Roles** | We do not know what an "Admin" is. We only know what the host tells us via `actor_fn`. | Rely entirely on the host's authorization wrapper. Provide UI building blocks, let the host define access levels. |

## Feature Dependencies

```text
Host Actor Extraction → Saved Views Ownership (Saved views need an owner)
Async Execution (Task/Oban) → Queued Exports (Cannot block LiveView)
Pluggable Storage → Queued Exports (Need a place to put the CSV)
Batched Deletes → Retention UI (Need a safe way to prune before tracking it)
```

## MVP Recommendation

Prioritize in this order (can be mapped to Phases):
1. **Infrastructure:** Introduce new Schema (`ExportJob`, `RetentionRun`, `SavedView`) and core Behaviours (`Storage`, `Queue`).
2. **Retention Engine:** Implement batched pruner and log to `RetentionRun`.
3. **Operator UI:** Add Retention view, Saved Views form to existing timeline, and Export Status page.
4. **Export Engine:** Implement the async exporter writing to `Threadline.Storage`.

Defer: Complex scheduling (cron UI) for exports. Let the host trigger exports via API if they want scheduled reports.
