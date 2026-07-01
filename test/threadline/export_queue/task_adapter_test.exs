defmodule Threadline.ExportQueue.TaskAdapterTest do
  use Threadline.DataCase, async: false

  alias Threadline.Governance.ExportJob
  alias Threadline.ExportQueue.TaskAdapter

  defmodule NoopStorage do
    @behaviour Threadline.Storage

    @impl true
    def init(_opts), do: :ok

    @impl true
    def put(_content, _opts \\ []), do: {:ok, "task-adapter.csv"}

    @impl true
    def get(_file_id), do: {:ok, ""}

    @impl true
    def path(_file_id), do: {:ok, "/tmp/task-adapter.csv"}

    @impl true
    def download_url(_file_id, _opts \\ []), do: {:error, :not_supported}

    @impl true
    def delete(_file_id), do: :ok
  end

  setup do
    previous_storage_adapter = Application.get_env(:threadline, :storage_adapter)
    previous_storage_schema = Application.get_env(:threadline, :storage_schema)

    on_exit(fn ->
      restore_env(:storage_adapter, previous_storage_adapter)
      restore_env(:storage_schema, previous_storage_schema)
    end)

    :ok
  end

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

  test "enqueue/2 carries selected storage schema into the background worker" do
    ensure_storage_schema!("audit")
    Application.put_env(:threadline, :storage_adapter, NoopStorage)
    Application.put_env(:threadline, :storage_schema, "threadline")

    supervisor_name = :"threadline-test-export-#{System.unique_integer([:positive])}"
    supervisor = start_supervised!({Task.Supervisor, name: supervisor_name})
    job_id = Ecto.UUID.generate()

    insert_job!(job_id, "audit")
    insert_job!(job_id, "threadline")

    assert :ok = TaskAdapter.enqueue(job_id, supervisor: supervisor, storage_schema: "audit")

    assert_eventually(
      fn ->
        case Repo.get(ExportJob, job_id, repo_opts("audit")) do
          %ExportJob{status: "completed"} -> true
          _ -> false
        end
      end,
      timeout: 2_000,
      message: "audit storage export job was not completed"
    )

    assert Repo.get!(ExportJob, job_id, repo_opts("threadline")).status == "pending"
  end

  test "enqueue/2 returns error if supervisor is not started" do
    assert {:error, _} = TaskAdapter.enqueue("dummy-job-id", supervisor: :non_existent_supervisor)
  end

  defp insert_job!(job_id, storage_schema) do
    %ExportJob{}
    |> ExportJob.changeset(%{
      id: job_id,
      status: "pending",
      query_params: %{"table" => "task_adapter_storage_schema_rows"}
    })
    |> Repo.insert!(repo_opts(storage_schema))
  end

  defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
  defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
end
