defmodule Threadline.Export.OrchestratorTest do
  use Threadline.DataCase

  alias Threadline.Export.Orchestrator
  alias Threadline.Governance.ExportJob
  alias Threadline.Storage.Local
  alias Threadline.Test.Repo

  @test_priv "priv/threadline_exports"

  defmodule FlipToDefaultStorage do
    @behaviour Threadline.Storage

    alias Threadline.Storage.Local

    @impl true
    def init(_opts), do: :ok

    @impl true
    def put(content, opts \\ []) do
      Application.put_env(:threadline, :storage_schema, "threadline")
      Local.put(content, opts)
    end

    @impl true
    def get(file_id), do: Local.get(file_id)

    @impl true
    def path(file_id), do: Local.path(file_id)

    @impl true
    def download_url(file_id, opts \\ []),
      do: Local.download_url(file_id, opts)

    @impl true
    def delete(file_id), do: Local.delete(file_id)
  end

  defmodule RecordingStorage do
    @behaviour Threadline.Storage

    alias Threadline.Storage.Local

    @impl true
    def init(_opts), do: :ok

    @impl true
    def put(content, opts \\ []) do
      result = Local.put(content, opts)
      notify({:storage_put, result})
      result
    end

    @impl true
    def get(file_id), do: Local.get(file_id)

    @impl true
    def path(file_id), do: Local.path(file_id)

    @impl true
    def download_url(file_id, opts \\ []),
      do: Local.download_url(file_id, opts)

    @impl true
    def delete(file_id) do
      notify({:storage_delete, file_id})
      Local.delete(file_id)
    end

    defp notify(message) do
      if pid = Application.get_env(:threadline, :test_orchestrator_notify_pid) do
        send(pid, message)
      end
    end
  end

  defmodule DeleteFailStorage do
    @behaviour Threadline.Storage

    alias Threadline.Storage.Local

    @impl true
    def init(_opts), do: :ok

    @impl true
    def put(content, opts \\ []), do: RecordingStorage.put(content, opts)

    @impl true
    def get(file_id), do: Local.get(file_id)

    @impl true
    def path(file_id), do: Local.path(file_id)

    @impl true
    def download_url(file_id, opts \\ []),
      do: Local.download_url(file_id, opts)

    @impl true
    def delete(file_id) do
      if pid = Application.get_env(:threadline, :test_orchestrator_notify_pid) do
        send(pid, {:storage_delete, file_id})
      end

      {:error, :storage_unavailable}
    end
  end

  defmodule RemoteRecordingStorage do
    @behaviour Threadline.Storage

    @impl true
    def init(_opts), do: :ok

    @impl true
    def put(content, _opts \\ []) do
      send(
        Application.fetch_env!(:threadline, :test_orchestrator_notify_pid),
        {:remote_put, content}
      )

      {:ok, "remote-export.csv"}
    end

    @impl true
    def get(_file_id), do: {:error, :not_implemented}

    @impl true
    def path(_file_id), do: {:error, :not_local}

    @impl true
    def download_url(_file_id, _opts \\ []), do: {:ok, "https://exports.example.test/file"}

    @impl true
    def delete(_file_id), do: :ok
  end

  setup do
    previous_storage_adapter = Application.get_env(:threadline, :storage_adapter)
    previous_storage_schema = Application.get_env(:threadline, :storage_schema)

    on_exit(fn ->
      restore_env(:storage_adapter, previous_storage_adapter)
      restore_env(:storage_schema, previous_storage_schema)
      Application.delete_env(:threadline, :test_orchestrator_notify_pid)
    end)

    if File.exists?(@test_priv) do
      File.rm_rf!(@test_priv)
    end

    Repo.delete_all(ExportJob, repo_opts())

    job =
      insert_job!(%{
        status: "pending",
        query_params: %{"table" => "some_table"}
      })

    %{job: job}
  end

  test "marks job as running, streams to file, stores via Threadline.Storage, and marks completed",
       %{job: job} do
    assert :ok = Orchestrator.run(job.id, repo: Repo)

    updated_job = Repo.get!(ExportJob, job.id, repo_opts())
    assert updated_job.status == "completed"
    assert %DateTime{} = updated_job.started_at
    assert %DateTime{} = updated_job.completed_at
    assert %DateTime{} = updated_job.expires_at
    assert DateTime.compare(updated_job.expires_at, updated_job.completed_at) == :gt
    assert is_binary(updated_job.file_path)

    # Verify the file is in local storage
    assert {:ok, _content} = Local.get(updated_job.file_path)
  end

  test "only one concurrent worker atomically claims a pending export", %{job: job} do
    tasks =
      for _ <- 1..2 do
        Task.async(fn -> Orchestrator.run(job.id, repo: Repo) end)
      end

    results = tasks |> Enum.map(&Task.await(&1, 5_000)) |> Enum.sort()

    assert results == [:ok, {:error, :not_claimable}]

    updated_job = Repo.get!(ExportJob, job.id, repo_opts())
    assert updated_job.status == "completed"
    assert {:ok, _content} = Local.get(updated_job.file_path)
  end

  test "replays persisted string date params and stores only rows inside the requested window" do
    insert_change!("outside-before", ~U[2026-04-30 23:59:59Z])
    insert_change!("inside-start", ~U[2026-05-01 00:00:00Z])
    insert_change!("inside-end", ~U[2026-05-06 23:59:00Z])
    insert_change!("outside-after", ~U[2026-05-07 00:00:00Z])

    job =
      insert_job!(%{
        status: "pending",
        query_params: %{
          "table" => "threadline_export_replay_rows",
          "from" => "2026-05-01T00:00",
          "to" => "2026-05-06T23:59"
        }
      })

    assert :ok = Orchestrator.run(job.id, repo: Repo)

    updated_job = Repo.get!(ExportJob, job.id, repo_opts())
    assert updated_job.status == "completed"
    assert {:ok, csv} = Local.get(updated_job.file_path)
    assert csv =~ "inside-start"
    assert csv =~ "inside-end"
    refute csv =~ "outside-before"
    refute csv =~ "outside-after"
  end

  test "invalid persisted datetime params fail closed with parser detail", %{job: _job} do
    bad_job =
      insert_job!(%{
        status: "pending",
        query_params: %{"from" => "not-a-date"}
      })

    assert {:error, _} = Orchestrator.run(bad_job.id, repo: Repo)

    updated_job = Repo.get!(ExportJob, bad_job.id, repo_opts())
    assert updated_job.status == "failed"
    assert %DateTime{} = updated_job.started_at
    assert is_binary(updated_job.error_message)
    assert %DateTime{} = updated_job.expires_at
    assert is_nil(updated_job.completed_at)
    assert updated_job.error_message =~ "invalid datetime: not-a-date"
  end

  test "worker source does not mint atoms from persisted query params" do
    source = File.read!("lib/threadline/export/orchestrator.ex")

    refute source =~ ~r/String\.to_atom\s*\(/
  end

  test "configured storage schema remains fixed across queued export status and stream work" do
    ensure_storage_schema!("audit")
    Application.put_env(:threadline, :storage_adapter, FlipToDefaultStorage)

    job_id = Ecto.UUID.generate()
    table = "queued_export_storage_#{System.unique_integer([:positive])}"
    captured_at = ~U[2026-06-01 00:00:00Z]

    insert_job!(
      %{
        id: job_id,
        status: "pending",
        query_params: %{"table" => table}
      },
      "threadline"
    )

    insert_job!(
      %{
        id: job_id,
        status: "pending",
        query_params: %{"table" => table}
      },
      "audit"
    )

    default_change =
      insert_change!("default-storage", captured_at,
        table: table,
        storage_schema: "threadline"
      )

    audit_change =
      insert_change!("audit-storage", captured_at,
        table: table,
        storage_schema: "audit"
      )

    with_storage_schema("audit", fn ->
      assert :ok = Orchestrator.run(job_id, repo: Repo)
    end)

    audit_job = Repo.get!(ExportJob, job_id, repo_opts("audit"))
    default_job = Repo.get!(ExportJob, job_id, repo_opts())

    assert audit_job.status == "completed"
    assert default_job.status == "pending"

    assert {:ok, csv} = Local.get(audit_job.file_path)
    assert csv =~ to_string(audit_change.id)
    assert csv =~ "audit-storage"
    refute csv =~ to_string(default_change.id)
    refute csv =~ "default-storage"
  end

  test "portable storage adapters receive CSV bytes instead of a temporary pathname" do
    Application.put_env(:threadline, :test_orchestrator_notify_pid, self())
    row_id = "remote-storage-row"
    table = "remote_storage_exports"
    insert_change!(row_id, ~U[2026-06-01 00:00:00Z], table: table)

    job =
      insert_job!(%{
        status: "pending",
        query_params: %{"table" => table}
      })

    assert :ok =
             Orchestrator.run(job.id,
               repo: Repo,
               storage_adapter: RemoteRecordingStorage
             )

    assert_receive {:remote_put, uploaded_body}
    assert is_binary(uploaded_body)
    assert String.starts_with?(uploaded_body, Threadline.Export.csv_header())
    assert uploaded_body =~ row_id
    refute uploaded_body =~ System.tmp_dir!() <> "/export_"

    updated_job = Repo.get!(ExportJob, job.id, repo_opts())
    assert updated_job.status == "completed"
    assert updated_job.file_path == "remote-export.csv"
  end

  test "a transaction commit failure never stores an export object", %{job: job} do
    Application.put_env(:threadline, :test_orchestrator_notify_pid, self())

    transaction_fn = fn transaction_body, transaction_opts ->
      Repo.transaction(
        fn ->
          transaction_body.()
          Repo.rollback(:forced_commit_failure)
        end,
        transaction_opts
      )
    end

    assert {:error, :forced_commit_failure} =
             Orchestrator.run(job.id,
               repo: Repo,
               storage_adapter: RecordingStorage,
               transaction_fn: transaction_fn
             )

    refute_receive {:storage_put, _}
    updated_job = Repo.get!(ExportJob, job.id, repo_opts())
    assert updated_job.status == "failed"
    assert is_nil(updated_job.file_path)
  end

  test "a completion update failure compensates by deleting the stored object", %{job: job} do
    Application.put_env(:threadline, :test_orchestrator_notify_pid, self())

    completion_fn = fn _repo, _job, _file_path, _storage_opts ->
      {:error, :forced_completion_update_failure}
    end

    assert {:error, :forced_completion_update_failure} =
             Orchestrator.run(job.id,
               repo: Repo,
               storage_adapter: RecordingStorage,
               completion_fn: completion_fn
             )

    assert_receive {:storage_put, {:ok, file_id}}
    assert_receive {:storage_delete, ^file_id}
    assert {:error, :enoent} = Local.get(file_id)

    updated_job = Repo.get!(ExportJob, job.id, repo_opts())
    assert updated_job.status == "failed"
    assert is_nil(updated_job.file_path)
  end

  test "a failed compensation retains the object identifier for cleanup retry", %{job: job} do
    Application.put_env(:threadline, :test_orchestrator_notify_pid, self())

    completion_fn = fn _repo, _job, _file_path, _storage_opts ->
      {:error, :forced_completion_update_failure}
    end

    assert {:error, :forced_completion_update_failure} =
             Orchestrator.run(job.id,
               repo: Repo,
               storage_adapter: DeleteFailStorage,
               completion_fn: completion_fn
             )

    assert_receive {:storage_put, {:ok, file_id}}
    assert_receive {:storage_delete, ^file_id}
    assert {:ok, _content} = Local.get(file_id)

    updated_job = Repo.get!(ExportJob, job.id, repo_opts())
    assert updated_job.status == "failed"
    assert updated_job.file_path == file_id
    assert updated_job.error_message =~ "compensation failed"
  end

  defp insert_job!(attrs, storage_schema \\ "threadline") do
    Repo.insert!(
      struct(ExportJob, attrs),
      repo_opts(storage_schema)
    )
  end

  defp insert_change!(row_id, captured_at, opts \\ []) do
    storage_schema = Keyword.get(opts, :storage_schema, "threadline")
    table = Keyword.get(opts, :table, "threadline_export_replay_rows")

    txn =
      Repo.insert!(
        AuditTransaction.changeset(%{
          txid: :rand.uniform(1_000_000_000),
          occurred_at: captured_at
        }),
        repo_opts(storage_schema)
      )

    Repo.insert!(
      AuditChange.changeset(%{
        transaction_id: txn.id,
        table_schema: "public",
        table_name: table,
        table_pk: %{"id" => row_id},
        op: "insert",
        data_after: %{"id" => row_id},
        captured_at: captured_at
      }),
      repo_opts(storage_schema)
    )
  end

  defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
  defp restore_env(key, value), do: Application.put_env(:threadline, key, value)
end
