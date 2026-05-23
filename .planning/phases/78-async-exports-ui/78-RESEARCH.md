<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
(None explicitly provided in CONTEXT.md)

### the agent's Discretion
(None explicitly provided in CONTEXT.md)

### Deferred Ideas (OUT OF SCOPE)
(None explicitly provided in CONTEXT.md)
</user_constraints>

# Phase 78: Async Exports & UI - Research

**Researched:** 2024-05-24
**Domain:** Background Job Processing, LiveView UI, Large File Streaming
**Confidence:** HIGH

## Summary

This phase implements asynchronous CSV exports using `Task.Supervisor` and Ecto state, enabling operators to extract massive datasets without blocking the UI or timing out the HTTP connection. The foundation schemas (`threadline_export_jobs`) and behaviours (`Threadline.Storage`, `Threadline.ExportQueue`) were established in Phase 75. 

To complete this, Threadline requires a concrete `Threadline.ExportQueue.Task` implementation (acting as a built-in supervisor and queue adapter), a worker module (`Threadline.Export.Orchestrator`) that streams Ecto queries directly to a temporary file via `Threadline.Export.stream_export_rows/2`, and an operator-facing LiveView (`Threadline.OperatorSurface.Live.ExportStatusLive`) to monitor and download these artifacts. A cleanup mechanism must also be implemented to prune expired jobs and storage artifacts.

**Primary recommendation:** Implement `Threadline.ExportQueue.Task` as a standalone `Task.Supervisor` wrapper, use Ecto's `Repo.stream/2` to pipe chunked CSV generation into temporary local files before handing off to `Threadline.Storage`, and extend `Threadline.OperatorSurface.Router` to include the new `/exports` status LiveView.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Request background export | UI (LiveView) | API / Queue (`ExportQueue`) | Operator triggers via UI; backend writes job to Ecto and enqueues task. |
| Process export job | Worker (`Task.Supervisor`) | DB / Storage | `Orchestrator` runs asynchronously, streams from DB, formats to CSV, writes to Storage. |
| Export Status UI | UI (LiveView) | DB (`ExportJob`) | Displays real-time status of jobs by querying/polling Ecto state. |
| CSV Download | API (Controller) | Storage (`Threadline.Storage`) | Streams completed file from storage adapter to client browser. |
| Artifact Cleanup | Worker / Pruner | Storage & DB | Background task checks `expires_at` and removes files and DB rows. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Task.Supervisor` | built-in | Background execution | Zero-dependency, native OTP way to run supervised async tasks. |
| `NimbleCSV` | ~> 1.2 | CSV generation | Exists in Threadline's dependencies; high-performance streaming. |

## Architecture Patterns

### System Architecture Diagram
```
[Operator UI] --(Request Export)--> [LiveView / Controller]
                                         |
                                         v
                                  [Ecto (threadline_export_jobs)]
                                         |
                                         v
                            [Threadline.ExportQueue.Task]
                                         |
                                         v
                             [Task.Supervisor Process]
                                         |
                                         v
                        [Threadline.Export.Orchestrator]
                                         |
                       (Streams rows via Ecto.Repo.stream/2)
                                         |
                                         v
                              [Threadline.Storage] --(Local FS / S3)--> [Export Artifact]
```

### Pattern 1: Streaming Ecto to File
**What:** Reading massive datasets without loading them all into memory, converting to CSV, and streaming to a local file.
**When to use:** In `Threadline.Export.Orchestrator` when executing an export job.
**Example:**
```elixir
Repo.transaction(fn ->
  tmp_path = "priv/threadline_exports/tmp_#{job_id}.csv"
  file = File.open!(tmp_path, [:write, :utf8])
  IO.write(file, Threadline.Export.csv_header())
  
  filters
  |> Threadline.Export.stream_export_rows(opts)
  |> Stream.map(&Threadline.Export.format_changes_iodata([&1], :csv))
  |> Stream.into(IO.stream(file, :line))
  |> Stream.run()
  
  File.close(file)
  # Then call Threadline.Storage.put(tmp_path, ...)
end, timeout: :infinity)
```

## Anti-Patterns to Avoid
- **In-Memory Accumulation:** Avoid using `Repo.all` or `Enum.map` for massive exports. Always use `Repo.stream` combined with `Stream.into` for constant memory usage.
- **Unsupervised Tasks:** Do not use `Task.start/1` or `Task.async/1` without linking. Always use `Task.Supervisor.start_child/2` to ensure jobs do not orphan the node if it restarts, though Ecto state recovery will also handle this.
- **Hardcoding Oban:** Do not introduce Oban or other third-party queues directly into Threadline's core. Adhere to the zero-host-intrusion principle by defaulting to `Task.Supervisor`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| In-memory CSV buffering | Custom string accumulation | `NimbleCSV` + `Stream.into` | Constant memory profile regardless of export size. |
| CSV header formatting | Manual string building | `Threadline.Export.csv_header/1` | Keep exact parity with the existing synchronous export controller. |
| Job execution tracking | GenServer state | `threadline_export_jobs` table | State must survive supervisor restarts and multi-node setups. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | N/A - Greenfield feature |
| Live service config | None | N/A |
| OS-registered state | None | N/A |
| Secrets/env vars | None | N/A |
| Build artifacts | `priv/threadline_exports/` | Add cleanup logic to prune expired files |

## Common Pitfalls

### Pitfall 1: `Threadline.Storage.Local.put/2` Writing Paths as Strings
**What goes wrong:** `Threadline.Storage.Local.put(content)` currently uses `File.write(path, content)`. If the orchestrator passes a local file path (e.g. `/tmp/export.csv`) to `put/2`, `Local.put` will literally write the string `"/tmp/export.csv"` into the exported file rather than copying its contents.
**Why it happens:** Phase 75 defined `@type path_or_content :: String.t() | binary()` but `Local.put` does not distinguish between a file path string and a raw string.
**How to avoid:** Update `Threadline.Storage.Local.put/2` to check `File.regular?(content)`. If true, use `File.cp(content, path)`. If false, use `File.write(path, content)`.

### Pitfall 2: Transaction Timeout on Long Exports
**What goes wrong:** Ecto `Repo.stream` requires being run inside a database transaction. Massive queries can take minutes, exceeding the default `timeout` (15,000ms).
**How to avoid:** Set a high or `:infinity` timeout for the `Repo.transaction` call in the orchestrator: `Repo.transaction(fn -> ... end, timeout: :infinity)`.

### Pitfall 3: Dangling `running` Jobs on Node Crash
**What goes wrong:** A node crashes while exporting, leaving the DB status as `running` forever.
**How to avoid:** During the init of the cleanup pruner, identify jobs stuck in `running` for > 24 hours and transition them to `failed`. 

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXP-01 | Orchestrator processes background export via Task.Supervisor | integration | `mix test test/threadline/export_queue_test.exs` | ❌ Wave 0 |
| EXP-02 | Streams CSV safely without memory bloat | integration | `mix test test/threadline/export/orchestrator_test.exs` | ❌ Wave 0 |
| EXP-03 | Export Status UI displays jobs and download links | e2e/liveview | `mix test test/threadline/operator_surface/live/export_status_live_test.exs` | ❌ Wave 0 |
| EXP-04 | Cleanup mechanism deletes expired jobs/files | unit | `mix test test/threadline/export/cleanup_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/threadline/export_queue_test.exs`
- [ ] `test/threadline/export/orchestrator_test.exs`
- [ ] `test/threadline/operator_surface/live/export_status_live_test.exs`
- [ ] `test/threadline/export/cleanup_test.exs`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Relies on host Phoenix app |
| V3 Session Management | no | Relies on host Phoenix app |
| V4 Access Control | yes | Download routes must verify actor authorization |
| V5 Input Validation | yes | Ecto changesets validate `query_params` |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir / Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure Direct Object Reference (IDOR) | Information Disclosure | Ensure download links are bound to the authenticated actor or verify authorization rules before serving. |
| Path Traversal | Tampering | Restrict file reads to `priv/threadline_exports` inside `Threadline.Storage.Local`. |

## Sources

### Primary (HIGH confidence)
- Threadline Codebase (`lib/threadline/storage/local.ex`, `lib/threadline/export.ex`)
- Phase 75 RESEARCH & PATTERNS (`.planning/phases/75-governance-infrastructure-and-state/`)

### Secondary (MEDIUM confidence)
- N/A - Internal architecture.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir primitives (`Task.Supervisor`, `Repo.stream`).
- Architecture: HIGH - Follows existing `Threadline.Retention.Pruner` pattern and Phase 75 behaviours.
- Pitfalls: HIGH - Found direct logical conflict in `Local.put/2` code vs path expectations.

**Research date:** 2024-05-24
**Valid until:** 2024-06-24
