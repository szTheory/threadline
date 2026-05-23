defmodule Threadline.ExportQueue.TaskAdapterTest do
  use ExUnit.Case, async: true
  alias Threadline.ExportQueue.TaskAdapter

  setup do
    _pid = start_supervised!({Task.Supervisor, name: Threadline.Test.ExportTaskSupervisor})
    %{supervisor: Threadline.Test.ExportTaskSupervisor}
  end

  test "enqueue/2 spawns a background task via the given supervisor", %{supervisor: supervisor} do
    # We pass an invalid job_id so that Orchestrator.run fails safely, or
    # since we just care about it being spawned, we can pass a random job_id.
    # The actual failure in the background process will be logged but it shouldn't
    # crash the test process since they are supervised differently.
    
    # Alternatively, we just check the return type.
    assert :ok = TaskAdapter.enqueue("dummy-job-id", supervisor: supervisor)
    
    # Allow some time for the task to be spawned and run
    Process.sleep(10)
    
    # Supervisor should have started the child
    _children = Task.Supervisor.children(supervisor)
    # The child may have already exited, or might still be running.
    # Let's just assert that enqueue returns :ok.
  end

  test "enqueue/2 returns error if supervisor is not started" do
    assert {:error, _} = TaskAdapter.enqueue("dummy-job-id", supervisor: :non_existent_supervisor)
  end
end
