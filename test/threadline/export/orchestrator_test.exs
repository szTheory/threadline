defmodule Threadline.Export.OrchestratorTest do
  use Threadline.DataCase

  alias Threadline.Export.Orchestrator
  alias Threadline.Governance.ExportJob
  alias Threadline.Storage.Local
  alias Threadline.Test.Repo

  @test_priv "priv/threadline_exports"

  setup do
    if File.exists?(@test_priv) do
      File.rm_rf!(@test_priv)
    end

    # We need to insert a row to `threadline_export_jobs`. Wait, is this table available in Test.Repo?
    # Yes, it should be migrated.
    Repo.delete_all(ExportJob)

    job =
      Repo.insert!(%ExportJob{
        status: "pending",
        query_params: %{"table" => "some_table"}
      })

    %{job: job}
  end

  test "marks job as running, streams to file, stores via Threadline.Storage, and marks completed",
       %{job: job} do
    assert :ok = Orchestrator.run(job.id, repo: Repo)

    updated_job = Repo.get!(ExportJob, job.id)
    assert updated_job.status == "completed"
    assert %DateTime{} = updated_job.started_at
    assert %DateTime{} = updated_job.completed_at
    assert %DateTime{} = updated_job.expires_at
    assert DateTime.compare(updated_job.expires_at, updated_job.completed_at) == :gt
    assert is_binary(updated_job.file_path)

    # Verify the file is in local storage
    assert {:ok, _content} = Local.get(updated_job.file_path)
  end

  test "on failure, marks job as failed with error_message", %{job: _job} do
    # Force a failure by passing an invalid job_id or invalid query
    # We can pass query_params that raises (e.g., unknown key which triggers ArgumentError in validate_timeline_filters!)
    bad_job =
      Repo.insert!(%ExportJob{
        status: "pending",
        query_params: %{"invalid_key" => "boom"}
      })

    assert {:error, _} = Orchestrator.run(bad_job.id, repo: Repo)

    updated_job = Repo.get!(ExportJob, bad_job.id)
    assert updated_job.status == "failed"
    assert %DateTime{} = updated_job.started_at
    assert is_binary(updated_job.error_message)
    assert %DateTime{} = updated_job.expires_at
    assert is_nil(updated_job.completed_at)
    assert updated_job.error_message =~ "unknown timeline filter key"
  end
end
