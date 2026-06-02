defmodule ThreadlinePhoenix.Demo.Seed.RetentionRuns do
  @moduledoc """
  Plants a deterministic spread of `threadline_retention_runs` so the retention
  history screen demonstrates its full lifecycle — a small succeeded run, a
  failed run (exercises the danger summary card + warning alert), a large
  offboarding prune (big-number formatting), and a not-yet-started run — rather
  than a single row.

  Mirrors `Demo.Seed.Exports`: fixed UUIDv5 ids and epoch-relative timestamps so
  screenshots are stable across runs. Additive to the real purge run recorded by
  `Demo.Seed.RetentionTail`; the newest row by `started_at` stays a completed run
  so the summary reads "Completed".
  """

  alias Threadline.Governance.RetentionRun
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.Demo.Manifest.UUID
  alias ThreadlinePhoenix.Repo

  @demo_namespace_bin UUID.v5_binary(UUID.dns_namespace(), "threadline.demo")

  @doc false
  @spec run(map()) :: map()
  def run(ctx) do
    now = Manifest.epoch()
    inserted_at = DateTime.utc_now(:second)

    small_started = usec(DateTime.add(now, -2, :day))
    large_started = usec(DateTime.add(now, -90, :day))

    rows =
      [
        %{
          id: run_id("completed-small"),
          status: "completed",
          deleted_count: 14,
          duration_ms: 320,
          started_at: small_started,
          completed_at: usec(DateTime.add(small_started, 1, :second))
        },
        %{
          id: run_id("failed"),
          status: "failed",
          error_message: "Demo prune aborted: lock timeout on audit_changes.",
          started_at: usec(DateTime.add(now, -14, :day))
        },
        %{
          id: run_id("completed-large"),
          status: "completed",
          deleted_count: 18_342,
          duration_ms: 9_120,
          started_at: large_started,
          completed_at: usec(DateTime.add(large_started, 10, :second))
        },
        %{
          id: run_id("pending"),
          status: "pending"
        }
      ]
      |> Enum.map(&Map.merge(&1, %{inserted_at: inserted_at, updated_at: inserted_at}))

    Repo.insert_all(RetentionRun, rows,
      on_conflict:
        {:replace,
         [
           :status,
           :deleted_count,
           :duration_ms,
           :error_message,
           :started_at,
           :completed_at,
           :updated_at
         ]},
      conflict_target: :id
    )

    ctx
  end

  defp run_id(name) do
    UUID.format(UUID.v5_binary(@demo_namespace_bin, "retention_run/#{name}"))
  end

  defp usec(%DateTime{} = dt), do: %{dt | microsecond: {0, 6}}
end
