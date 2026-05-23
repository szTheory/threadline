defmodule Threadline.ExportQueue.TaskAdapter do
  @moduledoc """
  A simple implementation of `Threadline.ExportQueue` using `Task.Supervisor`.
  
  It spawns a background process using `Task.Supervisor.start_child/3`. By default,
  it expects a supervisor named `Threadline.Export.TaskSupervisor` to be running
  in the application tree, but you can override this by passing the `:supervisor`
  option in `opts`.
  """

  @behaviour Threadline.ExportQueue

  @doc """
  Enqueues the export job by spawning a supervised task.
  """
  @impl true
  def enqueue(job_id, opts \\ []) do
    supervisor = Keyword.get(opts, :supervisor, Threadline.Export.TaskSupervisor)

    try do
      case Task.Supervisor.start_child(supervisor, fn ->
        Threadline.Export.Orchestrator.run(job_id)
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
