# Phase 75: Governance Infrastructure & State - Research

## Goal
Foundations for background operations and DB state are established.

## Requirements
- **INFRA-01**: Introduce Ecto schemas and migrations for `threadline_export_jobs`, `threadline_retention_runs`, and `threadline_saved_views`.
- **INFRA-02**: Define `Threadline.Storage` and `Threadline.ExportQueue` behaviours to formalize pluggable backend components for storage and background task orchestration.

## Findings

1. **Migration Strategy**: The schemas will be placed in `_threadline_governance_schema.exs`. The module `Threadline.Governance.Migration` will expose a `migration_content/0` function. The `mix threadline.install` task will be updated to output this migration alongside the capture and semantics schemas.
2. **Schemas**: 
   - `Threadline.Governance.ExportJob`: Table `threadline_export_jobs` with fields `status` (string), `query_params` (map), `actor_ref` (Threadline.Semantics.ActorRef), `file_path` (string), `error_message` (string), `started_at` (utc_datetime_usec), `completed_at` (utc_datetime_usec), `expires_at` (utc_datetime_usec).
   - `Threadline.Governance.RetentionRun`: Table `threadline_retention_runs` with fields `status` (string), `deleted_count` (integer), `duration_ms` (integer), `error_message` (string), `started_at` (utc_datetime_usec), `completed_at` (utc_datetime_usec).
   - `Threadline.Governance.SavedView`: Table `threadline_saved_views` with fields `name` (string), `actor_ref` (Threadline.Semantics.ActorRef), `filters` (map).
3. **Behaviours**:
   - `Threadline.Storage`: 
     - `@callback put(path :: String.t(), stream_or_binary :: Enumerable.t() | binary()) :: :ok | {:error, term()}`
     - `@callback get(path :: String.t()) :: {:ok, binary()} | {:error, term()}`
     - `@callback download_url(path :: String.t(), expires_in_seconds :: pos_integer()) :: {:ok, String.t()} | {:error, term()}`
     - `@callback delete(path :: String.t()) :: :ok | {:error, term()}`
   - `Threadline.Storage.Local`:
     - Will use `File` operations. It needs a directory. A good default is `priv/exports`.
   - `Threadline.ExportQueue`:
     - `@callback enqueue(job_id :: Ecto.UUID.t()) :: :ok | {:error, term()}`

## Execution Confidence
High. The implementation maps directly to well-established patterns in the Elixir ecosystem and existing patterns in this project.
