defmodule Threadline.ExportQueue.TaskAdapter do
  @moduledoc """
  Runs export jobs in supervised, in-process tasks.

  This is the default `Threadline.ExportQueue` adapter. It starts a child under
  the export task supervisor that Threadline adds to its supervision tree, then
  runs the queued export lifecycle.

  The adapter is lightweight and requires no optional dependency, but queued work
  is not durable across node or process restarts. Use
  `Threadline.ExportQueue.Oban` when the queue must be persistent or shared by
  multiple nodes.

  `enqueue/2` accepts `:storage_schema` and passes it to the orchestrator. Tests
  and custom supervision trees may override `:supervisor`; if that supervisor is
  unavailable, the adapter returns `{:error, :supervisor_not_started}`.
  """

  alias Threadline.Export.Orchestrator

  @behaviour Threadline.ExportQueue

  @typedoc "An option accepted by `enqueue/2`."
  @type enqueue_opt :: Threadline.storage_schema_opt() | {:supervisor, pid() | atom() | tuple()}

  @typedoc "The result of starting an export task; the task supervisor owns the error reason."
  @type enqueue_result :: :ok | {:error, Orchestrator.error_reason()}

  @impl true
  def init(_opts), do: :ok

  @doc """
  Enqueues an export job by spawning a supervised task and returns `:ok` when accepted.

  Use this in-process adapter for single-node work; use the Oban adapter when
  jobs must survive process restarts or run across nodes. The task calls
  `Threadline.Export.Orchestrator.run/2` with the selected storage schema.

  ## Options

  - `:storage_schema` — string. Defaults to the configured Threadline storage schema.
  - `:supervisor` — process or registered supervisor name. Defaults to the application export task supervisor.

  Other option keys are ignored.

  ## Returns

  - `:ok` — the supervised task was started.
  - `{:error, reason}` — the supervisor rejected the child or is not started.
  """
  @impl true
  @spec enqueue(String.t(), [enqueue_opt()]) :: enqueue_result()
  def enqueue(job_id, opts \\ []) do
    supervisor = Keyword.get(opts, :supervisor, Threadline.Export.TaskSupervisor)
    storage_schema = Threadline.StorageSchema.get(opts)

    try do
      case Task.Supervisor.start_child(supervisor, fn ->
             Orchestrator.run(job_id, storage_schema: storage_schema)
           end) do
        {:ok, _pid} -> :ok
        {:ok, _pid, _info} -> :ok
        {:error, reason} -> {:error, reason}
      end
    catch
      :exit, _reason ->
        {:error, :supervisor_not_started}
    end
  end
end
