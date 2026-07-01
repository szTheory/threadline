defmodule Threadline.Export.CleanupTest do
  use Threadline.DataCase
  alias Threadline.Export.CleanupTask
  alias Threadline.Governance.ExportJob
  alias Threadline.Test.Repo

  defmodule FlipToDefaultOnDeleteStorage do
    @behaviour Threadline.Storage

    @impl true
    def init(_opts), do: :ok

    @impl true
    def put(content, opts \\ []), do: Threadline.Storage.Local.put(content, opts)

    @impl true
    def get(file_id), do: Threadline.Storage.Local.get(file_id)

    @impl true
    def path(file_id), do: Threadline.Storage.Local.path(file_id)

    @impl true
    def download_url(file_id, opts \\ []),
      do: Threadline.Storage.Local.download_url(file_id, opts)

    @impl true
    def delete(file_id) do
      Application.put_env(:threadline, :storage_schema, "threadline")
      Threadline.Storage.Local.delete(file_id)
    end
  end

  setup do
    {:ok, _} = Application.ensure_all_started(:threadline)
    previous_storage_adapter = Application.get_env(:threadline, :storage_adapter)
    previous_storage_schema = Application.get_env(:threadline, :storage_schema)

    # Ensure test storage directory is clean
    test_storage_dir = Path.join(System.tmp_dir!(), "threadline_test_exports_cleanup")
    File.rm_rf(test_storage_dir)
    File.mkdir_p!(test_storage_dir)

    on_exit(fn ->
      File.rm_rf(test_storage_dir)
      restore_env(:storage_adapter, previous_storage_adapter)
      restore_env(:storage_schema, previous_storage_schema)
    end)

    Application.put_env(:threadline, :storage_dir, test_storage_dir)

    {:ok, storage_dir: test_storage_dir}
  end

  describe "init/1" do
    test "resets jobs stuck in running state for > 24 hours to failed" do
      now = DateTime.utc_now()

      # 25 hours ago
      stuck_started_at = DateTime.add(now, -25, :hour)

      stuck_job =
        insert_job!(%{
          status: "running",
          query_params: %{},
          started_at: stuck_started_at
        })

      # 2 hours ago (should not be reset)
      recent_started_at = DateTime.add(now, -2, :hour)

      recent_job =
        insert_job!(%{
          status: "running",
          query_params: %{},
          started_at: recent_started_at
        })

      # Run init (should immediately reset stuck job)
      {:ok, _state} = CleanupTask.init(repo: Repo, interval_ms: :timer.hours(1))

      {:noreply, _state} =
        CleanupTask.handle_info(:bootstrap_reconcile, %{
          repo: Repo,
          interval_ms: :timer.hours(1),
          stale_running_cutoff_hours: 24
        })

      stuck_job = Repo.get!(ExportJob, stuck_job.id, repo_opts())
      assert stuck_job.status == "failed"
      assert stuck_job.error_message == "Abandoned"
      assert %DateTime{} = stuck_job.expires_at

      assert Repo.get(ExportJob, recent_job.id, repo_opts()).status == "running"
    end
  end

  describe "handle_info :run_cleanup" do
    test "deletes expired terminal jobs and their files while preserving active rows" do
      now = DateTime.utc_now()

      # File for expired job
      expired_file_id = "expired_job.csv"
      Threadline.Storage.Local.put("some data", file_id: expired_file_id)

      expired_job =
        insert_job!(%{
          status: "completed",
          query_params: %{},
          file_path: expired_file_id,
          expires_at: DateTime.add(now, -1, :hour)
        })

      failed_job =
        insert_job!(%{
          status: "failed",
          query_params: %{},
          expires_at: DateTime.add(now, -1, :hour)
        })

      # File for valid job
      valid_file_id = "valid_job.csv"
      Threadline.Storage.Local.put("some data", file_id: valid_file_id)

      valid_job =
        insert_job!(%{
          status: "completed",
          query_params: %{},
          file_path: valid_file_id,
          # Expires in future
          expires_at: DateTime.add(now, 1, :hour)
        })

      running_job =
        insert_job!(%{
          status: "running",
          query_params: %{},
          expires_at: DateTime.add(now, -1, :hour)
        })

      state = %{repo: Repo, interval_ms: :timer.hours(1)}

      # We need to test the logic, let's call it directly or let the message trigger it
      {:noreply, _new_state} = CleanupTask.handle_info(:run_cleanup, state)

      # Expired job should be deleted from DB and disk
      refute Repo.get(ExportJob, expired_job.id, repo_opts())
      refute Repo.get(ExportJob, failed_job.id, repo_opts())
      assert {:error, :not_found} = Threadline.Storage.Local.path(expired_file_id)

      # Valid job should remain
      assert Repo.get(ExportJob, valid_job.id, repo_opts())
      assert Repo.get(ExportJob, running_job.id, repo_opts())
      assert {:ok, _} = Threadline.Storage.Local.path(valid_file_id)
    end

    test "deletes expired jobs only from the configured storage schema" do
      ensure_storage_schema!("audit")
      Application.put_env(:threadline, :storage_adapter, FlipToDefaultOnDeleteStorage)

      now = DateTime.utc_now()
      job_id = Ecto.UUID.generate()
      expired_file_id = "audit_expired_job.csv"
      Threadline.Storage.Local.put("some data", file_id: expired_file_id)

      insert_job!(
        %{
          id: job_id,
          status: "completed",
          query_params: %{},
          file_path: expired_file_id,
          expires_at: DateTime.add(now, -1, :hour)
        },
        "audit"
      )

      insert_job!(
        %{
          id: job_id,
          status: "completed",
          query_params: %{},
          file_path: "default_sentinel.csv",
          expires_at: DateTime.add(now, -1, :hour)
        },
        "threadline"
      )

      state = %{repo: Repo, interval_ms: :timer.hours(1), storage_schema: "audit"}

      with_storage_schema("audit", fn ->
        {:noreply, _new_state} = CleanupTask.handle_info(:run_cleanup, state)
      end)

      refute Repo.get(ExportJob, job_id, repo_opts("audit"))
      assert Repo.get(ExportJob, job_id, repo_opts())
      assert {:error, :not_found} = Threadline.Storage.Local.path(expired_file_id)
    end
  end

  defp insert_job!(attrs, storage_schema \\ "threadline") do
    Repo.insert!(
      struct(ExportJob, attrs),
      repo_opts(storage_schema)
    )
  end

  defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
  defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
end
