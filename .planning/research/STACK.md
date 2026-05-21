# Technology Stack

**Project:** Threadline
**Researched:** 2026-05-08 (v1.20 - Scale and Governance Depth)
**Overall Confidence:** HIGH

## Recommended Stack Strategy

For v1.20, Threadline continues its **"Zero Host Intrusion"** philosophy. While heavy-duty features like Queued Exports and Retention typically imply heavy-duty dependencies (like Oban for jobs, `pg_partman` for partitioning, and AWS SDK for S3), introducing them as hard requirements would violate Threadline's adoption contract.

Instead, v1.20 will use built-in OTP and Ecto primitives as the default tier, with defined adapter contracts (Behaviours) for host-provided infrastructure.

### Core Architecture Choices

| Feature | Built-in (Default) | Host Adapter (Scale) | Rationale |
|---------|-------------------|----------------------|-----------|
| **Export Queue** | `Task.Supervisor` + Ecto state | `Oban` integration | Ecto tracks the job state (`pending`, `completed`), standard Task runs it. Good for single-node or low-volume. Adopters with Oban can override the executor. |
| **Export Storage** | Local File System (`File.stream!`) | `Threadline.Storage.S3` (via ExAws) | Multi-node deployments need centralized storage. We provide a clean `Threadline.Storage` behaviour. |
| **Retention Pruning** | Ecto Batched Deletes + `GenServer` | Native Postgres Partitioning | Partitioning is superior for scale, but requires invasive migrations, DB ownership, and composite primary keys. Ecto batched deletes are safer for brownfield adoption. |
| **Governance State** | Ecto (`threadline_saved_views`, etc.) | - | The library manages its own schema for Saved Views and Retention History, keeping governance inside the existing Repo. |

## Dependencies Posture

**No new required dependencies for `threadline`.**

### Optional Integrations
If the host provides these, Threadline can utilize them via adapters:
*   `oban` - For distributed, resilient export queues.
*   `ex_aws_s3` - For multi-node safe CSV export storage.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| **Large Deletions** | Ecto Batched Deletes (Chunked) | Postgres Partitioning (`pg_partman`) | Partitioning is the industry standard for time-series, but it breaks existing foreign keys, requires composite primary keys (UUID + timestamp), and often requires superuser DB privileges to set up automation. Too invasive for a drop-in library. |
| **Job Queue** | Ecto Table + OTP `Task` | Enforced `oban` dependency | Oban is fantastic, but forces adopters to create Oban tables, manage queues, and run Oban workers. For adopters who use ExQ or just want a simple UI, this is a bridge too far. |
| **Export Format** | CSV | Parquet | Parquet is better for analytics, but CSV is natively supported via `nimble_csv` (already in our stack) and is universally readable by non-engineers. |

## Implementation Idioms

*   **Batched Deletes:** Ecto `delete_all` with a `limit` inside a recursive function to allow Postgres `autovacuum` to keep up with dead tuples.
*   **Streams:** Use `Ecto.Repo.stream/2` into `NimbleCSV` into `File.stream!/1` to process millions of rows in constant memory.

## Sources
*   Elixir/Ecto community consensus on large table management (avoiding lock contention).
*   Oban architecture patterns vs standard `Task.Supervisor`.
