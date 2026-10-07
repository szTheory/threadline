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

  @typedoc "The identifier of an existing export job passed to the configured queue adapter."
  @type job_id :: String.t() | binary()

  @typedoc "Adapter-defined keyword options that Threadline passes through without interpreting their keys."
  @type options :: Threadline.Storage.options()

  @typedoc "Any Elixir value returned by an adapter as an error reason; Threadline treats it as opaque."
  @type error_reason ::
          atom()
          | number()
          | bitstring()
          | pid()
          | port()
          | reference()
          | function()
          | tuple()
          | maybe_improper_list(error_reason(), error_reason())
          | %{optional(error_reason()) => error_reason()}

  @doc """
  Initializes the adapter from its module-keyed configuration, returning `:ok`
  when ready or `{:error, reason}` when initialization fails.

  Return `{:error, reason}` for invalid configuration or unavailable optional
  dependencies.
  """
  @callback init(options()) :: :ok | {:error, error_reason()}

  @doc """
  Enqueues an export job for background processing, returning `:ok` after the
  queue accepts responsibility or `{:error, reason}` when it cannot.

  Takes the ID of the `threadline_export_jobs` record to process. Return `:ok`
  only after the queue has accepted responsibility for running it.
  """
  @callback enqueue(job_id(), options()) :: :ok | {:error, error_reason()}
end
