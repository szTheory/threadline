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

  @behaviour Threadline.ExportQueue

  @impl true
  def init(_opts), do: :ok

  @doc """
  Enqueues the export job by spawning a supervised task.
  """
  @impl true
  def enqueue(job_id, opts \\ []) do
    supervisor = Keyword.get(opts, :supervisor, Threadline.Export.TaskSupervisor)
    storage_schema = Threadline.StorageSchema.get(opts)

    try do
      case Task.Supervisor.start_child(supervisor, fn ->
             Threadline.Export.Orchestrator.run(job_id, storage_schema: storage_schema)
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
