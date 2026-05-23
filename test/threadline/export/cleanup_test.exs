defmodule Threadline.Export.CleanupTest do
  use Threadline.DataCase
  alias Threadline.Export.CleanupTask
  alias Threadline.Governance.ExportJob
  alias Threadline.Test.Repo

  setup do
    {:ok, _} = Application.ensure_all_started(:threadline)
    
    # Ensure test storage directory is clean
    test_storage_dir = Path.join(System.tmp_dir!(), "threadline_test_exports_cleanup")
    File.rm_rf(test_storage_dir)
    File.mkdir_p!(test_storage_dir)
    
    on_exit(fn ->
      File.rm_rf(test_storage_dir)
    end)

    Application.put_env(:threadline, :storage_dir, test_storage_dir)

    {:ok, storage_dir: test_storage_dir}
  end

  describe "init/1" do
    test "resets jobs stuck in running state for > 24 hours to failed" do
      now = DateTime.utc_now()
      
      # 25 hours ago
      stuck_started_at = DateTime.add(now, -25, :hour)
      
      stuck_job = Repo.insert!(%ExportJob{
        status: "running",
        query_params: %{},
        started_at: stuck_started_at
      })

      # 2 hours ago (should not be reset)
      recent_started_at = DateTime.add(now, -2, :hour)
      
      recent_job = Repo.insert!(%ExportJob{
        status: "running",
        query_params: %{},
        started_at: recent_started_at
      })

      # Run init (should immediately reset stuck job)
      {:ok, _state} = CleanupTask.init([repo: Repo, interval_ms: :timer.hours(1)])

      assert Repo.get(ExportJob, stuck_job.id).status == "failed"
      assert Repo.get(ExportJob, stuck_job.id).error_message == "Abandoned"
      
      assert Repo.get(ExportJob, recent_job.id).status == "running"
    end
  end

  describe "handle_info :run_cleanup" do
    test "deletes expired jobs and their files", %{storage_dir: storage_dir} do
      now = DateTime.utc_now()
      
      # File for expired job
      expired_file_path = "expired_job.csv"
      abs_expired_file = Path.join(storage_dir, expired_file_path)
      File.write!(abs_expired_file, "some data")
      
      expired_job = Repo.insert!(%ExportJob{
        status: "completed",
        query_params: %{},
        file_path: expired_file_path,
        expires_at: DateTime.add(now, -1, :hour)
      })

      # File for valid job
      valid_file_path = "valid_job.csv"
      abs_valid_file = Path.join(storage_dir, valid_file_path)
      File.write!(abs_valid_file, "some data")
      
      valid_job = Repo.insert!(%ExportJob{
        status: "completed",
        query_params: %{},
        file_path: valid_file_path,
        expires_at: DateTime.add(now, 1, :hour) # Expires in future
      })

      state = %{repo: Repo, interval_ms: :timer.hours(1)}
      
      # We need to test the logic, let's call it directly or let the message trigger it
      {:noreply, _new_state} = CleanupTask.handle_info(:run_cleanup, state)

      # Expired job should be deleted from DB and disk
      refute Repo.get(ExportJob, expired_job.id)
      refute File.exists?(abs_expired_file)

      # Valid job should remain
      assert Repo.get(ExportJob, valid_job.id)
      assert File.exists?(abs_valid_file)
    end
  end
end
