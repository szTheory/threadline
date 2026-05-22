defmodule Threadline.Retention.PrunerTest do
  use Threadline.DataCase, async: false

  alias Threadline.Governance.RetentionRun
  alias Threadline.Retention.Pruner

  @lock_key :erlang.phash2("threadline_retention_pruner")

  setup do
    prev = Application.get_env(:threadline, :retention)

    on_exit(fn ->
      Application.put_env(:threadline, :retention, prev)
    end)

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true
    )

    :ok
  end

  test "on init, marks running RetentionRuns older than 24h as failed" do
    Repo.delete_all(RetentionRun)

    now = DateTime.utc_now()
    older_than_24h = DateTime.add(now, -25, :hour) |> DateTime.truncate(:microsecond)
    newer_than_24h = DateTime.add(now, -23, :hour) |> DateTime.truncate(:microsecond)

    r1 = Repo.insert!(%RetentionRun{status: "running", started_at: older_than_24h})
    r2 = Repo.insert!(%RetentionRun{status: "running", started_at: newer_than_24h})
    r3 = Repo.insert!(%RetentionRun{status: "completed", started_at: older_than_24h})

    {:ok, _pid} = start_supervised({Pruner, repo: Repo, interval_ms: 10_000, sleep_ms: 0})

    assert Repo.get!(RetentionRun, r1.id).status == "failed"
    assert Repo.get!(RetentionRun, r1.id).error_message == "Abandoned"

    assert Repo.get!(RetentionRun, r2.id).status == "running"
    assert Repo.get!(RetentionRun, r3.id).status == "completed"
  end

  test "schedules itself, acquires lock, and calls purge" do
    Repo.delete_all(RetentionRun)
    {:ok, _pid} = start_supervised({Pruner, repo: Repo, interval_ms: 10, sleep_ms: 0})

    # Wait for the GenServer to handle the scheduled message
    Process.sleep(100)

    runs = Repo.all(RetentionRun)
    assert length(runs) >= 1
    assert Enum.any?(runs, fn r -> r.status == "completed" end)
  end

  test "skips purging if lock is held elsewhere" do
    Repo.delete_all(RetentionRun)

    task =
      Task.async(fn ->
        Repo.transaction(fn ->
          Ecto.Adapters.SQL.query!(Repo, "SELECT pg_try_advisory_lock($1)", [@lock_key])

          receive do
            :release_lock ->
              Ecto.Adapters.SQL.query!(Repo, "SELECT pg_advisory_unlock($1)", [@lock_key])
              :ok
          end
        end)
      end)

    Process.sleep(50)

    try do
      {:ok, _pid} = start_supervised({Pruner, repo: Repo, interval_ms: 10, sleep_ms: 0})

      Process.sleep(100)

      assert Repo.all(RetentionRun) == []
    after
      send(task.pid, :release_lock)
      Task.await(task)
    end
  end
end
