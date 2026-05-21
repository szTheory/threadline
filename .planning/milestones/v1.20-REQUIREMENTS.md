# Requirements: v1.20 - Scale and Governance Depth

## Themes

- **Safe Pruning:** Deleting millions of old audit rows without bringing down production databases via autovacuum-aware batching.
- **Async Execution:** Shifting massive CSV exports from synchronous HTTP requests to durable, queue-backed background jobs.
- **Operator Ergonomics:** Giving operators the ability to save common queries and monitor background task health.
- **Zero-Intrusion Scaling:** Building these capabilities with standard OTP primitives (`Task.Supervisor`) by default, while exposing clean Behaviours for Oban and S3 to support enterprise multi-node deployments.

## V1 Requirements

### Infrastructure & State (INFRA)
- **INFRA-01**: Introduce Ecto schemas and migrations for `threadline_export_jobs`, `threadline_retention_runs`, and `threadline_saved_views`.
- **INFRA-02**: Define `Threadline.Storage` and `Threadline.ExportQueue` behaviours to formalize pluggable backend components for storage and background task orchestration.

### Retention Engine (RET)
- **RET-01**: Implement a batched, autovacuum-aware retention pruner (`Threadline.Retention.Pruner`) that sleeps between chunked deletes to avoid long-running locks.
- **RET-02**: Track retention runs in the DB (`threadline_retention_runs`) with start/stop times, duration, and deleted row counts.
- **RET-03**: Provide a "Retention History" LiveView page inside the operator surface to monitor active pruning and past runs.

### Saved Views (VIEW)
- **VIEW-01**: Implement actor-owned saved filter states relying strictly on the host's `actor_fn` to determine ownership without forcing a User schema dependency.
- **VIEW-02**: Add a UI form to the existing raw timeline browse page to create, apply, and delete saved views.

### Async Exports (EXP)
- **EXP-01**: Implement a built-in export orchestrator using `Task.Supervisor` and Ecto state (`threadline_export_jobs`) to run exports without blocking LiveView.
- **EXP-02**: Stream massive CSV exports safely to `Threadline.Storage.Local` using `Repo.stream` inside a database transaction and `NimbleCSV`.
- **EXP-03**: Add an "Export Status" UI inside the operator surface to monitor pending/running/completed exports and download completed artifacts.
- **EXP-04**: Implement automatic expiration and cleanup of old export artifacts (e.g., older than 7 days) to prevent local or cloud storage bloat.

### Scale Adapters (ADAPT)
- **ADAPT-01**: Provide a documented, optional Oban queue adapter (`Threadline.ExportQueue.Oban`) for enterprise scaling.
- **ADAPT-02**: Provide a documented, optional S3 storage adapter (`Threadline.Storage.S3`) using `ex_aws_s3` for multi-node deployments.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01    | Phase 75 | Pending |
| INFRA-02    | Phase 75 | Pending |
| RET-01      | Phase 76 | Pending |
| RET-02      | Phase 76 | Pending |
| RET-03      | Phase 76 | Pending |
| VIEW-01     | Phase 77 | Pending |
| VIEW-02     | Phase 77 | Pending |
| EXP-01      | Phase 78 | Pending |
| EXP-02      | Phase 78 | Pending |
| EXP-03      | Phase 78 | Pending |
| EXP-04      | Phase 78 | Pending |
| ADAPT-01    | Phase 79 | Pending |
| ADAPT-02    | Phase 79 | Pending |
