# Phase 75: Governance Infrastructure & State — Discussion & Recommendations

This document synthesizes the architectural decisions and "gray areas" for Phase 75, which introduces core DB schemas and backend Behaviours for storage and queuing.

**Goal**: Foundations for background operations and DB state are established.
**Requirements**: INFRA-01, INFRA-02

## 1. Migration Structure & Rollout (INFRA-01)

**Gray Area**: How should we ship these new schemas to consumers without disrupting existing `audit_transactions` and `audit_changes` deployments?

**Recommendation**: Add a dedicated `_threadline_governance_schema.exs` generated via `mix threadline.install`.
- **Rationale**: Keeps core capture separate from Phase 75 governance capabilities. It allows adopters upgrading from older versions to safely run `mix threadline.install` again. The Mix task will be updated to skip existing files and only emit the governance schema if it doesn't already exist.
- **Schemas**:
  - `threadline_export_jobs`
    - `id` (binary_id, pk)
    - `status` (string: pending, processing, completed, failed, expired)
    - `query_params` (jsonb)
    - `actor_ref` (jsonb — explicitly reusing `Threadline.Semantics.ActorRef`)
    - `file_path` (string)
    - `error_message` (text)
    - `started_at`, `completed_at`, `expires_at` (utc_datetime_usec)
    - timestamps()
  - `threadline_retention_runs`
    - `id` (binary_id, pk)
    - `status` (string: running, completed, failed)
    - `deleted_count` (integer)
    - `duration_ms` (integer)
    - `error_message` (text)
    - `started_at`, `completed_at` (utc_datetime_usec)
    - timestamps()
  - `threadline_saved_views`
    - `id` (binary_id, pk)
    - `name` (string)
    - `actor_ref` (jsonb — explicitly reusing `Threadline.Semantics.ActorRef` per VIEW-01)
    - `filters` (jsonb)
    - timestamps()

## 2. Storage Behaviour Design (INFRA-02)

**Gray Area**: What is the most robust interface for handling potentially massive (millions of rows) CSV exports?

**Recommendation**: A stream-friendly storage behaviour (`Threadline.Storage`).
- **Rationale**: To prevent OOM errors, exports must be streamed directly to storage. The adapter must support writing chunks sequentially or handling an Elixir `Enumerable.t` (stream) directly.
- **Contract**:
  ```elixir
  defmodule Threadline.Storage do
    @callback put(path :: String.t(), stream_or_binary :: Enumerable.t() | binary()) :: :ok | {:error, term()}
    @callback get(path :: String.t()) :: {:ok, binary()} | {:error, term()}
    @callback download_url(path :: String.t(), expires_in_seconds :: pos_integer()) :: {:ok, String.t()} | {:error, term()}
    @callback delete(path :: String.t()) :: :ok | {:error, term()}
  end
  ```
- **Local Fallback**: `Threadline.Storage.Local` will write to a configured `priv/exports` directory and generate a signed/tokenized route for downloads.

## 3. Background Queue Behaviour Design (INFRA-02)

**Gray Area**: How do we abstract over `Task.Supervisor` (Phase 78) and `Oban` (Phase 79) safely?

**Recommendation**: State-first queuing via DB job IDs (`Threadline.ExportQueue`).
- **Rationale**: Passing a full Map of parameters to an unknown queue implementation is risky (Oban uses JSON, Task.Supervisor passes terms). By enforcing that the job state is written to `threadline_export_jobs` *first*, the queue behaviour only needs to accept the `job_id`. The worker pulls the state from the DB before executing.
- **Contract**:
  ```elixir
  defmodule Threadline.ExportQueue do
    @callback enqueue(job_id :: Ecto.UUID.t()) :: :ok | {:error, term()}
  end
  ```

---
*Generated autonomously per project `.gemini` conventions. If these decisions are approved, we can proceed to `/gsd-plan-phase 75`.*