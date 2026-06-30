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

  test "replays persisted string date params and stores only rows inside the requested window" do
    insert_change!("outside-before", ~U[2026-04-30 23:59:59Z])
    insert_change!("inside-start", ~U[2026-05-01 00:00:00Z])
    insert_change!("inside-end", ~U[2026-05-06 23:59:00Z])
    insert_change!("outside-after", ~U[2026-05-07 00:00:00Z])

    job =
      Repo.insert!(%ExportJob{
        status: "pending",
        query_params: %{
          "table" => "threadline_export_replay_rows",
          "from" => "2026-05-01T00:00",
          "to" => "2026-05-06T23:59"
        }
      })

    assert :ok = Orchestrator.run(job.id, repo: Repo)

    updated_job = Repo.get!(ExportJob, job.id)
    assert updated_job.status == "completed"
    assert {:ok, csv} = Local.get(updated_job.file_path)
    assert csv =~ "inside-start"
    assert csv =~ "inside-end"
    refute csv =~ "outside-before"
    refute csv =~ "outside-after"
  end

  test "invalid persisted datetime params fail closed with parser detail", %{job: _job} do
    bad_job =
      Repo.insert!(%ExportJob{
        status: "pending",
        query_params: %{"from" => "not-a-date"}
      })

    assert {:error, _} = Orchestrator.run(bad_job.id, repo: Repo)

    updated_job = Repo.get!(ExportJob, bad_job.id)
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

  defp insert_change!(row_id, captured_at) do
    txn =
      Repo.insert!(
        AuditTransaction.changeset(%{
          txid: :rand.uniform(1_000_000_000),
          occurred_at: captured_at
        })
      )

    Repo.insert!(
      AuditChange.changeset(%{
        transaction_id: txn.id,
        table_schema: "public",
        table_name: "threadline_export_replay_rows",
        table_pk: %{"id" => row_id},
        op: "insert",
        data_after: %{"id" => row_id},
        captured_at: captured_at
      })
    )
  end
end
