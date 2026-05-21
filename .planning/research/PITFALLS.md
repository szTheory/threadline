# Domain Pitfalls

**Domain:** Audit Logging / Operator UI Governance
**Researched:** 2026-05-08 (v1.20 - Scale and Governance Depth)
**Overall Confidence:** HIGH

## Critical Pitfalls

Mistakes that cause rewrites or major production incidents.

### Pitfall 1: Naive `DELETE FROM` (The Autovacuum Trap)
**What goes wrong:** Adopters write a cron job that runs `DELETE FROM threadline_audits WHERE inserted_at < '30 days ago'`.
**Why it happens:** It works perfectly in dev and staging where there are only 10,000 rows.
**Consequences:** In production, deleting 5 million rows at once creates massive lock contention. Postgres doesn't free the disk space immediately (they become "dead tuples"). The resulting WAL bloat and index bloat can bring down the primary database, and the massive delete transaction will likely time out.
**Prevention:** Threadline MUST provide a safe, chunked deletion mechanism out-of-the-box (`Threadline.Retention.Pruner`) that sleeps between small batches to allow Postgres autovacuum to run.
**Detection:** High CPU utilization on the database, replication lag spikes, and `transaction timeout` errors during the pruning window.

### Pitfall 2: Stateful Local Disk in Multi-Node Setups
**What goes wrong:** An operator queues an export. The server generates a 100MB CSV and saves it to `/tmp/export_123.csv`. The UI polls and says "Done! Click to download". The user clicks, and gets a 404.
**Why it happens:** The user's "Download" HTTP request was load-balanced to Node B, but the file was generated on Node A.
**Consequences:** Broken exports, frustrated operators, and support tickets.
**Prevention:** Introduce a `Threadline.Storage` behaviour. Default to local disk for single-node apps, but provide an S3 adapter and loudly document that multi-node deployments MUST configure an external storage adapter or sticky sessions.
**Detection:** 404 errors on `/threadline/exports/:id/download` despite the job showing "Completed".

## Moderate Pitfalls

### Pitfall 1: Enforcing Oban as a Hard Dependency
**What goes wrong:** Threadline decides that because queuing is hard, it will just use Oban and add `{:oban, "~> 2.17"}` to `mix.exs`.
**Prevention:** Threadline's core promise is low intrusion. Build a simple `Task.Supervisor`-backed queue in Ecto for the default case, and provide a `Threadline.ExportQueue` behaviour with an Oban adapter for power users.

### Pitfall 2: Assuming "User" exists for Saved Views
**What goes wrong:** Creating a `threadline_saved_views` table with `user_id uuid REFERENCES users(id)`.
**Prevention:** Threadline is auth-agnostic. Rely on the `actor` (e.g. stringified ID or tuple) extracted by the host's `actor_fn` to determine ownership of Saved Views and Export Jobs. Store it as a plain string or JSONB in the Threadline tables.

## Minor Pitfalls

### Pitfall 1: LiveView Timeouts on CSV Streaming
**What goes wrong:** Exporting 2 million rows via `Repo.stream` directly inside a LiveView event handler.
**Prevention:** Never run unbounded DB streams inside a Phoenix channel process. Always hand off to a background process (Task or GenServer) and have LiveView poll or subscribe for updates.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Retention UI | Assuming the retention pruner will finish quickly. | Treat the pruner as a long-running background job. The UI should display `running` status and row counts periodically. |
| Queued Exports | Streaming massive CSVs causing OOM errors. | strictly use `Ecto.Repo.stream` inside a transaction, pipe through `NimbleCSV`, and write directly to disk/S3 in constant memory. |
