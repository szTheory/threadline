defmodule ThreadlinePhoenix.Demo.Seed.Exports do
  @moduledoc false

  alias Threadline.Governance.{ExportJob, SavedView}
  alias Threadline.Semantics.ActorRef
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.Demo.Manifest.UUID
  alias ThreadlinePhoenix.Repo

  @demo_namespace_bin UUID.v5_binary(UUID.dns_namespace(), "threadline.demo")

  @doc false
  @spec run(map()) :: map()
  def run(ctx) do
    now = Manifest.epoch()
    actor_ref = %ActorRef{type: :user, id: Manifest.user_id(:admin)}
    completed_path = write_completed_export!()

    inserted_at = DateTime.utc_now(:second)

    rows =
      [
        %{
          id: export_id("completed-downloadable"),
          status: "completed",
          query_params: %{"correlation_id" => Manifest.correlation_id(:acme_4521_close)},
          actor_ref: actor_ref,
          file_path: completed_path,
          started_at: usec(DateTime.add(now, -20, :minute)),
          completed_at: usec(DateTime.add(now, -18, :minute)),
          # Wall-clock-relative so this job stays downloadable no matter how far
          # real time has advanced past the fixed demo epoch — the export screen
          # computes expiry against DateTime.utc_now/0. (started_at/completed_at
          # stay epoch-relative; they only affect display, not the expiry logic.)
          expires_at: usec(DateTime.add(DateTime.utc_now(), 7, :day))
        },
        %{
          id: export_id("failed"),
          status: "failed",
          query_params: %{"table" => "ticket_replies"},
          actor_ref: actor_ref,
          error_message: "Demo export failed while writing the destination file.",
          started_at: usec(DateTime.add(now, -12, :minute)),
          completed_at: usec(DateTime.add(now, -11, :minute)),
          expires_at: usec(DateTime.add(now, 7, :day))
        },
        %{
          id: export_id("running"),
          status: "running",
          query_params: %{"table" => "tickets"},
          actor_ref: actor_ref,
          started_at: usec(DateTime.add(now, -5, :minute))
        },
        %{
          id: export_id("pending"),
          status: "pending",
          query_params: %{"actor_kind" => "user", "actor_id" => Manifest.user_id(:admin)},
          actor_ref: actor_ref
        },
        %{
          id: export_id("completed-expired"),
          status: "completed",
          query_params: %{"correlation_id" => "expired-demo-export"},
          actor_ref: actor_ref,
          file_path: completed_path,
          started_at: usec(DateTime.add(now, -10, :day)),
          completed_at: usec(DateTime.add(now, -10, :day)),
          expires_at: usec(DateTime.add(now, -1, :day))
        }
      ]
      |> Enum.map(&Map.merge(&1, %{inserted_at: inserted_at, updated_at: inserted_at}))

    Repo.insert_all(ExportJob, rows,
      on_conflict:
        {:replace,
         [
           :status,
           :query_params,
           :actor_ref,
           :file_path,
           :error_message,
           :started_at,
           :completed_at,
           :expires_at,
           :updated_at
         ]},
      conflict_target: :id
    )

    seed_saved_views(actor_ref, inserted_at)

    ctx
  end

  # F-204 data: 1–2 SavedView rows for admin's actor_ref so the Home "pick up
  # where you left off" section has data. Render defers to Phase 139.
  defp seed_saved_views(actor_ref, inserted_at) do
    saved_view_rows = [
      %{
        id: saved_view_id("recent-deletes"),
        name: "Recent deletes",
        actor_ref: actor_ref,
        filters: %{"op" => "delete"},
        inserted_at: inserted_at,
        updated_at: inserted_at
      },
      %{
        id: saved_view_id("closed-tickets"),
        name: "Closed this week",
        actor_ref: actor_ref,
        filters: %{"table" => "tickets", "status" => "closed"},
        inserted_at: inserted_at,
        updated_at: inserted_at
      }
    ]

    Repo.insert_all(SavedView, saved_view_rows,
      on_conflict: {:replace, [:name, :filters, :actor_ref, :updated_at]},
      conflict_target: :id
    )
  end

  defp write_completed_export! do
    dir = Path.join(:code.priv_dir(:threadline_phoenix), "threadline_exports")
    File.mkdir_p!(dir)

    path = Path.join(dir, "demo_completed_export.csv")

    File.write!(path, """
    id,table_name,op,captured_at
    demo,tickets,update,#{DateTime.to_iso8601(Manifest.last_tuesday())}
    """)

    path
  end

  defp export_id(name) do
    UUID.format(UUID.v5_binary(@demo_namespace_bin, "export/#{name}"))
  end

  defp saved_view_id(name) do
    UUID.format(UUID.v5_binary(@demo_namespace_bin, "saved_view/#{name}"))
  end

  defp usec(%DateTime{} = dt), do: %{dt | microsecond: {0, 6}}
end
