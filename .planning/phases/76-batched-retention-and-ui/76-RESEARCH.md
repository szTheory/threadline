# Phase 76: Batched Retention & UI - Research

**Researched:** May 2024
**Domain:** Elixir/PostgreSQL Background Data Pruning & Phoenix LiveView Monitoring
**Confidence:** HIGH

## Summary

Phase 76 introduces safe background execution and observability for Threadline's retention policy. Currently, `Threadline.Retention.purge/1` deletes expired rows in a tight loop which, on large datasets, can exhaust PostgreSQL resources and block `autovacuum`. This phase wraps that logic in an autovacuum-aware pruner that sleeps between batches to yield database locks.

Additionally, we need to track the execution history of these runs in the database so operators can audit the deletion process. A Phoenix LiveView page in the Operator Surface will monitor active pruning and past runs. A tracking schema (`threadline_retention_runs`) was already defined in Phase 75 Governance's migration, so we will utilize the `Threadline.Governance.RetentionRun` schema to store start times, stop times, and deleted row counts.

**Primary recommendation:** Implement `Threadline.Retention.Pruner` as a GenServer using `Process.send_after/3` for scheduling and a PostgreSQL advisory lock (`pg_try_advisory_lock`) to prevent concurrent pruning in a multi-node cluster. Update `Threadline.Retention.purge/1` to accept a `:sleep_ms` option, wrapping the chunked loops with schema inserts to track progress in `threadline_retention_runs`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| DB Run Tracking | Database | API / Backend | Persistent tracking of prune jobs across cluster nodes and restarts via `threadline_retention_runs`. |
| Chunked DB Deletions | API / Backend | Database | `Threadline.Retention` loops with `Process.sleep/1` to yield DB locks, allowing `autovacuum` to clean up dead tuples. |
| Background Scheduling | API / Backend | — | A GenServer `Threadline.Retention.Pruner` schedules itself via `Process.send_after/3` avoiding external dependencies like Oban. |
| Retention Monitor UI | Frontend Server (SSR)| Browser | Phoenix LiveView renders the history table & active status inside the Operator Surface. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto SQL | ~> 3.10 | Database querying | Threadline's core storage mechanism. `pg_try_advisory_lock` is executed through Ecto. |
| Phoenix LiveView | ~> 1.0 | Operator UI | Native Elixir interactive UI without SPAs. Native real-time streaming capability. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GenServer timer | Oban | Oban is the gold standard for Elixir background jobs, but as a library, Threadline avoids forcing external heavy dependencies on adopters. |
| `threadline_retention_runs` lock | Advisory Locks | Advisory locks are native to PG and instantly released if the node dies, preventing a stuck "running" state in the DB if a node crashes mid-prune. We'll use advisory locks to guarantee single-execution across a cluster. |

**Installation:**
```bash
# N/A - Ecto and Phoenix LiveView are already defined in mix.exs
```

## Architecture Patterns

### System Architecture Diagram

```
Operator/Timer -> [Threadline.Retention.Pruner]
                        | (Acquires Advisory Lock)
                        v
         [Threadline.Retention (purge_loop)]
           /        |           \
      (Batch 1)  (Sleep Nms) (Batch 2)
          |                     |
     [PostgreSQL: audit_changes (DELETE)]
                        |
                        v
    [PostgreSQL: threadline_retention_runs (INSERT/UPDATE)]
                        ^
                        |
    [Operator Surface: Retention History LiveView] <- Operator
```

### Pattern 1: Autovacuum-Aware Chunking
**What:** Deleting rows in a massive loop can exhaust lock limits or block vacuuming. We yield to the DB by sleeping after each small batch.
**When to use:** Any time deleting > 10,000 rows in PostgreSQL.
**Example:**
```elixir
# In Threadline.Retention
Enum.reduce_while(1..max_batches, {0, 0, 0}, fn idx, {tc, tt, _} ->
  n1 = delete_change_batch(repo, cutoff, batch_size)
  
  if sleep_ms > 0 and n1 > 0 do
    Process.sleep(sleep_ms)
  end
  # ...
end)
```

### Pattern 2: Cluster Singleton via Advisory Locks
**What:** Running a timer-based GenServer on all nodes but ensuring only one executes the destructive task.
**When to use:** Library-provided background workers where `global` registration or `Oban` is unavailable.
**Example:**
```elixir
def handle_info(:prune, state) do
  lock_id = :erlang.phash2("threadline_retention_pruner")
  case Ecto.Adapters.SQL.query(state.repo, "SELECT pg_try_advisory_lock($1)", [lock_id]) do
    {:ok, %{rows: [[true]]}} ->
      try do
        Threadline.Retention.purge(repo: state.repo, sleep_ms: state.sleep_ms)
      after
        Ecto.Adapters.SQL.query(state.repo, "SELECT pg_advisory_unlock($1)", [lock_id])
      end
    _ ->
      :ok # Another node is currently holding the lock
  end
  schedule_next_prune(state.interval_ms)
  {:noreply, state}
end
```

### Anti-Patterns to Avoid
- **Blocking autovacuum:** Deleting millions of rows in a single transaction. This balloons WAL size and causes table bloat. The chunked loop must NOT be inside a single `Repo.transaction`.
- **Assuming `status: "running"` is reliable:** If a node crashes mid-purge, the run record stays "running" forever. The UI must treat "running" jobs older than 24h as failed, or the GenServer must clean up orphaned runs on boot.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Single Node Execution | Distributed consensus algorithm | `pg_try_advisory_lock` | PostgreSQL natively handles session-based lock cleanup if the connection dies (e.g. node crash). |
| Real-time UI Updates | Polling HTTP endpoints | Phoenix LiveView + PubSub | LiveView natively pushes updates to the client when the DB is modified or the GenServer broadcasts progress. |

## Common Pitfalls

### Pitfall 1: Stale "Running" Records
**What goes wrong:** A retention run is marked `status: "running"` but the node crashes or is restarted. The record never updates to completed/failed.
**Why it happens:** Hard shutdowns bypass `terminate/2` callbacks.
**How to avoid:** The LiveView UI should display runs running for > 24 hours as "Abandoned", and the `Pruner` startup could query and fail any dangling runs before it starts a new one.

### Pitfall 2: Locking Out Application Queries
**What goes wrong:** Even batched deletes can lock indexes.
**Why it happens:** Deleting rows requires acquiring row-level locks and modifying indexes. If batches are too large (e.g., 50,000) or sleep is 0, normal writes to `audit_changes` might timeout.
**How to avoid:** Default `batch_size: 500` and default `sleep_ms: 50` allows write concurrency.

### Pitfall 3: LiveView Streaming Reset
**What goes wrong:** The LiveView list of history runs flickers or duplicates.
**Why it happens:** LiveView `stream_insert` not handling the DOM `id` correctly.
**How to avoid:** Ensure the `id` DOM element matches the stream config and use `stream_insert` to update the active running job progressively without resetting the stream.

## Code Examples

### Tracking Run in Database
```elixir
alias Threadline.Governance.RetentionRun

def record_run_start(repo) do
  %RetentionRun{}
  |> RetentionRun.changeset(%{status: "running", started_at: DateTime.utc_now()})
  |> repo.insert!()
end

def record_run_finish(repo, run, counts) do
  run
  |> RetentionRun.changeset(%{
    status: "completed",
    completed_at: DateTime.utc_now(),
    deleted_count: counts.deleted_changes + counts.deleted_transactions,
    duration_ms: DateTime.diff(DateTime.utc_now(), run.started_at, :millisecond)
  })
  |> repo.update!()
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unmonitored batching | DB-tracked runs | Phase 76 | Operators can audit that pruning is actually occurring and how many records are dropped. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `threadline_retention_runs` table exists | Summary | [ASSUMED] The migration from Phase 75 Governance must have been executed by adopters. If they haven't, pruning will fail. We should document an upgrade note. |

## Open Questions (RESOLVED)

1. **How does the LiveView get real-time progress?**
   - What we know: The `Pruner` loops over batches and takes time.
   - What's unclear: Should it broadcast to `Phoenix.PubSub` every 10 batches so the UI updates `deleted_count` in real time?
   - Recommendation: No, stick to the `Process.send_after` polling pattern found in `CoverageLive` (as mapped in PATTERNS.md). This avoids PubSub complexity and keeps the implementation simpler and consistent with existing patterns.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `MIX_ENV=test mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RET-01 | Pruner GenServer sleeps and yields | unit | `mix test test/threadline/retention/pruner_test.exs` | ❌ Wave 0 |
| RET-02 | Runs tracked in `threadline_retention_runs` | unit | `mix test test/threadline/retention_test.exs` | ✅ Wave 0 (partially) |
| RET-03 | Retention History UI displays runs | e2e | `mix test test/threadline/operator_surface/live/retention_live_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `MIX_ENV=test mix ci.all`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/threadline/retention/pruner_test.exs` — covers RET-01
- [ ] `test/threadline/operator_surface/live/retention_live_test.exs` — covers RET-03

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Operator Surface Auth Plug (`auth.ex`) |
| V3 Session Management | yes | `live_session` via Router macro |
| V4 Access Control | yes | LiveView Mount scope enforcement |
| V5 Input Validation | yes | Ecto Changeset for `RetentionRun` |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure Direct Object Reference (IDOR) | Elevation of Privilege | Ensure Retention UI is bounded by `authorize_fn` operator roles. |
| Denial of Service via DB Lock Exhaustion | Denial of Service | Batching + `Process.sleep` avoids lock exhaustion. |

## Sources

### Primary (HIGH confidence)
- `mix.exs` - Confirmed Phoenix ~> 1.7, Ecto ~> 3.10
- `lib/threadline/retention.ex` - Verified current purge logic lacks sleeping.
- `lib/threadline/governance/migration.ex` - Verified `threadline_retention_runs` schema exists.

### Secondary (MEDIUM confidence)
- Postgres Docs - Advisory Locks
- Phoenix LiveView Docs - Streaming and PubSub

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Inspected local project files and versions.
- Architecture: HIGH - Advisory locks and batched deletes are standard for this problem space in Elixir.
- Pitfalls: HIGH - Node crashes leaving stuck DB runs is a universally encountered state-machine issue.

**Research date:** May 2024
**Valid until:** 30 days
