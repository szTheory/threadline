# Architecture Patterns

**Project:** Threadline
**Researched:** 2026-05-08 (v1.20 - Scale and Governance Depth)
**Overall Confidence:** HIGH

## Recommended Architecture

v1.20 expands Threadline's footprint by introducing persistent state for governance and background operations, shifting from a purely "capture and read" model to a "manage and schedule" model.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Threadline.Retention.Pruner` | Executes batched deletions to enforce retention policy. | `Ecto.Repo` (DB), `Threadline.Retention.Run` (Schema) |
| `Threadline.Export.Orchestrator` | Manages the queueing, execution, and state transitions of async exports. | `Task.Supervisor`, `Ecto.Repo` (`threadline_export_jobs`) |
| `Threadline.Storage` (Behaviour) | Abstraction for storing and retrieving large CSV payloads. | Local File System (default), S3 (optional) |
| `Threadline.Governance` | Domain context for Saved Views and access policies. | `Ecto.Repo` (`threadline_saved_views`) |
| `Threadline.OperatorSurface` | UI components for managing all of the above. | All domain contexts, Phoenix LiveView |

### Data Flow: Queued Exports

1. **Request:** Operator initiates an export via the UI.
2. **Queue:** `Export.Orchestrator` creates an `ExportJob` record (state: `pending`, actor: operator).
3. **Execution:** UI kicks off an async task (or Oban picks it up). Task updates state to `running`.
4. **Stream:** `Ecto.Repo.stream/2` runs the query, pipes through `NimbleCSV`, and writes to `Threadline.Storage`.
5. **Completion:** Task updates `ExportJob` state to `completed` with a storage reference URI.
6. **Delivery:** Operator clicks "Download" in UI, LiveView streams the file from `Storage` to the client.

### Data Flow: Retention Pruning

1. **Trigger:** A cron job, API call, or `GenServer` ticker initiates the pruning process.
2. **Setup:** A new `RetentionRun` record is created (status: `running`).
3. **Chunking:** A recursive function executes `DELETE FROM threadline_audits WHERE inserted_at < ? LIMIT 5000`.
4. **Loop:** It sleeps briefly to allow `autovacuum`, then repeats until 0 rows are deleted.
5. **Finalize:** Updates `RetentionRun` with `rows_deleted`, `duration_ms`, and status `completed`.

## Patterns to Follow

### Pattern 1: Pluggable Backend Behaviours
**What:** Define explicit Behaviours for features that often require cloud infrastructure (Storage, Queues).
**When:** For Export Storage and Export Queuing.
**Example:**
```elixir
defmodule Threadline.Storage do
  @callback put(key :: String.t(), stream :: Enumerable.t()) :: {:ok, uri :: String.t()} | {:error, term()}
  @callback get(uri :: String.t()) :: {:ok, Enumerable.t()} | {:error, term()}
end
```
Provide a `Threadline.Storage.Local` default that uses `File.stream!`.

### Pattern 2: Batched Ecto Deletions
**What:** Deleting records using explicit `limit` and subqueries to avoid long-running locks.
**When:** Implementing the Retention Pruner.
**Example:**
```elixir
# In Ecto, a batched delete looks like this to utilize index scans effectively:
query = from a in Audit, where: a.inserted_at < ^threshold, select: a.id, limit: 5000
from(a in Audit, where: a.id in subquery(query)) |> Repo.delete_all()
```

### Pattern 3: Actor-Owned Governance State
**What:** Saved Views and Exports belong to the person who created them. Since Threadline does not define the `User` schema, it uses the extracted `actor` metadata.
**When:** Persisting `SavedView` and `ExportJob` records.
**Instead of:** `belongs_to :user, MyApp.Accounts.User`
**Do:** `field :actor_id, :string` (derived from the host's `actor_fn`).

## Anti-Patterns to Avoid

### Anti-Pattern 1: Naive `Repo.delete_all`
**What:** `Repo.delete_all(from a in Audit, where: a.inserted_at < ^30_days_ago)`
**Why bad:** If the table has 50 million rows and 10 million are older than 30 days, this single transaction will lock the table, generate massive WAL bloat, and likely time out, taking down the database.
**Instead:** Batch deletes in chunks of 1,000 to 5,000 rows, yielding between chunks.

### Anti-Pattern 2: LiveView Blocking Streams
**What:** Running a 2-minute CSV export stream inside a LiveView event handler.
**Why bad:** Blocks the LiveView process, ignores heartbeat, causes disconnects. If the user navigates away, the export silently dies.
**Instead:** Hand off to a `Task.Supervisor` (or Oban), update an Ecto table, and have LiveView poll or subscribe to pubsub for completion.

### Anti-Pattern 3: Hardcoding `/tmp/` Storage
**What:** Storing exports in `/tmp/` on the local disk in a distributed application.
**Why bad:** If Node A processes the export, and the user's browser requests the download from Node B, it results in a 404.
**Instead:** Offer the `Threadline.Storage` behaviour so adopters can use S3/GCS. For single-node apps, local storage is fine, but it must be an explicit choice.

## Scalability Considerations

| Concern | Small Adopter (1 Node, 1M rows) | Enterprise Adopter (Multi-node, 100M+ rows) |
|---------|--------------------------------|--------------------------------------------|
| **Exports** | Uses `Task` and `Local` storage. | Configures `Oban` adapter and `S3` storage adapter. |
| **Retention** | Standard Ecto batched deletes keep DB healthy. | Disables built-in pruner, relies on native Postgres Partitioning managed via external tools. |
