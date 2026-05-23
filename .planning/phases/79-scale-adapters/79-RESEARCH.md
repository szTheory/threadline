# Phase 79: Scale Adapters - Research

**Researched:** 2024-05-23
**Domain:** Enterprise Scale-out Adapters (Oban, S3) & Dependency Management
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **In-Tree Optional Dependencies:** Threadline will include `oban`, `ex_aws`, `ex_aws_s3`, `hackney`, and `sweet_xml` as `optional: true` dependencies in `mix.exs`. The adapters ship inside the main `threadline` package.
- **`Threadline.ExportQueue.Oban`:** Implement this multi-node queue adapter.
- **`Threadline.Storage.S3`:** Implement this shared CSV export storage adapter.
- **Developer Ergonomics:** Adapters must implement an initialization safeguard that uses `Code.ensure_loaded?/1` and raises clear error messages if the optional dependencies are missing, instead of failing with cryptic `UndefinedFunctionError` crashes at runtime.

### The Agent's Discretion
- The exact point of invocation for `init/1` checks.
- Compile-time safety for Oban workers.
- Default options for ExAws and Oban interactions.

### Deferred Ideas (OUT OF SCOPE)
- Extracting adapters into separate Hex packages.
- Bring Your Own Adapter (BYOA) with no provided implementations.
</user_constraints>

## Summary

This research formalizes the "Scale Adapters" required for enterprise Threadline deployments. The core architectural decision is to use **In-Tree Optional Dependencies**. This means the new adapters (`Threadline.ExportQueue.Oban` and `Threadline.Storage.S3`) will live directly in the `lib/threadline/` directory of the main package, while their underlying third-party libraries will be added to `mix.exs` with `optional: true`. 

This approach maintains a zero-configuration experience for single-node SMBs (who will use the existing `TaskAdapter` and `Local` storage) while providing battle-tested scale-out options for enterprises without forcing them to write boilerplate integrations. To ensure excellent Developer Experience (DX), both adapters will implement initialization safeguards that fail with clear, actionable error messages if a user configures the adapter without adding the optional dependencies.

**Primary recommendation:** Update `mix.exs` with the 5 optional dependencies, update the `Threadline.Storage` and `Threadline.ExportQueue` behaviours to include an `@callback init(keyword()) :: :ok | {:error, term()}` (and provide default no-op implementations in existing adapters), and implement the `Oban` and `S3` adapters with robust `Code.ensure_loaded?/1` guardrails.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency Management | Config / Build | — | `mix.exs` declares `optional: true` to prevent forcing transitive deps on SMBs. |
| Background Jobs | API / Backend | — | `Oban` adapter maps `Threadline.ExportQueue` to Postgres-backed queues. |
| Artifact Storage | Database / Storage | API / Backend | `S3` adapter maps `Threadline.Storage` to cloud object storage. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `oban` | `~> 2.15` | Background Job Processing | Standard Elixir queue. (Optional dependency) |
| `ex_aws` | `~> 2.4` | AWS API Client | Standard Elixir AWS library. (Optional dependency) |
| `ex_aws_s3` | `~> 2.4` | AWS S3 Client | Standard Elixir S3 module. (Optional dependency) |
| `hackney` | `~> 1.18` | HTTP Client | Required by `ex_aws` by default. (Optional dependency) |
| `sweet_xml` | `~> 0.7` | XML Parsing | Required by `ex_aws` for S3 responses. (Optional dependency) |

**Installation:**
```bash
# Handled via `mix.exs` modification directly by adding to `deps()`.
```

## Architecture Patterns

### Recommended Project Structure
```
lib/threadline/
├── export_queue/
│   ├── task_adapter.ex      # Existing
│   └── oban.ex              # New Oban adapter
├── storage/
│   ├── local.ex             # Existing
│   └── s3.ex                # New S3 adapter
└── ...
```

### Pattern 1: Optional Dependency Safeguards
**What:** Preventing cryptic `UndefinedFunctionError` crashes when a user configures an adapter but forgets the dependency.
**When to use:** In any module relying on `optional: true` dependencies.
**Example:**
```elixir
defmodule Threadline.Storage.S3 do
  @behaviour Threadline.Storage

  @impl true
  def init(_opts) do
    unless Code.ensure_loaded?(ExAws.S3) do
      raise """
      Threadline.Storage.S3 requires the :ex_aws and :ex_aws_s3 dependencies.
      Please add them to your mix.exs:
        {:ex_aws, "~> 2.4"},
        {:ex_aws_s3, "~> 2.4"},
        {:hackney, "~> 1.18"},
        {:sweet_xml, "~> 0.7"}
      """
    end
    :ok
  end
end
```

### Pattern 2: Conditional Compilation for Oban Worker
**What:** The `Oban` adapter requires a Worker module that `use Oban.Worker`. This will fail to compile if `:oban` is not installed, even if the user never references it.
**When to use:** Defining the worker inside the main application.
**Example:**
```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Threadline.ExportQueue.ObanWorker do
    use Oban.Worker, queue: :threadline_exports, max_attempts: 3

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"job_id" => job_id}}) do
      Threadline.Export.Orchestrator.run(job_id)
    end
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Distributed Queuing | Custom PG-based queues | `Oban` adapter | Oban handles retries, concurrency, and telemetry flawlessly. |
| Object Storage | Raw HTTP to AWS API | `ex_aws_s3` adapter | Request signing (SigV4) and multipart uploads are highly error-prone. |

## Common Pitfalls

### Pitfall 1: Compile-time dependencies on Optional libraries
**What goes wrong:** If `Threadline.ExportQueue.Oban` calls `use Oban.Worker` at the top level, the entire Threadline package will fail to compile for adopters who do NOT have `:oban` in their `mix.exs`.
**Why it happens:** `use` macros execute at compile time.
**How to avoid:** Wrap the worker module definition in `if Code.ensure_loaded?(Oban) do ... end`.

### Pitfall 2: Missing `hackney` or `sweet_xml` for ExAws
**What goes wrong:** `ex_aws` compiles fine, but crashes at runtime with cryptic errors because it expects an HTTP client and XML parser to be present.
**Why it happens:** `ex_aws` doesn't strictly depend on specific HTTP clients or XML parsers to allow flexibility.
**How to avoid:** Ensure the error message raised by `Threadline.Storage.S3.init/1` explicitly instructs the user to include `:hackney` and `:sweet_xml` in addition to `:ex_aws`.

## Code Examples

### Oban Adapter Enqueue
```elixir
defmodule Threadline.ExportQueue.Oban do
  @behaviour Threadline.ExportQueue

  @impl true
  def init(_opts) do
    unless Code.ensure_loaded?(Oban) do
      raise """
      Threadline.ExportQueue.Oban requires the :oban dependency.
      Please add it to your mix.exs:
        {:oban, "~> 2.15"}
      """
    end
    :ok
  end

  @impl true
  def enqueue(job_id, opts \\ []) do
    # Requires Threadline.ExportQueue.ObanWorker to be conditionally compiled
    %{"job_id" => job_id}
    |> Threadline.ExportQueue.ObanWorker.new(opts)
    |> Oban.insert()
  end
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` / `config/test.exs` |
| Quick run command | `mix test test/threadline/export_queue/oban_test.exs` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADAPT-01 | Oban adapter provides `enqueue/2` and compiles conditionally | unit | `mix test test/threadline/export_queue/oban_test.exs` | ❌ |
| ADAPT-02 | S3 adapter provides `put/2`, `get/1`, `path/1`, `download_url/2`, `delete/1` | unit | `mix test test/threadline/storage/s3_test.exs` | ❌ |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | S3 presigned URLs (`ExAws.S3.presigned_url`) |
| V6 Cryptography | yes | `ex_aws` handles AWS SigV4 signing over HTTPS |

### Known Threat Patterns for Scale Adapters

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publicly accessible S3 exports | Information Disclosure | `Threadline.Storage.S3.download_url` generates strictly short-lived, presigned URLs. It must never use public read ACLs or return generic path endpoints. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/79-scale-adapters/79-DISCUSSION.md`
- `.planning/research/79-adapter-strategy.md`
- Threadline Codebase: `mix.exs`, `lib/threadline/storage.ex`, `lib/threadline/export_queue.ex`