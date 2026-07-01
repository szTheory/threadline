defmodule Threadline.Retention.PrunerTest do
  use Threadline.DataCase, async: false

  alias Threadline.Governance.RetentionRun
  alias Threadline.Retention.Pruner

  @lock_key :erlang.phash2("threadline_retention_pruner")

  setup do
    # The pruner is a singleton (named __MODULE__). A pruner left running by a
    # previous test could insert a RetentionRun into this test after our
    # delete_all, so stop it deterministically before we begin.
    stop_named_process!(Pruner)

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

  defp start_application_supervisor!(opts \\ []) do
    retention = Application.get_env(:threadline, :retention, [])

    opts =
      [repo: Threadline.Test.Repo]
      |> Keyword.merge(Keyword.take(retention, [:interval_ms, :sleep_ms]))
      |> Keyword.merge(opts)

    start_supervised!({Threadline.Retention.Pruner, opts})
  end

  test "application-owned startup marks running RetentionRuns older than 24h as failed" do
    Repo.delete_all(RetentionRun, repo_opts())

    now = DateTime.utc_now()
    older_than_24h = DateTime.add(now, -25, :hour) |> DateTime.truncate(:microsecond)
    newer_than_24h = DateTime.add(now, -23, :hour) |> DateTime.truncate(:microsecond)

    r1 = Repo.insert!(%RetentionRun{status: "running", started_at: older_than_24h}, repo_opts())
    r2 = Repo.insert!(%RetentionRun{status: "running", started_at: newer_than_24h}, repo_opts())
    r3 = Repo.insert!(%RetentionRun{status: "completed", started_at: older_than_24h}, repo_opts())

    start_application_supervisor!()

    assert Pruner.started?()

    assert Repo.get!(RetentionRun, r1.id, repo_opts()).status == "failed"
    assert Repo.get!(RetentionRun, r1.id, repo_opts()).error_message == "Abandoned"

    assert Repo.get!(RetentionRun, r2.id, repo_opts()).status == "running"
    assert Repo.get!(RetentionRun, r3.id, repo_opts()).status == "completed"
  end

  test "schedules pruning on the named runtime" do
    Repo.delete_all(RetentionRun, repo_opts())

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: 10,
      sleep_ms: 0
    )

    start_application_supervisor!()

    assert_eventually(
      fn ->
        runs = Repo.all(RetentionRun, repo_opts())
        length(runs) >= 1 and Enum.any?(runs, fn run -> run.status == "completed" end)
      end,
      message: "scheduled pruner should record a completed RetentionRun"
    )
  end

  test "skips purging while the advisory lock is held elsewhere, then resumes after release" do
    Repo.delete_all(RetentionRun, repo_opts())

    # 24h interval so the only prune attempts are the ones we trigger explicitly —
    # no timer-driven runs racing the assertions.
    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    start_application_supervisor!()

    # Hold the lock on a dedicated session (outside the repo pool) so the pruner's
    # pg_try_advisory_lock reliably fails — no pool-allocation race.
    with_advisory_lock_held(Repo, @lock_key, fn ->
      Pruner.trigger()
      drain_mailbox(Pruner)

      assert Repo.all(RetentionRun, repo_opts()) == [],
             "pruner must skip purging while the advisory lock is held by another session"
    end)

    # Lock released: a triggered prune now acquires the lock and records a run.
    Pruner.trigger()
    drain_mailbox(Pruner)

    assert_eventually(
      fn -> Repo.all(RetentionRun, repo_opts()) != [] end,
      message: "pruner should record a RetentionRun once the lock is free"
    )
  end

  test "startup marks abandoned runs only in the selected storage schema" do
    ensure_storage_schema!("audit")

    now = DateTime.utc_now()
    older_than_24h = DateTime.add(now, -25, :hour) |> DateTime.truncate(:microsecond)

    audit_run =
      Repo.insert!(
        %RetentionRun{status: "running", started_at: older_than_24h},
        repo_opts("audit")
      )

    default_run =
      Repo.insert!(%RetentionRun{status: "running", started_at: older_than_24h}, repo_opts())

    start_application_supervisor!(storage_schema: "audit")

    assert Repo.get!(RetentionRun, audit_run.id, repo_opts("audit")).status == "failed"
    assert Repo.get!(RetentionRun, audit_run.id, repo_opts("audit")).error_message == "Abandoned"

    assert Repo.get!(RetentionRun, default_run.id, repo_opts()).status == "running"
    assert Repo.get!(RetentionRun, default_run.id, repo_opts()).error_message == nil
  end

  test "triggered prune records runs only in the selected storage schema" do
    ensure_storage_schema!("audit")

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: true,
      interval_ms: :timer.hours(24),
      sleep_ms: 0
    )

    start_application_supervisor!(storage_schema: "audit")

    Pruner.trigger()
    drain_mailbox(Pruner)

    assert_eventually(
      fn ->
        runs = Repo.all(RetentionRun, repo_opts("audit"))
        length(runs) >= 1 and Enum.any?(runs, fn run -> run.status == "completed" end)
      end,
      message: "selected-storage pruner should record a completed audit RetentionRun"
    )

    assert Repo.all(RetentionRun, repo_opts()) == []
  end
end
