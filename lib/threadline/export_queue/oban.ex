defmodule Threadline.ExportQueue.Oban do
  @moduledoc """
  Enqueues Threadline exports in Oban.

  Use this optional `Threadline.ExportQueue` adapter for durable, multi-node job
  execution. Add `:oban` to the host project, configure and supervise Oban in the
  host application, then select the adapter:

      config :threadline, export_queue_adapter: Threadline.ExportQueue.Oban

      config :threadline, Threadline.ExportQueue.Oban,
        oban_name: Oban,
        queue: :threadline_exports

  Supported module-keyed options are:

    * `:oban_name` - the supervised Oban instance name; defaults to `Oban`
    * `:queue` - the queue atom; defaults to `:threadline_exports`
    * `:worker_mod` - a module exporting `new/2`; defaults to Threadline's worker

  `init/1` returns an error when Oban is unavailable or these options are invalid.
  `enqueue/2` inserts a job carrying the Threadline export-job identifier and
  storage schema. The built-in worker calls `Threadline.Export.Orchestrator.run/2`,
  preserving Threadline's lifecycle, storage, failure, and expiry semantics.
  Insert failures are returned as descriptive `{:error, reason}` values.
  """

  @behaviour Threadline.ExportQueue

  @impl true
  def init(opts) do
    with :ok <- ensure_oban_loaded(),
         :ok <- validate_oban_name(Keyword.get(opts, :oban_name, Oban)),
         :ok <- validate_queue(Keyword.get(opts, :queue, :threadline_exports)),
         :ok <- validate_worker(Keyword.get(opts, :worker_mod, Threadline.ExportQueue.ObanWorker)) do
      :ok
    end
  end

  @impl true
  def enqueue(job_id, opts \\ []) do
    opts = Application.get_env(:threadline, __MODULE__, []) |> Keyword.merge(opts)
    oban_mod = Keyword.get(opts, :oban_mod, Oban)
    oban_name = Keyword.get(opts, :oban_name, Oban)
    worker_mod = Keyword.get(opts, :worker_mod, Threadline.ExportQueue.ObanWorker)
    queue = Keyword.get(opts, :queue, :threadline_exports)
    storage_schema = Threadline.StorageSchema.get(opts)

    try do
      with :ok <- init(opts),
           job <- worker_mod.new(%{job_id: job_id, storage_schema: storage_schema}, queue: queue),
           result <- oban_mod.insert(oban_name, job) do
        case result do
          {:ok, _job} -> :ok
          {:error, reason} -> {:error, normalize_enqueue_error(reason)}
        end
      end
    rescue
      error ->
        {:error, normalize_enqueue_error(Exception.message(error))}
    end
  end

  defp ensure_oban_loaded do
    if Code.ensure_loaded?(Oban) do
      :ok
    else
      {:error, "Oban adapter requires the :oban dependency"}
    end
  end

  defp validate_oban_name(name) when is_atom(name), do: :ok
  defp validate_oban_name(_name), do: {:error, "Oban adapter expects :oban_name to be an atom"}

  defp validate_queue(queue) when is_atom(queue), do: :ok
  defp validate_queue(_queue), do: {:error, "Oban adapter expects :queue to be an atom"}

  defp validate_worker(worker_mod) when is_atom(worker_mod) do
    if worker_mod == Threadline.ExportQueue.ObanWorker or function_exported?(worker_mod, :new, 2) do
      :ok
    else
      {:error, "Oban adapter expects :worker_mod to export new/2"}
    end
  end

  defp validate_worker(_worker_mod) do
    {:error, "Oban adapter expects :worker_mod to be a module"}
  end

  defp normalize_enqueue_error(reason) when is_binary(reason),
    do: "Oban enqueue failed: #{reason}"

  defp normalize_enqueue_error(reason) when is_atom(reason) do
    "Oban enqueue failed: #{reason}"
  end

  defp normalize_enqueue_error(%{message: message}) when is_binary(message) do
    "Oban enqueue failed: #{message}"
  end

  defp normalize_enqueue_error(reason), do: "Oban enqueue failed: #{inspect(reason)}"
end

if Code.ensure_loaded?(Oban) do
  defmodule Threadline.ExportQueue.ObanWorker do
    @moduledoc false
    use Oban.Worker, queue: :threadline_exports, max_attempts: 3

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"job_id" => job_id, "storage_schema" => storage_schema}}) do
      Threadline.Export.Orchestrator.run(job_id, storage_schema: storage_schema)
    end

    def perform(%Oban.Job{args: %{"job_id" => job_id}}) do
      Threadline.Export.Orchestrator.run(job_id)
    end
  end
end
