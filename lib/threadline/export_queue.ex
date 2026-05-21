defmodule Threadline.ExportQueue do
  @moduledoc """
  Behaviour for enqueueing asynchronous export jobs.

  Threadline provides a simple OTP `Task.Supervisor`-based implementation
  by default. Adopters needing persistent or multi-node queueing can implement
  this behaviour using tools like Oban.
  """

  @type job_id :: String.t() | binary()

  @doc """
  Enqueues an export job for background processing.

  Takes the ID of the `threadline_export_jobs` record to process.
  """
  @callback enqueue(job_id()) :: :ok | {:error, term()}
end
