defmodule Threadline.ExportQueue.Oban do
  @moduledoc """
  Oban-based implementation of `Threadline.ExportQueue`.

  This adapter enqueues export jobs into Oban for robust, persistent background processing.
  Requires the optional `:oban` dependency.
  """

  @behaviour Threadline.ExportQueue

  @impl true
  def init(_opts) do
    if Code.ensure_loaded?(Oban) do
      :ok
    else
      raise "Oban adapter requires the :oban dependency. Please add {:oban, \"~> 2.15\"} to your mix.exs."
    end
  end

  @impl true
  def enqueue(job_id, opts \\ []) do
    oban_mod = Keyword.get(opts, :oban_mod, Oban)
    oban_name = Keyword.get(opts, :oban_name, Oban)
    
    # We build the job via the worker
    job = Threadline.ExportQueue.ObanWorker.new(%{job_id: job_id})

    case oban_mod.insert(oban_name, job) do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end

if Code.ensure_loaded?(Oban) do
  defmodule Threadline.ExportQueue.ObanWorker do
    @moduledoc false
    use Oban.Worker, queue: :threadline_exports, max_attempts: 3

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"job_id" => job_id}}) do
      Threadline.Export.Orchestrator.run(job_id)
    end
  end
end
