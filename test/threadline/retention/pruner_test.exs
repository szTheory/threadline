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
      delete_empty_transactions: true,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    :ok
  end

  defp start_application_supervisor! do
    start_supervised!(
      {Threadline.Application, name: :"threadline-pruner-test-#{System.unique_integer()}"}
    )
  end

  defp eventually(assertion, attempts \\ 20)

  defp eventually(assertion, 1), do: assertion.()

  defp eventually(assertion, attempts) do
    case assertion.() do
      true ->
        true

      false ->
        Process.sleep(25)
        eventually(assertion, attempts - 1)
    end
  end

  test "application-owned startup marks running RetentionRuns older than 24h as failed" do
    Repo.delete_all(RetentionRun)

    now = DateTime.utc_now()
    older_than_24h = DateTime.add(now, -25, :hour) |> DateTime.truncate(:microsecond)
    newer_than_24h = DateTime.add(now, -23, :hour) |> DateTime.truncate(:microsecond)

    r1 = Repo.insert!(%RetentionRun{status: "running", started_at: older_than_24h})
    r2 = Repo.insert!(%RetentionRun{status: "running", started_at: newer_than_24h})
    r3 = Repo.insert!(%RetentionRun{status: "completed", started_at: older_than_24h})

    start_application_supervisor!()

    assert Pruner.started?()

    assert Repo.get!(RetentionRun, r1.id).status == "failed"
    assert Repo.get!(RetentionRun, r1.id).error_message == "Abandoned"

    assert Repo.get!(RetentionRun, r2.id).status == "running"
    assert Repo.get!(RetentionRun, r3.id).status == "completed"
  end

  test "application-owned startup schedules pruning on the named runtime" do
    Repo.delete_all(RetentionRun)

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: 10,
      sleep_ms: 0
    )

    start_application_supervisor!()

    assert eventually(fn ->
             runs = Repo.all(RetentionRun)
             length(runs) >= 1 and Enum.any?(runs, fn run -> run.status == "completed" end)
           end)
  end

  test "skips purging if lock is held elsewhere" do
    Repo.delete_all(RetentionRun)
    parent = self()

    task =
      Task.async(fn ->
        Repo.transaction(fn ->
          Ecto.Adapters.SQL.query!(Repo, "SELECT pg_try_advisory_lock($1)", [@lock_key])
          send(parent, :lock_acquired)

          receive do
            :release_lock ->
              Ecto.Adapters.SQL.query!(Repo, "SELECT pg_advisory_unlock($1)", [@lock_key])
              :ok
          end
        end)
      end)

    assert_receive :lock_acquired, 1_000

    try do
      Application.put_env(:threadline, :retention,
        enabled: true,
        keep_days: 1,
        delete_empty_transactions: true,
        interval_ms: 10,
        sleep_ms: 0
      )

      start_application_supervisor!()

      Process.sleep(100)

      assert Repo.all(RetentionRun) == []
    after
      send(task.pid, :release_lock)
      Task.await(task)
    end
  end
end
