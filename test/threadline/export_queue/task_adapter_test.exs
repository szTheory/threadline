defmodule Threadline.ExportQueue.TaskAdapterTest do
  use ExUnit.Case, async: true
  alias Threadline.ExportQueue.TaskAdapter

  test "the default task supervisor is started by the application" do
    assert is_pid(Process.whereis(Threadline.Export.TaskSupervisor))
  end

  test "enqueue/2 spawns a background task via an explicit supervisor override" do
    supervisor = start_supervised!({Task.Supervisor, name: Threadline.Test.ExportTaskSupervisor})

    # The background task runs the orchestrator with a dummy job_id and fails
    # safely (logged, supervised separately) — this test only asserts that
    # enqueue accepts the explicit supervisor override and returns :ok, in
    # contrast to the unstarted-supervisor error case below. No sleep needed:
    # the spawn is fire-and-forget and nothing is asserted about its outcome.
    assert :ok = TaskAdapter.enqueue("dummy-job-id", supervisor: supervisor)
  end

  test "enqueue/2 returns error if supervisor is not started" do
    assert {:error, _} = TaskAdapter.enqueue("dummy-job-id", supervisor: :non_existent_supervisor)
  end
end
