defmodule Threadline.ExportQueue do
  @moduledoc """
  Enqueues Threadline export jobs for asynchronous processing.

  Threadline uses `Threadline.ExportQueue.TaskAdapter` by default. Select the
  optional Oban adapter or a custom implementation in the host application:

      config :threadline, export_queue_adapter: MyApp.AuditExportQueue

  Threadline reads module-keyed options and passes them to `c:init/1` during
  application startup when a repository is configured:

      config :threadline, MyApp.AuditExportQueue, queue: :exports

  Return `:ok` only when the queue is ready. Returning `{:error, reason}` or
  raising prevents Threadline's supervision tree from starting, so invalid
  configuration and missing optional dependencies fail early.

  `c:enqueue/2` receives the identifier of an existing Threadline export job and
  runtime options such as `:storage_schema`. A custom queue worker should call
  `Threadline.Export.Orchestrator.run/2` with that identifier and preserve those
  options. The orchestrator owns job transitions, export generation, storage,
  failure recording, and expiry; duplicating that lifecycle in an adapter can
  leave job state inconsistent.

  See `Threadline.ExportQueue.TaskAdapter` for in-process execution and
  `Threadline.ExportQueue.Oban` for durable, multi-node execution.
  """

  @type job_id :: String.t() | binary()

  @doc """
  Initializes the adapter from its module-keyed configuration.

  Return `{:error, reason}` for invalid configuration or unavailable optional
  dependencies.
  """
  @callback init(keyword()) :: :ok | {:error, term()}

  @doc """
  Enqueues an export job for background processing.

  Takes the ID of the `threadline_export_jobs` record to process. Return `:ok`
  only after the queue has accepted responsibility for running it.
  """
  @callback enqueue(job_id(), keyword()) :: :ok | {:error, term()}
end
