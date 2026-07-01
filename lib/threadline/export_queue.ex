defmodule Threadline.ExportQueue do
  @moduledoc """
  Behaviour for enqueueing asynchronous export jobs.

  Threadline provides a simple OTP `Task.Supervisor`-based implementation
  by default. Adopters needing persistent or multi-node queueing can implement
  this behaviour using tools like Oban.

  The `init/1` callback is used for dependency safeguards, ensuring adapters fail
  early if their required underlying library is missing from the environment.
  """

  @type job_id :: String.t() | binary()

  @doc """
  Initializes the adapter. Called during application startup to verify
  configuration and presence of underlying dependencies.
  """
  @callback init(keyword()) :: :ok | {:error, term()}

  @doc """
  Enqueues an export job for background processing.

  Takes the ID of the `threadline_export_jobs` record to process.
  """
  @callback enqueue(job_id(), keyword()) :: :ok | {:error, term()}
end
